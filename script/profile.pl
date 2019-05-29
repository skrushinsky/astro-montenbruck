#!/usr/bin/env perl
################################################################################
# This script may be used for profiling
################################################################################
use 5.22.0;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use AstroScript::Ephemeris qw/apparent/;
use AstroScript::Ephemeris::Planet qw/@PLANETS/;

my $t = -0.34913099854893875;
# get iterator function
my $iter = apparent( $t, \@PLANETS );

while ( my $result = $iter->() ) {
    my ($id, $co) = @$result;
}
