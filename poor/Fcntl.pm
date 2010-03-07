# poor Fcntl.pm - substitute of real Fcntl.pm for Sjis software

package Fcntl;

use Symbol;

sub import {
    my $pkg = shift;
    my $callpkg = caller(0);
    for (qw(O_RDONLY O_WRONLY O_APPEND O_CREAT O_TRUNC LOCK_SH LOCK_EX LOCK_NB sysopen)) {
        *{"$callpkg\::$_"} = \&{"$pkg\::$_"};
    }
}

sub unimport {}

sub O_RDONLY {0}
sub O_WRONLY {1}
sub O_APPEND {8}
sub O_CREAT  {256}
sub O_TRUNC  {512}

sub LOCK_SH  {1}
sub LOCK_EX  {2}
sub LOCK_NB  {4}

sub sysopen (*$$) {
    my($fh,$filename,$mode) = @_;

    # 7.6. Writing a Subroutine That Takes Filehandles as Built-ins Do
    # in Chapter 7. File Access
    # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.

    $fh = Symbol::qualify_to_ref($fh, caller());

    if ($mode == O_RDONLY) {
        return open $fh, $filename;
    }
    elsif ($mode == (O_WRONLY | O_TRUNC | O_CREAT)) {
        return open $fh, ">$filename";
    }
    elsif ($mode == (O_WRONLY | O_APPEND)) {
        return open $fh, ">>$filename";
    }

    die "sysopen: Can't mode($mode)";
}

1;

__END__

=head1 NAME

Fcntl - substitute of real Fcntl.pm for Sjis software

=head1 SYNOPSIS

    use Fcntl;
    use Fcntl qw(:DEFAULT :flock); # same as upper line

=head1 DESCRIPTION

This file is a substitute of Fcntl.pm.

When standard modules is not supported, you can use this file instead
of Fcntl.pm for running Sjis software.

=head1 EXPORTED SYMBOLS

By default your system's O_* constants (eg, O_RDONLY O_WRONLY) are
exported into your namespace.

You can use that the flock() constants (LOCK_SH, LOCK_EX and LOCK_NB)
be provided always.

See L<perlopentut> to learn about the uses of the O_* constants
with sysopen().

=head1 BUGS

This module has only a minimum function for the Sjis software.

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
