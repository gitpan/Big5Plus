# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あいいいいう' =~ /(あい{4,5}いう)/) {
    print "not ok - 1 $^X $__FILE__ not ('あいいいいう' =~ /あい{4,5}いう/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('あいいいいう' =~ /あい{4,5}いう/).\n";
}

__END__
