#!/usr/bin/env perl
use 5.22.0;
no warnings qw/experimental/;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");

use Getopt::Std;
use Readonly;
use DateTime;
use DateTime::Format::Strptime;

use Astro::Montenbruck::Time qw/jd2te jd_cent/;
use Astro::Montenbruck::Ephemeris qw/iterator/;
use Astro::Montenbruck::Ephemeris::Planet qw/@PLANETS/;
use Astro::Montenbruck::Helpers qw/dmsz_str dms_or_dec_str/;
use Math::Trig qw/rad2deg/;
use Astro::Montenbruck::CoCo qw/$EQU $ECL ecl2equ/;
use Astro::Montenbruck::Nutation qw/ecl_obl/;

our $VERSION = '1.00';

use constant USAGE => <<USAGE;
Compute planetary positions.

Usage:
perl ephemeris.pl [OPTIONS]

Options:
-t -- UTC date/time in format: YYYY-MM-DD HH:MM, current by default.
-e -- Ephemeris/Dynamic time options:
      1 - calculate Delta-T correction (default)
      0 - do not calculate Delta-T
-c -- coordinates type:
      E - ecliptic,
      Q - equatorial arc-degrees,
      H - equatorial hours,
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
Readonly::Array our @EQU_COORDS => ( $COO_EQU_DEGREES, $COO_EQU_HOURS );
Readonly our $FMT_SEXADECIMAL   => 0;
Readonly our $FMT_DECIMAL       => 1;

my %arg;
getopts( 'hmt:c:f:e:', \%arg );

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
    when ('H') {
        $coo = $COO_EQU_HOURS
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

my $jd = $dt->jd;
printf( "Julian Day: %f\n", $jd );
my ($t, $delta_t);
if ($use_delta_t) {
    ($t, $delta_t) = jd2te($jd);
    printf("Delta-T: %5.2f\n\n", $delta_t);
} else {
    $t = jd_cent($jd);
    $delta_t = 0;
    print("\n");
}

my $obliq = ecl_obl($t);

my @hdrs =
    ( grep /^$coo$/, @EQU_COORDS )
  ? ( 'R.A.', ' Dcl.' )
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
    my ( $id, $pos ) = @$res;
    my $x_str;
    if ( grep /^$coo$/, @EQU_COORDS ) {
        ( $pos->{x}, $pos->{y} ) = ecl2equ( $pos->{x}, $pos->{y}, $obliq );
        if ( $coo == $COO_EQU_HOURS ) {
            $x_str = $dms_or_ddd->( $pos->{x} / 15, places => 2 );
        }
        else {
            $x_str = $dms_or_ddd->( $pos->{x} );
        }

    }
    elsif ( $coo == $COO_ECL_ZODIAC ) {
        $x_str = dmsz_str( $pos->{x}, decimal => $fmt == $FMT_DECIMAL );
    }
    else {
        $x_str = $dms_or_ddd->( $pos->{x}, places => 3 );
    }
    my $y_str = $dms_or_ddd->(
        $pos->{y},
        places => 2,
        sign   => 1,
    );
    my $z_str = sprintf( '%07.4f', $pos->{z} );
    #my $name = $id eq $LN ? 'True Node' : $id;
    my $name = $id;
    if ($arg{m}) {
        my $m_str = $dms_or_ddd->(
            $pos->{motion},
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
    rad2deg($obliq),
    places  => 2,
    sign    => 1,
    decimal => $fmt == $FMT_DECIMAL
);
say "Ecliptic Obliquity: $o_str";
