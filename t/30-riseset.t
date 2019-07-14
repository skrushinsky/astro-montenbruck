
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.1;
use Astro::Montenbruck::MathUtils qw/ddd dms frac/;
use Astro::Montenbruck::Ephemeris::Planet qw/:ids @PLANETS/;

BEGIN {
    use_ok( 'Astro::Montenbruck::RiseSet', qw/:all/ );
}

subtest 'Sun & Moon, normal conditions' => sub {
    my $lat = 48.1;
    my $lng = -11.6;

    my @cases = (
        {
            date => [ 1989, 3, 23 ],
            $MO => {
                $EVT_RISE => [ 18, 57 ],
                $EVT_SET  => [ 5,  13 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  11 ],
                $EVT_SET  => [ 17, 30 ],
            },
        },
        {
            date => [ 1989, 3, 24 ],
            $MO => {
                $EVT_RISE => [ 20, 5 ],
                $EVT_SET  => [ 5,  28 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  9 ],
                $EVT_SET  => [ 17, 32 ],
            },
        },
        {
            date => [ 1989, 3, 25 ],
            $MO => {
                $EVT_RISE => [ 21, 15 ],
                $EVT_SET  => [ 5,  45 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  7 ],
                $EVT_SET  => [ 17, 33 ],
            },
        },
        {
            date => [ 1989, 3, 26 ],
            $MO => {
                $EVT_RISE => [ 22, 26 ],
                $EVT_SET  => [ 6,  6 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  5 ],
                $EVT_SET  => [ 17, 35 ],
            },
        },
        {
            date => [ 1989, 3, 27 ],
            $MO => {
                $EVT_RISE => [ 23, 34 ],
                $EVT_SET  => [ 6,  33 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  2 ],
                $EVT_SET  => [ 17, 36 ],
            },
        },
        {
            date => [ 1989, 3, 28 ],
            $MO => {
                set => [ 7, 9 ],
            },
            $SU => {
                $EVT_RISE => [ 5,  0 ],
                $EVT_SET  => [ 17, 38 ],
            },
        },
        {
            date => [ 1989, 3, 29 ],
            $MO => {
                $EVT_RISE => [ 0, 38 ],
                $EVT_SET  => [ 7, 58 ],
            },
            $SU => {
                $EVT_RISE => [ 4,  58 ],
                $EVT_SET  => [ 17, 39 ],
            },
        },
        {
            date => [ 1989, 3, 30 ],
            $MO => {
                $EVT_RISE => [ 1, 31 ],
                $EVT_SET  => [ 9, 0 ],
            },
            $SU => {
                $EVT_RISE => [ 4,  56 ],
                $EVT_SET  => [ 17, 41 ],
            },
        },
        {
            date => [ 1989, 3, 31 ],
            $MO => {
                $EVT_RISE => [ 2,  14 ],
                $EVT_SET  => [ 10, 14 ],
            },
            $SU => {
                $EVT_RISE => [ 4,  54 ],
                $EVT_SET  => [ 17, 42 ],
            },
        },
        {
            date => [ 1989, 4, 1 ],
            $MO => {
                $EVT_RISE => [ 2,  47 ],
                $EVT_SET  => [ 11, 35 ],
            },
            $SU => {
                $EVT_RISE => [ 4,  52 ],
                $EVT_SET  => [ 17, 43 ],
            },
        },
    );

    for my $case (@cases) {
        my $date = $case->{date};
        for my $pla ($MO, $SU) {
            my $func = rst_event(
                planet => $pla,
                year   => $date->[0],
                month  => $date->[1],
                day    => $date->[2],
                phi    => $lat,
                lambda => $lng
            );
            for my $evt ($EVT_RISE, $EVT_SET) {
                if (exists $case->{$pla}->{$evt}) {
                    my @dm = @{$case->{$pla}->{$evt}};
                    my $exp = ddd(@dm);
                    $func->(
                        $evt,
                        on_event => sub {
                            my $ut = frac($_[0] - 0.5) * 24;
                            delta_ok($ut, $exp,
                                sprintf( '%s %s: %02d:%02d', $pla, $evt, @dm )
                            )
                        },
                        on_noevent => sub { fail("$pla: $evt event expected") }
                    )
                }

            }

        }
    }
    done_testing();
};

