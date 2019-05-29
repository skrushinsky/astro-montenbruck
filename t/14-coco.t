#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = '1.00';

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::Simple tests => 4;
use Astro::Montenbruck::MathUtils qw/dms/;

use Astro::Montenbruck::CoCo qw/ecl2equ equ2ecl/;

{
	# equator <-> ecliptic conversion
	my $alpha = 116.328942;
	my $delta = 28.026183;
	my $epsilon = 23.4392911;

	my ($lambda, $beta) = equ2ecl( $alpha, $delta, $epsilon);
	my ($r1, $r2) = map { sprintf("%.5f", $_) } ($lambda, $beta);
	ok($r1 eq '113.21563', 'equ2ecl: lambda');
	ok($r2 eq '6.68417', 'equ2ecl: beta');

    my ($alpha1, $delta1) = ecl2equ( $lambda, $beta, $epsilon);
    my ($r3, $r4) = map { sprintf("%.6f", $_) } ($alpha1, $delta1);
    ok($r3 eq '116.328942', 'ecl2equ: alpha');
    ok($r4 eq '28.026183', 'ecl2equ: delta');

}
