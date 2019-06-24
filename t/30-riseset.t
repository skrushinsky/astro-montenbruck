
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.1;
use Astro::Montenbruck::MathUtils qw/ddd dms/;

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
            rise  => [ 4,  3],
            set   => [18, 39],
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
            rise  => [ 4,  1],
            set   => [18, 40],
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
            rise  => [ 3, 59],
            set   => [18, 42],
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
            rise  => [ 3, 56],
            set   => [18, 44],
        }
    },
    {
        date      => [1989, 3, 27],
        moon      => {
            rise  => [23, 34],
            set   => [ 6, 33],
        },
        sun       => {
            rise  => [ 5,  2],
            set   => [17, 36],
        },
        twilight  => {
            rise  => [ 3, 54],
            set   => [18, 45],
        }
    },
    {
        date      => [1989, 3, 28],
        moon      => {
            set   => [ 7,  9],
        },
        sun       => {
            rise  => [ 5,  0],
            set   => [17, 38],
        },
        twilight  => {
            rise  => [ 3, 52],
            set   => [18, 47],
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
            rise  => [ 3, 50],
            set   => [18, 48],
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
            rise  => [ 3, 48],
            set   => [18, 50],
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
            rise  => [ 3, 45],
            set   => [18, 52],
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
            rise  => [ 3, 43],
            set   => [18, 53],
        }
    },
);


sub _check_rs {
    my ($obj, $func) = @_;

    for my $case (@cases) {
        my ($got_rise, $got_set);
        $func->(
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
        if ( exists $case->{$obj}->{rise} ) {
            my $exp = $case->{$obj}->{rise};
            my $msg = sprintf('rise: %d-%02d-%02d %02d:%02d', @{$case->{date}}, @$exp);
            if ($got_rise) {
                my @got = dms($got_rise, 2);
                delta_ok($got_rise, ddd(@$exp), $msg)
                    or diag(sprintf('expected: %02d:%02d, got: %02d:%02d', @$exp, @got));
            } else {
                fail($msg);
            }
        }
        if ( exists $case->{$obj}->{set} ) {
            my $exp = $case->{$obj}->{set};
            my $msg = sprintf('set: %d-%02d-%02d %02d:%02d', @{$case->{date}}, @$exp);
            if ($got_set) {
                my @got = dms($got_set, 2);
                delta_ok($got_set, ddd(@$exp), $msg)
                    or diag(sprintf('expected: %02d:%02d, got: %02d:%02d', @$exp, @got));
            } else {
                fail($msg);
            }
        }
    }

}


subtest 'Sun rise/set' => sub {
    _check_rs('sun', \&rs_sun);
    done_testing();
};

subtest 'Moon rise/set' => sub {
    _check_rs('moon', \&rs_moon);
    done_testing();
};

subtest 'Nautical twilight' => sub {
    _check_rs('twilight', \&twilight);
    done_testing();
};



done_testing();
