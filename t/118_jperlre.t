# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{��} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('����q' =~ /(����{1,}����)/) {
    print "not ok - 1 $^X $__FILE__ not ('����q' =~ /����{1,}����/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('����q' =~ /����{1,}����/).\n";
}

__END__
