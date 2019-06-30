
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.1;
use Astro::Montenbruck::MathUtils qw/ddd dms/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids/;
BEGIN {
    use_ok( 'Astro::Montenbruck::RiseSet', qw/:all/ );
}

subtest 'Normal conditions' => sub {
    plan tests => 3;

    my $lat = 48.1;
    my $lng = -11.6;

    my @cases = (
        {
            date => [ 1989, 3, 23 ],
            moon => {
                rise => [ 18, 57 ],
                set  => [ 5,  13 ],
            },
            sun => {
                rise => [ 5,  11 ],
                set  => [ 17, 30 ],
            },
            twilight => {
                rise => [ 4,  3 ],
                set  => [ 18, 39 ],
            }
        },
        {
            date => [ 1989, 3, 24 ],
            moon => {
                rise => [ 20, 5 ],
                set  => [ 5,  28 ],
            },
            sun => {
                rise => [ 5,  9 ],
                set  => [ 17, 32 ],
            },
            twilight => {
                rise => [ 4,  1 ],
                set  => [ 18, 40 ],
            }
        },
        {
            date => [ 1989, 3, 25 ],
            moon => {
                rise => [ 21, 15 ],
                set  => [ 5,  45 ],
            },
            sun => {
                rise => [ 5,  7 ],
                set  => [ 17, 33 ],
            },
            twilight => {
                rise => [ 3,  59 ],
                set  => [ 18, 42 ],
            }
        },
        {
            date => [ 1989, 3, 26 ],
            moon => {
                rise => [ 22, 26 ],
                set  => [ 6,  6 ],
            },
            sun => {
                rise => [ 5,  5 ],
                set  => [ 17, 35 ],
            },
            twilight => {
                rise => [ 3,  56 ],
                set  => [ 18, 44 ],
            }
        },
        {
            date => [ 1989, 3, 27 ],
            moon => {
                rise => [ 23, 34 ],
                set  => [ 6,  33 ],
            },
            sun => {
                rise => [ 5,  2 ],
                set  => [ 17, 36 ],
            },
            twilight => {
                rise => [ 3,  54 ],
                set  => [ 18, 45 ],
            }
        },
        {
            date => [ 1989, 3, 28 ],
            moon => {
                set => [ 7, 9 ],
            },
            sun => {
                rise => [ 5,  0 ],
                set  => [ 17, 38 ],
            },
            twilight => {
                rise => [ 3,  52 ],
                set  => [ 18, 47 ],
            }
        },
        {
            date => [ 1989, 3, 29 ],
            moon => {
                rise => [ 0, 38 ],
                set  => [ 7, 58 ],
            },
            sun => {
                rise => [ 4,  58 ],
                set  => [ 17, 39 ],
            },
            twilight => {
                rise => [ 3,  50 ],
                set  => [ 18, 48 ],
            }
        },
        {
            date => [ 1989, 3, 30 ],
            moon => {
                rise => [ 1, 31 ],
                set  => [ 9, 0 ],
            },
            sun => {
                rise => [ 4,  56 ],
                set  => [ 17, 41 ],
            },
            twilight => {
                rise => [ 3,  48 ],
                set  => [ 18, 50 ],
            }
        },
        {
            date => [ 1989, 3, 31 ],
            moon => {
                rise => [ 2,  14 ],
                set  => [ 10, 14 ],
            },
            sun => {
                rise => [ 4,  54 ],
                set  => [ 17, 42 ],
            },
            twilight => {
                rise => [ 3,  45 ],
                set  => [ 18, 52 ],
            }
        },
        {
            date => [ 1989, 4, 1 ],
            moon => {
                rise => [ 2,  47 ],
                set  => [ 11, 35 ],
            },
            sun => {
                rise => [ 4,  52 ],
                set  => [ 17, 43 ],
            },
            twilight => {
                rise => [ 3,  43 ],
                set  => [ 18, 53 ],
            }
        },
    );

    my $check_rs = sub {
        my ( $obj, $func ) = @_;

        for my $case (@cases) {
            my ( $got_rise, $got_set );
            $func->(
                @{ $case->{date} },
                $lng, $lat,
                on_event => sub {
                    my ( $evt, $ut ) = @_;
                    if ( $evt eq $EVT_RISE ) {
                        $got_rise = $ut;
                    }
                    else {
                        $got_set = $ut;
                    }
                }
            );
            if ( exists $case->{$obj}->{rise} ) {
                my $exp = $case->{$obj}->{rise};
                my $msg = sprintf( 'rise: %d-%02d-%02d %02d:%02d',
                    @{ $case->{date} }, @$exp );
                if ($got_rise) {
                    my @got = dms( $got_rise, 2 );
                    delta_ok( $got_rise, ddd(@$exp), $msg )
                      or diag(
                        sprintf(
                            'expected: %02d:%02d, got: %02d:%02d',
                            @$exp, @got
                        )
                      );
                }
                else {
                    fail($msg);
                }
            }
            if ( exists $case->{$obj}->{set} ) {
                my $exp = $case->{$obj}->{set};
                my $msg = sprintf( 'set: %d-%02d-%02d %02d:%02d',
                    @{ $case->{date} }, @$exp );
                if ($got_set) {
                    my @got = dms( $got_set, 2 );
                    delta_ok( $got_set, ddd(@$exp), $msg )
                      or diag(
                        sprintf(
                            'expected: %02d:%02d, got: %02d:%02d',
                            @$exp, @got
                        )
                      );
                }
                else {
                    fail($msg);
                }
            }
        }

    };

    subtest 'Sun rise/set' => sub {
        $check_rs->( 'sun', \&rs_sun );
        done_testing();
    };

    subtest 'Moon rise/set' => sub {
        $check_rs->( 'moon', \&rs_moon );
        done_testing();
    };

    subtest 'Nautical twilight' => sub {
        $check_rs->( 'twilight', \&twilight );
        done_testing();
    };

};

