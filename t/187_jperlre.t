# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{��} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('��A��' =~ /��[^]]��/) {
    print "ok - 1 $^X $__FILE__ ('��A��' =~ /��[^]]��/)\n";
}
else {
    print "not ok - 1 $^X $__FILE__ ('��A��' =~ /��[^]]��/)\n";
}

__END__