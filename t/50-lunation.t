
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.4;

BEGIN {
    use_ok( 'Astro::Montenbruck::Lunation', qw/:all/ );
}

subtest 'search_event' => sub {
    my @cases = (
        [ [1977, 2, 15], $NEW_MOON, 2443192.65118 ],
        [ [2044, 1, 1], $LAST_QUARTER, 2467636.49186 ]
    );

    for (@cases) {
        my ($date, $q, $exp) = @$_;
        my $got = search_event($date, $q);
        delta_ok($got, $exp);
    }

    done_testing();
};

done_testing();