subtest 'Twilight, normal conditions' => sub {
    my ($lat, $lng) = (48.1, -11.6);
    my @cases = (
        {
            date => [ 1989, 3, 23 ],
            $EVT_RISE => [ 4,  3 ],
            $EVT_SET  => [ 18, 39 ],
        },
        {
            date => [ 1989, 3, 24 ],
            $EVT_RISE => [ 4,  1 ],
            $EVT_SET  => [ 18, 40 ],
        },
        {
            date => [ 1989, 3, 25 ],
            $EVT_RISE => [ 3,  59 ],
            $EVT_SET  => [ 18, 42 ],
        },
        {
            date => [ 1989, 3, 26 ],
            $EVT_RISE => [ 3,  56 ],
            $EVT_SET  => [ 18, 44 ],
        },
        {
            date => [ 1989, 3, 27 ],
            $EVT_RISE => [ 3,  54 ],
            $EVT_SET  => [ 18, 45 ],
        },
        {
            date => [ 1989, 3, 28 ],
            $EVT_RISE => [ 3,  52 ],
            $EVT_SET  => [ 18, 47 ],
        },
        {
            date => [ 1989, 3, 29 ],
            $EVT_RISE => [ 3,  50 ],
            $EVT_SET  => [ 18, 48 ],
        },
        {
            date => [ 1989, 3, 30 ],
            $EVT_RISE => [ 3,  48 ],
            $EVT_SET  => [ 18, 50 ],
        },
        {
            date => [ 1989, 3, 31 ],
            $EVT_RISE => [ 3,  45 ],
            $EVT_SET  => [ 18, 52 ],
        },
        {
            date => [ 1989, 4, 1 ],
            $EVT_RISE => [ 3,  43 ],
            $EVT_SET  => [ 18, 53 ],
        },
    );

    for my $case (@cases) {
        my $date = $case->{date};

        my $func = twilight(
            year   => $date->[0],
            month  => $date->[1],
            day    => $date->[2],
            phi    => $lat,
            lambda => $lng
        );
        for my $evt ($EVT_RISE, $EVT_SET) {
            my @dm = @{$case->{$evt}};
            my $exp = ddd(@dm);
            $func->(
                $evt,
                on_event => sub {
                    my $ut = frac($_[0] - 0.5) * 24;
                    delta_ok($ut, $exp,
                        sprintf( '%s: %02d:%02d', $evt, @dm )
                    )
                },
                on_noevent => sub { fail("$evt event expected") }
            )
        }
    }

    my $msg = "\"$EVT_TRANSIT\" event type for twilight raises exception";
    eval {
        twilight(
            year   => 1989,
            month  => 3,
            day    => 23,
            phi    => $lat,
            lambda => $lng
        )->($EVT_TRANSIT);
        fail($msg);
    };
    ok($@ =~ /event is irrelevant here/, $msg);

    done_testing()
};

subtest 'Extreme latitude' => sub {
    plan tests => 1;
    my ($lat, $lng) = (65.0, -10.0);
    my @date = (1989, 6, 19);
    my $func = rst_event(
        planet => $MO,
        year   => $date[0],
        month  => $date[1],
        day    => $date[2],
        phi    => $lat,
        lambda => $lng
    );

    $func->(
        $EVT_RISE,
        on_event => sub {
            fail "Should not happen"
        },
        on_noevent => sub {
            cmp_ok($_[0], 'eq', $STATE_NEVER_RISES, "State $STATE_NEVER_RISES")
        }
    );
};


subtest 'Extreme latitude' => sub {
    plan tests => 1;
    my ($lat, $lng) = (65.0, -10.0);
    my @date = (1989, 6, 19);
    my $func = rst_event(
        planet => $MO,
        year   => $date[0],
        month  => $date[1],
        day    => $date[2],
        phi    => $lat,
        lambda => $lng
    );

    $func->(
        $EVT_RISE,
        on_event => sub {
            fail "Should not happen"
        },
        on_noevent => sub {
            cmp_ok($_[0], 'eq', $STATE_NEVER_RISES, "State $STATE_NEVER_RISES")
        }
    );
};

