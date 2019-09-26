
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 1e-6;
use Astro::Montenbruck::Time qw/cal2jd mjd2jd/;

BEGIN {
    use_ok( 'Astro::Montenbruck::Lunation::NewMoon', qw/iter_newmoon/ );
}

my @cases = (
    {
        mjd  => 51165.944510615685,
        lat  => 4.2589873169419086
    },
    {
        mjd  => 51195.658417518716,
        lat  => 2.2244955538603421
    },
    {
        mjd  => 51225.278283041021,
        lat  => -0.49491774666817567
    },
    {
        mjd  => 51254.778376053371,
        lat  => -3.0328727583247663
    },
    {
        mjd  => 51284.173188357432,
        lat  => -4.6350373091276884
    },
    {
        mjd  => 51313.500450960237,
        lat  => -4.9561045864140354
    },
    {
        mjd  => 51342.798815887501,
        lat  => -4.024465834654583
    },
    {
        mjd  => 51372.106367681496,
        lat  => -2.079287498918069
    },
    {
        mjd  => 51401.4660818259,
        lat  => 0.44509288437116584
    },
    {
        mjd  => 51430.91827312942,
        lat  => 2.902118724404446
    },
    {
        mjd  => 51460.485531775077,
        lat  => 4.5806930431505508
    },
    {
        mjd  => 51490.167018909575,
        lat  => 4.9546317450335353
    },
    {
        mjd  => 51519.940307540142,
        lat  => 3.8765160621776666
    },
    {
        mjd  => 51549.757404136311,
        lat  => 1.6425523268029747
    },
);

my $iter = iter_newmoon(1999);
for my $case (@cases) {
    my $got = $iter->() or last;
    delta_ok(
        $got->[0],
        $case->{mjd},
        sprintf( 'JD %.4f', $case->{mjd} )
    );
    delta_ok(
        $got->[1],
        $case->{lat},
        sprintf( 'Moon Lat. %.3f', $case->{lat} )
    );

}

done_testing();
