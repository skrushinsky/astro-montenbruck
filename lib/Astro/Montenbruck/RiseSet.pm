package Astro::Montenbruck::RiseSet;

use strict;
use warnings;
use feature qw/switch/;

use Exporter qw/import/;
use Readonly;

use Math::Trig qw/:pi deg2rad rad2deg/;
#use Astro::Montenbruck::MathUtils qw/frac ARCS polynome/;
use Astro::Montenbruck::Time qw/jd2lst jd2mjd mjd2jd cal2jd $J2000/;
use Astro::Montenbruck::Ephemeris::Planet::Sun;
use Astro::Montenbruck::Ephemeris::Planet::Moon;
use Astro::Montenbruck::CoCo qw/ecl2equ/;
use Astro::Montenbruck::NutEqu qw/obliquity/;

our %EXPORT_TAGS = (
    all => [ qw/rs_sun rs_moon twilight $EVT_RISE $EVT_SET/ ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = 0.01;

Readonly our $EVT_RISE => 'rise';
Readonly our $EVT_SET  => 'set';

sub _objpos {
    my ($obj, $t) = @_;
    my ($lambda, $beta) = $obj->position($t); # apparent geocentric ecliptical coordinates
    my $eps = obliquity($t);
    ecl2equ($lambda, $beta, $eps);
}


# Finds a parabola through 3 points: (-1, $y_minus), (0, $y_0) and (1, $y_plus),
# that do not lie on straight line.
# Arguments:
# $y_minus, $y_0, $y_plus - three Y-values
# $xe, $ye - X and Y of the extreme value of the parabola
# $zero1 - first root within [-1, +1] (for $nz = 1, 2)
# $zero2 - second root within [-1, +1] (only for $nz = 2)
# $nz - number of roots within the interval [-1, +1]
sub _quad {
    my ($y_minus, $y_0, $y_plus, $xe, $ye, $zero1, $zero2) = @_;
    my $nz = 0;
    my $a = 0.5 * ($y_minus + $y_plus) - $y_0;
    my $b = 0.5 * ($y_plus - $y_minus);
    my $c = $y_0;

    $$xe = -$b / (2 * $a);
    $$ye = ($a * $$xe + $b) * $$xe + $c;
    my $dis = $b * $b - 4 * $a * $c; # discriminant of y = axx+bx+c
    if ($dis >= 0) {
        # parabola intersects x-axis
        my $dx = 0.5 * sqrt($dis) / abs($a);
        $$zero1 = $$xe - $dx;
        $$zero2 = $$xe + $dx;
        $nz++ if abs($$zero1) <= 1;
        $nz++ if abs($$zero2) <= 1;
        $$zero1 = $$zero2 if $$zero1 < -1;
    }
    $nz
}

# Calculates sine of the altitude at hourly intervals.
sub _sin_alt {
    my ($mjd, $lambda, $cphi, $sphi, $get_position) = @_;
    my $t = ($mjd - 51544.5) / 36525;
    my ($ra, $de) = $get_position->($t);
    my $tau = deg2rad(15 * (jd2lst(mjd2jd($mjd), $lambda) - $ra));
    my $rde = deg2rad($de);
    $sphi * sin($rde) + $cphi * cos($rde) * cos($tau)
}

sub _sun_moon_rs {
    my ( $year, $month, $day, $lam, $phi, %arg ) = @_;

    my $mjd0    = jd2mjd(cal2jd($year, $month, int($day)));
    my $sphi    = sin(deg2rad($phi));
    my $cphi    = cos(deg2rad($phi));
    my $sin_alt = sub {
        _sin_alt(
            $mjd0 + $_[0] / 24, $lam, $cphi, $sphi, $arg{get_position}
        )
    };
    my $hour    = 1;
    my $y_minus = $sin_alt->($hour-1) - $arg{sin_h0};
    my $above   = $y_minus > 0;
    my ($rise_found, $set_found) = (0, 0);
    my ($xe, $ye, $zero1, $zero2) = (0, 0, 0, 0);
    # loop over search intervals from [0h-2h] to [22h-24h]
    do {
        my $y0 = $sin_alt->($hour) - $arg{sin_h0};
        my $y_plus = $sin_alt->($hour+1) - $arg{sin_h0};
        # find parabola through three values $y_minus, $y0, $y_plus
        my $nz = _quad($y_minus, $y0, $y_plus, \$xe, \$ye, \$zero1, \$zero2);
$DB::single = 1 if $nz;
        given( $nz ) {
            when (1) {
                if ($y_minus < 0) {
                    $arg{on_event}->($EVT_RISE, $hour + $zero1);
                    $rise_found = 1;
                } else {
                    $arg{on_event}->($EVT_SET , $hour + $zero1);
                    $set_found = 1;
                }
            };
            when (2) {
                if ($ye < 0) {
                    $arg{on_event}->($EVT_RISE, $hour + $zero2);
                    $arg{on_event}->($EVT_SET , $hour + $zero1);
                }
                else {
                    $arg{on_event}->($EVT_RISE, $hour + $zero1);
                    $arg{on_event}->($EVT_SET , $hour + $zero2);
                }
                ($rise_found, $set_found) = (1, 1);
            }
        }
        # prepare for next interval
        $y_minus = $y_plus;
        $hour += 2;
    } until ($hour == 25 || ($rise_found && $set_found) );

    $arg{on_noevent}->($above) unless ($rise_found || $set_found);
}

sub rs_sun {
    # sunrise at h = -50'
    _sun_moon_rs(
        @_,
        get_position => sub {
            _objpos(Astro::Montenbruck::Ephemeris::Planet::Sun->new(), $_[0])
        },
        sin_h0 => sin(deg2rad(8/60))
    )
}

sub rs_moon {
    # moonrise at h = 8'
    _sun_moon_rs(
        @_,
        get_position => sub {
            _objpos(Astro::Montenbruck::Ephemeris::Planet::Moon->new(), $_[0])
        },
        sin_h0 => sin(deg2rad(-50/60))
    )
}

sub twilight {
    # nautical twilight at h = -12 degrees
    _sun_moon_rs(
        @_,
        get_position => sub {
            _objpos(Astro::Montenbruck::Ephemeris::Planet::Sun->new(), $_[0])
        },
        sin_h0 => sin(deg2rad(-12))
    )
}
