# This file is encoded in Big5Plus.
die "This file is not encoded in Big5Plus.\n" if q{��} ne "\x82\xa0";

use Big5Plus;
print "1..1\n";

# In string, @dog now must be written as \@dog (Perl 5.6.0�܂�)
# �u������̒��ł́A@dog�͍���\@dog�Ə����Ȃ���΂Ȃ�Ȃ��v
if ("�ԁ@\flower" eq pack('C10',0x89,0xd4,0x81,0x40,0x0C,0x6c,0x6f,0x77,0x65,0x72)) {
    print qq<ok - 1 "HANA yen flower"\n>;
}
else {
    print qq<not ok - 1 "HANA yen flower"\n>;
}

__END__

Big5Plus.pm �̏������ʂ��ȉ��ɂȂ邱�Ƃ����҂��Ă���

if ("�ԁ\@\flower" eq pack('C10',0x89,0xd4,0x81,0x40,0x0C,0x6c,0x6f,0x77,0x65,0x72)) {

Shift-JIS�e�L�X�g�𐳂�������
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm