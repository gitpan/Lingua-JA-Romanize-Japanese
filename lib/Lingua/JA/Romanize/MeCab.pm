=head1 NAME

Lingua::JA::Romanize::MeCab - Romanization of Japanese language with MeCab

=head1 SYNOPSIS

    use Lingua::JA::Romanize::MeCab;

    my $conv = Lingua::JA::Romanize::MeCab->new();
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

This is MeCab version of L<Lingua::JA::Romanize::Japanese> module.
MeCab's Perl binding, MeCab.pm, is required.

=head1 SEE ALSO

L<Lingua::JA::Romanize::Japanese>

http://mecab.sourceforge.jp/ (Japanese)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Yusuke Kawasaki. All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
# ----------------------------------------------------------------
    package Lingua::JA::Romanize::MeCab;
    use strict;
    use Carp;
    use MeCab;
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
    $self->{mecab} = MeCab::Tagger->new( @_ );
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
    my $pair = ($self->string( $src ))[0];  # need loop for nodes which have surface
    return if ( scalar @$pair == 1 );
    return $pair->[1];
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
    my $src = $self->utf8_to_eucjp( shift );
    my $array = [];

    my $node = $self->{mecab}->parseToNode( $src );
    for( ; $node; $node = $node->{next} ) {
        next unless defined $node->{surface};
        my $midasi = $self->eucjp_to_utf8( $node->{surface} );
        my $kana = (split( /,/, $node->{feature} ))[7];
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