subtest 'Rise, Set, Transit' => sub {
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
    plan tests => @cases * 3;

    my @date = (1999, 12, 31);
    my ($lat, $lng) = (48.1, -11.6);

    for my $case (@cases) {
        my $id   = $case->{id};
        my $date = $case->{date};
        my $func = rst_event(
            planet => $id,
            year   => $date[0],
            month  => $date[1],
            day    => $date[2],
            phi    => $lat,
            lambda => $lng
        );

        for my $evt($EVT_RISE, $EVT_SET, $EVT_TRANSIT) {
            my @dm = @{$case->{$evt}};
            my $exp = ddd(@dm);
            $func->(
                $evt,
                on_event => sub {
                    my $ut = frac($_[0] - 0.5) * 24;
                    delta_ok($ut, $exp,
                        sprintf( '%s %s: %02d:%02d', $id, $evt, @dm )
                    )
                },
                on_noevent => sub { fail("$id: $evt event expected") }
            );
        }

    }

};

subtest 'Meeus Venus example' => sub {
    plan tests => 3;
    my %cases = (
        $EVT_RISE    => ddd(12, 25),
        $EVT_TRANSIT => ddd(19, 41),
        $EVT_SET     => ddd( 2, 55)
    );

    my $func = rst_event(
        planet => $VE,
        year   => 1988,
        month  => 3,
        day    => 20,
        phi    => 42.3333,
        lambda => 71.0833
    );
    for my $evt ($EVT_RISE, $EVT_TRANSIT, $EVT_SET) {
        my $case = $cases{$evt};
        $func->(
            $evt,
            on_event => sub {
                my $ut = frac($_[0] - 0.5) * 24;
                delta_ok(
                    $ut,
                    $case,
                    sprintf('%s %s at %02d:%02d', $VE, $evt, dms($case, 2))
                )
            },
            on_noevent => sub {
                fail "Event expected"
            }
        );
    }
};


