package Astro::Montenbruck::RiseSet;

use strict;
use warnings;
no warnings qw/experimental/;
use feature qw/switch state/;

use Exporter qw/import/;
use POSIX qw /fmod/;
use Readonly;
use Memoize;
memoize qw/_get_obliquity/;

use Math::Trig qw/:pi deg2rad rad2deg atan acos/;
use Astro::Montenbruck::MathUtils qw/frac/;
use Astro::Montenbruck::Time qw/cal2jd jd_cent/;
use Astro::Montenbruck::Time::Sidereal qw/ramc/;
use Astro::Montenbruck::Ephemeris::Planet::Sun;
use Astro::Montenbruck::Ephemeris::Planet::Moon;
use Astro::Montenbruck::CoCo qw/ecl2equ/;
use Astro::Montenbruck::NutEqu qw/obliquity/;
use Astro::Montenbruck::Ephemeris qw/iterator/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;

our %EXPORT_TAGS = ( all => [
       qw/rs_sun rs_moon twilight rst_event
          $EVT_RISE $EVT_SET $EVT_TRANSIT $STATE_CIRCUMPOLAR $STATE_NEVER_RISES/
    ],
);
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION     = 0.01;

Readonly our $EVT_RISE    => 'rise';
Readonly our $EVT_SET     => 'set';
Readonly our $EVT_TRANSIT => 'transit';

Readonly our $STATE_RISES_SETS  => 0;
Readonly our $STATE_CIRCUMPOLAR => 1;
Readonly our $STATE_NEVER_RISES => 2;

Readonly our $COSEPS => 0.91748;
Readonly our $SINEPS => 0.39778;

Readonly our $SIN_H0_SUN => sin( deg2rad(-50 / 60) );
Readonly our $SIN_H0_MOO => sin( deg2rad(  8 / 60) );
Readonly our $SIN_H0_PLA => sin( deg2rad(-34 / 60) );
Readonly our $SIN_H0_TWL => sin( deg2rad(-12) );

Readonly our $SID => 0.9972696; # Conversion sidereal/solar time

sub mini_sun {
    my $t  = shift;
    my $m  = pi2 * frac( 0.993133 + 99.997361 * $t );
    my $dl = 6893 * sin($m) + 72 * sin( 2 * $m );
    my $l = pi2 * frac( 0.7859453 + $m / pi2 + ( 6191.2 * $t + $dl ) / 1296e3 );
    my $sl  = sin($l);
    my $x   = cos($l);
    my $y   = $COSEPS * $sl;
    my $z   = $SINEPS * $sl;
    my $rh0 = sqrt( 1 - $z * $z );
    my $de  = ( 360 / pi2 ) * atan( $z / $rh0 );
    my $ra  = ( 48 / pi2 ) * atan( $y / ( $x + $rh0 ) );
    $ra += 24 if $ra < 0;
    $ra * 15, $de
}


sub _get_obliquity { obliquity($_[0]) }

sub _objpos {
    my ( $obj, $t ) = @_;
    my ( $lambda, $beta ) = $obj->position($t);    # apparent geocentric ecliptical coordinates
    ecl2equ( $lambda, $beta, _get_obliquity($t) );
}

sub _cs_phi {
    my $phi = shift;
    my $rphi = deg2rad($phi);
    cos($rphi), sin($rphi)
}

