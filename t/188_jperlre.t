# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あA]い' =~ /あ[^]]い/) {
    print "not ok - 1 $^X $__FILE__ ('あA]い' =~ /あ[^]]い/)\n";
}
else {
    print "ok - 1 $^X $__FILE__ ('あA]い' =~ /あ[^]]い/)\n";
}

__END__
