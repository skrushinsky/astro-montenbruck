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
          $TWILIGHT_CIVIL $TWILIGHT_ASTRO $TWILIGHT_NAUTICAL/
    ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION   = 0.01;

Readonly our $EVT_RISE    => 'rise';
Readonly our $EVT_SET     => 'set';
Readonly our $EVT_TRANSIT => 'transit';

Readonly our $STATE_CIRCUMPOLAR => 'circumpolar';
Readonly our $STATE_NEVER_RISES => 'never rises';

Readonly our $TWILIGHT_CIVIL    => 'civil';
Readonly our $TWILIGHT_ASTRO    => 'astronomical';
Readonly our $TWILIGHT_NAUTICAL => 'nautical';

Readonly our $H0_SUN => -50 / 60;
Readonly our $H0_MOO =>   8 / 60;
Readonly our $H0_PLA => -34 / 60;
Readonly::Hash our %H0_TWL => (
    $TWILIGHT_CIVIL    => -6,
    $TWILIGHT_ASTRO    => -18,
    $TWILIGHT_NAUTICAL => -12
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

# Return the standard altitude of the Moon.
#
# Arguments:
#   - $r : Distance between the centers of the Earth and Moon, in km.
# Returns:
#   - Standard altitude in radians.
sub _moon_rs_alt {
    my ($y, $m, $d) = @_;
    $H0_MOO
}

sub rst_event {
    my %arg = @_;
    my $pla = delete $arg{planet};

    _rst_function(
        h       => do {
            given( $pla ) {
                $H0_SUN when $SU;
                _moon_rs_alt($arg{year}, $arg{month}, $arg{day}) when $MO;
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
    my %arg = (type => $TWILIGHT_NAUTICAL, @_);
    my $type = delete $arg{type};

    my $func = _rst_function(
        h        => $H0_TWL{$type},
        pos_func => sub {
            my $jd = shift;
            _get_equatorial( $SU, $jd )
        },
        %arg
    );
    # Make sure the function receives proper arguments.
    sub {
        my $evt = shift;
        die "\"$EVT_TRANSIT\" event is irrelevant here" if $evt eq $EVT_TRANSIT;
        $func->($evt, @_)
    }
}


1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::RiseSet — rise, set, transit.

=head1 SYNOPSIS

use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;
use Astro::Montenbruck::MathUtils qw/frac/;
use Astro::Montenbruck::RiseSet', qw/:all/;

# create function for calculating Moon events for Munich, Germany, on March 23, 1989.
my $func = rst_event(
    planet => $MO,
    year   => 1989,
    month  => 3,
    day    => 23,
    phi    => 48.1,
    lambda => -11.6
);

# calculate Moon rise. Alternatively, use $EVT_SET for set, $EVT_TRANSIT for
# transit as the first argument
$func->(
    $EVT_RISE,
    on_event => sub {
        my $jd = shift; # Standard Julian date
        my $ut = frac(jd - 0.5) * 24; # UTC, 18.95 = 18h57m
    }
);


=head1 VERSION

Version 0.01


=head1 DESCRIPTION

Rise, set and transit times of celestial bodies. The calculations are based on
I<"Astronomical Algorythms" by Jean Meeus>. The same subject is discussed in
I<Montenbruck & Phleger> book, but Meeus's method is more general and consistent.
Unit tests use examples from the both sources.

The general problem here is to find the instant of time at which a celestial
body reaches a predetermined I<altitude>.

To take into account parallax, refraction and apparent radius of the bodies, we
use average corrections to geometric altitudes:

=over

=item * sunrise, sunset : B<-0°50'>

=item * moonrise, moonset : B<0°8'>

=item * stars and planets : B<-0°34'>

=back

The library also calculates the times of the beginning and end of twilight.
There are three types of twilight:

=over

=item * I<astronomical>, when Sun altitude is B<-18°>

=item * I<nautical>, when Sun altitude is B<-12°>

=item * I<civil>, when Sun altitude is B<-6°>

=back

=head1 EXPORT

=head2 FUNCTIONS

=over

=item * L</rst_event( %args )>

=item * L</twilight( %args )>

=back

=head2 CONSTANTS

=head3 EVENTS

=over

=item * C<$EVT_RISE> — rise

=item * C<$EVT_SET> — set

=item * C<$EVT_TRANSIT> — transit (upper culmination)

=back

=head3 STATES

=over

=item * C<$STATE_CIRCUMPOLAR> — always above the horizon

=item * C<$STATE_NEVER_RISES> — always below the horizon

=back

=head3 TYPES OF TWILIGHT

=over

=item * C<$TWILIGHT_CIVIL> — civil

=item * C<$TWILIGHT_ASTRO> — astronomical

=item * C<$TWILIGHT_NAUTICAL> — nautical

=back


=head1 FUNCTIONS

=head2 rst_event( %args )

Returns function for calculating time of event.
See L</RISE/SET/TRANSIT EVENT FUNCTION> below.

=head3 Named Arguments

=over

=item * B<planet> — Celestial body identifier, one of constants defined in
                   L<Astro::Montenbruck::Ephemeris::Planet>.

=item * B<year> — year, astronomical, zero-based

=item * B<month> — month, 1..12

=item * B<day> — day, 1..31

=item * B<phi> — geographic latitude, degrees, positive northward

=item * B<lambda> — geographic longitude, degrees, positive westward

=back

=head2 RISE/SET/TRANSIT EVENT FUNCTION

    $func->( EVENT_TYPE, on_event => sub{ ... }, on_noevent => sub{ ... } );

Its first argument, I<event type>, is one of C</$EVT_RISE>, C</$EVT_SET>, or
C</$EVT_TRANSIT>, see L</EVENTS>. Named arguments are callback functions:

=over

=item *

C<on_event> is called when the event time is determined. The argument is
I<Standard Julian date> of the event.

    on_event => sub { my $jd = shift; ... }

=item *

C<on_noevent> is called when the event never happens, either because the body
never rises, or is circumpolar. The argument is respectively
C</$STATE_NEVER_RISES> or C</$STATE_CIRCUMPOLAR>, see L</STATES>.

    on_noevent => sub { my $state = shift; ... }

=back

=head2 twilight( %args )

Function for calculating twilight. See L</TWILIGHT EVENT FUNCTION> below.

=head3 Named Arguments

=over

=item * B<type> — type of twilight, C</$TWILIGHT_NAUTICAL>, C</$TWILIGHT_ASTRO>
                  or C</$TWILIGHT_CIVIL>, see L</TYPES OF TWILIGHT>.

=item * B<year> — year, astronomical, zero-based

=item * B<month> — month, 1..12

=item * B<day> — day, 1..31

=item * B<phi> — geographic latitude, degrees, positive northward

=item * B<lambda> — geographic longitude, degrees, positive westward

=back

=head2 TWILIGHT EVENT FUNCTION

    $func->( EVENT_TYPE, on_event => sub{ ... }, on_noevent => sub{ ... } );

Its first argument, I<event type>, is one of C</$EVT_RISE> or C</$EVT_SET>,
meaning respectively I<beginning of the morning twilight> or
I<end of the evening twilight>. Named arguments are callback functions:

=over

=item *

C<on_event> is called when the event time is determined. The argument is
I<Standard Julian date> of the event.

    on_event => sub { my $jd = shift; ... }

=item *

C<on_noevent> is called when the event never happens, either because the body
never rises, or is circumpolar. The argument is respectively
L</$STATE_NEVER_RISES> or L</$STATE_CIRCUMPOLAR>.

    on_noevent => sub { my $state = shift; ... }

=back

=cut
