#!/usr/bin/env perl

use 5.22.0;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");

binmode( STDOUT, ":encoding(UTF-8)" );

our $VERSION = 0.01;

use Getopt::Long qw/GetOptions/;
use POSIX qw/strftime floor/;
use Carp qw/croak/;
use DateTime;
use Astro::Montenbruck::Ephemeris::Planet qw/$MO/;
use Astro::Montenbruck::Time qw/jd2cal jd2unix/;

# use Astro::Montenbruck::Ephemeris qw/find_positions/;
use Astro::Montenbruck::RiseSet qw/rst/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;
use Astro::Montenbruck::Utils::Helpers
  qw/format_geo current_timezone local_now parse_geocoords @DEFAULT_PLACE/;
use Astro::Montenbruck::Lunation qw/:all/;

sub parse_date {
    my ( $date_str, $tz_name ) = @_;
    my ( $ye, $mo, $da ) = $date_str =~ /(\d+)-(\d+)-(\d+)/;
    DateTime->new(
        year      => $ye,
        month     => $mo,
        day       => $da,
        hour      => 12,
        minute    => 0,
        second    => 0,
        time_zone => $tz_name
    );
}

sub jd2str {
    my $jd  = shift;
    my $tz  = shift;
    my %arg = ( format => '%Y-%m-%d', @_ );

    DateTime->from_epoch(
        epoch     => jd2unix($jd),
        time_zone => $tz
    )->strftime( $arg{format} );
}

sub find_lunar_phase {
    my $dt = shift;

    # find New Moon closest to the date
    my $j = search_event( [ $dt->year, $dt->month, $dt->day ], $NEW_MOON );

    # if the event has not happened yet, find the previous one
    if ( $j > $dt->jd ) {
        my ( $y, $m, $d ) = jd2cal( $j - 28 );
        $j = search_event( [ $y, $m, floor($d) ], $NEW_MOON );
    }

    my @month  = @MONTH;
    my $last_q = shift @month;    # this shouls always be the New Moon
    my $last_j = $j;              # Julian date of the last New Moon
    while (@month) {
        my $next_q = shift @month;
        my ( $y, $m, $d ) = jd2cal $last_j;
        my $next_j = search_event( [ $y, $m, floor($d) ], $next_q );
        return $last_q if $dt->jd >= $last_j && $dt->jd < $next_j;
        ( $last_q, $last_j ) = ( $next_q, $next_j );
    }

    croak 'Could not find lunar phase for date ' . $dt->strftime('%F %T');
}

my $now = local_now();

my $help  = 0;
my $man   = 0;
my $date  = $now->strftime('%F');
my $tzone = current_timezone();
my @place;

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'date:s'     => \$date,
    'timezone:s' => \$tzone,
    'place:s{2}' => \@place,
) or pod2usage(2);

my $dt = parse_date( $date, $tzone );
my $tz = DateTime::TimeZone->new( name => $tzone );
@place = @DEFAULT_PLACE unless @place;
my ( $lat, $lon );

# first, check if geo-coordinates are given in decimal format
if ( grep( /^[\+\-]?(\d+(\.?\d+)?|(\.\d+))$/, @place ) == 2 ) {
    ( $lat, $lon ) = @place;
}
else {
    ( $lat, $lon ) = parse_geocoords(@place);
}

say sprintf( 'Date : %s', $dt->strftime('%Y-%m-%d') );
say sprintf( 'Place: %s', format_geo( $lat, $lon ) );
say '';

# Convert Julian date to centuries since epoch 2000.0
# my $t = ( $jd - 2451545 ) / 36525;

# build top-level function for any event and any celestial object
# for given time and place
my $rst_func = rst(
    date   => [ $dt->year, $dt->month, $dt->day ],
    phi    => $lat,
    lambda => $lon
);
my %report;
$rst_func->(
    $MO,
    on_event => sub {
        my ( $evt, $jd_evt ) = @_;
        $report{$evt} = jd2str( $jd_evt, $tz, format => '%H:%M %Z' );
    },
    on_noevent => sub {
        my ( $evt, $state ) = @_;
        $report{$evt} = $state;
    }
);
say sprintf( "Moon Rise: %s\nMoon Transit: %s\nMoon Set: %s",
    map { $report{$_} } @RS_EVENTS );
say '';

say sprintf( 'Lunar phase: %s', find_lunar_phase($dt) );

__END__

=pod

=encoding UTF-8

=head1 NAME

moon — calculate rise, set, transit of the Moon and a lunar date

=head1 SYNOPSIS

  moon [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--date>

Start date, in B<YYYY-DD-MM> format, current date by default.

  --date=2019-06-08 # calendar date

=item B<--timezone>

Time zone name, e.g.: C<EST>, C<UTC>, C<Europe/Berlin> etc. 
or I<offset from Greenwich> in format B<+HHMM> / B<-HHMM>, like C<+0300>.

    --timezone=CET # Central European Time
    --timezone=EST # Eastern Standard Time
    --timezone=UTC # Universal Coordinated Time
    --timezone=GMT # Greenwich Mean Time, same as the UTC
    --timezone=+0300 # UTC + 3h (eastward from Greenwich)
    --timezone="Europe/Moscow"

By default, a local timezone.

Please, note: Windows platform may not recognize some time zone names, like C<MSK>.
In such cases use I<offset from Greenwich> format, as described above.


=item B<--place>

The observer's location. Contains 2 elements, space separated. 

=over

=item * 

latitude in C<DD(N|S)MM> format, B<N> for North, B<S> for South.

=item * 

longitude in C<DDD(W|E)MM> format, B<W> for West, B<E> for East.

=back

E.g.: C<--place=51N28 0W0> for I<Greenwich, UK> (the default).

B<Decimal numbers> are also supported. In that case

=over

=item * 

The latitude always goes first

=item * 

Negative numbers represent I<South> latitude and I<East> longitudes. 

=back

C<--place=55.75 -37.58> for I<Moscow, Russian Federation>.
C<--place=40.73 73.935> for I<New-York, NY, USA>.


=back

=head1 DESCRIPTION

B<moon> Computes rise, set and lunar phase for a date
 
    $ perl ./script/moon.pl 

    Date : 2022-01-30
    Place: 51N28, 000W00

    Moon Rise: 09:54 MSK
    Moon Transit: 13:31 MSK
    Moon Set: 17:09 MSK
    Lunar phase: Full Moon

=cut