#     my $check_rs = sub {
#         my ( $obj, $func ) = @_;
#
#         for my $case (@cases) {
#             my ( $got_rise, $got_set );
#             $func->(
#                 @{ $case->{date} },
#                 $lng, $lat,
#                 on_event => sub {
#                     my ( $evt, $ut ) = @_;
#                     if ( $evt eq $EVT_RISE ) {
#                         $got_rise = $ut;
#                     }
#                     else {
#                         $got_set = $ut;
#                     }
#                 }
#             );
#             if ( exists $case->{$obj}->{rise} ) {
#                 my $exp = $case->{$obj}->{rise};
#                 my $msg = sprintf( 'rise: %d-%02d-%02d %02d:%02d',
#                     @{ $case->{date} }, @$exp );
#                 if ($got_rise) {
#                     my @got = dms( $got_rise, 2 );
#                     delta_ok( $got_rise, ddd(@$exp), $msg )
#                       or diag(
#                         sprintf(
#                             'expected: %02d:%02d, got: %02d:%02d',
#                             @$exp, @got
#                         )
#                       );
#                 }
#                 else {
#                     fail($msg);
#                 }
#             }
#             if ( exists $case->{$obj}->{set} ) {
#                 my $exp = $case->{$obj}->{set};
#                 my $msg = sprintf( 'set: %d-%02d-%02d %02d:%02d',
#                     @{ $case->{date} }, @$exp );
#                 if ($got_set) {
#                     my @got = dms( $got_set, 2 );
#                     delta_ok( $got_set, ddd(@$exp), $msg )
#                       or diag(
#                         sprintf(
#                             'expected: %02d:%02d, got: %02d:%02d',
#                             @$exp, @got
#                         )
#                       );
#                 }
#                 else {
#                     fail($msg);
#                 }
#             }
#         }
#
#     };
#
#     subtest 'Sun rise/set' => sub {
#         $check_rs->( 'sun', \&rs_sun );
#         done_testing();
#     };
#
#     subtest 'Moon rise/set' => sub {
#         $check_rs->( 'moon', \&rs_moon );
#         done_testing();
#     };
#
#     subtest 'Nautical twilight' => sub {
#         $check_rs->( 'twilight', \&twilight );
#         done_testing();
#     };
#
# };
#
# subtest 'Extreme latitude' => sub {
#     my $lat = 65.0;
#     my $lng = -10.0;
#     my @date = (1989, 6, 19);
#     rs_moon(
#         @date, $lng, $lat,
#         on_event => sub {
#             fail "No rise or set expected";
#         },
#         on_noevent => sub {
#             my $above = shift;
#             ok( $above == 0, "always invisible" );
#         }
#     );
#
#     my ( $ut_rise, $ut_sett );
#     rs_sun(
#         @date, $lng, $lat,
#         on_event => sub {
#             my ( $evt, $ut ) = @_;
#             $ut_rise = $ut if $evt eq $EVT_RISE;
#             $ut_sett = $ut if $evt eq $EVT_SET;
#         }
#     );
#
#     delta_ok( $ut_rise, ddd( 0, 20 ), "Sun rise at 1989-06-19" )
#       or diag("Expected: 00:20, got: @{[dms($ut_rise, 2)]}");
#     delta_ok( $ut_sett, ddd( 22, 21 ), "Sun set at 1989-06-19" )
#       or diag("Expected: 22:21, got: @{[dms($ut_sett, 2)]}");
#
#     twilight(
#         @date, $lng, $lat,
#         on_event => sub {
#             fail "No twilight start or end expected";
#         },
#         on_noevent => sub {
#             my $above = shift;
#             ok( $above == 1, "always bright" );
#         }
#     );
#
#     done_testing();
# };
#
# subtest 'Rise, Set, Transit' => sub {
#     my @date = (1999, 12, 31);
#     my $lat = 48.1;
#     my $lng = -11.6;
#     my @cases = (
#         {
#             id           => $SU,
#             $EVT_RISE    => [ 7,  4],
#             $EVT_TRANSIT => [11, 16],
#             $EVT_SET     => [15, 29]
#         },
#         {
#             id           => $ME,
#             $EVT_RISE    => [ 6, 33],
#             $EVT_TRANSIT => [10, 37],
#             $EVT_SET     => [14, 41]
#         },
#         {
#             id           => $VE,
#             $EVT_RISE    => [ 3, 52],
#             $EVT_TRANSIT => [ 8, 30],
#             $EVT_SET     => [13,  8]
#         },
#         {
#             id           => $MA,
#             $EVT_RISE    => [ 9, 33],
#             $EVT_TRANSIT => [14, 35],
#             $EVT_SET     => [19, 37]
#         },
#         {
#             id           => $JU,
#             $EVT_RISE    => [11, 29],
#             $EVT_TRANSIT => [18, 10],
#             $EVT_SET     => [ 0, 55]
#         },
#         {
#             id           => $SA,
#             $EVT_RISE    => [12,  9],
#             $EVT_TRANSIT => [19, 10],
#             $EVT_SET     => [ 2, 14]
#         },
#         {
#             id           => $UR,
#             $EVT_RISE    => [ 9,  2],
#             $EVT_TRANSIT => [13, 45],
#             $EVT_SET     => [18, 28]
#         },
#         {
#             id           => $NE,
#             $EVT_RISE    => [ 8, 25],
#             $EVT_TRANSIT => [12, 57],
#             $EVT_SET     => [17, 29]
#         },
#         {
#             id           => $PL,
#             $EVT_RISE    => [ 4, 11],
#             $EVT_TRANSIT => [ 9, 22],
#             $EVT_SET     => [14, 32]
#         },
#     );
#
#     for my $case (@cases) {
#         my $id = $case->{id};
#         my $func = rst_event($id, @date, $lng, $lat);
#
#         for my $evt ($EVT_RISE, $EVT_TRANSIT, $EVT_TRANSIT) {
#             my @ut = @{$case->{$evt}};
#             my $exp = ddd(@ut);
#             $func->($evt,
#                 on_event   => sub {
#                     my $lt = shift;
#                     delta_ok($lt, $exp, sprintf('%s %s at %02d:%02d', $id, $evt, @ut))
#                 },
#                 on_noevent => sub { fail("$id: rise or set expected") }
#             )
#         }
#     }
#
#     done_testing();
# };
#
# subtest 'Compare Sun/Moon rise/set Montenbruck methods' => sub {
#     plan tests => 4;
#
#     my @geo = (-11.6, 48.1);
#     my @date = (1999, 12, 31);
#
#     my %rs_func = (
#         $SU => sub { rs_sun(@_) },
#         $MO => sub { rs_moon(@_)}
#     );
#
#     my $compare = sub {
#         my ($id, $t1, $t2, $evt) = @_;
#         delta_ok(
#             $t1, $t2,
#             sprintf(
#                 'Compare %s %s: %02d:%02d / %02d:%02d',
#                 $id, $evt, dms($t1, 2), dms($t2, 2)
#             )
#         )
#     };
#
#     for my $id ($SU, $MO) {
#         my @rise;
#         my @sett;
#         $rs_func{$id} (
#             @date, @geo,
#             on_event => sub {
#                 my ( $evt, $ut ) = @_;
#                 $rise[0] = $ut if $evt eq $EVT_RISE;
#                 $sett[0] = $ut if $evt eq $EVT_SET;
#             }
#         );
#         my $func = rst_event($id, @date, @geo);
#         $func->($EVT_RISE, on_event => sub { $rise[1] = shift });
#         $func->($EVT_SET , on_event => sub { $sett[1] = shift });
#
#         $compare->($id, @rise, 'rise');
#         $compare->($id, @sett, 'set');
#     }
# };
#
#
# subtest 'Meeus' => sub {
#     my %cases = (
#         $EVT_RISE    => ddd(12, 25),
#         $EVT_TRANSIT => ddd(19, 41),
#         $EVT_SET     => ddd( 2, 55)
#     );
#
#     my $func = rst_event_meeus(
#         planet => $VE,
#         year   => 1988,
#         month  => 3,
#         day    => 20,
#         h      => -0.5667,
#         phi    => 42.3333,
#         lambda => 71.0833
#     );
#     for my $evt ($EVT_RISE, $EVT_TRANSIT, $EVT_SET) {
#         my $case = $cases{$evt};
#         $func->(
#             $evt,
#             on_event => sub {
#                 my $j = shift;
#                 my $ut = frac($j - 0.5) * 24;
#                 delta_ok(
#                     $ut,
#                     $case,
#                     sprintf('Venus %-12s at %02d:%02d', $evt, dms($case, 2))
#                 )
#             },
#             on_noevent => sub {
#                 fail "Event expected"
#             }
#         );
#     }
#     done_testing();
# };
#
# subtest 'Compare Meeus & Montenbruck rise/set' => sub {
#     plan tests => 2 * @PLANETS;
#
#     my ($lng, $lat) = (71.0833, 42.3333);
#     my ($year, $month, $day) = (1988, 3, 20);
#
#     my $compare = sub{
#         my ($id, $evt, $t1, $t2) = @_;
#         delta_ok(
#             $t1, $t2,
#             sprintf(
#                 'Compare %s %s: %02d:%02d / %02d:%02d',
#                 $id, $evt, dms($t1, 2), dms($t2, 2)
#             )
#         )
#     };
#
#     for my $planet (@PLANETS) {
#         my $meeus = rst_event_meeus(
#             planet => $planet,
#             year   => $year,
#             month  => $month,
#             day    => $day,
#             h      => 0.125,
#             phi    => $lat,
#             lambda => $lng
#         );
#         my @rs_meeus;
#         $meeus->(
#             $EVT_RISE,
#             on_event => sub{ $rs_meeus[0] = frac($_[0] - 0.5) * 24 }
#         );
#         $meeus->(
#             $EVT_SET,
#             on_event => sub{ $rs_meeus[1] = frac($_[0] - 0.5) * 24 }
#         );
#
#         my @rs_mont;
#
#         my $mont_func = do {
#             given($planet) {
#                 rs_sun
#             }
#         };
#
#         $mont_func->(
#             $year, $month, $day, $lng, $lat,
#             on_event => sub {
#                 my ( $evt, $ut ) = @_;
#                 if ($evt eq $EVT_RISE) {
#                     $rs_mont[0] = $ut;
#                 } else {
#                     $rs_mont[1] = $ut;
#                 }
#             }
#         );
#         $compare->($planet, $EVT_RISE, $rs_meeus[0], $rs_mont[0]);
#         $compare->($planet, $EVT_SET , $rs_meeus[1], $rs_mont[1]);
#     }
#
# };

done_testing();
