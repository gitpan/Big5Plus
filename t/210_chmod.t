# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{��} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use Big5Plus;
print "1..1\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

open(FILE,'>F�@�\') || die "Can't open file: F�@�\\n";
print FILE "1\n";
close(FILE);

# chmod
if (chmod(0755,'F�@�\') == 1) {
    print "ok - 1 chmod $^X $__FILE__\n";
}
else {
    print "not ok - 1 chmod: $! $^X $__FILE__\n";
}

unlink('F�@�\');

__END__