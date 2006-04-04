=head1 NAME

Lingua::JA::Romanize::Kana - Romanization of Japanese Hiragana/Katakana

=head1 SYNOPSIS

    use Lingua::JA::Romanize::Kana;

    my $conv = Lingua::JA::Romanize::Kana->new();
    my $roman = $conv->char( $kana );
    printf( "<ruby><rb>%s</rb><rt>%s</rt></ruby>", $kana, $roman );

    my @array = $conv->string( $string );
    foreach my $pair ( @array ) {
        my( $raw, $ruby ) = @$pair;
        if ( defined $ruby ) {
            printf( "<ruby><rb>%s</rb><rt>%s</rt></ruby>", $raw, $ruby );
        } else {
            print $raw;
        }
    }

=head1 DESCRIPTION

Hiragana and Katakana are general terms for the syllabic Japanese scripts.

=head1 METHODS

=head2 $conv = Lingua::JA::Romanize::Kana->new();

This constructer methods returns a new object with its dictionary cached.

=head2 $roman = $conv->char( $Kana );

This method returns romanized letters of a Kana character.
It returns undef when $Kana is not a valid Kana character.
The argument's encoding must be UTF-8.
Both of Hiragana or Katakana characters are allowed.
But Kanji character is not supported by this module.
See L<Lingua::JA::Romanize::Japanese>.

=head2 $roman = $conv->chars( $string );

This method returns romanized letters of Kana characters.

=head2 @array = $conv->string( $string );

This method returns a array of referenced arrays
which are pairs of a Kana chacater and its romanized letters.

    $array[0]           # first Kana character's pair (array)
    $array[1][0]        # secound Kana character itself
    $array[1][1]        # its romanized letters

=head1 SEE ALSO

L<Lingua::JA::Romanize::Japanese>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Yusuke Kawasaki. All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
    package Lingua::JA::Romanize::Kana;
    use strict;
    use vars qw( $VERSION );
    $VERSION = "0.12";
# ----------------------------------------------------------------
    my $KANA_MAP = [qw(
            xa  a   xi  i   xu  u   xe  e   xo  o   ka  ga  ki  gi  ku
        gu  ke  ge  ko  go  sa  za  shi ji  su  zu  se  ze  so  zo  ta
        da  chi ji  xtu tsu zu  te  de  to  do  na  ni  nu  ne  no  ha
        ba  pa  hi  bi  pi  fu  bu  pu  he  be  pe  ho  bo  po  ma  mi
        mu  me  mo  xya ya  xyu yu  xyo yo  ra  ri  ru  re  ro  xwa wa
        wi  we  wo  n   vu  ka  ke
    )];
# ----------------------------------------------------------------
sub new {
    my $package = shift;
    my $self = {@_};
    bless $self, $package;
    $self;
}
# ----------------------------------------------------------------
sub char {
    my $self = shift;
    my $char = shift;
    my( $c1, $c2, $c3, $c4 ) = unpack("C*",$char);
    return if ( ! defined $c3 || defined $c4 );
    my $ucs2 = (($c1 & 0x0F)<<12) | (($c2 & 0x3F)<<6) | ($c3 & 0x3F);
    return if ( $ucs2 < 0x3041 );
    return if ( $ucs2 > 0x3093 && $ucs2 < 0x30A1 );
    return if ( $ucs2 > 0x30F6 );
    my $offset = ( $ucs2 - 0x3041 ) % 96;
    $KANA_MAP->[$offset];
}
# ----------------------------------------------------------------
sub chars {
    my $self = shift;
    my @array = $self->string( shift );
    join( "", map {$#$_>0 ? $_->[1] : $_->[0]} @array );
}
# ----------------------------------------------------------------
sub string {
    my $self = shift;
    my $src = shift;
    my $array = [];

    while ( $src =~ /(\xE3[\x80-\xBF]{2})|([^\xE3]+)/sg ) {
        if ( defined $1 ) {
            my $pair = [ $1 ];
            my $roman = $self->char( $1 );
            $pair->[1] = $roman if defined $roman;
            push( @$array, $pair );
        } else {
            push( @$array, [ $2 ] );
        }
    }

    $self->normalize( $array );
}
# ----------------------------------------------------------------
sub normalize {
    my $self = shift;
    my $array = shift;

    for( my $i=0; $i<$#$array; $i ++ ) {
        next if ( scalar @{$array->[$i]} < 2 );
        next if ( scalar @{$array->[$i+1]} < 2 );
        my $this = $array->[$i]->[1];
        my $next = $array->[$i+1]->[1];
        if ( $this eq "n" && $next =~ /^[bmp]/ ) {
            $array->[$i]->[1] = "m";
        } elsif ( $this eq "xtu" && $next =~ /^([^aiueo])/ ) {
            my $head = $1;
            $head = "t" if ( $head eq "c" );
            $array->[$i+1]->[0] = $array->[$i]->[0].$array->[$i+1]->[0];
            $array->[$i+1]->[1] = $head.$next;
            $array->[$i] = undef;
        } elsif ( $this =~ /i$/ && $next =~ /^xy/ ) {
            my $head = ( $this =~ /^(.*)i$/ )[0];
            my $tail = ( $next =~ /^x(y.*)$/ )[0];
            $tail =~ s/^y// if ( $head =~ /(.h|^j)$/ );
            $array->[$i+1]->[0] = $array->[$i]->[0].$array->[$i+1]->[0];
            $array->[$i+1]->[1] = $head.$tail;
            $array->[$i] = undef;
        } elsif ( $this =~ /o$/ && $next =~ /^x?o$/ ) {
            $array->[$i+1]->[0] = $array->[$i]->[0].$array->[$i+1]->[0];
            $array->[$i+1]->[1] = $this."h";
            $array->[$i] = undef;
        } elsif ( $this eq "vu" && $next =~ /^x([aiueo])$/ ) {
            my $tail = $1;
            $array->[$i+1]->[0] = $array->[$i]->[0].$array->[$i+1]->[0];
            $array->[$i+1]->[1] = "v".$tail;
            $array->[$i] = undef;
        }
    }
    $array = [ grep { ref $_ } @$array ];

    for( my $i=0; $i<=$#$array; $i ++ ) {
        next if ( scalar @{$array->[$i]} < 2 );
        $array->[$i]->[1] =~ s/^x//;
    }

    @$array;
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
