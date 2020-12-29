#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More tests => 4;
use Test::Number::Delta within => 1e-4;
use Astro::Montenbruck::NutEqu qw/mean2true/;
use Astro::Montenbruck::Ephemeris::Planet qw/true2apparent/;

BEGIN {
	use_ok( 'Astro::Montenbruck::Ephemeris::Planet::Sun' );
}

my $sun = new_ok('Astro::Montenbruck::Ephemeris::Planet::Sun');


# Meeus, "Astronomical Algoryhms", 2 ed, p.165

my $jd = 2448908.5; # 1992 Oct 13, 0h
my $t  = ($jd - 2451545) / 36525;
my ($l, $b, $r) = $sun->position($t); # true geocentric ecliptical coordinates

subtest 'Mean' => sub {
    plan tests => 2;

    my @exp = (199.907272, 0.99760853);
    delta_ok($l, $exp[0], 'longitude') or diag("Expected: ${exp[0]}, got: $l");
    delta_ok($r, $exp[1], 'radius-vector') or diag("Expected: ${exp[1]}, got: $r");;
};

subtest 'Apparent' => sub {
    plan tests => 2;

    my @exp = (199.905989, 0.0002);
    my ($al, $ab, $r) = true2apparent([$l, $b, $r], mean2true($t));
    delta_ok($al, $exp[0], 'longitude') or diag("Expected: ${exp[0]}, got: $al");
    delta_ok($ab, $exp[1], 'latitude') or diag("Expected: ${exp[1]}, got: $ab");;
};






