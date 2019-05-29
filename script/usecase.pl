#!/usr/bin/env perl
################################################################################
# Simple usage example.
################################################################################
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";

our $VERSION = '1.00';

use DateTime;
use AstroScript::Ephemeris qw/apparent/;
use AstroScript::Ephemeris::Planet qw/@PLANETS/;
use Data::Dumper;

my $jd = DateTime->now->jd; # Standard Julian date for current moment
my $t  = ($jd - 2451545) / 36525; # Convert Julian date in centuries
# for more accuracy t should be converted to Ephemeris time.

my $iter = apparent($t, \@PLANETS); # get iterator function

while ( my $result = $iter->() ) {
    my ($id, $co) = @$result;
    print $id, "\n", Dumper($co), "\n"; # geocentric longitude, latitude and distance from Earth
}