subtest 'Extreme latitude' => sub {
    my $lat = 65.0;
    my $lng = -10.0;
    my @date = (1989, 6, 19);
    rs_moon(
        @date, $lng, $lat,
        on_event => sub {
            fail "No rise or set expected";
        },
        on_noevent => sub {
            my $above = shift;
            ok( $above == 0, "always invisible" );
        }
    );

    my ( $ut_rise, $ut_sett );
    rs_sun(
        @date, $lng, $lat,
        on_event => sub {
            my ( $evt, $ut ) = @_;
            $ut_rise = $ut if $evt eq $EVT_RISE;
            $ut_sett = $ut if $evt eq $EVT_SET;
        }
    );

    delta_ok( $ut_rise, ddd( 0, 20 ), "Sun rise at 1989-06-19" )
      or diag("Expected: 00:20, got: @{[dms($ut_rise, 2)]}");
    delta_ok( $ut_sett, ddd( 22, 21 ), "Sun set at 1989-06-19" )
      or diag("Expected: 22:21, got: @{[dms($ut_sett, 2)]}");

    twilight(
        @date, $lng, $lat,
        on_event => sub {
            fail "No twilight start or end expected";
        },
        on_noevent => sub {
            my $above = shift;
            ok( $above == 1, "always bright" );
        }
    );

    done_testing();
};

subtest 'Rise, Set, Transit' => sub {
    my @date = (1999, 12, 31);
    my $lat = 48.1;
    my $lng = -11.6;
    my @cases = (
        {
            id           => $SU,
            $EVT_RISE    => [ 7,  4],
            $EVT_TRANSIT => [11, 16],
            $EVT_SET     => [15, 29]
        },
        {
            id           => $ME,
            $EVT_RISE    => [ 6, 33],
            $EVT_TRANSIT => [10, 37],
            $EVT_SET     => [14, 41]
        },
        {
            id           => $VE,
            $EVT_RISE    => [ 3, 52],
            $EVT_TRANSIT => [ 8, 30],
            $EVT_SET     => [13,  8]
        },
        {
            id           => $MA,
            $EVT_RISE    => [ 9, 33],
            $EVT_TRANSIT => [14, 35],
            $EVT_SET     => [19, 37]
        },
        {
            id           => $JU,
            $EVT_RISE    => [11, 29],
            $EVT_TRANSIT => [18, 10],
            $EVT_SET     => [ 0, 55]
        },
        {
            id           => $SA,
            $EVT_RISE    => [12,  9],
            $EVT_TRANSIT => [19, 10],
            $EVT_SET     => [ 2, 14]
        },
        {
            id           => $UR,
            $EVT_RISE    => [ 9,  2],
            $EVT_TRANSIT => [13, 45],
            $EVT_SET     => [18, 28]
        },
        {
            id           => $NE,
            $EVT_RISE    => [ 8, 25],
            $EVT_TRANSIT => [12, 57],
            $EVT_SET     => [17, 29]
        },
        {
            id           => $PL,
            $EVT_RISE    => [ 4, 11],
            $EVT_TRANSIT => [ 9, 22],
            $EVT_SET     => [14, 32]
        },
    );

    for my $case (@cases) {
        my $id = $case->{id};
        my $func = rst_event($id, @date, $lng, $lat);

        for my $evt ($EVT_RISE, $EVT_TRANSIT, $EVT_TRANSIT) {
            my @ut = @{$case->{$evt}};
            my $exp = ddd(@ut);
            $func->($evt,
                on_event   => sub {
                    my $lt = shift;
                    delta_ok($lt, $exp, sprintf('%s %s at %02d:%02d', $id, $evt, @ut))
                },
                on_noevent => sub { fail("$id: rise or set expected") }
            )
        }
    }

    done_testing();
};

subtest 'Compare Sun/Moon rise/set methods' => sub {
    plan tests => 4;

    my @geo = (-11.6, 48.1);
    my @date = (1999, 12, 31);

    my %rs_func = (
        $SU => sub { rs_sun(@_) },
        $MO => sub { rs_moon(@_)}
    );

    my $compare = sub {
        my ($id, $t1, $t2, $evt) = @_;
        delta_ok(
            $t1, $t2,
            sprintf(
                'Compare %s %s: %02d:%02d / %02d:%02d',
                $id, $evt, dms($t1, 2), dms($t2, 2)
            )
        )
    };

    for my $id ($SU, $MO) {
        my @rise;
        my @sett;
        $rs_func{$id} (
            @date, @geo,
            on_event => sub {
                my ( $evt, $ut ) = @_;
                $rise[0] = $ut if $evt eq $EVT_RISE;
                $sett[0] = $ut if $evt eq $EVT_SET;
            }
        );
        my $func = rst_event($id, @date, @geo);
        $func->($EVT_RISE, on_event => sub { $rise[1] = shift });
        $func->($EVT_SET , on_event => sub { $sett[1] = shift });

        $compare->($id, @rise, 'rise');
        $compare->($id, @sett, 'set');
    }
};


done_testing();
