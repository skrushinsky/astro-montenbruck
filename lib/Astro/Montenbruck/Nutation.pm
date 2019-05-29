package Astro::Montenbruck::Nutation;

use warnings;
use strict;
use Data::Dumper;

our $VERSION = '1.00';

use Exporter qw/import/;
use Readonly;

our %EXPORT_TAGS = (
    all     => [ qw/nut_lon nut_obl ecl_obl/ ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

use Astro::Montenbruck::MathUtils qw/ddd reduce_rad polynome/;
use Math::Trig qw/deg2rad/;

#
# Constant terms.
#

Readonly::Array our @TABLE => (
    [ 0,  0,  0,  0,  1, -171996, -1742, 92025,  89 ],
    [-2,  0,  0,  2,  2,  -13187,   -16,  5736, -31 ],
    [ 0,  0,  0,  2,  2,   -2274,    -2,   977,  -5 ],
    [ 0,  0,  0,  0,  2,    2062,     2,  -895,   5 ],
    [ 0,  1,  0,  0,  0,    1426,   -34,    54,  -1 ],
    [ 0,  0,  1,  0,  0,     712,     1,    -7,   0 ],
    [-2,  1,  0,  2,  2,    -517,    12,   224,  -6 ],
    [ 0,  0,  0,  2,  1,    -386,    -4,   200,   0 ],
    [ 0,  0,  1,  2,  2,    -301,     0,   129,  -1 ],
    [-2, -1,  0,  2,  2,     217,    -5,   -95,   3 ],
    [-2,  0,  1,  0,  0,    -158,     0,     0,   0 ],
    [-2,  0,  0,  2,  1,     129,     1,   -70,   0 ],
    [ 0,  0, -1,  2,  2,     123,     0,   -53,   0 ],
    [ 2,  0,  0,  0,  0,      63,     0,     0,   0 ],
    [ 0,  0,  1,  0,  1,      63,     1,   -33,   0 ],
    [ 2,  0, -1,  2,  2,     -59,     0,    26,   0 ],
    [ 0,  0, -1,  0,  1,     -58,    -1,    32,   0 ],
    [ 0,  0,  1,  2,  1,     -51,     0,    27,   0 ],
    [-2,  0,  2,  0,  0,      48,     0,     0,   0 ],
    [ 0,  0, -2,  2,  1,      46,     0,   -24,   0 ],
    [ 2,  0,  0,  2,  2,     -38,     0,    16,   0 ],
    [ 0,  0,  2,  2,  2,     -31,     0,    13,   0 ],
    [ 0,  0,  2,  0,  0,      29,     0,     0,   0 ],
    [-2,  0,  1,  2,  2,      29,     0,   -12,   0 ],
    [ 0,  0,  0,  2,  0,      26,     0,     0,   0 ],
    [-2,  0,  0,  2,  0,     -22,     0,     0,   0 ],
    [ 0,  0, -1,  2,  1,      21,     0,   -10,   0 ],
    [ 0,  2,  0,  0,  0,      17,    -1,     0,   0 ],
    [ 2,  0, -1,  0,  1,      16,     0,    -8,   0 ],
    [-2,  2,  0,  2,  2,     -16,     1,     7,   0 ],
    [ 0,  1,  0,  0,  1,     -15,     0,     9,   0 ],
    [-2,  0,  1,  0,  1,     -13,     0,     7,   0 ],
    [ 0, -1,  0,  0,  1,     -12,     0,     6,   0 ],
    [ 0,  0,  2, -2,  0,      11,     0,     0,   0 ],
    [ 2,  0, -1,  2,  1,     -10,     0,     5,   0 ],
    [ 2,  0,  1,  2,  2,      -8,     0,     3,   0 ],
    [ 0,  1,  0,  2,  2,       7,     0,    -3,   0 ],
    [-2,  1,  1,  0,  0,      -7,     0,     0,   0 ],
    [ 0, -1,  0,  2,  2,      -7,     0,     3,   0 ],
    [ 2,  0,  0,  2,  1,      -7,     0,     3,   0 ],
    [ 2,  0,  1,  0,  0,       6,     0,     0,   0 ],
    [-2,  0,  2,  2,  2,       6,     0,    -3,   0 ],
    [-2,  0,  1,  2,  1,       6,     0,    -3,   0 ],
    [ 2,  0, -2,  0,  1,      -6,     0,     3,   0 ],
    [ 2,  0,  0,  0,  1,      -6,     0,     3,   0 ],
    [ 0, -1,  1,  0,  0,       5,     0,     0,   0 ],
    [-2, -1,  0,  2,  1,      -5,     0,     3,   0 ],
    [-2,  0,  0,  0,  1,      -5,     0,     3,   0 ],
    [ 0,  0,  2,  2,  1,      -5,     0,     3,   0 ],
    [-2,  0,  2,  0,  1,       4,     0,     0,   0 ],
    [-2,  1,  0,  2,  1,       4,     0,     0,   0 ],
    [ 0,  0,  1, -2,  0,       4,     0,     0,   0 ],
    [-1,  0,  1,  0,  0,      -4,     0,     0,   0 ],
    [-2,  1,  0,  0,  0,      -4,     0,     0,   0 ],
    [ 1,  0,  0,  0,  0,      -4,     0,     0,   0 ],
    [ 0,  0,  1,  2,  0,       3,     0,     0,   0 ],
    [ 0,  0, -2,  2,  2,      -3,     0,     0,   0 ],
    [-1, -1,  1,  0,  0,      -3,     0,     0,   0 ],
    [ 0,  1,  1,  0,  0,      -3,     0,     0,   0 ],
    [ 0, -1,  1,  2,  2,      -3,     0,     0,   0 ],
    [ 2, -1, -1,  2,  2,      -3,     0,     0,   0 ],
    [ 0,  0,  3,  2,  2,      -3,     0,     0,   0 ],
    [ 2, -1,  0,  2,  2,      -3,     0,     0,   0 ]
);

Readonly::Array our @KD
    => map { deg2rad $_ , 1} (297.85036, 445267.111480, -0.0019142, 1.0/189474);
Readonly::Array our @KM
    => map { deg2rad $_, 1 } (357.52772, 35999.050340, -0.0001603, -1.0/300000);
Readonly::Array our @KM1
    => map { deg2rad $_, 1 } (134.96298, 477198.867398, 0.0086972, 1.0/ 56250);
Readonly::Array our @KF
    => map { deg2rad $_, 1 } (93.27191,  483202.017538, -0.0036825, 1.0/327270);
Readonly::Array our @KO
    => map { deg2rad $_, 1 } (125.04452, -1934.136261, 0.0020708, 1.0/450000);

# Terms for calculating ecliptic obliquity in radians
Readonly::Array our @ETERMS
    => map { deg2rad(ddd(@$_)) }
        ([23, 26,  21.448], [0, 0, -4680.93], [0, 0,  -1.55], [0, 0, 1999.25],
         [ 0,  0, -51.38 ], [0, 0,  -249.67], [0, 0, -39.05], [0, 0,    7.12],
         [ 0,  0,  27.87 ], [0, 0,     5.79], [0, 0,   2.45]);



sub _iter_table {
    my ($t, $callback) = @_;


    print Dumper([$t, \@KD, polynome($t, @KD)]);

    my ($D, $M, $M1, $F, $omega)
        = map { reduce_rad(polynome($t, @$_)) } (\@KD, \@KM, \@KM1, \@KF, \@KO);

    # Astrolabe: 2.39044329248 1.65769978124 4.00166320529 2.50294014427 0.196403352891
    for (my $i = 0; $i < @TABLE; $i++) {
        my ($tD, $tM, $tM1, $tF, $tomega, $tpsiK, $tpsiT, $tepsK, $tepsT) = @{$TABLE[$i]};
        my $arg = $D * $tD + $M * $tM + $M1 * $tM1 + $F * $tF + $omega * $tomega; # 0.19640335289105515
        my $x = $tpsiK / 10000.0 + $tpsiT / 100000.0 * $t;
        $callback->($x, $arg);
    }
}

sub nut_lon {
    my $t = shift;
    my $delta_psi = 0;
    _iter_table(
        $t,
        sub {
            my ($x, $arg) = @_;
            $delta_psi += $x * sin($arg);
        }
    );
    $delta_psi /= 3600;
    deg2rad( $delta_psi );
}

sub nut_obl {
    my $t = shift;
    my $delta_eps = 0;
    _iter_table(
        $t,
        sub {
            my ($x, $arg) = @_;
            $delta_eps += $x * cos($arg);
        }
    );

    $delta_eps /= 3600;
    deg2rad( $delta_eps );
}

sub ecl_obl {
    my $t = shift;
    polynome($t / 100, @ETERMS)
}


1; # End of Astro::Montenbruck::Nutation

__END__

=head1 NAME

Astro::Montenbruck::Nutation - nutation and obliquity of ecliptic

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Astro::Montenbruck::Nutation qw/:all/;

    $delta_psi = nut_lon($t); # nutation in longitude
    $delta_eps = nut_obl($t); # nutation in ecliptic obliquity
    $epsilon = ecl_obl($t); # obliquity of ecliptic
    ...

=head1 EXPORT

=over

=item * L</$delta_psi = nut_lon($t)>

=item * L</$delta_eps = nut_obl($t)>

=item * L</$epsilon = ecl_obl($t)>

=back

=head1 SUBROUTINES/METHODS

=head2 $delta_psi = nut_lon($t)

Nutation in longitude (radians)

=head2 $delta_eps = nut_obl($t)

Nutation in obliquity (radians)

=head2 $epsilon = ecl_obl($t)

Obliquity of ecliptic in radians. Accuracy is 0.01" between 1000 and 3000,
and a few arc-seconds after 10,000 years.

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2019 Sergey Krushinsky.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
