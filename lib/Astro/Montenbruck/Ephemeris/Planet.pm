package Astro::Montenbruck::Ephemeris::Planet;
use strict;
use warnings;

use Readonly;
use Math::Trig qw/:pi rad2deg/;
use Astro::Montenbruck::MathUtils qw/frac ARCS spherical rectangular/;

our $VERSION = '1.00';

Readonly our $MO => 'Moon';
Readonly our $SU => 'Sun';
Readonly our $ME => 'Mercury';
Readonly our $VE => 'Venus';
Readonly our $MA => 'Mars';
Readonly our $JU => 'Jupiter';
Readonly our $SA => 'Saturn';
Readonly our $UR => 'Uranus';
Readonly our $NE => 'Neptune';
Readonly our $PL => 'Pluto';

Readonly::Array our @PLANETS =>
  ( $MO, $SU, $ME, $VE, $MA, $JU, $SA, $UR, $NE, $PL );


use Exporter qw/import/;

our %EXPORT_TAGS = ( ids => [qw/$MO $SU $ME $VE $MA $JU $SA $UR $NE $PL/], );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'ids'} }, '@PLANETS' );


sub new {
    my ( $class, %arg ) = @_;
    bless { _id => $arg{id}, }, $class;
}

# Transformation of mean to true coordinates including
# terms >0.1" according to IAU 1980.
sub _nutequ {
    my ( $t, $x, $y, $z ) = @_;
    my $ls = pi2 * frac( 0.993133 + 99.997306 * $t );    # mean anomaly Sun
    my $d =
      pi2 * frac( 0.827362 + 1236.853087 * $t );    # diff. longitude Moon-Sun
    my $f =
      pi2 * frac( 0.259089 + 1342.227826 * $t );    # mean argument of latitude
    my $n = pi2 * frac( 0.347346 - 5.372447 * $t ); # longit. ascending node
    my $eps = 0.4090928 - 2.2696E-4 * $t;           # obliquity of the ecliptic
    my $dpsi =
      ( -17.200 * sin($n) -
          1.319 * sin( 2 * ( $f - $d + $n ) ) -
          0.227 * sin( 2 * ( $f + $n ) ) +
          0.206 * sin( 2 * $n ) +
          0.143 * sin($ls) ) /
      ARCS;
    my $deps =
      ( +9.203 * cos($n) +
          0.574 * cos( 2 * ( $f - $d + $n ) ) +
          0.098 * cos( 2 * ( $f + $n ) ) -
          0.090 * cos( 2 * $n ) ) /
      ARCS;
    my $c  = $dpsi * cos($eps);
    my $s  = $dpsi * sin($eps);
    my $dx = -( $c * $y + $s * $z );
    my $dy = ( $c * $x - $deps * $z );
    my $dz = ( $s * $x + $deps * $y );
    $x + $dx, $y + $dy, $z + $dz;
}

sub _posvel {
    my ( $self, $l, $b, $r, $dl, $db, $dr ) = @_;
    my $cl = cos($l);
    my $sl = sin($l);
    my $cb = cos($b);
    my $sb = sin($b);
    my $x  = $r * $cl * $cb;
    my $vx = $dr * $cl * $cb - $dl * $r * $sl * $cb - $db * $r * $cl * $sb;
    my $y  = $r * $sl * $cb;
    my $vy = $dr * $sl * $cb + $dl * $r * $cl * $cb - $db * $r * $sl * $sb;
    my $z  = $r * $sb;
    my $vz = $dr * $sb + $db * $r * $cb;
    ( $x, $y, $z, $vx, $vy, $vz );
}

