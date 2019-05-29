#!/usr/bin/env perl
################################################################################
# Run all tests from ../t directory
################################################################################
use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::Harness;

my $root = "$Bin/../t";
opendir (my $dh, $root) || die "cannot open directory: $!";
my @tests = map {"$root/$_"} grep { -f "$root/$_" && /\.t$/ } readdir $dh;
runtests @tests;
