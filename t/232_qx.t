# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{あ} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use Big5Plus;
print "1..1\n";

if ($^O !~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    print "ok - 1 # SKIP $^X $0\n";
    exit;
}

mkdir('directory',0777);
mkdir('D機能',0777);
open(FILE,'>D機能/file1.txt') || die "Can't open file: D機能/file1.txt\n";
print FILE "1\n";
close(FILE);
open(FILE,'>D機能/file2.txt') || die "Can't open file: D機能/file2.txt\n";
print FILE "1\n";
close(FILE);
open(FILE,'>D機能/file3.txt') || die "Can't open file: D機能/file3.txt\n";
print FILE "1\n";
close(FILE);

# qx
system('echo 1 >D機能\\qx.txt');
my @qx = split /\n/, `dir /b D機能 2>NUL`;
if (@qx) {
    print "ok - 1 qx $^X $__FILE__\n";
}
else {
    print "not ok - 1 qx: $! $^X $__FILE__\n";
}
system('del D機能\\qx.txt');

unlink('D機能/file1.txt');
unlink('D機能/file2.txt');
unlink('D機能/file3.txt');
rmdir('directory');
rmdir('D機能');

__END__