sub _geocentric {
    my ( $self, $t, $hpla_ref, $gsun_ref ) = @_;
    my ( $dl, $db, $dr, $dls, $dbs, $drs );

    # not geometric
    my $m = pi2 * frac( 0.9931266 + 99.9973604 * $t ); # Sun
    $dls = 172.00 + 5.75 * sin($m);
    $drs = 2.87 * cos($m);
    $dbs = 0.0;
    ###
    ( $dl, $db, $dr ) = $self->_lbr_geo($t);
    ###

    my ( $xs, $ys, $zs, $vxs, $vys, $vzs ) =
      $self->_posvel( $gsun_ref->{l}, $gsun_ref->{b}, $gsun_ref->{r}, $dls,
        $dbs, $drs );
    my ( $xp, $yp, $zp, $vx, $vy, $vz ) =
      $self->_posvel( $hpla_ref->{l}, $hpla_ref->{b}, $hpla_ref->{r}, $dl, $db,
        $dr );
    my $x = $xp + $xs;
    my $y = $yp + $ys;
    my $z = $zp + $zs;

    # mean heliocentric motion
    my $delta0 = sqrt( $x * $x + $y * $y + $z * $z );
    my $fac    = 0.00578 * $delta0 * 1E-4;

    # apparent
    $x -= $fac * ( $vx + $vxs );
    $y -= $fac * ( $vy + $vys );
    $z -= $fac * ( $vz + $vzs );

    { l => $xp, b => $yp, r => $zp }, # ecliptic heliocentric coordinates of the planet
    { x => $xs, y => $ys, z => $zs }, # ecliptic geocentric coordinates of the Sun
    { x => $x,  y => $y,  z => $z }   # ecliptic geoocentric coordinates of the planet
}


sub position {
    my ( $self, $t, $sun ) = @_;
    my ( $l, $b, $r ) = $self->heliocentric($t);

    # geocentric ecliptic coordinates (light-time corrected)
    my ( $ph_ref, $sg_ref, $pg_ref ) =
        $self->_geocentric( $t, { l => $l, b => $b, r => $r }, $sun );
    my ( $x, $y, $z ) = _nutequ( $t, map { $pg_ref->{$_} } qw/x y z/ );

    # heliocentric ecliptic (geometric)
    my ( $hx, $hy, $hz ) =
      spherical( $ph_ref->{r}, $ph_ref->{b}, $ph_ref->{l} );

    # spherical coordinates: delta (au), latitude and longitude (radians)
    my ( $gz, $gy, $gx ) = spherical( $x, $y, $z );
    # convert to degrees
    { x => rad2deg($gx), y => rad2deg($gy), z => $gz }
}

sub heliocentric {
    die "Must be overriden by a descendant"
}


1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet - Base class for a planet.

=head1 SYNOPSIS

  package Astro::Montenbruck::Ephemeris::Planet::Mercury;
  use base qw/Astro::Montenbruck::Ephemeris::Planet/;
  ...

  sub  heliocentric {
    # implement the method
  }


=head1 DESCRIPTION

Base class for a planet. Designed to be extended. Used internally in
Astro::Montenbruck::Ephemeris modules. Subclasses must implement B<heliocentric>
method.

=head1 SUBROUTINES/METHODS

=head2 $planet = Astro::Montenbruck::Ephemeris::Planet->new( $id )

Constructor. B<$id> is identifier from C<@PLANETS> array (See L</"EXPORTED CONSTANTS">).

=head2 $xyz = $self->position($t, $sun)

Geocentric ecliptic coordinates of a planet

=head3 Arguments

=over

=item *

B<$t> — time in Julian centuries since J2000: C<(JD-2451545.0)/36525.0>

=item *

B<$sun> — ecliptic geocentric coordinates of the Sun (hashref with B<'x'>, B<'y'>, B<'z'> keys)

=back

=head3 Returns

Hashref of geocentric ecliptical coordinates.

=over

=item * B<x> — geocentric longitude, arc-degrees

=item * B<y> — geocentric latitude, arc-degrees

=item * B<z> — distance from Earth, AU

=back

=head2 $self->heliocentric($t)

Given time in centuries since epoch 2000.0, calculate apparent geocentric
ecliptical coordinates C<($l, $b, $r)>.

=over

=item * B<$l> — longitude, radians

=item * B<$b> — latitude, radians

=item * B<$r> — distance from Earth, A.U.

=back



=head1 EXPORTED CONSTANTS

=over

=item * C<$MO> — Moon

=item * C<$SU> — Sun

=item * C<$ME> — Mercury

=item * C<$VE> — Venus

=item * C<$MA> — Mars

=item * C<$JU> — Jupiter

=item * C<$SA> — Saturn

=item * C<$UR> — Uranus

=item * C<$NE> — Neptune

=item * C<$PL> — Pluto

=item * C<@PLANETS> — array containing all the ids listed above

=back

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
