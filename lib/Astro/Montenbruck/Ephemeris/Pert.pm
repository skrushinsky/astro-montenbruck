package Astro::Montenbruck::Ephemeris::Pert;

use strict;
use warnings;
use Exporter qw/import/;
our @EXPORT_OK = qw(pert addthe);

our $VERSION = 0.01;

use constant O => 16;
use constant {
    Om1 => O - 1,
    Op1 => O + 1,
};

sub addthe {
    $_[0] * $_[2] - $_[1] * $_[3], $_[1] * $_[2] + $_[0] * $_[3];
}

sub pert {
    my %arg      = @_;
    my $callback = $arg{callback};
    my $_m_T     = $arg{T};
    my $_M       = $arg{M};
    my $_I_min   = $arg{I_min};
    my $_I_max   = $arg{I_max};
    my $_i_min   = $arg{i_min};
    my $_i_max   = $arg{i_max};
    my $_phi     = $arg{phi} || 0.0;
    my $_m_cosM  = cos( $arg{M} );
    my $_m_sinM  = sin( $arg{M} );
    my $_m_C     = [];
    my $_m_S     = [];
    my $_m_c     = [];
    my $_m_s     = [];
    $_m_C->[O] = cos($_phi);
    $_m_S->[O] = sin($_phi);

    for ( my $i = 0 ; $i < $_I_max ; $i++ ) {
        my $k  = O + $i;
        my $k1 = $k + 1;
        ( $_m_C->[$k1], $_m_S->[$k1] ) =
          addthe( $_m_C->[$k], $_m_S->[$k], $_m_cosM, $_m_sinM );
    }
    for ( my $i = 0 ; $i > $_I_min ; $i-- ) {
        my $k  = O + $i;
        my $k1 = $k - 1;
        ( $_m_C->[$k1], $_m_S->[$k1] ) =
          addthe( $_m_C->[$k], $_m_S->[$k], $_m_cosM, -$_m_sinM );
    }
    $_m_c->[O]   = 1.0;
    $_m_c->[Op1] = cos( $arg{m} );
    $_m_c->[Om1] = +$_m_c->[Op1];
    $_m_s->[O]   = 0.0;
    $_m_s->[Op1] = sin( $arg{m} );
    $_m_s->[Om1] = -$_m_s->[Op1];
    for ( my $i = 1 ; $i < $_i_max ; $i++ ) {
        my $k  = O + $i;
        my $k1 = $k + 1;
        ( $_m_c->[$k1], $_m_s->[$k1] ) =
          addthe( $_m_c->[$k], $_m_s->[$k], $_m_c->[Op1], $_m_s->[Op1] );
    }
    for ( my $i = -1 ; $i > $_i_min ; $i-- ) {
        my $k  = O + $i;
        my $k1 = $k - 1;
        ( $_m_c->[$k1], $_m_s->[$k1] ) =
          addthe( $_m_c->[$k], $_m_s->[$k], $_m_c->[Om1], $_m_s->[Om1] );
    }
    my $_m_u = 0.0;
    my $_m_v = 0.0;

    sub {
        my ( $I, $i, $iT, $dlc, $dls, $drc, $drs, $dbc, $dbs ) = @_;
        my $k = O + $I;
        my $j = O + $i;
        if ( $iT == 0 ) {
            ( $_m_u, $_m_v ) =
              addthe( $_m_C->[$k], $_m_S->[$k], $_m_c->[$j], $_m_s->[$j] );
        }
        else {
            $_m_u *= $_m_T;
            $_m_v *= $_m_T;
        }
        $callback->(
            $dlc * $_m_u + $dls * $_m_v,
            $drc * $_m_u + $drs * $_m_v,
            $dbc * $_m_u + $dbs * $_m_v
        );
      }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Pert - Calculation of perturbations.

=head1 SYNOPSIS

  use Astro::Montenbruck::Ephemeris::Pert qw /pert/;

  ($dl, $dr, $db) = (0, 0, 0); # Corrections in longitude ["],
  $pert_cb = sub { $dl += $_[0]; $dr += $_[1]; $db += $_[2] };

  # Perturbations by Venus
  $term
    = pert( T     => $t,
            M     => $m1,
            m     => $m2,
            I_min =>-1,
            I_max => 9,
            i_min =>-5,
            i_max => 0,
            callback => $pert_cb);

  # Perturbations by the Earth
  $term
    = pert( T     => $t,
            M     => $m1,
            m     => $m3,
            I_min => 0,
            I_max => 2,
            i_min =>-4,
            i_max =>-1,
            callback => $pert_cb);

=head1 DESCRIPTION

Calculates perturbations for Sun, Moon and the 8 planets. Used internally by
L<Astro::Montenbruck::Ephemeris> module.

=head2 EXPORT

=over

=item * L<pert(%args)>

=item * L<addthe($a, $b, $c, $d)>

=back

=head1 SUBROUTINES/METHODS

=head2 pert(%args)

Calculates perturbations to ecliptic heliocentric coordinates of the planet.

=head3 Named arguments

=over

=item * $t — time in centuries since epoch 2000.0

=item * M, m, I_min, I_max, i_min, i_max — misc. internal indices

=item * callback — reference to a function which receives corrections to 3
coordinates and typically applies them (see the example above)

=back

=head2 addthe($a, $b, $c, $d)

Calculates C<c=cos(a1+a2)> and C<s=sin(a1+a2)> from the addition theorems for
C<c1=cos(a1), s1=sin(a1), c2=cos(a2) and s2=sin(a2)>

=head3 Arguments

c1, s1, c2, s2


=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
