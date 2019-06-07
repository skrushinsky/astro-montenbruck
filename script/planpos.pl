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
use DateTime::Format::Strptime;
use Term::ANSIColor;

use Readonly;

use Astro::Montenbruck::Time qw/jd_cent jd2lst $SEC_PER_CEN/;
use Astro::Montenbruck::Time::DeltaT qw/delta_t/;
use Astro::Montenbruck::MathUtils qw/frac hms/;

my $man    = 0;
my $help   = 0;
my $use_dt = 1;

my %datetime = (
    value => DateTime->now('%F %T %Z'),
    mode  => 'DT',
);
my %place = (
    name  => 'Unknown',
    lat   => '51N30',
    lon   => '000W07'
);

sub jd_to_timepiece {
    my $jd = shift;
    my ($ye, $mo, $da) = jd2cal($jd);
    my ($ho, $mi, $se) = hms( frac($da) * 24 );
    my $s = sprintf(
        '%d-%02d-%02d %02d:%02d:%02d', $ye, $mo, $da, $ho, $mi, int($se)
    );
    return Time::Piece->strptime($s, '%F %T')
}

sub parse_datetime {
    my ($mode, $value) = @_;
    given ( $mode ) {
        when ('DT') {
            return localtime->strptime($value, '%Y-%m-%d %H:%M Z');
        }
        when ('JD') {
            return jd_to_timepiece( $value )
        }
    }
    die "Unknown datetime mode: $mode"
}


# Parse options and print usage if there is a syntax error,
# or if usage was explicitly requested.
GetOptions(
    'help|?'      => \$help,
    'man'         => \$man,
    'datetime:s'  => \%datetime,
    'place:s'     => \%place,
    'dt!'         => \$use_dt

) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;



my $local = parse_datetime($datetime{mode}, $datetime{value});
my $utc   = gmtime($local->epoch);
print colored( sprintf('%-15s', 'Local Time:'), 'white' );
say colored( $local->strftime('%F %R %Z'), 'bright_yellow');
print colored( sprintf('%-15s', 'UTC:'), 'white' );
say colored( $utc->strftime('%F %R %Z'), 'bright_yellow');
print colored( sprintf('%-15s', 'Julian Day:'), 'white' );
say colored( sprintf('%.6f', $utc->julian_day), 'bright_yellow');



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

=item B<--datetime>

Date and time. Contains 2 elements: B<value> and B<mode>, e.g.:
C<--datetime value=2019-06-05T20:00:00 mode=UT>  The B<value>, depending on
B<mode> option, may be either a I<calendar entry>, or a floating-point
I<Julian Day>. The B<mode> is one of:

=over

=item * B<DT> (default) — date and time in ISO format C<"YYYY-MM-DDTHH:MM Z">

=item * B<JD> — I<Standard Julian Date>

=back

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
