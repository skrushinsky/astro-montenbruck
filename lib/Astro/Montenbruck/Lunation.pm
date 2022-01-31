package Astro::Montenbruck::Lunation;

use strict;
use warnings;

use Exporter qw/import/;
use Readonly;
use Math::Trig qw/deg2rad rad2deg/;

use Astro::Montenbruck::Time qw/is_leapyear day_of_year $J1900/;
use Astro::Montenbruck::MathUtils qw/reduce_deg/;

Readonly our $NEW_MOON      => 'New Moon';
Readonly our $FIRST_QUARTER => 'First Quarter';
Readonly our $FULL_MOON     => 'Full Moon';
Readonly our $LAST_QUARTER  => 'Last Quarter';

Readonly::Array our @MONTH =>
  ( $NEW_MOON, $FIRST_QUARTER, $FULL_MOON, $LAST_QUARTER );
Readonly our @QUARTERS =>
  qw/$NEW_MOON $FIRST_QUARTER $FULL_MOON $LAST_QUARTER @MONTH/;

my @funcs = qw/mean_phase search_event/;

our %EXPORT_TAGS = (
    quarters  => \@QUARTERS,
    functions => \@funcs,
    all       => [ @QUARTERS, @funcs ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION   = 1.00;

Readonly::Hash our %COEFFS => (
    $NEW_MOON      => 0.0,
    $FIRST_QUARTER => 0.25,
    $FULL_MOON     => 0.5,
    $LAST_QUARTER  => 0.75,
);

sub mean_phase {
    my ( $frac, $ye, $mo, $da ) = @_;
    sprintf( '%.0f', ( $ye - 1900 ) * 12.3685 ) + $frac;
}

# Calculates delta for Full and New Moon.
sub nf_delta {
    my ( $t, $ms, $mm, $tms, $tmm, $tf ) = @_;

    ( 1.734e-1 - 3.93e-4 * $t ) * sin($ms) +
      2.1e-3 * sin($tms) -
      4.068e-1 * sin($mm) +
      1.61e-2 * sin($tmm) -
      4e-4 * sin( $mm + $tmm ) +
      1.04e-2 * sin($tf) -
      5.1e-3 * sin( $ms + $mm ) -
      7.4e-3 * sin( $ms - $mm ) +
      4e-4 * sin( $tf + $ms ) -
      4e-4 * sin( $tf - $ms ) -
      6e-4 * sin( $tf + $mm ) +
      1e-3 * sin( $tf - $mm ) +
      5e-4 * sin( $ms + $tmm );
}

# Calculates delta for First ans Last quarters .
sub fl_delta {
    my ( $t, $ms, $mm, $tms, $tmm, $tf ) = @_;

    ( 0.1721 - 0.0004 * $t ) * sin($ms) +
      0.0021 * sin($tms) -
      0.6280 * sin($mm) +
      0.0089 * sin($tmm) -
      0.0004 * sin( $tmm + $mm ) +
      0.0079 * sin($tf) -
      0.0119 * sin( $ms + $mm ) -
      0.0047 * sin( $ms - $mm ) +
      0.0003 * sin( $tf + $ms ) -
      0.0004 * sin( $tf - $ms ) -
      0.0006 * sin( $tf + $mm ) +
      0.0021 * sin( $tf - $mm ) +
      0.0003 * sin( $ms + $tmm ) +
      0.0004 * sin( $ms - $tmm ) -
      0.0003 * sin( $tms + $mm );
}

sub search_event {
    my ( $date, $quarter ) = @_;
    my ( $ye, $mo, $da ) = @$date;

    my $k = mean_phase( $COEFFS{$quarter}, @$date );

    my $t1 = $k / 1236.85;
    my $t2 = $t1 * $t1;
    my $t3 = $t2 * $t1;

    my $c = deg2rad( 166.56 + ( 132.87 - 9.173e-3 * $t1 ) * $t1 );

    # time of the mean phase
    my $j =
      0.75933 + 29.53058868 * $k +
      0.0001178 * $t2 -
      1.55e-07 * $t3 +
      3.3e-4 * sin($c);

    my $assemble = sub {
        deg2rad( reduce_deg( $_[0] + $_[1] * $k + $_[2] * $t2 + $_[3] * $t3 ) );
    };

    my $ms    = $assemble->( 359.2242, 29.105356080, -0.0000333, -0.00000347 );
    my $mm    = $assemble->( 306.0253, 385.81691806, 0.0107306,  0.00001236 );
    my $f     = $assemble->( 21.2964,  390.67050646, -0.0016528, -0.00000239 );
    my $delta = do {
        my $tms = $ms + $ms;
        my $tmm = $mm + $mm;
        my $tf  = $f + $f;
        if ( $quarter eq $NEW_MOON || $quarter eq $FULL_MOON ) {
            nf_delta( $t1, $ms, $mm, $tms, $tmm, $tf );
        }
        else {
            my $w = 0.0028 - 0.0004 * cos($ms) + 0.0003 * cos($ms);
            $w = -$w if $quarter eq $LAST_QUARTER;
            fl_delta( $t1, $ms, $mm, $tms, $tmm, $tf ) + $w;
        }
    };
    $j + $delta + $J1900;
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
  $jd = search_event([2019, 8, 12], $NEW_MOON)


=head1 DESCRIPTION

Searches lunar quarters. Algorithms are based on
I<"Astronomical Algorithms"> by I<Jean Meeus>, I<Second Edition>, I<Willmann-Bell, Inc., 1998>.


=head1 EXPORT

=head2 CONSTANTS

=head3 QUARTERS

=over

=item * C<$NEW_MOON>

=item * C<$FIRST_QUARTER>

=item * C<$FULL_MOON>

=item * C<$LAST_QUARTER>

=back

=head3 MONTH

=over

=item * C<@MONTH> 

=back

Array of L<QUARTERS> in proper order.


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

In scalar context returns I<Standard Julian day> of the event, dynamic time.

In list context:

=over

=item * I<Standard Julian day> of the event, dynamic time.

=item * Argument of latitude, arc-degrees. This value is required for detecting elipses.

=back



=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2021 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
