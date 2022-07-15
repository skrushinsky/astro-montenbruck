#!/usr/bin/env perl
use 5.22.0;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");

use POSIX qw/strftime/;
use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;

use DateTime;
use DateTime::TimeZone;

use Astro::Montenbruck::Ephemeris::Planet qw/:ids @PLANETS/;
use Astro::Montenbruck::Time qw/jdnow jd2cal cal2jd jd2unix/;
use Astro::Montenbruck::RiseSet::Constants qw/:events :states/;
use Astro::Montenbruck::RiseSet qw/rst/;
use Astro::Montenbruck::Utils::Helpers qw/parse_geocoords format_geo current_timezone @DEFAULT_PLACE/;

our $VERSION = 0.02;
binmode(STDOUT, ":encoding(UTF-8)");


sub parse_date {
    my ($date_str, $tz_name) = @_;
    my ($ye, $mo, $da) = $date_str =~ /(\d+)-(\d+)-(\d+)/;
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

sub jd2str  {
    my $jd = shift;
    my $tz = shift;
    my %arg = (format => '%Y-%m-%d', @_);

	DateTime->from_epoch(
		epoch     => jd2unix($jd), 
		time_zone => $tz
	)->strftime($arg{format})	
};

my $man    = 0;
my $help   = 0;
my $start  = strftime('%Y-%m-%d', localtime());
my $tzone = current_timezone();
my $days   = 30;
my @place;

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'start:s'    => \$start,
    'days:i'     => \$days,
    'timezone:s' => \$tzone,
    'place:s{2}' => \@place,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

my $dt = parse_date($start, $tzone);
my $tz = DateTime::TimeZone->new( name => $tzone );
@place = @DEFAULT_PLACE unless @place;
my ($lat, $lon);

# first, check if geo-coordinates are given in decimal format
if  (grep(/^[\+\-]?(\d+(\.?\d+)?|(\.\d+))$/, @place) == 2) {
    ($lat, $lon) = @place;
} else {
    ($lat, $lon) = parse_geocoords(@place);
}
say format_geo($lat, $lon);
say sprintf('Time Zone: %s', $tz->name);
say '';

my $jd_start = $dt->jd;
my $jd_end = $jd_start + $days;

for (my $jd = $jd_start; $jd < $jd_end; $jd++) { 
    my @date = jd2cal($jd);
    say jd2str($jd, $tz, format => '%F %Z');
    
    my $rst_func = rst(
        date     => \@date,
        phi      => $lat,
        lambda   => $lon
    );

    for my $pla (@PLANETS) {
        my %report;
        $rst_func->(
            $pla,
            on_event   => sub {
                my ($evt, $jd_evt) = @_;
                $report{$evt} = jd2str($jd_evt, $tz, format => '%m-%d %H:%M')
            },
            on_noevent => sub {
                my ($evt, $state) = @_;
                $report{$evt} = $state;
            }
        );            
        say sprintf(
            '%-12s rise: %s, transit: %s, set: %s',
            $pla, 
            map {$report{$_}} @RS_EVENTS)
    } 
    say('');     
}


__END__

=pod

=encoding UTF-8

=head1 NAME

rst_almanac — calculate rise, set and transit times of Sun, Moon and the planets.


=head1 SYNOPSIS

  rst_almanac [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--start>

Start date, in B<YYYY-DD-MM> format, current date by default.

=item B<--days>

Number of days to process, B<30> by default

=item B<--timezone>

I<Time zone name> (e.g. C<Europe/Berlin>, C<Australia/Sydney>); 
or I<offset from Greenwich> in format B<+HHMM> / B<-HHMM> (e.g., C<+0300>); or possibly I<time zone abbreviation> (e.g. C<CET>).

Defaults to local timezone as reported by your operating system if omitted.

    --timezone=+0300 # UTC + 3h (eastward from Greenwich)
    --timezone="Europe/Moscow"
    --timezone=-0500 # UTC - 5h (westward from Greenwich)
    --timezone="America/Chicago"
    --timezone=CET # Central European Time
    --timezone=EST # Eastern Standard Time
    --timezone=UTC # Universal Coordinated Time
    --timezone=GMT # Greenwich Mean Time, same as the UTC

Use of either the I<time zone name> or I<offset from Greenwich> format is encouraged, as the I<time zone abbreviation> format is not considered definitive by the DateTime module and some abbreviations may not be recognized as valid (e.g., C<MSK>, C<EDT>, C<CST>).
For a list of supported time zone names and offsets, see L<https://en.wikipedia.org/wiki/List_of_tz_database_time_zones>.


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

Negative numbers represent I<South> latitude and I<East> longitudes.  B<Note>: in some online mapping applications (e.g., google), I<West> longitudes are considered negative (following ISO 6709), so be aware of that difference when looking up coordinates with those applications.

=back

C<--place=55.75 -37.58> for I<Moscow, Russian Federation>.
C<--place=40.73 73.935> for I<New-York, NY, USA>.

=back


=head1 DESCRIPTION

Calculate rise, set and transit times of Sun, Moon and the planets for given range of days


=head2 EXAMPLES

    perl ./script/rst_almanac.pl --place=56N26 37E09 --days=7
    perl ./script/rst_almanac.pl --place=56N26 37E09 --start=2021-01-01 --days=365
    

=cut
