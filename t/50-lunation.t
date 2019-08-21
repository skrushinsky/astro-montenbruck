
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
        [ [1977, 2, 15], $NEW_MOON     , 2443192.65118 ],
        [ [1965, 2,  1], $FIRST_QUARTER, 2438800.87026 ],
        [ [1965, 2,  1], $FULL_MOON    , 2438807.52007 ],
        [ [2044, 1,  1], $LAST_QUARTER , 2467636.49186 ],
        [ [2019, 8, 21], $NEW_MOON     , 2458725.94287 ],
        [ [2019, 8, 21], $FIRST_QUARTER, 2458732.63302 ],
        [ [2019, 8, 21], $FULL_MOON    , 2458740.69049 ],
        [ [2019, 8, 21], $LAST_QUARTER , 2458748.61252 ],
    );

    for (@cases) {
        my ($date, $q, $exp) = @$_;
        my $got = search_event($date, $q);
        delta_ok($got, $exp, sprintf('%s: %d-%d-%d', $q, @$date));
    }

    done_testing();
};

done_testing();
