use strict;

# make make.bat
open(MAKEBAT,">make.bat") || die "Can't open file: make.bat\n";
print MAKEBAT <DATA>;
close(MAKEBAT);

__END__
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14

# poor make

undef @rem;
use strict;
use File::Path;
use File::Copy;
use File::Basename;
use Test::Harness;
use Archive::Tar;
use Compress::Zlib;

unless (@ARGV) {
    die <<END;

usage: make
usage: make test
usage: make install
usage: make dist
usage: make tar.bat

END
}

# get file list
open(MANIFEST,"MANIFEST") || die "Can't open file: MANIFEST\n";
chomp(my @file = <MANIFEST>);
close(MANIFEST);

for my $target (@ARGV) {
    if ($target eq 'test') {
        my @test = grep m{ \A (?: test\.pl | t/.+\.t ) \z }xmsi, @file;
        runtests(@test);
    }
    elsif ($target eq 'install') {

        # install *.pm files to /Perl/site/lib
        my($perl_site_lib) = grep(m{/site/}xmsi, @INC);
        for (grep m/ \. pm \z /xmsi, @file) {
            print STDERR "copy $_ $perl_site_lib\n";
            copy($_, $perl_site_lib);
        }

        # install *.pl and *.bat files to /Perl/bin
        my($perl_bin) = $^X =~ /^(.*)\\[^\\]*$/;
        for (grep m/ \. (?: pl | bat ) \z /xmsi, @file) {
            next if m/(?: Makefile | test ) \.pl  $/xmsi;
            next if m/(?: make | tar )      \.bat $/xmsi;
            print STDERR "copy $_ $perl_bin\n";
            copy($_, $perl_bin);
        }
    }
    elsif ($target eq 'dist') {

        # make work directory
        my($changes) = grep(/^Changes$/i,@file);
        open(CHANGES,$changes) || die "Can't open file: $changes\n";
        my $version;
        while (<CHANGES>) {
            if (/^(\d+\.\d+)/) {
                $version = $1;
            }
        }
        close(CHANGES);
        my $basename = basename($file[0], '.pm','.pl','.bat');
        my $tardir = "$basename-$version";
        rmtree($tardir,0,0);

        # rewrite META.yml file
        if(my($metayml) = grep(/^META\.yml$/i,@file)) {
            if (open(METAYML,$metayml)) {
                $_ = join('',<METAYML>);
                close(METAYML);
                if (open(METAYML,">$metayml")) {
                    s/^(version:\s*)\d+\.\d+/$1$version/m;
                    binmode(METAYML);
                    print METAYML $_;
                    close(METAYML);
                }
            }
        }

        # make *.tar file
        my $tar = Archive::Tar->new;
        for my $file (@file) {
            if (-e $file) {
                mkpath(dirname("$tardir/$file"),0,0777);
                print STDERR "copy $file $tardir/$file\n";
                copy($file, "$tardir/$file");
                $tar->add_files("$tardir/$file");
            }
            else {
                die "file: $file is not exists.\n";
            }
        }
        my $tarfile = "$tardir.tar";
        $tar->write($tarfile);
        rmtree($tardir,0,0);

        # make *.tar.gz file
        my $gz = gzopen("$tarfile.gz", 'wb');
        open(TAR, $tarfile) || die "Can't open file: $tarfile\n";
        binmode(TAR);
        $gz->gzwrite(join('',<TAR>));
        close(TAR);
        $gz->gzclose;
        unlink $tarfile;

		# untar test
		system("make.bat tar.bat");
		system("tar.bat xzvf $tarfile.gz");
    }
    elsif ($target eq 'tar.bat') {

        # make tar.bat
        open(TARBAT,">tar.bat") || die "Can't open file: tar.bat\n";
        print TARBAT <DATA>;
        close(TARBAT);
    }
    else {
        warn "unknown target: $target.\n";
    }
}

__END__
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14

# poor tar

undef @rem;
use strict;
use Compress::Zlib;
use Archive::Tar;

if ($ARGV[0] ne 'xzvf') {
    die <<END;

usage: tar xzvf file1.tar.gz file2.tar.gz ...

** This tar supports xzvf option only. **
END
}

for my $gzfile (grep m/\.tar\.gz$/xmsi, @ARGV) {

    my $gz = gzopen($gzfile, 'rb');
    (my $tarfile = $gzfile) =~ s/\.gz$//xmsi;
    open(TAR,">$tarfile") || die "Can't open file: $tarfile\n";
    binmode(TAR);
    while ($gz->gzreadline(my $line)) {
        print TAR $line;
    }
    $gz->gzclose;
    close(TAR);

    my $tar = Archive::Tar->new($tarfile,1);
    for my $file ($tar->list_files){
        if (-e $file) {
            print STDERR "skip $file is already exists.\n";
        }
        else {
            print STDERR "x $file\n";
            $tar->extract($file);
        }
    }
    unlink $tarfile;
}

__END__
:endofperl
