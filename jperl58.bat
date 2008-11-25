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
$VERSION = "1.0.0"; undef @rem;
######################################################################
#
# jperl58 -  execute ShiftJIS perlscript on the perl5.8
#
# Copyright (c) 2008 INABA Hitoshi <ina@cpan.org>
#
######################################################################

# print usage
unless (@ARGV) {
    die <<END;

$0 ver.$VERSION

usage:

C:\\>$0 perlscript.pl ...     --- for ShiftJIS script

C:\\>$0 --s perlscript.pl ... --- for ShiftJIS script

C:\\>$0 --b perlscript.pl ... --- for Big5Plus script

C:\\>$0 --g perlscript.pl ... --- for GBK script

C:\\>$0 --h perlscript.pl ... --- for UHC script

END
}

# quote by "" if include space
for (@ARGV) {
    $_ = qq{"$_"} if / /;
}

# compile script
$filter = 'esjis.pl';
for (@ARGV) {
    if (s/^--([sbgu])$//) {
        $filter = {
            's' => 'esjis.pl',
            'b' => 'ebig5plus.pl',
            'g' => 'egbk.pl',
            'u' => 'euhc.pl',
        }->{$1};
        next;
    }
    next if /^-/; # skip command line option

    if (not -e $_) {
        die "$0: script $_ is not exists.";
    }
    else {

        # if new *.e file exists
        if ((-e "$_.e") and ((stat("$_.e"))[9] > (stat($_))[9]) and ((stat("$_.e"))[9] > (stat(&abspath($filter)))[9])) {
            $_ = "$_.e";
            last;
        }

        # make temp filename
        do {
            $tmpnam = sprintf('%s.%d.%d', $_, time, rand(10000));
        } while (-e $tmpnam);

        # escape ShiftJIS of script
        if (system(qq{$^X -S $filter $_ > $tmpnam}) == 0) {
            rename($tmpnam,"$_.e") or unlink $tmpnam;
        }
        elsif (system(qq{perl58.bat -S $filter $_ > $tmpnam}) == 0) {
            rename($tmpnam,"$_.e") or unlink $tmpnam;
        }
        else {
            unlink $tmpnam;
            die "$0: Can't execute script: $_";
        }
    }

    # rewrite script filename
    $_ = "$_.e";
    last;
}

# if this script running under perl5.8
if ($] =~ /^5\.008/) {
    exit system($^X, @ARGV);
}
else {
    exit system('perl58.bat', @ARGV);
}

# find absolute path
sub abspath($) {
    my($file) = @_;

    if (-e $file) {
        return $file;
    }

    # -S option
    for my $dir (split /;/, $ENV{'PATH'}) {
        if (-e qq{$dir\\$file}) {
            return qq{$dir\\$file};
        }
    }

    die "Can't find file: $file\n";
}

__END__

=pod

=head1 NAME

jperl58 - execute ShiftJIS perlscript on the perl5.8

=head1 SYNOPSIS

    B<jperl58>     [perlscript.pl]   --- for ShiftJIS script

    B<jperl58 --s> [perlscript.pl]   --- for ShiftJIS script

    B<jperl58 --b> [perlscript.pl]   --- for Big5Plus script

    B<jperl58 --g> [perlscript.pl]   --- for GBK script

    B<jperl58 --h> [perlscript.pl]   --- for UHC script

=head1 DESCRIPTION

This utility converts a CJK perl script into a escaped script that
can be executed by original perl5.8 on DOS-like operating systems.

If the up-to-date escaped file already exists, it is not made again.

When running perl is not version 5.8, the escaped script will execute
by perl58.bat.

=head1 EXAMPLES

    C:\> jperl58 foo.pl
    [..creates foo.pl.e and execute it..]

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

perl, esjis.pl, ebig5plus.pl, egbk.pl, euhc.pl

=cut

:endofperl
