=head1 NAME

Lingua::JA::Romanize::Juman - Romanization of Japanese language with JUMAN

=head1 SYNOPSIS

    use Lingua::JA::Romanize::Juman;

    my $conv = Lingua::JA::Romanize::Juman->new();
    my $roman = $conv->char( $kanji );
    printf( "<ruby><rb>%s</rb><rt>%s</rt></ruby>", $kanji, $roman );

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

This is JUMAN version of L<Lingua::JA::Romanize::Japanese> module.
Both of JUMAN and its Perl binding, Juman.pm, are required.

=head1 SEE ALSO

L<Lingua::JA::Romanize::Japanese>

http://www.kc.t.u-tokyo.ac.jp/nl-resource/juman.html (Japanese)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Yusuke Kawasaki. All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
    package Lingua::JA::Romanize::Juman;
    use strict;
    use Carp;
    use Juman;
    use Encode;
    use Lingua::JA::Romanize::Kana;
    use vars qw( $VERSION );
    $VERSION = "0.12";
# ----------------------------------------------------------------
    if ( $] > 5.008 ) {
        require Encode;
    } else {
        local $@;
        eval { require Jcode; };
        die "Jcode.pm is required on Perl $]\n" if $@;
    }
# ----------------------------------------------------------------
sub new {
    my $package = shift;
    my $self = {};
    $self->{juman} = Juman->new( @_ );
    $self->{kana} = Lingua::JA::Romanize::Kana->new();
    $self->{jcode} = Jcode->new("") unless ( $] > 5.008 );
    bless $self, $package;
    $self;
}
# ----------------------------------------------------------------
sub char {
    my $self = shift;
    my $src = shift;
    my $roman = $self->{kana}->char($src);
    return $roman if $roman;
    $src = $self->utf8_to_eucjp( $src );
    my $result = $self->{juman}->analysis( $src ) or return;
    my $node = $result->mrph(0) or return;
    my $kana = $node->yomi() or return;
    $kana = $self->eucjp_to_utf8( $kana );
    my @array = grep {$#$_>0} $self->{kana}->string($kana);
    return unless scalar @array;
    join( "", map {$_->[1]} @array );
}
# ----------------------------------------------------------------
sub chars {
    my $self = shift;
    my @array = $self->string( shift );
    join( " ", map {$#$_>0 ? $_->[1] : $_->[0]} @array );
}
# ----------------------------------------------------------------
sub string {
    my $self = shift;
    my $src = shift;
    Encode::from_to( $src, "UTF-8", "EUC-JP" );
    my $result = $self->{juman}->analysis( $src );
    my $array = [];

    foreach my $node ( $result->mrph() ) {
        my $midasi = $node->midasi();
        $midasi =~ s/^\\//;
        my $hinsi = $node->hinsi_id();
        my $kana = $node->yomi() if ( $hinsi != 1 );
        $midasi = $self->eucjp_to_utf8( $midasi ) if defined $midasi;
        $kana = $self->eucjp_to_utf8( $kana ) if defined $kana;
        my @array = $self->{kana}->string($kana) if $kana;
        my $roman = join( "", map {$_->[1]} grep {$#$_>0} @array ) if scalar @array;
        my $pair = $roman ? [ $midasi, $roman ] : [ $midasi ];
        push( @$array, $pair );
    }

    $self->{kana}->normalize( $array );
}
# ----------------------------------------------------------------
sub utf8_to_eucjp {
    my $self = shift;
    my $src = shift;
    if ( $] > 5.008 ) {
        Encode::from_to( $src, "UTF-8", "EUC-JP" );
    } else {
        $src = $self->{jcode}->set( \$src, "utf8" )->euc();
    }
    $src;
}
# ----------------------------------------------------------------
sub eucjp_to_utf8 {
    my $self = shift;
    my $src = shift;
    if ( $] > 5.008 ) {
        Encode::from_to( $src, "EUC-JP", "UTF-8" );
    } else {
        $src = $self->{jcode}->set( \$src, "euc" )->utf8();
    }
    $src;
}
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
