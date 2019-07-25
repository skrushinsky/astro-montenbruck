#!/perl

use 5.22.0;
use strict;
no warnings qw/experimental/;
use feature qw/state switch/;

use utf8;
use FindBin qw/$Bin/;
use lib ("$Bin/lib", "$Bin/../lib");
use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;
use DateTime;
use Term::ANSIColor;

use Readonly;

use Astro::Montenbruck::MathUtils qw/frac hms/;
use Astro::Montenbruck::Ephemeris::Planet qw/@PLANETS/;
use Astro::Montenbruck::Time qw/jd2unix/;
use Astro::Montenbruck::RiseSet qw/:all/;
use Helpers qw/parse_datetime parse_geocoords format_geo hms_str
               $LOCALE @DEFAULT_PLACE/;
use Display qw/%LIGHT_THEME %DARK_THEME print_data/;

binmode(STDOUT, ":utf8");

Readonly::Hash our %TWILIGHT_TITLE => (
    $EVT_RISE => 'Morning',
    $EVT_SET  => 'Evening',
);

sub process_planet {
    my ($id, $func, $scheme, $tzone) = @_;

    print colored( sprintf('%-8s', $id), $scheme->{table_row_title} );

    for my $evt (@RS_EVENTS) {
        $func->(
            $evt,
            on_event   => sub {
                my $jd = shift; # Standard Julian date
                my $dt = DateTime->from_epoch(epoch => jd2unix($jd))
                                 ->set_time_zone($tzone);
                print colored(
                    $dt->strftime('%T'),
                    $scheme->{table_row_data}
                );
                print "   ";
            },
            on_noevent => sub {
                print colored(
                    sprintf('%-8s', ' — '),
                    $scheme->{table_row_error}
                );
                print " ";
            }
        );
    }
    print "\n"
}


sub process_twilight {
    my ($func, $scheme, $tzone) = @_;

    for my $evt ($EVT_RISE, $EVT_SET) {
        $func->(
            $evt,
            on_event   => sub {
                my $jd = shift; # Standard Julian date
                my $dt = DateTime->from_epoch(epoch => jd2unix($jd))
                                 ->set_time_zone($tzone);
                print_data(
                    $TWILIGHT_TITLE{$evt},
                    $dt->strftime('%T'),
                    scheme      => $scheme,
                    title_width => 7
                );
            },
            on_noevent => sub {
                print_data(
                    $TWILIGHT_TITLE{$evt},
                    ' — ',
                    scheme      => $scheme,
                    title_width => 7
                );
            }
        );
    }
}

my $man      = 0;
my $help     = 0;
my $date     = DateTime->now()->set_locale($LOCALE)->strftime('%F');
my @place;
my $theme    = 'dark';
my $twilight = $TWILIGHT_NAUTICAL;

# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'date:s'     => \$date,
    'place:s{2}' => \@place,
    'theme:s'    => \$theme,
    'twilight:s' => \$twilight
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

@place = @DEFAULT_PLACE unless @place;

my $scheme = do {
    given (lc $theme) {
        \%DARK_THEME  when 'dark';
        \%LIGHT_THEME when 'light';
        default { warn "Unknown theme: $theme. Using default (dark)"; \%DARK_THEME }
    }
};

my $local = parse_datetime($date);
print_data(
    'Date',
    $local->strftime('%F %Z'),
    scheme      => $scheme,
    title_width => 7
);
my $utc = $local->time_zone ne 'UTC' ? $local->clone->set_time_zone('UTC')
                                     : $local;
my ($lat, $lon) = parse_geocoords(@place);
print_data(
    'Place',
    format_geo($lat, $lon),
    scheme      => $scheme,
    title_width => 7
);
print "\n";
print colored(
    "        rise       transit    set     \n",
    $scheme->{table_row_title}
);
for (@PLANETS) {
    my $func = rst_event(
        planet => $_,
        year   => $utc->year,
        month  => $utc->month,
        day    => $utc->day,
        phi    => $lat,
        lambda => $lon
    );
    process_planet($_, $func, $scheme, $local->time_zone)
}

say colored("\nTwilight ($twilight)\n", $scheme->{data_row_title});
process_twilight(
    twilight(
        year   => $utc->year,
        month  => $utc->month,
        day    => $utc->day,
        phi    => $lat,
        lambda => $lon,
        type   => $twilight
    ),
    $scheme,
    $local->time_zone
);

print "\n";


__END__

=pod

=encoding UTF-8

=head1 NAME

riseset — calculate rise, set and transit times of Sun, Moon and the planets.

=head1 SYNOPSIS

  riseset [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--time>

Date and time, either a I<calendar entry> in format C<YYYY-MM-DD HH:MM Z>, or
C<YYYY-MM-DD HH:MM Z>, or a floating-point I<Julian Day>:

  --datetime="2019-06-08 12:00 +0300"
  --datetime="2019-06-08 09:00 UTC"
  --datetime=2458642.875

Calendar entries should be enclosed in quotation marks. Optional B<"Z"> stands for
time zone, short name or offset from UTC. C<"+00300"> in the example above means
I<"3 hours east of Greenwich">.

=item B<--place>

The observer's location. Contains 2 elements, space separated, in any order:

=over

=item * latitude in C<DD(N|S)MM> format, B<N> for North, B<S> for South.

=item * longitude in C<DDD(W|E)MM> format, B<W> for West, B<E> for East.

=back

E.g.: C<--place=51N28 0W0> for I<Greenwich, UK>.

=item B<--twilight> type of twilight:

=over

=item * B<civil>

=item * B<nautical>

=back


=item B<--theme> color scheme:

=over

=item * B<dark>, default: color scheme for dark consoles

=item * B<light> color scheme for light consoles

=back

=back


=head1 DESCRIPTION

B<riseset> riseset — calculate rise, set and transit times of Sun, Moon and the planets.

=cut
