package Astro::Montenbruck::RiseSet;

use strict;
use warnings;
no warnings qw/experimental/;
use feature qw/switch state/;

use Exporter qw/import/;
use Readonly;

use Math::Trig qw/:pi deg2rad rad2deg atan/;
use Astro::Montenbruck::MathUtils qw/frac/;
use Astro::Montenbruck::Time qw/cal2jd jd_cent/;
use Astro::Montenbruck::Time::Sidereal qw/ramc/;
use Astro::Montenbruck::Ephemeris::Planet::Sun;
use Astro::Montenbruck::Ephemeris::Planet::Moon;
use Astro::Montenbruck::CoCo qw/ecl2equ/;
use Astro::Montenbruck::NutEqu qw/obliquity/;

our %EXPORT_TAGS = ( all => [qw/rs_sun rs_moon twilight $EVT_RISE $EVT_SET/], );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION     = 0.01;

Readonly our $EVT_RISE => 'rise';
Readonly our $EVT_SET  => 'set';
Readonly our $COSEPS   => 0.91748;
Readonly our $SINEPS   => 0.39778;

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
    $ra * 15, $de;
}

sub _objpos {
    my ( $obj, $t ) = @_;
    my ( $lambda, $beta ) =
      $obj->position($t);    # apparent geocentric ecliptical coordinates
    my $eps = obliquity($t);
    ecl2equ( $lambda, $beta, $eps );
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

    my $jd0     = cal2jd( $year, $month, $day );
    my $rphi    = deg2rad($phi);
    my $sphi    = sin($rphi);
    my $cphi    = cos($rphi);
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
        #get_position => sub { mini_sun( $_[0] ) },
        sin_h0       => sin( deg2rad( -50 / 60 ) )
    );
}

sub rs_moon {
    state $moo = Astro::Montenbruck::Ephemeris::Planet::Moon->new();

    # moonrise at h = 8'
    _sun_moon_rs(
        @_,
        get_position => sub { _objpos( $moo, $_[0] ) },
        sin_h0       => sin( deg2rad( 8 / 60 ) )
    );
}

sub twilight {
    state $sun = Astro::Montenbruck::Ephemeris::Planet::Sun->new();

    # nautical twilight at h = -12 degrees
    _sun_moon_rs(
        @_,
        get_position => sub { _objpos( $sun, $_[0] ) },
        sin_h0       => sin( deg2rad(-12) )
    );
}
