package Astro::Montenbruck::RiseSet;

use strict;
use warnings;

use Exporter qw/import/;
use Readonly;

use Math::Trig qw/:pi deg2rad rad2deg/;
#use Astro::Montenbruck::MathUtils qw/frac ARCS polynome/;
use Astro::Montenbruck::Time qw/jd0/;

our @EXPORT_OK = qw/riseset/;
our $VERSION = 0.01;

Readonly our $RISE => 'rise';
Readonly our $SET  => 'set';

# 1. moonrise at h = 8'
# 2. sunrise at h = -50'
# 3. nautical twilight at h = -12 degrees
Readonly our $SINH0 => map { sin(deg2rad $_) } (8/60, -50/60, -12);


sub riseset {
    my $jd = shift;
    my $jd0 = jd0($jd);

    for my $iobj(0..2) {
        my $hour = 1.0;
        my $y_minus = sin_alt($iobj, )
    }

}
