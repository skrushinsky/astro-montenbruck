#!/usr/bin/env perl
use 5.22.0;
no warnings qw/experimental/;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");

use Getopt::Std;
use Readonly;
use DateTime;
use DateTime::Format::Strptime;

use Astro::Montenbruck::Time qw/jd_cent jd2lst $SEC_PER_CEN/;
use Astro::Montenbruck::Time::DeltaT qw/delta_t/;
use Astro::Montenbruck::Ephemeris qw/iterator/;
use Astro::Montenbruck::Ephemeris::Planet qw/@PLANETS/;
use Astro::Montenbruck::Helpers qw/dmsz_str dms_or_dec_str hms_str format_geo parse_geocoords/;
use Math::Trig qw/rad2deg/;
use Astro::Montenbruck::CoCo qw/:all/;
#use Astro::Montenbruck::Nutation qw/ecl_obl/;
use Astro::Montenbruck::NutEqu qw/obliquity/;

our $VERSION = 0.01;

use constant USAGE => <<USAGE;
Compute planetary positions.

Usage:
perl ephemeris.pl [OPTIONS]

Options:
-t -- UTC date/time in format: YYYY-MM-DD HH:MM, current by default.
-g -- Geographical coordinates, comma-separated latitude and longitude:
      DD[N|S]MM, DDD[E|W]MM
      N - North, S - South, W - West, E - East.
-e -- Ephemeris/Dynamic time options:
      1 - calculate Delta-T correction (default)
      0 - do not calculate Delta-T
-c -- coordinates type:
      E - ecliptic,
      Q - equatorial arc-degrees,
      T - equatorial hours,
      H - horizontal arc-degrees,
      Z - zodiac  (default)
-f -- format of arc-degrees:
      S - sexadecimal (default)
      D - decimal
-m -- calculate mean daily motion (slower)
-h -- print this help message
USAGE

Readonly our $COO_ECL_DEGREES   => 0;
Readonly our $COO_ECL_ZODIAC    => 1;
Readonly our $COO_EQU_DEGREES   => 2;
Readonly our $COO_EQU_HOURS     => 3;
Readonly our $COO_HRZ_DEGREES   => 4;
Readonly::Array our @EQU_COORDS => ( $COO_EQU_DEGREES, $COO_EQU_HOURS );
Readonly our $FMT_SEXADECIMAL   => 0;
Readonly our $FMT_DECIMAL       => 1;

my %arg;
getopts( 'hmt:g:c:f:e:', \%arg );

if ( $arg{h} ) {
    print USAGE;
    exit 0;
}

$arg{c} //= 'Z';
my $coo;
given ( $arg{c} ) {
    when ('E') {
        $coo = $COO_ECL_DEGREES
    }
    when ('Q') {
        $coo = $COO_EQU_DEGREES
    }
    when ('T') {
        $coo = $COO_EQU_HOURS
    }
    when ('H') {
        $coo = $COO_HRZ_DEGREES
    }
    when ('Z') {
        $coo = $COO_ECL_ZODIAC
    }
    default {
        die "Unknown arc-degrees type: '$arg{c}'!"
    }
}

my $dt = do {
    if ( $arg{t} ) {
        my $strp = DateTime::Format::Strptime->new(
            pattern   => '%F %R',
            time_zone => 'UTC'
        );
        $strp->parse_datetime( $arg{t} );
    }
    else {
        DateTime->now();
    }
};

my @geo = do {
    if ($arg{g}) {
        parse_geocoords(split /\s*,\s*/, $arg{g})
    }
    else {
         (0, 0)
    }
};

$arg{f} //= 'S';
my $fmt;
given ( $arg{f} ) {
    when ('S') {
        $fmt = $FMT_SEXADECIMAL
    }
    when ('D') {
        $fmt = $FMT_DECIMAL
    }
    default {
        die "Unknown coordinates format: '$arg{f}'!"
    }
}

$arg{e} //= '1';
my $use_delta_t;
given ( $arg{e} ) {
    when ('1') {
        $use_delta_t = 1;
    }
    when ('0') {
        $use_delta_t = 0;
    }
    default {
        die "-e argument must be either 1 or 0"
    }
}

