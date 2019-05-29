package Astro::Montenbruck::CoCo;

use strict;
use warnings;
use Exporter qw/import/;
use POSIX qw /tan atan2 asin/;
use Astro::Montenbruck::MathUtils qw/reduce_rad/;
use Math::Trig qw/deg2rad rad2deg/;
use Readonly;

Readonly::Scalar our $ECL => 1;
Readonly::Scalar our $EQU => 2;

our @EXPORT_OK = qw/ecl2equ equ2ecl $ECL $EQU/;

our $VERSION = '1.00';

# Common routine for coordinate conversion
# $target = EQU_TO_ECL ( 1) for equator -> ecliptic
# $target = ECL_TO_EQU (-1) for ecliptic -> equator
sub _equ_ecl {
    my ( $x, $y, $e, $target ) = @_;
    my $k = $target == $ECL ? 1
                            : $target == $EQU ? -1 : 0;
    die "Unknown target: '$target'! \n" until $k;

    my $sin_a = sin($x);
    my $cos_e = cos($e);
    my $sin_e = sin($e);
    reduce_rad(atan2( $sin_a * $cos_e + $k * ( tan($y) * $sin_e ), cos($x) )),
      asin( sin($y) * $cos_e - $k * ( cos($y) * $sin_e * $sin_a ) );
}


sub equ2ecl {
    map { rad2deg $_ } _equ_ecl( ( map { deg2rad $_ } @_ ), $ECL );
}

sub ecl2equ {
    map { rad2deg $_ } _equ_ecl( ( map { deg2rad $_ } @_ ), $EQU );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::CoCo - Coordinates conversions.

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Celestial sphera related calculations used by AstroScript modules.

=head1 EXPORT

=over

=item * L</equ2ecl($alpha, $delta, $epsilon)>

=item * L</ecl2equ($lambda, $beta, $epsilon)>

=back

=head1 FUNCTIONS

=head2 equ2ecl($alpha, $delta, $epsilon)

Conversion of equatorial into ecliptic coordinates

=head3 Arguments

=over

=item * B<$alpha> — right ascension

=item * B<$delta> — declination

=item * B<$epsilon> — ecliptic obliquity

=back

=head3 Returns

Ecliptic coordinates:

=over

=item * B<$lambda>

=item * B<$beta>

=back

All arguments and return values are in degrees.

=head2 ecl2equ($lambda, $beta, $epsilon)

Conversion of ecliptic into equatorial coordinates

=head3 Arguments

=over

=item * B<$lambda> — celestial longitude

=item * B<$beta> — celestial latitude

=item * B<$epsilon> — ecliptic obliquity

=back

=head3 Returns

Equatorial coordinates:

=over

=item * B<$alpha> — right ascension

=item * B<$delta> — declination

=back

All arguments and return values are in degrees.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Astro::Montenbruck::CoCo

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
