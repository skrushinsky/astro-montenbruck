
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 1e-2;
use Astro::Montenbruck::MathUtils qw/ddd/;

BEGIN {
	use_ok( 'Astro::Montenbruck::RiseSet', qw/:all/ );
}

my $lat = 48.1;
my $lng = -11.6;

my @cases = (
    {
        date      => [1989, 3, 23],
        moon      => {
            rise  => [18, 57],
            set   => [ 5, 13],
        },
        sun       => {
            rise  => [ 5, 11],
            set   => [17, 30],
        },
        twilight  => {
            end   => [ 4,  3],
            start => [18, 39],
        }
    },
    {
        date      => [1989, 3, 24],
        moon      => {
            rise  => [20,  5],
            set   => [ 5, 28],
        },
        sun       => {
            rise  => [ 5,  9],
            set   => [17, 32],
        },
        twilight  => {
            end   => [ 4,  1],
            start => [18, 40],
        }
    },
    {
        date      => [1989, 3, 25],
        moon      => {
            rise  => [21, 15],
            set   => [ 5, 45],
        },
        sun       => {
            rise  => [ 5,  7],
            set   => [17, 33],
        },
        twilight  => {
            end   => [ 3, 59],
            start => [18, 42],
        }
    },
    {
        date      => [1989, 3, 26],
        moon      => {
            rise  => [22, 26],
            set   => [ 6,  6],
        },
        sun       => {
            rise  => [ 5,  5],
            set   => [17, 35],
        },
        twilight  => {
            end   => [ 3, 56],
            start => [18, 44],
        }
    },
    {
        date      => [1989, 3, 27],
        moon      => {
            set   => [ 6, 33],
        },
        sun       => {
            rise  => [ 5,  2],
            set   => [17, 36],
        },
        twilight  => {
            end   => [ 3, 54],
            start => [18, 45],
        }
    },
    {
        date      => [1989, 3, 28],
        moon      => {
            rise  => [23, 34],
            set   => [ 7,  9],
        },
        sun       => {
            rise  => [ 5,  0],
            set   => [17, 38],
        },
        twilight  => {
            end   => [ 3, 52],
            start => [18, 47],
        }
    },
    {
        date      => [1989, 3, 29],
        moon      => {
            rise  => [ 0, 38],
            set   => [ 7, 58],
        },
        sun       => {
            rise  => [ 4, 58],
            set   => [17, 39],
        },
        twilight  => {
            end   => [ 3, 50],
            start => [18, 48],
        }
    },
    {
        date      => [1989, 3, 30],
        moon      => {
            rise  => [ 1, 31],
            set   => [ 9,  0],
        },
        sun       => {
            rise  => [ 4, 56],
            set   => [17, 41],
        },
        twilight  => {
            end   => [ 3, 48],
            start => [18, 50],
        }
    },
    {
        date      => [1989, 3, 31],
        moon      => {
            rise  => [ 2, 14],
            set   => [10, 14],
        },
        sun       => {
            rise  => [ 4, 54],
            set   => [17, 42],
        },
        twilight  => {
            end   => [ 3, 45],
            start => [18, 52],
        }
    },
    {
        date      => [1989, 4, 1],
        moon      => {
            rise  => [ 2, 47],
            set   => [11, 35],
        },
        sun       => {
            rise  => [ 4, 52],
            set   => [17, 43],
        },
        twilight  => {
            end   => [ 3, 43],
            start => [18, 53],
        }
    },
);


subtest 'Sun rise/set' => sub {

    for my $case (@cases) {
        my @hm = @{$case->{sun}->{rise}};
        my $exp = $hm[0] + $hm[1] / 60;
        my ($got_rise, $got_set);
        rs_sun(
            @{$case->{date}}, $lng, $lat,
            on_event => sub {
                my ($evt, $ut) = @_;
                if ($evt eq $EVT_RISE) {
                    $got_rise = $ut;
                } else {
                    $got_set = $ut;
                }
            }
        );
        if ( exists $case->{sun}->{rise} ) {
            my $exp = $case->{sun}->{rise};
            my $msg = sprintf('rise at %02d:%02d', @$exp);
            if ($got_rise) {
                delta_ok($got_rise, ddd(@$exp), $msg);
            } else {
                fail($msg);
            }
        }
        if ( exists $case->{sun}->{set} ) {
            my $exp = $case->{sun}->{set};
            my $msg = sprintf('set at %02d:%02d', @$exp);
            if ($got_set) {
                delta_ok($got_set, ddd(@$exp), $msg);
            } else {
                fail($msg);
            }
        }
    }
    done_testing();
};



done_testing();
