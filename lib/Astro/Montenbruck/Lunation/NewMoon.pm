package Astro::Montenbruck::Lunation::NewMoon;

use strict;
use warnings;

use Exporter qw/import/;
use Readonly;
use Math::Trig qw/:pi/;
use Astro::Montenbruck::MathUtils qw/frac reduce_rad frac2pi ARCS/;

our %EXPORT_TAGS = ( all => [qw/iter_newmoon/], );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION     = 0.01;

# rate of change dD/ dT of the mean elongation Moon - Sun in revol. / century
Readonly our $D1 => 1236.853086;

# mean elongation $d of the Moon from the Sun for the epoch J2000 in units of 1rev=360deg
Readonly our $D0 => 0.827361;

sub _improve {
    my ( $t, $callback ) = @_;

    # mean elements of the lunar orbit
    my ( $l, $ls, $f ) = map { frac2pi($_->[0] + $_->[1] * $t) } (
        [ 0.374897, 1325.55241 ], # mean anomaly of the Moon
        [ 0.993133, 99.997361 ],  # mean anomaly of the Sun
        [ 0.259086, 1342.227825 ] # long. Moon - long. asc. node
    );
    my $d  = pi2 * (frac(0.5 + $D0 + $D1 * $t) - 0.5); # mean elongation Moon - Sun
    my $d2 = $d + $d;
    my $l2 = $l + $l;
    my $f2 = $f + $f;

    # periodic perturbations of the lunar and solar longitude (in arc-seconds)
    # my $dlm = sum(
    #     map { $_[0] * sin($_[1]) } (
    #         [ 22640, $l ],
    #         [ -4586, $l - $d2 ],
    #         [ 2370,  $d2 ],
    #         [ 769,   $l2 ],
    #         [ -668,  $ls],
    #         [ -412,  $f2],
    #         [ -212,  $l2 - $d2 ],
    #         [ -206,  $l + $ls - $d2 ],
    #         [ 192,   $l + $d2 ],
    #         [ -165,  $ls - $d2 ],
    #         [ -125,  $d ],
    #         [ -110,  $l + $ls ],
    #         [ 148,   $l - $ls ],
    #         [ -55,   $f2 - $d2 ]
    #     )
    # );
    my $dlm = 22640*sin($l) - 4586*sin($l-2*$d) + 2370*sin(2*$d) + 769*sin(2*$l)
           - 668*sin($ls) - 412*sin(2*$f) - 212*sin(2*$l-2*$d)
           - 206*sin($l+$ls-2*$d) + 192*sin($l+2*$d) - 165*sin($ls-2*$d)
           - 125*sin($d) - 110*sin($l+$ls) + 148*sin($l-$ls) - 55*sin(2*$f-2*$d);
    my $dls = 6893 * sin($ls) + 72 * sin( $ls + $ls );
    # difference of the true longitudes of Moon and Sun in revolutions
    my $dlam = $d / pi2 + ( $dlm - $dls ) / 1296000;
    # correction for the time of new Moon
    my $b = ( 18520.0 * sin( $f + $dlm / ARCS ) - 526 * sin( $f - $d2 ) ) / 3600.0;
    $callback->( $dlam, $b );
}

sub iter_newmoon {
    my $ye = shift;

    my $lun_0 = int( $D1 * ( $ye - 2000 ) / 100 );
    my $lun_i = $lun_0 - 1;
    sub {
        return undef if ++$lun_i > $lun_0 + 13;
$DB::single = 1 if $lun_i == -11;
        my $t = ( $lun_i - $D0 ) / $D1;
        _improve(
            $t,
            sub {
                $t -= $_[0] / $D1
            }
        );
        my $b;
        _improve(
            $t,
            sub {
                $t -= $_[0] / $D1;
                $b = $_[1]
            }
        );
        return [36525 * $t + 51544.5, $b]
    }
}

1;
