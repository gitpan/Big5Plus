# poor Symbol.pm - substitute of real Symbol.pm for Sjis software

package Symbol;

sub import {
    my $pkg = shift;
    my $callpkg = caller(0);
    for (qw(gensym qualify qualify_to_ref)) {
        *{"$callpkg\::$_"} = \&{"$pkg\::$_"};
    }
}

sub unimport {}

my $genpkg = "Symbol::";
my $genseq = 0;

sub gensym () {
    my $name = "GEN" . $genseq++;
    my $ref = \*{$genpkg . $name};
    delete $$genpkg{$name};
    $ref;
}

sub qualify ($;$) {
    my ($name) = @_;
    if (!ref($name) && index($name, '::') == -1 && index($name, "'") == -1) {
        my $pkg;
        # Global names: special character, "^xyz", or other.
        if ($name =~ /^(([^a-z])|(\^[a-z_]+))\z/i || $global{$name}) {
            # RGS 2001-11-05 : translate leading ^X to control-char
            $name =~ s/^\^([a-z_])/'qq(\c'.$1.')'/eei;
            $pkg = "main";
        }
        else {
            $pkg = (@_ > 1) ? $_[1] : caller;
        }
        $name = $pkg . "::" . $name;
    }
    $name;
}

sub qualify_to_ref ($;$) {
    return \*{ qualify $_[0], @_ > 1 ? $_[1] : caller };
}

1;

__END__

=head1 NAME

Symbol - substitute of real Symbol.pm for Sjis software

=head1 SYNOPSIS

    use Symbol;

    $sym = gensym;
    open($sym, "filename");
    $_ = <$sym>;
    # etc.

    print qualify("x"), "\n";              # "main::x"
    print qualify("x", "FOO"), "\n";       # "FOO::x"
    print qualify("BAR::x"), "\n";         # "BAR::x"
    print qualify("BAR::x", "FOO"), "\n";  # "BAR::x"
    print qualify("STDOUT", "FOO"), "\n";  # "main::STDOUT" (global)
    print qualify(\*x), "\n";              # returns \*x
    print qualify(\*x, "FOO"), "\n";       # returns \*x

    # use strict refs;
    print { qualify_to_ref $fh } "foo!\n";
    $ref = qualify_to_ref $name, $pkg;

=head1 DESCRIPTION

This file is a substitute of Symbol.pm.

When standard modules is not supported, you can use this file instead of
Symbol.pm for running Sjis software.

C<Symbol::gensym> creates an anonymous glob and returns a reference
to it.  Such a glob reference can be used as a file or directory
handle.

C<Symbol::qualify> turns unqualified symbol names into qualified
variable names (e.g. "myvar" -E<gt> "MyPackage::myvar").  If it is given a
second parameter, C<qualify> uses it as the default package;
otherwise, it uses the package of its caller.  Regardless, global
variable names (e.g. "STDOUT", "ENV", "SIG") are always qualified with
"main::".

Qualification applies only to symbol names (strings).  References are
left unchanged under the assumption that they are glob references,
which are qualified by their nature.

C<Symbol::qualify_to_ref> is just like C<Symbol::qualify> except that it
returns a glob ref rather than a symbol name, so you can use the result
even if C<use strict 'refs'> is in effect.

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
