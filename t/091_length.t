# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

use Big5Plus;
print "1..2\n";

my $__FILE__ = __FILE__;

if (length('あいうえお') == 10) {
    print qq{ok - 1 length('あいうえお') == 10 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 length('あいうえお') == 10 $^X $__FILE__\n};
}

if (Big5Plus::length('あいうえお') == 5) {
    print qq{ok - 2 Big5Plus::length('あいうえお') == 5 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 Big5Plus::length('あいうえお') == 5 $^X $__FILE__\n};
}

__END__
