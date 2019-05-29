#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = '1.00';

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More tests => 1;

BEGIN {
    use_ok(
        'Astro::Montenbruck::Helpers', qw/parse_geocoords  dmsz_str dms_or_dec_str
          dmsdelta_str/
    );
}
