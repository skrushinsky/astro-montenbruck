package Astro::Montenbruck::Helpers;

use strict;
use warnings;

use Exporter qw/import/;


our $VERSION = '1.00';

use Readonly;

Readonly::Array our @ZODIAC =>
  qw/Aries Taurus Gemini Cancer Leo Virgin Libra Scorpio
  Sagittarius Capricorn Aquarius Pisces/;

our @EXPORT_OK = qw/parse_geocoords dmsz_str dms_or_dec_str
  dmsdelta_str hms_str format_geo @ZODIAC/;

use Astro::Montenbruck::MathUtils qw/dms zdms frac/;

sub parse_geocoords {
    my ( $lats, $lons ) = @_;
    my ( $lat, $lon ) = (0, 0);
    {
        $lats =~ /^(\d+)(S|N)(\d+)$/i;
        my $d = $1 or die 'Unexpected latitude degrees';
        my $n = $2 or die 'Unexpected latitude direction';
        my $m = $3 or die 'Unexpected latitude minutes';
        $lat = $d + $m / 60;
        $lat = -$lat if $n eq 'S';
    }
    {
        $lons =~ /^(\d+)(E|W)(\d+)$/i;
        my $d = $1 or die 'Unexpected longitude degrees';
        my $w = $2 or die 'Unexpected longitude direction';
        my $m = $3 or die 'Unexpected longitude minutes';
        $lon = $d + $m / 60;
        $lon = -$lon if $w eq 'E';
    }
    $lat, $lon;
}

sub dmsz_str {
    my $x = shift;
    my %arg = ( decimal => 0, @_ );
    my ( $s, $d, $m ) = zdms($x);
    my $z = substr( $ZODIAC[$s], 0, 3 );
    if ( $arg{decimal} ) {
        sprintf( '%05.2f %s', ( $x % 30 ) + frac($x), $z );
    }
    else {
        sprintf( '%02d:%02d %s', $d, $m, $z );
    }
}

sub dms_str {
    my $x = shift;
    sprintf( '%03d:%02d:%02d', dms($x) );
}

sub dms_or_dec_str {
    my $x   = shift;
    my %arg = ( decimal => 0, places => 3, sign => 0, @_ );
    my $s   = $arg{sign} ? ( $x < 0 ? '-' : '+' ) : '';

    if ( $arg{decimal} ) {
        my $f = sprintf( '0%d', $arg{places} + 3 );
        my $fmt = "$s%$f.2f";
        sprintf( $fmt, abs($x) );
    }
    else {
        my $f = sprintf( '0%dd', $arg{places} );
        my $fmt = "$s%$f:%02d:%02d";
        sprintf( $fmt, dms( abs($x) ) );
    }
}

sub hms_str {
    my $x = shift;
    my %arg = ( decimal => 0, @_ );
    $arg{decimal}
      ? sprintf( '05.2f',          $x )
      : sprintf( '%02d:%02d:%02d', dms($x) );
}

sub latde_str {
    my $y = shift;
    my %arg = ( decimal => 0, @_ );
    if ( $arg{decimal} ) {
        sprintf( '05.2f', $y );
    }
    else {
        sprintf( '%s%02d:%02d:%02d', $y < 0 ? '-' : '+', dms($y) );
    }
}

sub format_geo {
    my ($lat, $lon) = @_;
    my $a = abs($lat);
    my $b = abs($lon);
    my @lat = dms($a, 2);
    my $lats = sprintf('%02d%s%02d', $lat[0], ( $lat < 0 ? 'S' : 'N'), $lat[1] );
    my @lon = dms($b, 2);
    my $lons = sprintf('%03d%s%02d', $lon[0], ( $lon < 0 ? 'E' : 'W'), $lon[1] );

    "$lats, $lons"
}

1;

__END__

_END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Helpers - Helper functions for scripts.

=head1 VERSION

Version 1.00

=head1 DESCRIPTION

Helper functions for scripts, mainly string related.

=head1 EXPORT

=over

=item * L<< /parse_geocoords(l => number, m => number) >>

=item * L<< /dmsz_str($x, decimal => boolean) >>

=item * L</dms_str($x)>

=item * L<< /dms_or_dec_str($x, decimal => boolean, places => N, sign => boolean) >>

=item * L<< /hms_str($x, $decimal => boolean) >>

=item * L<< /latde_str($h, $decimal => boolean) >>

=back

=head1 FUNCTIONS

=head2 parse_geocoords(l => number, m => number)

Parse geographical coordinates

=head3 Named Arguments

=over

=item * B<l> — longitude in degrees

=item * B<m> — latitude in degrees

=back

=head3 Returns

List of formatted longitude and latitude, e.g: C<037E35>, C<55N45>.


=head2 dmsz_str($x, decimal => boolean)

Given ecliptic longitude B<$x>, return string with Zodiac position:
C<12:30 Aqu> or C<312.50 Aqu> depending on B<decimal> option.

=head3 Options

=over

=item * B<decimal> — return decimal degrees instead of degrees and minutes.

=back

=head2 dms_str($x)

Given ecliptic longitude B<$x>, return string of formatted degrees, minutes
and seconds, e.g.: C<312:30:02>.

=head2 dms_or_dec_str($x, decimal => boolean, places => N, sign => boolean)

Format ecliptic longitude B<$x>.

=head3 Options

=over

=item * B<decimal> — return decimal degrees instead of degrees and minutes. Default is I<false>

=item * B<places> — number of arc-degrees digits. If C<$x = 1>, C<3> gives C<001>, C<2> gives C<01>, C<1> gives C<1>. Default is B<3>

=item * B<sign> — if I<true>, the number will be prefixed with B<+> or B<->, depending on its sign. Default: I<false>.

=back

=head2 hms_str($x, $decimal => boolean)

Format time value B<$x>.

=head3 Options

=over

=item * B<decimal> — return decimal degrees instead of degrees and minutes.

=back

=head2 latde_str($h, $decimal => boolean)

Format time value B<$h>.

=head3 Options

=over

=item * B<decimal> — return decimal degrees instead of degrees and minutes.

=back



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Astro::Montenbruck::CoCo

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