# Finds a parabola through 3 points: (-1, $y_minus), (0, $y_0) and (1, $y_plus),
# that do not lie on straight line.
# Arguments:
# $y_minus, $y_0, $y_plus - three Y-values
# Returns:
# $nz - number of roots within the interval [-1, +1]
# $xe, $ye - X and Y of the extreme value of the parabola
# $zero1 - first root within [-1, +1] (for $nz = 1, 2)
# $zero2 - second root within [-1, +1] (only for $nz = 2)
sub _quad {
    my ( $y_minus, $y_0, $y_plus ) = @_;
    my $nz = 0;
    my $a  = 0.5 * ( $y_minus + $y_plus ) - $y_0;
    my $b  = 0.5 * ( $y_plus - $y_minus );
    my $c  = $y_0;

    my $xe  = -$b / ( 2 * $a );
    my $ye  = ( $a * $xe + $b ) * $xe + $c;
    my $dis = $b * $b - 4 * $a * $c;  # discriminant of y = axx+bx+c
    my @zeroes;
    if ( $dis >= 0 ) {
        # parabola intersects x-axis
        my $dx = 0.5 * sqrt($dis) / abs($a);
        @zeroes[0, 1] = ($xe - $dx, $xe + $dx);
        $nz++ if abs( $zeroes[0] ) <= 1;
        $nz++ if abs( $zeroes[1] ) <= 1;
        $zeroes[0] = $zeroes[1] if $zeroes[0] < -1;
    }
    $nz, $xe, $ye, @zeroes;
}

# Calculates sine of the altitude at hourly intervals.
sub _sin_alt {
    my ( $jd, $lambda, $cphi, $sphi, $get_position ) = @_;
    my $t = jd_cent($jd);
    my ( $ra, $de ) = $get_position->($t);
    my $tau = deg2rad( ramc( $jd, $lambda ) - $ra );
    my $rde = deg2rad($de);
    $sphi * sin($rde) + $cphi * cos($rde) * cos($tau);
}

sub _sun_moon_rs {
    my ( $year, $month, $day, $lam, $phi, %arg ) = @_;

    my $jd0     = cal2jd( $year, $month, int($day) );
    my ($cphi, $sphi) = _cs_phi($phi);
    my $sin_alt = sub {
        my $hour = shift;
        _sin_alt( $jd0 + $hour / 24, $lam, $cphi, $sphi, $arg{get_position} );
    };
    my $hour    = 1;
    my $y_minus = $sin_alt->( $hour - 1 ) - $arg{sin_h0};
    my $above   = $y_minus > 0;
    my ( $rise_found, $set_found ) = ( 0, 0 );

    # loop over search intervals from [0h-2h] to [22h-24h]
    do {
        my $y0     = $sin_alt->($hour) - $arg{sin_h0};
        my $y_plus = $sin_alt->( $hour + 1 ) - $arg{sin_h0};

        # find parabola through three values $y_minus, $y0, $y_plus
        my ( $nz, $xe, $ye, @zeroes ) = _quad( $y_minus, $y0, $y_plus );
        given ($nz) {
            when (1) {
                if ( $y_minus < 0 ) {
                    $arg{on_event}->( $EVT_RISE, $hour + $zeroes[0] );
                    $rise_found = 1;
                }
                else {
                    $arg{on_event}->( $EVT_SET, $hour + $zeroes[0] );
                    $set_found = 1;
                }
            }
            when (2) {
                if ( $ye < 0 ) {
                    $arg{on_event}->( $EVT_RISE, $hour + $zeroes[1] );
                    $arg{on_event}->( $EVT_SET,  $hour + $zeroes[0] );
                }
                else {
                    $arg{on_event}->( $EVT_RISE, $hour + $zeroes[0] );
                    $arg{on_event}->( $EVT_SET,  $hour + $zeroes[1] );
                }
                ( $rise_found, $set_found ) = ( 1, 1 );
            }
        }

        # prepare for next interval
        $y_minus = $y_plus;
        $hour += 2;
    } until ( ( $hour == 25 ) || ( $rise_found && $set_found ) );

    $arg{on_noevent}->($above) unless ( $rise_found || $set_found );
}

sub rs_sun {
    state $sun = Astro::Montenbruck::Ephemeris::Planet::Sun->new();
    # sunrise at h = -50'
    _sun_moon_rs(
        @_,
        get_position => sub { _objpos($sun, $_[0]) },
        sin_h0       => $SIN_H0_SUN
    );
}

