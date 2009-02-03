@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
exit /b %errorlevel%
goto endofperl
@rem ';
#!perl
#line 15
my $VERSION = "1.0.1"; undef @rem;
######################################################################
#
# perl55 -  execute perlscript on the perl5.5 without %PATH% settings
#
# Copyright (c) 2008, 2009 INABA Hitoshi <ina@cpan.org>
#
######################################################################

use strict;

# print usage
unless (@ARGV) {
    die <<END;

$0 ver.$VERSION

usage:

C:\\>$0 perlscript.pl ...

Find perl5.5 order by,
  1st, C:\\Perl55\\bin\\perl.exe
  2nd, D:\\Perl55\\bin\\perl.exe
  3rd, E:\\Perl55\\bin\\perl.exe
                :
                :

When found it, then execute perlscript on the its perl.exe.

END
}

# quote by "" if include space
@ARGV = map { / / ? qq{"$_"} : $_ } @ARGV;

# if this script running under perl5.5
if ($] =~ /^5\.005/) {
    exit system($^X, @ARGV);
}

# if .conf file exists
if (open(CONF,"$0.conf")) {
    my $perlbin = <CONF>;
    close CONF;
    if (-e $perlbin) {
        exit system($perlbin, @ARGV);
    }
}

# find perl5.5 in the computer
my @perlbin = ();
eval <<'END';
use Win32API::File qw(:DRIVE_);

Win32API::File::GetLogicalDriveStrings(4*26+1, my $LogicalDriveStrings);
for my $driveroot (split /\0/, $LogicalDriveStrings) {
    my $type = Win32API::File::GetDriveType($driveroot);
    # 0 DRIVE_UNKNOWN
    # 1 DRIVE_NO_ROOT_DIR
    # 2 DRIVE_REMOVABLE
    # 3 DRIVE_FIXED
    # 4 DRIVE_REMOTE
    # 5 DRIVE_CDROM
    # 6 DRIVE_RAMDISK
    if (($type == DRIVE_FIXED)  or
        ($type == DRIVE_REMOTE) or
        ($type == DRIVE_RAMDISK)
    ) {
        if (-e "${driveroot}perl55\\bin\\perl.exe") {
            push @perlbin, "${driveroot}perl55\\bin\\perl.exe";
        }
    }
}
END

# get drive list by 'net share' command
# Windows NT, Windows 2000, Windows XP, Windows Server 2003, Windows Vista
# maybe also Windows Server 2008
if ($@) {
    while (`net share 2>NUL` =~ /\b([A-Z])\$ +\1:\\ +Default share\b/ig) {
        if (-e "$1:\\perl55\\bin\\perl.exe") {
            push @perlbin, "$1:\\perl55\\bin\\perl.exe";
        }
    }
}

# perl5.5 not found
if (@perlbin == 0) {
    die "$0: nothing \\Perl55\\bin\\perl.exe nowhere.\n";
}

# only one perl5.5 found
elsif (@perlbin == 1) {

    # execute perlscript on the its perl.exe.
    if (open(CONF,">$0.conf")) {
        print CONF $perlbin[0];
        close CONF;
    }
    exit system($perlbin[0], @ARGV);
}

# if many perl5.5 found
elsif (@perlbin > 1) {

    # select one perl.exe
    print STDERR "This computer has many perl.exe.\n";
    print STDERR map {"$_\n"} @perlbin;
    print STDERR "Which perl.exe do you use? (exit by [Ctrl]+[C])";
    while (1) {
        print STDERR "drive = ";
        my $drive = <STDIN>;
        $drive = substr($drive,0,1);
        if (my($perlbin) = grep /^$drive/i, @perlbin) {

            # execute perlscript on the its perl.exe.
            if (open(CONF,">$0.conf")) {
                print CONF $perlbin;
                close CONF;
            }
            exit system($perlbin, @ARGV);
        }
    }
}

__END__

=pod

=head1 NAME

perl55 - execute perlscript on the perl5.5 without %PATH% settings

=head1 SYNOPSIS

B<perl55> [perlscript.pl]

=head1 DESCRIPTION

This program is useful when perl5.5 and perl5.5 are on the one computer.
Set perl5.5's bin directory to environment variable %PATH%, do not set perl5.5's
bin directory to %PATH%.

It is necessary to install perl5.5 in "\Perl55\bin" directory of the drive of
either. This program is executed by perl5.5, and find the perl5.5 and execute it.

 Find perl5.5 order by,
   1st, C:\Perl55\bin\perl.exe
   2nd, D:\Perl55\bin\perl.exe
   3rd, E:\Perl55\bin\perl.exe
                 :
                 :

When found it, then execute perlscript on the its perl.exe.

=head1 EXAMPLES

    C:\> perl55 foo.pl
    [..execute foo.pl by perl5.5..]

=head1 BUGS AND LIMITATIONS

Please patches and report problems to author are welcome.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

This project was originated by INABA Hitoshi.
For any questions, use E<lt>ina@cpan.orgE<gt> so we can share
this file.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

perl

=cut

:endofperl
