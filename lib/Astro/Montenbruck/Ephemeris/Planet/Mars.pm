package Astro::Montenbruck::Ephemeris::Planet::Mars;

use strict;
use warnings;

use base qw/Astro::Montenbruck::Ephemeris::Planet/;

use Math::Trig qw/:pi/;
use Astro::Montenbruck::Ephemeris::Pert qw /pert/;
use Astro::Montenbruck::MathUtils qw /frac ARCS/;
use Astro::Montenbruck::Ephemeris::Planet qw/$MA/;

our $VERSION = 0.01;

sub new {
    my $class = shift;
    $class->SUPER::new( id => $MA );
}

sub heliocentric {
    my ( $self, $t ) = @_;

    # Mean anomalies of planets in [rad]
    my $m2 = pi2 * frac( 0.1382208 + 162.5482542 * $t );
    my $m3 = pi2 * frac( 0.9926208 + 99.9970236 * $t );
    my $m4 = pi2 * frac( 0.0538553 + 53.1662736 * $t );
    my $m5 = pi2 * frac( 0.0548944 + 8.4290611 * $t );
    my $m6 = pi2 * frac( 0.8811167 + 3.3935250 * $t );

    my ( $dl, $dr, $db ) = ( 0, 0, 0 );    # Corrections in longitude ["],
    my $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

    # Perturbations by Venus
    my $term = pert(
        T        => $t,
        M        => $m4,
        m        => $m2,
        I_min    => 0,
        I_max    => 7,
        i_min    => -2,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( 0, -1, 0, -0.01, -0.03, 0.10,  -0.04, 0.00,  0.00 );
    $term->( 1, -1, 0, 0.05,  0.10,  -2.08, 0.75,  0.00,  0.00 );
    $term->( 2, -1, 0, -0.25, -0.57, -2.58, 1.18,  0.05,  -0.04 );
    $term->( 2, -2, 0, 0.02,  0.02,  0.13,  -0.14, 0.00,  0.00 );
    $term->( 3, -1, 0, 3.41,  5.38,  1.87,  -1.15, 0.01,  -0.01 );
    $term->( 3, -2, 0, 0.02,  0.02,  0.11,  -0.13, 0.00,  0.00 );
    $term->( 4, -1, 0, 0.32,  0.49,  -1.88, 1.21,  -0.07, 0.07 );
    $term->( 4, -2, 0, 0.03,  0.03,  0.12,  -0.14, 0.00,  0.00 );
    $term->( 5, -1, 0, 0.04,  0.06,  -0.17, 0.11,  -0.01, 0.01 );
    $term->( 5, -2, 0, 0.11,  0.09,  0.35,  -0.43, -0.01, 0.01 );
    $term->( 6, -2, 0, -0.36, -0.28, -0.20, 0.25,  0.00,  0.00 );
    $term->( 7, -2, 0, -0.03, -0.03, 0.11,  -0.13, 0.00,  -0.01 );

    # Keplerian motion and perturbations by the Earth
    $term = pert(
        T        => $t,
        M        => $m4,
        m        => $m3,
        I_min    => -1,
        I_max    => 16,
        i_min    => -9,
        i_max    => 0,
        callback => $pert_cb
    );

    $term->( 1,  0,  0, -5.32, 38481.97, -141856.04, 0.40,  -6321.67, 1876.89 );
    $term->( 1,  0,  1, -1.12, 37.98,    -138.67,    -2.93, 37.28,    117.48 );
    $term->( 1,  0,  2, -0.32, -0.03,    0.12,       -1.19, 1.04,     -0.40 );
    $term->( 2,  0,  0, 28.28, 2285.80,  -6608.37,   0.00,  -589.35,  174.81 );
    $term->( 2,  0,  1, 1.64,  3.37,     -12.93,     0.00,  2.89,     11.10 );
    $term->( 2,  0,  2, 0.00,  0.00,     0.00,       0.00,  0.10,     -0.03 );
    $term->( 3,  0,  0, 5.31,  189.29,   -461.81,    0.00,  -61.98,   18.53 );
    $term->( 3,  0,  1, 0.31,  0.35,     -1.36,      0.00,  0.25,     1.19 );
    $term->( 4,  0,  0, 0.81,  17.96,    -38.26,     0.00,  -6.88,    2.08 );
    $term->( 4,  0,  1, 0.05,  0.04,     -0.15,      0.00,  0.02,     0.14 );
    $term->( 5,  0,  0, 0.11,  1.83,     -3.48,      0.00,  -0.79,    0.24 );
    $term->( 6,  0,  0, 0.02,  0.20,     -0.34,      0.00,  -0.09,    0.03 );
    $term->( -1, -1, 0, 0.09,  0.06,     0.14,       -0.22, 0.02,     -0.02 );
    $term->( 0,  -1, 0, 0.72,  0.49,     1.55,       -2.31, 0.12,     -0.10 );
    $term->( 1,  -1, 0, 7.00,  4.92,  13.93, -20.48, 0.08,  -0.13 );
    $term->( 2,  -1, 0, 13.08, 4.89,  -4.53, 10.01,  -0.05, 0.13 );
    $term->( 2,  -2, 0, 0.14,  0.05,  -0.48, -2.66,  0.01,  0.14 );
    $term->( 3,  -1, 0, 1.38,  0.56,  -2.00, 4.85,   -0.01, 0.19 );
    $term->( 3,  -2, 0, -6.85, 2.68,  8.38,  21.42,  0.00,  0.03 );
    $term->( 3,  -3, 0, -0.08, 0.20,  1.20,  0.46,   0.00,  0.00 );
    $term->( 4,  -1, 0, 0.16,  0.07,  -0.19, 0.47,   -0.01, 0.05 );
    $term->( 4,  -2, 0, -4.41, 2.14,  -3.33, -7.21,  -0.07, -0.09 );
    $term->( 4,  -3, 0, -0.12, 0.33,  2.22,  0.72,   -0.03, -0.02 );
    $term->( 4,  -4, 0, -0.04, -0.06, -0.36, 0.23,   0.00,  0.00 );
    $term->( 5,  -2, 0, -0.44, 0.21,  -0.70, -1.46,  -0.06, -0.07 );
    $term->( 5,  -3, 0, 0.48,  -2.60, -7.25, -1.37,  0.00,  0.00 );
    $term->( 5,  -4, 0, -0.09, -0.12, -0.66, 0.50,   0.00,  0.00 );
    $term->( 5,  -5, 0, 0.03,  0.00,  0.01,  -0.17,  0.00,  0.00 );
    $term->( 6,  -2, 0, -0.05, 0.03,  -0.07, -0.15,  -0.01, -0.01 );
    $term->( 6,  -3, 0, 0.10,  -0.96, 2.36,  0.30,   0.04,  0.00 );
    $term->( 6,  -4, 0, -0.17, -0.20, -1.09, 0.94,   0.02,  -0.02 );
    $term->( 6,  -5, 0, 0.05,  0.00,  0.00,  -0.30,  0.00,  0.00 );
    $term->( 7,  -3, 0, 0.01,  -0.10, 0.32,  0.04,   0.02,  0.00 );
    $term->( 7,  -4, 0, 0.86,  0.77,  1.86,  -2.01,  0.01,  -0.01 );
    $term->( 7,  -5, 0, 0.09,  -0.01, -0.05, -0.44,  0.00,  0.00 );
    $term->( 7,  -6, 0, -0.01, 0.02,  0.10,  0.08,   0.00,  0.00 );
    $term->( 8,  -4, 0, 0.20,  0.16,  -0.53, 0.64,   -0.01, 0.02 );
    $term->( 8,  -5, 0, 0.17,  -0.03, -0.14, -0.84,  0.00,  0.01 );
    $term->( 8,  -6, 0, -0.02, 0.03,  0.16,  0.09,   0.00,  0.00 );
    $term->( 9,  -5, 0, -0.55, 0.15,  0.30,  1.10,   0.00,  0.00 );
    $term->( 9,  -6, 0, -0.02, 0.04,  0.20,  0.10,   0.00,  0.00 );
    $term->( 10, -5, 0, -0.09, 0.03,  -0.10, -0.33,  0.00,  -0.01 );
    $term->( 10, -6, 0, -0.05, 0.11,  0.48,  0.21,   -0.01, 0.00 );
    $term->( 11, -6, 0, 0.10,  -0.35, -0.52, -0.15,  0.00,  0.00 );
    $term->( 11, -7, 0, -0.01, -0.02, -0.10, 0.07,   0.00,  0.00 );
    $term->( 12, -6, 0, 0.01,  -0.04, 0.18,  0.04,   0.01,  0.00 );
    $term->( 12, -7, 0, -0.05, -0.07, -0.29, 0.20,   0.01,  0.00 );
    $term->( 13, -7, 0, 0.23,  0.27,  0.25,  -0.21,  0.00,  0.00 );
    $term->( 14, -7, 0, 0.02,  0.03,  -0.10, 0.09,   0.00,  0.00 );
    $term->( 14, -8, 0, 0.05,  0.01,  0.03,  -0.23,  0.00,  0.03 );
    $term->( 15, -8, 0, -1.53, 0.27,  0.06,  0.42,   0.00,  0.00 );
    $term->( 16, -8, 0, -0.14, 0.02,  -0.10, -0.55,  -0.01, -0.02 );
    $term->( 16, -9, 0, 0.03,  -0.06, -0.25, -0.11,  0.00,  0.00 );

    # Perturbations by Mars
    $term = pert(
        T        => $t,
        M        => $m4,
        m        => $m5,
        I_min    => -2,
        I_max    => 5,
        i_min    => -5,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( -2, -1, 0, 0.05,   0.03,   0.08,   -0.14,  0.01,  -0.01 );
    $term->( -1, -1, 0, 0.39,   0.27,   0.92,   -1.50,  -0.03, -0.06 );
    $term->( -1, -2, 0, -0.16,  0.03,   0.13,   0.67,   -0.01, 0.06 );
    $term->( -1, -3, 0, -0.02,  0.01,   0.05,   0.09,   0.00,  0.01 );
    $term->( 0,  -1, 0, 3.56,   1.13,   -5.41,  -7.18,  -0.25, -0.24 );
    $term->( 0,  -2, 0, -1.44,  0.25,   1.24,   7.96,   0.02,  0.31 );
    $term->( 0,  -3, 0, -0.21,  0.11,   0.55,   1.04,   0.01,  0.05 );
    $term->( 0,  -4, 0, -0.02,  0.02,   0.11,   0.11,   0.00,  0.01 );
    $term->( 1,  -1, 0, 16.67,  -19.15, 61.00,  53.36,  -0.06, -0.07 );
    $term->( 1,  -2, 0, -21.64, 3.18,   -7.77,  -54.64, -0.31, 0.50 );
    $term->( 1,  -3, 0, -2.82,  1.45,   -2.53,  -5.73,  0.01,  0.07 );
    $term->( 1,  -4, 0, -0.31,  0.28,   -0.34,  -0.51,  0.00,  0.00 );
    $term->( 2,  -1, 0, 2.15,   -2.29,  7.04,   6.94,   0.33,  0.19 );
    $term->( 2,  -2, 0, -15.69, 3.31,   -15.70, -73.17, -0.17, -0.25 );
    $term->( 2,  -3, 0, -1.73,  1.95,   -9.19,  -7.20,  0.02,  -0.03 );
    $term->( 2,  -4, 0, -0.01,  0.33,   -1.42,  0.08,   0.01,  -0.01 );
    $term->( 2,  -5, 0, 0.03,   0.03,   -0.13,  0.12,   0.00,  0.00 );
    $term->( 3,  -1, 0, 0.26,   -0.28,  0.73,   0.71,   0.08,  0.04 );
    $term->( 3,  -2, 0, -2.06,  0.46,   -1.61,  -6.72,  -0.13, -0.25 );
    $term->( 3,  -3, 0, -1.28,  -0.27,  2.21,   -6.90,  -0.04, -0.02 );
    $term->( 3,  -4, 0, -0.22,  0.08,   -0.44,  -1.25,  0.00,  0.01 );
    $term->( 3,  -5, 0, -0.02,  0.03,   -0.15,  -0.08,  0.00,  0.00 );
    $term->( 4,  -1, 0, 0.03,   -0.03,  0.08,   0.08,   0.01,  0.01 );
    $term->( 4,  -2, 0, -0.26,  0.06,   -0.17,  -0.70,  -0.03, -0.05 );
    $term->( 4,  -3, 0, -0.20,  -0.05,  0.22,   -0.79,  -0.01, -0.02 );
    $term->( 4,  -4, 0, -0.11,  -0.14,  0.93,   -0.60,  0.00,  0.00 );
    $term->( 4,  -5, 0, -0.04,  -0.02,  0.09,   -0.23,  0.00,  0.00 );
    $term->( 5,  -4, 0, -0.02,  -0.03,  0.13,   -0.09,  0.00,  0.00 );
    $term->( 5,  -5, 0, 0.00,   -0.03,  0.21,   0.01,   0.00,  0.00 );

    # Perturbations by Saturn
    $term = pert(
        T        => $t,
        M        => $m4,
        m        => $m6,
        I_min    => -1,
        I_max    => 3,
        i_min    => -4,
        i_max    => -1,
        callback => $pert_cb
    );

    $term->( -1, -1, 0, 0.03, 0.13,  0.48,  -0.13, 0.02,  0.00 );
    $term->( 0,  -1, 0, 0.27, 0.84,  0.40,  -0.43, 0.01,  -0.01 );
    $term->( 0,  -2, 0, 0.12, -0.04, -0.33, -0.55, -0.01, -0.02 );
    $term->( 0,  -3, 0, 0.02, -0.01, -0.07, -0.08, 0.00,  0.00 );
    $term->( 1,  -1, 0, 1.12, 0.76,  -2.66, 3.91,  -0.01, 0.01 );
    $term->( 1,  -2, 0, 1.49, -0.95, 3.07,  4.83,  0.04,  -0.05 );
    $term->( 1,  -3, 0, 0.21, -0.18, 0.55,  0.64,  0.00,  0.00 );
    $term->( 2,  -1, 0, 0.12, 0.10,  -0.29, 0.34,  -0.01, 0.02 );
    $term->( 2,  -2, 0, 0.51, -0.36, 1.61,  2.25,  0.03,  0.01 );
    $term->( 2,  -3, 0, 0.10, -0.10, 0.50,  0.43,  0.00,  0.00 );
    $term->( 2,  -4, 0, 0.01, -0.02, 0.11,  0.05,  0.00,  0.00 );
    $term->( 3,  -2, 0, 0.07, -0.05, 0.16,  0.22,  0.01,  0.01 );

    # Ecliptic coordinates ([rad],[AU])
    $dl +=
      +52.49 * sin( pi2 * ( 0.1868 + 0.0549 * $t ) ) +
      0.61 * sin( pi2 * ( 0.9220 + 0.3307 * $t ) ) +
      0.32 * sin( pi2 * ( 0.4731 + 2.1485 * $t ) ) +
      0.28 * sin( pi2 * ( 0.9467 + 0.1133 * $t ) );
    $dl += +0.14 + 0.87 * $t - 0.11 * $t * $t;

    my $l =
      pi2 *
      frac( 0.9334591 + $m4 / pi2 +
          ( ( 6615.5 + 1.1 * $t ) * $t + $dl ) / 1296.0E3 );
    my $r = 1.5303352 + 0.0000131 * $t + $dr * 1.0E-6;
    my $b = ( 596.32 + ( -2.92 - 0.10 * $t ) * $t + $db ) / ARCS;

    $l, $b, $r;
}

# Intermediate variables for calculating geocentric positions.
sub _lbr_geo {
    my ( $self, $t ) = @_;

    my $m   = pi2 * frac( 0.0538553 + 53.1662736 * $t );
    my $c2m = cos( 2 * $m );
    my $sm  = sin($m);
    my $cm  = cos($m);

    my $dl = 91.50 + 17.07 * $cm + 2.03 * $c2m;
    my $dr = 12.98 * $sm + 1.21 * $c2m;
    my $db = 0.83 * $cm + 2.80 * $sm;

    $dl, $db, $dr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet::Mars  - Mars.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Planet::Mars;
  my $planet = Astro::Montenbruck::Ephemeris::Planet::Mars->new();
  my @geo = $planet->position($t); # apparent geocentric ecliptical coordinates

=head1 DESCRIPTION

Child class of L<Astro::Montenbruck::Ephemeris::Planet>, responsible for calculating
B<Mars> position.

=head1 METHODS

=head2 Astro::Montenbruck::Ephemeris::Planet::Mars->new

Constructor.

=head2 $self->heliocentric($t)

See description in L<Astro::Montenbruck::Ephemeris::Planet>.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2022 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
