# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{��} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

# �}�b�`���Ȃ��͂��Ȃ̂Ƀ}�b�`����i�P�j
if ("���J��" =~ /�|�b�g/) {
    print qq<not ok - 1 "YAKAN" =~ /POTTO/>;
}
else {
    print qq<ok - 1 "YAKAN" =~ /POTTO/>;
}

__END__

Shift-JIS�e�L�X�g�𐳂�������
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
