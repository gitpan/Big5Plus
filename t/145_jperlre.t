# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あうe' =~ /(あ[い-え]e)/) {
    if ("$1" eq "あうe") {
        print "ok - 1 $^X $__FILE__ ('あうe' =~ /あ[い-え]e/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('あうe' =~ /あ[い-え]e/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('あうe' =~ /あ[い-え]e/).\n";
}

__END__
