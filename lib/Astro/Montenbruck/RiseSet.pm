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

use Math::Trig qw/:pi deg2rad rad2deg acos/;
use Astro::Montenbruck::MathUtils qw/frac to_range diff_angle reduce_deg/;
use Astro::Montenbruck::Time qw/cal2jd jd_cent $SEC_PER_DAY/;
use Astro::Montenbruck::Time::Sidereal qw/ramc/;
use Astro::Montenbruck::Time::DeltaT qw/delta_t/;
use Astro::Montenbruck::CoCo qw/ecl2equ equ2hor/;
use Astro::Montenbruck::NutEqu qw/obliquity/;
use Astro::Montenbruck::Ephemeris qw/iterator/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;

our %EXPORT_TAGS = (
    all => [
        qw/rst_event twilight
          $EVT_RISE $EVT_SET $EVT_TRANSIT $STATE_CIRCUMPOLAR $STATE_NEVER_RISES
          $TWILIGHT_CIVIL $TWILIGHT_ASTRO $TWILIGHT_NAUTI/
    ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION   = 0.01;

Readonly our $EVT_RISE    => 'rise';
Readonly our $EVT_SET     => 'set';
Readonly our $EVT_TRANSIT => 'transit';

Readonly our $STATE_CIRCUMPOLAR => 'circumpolar';
Readonly our $STATE_NEVER_RISES => 'never rises';

Readonly our $TWILIGHT_CIVIL => 'civil';
Readonly our $TWILIGHT_ASTRO => 'astronomical';
Readonly our $TWILIGHT_NAUTI => 'nautical';

Readonly our $H0_SUN => -50 / 60;
Readonly our $H0_MOO =>   8 / 60;
Readonly our $H0_PLA => -34 / 60;
Readonly::Hash our %H0_TWL => (
    $TWILIGHT_CIVIL => -6,
    $TWILIGHT_ASTRO => -18,
    $TWILIGHT_NAUTI => -12
);

sub _get_obliquity { obliquity( $_[0] ) }

sub _get_equatorial {
    my ( $id, $jd ) = @_;
    my $t    = jd_cent($jd);
    my $iter = iterator( $t, [$id] );
    my $res  = $iter->();
    my @ecl  = @{ $res->[1] }[ 0 .. 1 ];
    map { deg2rad($_) } ecl2equ( @ecl, _get_obliquity($t) );
}


# Interpolate from three equally spaced tabular angular values.
#
# [Meeus-1998; equation 3.3]
#
# This version is suitable for interpolating from a table of
# angular values which may cross the origin of the circle,
# for example: 359 degrees...0 degrees...1 degree.
#
# Arguments:
#   - `n` : the interpolating factor, must be between -1 and 1
#   - `y` : a sequence of three values
#
# Results:
#   - the interpolated value of y

sub _interpolate_angle3 {
    my ( $n, $y ) = @_;
    die "interpolating factor $n out of range" unless ( -1 < $n ) && ( $n < 1 );

    my $a = diff_angle( $y->[0], $y->[1], 'radians' );
    my $b = diff_angle( $y->[1], $y->[2], 'radians' );
    my $c = diff_angle( $a,      $b,      'radians' );
    $y->[1] + $n / 2 * ( $a + $b + $n * $c );
}

# Interpolate from three equally spaced tabular values.
#
# [Meeus-1998; equation 3.3]
#
# Parameters:
#   - `n` : the interpolating factor, must be between -1 and 1
#   - `y` : a sequence of three values
#
# Results:
#   - the interpolated value of y
sub _interpolate3 {
    my ( $n, $y ) = @_;
    die "interpolating factor out of range $n" unless ( -1 < $n ) && ( $n < 1 );

    my $a = $y->[1] - $y->[0];
    my $b = $y->[2] - $y->[1];
    my $c = $b - $a;
    $y->[1] + $n / 2 * ( $a + $b + $n * $c );
}

sub _rst_function {
    my %arg = @_;
    my ( $h, $phi, $lambda ) = map { deg2rad( $arg{$_} ) } qw/h phi lambda/;
    my $sin_h = sin($h);
    my $delta = $arg{delta} || 1 / 1440;
    my $jdm = cal2jd( $arg{year}, $arg{month}, int( $arg{day} ) );
    my $gstm = deg2rad( ramc( $jdm, 0 ) );
    my @equ = map { [ $arg{pos_func}->($jdm + $_ ) ] } ( -1 .. 1 );
    my @alpha = map { $_->[0] } @equ;
    my @delta = map { $_->[1] } @equ;
    my $cos_h = ( $sin_h - sin($phi) * sin( $delta[1] ) ) /
      ( cos($phi) * cos( $delta[1] ) );
    my $dt = delta_t($jdm) / $SEC_PER_DAY;

    sub {
        my $evt = shift;    # $EVT_RISE, $EVT_SET or $EVT_TRANSIT
        die "Unknown event: $evt"
          unless grep /^$evt$/, ( $EVT_RISE, $EVT_SET, $EVT_TRANSIT );
        my %arg = ( max_iter => 10, @_ );

        if ( $cos_h < -1 ) {
            $arg{on_noevent}->($STATE_CIRCUMPOLAR);
            return;
        }
        elsif ( $cos_h > 1 ) {
            $arg{on_noevent}->($STATE_NEVER_RISES);
            return;
        }
        my $h0 = acos($cos_h);
        my $m0 = ( $alpha[1] + $lambda - $gstm ) / pi2;
        my $m  = do {
            given ($evt) {
                $m0 when $EVT_TRANSIT;
                $m0 - $h0 / pi2 when $EVT_RISE;
                $m0 + $h0 / pi2 when $EVT_SET;
            }
        };
        if ( $m < 0 ) {
            $m++;
        }
        elsif ( $m > 1 ) {
            $m--;
        }
        die "m is out of range: $m" unless ( 0 <= $m ) && ( $m <= 1 );

        for ( 0 .. $arg{max_iter} ) {
            my $m0 = $m;
            my $theta0 = deg2rad( reduce_deg( rad2deg($gstm) + 360.985647 * $m ) );
            my $n  = $m + $dt;
            my $ra = _interpolate_angle3( $n, \@alpha );
            my $h1 = diff_angle( 0, $theta0 - $lambda - $ra, 'radians' );
            my $dm = do {
                given ($evt) {
                    -( $h1 / pi2 ) when $EVT_TRANSIT;
                    default {
                        my $de = _interpolate3( $n, \@delta );
                        my ( $az, $alt ) = map { deg2rad($_) }
                          equ2hor( map { rad2deg($_) } ( $h1, $de, $phi ) );
                        ( $alt - $h ) /
                          ( pi2 * cos($de) * cos($phi) * sin($h1) );
                    }
                }
            };
            $m += $dm;
            if ( abs( $m - $m0 ) < $delta ) {
                $arg{on_event}->( $jdm + $m );
                return
            }
        }
        die 'bailout!';
      }
}

sub rst_event {
    my %arg = @_;
    my $pla = delete $arg{planet};

    _rst_function(
        h       => do {
            given( $pla ) {
                $H0_SUN when $SU;
                $H0_MOO when $MO;
                default { $H0_PLA }
            }
        },
        pos_func => sub {
            my $jd = shift;
            _get_equatorial( $pla, $jd )
        },
        %arg
    )
}

sub twilight {
    my %arg = (type => $TWILIGHT_NAUTI, @_);
    _rst_function(
        h        => $H0_TWL{$arg{type}},
        pos_func => sub {
            my $jd = shift;
            _get_equatorial( $SU, $jd )
        },
        %arg
    );
}
