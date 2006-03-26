# ----------------------------------------------------------------
    use strict;
    use Test::More tests => 12;
    BEGIN { use_ok('Lingua::JA::Romanize::Japanese'); };
# ----------------------------------------------------------------
{
    my $roman = Lingua::JA::Romanize::Japanese->new();
    ok( ref $roman, "new" );

    ok( (! defined $roman->char("a")), "char: ascii" );
    is( $roman->char("\xE3\x81\xB2"), "hi", "char: hiragana hi" );
    is( $roman->char("\xE3\x82\xAB"), "ka", "char: katakana ka" );
    ok( $roman->char("\xE6\xBC\xA2") =~ /(^|\W)kan(\W|$)/, "char: kanji kan" );

    my @t1 = $roman->string("\xE6\xBC\xA2\xE5\xAD\x97");
    ok( $t1[0][1] =~ /(^|\W)kanji(\W|$)/, "string: okuri-nashi kanji" );

    my @t2 = $roman->string("\xE7\xAC\x91\xE3\x81\x86");
    ok( $t2[0][1] =~ /(^|\W)wara(\W|$)/, "string: okuri-ari warau" );

    my @t3 = $roman->string("\xE6\x9C\x89\xE3\x82\x8B");
    ok( $t3[0][1] =~ /(^|\W)a(\W|$)/, "string: okuri-ari aru" );

    my @t4 = $roman->string("\xE6\x9C\x89");
    ok( $t4[0][1] =~ /(^|\W)yuu(\W|$)/, "string: okuri-nashi yuu" );

    my @t5 = $roman->string("\xE5\xB7\xAE\xE5\x87\xBA\xE3\x81\x99");
    ok( $t5[0][1] =~ /(^|\W)sashida(\W|$)/, "string: okuri-ari sashidasu" );

    my @t6 = $roman->string("\xE5\xB7\xAE\xE5\x87\xBA\xE4\xBA\xBA");
    ok( $t6[0][1] =~ /(^|\W)sashidashinin(\W|$)/, "string: okuri-nashi sashidashinin" );
}
# ----------------------------------------------------------------
#   use Data::Dumper;
#   print Dumper( $roman->chars("some string") );
# ----------------------------------------------------------------
;1;
# ----------------------------------------------------------------
