#!/perl

use 5.22.0;
use strict;
no warnings qw/experimental/;

use utf8;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");
use Getopt::Long qw/GetOptions/;
use Pod::Usage qw/pod2usage/;
use DateTime;
use Term::ANSIColor;

use Readonly;

use Astro::Montenbruck::Time qw/jd_cent jd2lst $SEC_PER_CEN jd2unix/;
use Astro::Montenbruck::Time::DeltaT qw/delta_t/;
use Astro::Montenbruck::MathUtils qw/frac hms/;
use Astro::Montenbruck::Helpers qw/
    parse_datetime parse_geocoords format_geo hms_str $LOCALE/;

my $man    = 0;
my $help   = 0;
my $use_dt = 1;
my $time   = DateTime->now()->set_locale($LOCALE)->strftime('%F %T');
my @place;

sub print_data {
    my ($title, $data) = @_;
    print colored( sprintf('%-20s', $title), 'white' );
    say colored( ": $data", 'bright_yellow');
}


# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'     => \$help,
    'man'        => \$man,
    'time:s'     => \$time,
    'place:s{2}' => \@place,
    'dt!'        => \$use_dt

) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;

my $local = parse_datetime($time);
print_data('Local Time', $local->strftime('%F %T %Z'));
my $utc;
if ($local->time_zone ne 'UTC') {
    $utc   = $local->clone->set_time_zone('UTC');
    print_data('Universal Time', $utc->strftime('%F %T'));
} else {
    $utc = $local;
}
print_data('Julian Day', sprintf('%.6f', $utc->jd));

my $t = jd_cent($utc->jd);
if ($use_dt) {
    # Universal -> Dynamic Time
    my $delta_t = delta_t($utc->jd);
    print_data('Delta-T', sprintf('%05.2fs.', $delta_t));
    $t += $delta_t / $SEC_PER_CEN;
}



my ($lat, $lon) = parse_geocoords(@place);
print_data('Place', format_geo($lat, $lon));

# Local Sidereal Time
my $lst = jd2lst($utc->jd, $lon);
print_data('Sidereal Time', hms_str($lst));

__END__

=pod

=encoding UTF-8

=head1 NAME

planpos — calculate planetary positions for given time and place.

=head1 SYNOPSIS

  planpos [options]

=head1 OPTIONS

=over 4

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--time>

Date and time, either a I<calendar entry> in format C<YYYY-MM-DD HH:MM Z> or
C<YYYY-MM-DD HH:MM Z>, or a floating-point I<Julian Day>:

  --datetime "2019-06-08 12:00 +0300"
  --datetime date="2019-06-08 09:00 UTC"
  --datetime date=2458642.875 mode=JD

Calendar entries must be enclosed in quotes. Optional B<"Z"> stands for time
zone, short name or offset from UTC. C<"+00300"> in the example above means
I<"3 hours eastward">.

=item B<--place> — the observer's location. Contains 3 elements: B<name>, B<lat>
and B<lon>, e.g.: C<--place name="London, UK" lat=51N30 lon=000W07>.

=over

=item * B<name> is optional name. If it contains spaces, enclose it in quotes,
as in C<"London, UK">.

=item * B<lat> — latitude in C<DD(N|S)MM> format, B<N> for North, B<S> for South.

=item * B<lon> — longitude in C<DDD(W|E)MM> format, B<W> for West, B<E> for East.

=back


=item B<--coordinates> — type and format of coordinates to display:

=over

=item * B<1> — Ecliptical, angular units (default)

=item * B<2> — Ecliptical, zodiac

=item * B<3> — Equatorial, angular units

=item * B<4> — Equatorial, time units

=item * B<5> — Horizontal, angular units

=item * B<6> — Horizontal, time units

=back

=item B<--format> format of numbers:

=over

=item * B<D> decimal: arc-degrees or hours

=item * B<S> sexadecimal: degrees (hours), minutes, seconds

=back

=back

=head1 DESCRIPTION

B<planpos> computes planetary positions for current moment or given
time and place.


=cut
