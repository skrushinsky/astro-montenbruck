#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = '1.00';

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More tests => 4;
use Math::Trig qw/rad2deg/;
use Astro::Montenbruck::Nutation qw/:all/;
use Test::Number::Delta within => 1e-6;

BEGIN {
	use_ok( 'Astro::Montenbruck::Nutation', qw/:all/  );
}

my $j = 2446895.5;
my $t =  ($j - 2451545.0) / 36525.0;

my $delta_psi = nut_lon($t); # nutation in longitude
# Astrolabe gives -1.8364408090376296e-05
delta_ok(rad2deg(-1.83644080903776e-05), rad2deg($delta_psi), 'nutation in longitude');

my $delta_eps = nut_obl($t); # nutation in ecliptic obliquity
# Astrolabe gives 4.5778632189175224e-05
delta_ok(rad2deg(-8.68134198442675e-05), rad2deg($delta_eps), 'nutation in ecl. obliquity');

my $eps = ecl_obl($t); # obliquity of ecliptic
# Astrolabe gives:     0.40912169604580345
# Astrolabe algorithm: 0.409121692560358
my $epsd = rad2deg($eps); # obliquity of ecliptic
delta_ok($epsd, rad2deg(0.40912169604580345), 'ecliptic obliquity');