sub rs_moon {
    state $moo = Astro::Montenbruck::Ephemeris::Planet::Moon->new();
    # moonrise at h = 8'
    _sun_moon_rs(
        @_,
        get_position => sub { _objpos( $moo, $_[0] ) },
        sin_h0       => $SIN_H0_MOO
    );
}

sub twilight {
    state $sun = Astro::Montenbruck::Ephemeris::Planet::Sun->new();

    # nautical twilight at h = -12 degrees
    _sun_moon_rs(
        @_,
        get_position => sub { _objpos( $sun, $_[0] ) },
        sin_h0       => $SIN_H0_TWL
    );
}


sub rst_event {
    my ( $id, $year, $month, $day, $lam, $phi) = @_;
    my $jd   = cal2jd( $year, $month, int($day) );
    my $t0   = jd_cent($jd);
    my ($cphi, $sphi) = _cs_phi($phi);
    # Local sidereal time at 0h local time
    #my $lst00h = gmst(MJD) + lambda;
    my $lst00h = deg2rad(ramc( $jd, $lam ));

    my $get_position = sub {
        my $t = shift;
        my $iter = iterator( $t, [$id] );
        my $res = $iter->();
        my @ecl = @{$res->[1]}[0..1];
        map{ deg2rad($_) } ecl2equ( @ecl, _get_obliquity($t) );
    };

    my $sin_h0 = do {
        given ($id) {
            $SIN_H0_PLA when $SU;
            $SIN_H0_MOO when $MO;
            default { $SIN_H0_PLA }
        }
    };

    # Compute geocentric planetary position at 0h and 24h local time
    my ($ra00h, $de00h) = $get_position->($t0);
    my ($ra24h, $de24h) = $get_position->($t0 + 1 / 36525);
    # Generate continuous right ascension values in case of jumps between 0h and 24h
    $ra24h += pi2 if ($ra00h - $ra24h >  pi);
    $ra00h += pi2 if ($ra00h - $ra24h < -pi);

    # Compute rising, transit or setting time
    sub {
        my $evt = shift; # $EVT_RISE, $EVT_SET or $EVT_TRANSIT
        die "Unknown event: $evt" unless grep /^$evt$/, ($EVT_RISE, $EVT_SET, $EVT_TRANSIT);
        my %arg = (max_iter => 10, @_);

        # Starting value 12h local time
        my $lt    = 12;
        my $count = 0;
        my $delta_lt;
        # Iteration
        do {
            die 'Bail out!' if $count > $arg{max_iter};
            # Linear interpolation of planetary position
            my $h_ratio = $lt / 24;
            my $ra = $ra00h + $h_ratio * ($ra24h - $ra00h );
            my $de = $de00h + $h_ratio * ($de24h - $de00h );
            # Compute semi-diurnal arc (in rad)
            my $sda = ($sin_h0 - sin($de) * $sphi) / (cos($de) * $cphi);
            if (abs($sda) < 1) {
                $sda = acos($sda)
            }
            else {
                # Test for circumpolar motion or invisibility
                if ($phi * $de >= 0) {
                    $arg{on_noevent}->($STATE_CIRCUMPOLAR)
                }
                else {
                    $arg{on_noevent}->($STATE_NEVER_RISES)
                }
                return;  # Terminate iteration loop
            }
            # Local sidereal time
            my $lst = $lst00h + $lt / ($SID * 12 / pi);
            my $dtau = do {
                given ($evt) {
                    ($lst - $ra) + $sda when $EVT_RISE;
                    ($lst - $ra) - $sda when $EVT_SET;
                    ($lst - $ra)        when $EVT_TRANSIT;
                }
            };
            # Improved times for rising, culmination and setting
            $delta_lt = $SID * (12 / pi) * (fmod($dtau + pi, pi2) - pi);
            $lt -= $delta_lt;

            $count++;
        }
        until ( abs($delta_lt) <= 0.008 );
        $arg{on_event}->($lt);
    }
}