printf( "%s %s %s %s\n",
    $dt->ymd, $dt->christian_era, $dt->hms, $dt->time_zone_short_name );

printf( "%s\n\n", format_geo(@geo) );

my $jd = $dt->jd;
printf( "%-15s: %f\n", 'Julian Day', $jd );
my $t = jd_cent($jd);
my $delta_t = 0;
if ($use_delta_t) {
    # Universal -> Dynamic Time
    $delta_t = delta_t($jd);
    printf("%-15s: %05.2f\n", 'Delta-T', $delta_t);
    $t += $delta_t / $SEC_PER_CEN;
}
# Local Sidereal Time
my $lst = jd2lst($jd, $geo[1]);

printf("%-15s: %s\n\n", 'Sidereal Time', hms_str($lst));
# Ecliptic obliquity
my $obliq = obliquity($t);

my @hdrs =
    ( grep /^$coo$/, @EQU_COORDS )
  ? ( 'R.A.', ' Dcl.' )
  : $coo == $COO_HRZ_DEGREES ? ( 'Azm.', ' Alt.' )
                             : ( 'Lng.', ' Lat.' );

my $iter;
if ($arg{m}) {
    $iter = iterator( $t, \@PLANETS, with_motion => 1 );
    printf( "%-10s %-12s %-11s %-10s %-11s  \n", 'Name', @hdrs, 'Dist.', ' Motion' );
    print '-' x 56, "\n";
} else {
    $iter = iterator( $t, \@PLANETS );
    printf( "%-10s %-12s %-11s %-10s\n", 'Name', @hdrs, 'Dist.' );
    print '-' x 43, "\n";
}

my $dms_or_ddd = sub {
    dms_or_dec_str( @_, decimal => $fmt == $FMT_DECIMAL, );
};

while ( my $res = $iter->() ) {
    my ( $id, $pos, $motion ) = @$res;
    my $x_str;
    if ( grep /^$coo$/, (@EQU_COORDS, $COO_HRZ_DEGREES) ) {
        ( $pos->[0], $pos->[1] ) = ecl2equ( $pos->[0], $pos->[1], $obliq );
        if ( $coo == $COO_EQU_HOURS ) {
            $pos->[0] /= 15;
            $x_str = $dms_or_ddd->( $pos->[0], places => 2 );
        } elsif ( $coo == $COO_EQU_DEGREES ) {
            $x_str = $dms_or_ddd->( $pos->[0] );
        }
        elsif ( $coo == $COO_HRZ_DEGREES ) {
            my $h = $lst * 15 - $pos->[0]; # hour angle, arc-degrees
            ( $pos->[0], $pos->[1] ) = equ2hor( $h, $pos->[1], $geo[0]);
            $x_str = $dms_or_ddd->( $pos->[0] );
        }
    }
    elsif ( $coo == $COO_ECL_ZODIAC ) {
        $x_str = dmsz_str( $pos->[0], decimal => $fmt == $FMT_DECIMAL );
    }
    else {
        $x_str = $dms_or_ddd->( $pos->[0], places => 3 );
    }
    my $y_str = $dms_or_ddd->(
        $pos->[1],
        places => 2,
        sign   => 1,
    );
    my $z_str = sprintf( '%07.4f', $pos->[2] );
    #my $name = $id eq $LN ? 'True Node' : $id;
    my $name = $id;
    if (defined $motion) {
        my $m_str = $dms_or_ddd->(
            $motion,
            places => 2,
            sign   => 1,
        );
        printf( "%-10s %-12s %-11s %-10s %-11s\n", $name, $x_str, $y_str, $z_str, $m_str );
    } else {
        printf( "%-10s %-12s %-11s %-10s\n", $name, $x_str, $y_str, $z_str );
    }
}

print "\n";
my $o_str = dms_or_dec_str(
    $obliq,
    places  => 2,
    sign    => 1,
    decimal => $fmt == $FMT_DECIMAL
);
say "Ecliptic Obliquity: $o_str";
