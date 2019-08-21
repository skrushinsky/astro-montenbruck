package Astro::Montenbruck::Lunation;

use strict;
use warnings;

use Exporter qw/import/;
use Readonly;
use Math::Trig qw/deg2rad/;
use List::Util qw/any reduce/;
use List::MoreUtils qw/zip_unflatten/;
use Astro::Montenbruck::MathUtils qw/reduce_deg/;
use Astro::Montenbruck::Time qw/is_leapyear day_of_year/;

my @quarters   = qw/$NEW_MOON $FIRST_QUARTER $FULL_MOON $LAST_QUARTER/;
my @funcs = qw/search_event/;

our %EXPORT_TAGS = (
    quarters    => \@quarters,
    functions   => \@funcs,
    all         => [ @quarters, @funcs ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION   = 0.01;

Readonly our $NEW_MOON      => 'New Moon';
Readonly our $FIRST_QUARTER => 'First Quarter';
Readonly our $FULL_MOON     => 'Full Moon';
Readonly our $LAST_QUARTER  => 'Last Quarter';

Readonly::Array my @NEW_MOON_TERMS => (
    -0.40720, 0.17241,  0.01608,  0.01039,  0.00739,  -0.00514,
    0.00208,  -0.00111, -0.00057, 0.00056,  -0.00042, 0.00042,
    0.00038,  -0.00024, -0.00017, -0.00007, 0.00004,  0.00004,
    0.00003,  0.00003,  -0.00003, 0.00003,  -0.00002, -0.00002,
    0.00002
);

Readonly::Array my @FULL_MOON_TERMS => (
    -0.40614, 0.17302,  0.01614,  0.01043,  0.00734,  -0.00515,
    0.00209,  -0.00111, -0.00057, 0.00056,  -0.00042, 0.00042,
    0.00038,  -0.00024, -0.00017, -0.00007, 0.00004,  0.00004,
    0.00003,  0.00003,  -0.00003, 0.00003,  -0.00002, -0.00002,
    0.00002
);

Readonly::Array my @QUARTER_TERMS => (
    -0.62801, 0.17172,  -0.01183, 0.00862,  0.00804,  0.00454,
    0.00204,  -0.00180, -0.00070, -0.00040, -0.00034, 0.00032,
    0.00032,  -0.00028, 0.00027,  -0.00017, -0.00005, 0.00004,
    -0.00004, 0.00004,  0.00003,  0.00003,  0.00002,  0.00002,
    -0.00002
);

Readonly::Array my @A_TERMS => (
    0.000325, 0.000165, 0.000164, 0.000126, 0.000110, 0.000062,
    0.000060, 0.000056, 0.000047, 0.000042, 0.000040, 0.000037,
    0.000035, 0.000023
);

Readonly::Hash our %QUARTER => (
    $NEW_MOON => {
        fraction => 0.0,
        terms    => \@NEW_MOON_TERMS
    },
    $FIRST_QUARTER => {
        fraction => 0.25,
        terms    => \@QUARTER_TERMS
    },
    $FULL_MOON => {
        fraction => 0.5,
        terms    => \@FULL_MOON_TERMS
    },
    $LAST_QUARTER => {
        fraction => 0.75,
        terms    => \@QUARTER_TERMS
    },
);

sub search_event {
    my ( $date, $quarter ) = @_;

    my $q = $QUARTER{$quarter};

    my $n  = is_leapyear($date->[0]) ? 366 : 365;
    my $y  = day_of_year(@$date);
    my $k  = sprintf( '%.0f', ( $y - 2000 ) * 12.3685 ) + $q->{fraction};
    my $t  = $k / 1236.85;
    my $t2 = $t * $t;
    my $t3 = $t2 * $t;
    my $t4 = $t3 * $t;

    # JDE
    my $j =
      2451550.09766 + 29.530588861 * $k +
      0.00015437 * $t2 -
      1.5e-07 * $t3 +
      7.3e-10 * $t4;
    my $E  = 1 - 0.002516 * $t - 7.4e-06 * $t2;
    my $EE = $E * $E;

    # Sun's mean anomaly
    my $MS =
      reduce_deg( 2.5534 + 29.1053567 * $k - 1.4e-06 * $t2 - 1.1e-07 * $t3 );

    # Moon's mean anomaly
    my $MM =
      reduce_deg( 201.5643 + 385.81693528 * $k +
          0.0107582 * $t2 +
          1.238e-05 * $t3 -
          5.8e-08 * $t4 );

    # Moon's argument of latitude
    my $F =
      reduce_deg( 160.7108 + 390.67050284 * $k -
          0.0016118 * $t2 -
          2.27e-06 * $t3 -
          1.1e-08 * $t4 );

    # Longitude of the ascending node
    my $N = reduce_deg(
        124.7746 - 1.56375588 * $k + 0.0020672 * $t2 + 2.15e-06 * $t3 );

    my @A = (
        299.77 + 0.107408 * $k - 0.009173 * $t2,
        251.88 + 0.016321 * $k,
        251.83 + 26.651886 * $k,
        349.42 + 36.412478 * $k,
        84.66 + 18.206239 * $k,
        141.74 + 53.303771 * $k,
        207.14 + 2.453732 * $k,
        154.84 + 7.306860 * $k,
        34.52 + 27.261239 * $k,
        207.19 + 0.121824 * $k,
        291.34 + 1.844379 * $k,
        161.72 + 24.198154 * $k,
        239.56 + 25.513099 * $k,
        331.55 + 3.592518 * $k
    );

    my $mm2 = $MM + $MM;
    my $ms2 = $MS + $MS;
    my $mm3 = $mm2 + $MM;
    my $ms3 = $ms2 + $MS;
    my $f2  = $F + $F;

    my @si = do {
        if ( $quarter eq $NEW_MOON || $quarter eq $FULL_MOON ) {
            (
                $MM,
                $MS,
                $mm2,
                $f2,
                $MM - $MS,
                $MM + $MS,
                $ms2,
                $MM - $f2,
                $MM + $f2,
                $mm2 * $F,
                $mm2 + $MS,
                $mm3,
                $MS + $f2,
                $MS - $f2,
                $mm2 - $MS,
                $N,
                $MM + $ms2,
                $mm2 - $f2,
                $ms3,
                $MM + $MS - $f2,
                $mm2 + $f2,
                $MM + $MS + $f2,
                $MM - $MS + $f2,
                $MM - $MS - $f2,
                $mm3 + $MS,
                $mm2 + $mm2
            )
        }
        else {
            (
                $MM,
                $MS,
                $MM + $MS,
                $mm2,
                $f2,
                $MM - $MS,
                $ms2,
                $MM - $f2,
                $MM + $f2,
                $mm3,
                $mm2 - $MS,
                $MS + $f2,
                $MS - $f2,
                $MM + $ms2,
                $mm2 + $MS,
                $N,
                $MM - $MS - $f2,
                $mm2 + $f2,
                $MM + $MS + $f2,
                $MM - $ms2,
                $MM + $MS - $f2,
                $ms3,
                $mm2 - $f2,
                $MM - $MS + $f2,
                $mm3 + $MS
              )
        }
    };

    my @rsi = map { sin( deg2rad($_) ) } @si;
    my @terms =
      zip_unflatten( @{ $q->{terms} }, @rsi );
    my $s = 0;
    while ( my ( $i, $item ) = each @terms ) {
        my ($x, $y) = @$item;
        if ( $quarter eq $NEW_MOON || $quarter eq $FULL_MOON ) {
            if ( any { $i == $_ } ( 1, 4, 5, 9, 11, 12, 13 ) ) {
                $x *= $E;
            }
            elsif ( $i == 6 ) {
                $x *= $EE;
            }
        }
        else {
            if ( any { $i == $_ } ( 1, 2, 5, 10, 11, 12, 14 ) ) {
                $x *= $E;
            }
            elsif ( $i = 6 || $i == 13 ) {
                $x *= $EE;
            }
        }
        $s += $x * $y;
    }
    $j += $s;

    if ( $quarter eq $FIRST_QUARTER || $quarter eq $LAST_QUARTER ) {
        my ( $mm, $ms, $f ) = map { deg2rad($_) } ( $MM, $MS, $F );
        my $w =
          0.00306 - 0.00038 * cos($ms) +
          0.00026 * cos($mm) -
          2e-05 * cos( $ms + $mm ) +
          2e-05 * cos( $f + $f );
        $w = -$w if $quarter eq $LAST_QUARTER;
        $j += $w;
    }

    $s = reduce {
        $a + $b->[1] + sin( deg2rad( $b->[0] ) )
    } 0, zip_unflatten( @A, @A_TERMS );
    $j += $s;

    $j
}

1;
__END__


=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Lunation - Lunar quarters.

=head1 SYNOPSIS

  use Astro::Montenbruck::Lunation qw/:all/;

  # find instant of New Moon closest to 2019 Aug, 12
  $jd = search_event(date => [2019, 8, 12], quarter => $NEW_MOON)

  # find instant of Full Moon after the given date
  $jd = search_quarter(
      date      => [2019, 8, 12],
      phase     => $FULL_MOON,
      direction => $FORWARD
  );


=head1 DESCRIPTION

Searches lunar quarters.

=head1 EXPORT

=head2 CONSTANTS

=head3 QUARTERS

=over

=item * C<$NEW_MOON>

=item * C<$FIRST_QUARTER>

=item * C<$FULL_MOON>

=item * C<$LAST_QUARTER>

=back


=head1 SUBROUTINES

=head2 search_event(date => $arr, quarter => $scalar)

Calculate instant of apparent lunar phase closest to the given date.

=head3 Named Arguments

=over

=item * B<date> — array of B<year> (astronomical, zero-based), B<month> [1..12]
and B<day>, [1..31].

=item * B<quarter> — which quarter, one of: C<$NEW_MOON>, C<$FIRST_QUARTER>,
C<$FULL_MOON> or C<$LAST_QUARTER> see L</QUARTERS>.

=back

=head3 Returns

I<Standard Julian day> of the event. dynamic time.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
