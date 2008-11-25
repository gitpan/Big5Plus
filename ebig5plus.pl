######################################################################
#
# ebig5plus.pl - Source code filter to escape Big5Plus
#
# Copyright (c) 2008 INABA Hitoshi <ina@cpan.org>
#
######################################################################

use strict;
use 5.00503;

use vars qw($VERSION);
$VERSION = sprintf '%d.%02d', q$Revision: 0.29 $ =~ m/(\d+)/oxmsg;

use constant DEBUG => 1;
local $SIG{__WARN__} = sub { die "$0: ", @_ } if DEBUG;
local $^W = 1;

$| = 1;

BEGIN {
    if ($^X =~ m/jperl/oxmsi) {
        die "$0: need perl(not jperl) 5.00503 or later. (\$^X==$^X)";
    }
}

# regexp of character
my $qq_char   = qr/\\c[\x40-\x5F]|\\[\x81-\xFE][\x00-\xFF]|[\x81-\xFE\\][\x00-\xFF]|[\x00-\xFF]/oxms;
my  $q_char   = qr/[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]/oxms;
my $your_char = q {[\x81-\xFE][\x00-\xFF]|[\x00-\xFF]};

# P.1023 Appendix W.9 Multibyte Anchoring
# of ISBN 1-56592-224-7 CJKV Information Processing

my $your_gap  = q{(?:(?:[\x81-\xFE]{2})*?|[^\x81-\xFE](?:[\x81-\xFE]{2})*?)};

use vars qw($nest);

# regexp of nested parens in qqXX

# P.341 in Matching Nested Constructs with Embedded Code
# of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

my $qq_paren   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] | \\[\x81-\xFE][\x00-\xFF] | [\x81-\xFE\\][\x00-\xFF] |
                    [^()] |
                             \(  (?{$nest++}) |
                             \)  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_brace   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] | \\[\x81-\xFE][\x00-\xFF] | [\x81-\xFE\\][\x00-\xFF] |
                    [^{}] |
                             \{  (?{$nest++}) |
                             \}  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_bracket = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] | \\[\x81-\xFE][\x00-\xFF] | [\x81-\xFE\\][\x00-\xFF] |
                    [^[\]] |
                             \[  (?{$nest++}) |
                             \]  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_angle   = qr{(?{local $nest=0}) (?>(?:
                    \\c[\x40-\x5F] | \\[\x81-\xFE][\x00-\xFF] | [\x81-\xFE\\][\x00-\xFF] |
                    [^<>] |
                             \<  (?{$nest++}) |
                             \>  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $qq_scalar  = qr{(?: \{ (?:$qq_brace)*? \} |
                       (?: ::)? (?:
                             [a-zA-Z_][a-zA-Z_0-9]*
                       (?: ::[a-zA-Z_][a-zA-Z_0-9]* )* (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} )*
                                         (?: (?: -> )? (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} ) )*
                   ))
                 }xms;
my $qq_variable = qr{(?: \{ (?:$qq_brace)*? \} |
                        (?: ::)? (?:
                              [0-9]+            |
                              [^a-zA-Z_0-9\[\]] |
                              ^[A-Z]            |
                              [a-zA-Z_][a-zA-Z_0-9]*
                        (?: ::[a-zA-Z_][a-zA-Z_0-9]* )* (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} )*
                                          (?: (?: -> )? (?: \[ (?: \$\[ | \$\] | $qq_char )*? \] | \{ (?:$qq_brace)*? \} ) )*
                    ))
                  }xms;

# regexp of nested parens in qXX
my $q_paren    = qr{(?{local $nest=0}) (?>(?:
                    [\x81-\xFE][\x00-\xFF] |
                    [^()] |
                             \(  (?{$nest++}) |
                             \)  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_brace    = qr{(?{local $nest=0}) (?>(?:
                    [\x81-\xFE][\x00-\xFF] |
                    [^{}] |
                             \{  (?{$nest++}) |
                             \}  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_bracket  = qr{(?{local $nest=0}) (?>(?:
                    [\x81-\xFE][\x00-\xFF] |
                    [^[\]] |
                             \[  (?{$nest++}) |
                             \]  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;
my $q_angle    = qr{(?{local $nest=0}) (?>(?:
                    [\x81-\xFE][\x00-\xFF] |
                    [^<>] |
                             \<  (?{$nest++}) |
                             \>  (?(?{$nest>0})(?{$nest--})|(?!)))*) (?(?{$nest!=0})(?!))
                 }xms;

my $tr_variable = '';     # variable of                    tr///
use vars qw($slash);      # when 'm//', '/' means regexp match 'm//' and '?' means regexp match '??'
                          # when 'div', '/' means division operator and '?' means conditional operator (condition ? then : else)
my %heredoc      = ();    # here document
my $heredoc_qq   = 0;     # here document quote type

# When this script is main program
if ($0 eq __FILE__) {

    # show usage
    unless (@ARGV) {
        die <<END;
$0: usage

perl $0 Big5Plus_script.pl > Escaped_script.pl.e
END
    }

    # read Big5Plus script
    $_ = join '', <>;
    if (m/^use Ebig5plus;$/oxms) {
        print $_;
        exit 0;
    }
    else {
        if (m/(.+#line \d+\n)/omsgc) {
            my $head = $1;
            $head =~ s/\bjperl\b/perl/gi;
            print $head;
        }
        print "use Ebig5plus;\n";
        s/^ \s* use \s+ Big5Plus \s* ; \s* $//oxms;
    }

    $slash = 'm//';

    # Yes, I studied study yesterday.

    # P.359 in The Study Function
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    study $_;

    # while all script

    # one member of Tag-team
    #
    # P.315 in "Tag-team" matching with /gc
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    while (not /\G \z/oxgc) { # member
        print escape();
    }
    exit 0;
}

# escape Big5Plus script
sub escape {

# \n output here document

    # another member of Tag-team
    #
    # P.315 in "Tag-team" matching with /gc
    # of ISBN 0-596-00289-0 Mastering Regular Expressions, Second edition

    if (/\G ( \n ) /oxgc) { # another member (and so on)
        my $heredoc = '';
        if (scalar(keys %heredoc) >= 1) {
            $slash = 'm//';
            my($longest_heredoc_delimiter) = sort { length($heredoc{$b}) <=> length($heredoc{$a}) } keys %heredoc;
            if ($heredoc_qq >= 1) {
                $heredoc = e_heredoc($heredoc{$longest_heredoc_delimiter});
            }
            else {
                $heredoc =           $heredoc{$longest_heredoc_delimiter};
            }

            # skip here document
            /\G .*? \n $longest_heredoc_delimiter \n/xmsgc;

            %heredoc = ();
            $heredoc_qq = 0;
        }
        return "\n" . $heredoc;
    }

# ignore space, comment
    elsif (/\G (\s+|\#.*) /oxgc) { return $1; }

# scalar variable ($scalar = ...) =~ tr///;
    elsif (/\G ( \( \s* (?: local \s+ | my \s+ | our \s+ | state \s+ )? \$ $qq_scalar ) /oxgc) {
        my $e_string = e_string($1);

        if (/\G ( \s* = $qq_paren \) ) \s* =~ \s* (?= (?: tr|y) \b ) /oxgc) {
            $tr_variable = $e_string . e_string($1);
            $slash = 'm//';
            return '';
        }
        else {
            $slash = 'div';
            return $e_string;
        }
    }

# scalar variable $scalar =~ tr///;
    elsif (/\G ( \$ $qq_scalar ) /oxgc) {
        my $scalar = e_string($1);

        if (/\G \s* =~ \s* (?= (?: tr|y) \b ) /oxgc) {
            $tr_variable = $scalar;
            $slash = 'm//';
            return '';
        }
        else {
            $slash = 'div';
            return $scalar;
        }
    }

    # end of statement
    elsif (/\G ( [,;] ) /oxgc) {
        $slash = 'm//';

        # clear tr variable
        $tr_variable  = '';

        return $1;
    }

# bareword
    elsif (/\G ( \{ \s* (?: tr|index|rindex|reverse) \s* \} ) /oxmsgc) {
        return $1;
    }

# variable or function
    #                  $ @ % & *     $#
    elsif (/\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) \s* (?: split|chop|index|rindex|lc|uc|chr|ord|reverse|tr|y|q|qq|qx|qw|m|s|qr) ) \b /oxmsgc) {
        $slash = 'div';
        return $1;
    }
    #                $ $ $ $ $ $ $ $ $ $ $ $ $ $ $
    #                $ @ # \ ' " ` / ? ( ) [ ] < >
    elsif (/\G ( \$[\$\@\#\\\'\"\`\/\?\(\)\[\]\<\>] ) /oxmsgc) {
        $slash = 'div';
        return $1;
    }

# doit if, doit unless, doit while, doit until, doit for
    elsif (m{\G \b ( if | unless | while | until | for ) \b }oxgc) { $slash = 'm//'; return $1;  }

# functions of package Ebig5plus
    elsif (m{\G \b (CORE::(?:split|chop|index|rindex|lc|uc|chr|ord|reverse)) \b }oxgc) { $slash = 'm//'; return $1;    }
    elsif (m{\G \b split (\s* \( \s*) m\s*(\S)\2              }oxgc) { $slash = 'm//'; return   "Ebig5plus::split$1''";    }
    elsif (m{\G \b split (\s* \( \s*) //                      }oxgc) { $slash = 'm//'; return   "Ebig5plus::split$1''";    }
    elsif (m{\G \b split (\s+)        m\s*(\S)\2              }oxgc) { $slash = 'm//'; return   "Ebig5plus::split$1''";    }
    elsif (m{\G \b split (\s*)        //                      }oxgc) { $slash = 'm//'; return   "Ebig5plus::split$1''";    }
    elsif (m{\G \b split (\s* \( \s*) m\s*(\S)([ -?]\+?)\2    }oxgc) { $slash = 'm//'; return qq{Ebig5plus::split$1 q{$3}};}
    elsif (m{\G \b split (\s* \( \s*) /([ -?]\+?)/            }oxgc) { $slash = 'm//'; return qq{Ebig5plus::split$1 q{$2}};}
    elsif (m{\G \b split (\s+)        m\s*(\S)([ -?]\+?)\2    }oxgc) { $slash = 'm//'; return qq{Ebig5plus::split$1 q{$3}};}
    elsif (m{\G \b split (\s*)        /([ -?]\+?)/            }oxgc) { $slash = 'm//'; return qq{Ebig5plus::split$1 q{$2}};}
    elsif (m{\G \b split (\s* \( \s*) m\s*(\S)(\\[nrtf]\+?)\2 }oxgc) { $slash = 'm//'; return qq{Ebig5plus::split$1"$3"};  }
    elsif (m{\G \b split (\s* \( \s*) /(\\[nrtf]\+?)/         }oxgc) { $slash = 'm//'; return qq{Ebig5plus::split$1"$2"};  }
    elsif (m{\G \b split (\s+)        m\s*(\S)(\\[nrtf]\+?)\2 }oxgc) { $slash = 'm//'; return qq{Ebig5plus::split$1"$3"};  }
    elsif (m{\G \b split (\s*)        /(\\[nrtf]\+?)/         }oxgc) { $slash = 'm//'; return qq{Ebig5plus::split$1"$2"};  }
    elsif (m{\G \b split \b   (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Ebig5plus::split';        }
    elsif (m{\G \b chop \b    (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Ebig5plus::chop';         }
    elsif (m{\G \b index \b   (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Ebig5plus::index';        }
    elsif (m{\G \b rindex \b  (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Ebig5plus::rindex';       }
    elsif (m{\G \b lc \b      (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Ebig5plus::lc';           }
    elsif (m{\G \b uc \b      (?! \s* => )                    }oxgc) { $slash = 'm//'; return   'Ebig5plus::uc';           }

# tr/// or y///

    # about [cdsbB]* (/B modifier)
    #
    # P.559 in appendix C
    # of ISBN 4-89052-384-7 Programming perl
    # (Japanese title is: Perl puroguramingu)

    elsif (/\G \b (tr|y) \b /oxgc) {
        my $ope = $1;

        #        $1   $2               $3   $4               $5   $6
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([cdsbB]*) /oxgc) { # tr# # #
            my @tr = ($tr_variable,$2);
            return e_tr(@tr,'',$4,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                  /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                               /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr ( ) * *
                    }
                    die "$0: Transliteration replacement not terminated";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                               /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr { } * *
                    }
                    die "$0: Transliteration replacement not terminated";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                               /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr [ ] * *
                    }
                    die "$0: Transliteration replacement not terminated";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @tr = ($tr_variable,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                               /oxgc) { $e .= $1; }
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > < >
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cdsbB]*) /oxgc) { return e_tr(@tr,$e,$2,$4); } # tr < > * *
                    }
                    die "$0: Transliteration replacement not terminated";
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cdsbB]*) /oxgc) { # tr * * *
                    my @tr = ($tr_variable,$2);
                    return e_tr(@tr,'',$4,$6);
                }
            }
            die "$0: Transliteration pattern not terminated";
        }
    }

# q//
    elsif (/\G \b (q) \b /oxgc) {
        my $ope = $1;

#       if (/\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) { return e_q($ope,$1,$3,$2); } # q# #

        # avoid "Error: Runtime exception" of perl version 5.005_03
        # (and so on)

        if (/\G (\#) /oxgc) {                                                             # q# #
            my $q_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                    }
                elsif (/\G (\\\#)    /oxgc) { $q_string .= $1;                    }
                elsif (/\G (\#)      /oxgc) { return e_q($ope,'#','#',$q_string); }
                elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                    }
            }
            die "$0: Can't find string terminator anywhere before EOF";
        }

        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                           /oxgc) { $e .= $1; }

#               elsif (/\G (\() ((?:\\\)|\\\\|$q_paren)*?) (\)) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q ( )
                elsif (/\G (\() /oxgc) {                                                                   # q ( )
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\))    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\()    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\()      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\))      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'(',')',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\{) ((?:\\\}|\\\\|$q_brace)*?) (\}) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q { }
                elsif (/\G (\{) /oxgc) {                                                                   # q { }
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\})    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\{)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\{)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\})      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'{','}',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\[) ((?:\\\]|\\\\|$q_bracket)*?) (\]) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q [ ]
                elsif (/\G (\[) /oxgc) {                                                                     # q [ ]
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\])    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\[)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\[)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\])      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'[',']',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\<) ((?:\\\>|\\\\|$q_angle)*?) (\>) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q < >
                elsif (/\G (\<) /oxgc) {                                                                   # q < >
                    my $q_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\>)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\\\<)    /oxgc) { $q_string .= $1;                         }
                        elsif (/\G (\<)      /oxgc) { $q_string .= $1; $nest++;                }
                        elsif (/\G (\>)      /oxgc) {
                            if (--$nest == 0)       { return $e . e_q($ope,'<','>',$q_string); }
                            else                    { $q_string .= $1;                         }
                        }
                        elsif (/\G ($q_char) /oxgc) { $q_string .= $1;                         }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\S) ((?:\\\1|\\\\|$q_char)*?) (\1) /oxgc) { return $e . e_q($ope,$1,$3,$2); } # q * *
                elsif (/\G (\S) /oxgc) {                                                                  # q * *
                    my $delimiter = $1;
                    my $q_string = '';
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)             /oxgc) { $q_string .= $1;                                       }
                        elsif (/\G (\\\Q$delimiter\E) /oxgc) { $q_string .= $1;                                       }
                        elsif (/\G (\Q$delimiter\E)   /oxgc) { return $e . e_q($ope,$delimiter,$delimiter,$q_string); }
                        elsif (/\G ($q_char)          /oxgc) { $q_string .= $1;                                       }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }
            }
            die "$0: Can't find string terminator anywhere before EOF";
        }
    }

# qq//
    elsif (/\G \b (qq) \b /oxgc) {
        my $ope = $1;

#       if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { return e_qq($ope,$1,$3,$2); } # qq# #
        if (/\G (\#) /oxgc) {                                                     # qq# #
            my $qq_string = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                     }
                elsif (/\G (\\\#)     /oxgc) { $qq_string .= $1;                     }
                elsif (/\G (\#)       /oxgc) { return e_qq($ope,'#','#',$qq_string); }
                elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                     }
            }
            die "$0: Can't find string terminator anywhere before EOF";
        }

        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                  /oxgc) { $e .= $1; }

#               elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq ( )
                elsif (/\G (\() /oxgc) {                                                           # qq ( )
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\))     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\()       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\))       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'(',')',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq { }
                elsif (/\G (\{) /oxgc) {                                                           # qq { }
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\})     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\{)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\})       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'{','}',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq [ ]
                elsif (/\G (\[) /oxgc) {                                                             # qq [ ]
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\])     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\[)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\])       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'[',']',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq < >
                elsif (/\G (\<) /oxgc) {                                                           # qq < >
                    my $qq_string = '';
                    local $nest = 1;
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\\\>)     /oxgc) { $qq_string .= $1;                          }
                        elsif (/\G (\<)       /oxgc) { $qq_string .= $1; $nest++;                 }
                        elsif (/\G (\>)       /oxgc) {
                            if (--$nest == 0)        { return $e . e_qq($ope,'<','>',$qq_string); }
                            else                     { $qq_string .= $1;                          }
                        }
                        elsif (/\G ($qq_char) /oxgc) { $qq_string .= $1;                          }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }

#               elsif (/\G (\S) ((?:$qq_char)*?) (\1) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qq * *
                elsif (/\G (\S) /oxgc) {                                                          # qq * *
                    my $delimiter = $1;
                    my $qq_string = '';
                    while (not /\G \z/oxgc) {
                        if    (/\G (\\\\)             /oxgc) { $qq_string .= $1;                                        }
                        elsif (/\G (\\\Q$delimiter\E) /oxgc) { $qq_string .= $1;                                        }
                        elsif (/\G (\Q$delimiter\E)   /oxgc) { return $e . e_qq($ope,$delimiter,$delimiter,$qq_string); }
                        elsif (/\G ($qq_char)         /oxgc) { $qq_string .= $1;                                        }
                    }
                    die "$0: Can't find string terminator anywhere before EOF";
                }
            }
            die "$0: Can't find string terminator anywhere before EOF";
        }
    }

# qx//
    elsif (/\G \b (qx) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qx# #
            return e_qq($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx ( )
                elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx { }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx [ ]
                elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx < >
                elsif (/\G (\') ((?:$qq_char)*?)    (\') /oxgc) { return $e . e_q ($ope,$1,$3,$2); } # qx ' '
                elsif (/\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { return $e . e_qq($ope,$1,$3,$2); } # qx * *
            }
            die "$0: Can't find string terminator anywhere before EOF";
        }
    }

# qw//
    elsif (/\G \b (qw) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) (.*?) (\#) /oxmsgc) { # qw# #
            return e_qw($ope,$1,$3,$2);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                         /oxgc)   { $e .= $1; }
                elsif (/\G (\()          ([^)]*)         (\)) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw ( )
                elsif (/\G (\{)          ((?:$q_char)*?) (\}) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw { }
                elsif (/\G (\[)          ((?:$q_char)*?) (\]) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw [ ]
                elsif (/\G (\<)          ([^>]*)         (\>) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw < >
                elsif (/\G ([\x21-\x3F]) (.*?)           (\1) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw * *
                elsif (/\G (\S)          ((?:$q_char)*?) (\1) /oxmsgc) { return $e . e_qw($ope,$1,$3,$2); } # qw * *
            }
            die "$0: Can't find string terminator anywhere before EOF";
        }
    }

# m//
    elsif (/\G \b (m) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([cgimosx]*) /oxgc) { # m# #
            return e_m($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                                               /oxgc) { $e .= $1; }
                elsif (/\G (\()               ((?:$qq_paren)*?)   (\)) ([cgimosx]*) /oxgc) { return $e . e_m  ($ope,$1, $3, $2,$4); } # m ( )
                elsif (/\G (\{)               ((?:$qq_brace)*?)   (\}) ([cgimosx]*) /oxgc) { return $e . e_m  ($ope,$1, $3, $2,$4); } # m { }
                elsif (/\G (\[)               ((?:$qq_bracket)*?) (\]) ([cgimosx]*) /oxgc) { return $e . e_m  ($ope,$1, $3, $2,$4); } # m [ ]
                elsif (/\G (\<)               ((?:$qq_angle)*?)   (\>) ([cgimosx]*) /oxgc) { return $e . e_m  ($ope,$1, $3, $2,$4); } # m < >
                elsif (/\G (\')               ((?:$qq_char)*?)    (\') ([cgimosx]*) /oxgc) { return $e . e_m_q($ope,$1, $3, $2,$4); } # m ' '
                elsif (/\G ([\*\-\:\?\\\^\|]) ((?:$qq_char)*?)    (\1) ([cgimosx]*) /oxgc) { return $e . e_m  ($ope,'{','}',$2,$4); } # m | | --> m { }
                elsif (/\G (\S)               ((?:$qq_char)*?)    (\1) ([cgimosx]*) /oxgc) { return $e . e_m  ($ope,$1, $3, $2,$4); } # m * *
            }
            die "$0: Search pattern not terminated";
        }
    }

# s///

    # about [cegimosx]* (/cg modifier)
    #
    # P.67 in Pattern-Matching Operators
    # of ISBN 0-596-00241-6 Perl in a Nutshell, Second Edition.

    elsif (/\G \b (s) \b /oxgc) {
        my $ope = $1;

        #        $1   $2               $3   $4               $5   $6
        if (/\G (\#) ((?:$qq_char)*?) (\#) ((?:$qq_char)*?) (\#) ([cegimosx]*) /oxgc) { # s# # #
            my @s = ($ope,$1,$3,$2);
            return e_s1(@s,$6) . e_s2('',$5,$4,$6);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if (/\G (\s+|\#.*) /oxgc) { $e .= $1; }
                elsif (/\G (\() ((?:$qq_paren)*?) (\)) /oxgc) {
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s ( ) ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s ( ) { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s ( ) [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s ( ) < >
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2_q  ('"','"',$2,$4);} # s ( ) ' ' --> s ( ) " "
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2_dol('"','"',$2,$4);} # s ( ) $ $ --> s ( ) " "
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s ( ) * *
                    }
                    die "$0: Substitution replacement not terminated";
                }
                elsif (/\G (\{) ((?:$qq_brace)*?) (\}) /oxgc) {
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s { } ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s { } { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s { } [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s { } < >
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2_q  ('"','"',$2,$4);} # s { } ' ' --> s { } " "
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2_dol('"','"',$2,$4);} # s { } $ $ --> s { } " "
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s { } * *
                    }
                    die "$0: Substitution replacement not terminated";
                }
                elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) {
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s [ ] ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s [ ] { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s [ ] [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s [ ] < >
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2_q  ('"','"',$2,$4);} # s [ ] ' ' --> s [ ] " "
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2_dol('"','"',$2,$4);} # s [ ] $ $ --> s [ ] " "
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s [ ] * *
                    }
                    die "$0: Substitution replacement not terminated";
                }
                elsif (/\G (\<) ((?:$qq_angle)*?) (\>) /oxgc) {
                    my @s = ($ope,$1,$3,$2);
                    while (not /\G \z/oxgc) {
                        if    (/\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                        #           $1   $2                  $3   $4
                        elsif (/\G (\() ((?:$qq_paren)*?)   (\)) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s < > ( )
                        elsif (/\G (\{) ((?:$qq_brace)*?)   (\}) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s < > { }
                        elsif (/\G (\[) ((?:$qq_bracket)*?) (\]) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s < > [ ]
                        elsif (/\G (\<) ((?:$qq_angle)*?)   (\>) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s < > < >
                        elsif (/\G (\') ((?:$qq_char)*?)    (\') ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2_q  ('"','"',$2,$4);} # s < > ' ' --> s < > " "
                        elsif (/\G (\$) ((?:$qq_char)*?)    (\$) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2_dol('"','"',$2,$4);} # s < > $ $ --> s < > " "
                        elsif (/\G (\S) ((?:$qq_char)*?)    (\1) ([cegimosx]*) /oxgc) { return e_s1(@s,$4) . $e . e_s2    ($1,$3,$2,$4);  } # s < > * *
                    }
                    die "$0: Substitution replacement not terminated";
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\') ((?:$qq_char)*?) (\') ((?:$qq_char)*?) (\') ([cegimosx]*) /oxgc) { # s ' ' ' --> s " " "
                    my @s = ($ope,'"','"',$2);
                    return $e . e_s1_q(@s,$6) . e_s2_q('','"',$4,$6);
                }
                #           $1                 $2               $3   $4               $5   $6
                elsif (/\G ([\*\-\:\?\\\^\|]) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosx]*) /oxgc) { # s | | | --> s { } { }
                    my @s = ($ope,'{','}',$2);
                    return $e . e_s1(@s,$6) . e_s2('{','}',$4,$6);
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\$) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosx]*) /oxgc) { # s $ $ $ --> s " " "
                    my @s = ($ope,'"','"',$2);
                    return $e . e_s1_dol(@s,$6) . e_s2_dol('','"',$4,$6);
                }
                #           $1   $2               $3   $4               $5   $6
                elsif (/\G (\S) ((?:$qq_char)*?) (\1) ((?:$qq_char)*?) (\1) ([cegimosx]*) /oxgc) { # s * * *
                    my @s = ($ope,$1,$3,$2);
                    return $e . e_s1(@s,$6) . e_s2('',$5,$4,$6);
                }
            }
            die "$0: Substitution pattern not terminated";
        }
    }

# qr//
    elsif (/\G \b (qr) \b /oxgc) {
        my $ope = $1;
        if (/\G (\#) ((?:$qq_char)*?) (\#) ([imsox]*) /oxgc) { # qr# # #
            return e_qr($ope,$1,$3,$2,$4);
        }
        else {
            my $e = '';
            while (not /\G \z/oxgc) {
                if    (/\G (\s+|\#.*)                                             /oxgc) { $e .= $1; }
                elsif (/\G (\()               ((?:$qq_paren)*?)   (\)) ([imsox]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr ( )
                elsif (/\G (\{)               ((?:$qq_brace)*?)   (\}) ([imsox]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr { }
                elsif (/\G (\[)               ((?:$qq_bracket)*?) (\]) ([imsox]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr [ ]
                elsif (/\G (\<)               ((?:$qq_angle)*?)   (\>) ([imsox]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr < >
                elsif (/\G (\')               ((?:$qq_char)*?)    (\') ([imsox]*) /oxgc) { return $e . e_qr_q($ope,$1, $3, $2,$4); } # qr ' '
                elsif (/\G ([\*\-\:\?\\\^\|]) ((?:$qq_char)*?)    (\1) ([imsox]*) /oxgc) { return $e . e_qr  ($ope,'{','}',$2,$4); } # qr | | --> qr { }
                elsif (/\G (\S)               ((?:$qq_char)*?)    (\1) ([imsox]*) /oxgc) { return $e . e_qr  ($ope,$1, $3, $2,$4); } # qr * *
            }
            die "$0: Can't find string terminator anywhere before EOF";
        }
    }

# ''
    elsif (/\G (?<![\w\$\@\%\&\*]) (\') /oxgc) {
        my $q_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)            { $q_string .= $1;                   }
            elsif (/\G (\\\')    /oxgc)            { $q_string .= $1;                   }
            elsif (/\G \'        /oxgc)            { return e_q('', "'","'",$q_string); }
            elsif (/\G ($q_char) /oxgc)            { $q_string .= $1;                   }
        }
        die "$0: Can't find string terminator anywhere before EOF";
    }

# ""
    elsif (/\G (\") /oxgc) {
        my $qq_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)            { $qq_string .= $1;                    }
            elsif (/\G (\\\")    /oxgc)            { $qq_string .= $1;                    }
            elsif (/\G \"        /oxgc)            { return e_qq('', '"','"',$qq_string); }
            elsif (/\G ($q_char) /oxgc)            { $qq_string .= $1;                    }
        }
        die "$0: Can't find string terminator anywhere before EOF";
    }

# ``
    elsif (/\G (\`) /oxgc) {
        my $qx_string = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)    /oxgc)            { $qx_string .= $1;                    }
            elsif (/\G (\\\`)    /oxgc)            { $qx_string .= $1;                    }
            elsif (/\G \`        /oxgc)            { return e_qq('', '`','`',$qx_string); }
            elsif (/\G ($q_char) /oxgc)            { $qx_string .= $1;                    }
        }
        die "$0: Can't find string terminator anywhere before EOF";
    }

# //   --- not divide operator (num / num), not defined-or
    elsif (($slash eq 'm//') and /\G (\/) /oxgc) {
        my $regexp = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)          /oxgc)      { $regexp .= $1;                       }
            elsif (/\G (\\\/)          /oxgc)      { $regexp .= $1;                       }
            elsif (/\G \/ ([cgimosx]*) /oxgc)      { return e_m ('', '/','/',$regexp,$1); }
            elsif (/\G ($q_char)       /oxgc)      { $regexp .= $1;                       }
        }
        die "$0: Search pattern not terminated";
    }

# ??   --- not conditional operator (condition ? then : else)
    elsif (($slash eq 'm//') and /\G (\?) /oxgc) {
        my $regexp = '';
        while (not /\G \z/oxgc) {
            if    (/\G (\\\\)          /oxgc)      { $regexp .= $1;                       }
            elsif (/\G (\\\?)          /oxgc)      { $regexp .= $1;                       }
            elsif (/\G \? ([cgimosx]*) /oxgc)      { return e_m ('', '?','?',$regexp,$1); }
            elsif (/\G ($q_char)       /oxgc)      { $regexp .= $1;                       }
        }
        die "$0: Search pattern not terminated";
    }

# << (bit shift)   --- not here document
    elsif (/\G ( << \s* ) (?= [0-9\$\@\&] ) /oxgc) { $slash = 'm//'; return $1;           }

# <<'HEREDOC'
    elsif (/\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        my $script = substr $_, pos $_;
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "$0: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<\HEREDOC

    # P.66 "Here" Documents
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    elsif (/\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;

        # get here document
        my $script = substr $_, pos $_;
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "$0: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<"HEREDOC"
    elsif (/\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;
        $heredoc_qq++;

        # get here document
        my $script = substr $_, pos $_;
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "$0: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<HEREDOC
    elsif (/\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;
        $heredoc_qq++;

        # get here document
        my $script = substr $_, pos $_;
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "$0: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# <<`HEREDOC`
    elsif (/\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
        $slash = 'm//';
        my $here_quote = $1;
        my $delimiter  = $2;
        $heredoc_qq++;

        # get here document
        my $script = substr $_, pos $_;
        $script =~ s/.*?\n//oxm;
        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
            $heredoc{$delimiter} = $1;
        }
        else {
            die "$0: Can't find string terminator $delimiter anywhere before EOF";
        }
        return $here_quote;
    }

# __DATA__
    elsif (/\G ^ ( __DATA__ \n .*) \z /oxmsgc) { return $1; }

# __END__
    elsif (/\G ^ ( __END__  \n .*) \z /oxmsgc) { return $1; }

# \cD Control-D

    # P.68 Other Literal Tokens
    # of ISBN 0-596-00027-8 Programming Perl Third Edition.

    elsif (/\G   ( \cD         .*) \z /oxmsgc) { return $1; }

# \cZ Control-Z
    elsif (/\G   ( \cZ         .*) \z /oxmsgc) { return $1; }

    # any operator before div
    elsif (/\G (
            -- | \+\+ |
            [\)\}\]]

            ) /oxgc) { $slash = 'div'; return $1; }

    # any operator before m//
    elsif (/\G (

            != | !~ | ! |
            %= | % |
            &&= | && | &= | & |
            -= | -> | -[rwxoRWXOezsfdlpSbctugkTBMAC] | - |
            : |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+= | \+ |
            \.\.\. | \.\. | \.= | \. |
            \/\/= | \/\/ |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \| |
            ~~ | ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |
            \b(?: print )\b |

            [,;\(\{\[]

            ) /oxgc) { $slash = 'm//'; return $1; }

    # other any character
    elsif (/\G ($q_char) /oxgc) { $slash = 'div'; return $1; }

    # system error
    else {
        die "$0: oops, this shouldn't happen!";
    }
}

# escape Big5Plus string
sub e_string {
    my($string) = @_;
    my $e_string = '';

    local $slash = 'm//';

    # P.1024 Appendix W.10 Multibyte Processing
    # of ISBN 1-56592-224-7 CJKV Information Processing
    # (and so on)

    my @char = $string =~ m/ \G ([\x81-\xFE\\][\x00-\xFF]|[\x00-\xFF]) /oxmsg;

    # without { ... }
    if (not (grep(m/\A \{ \z/xms, @char) and grep(m/\A \} \z/xms, @char))) {
        if ($string !~ /<</oxms) {
            return $string;
        }
    }

E_STRING_LOOP:
    while ($string !~ /\G \z/oxgc) {

# bareword
        if ($string =~ /\G ( \{ \s* (?: tr | index | rindex | reverse ) \s* \} ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# variable or function
        #                             $ @ % & *     $#
        elsif ($string =~ /\G ( (?: [\$\@\%\&\*] | \$\# | -> | \b sub \b) \s* (?: split|chop|index|rindex|lc|uc|chr|ord|reverse|tr|y|q|qq|qx|qw|m|s|qr) ) \b /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }
        #                           $ $ $ $ $ $ $ $ $ $ $ $ $ $ $
        #                           $ @ # \ ' " ` / ? ( ) [ ] < >
        elsif ($string =~ /\G ( \$[\$\@\#\\\'\"\`\/\?\(\)\[\]\<\>] ) /oxmsgc) {
            $e_string .= $1;
            $slash = 'div';
        }

# functions of package Ebig5plus
        elsif ($string =~ m{\G \b (CORE::(?:split|chop|index|rindex|lc|uc|chr|ord|reverse)) \b }oxgc) { $e_string .= $1;     $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) m\s*(\S)\2              }oxgc) { $e_string .=   "Ebig5plus::split$1''";     $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) //                      }oxgc) { $e_string .=   "Ebig5plus::split$1''";     $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s+)        m\s*(\S)\2              }oxgc) { $e_string .=   "Ebig5plus::split$1''";     $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s*)        //                      }oxgc) { $e_string .=   "Ebig5plus::split$1''";     $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) m\s*(\S)([ -?]\+?)\2    }oxgc) { $e_string .= qq{Ebig5plus::split$1 q{$3}}; $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) /([ -?]\+?)/            }oxgc) { $e_string .= qq{Ebig5plus::split$1 q{$2}}; $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s+)        m\s*(\S)([ -?]\+?)\2    }oxgc) { $e_string .= qq{Ebig5plus::split$1 q{$3}}; $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s*)        /([ -?]\+?)/            }oxgc) { $e_string .= qq{Ebig5plus::split$1 q{$2}}; $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) m\s*(\S)(\\[nrtf]\+?)\2 }oxgc) { $e_string .= qq{Ebig5plus::split$1"$3"};   $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s* \( \s*) /(\\[nrtf]\+?)/         }oxgc) { $e_string .= qq{Ebig5plus::split$1"$2"};   $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s+)        m\s*(\S)(\\[nrtf]\+?)\2 }oxgc) { $e_string .= qq{Ebig5plus::split$1"$3"};   $slash = 'm//'; }
        elsif ($string =~ m{\G \b split (\s*)        /(\\[nrtf]\+?)/         }oxgc) { $e_string .= qq{Ebig5plus::split$1"$2"};   $slash = 'm//'; }
        elsif ($string =~ m{\G \b split \b                                   }oxgc) { $e_string .=   'Ebig5plus::split';         $slash = 'm//'; }
        elsif ($string =~ m{\G \b chop \b                                    }oxgc) { $e_string .=   'Ebig5plus::chop';          $slash = 'm//'; }
        elsif ($string =~ m{\G \b index \b                                   }oxgc) { $e_string .=   'Ebig5plus::index';         $slash = 'm//'; }
        elsif ($string =~ m{\G \b rindex \b                                  }oxgc) { $e_string .=   'Ebig5plus::rindex';        $slash = 'm//'; }
        elsif ($string =~ m{\G \b lc \b                                      }oxgc) { $e_string .=   'Ebig5plus::lc';            $slash = 'm//'; }
        elsif ($string =~ m{\G \b uc \b                                      }oxgc) { $e_string .=   'Ebig5plus::uc';            $slash = 'm//'; }

# q//
        elsif ($string =~ /\G \b (q) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:\\\#|\\\\|$q_char)*?) (\#) /oxgc) { # q# #
                $e_string .= e_q($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                                  /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:\\\\|\\\)|\\\(|$q_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q ( )
                    elsif ($string =~ /\G (\{) ((?:\\\\|\\\}|\\\{|$q_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q { }
                    elsif ($string =~ /\G (\[) ((?:\\\\|\\\]|\\\[|$q_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q [ ]
                    elsif ($string =~ /\G (\<) ((?:\\\\|\\\>|\\\<|$q_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q < >
                    elsif ($string =~ /\G (\S) ((?:\\\\|\\\1|     $q_char)*?)    (\1) /oxgc) { $e_string .= $e . e_q($ope,$1,$3,$2); next E_STRING_LOOP; } # q * *
                }
                die "$0: Can't find string terminator anywhere before EOF";
            }
        }

# qq//
        elsif ($string =~ /\G \b (qq) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qq# #
                $e_string .= e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq ( )
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq { }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq [ ]
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq < >
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qq * *
                }
                die "$0: Can't find string terminator anywhere before EOF";
            }
        }

# qx//
        elsif ($string =~ /\G \b (qx) \b /oxgc) {
            my $ope = $1;
            if ($string =~ /\G (\#) ((?:$qq_char)*?) (\#) /oxgc) { # qx# #
                $e_string .= e_qq($ope,$1,$3,$2);
            }
            else {
                my $e = '';
                while ($string !~ /\G \z/oxgc) {
                    if    ($string =~ /\G (\s+|\#.*)                    /oxgc) { $e .= $1; }
                    elsif ($string =~ /\G (\() ((?:$qq_paren)*?)   (\)) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx ( )
                    elsif ($string =~ /\G (\{) ((?:$qq_brace)*?)   (\}) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx { }
                    elsif ($string =~ /\G (\[) ((?:$qq_bracket)*?) (\]) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx [ ]
                    elsif ($string =~ /\G (\<) ((?:$qq_angle)*?)   (\>) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx < >
                    elsif ($string =~ /\G (\') ((?:$qq_char)*?)    (\') /oxgc) { $e_string .= $e . e_q ($ope,$1,$3,$2); next E_STRING_LOOP; } # qx ' '
                    elsif ($string =~ /\G (\S) ((?:$qq_char)*?)    (\1) /oxgc) { $e_string .= $e . e_qq($ope,$1,$3,$2); next E_STRING_LOOP; } # qx * *
                }
                die "$0: Can't find string terminator anywhere before EOF";
            }
        }

# ''
        elsif ($string =~ /\G (?<![\w\$\@\%\&\*]) (\') ((?:\\\'|\\\\|$q_char)*?) (\') /oxgc) { $e_string .= e_q('',$1,$3,$2); }

# ""
        elsif ($string =~ /\G (\") ((?:$qq_char)*?) (\") /oxgc)                              { $e_string .= e_qq('',$1,$3,$2); }

# ``
        elsif ($string =~ /\G (\`) ((?:$qq_char)*?) (\`) /oxgc)                              { $e_string .= e_qq('',$1,$3,$2); }

# << (bit shift)   --- not here document
	    elsif ($string =~ /\G ( << \s* ) (?= [0-9\$\@\&] ) /oxgc) { $slash = 'm//'; $e_string .= $1;           }

# <<'HEREDOC'
	    elsif ($string =~ /\G ( << '([a-zA-Z_0-9]*)' ) /oxgc) {
	        $slash = 'm//';
	        my $here_quote = $1;
	        my $delimiter  = $2;

	        # get here document
	        my $script = substr $_, pos $_;
	        $script =~ s/.*?\n//oxm;
	        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
	            $heredoc{$delimiter} = $1;
	        }
	        else {
	            die "$0: Can't find string terminator $delimiter anywhere before EOF";
	        }
	        $e_string .= $here_quote;
	    }

# <<\HEREDOC
	    elsif ($string =~ /\G ( << \\([a-zA-Z_0-9]+) ) /oxgc) {
	        $slash = 'm//';
	        my $here_quote = $1;
	        my $delimiter  = $2;

	        # get here document
	        my $script = substr $_, pos $_;
	        $script =~ s/.*?\n//oxm;
	        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
	            $heredoc{$delimiter} = $1;
	        }
	        else {
	            die "$0: Can't find string terminator $delimiter anywhere before EOF";
	        }
	        $e_string .= $here_quote;
	    }

# <<"HEREDOC"
	    elsif ($string =~ /\G ( << "([a-zA-Z_0-9]*)" ) /oxgc) {
	        $slash = 'm//';
	        my $here_quote = $1;
	        my $delimiter  = $2;
	        $heredoc_qq++;

	        # get here document
	        my $script = substr $_, pos $_;
	        $script =~ s/.*?\n//oxm;
	        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
	            $heredoc{$delimiter} = $1;
	        }
	        else {
	            die "$0: Can't find string terminator $delimiter anywhere before EOF";
	        }
	        $e_string .= $here_quote;
	    }

# <<HEREDOC
	    elsif ($string =~ /\G ( << ([a-zA-Z_0-9]+) ) /oxgc) {
	        $slash = 'm//';
	        my $here_quote = $1;
	        my $delimiter  = $2;
	        $heredoc_qq++;

	        # get here document
	        my $script = substr $_, pos $_;
	        $script =~ s/.*?\n//oxm;
	        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
	            $heredoc{$delimiter} = $1;
	        }
	        else {
	            die "$0: Can't find string terminator $delimiter anywhere before EOF";
	        }
	        $e_string .= $here_quote;
	    }

# <<`HEREDOC`
	    elsif ($string =~ /\G ( << `([a-zA-Z_0-9]*)` ) /oxgc) {
	        $slash = 'm//';
	        my $here_quote = $1;
	        my $delimiter  = $2;
	        $heredoc_qq++;

	        # get here document
	        my $script = substr $_, pos $_;
	        $script =~ s/.*?\n//oxm;
	        if ($script =~ /\A (.*? \n $delimiter \n) /xms) {
	            $heredoc{$delimiter} = $1;
	        }
	        else {
	            die "$0: Can't find string terminator $delimiter anywhere before EOF";
	        }
	        $e_string .= $here_quote;
	    }

        # any operator before div
        elsif ($string =~ /\G (
            -- | \+\+ |
            [\)\}\]]

            ) /oxgc) { $slash = 'div'; $e_string .= $1; }

        # any operator before m//
        elsif ($string =~ /\G (

            != | !~ | ! |
            %= | % |
            &&= | && | &= | & |
            -= | -> | -[rwxoRWXOezsfdlpSbctugkTBMAC] | - |
            : |
            <<= | <=> | <= | < |
            == | => | =~ | = |
            >>= | >> | >= | > |
            \*\*= | \*\* | \*= | \* |
            \+= | \+ |
            \.\.\. | \.\. | \.= | \. |
            \/\/= | \/\/ |
            \/= | \/ |
            \? |
            \\ |
            \^= | \^ |
            \b x= |
            \|\|= | \|\| | \|= | \| |
            ~~ | ~ |
            \b(?: and | cmp | eq | ge | gt | le | lt | ne | not | or | xor | x )\b |
            \b(?: print )\b |

            [,;\(\{\[]

            ) /oxgc) { $slash = 'm//'; $e_string .= $1; }

        # other any character
        elsif ($string =~ /\G ($q_char) /oxgc) { $e_string .= $1; }

        # system error
        else {
            die "$0: oops, this shouldn't happen!";
        }
    }

    return $e_string;
}

#
# quote for escape transliteration (tr/// or y///)
#
sub e_tr_q {
    my($charclass) = @_;

    # quote character class
    if ($charclass !~ m/'/oxms) {
        return e_q('',  "'", "'", $charclass); # --> q' '
    }
    elsif ($charclass !~ m{/}oxms) {
        return e_q('q',  '/', '/', $charclass); # --> q/ /
    }
    elsif ($charclass !~ m/\#/oxms) {
        return e_q('q',  '#', '#', $charclass); # --> q# #
    }
    elsif ($charclass !~ m/[\<\>]/oxms) {
        return e_q('q', '<', '>', $charclass); # --> q< >
    }
    elsif ($charclass !~ m/[\(\)]/oxms) {
        return e_q('q', '(', ')', $charclass); # --> q( )
    }
    elsif ($charclass !~ m/[\{\}]/oxms) {
        return e_q('q', '{', '}', $charclass); # --> q{ }
    }
    else {
        for my $delimiter (qw( ! " $ % & * + . : ; = ? @ ^ _ ` | ~ ), "\xA1" .. "\xDF") {
            if ($charclass !~ m/\Q$delimiter\E/xms) {
                return e_q('q', $delimiter, $delimiter, $charclass);
            }
        }
    }

    return e_q('q', '{', '}', $charclass);
}

#
# escape transliteration (tr/// or y///)
#
sub e_tr {
    my($variable,$charclass,$e,$charclass2,$modifier) = @_;
    my $e_tr = '';
    $modifier ||= '';

    $slash = 'div';

    # quote character class 1
    $charclass  = e_tr_q($charclass);

    # quote character class 2
    $charclass2 = e_tr_q($charclass2);

    # /b /B modifier
    if ($modifier =~ tr/bB//d) {
        if ($variable eq '') {
            $e_tr = qq{tr$charclass$e$charclass2$modifier};
        }
        else {
            $e_tr = qq{$variable =~ tr$charclass$e$charclass2$modifier};
        }
    }
    else {
        if ($variable eq '') {
            $e_tr = qq{Ebig5plus::tr(\$_,$charclass,$e$charclass2,'$modifier')};
        }
        else {
            $e_tr = qq{Ebig5plus::tr($variable,$charclass,$e$charclass2,'$modifier')};
        }
    }

    # clear tr variable
    $tr_variable  = '';

    return $e_tr;
}

#
# escape q string (q//, '')
#
sub e_q {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my @char = $string =~ m/ \G ([\x81-\xFE][\x00-\xFF]|[\x00-\xFF]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A ([\x81-\xFE]) (\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }
        elsif (($char[$i] =~ m/\A ([\x81-\xFE]) (\\) \z/xms) and defined($char[$i+1]) and ($char[$i+1] eq '\\')) {
            $char[$i] = $1 . '\\' . $2;
        }
    }
    if (defined($char[-1]) and ($char[-1] =~ m/\A ([\x81-\xFE]) (\\) \z/xms)) {
        $char[-1] = $1 . '\\' . $2;
    }

    return join '', $ope, $delimiter, @char, $end_delimiter;
}

#
# escape qq string (qq//, "", qx//, ``)
#
sub e_qq {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    my $metachar = qr/[\@\\\|]/oxms; # '|' is for qx//, ``, open() and system()

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m/ \G ([\x81-\xFE\\][\x00-\xFF]|[\x00-\xFF]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A ([\x81-\xFE]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {

            # "STRING @{[ LIST EXPR ]} MORE STRING"
            #
            # 1.15. Interpolating Functions and Expressions Within Strings
            # in Chapter 1. Strings
            # of ISBN 0-596-00313-7 Perl Cookbook, 2nd Edition.
            # (and so on)

            $char[$i] = '@{[Ebig5plus::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ebig5plus::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', $ope, $delimiter, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    else {
        return join '', $ope, $delimiter, @char,                               $end_delimiter;
    }
}

#
# escape qw string (qw//)
#
sub e_qw {
    my($ope,$delimiter,$end_delimiter,$string) = @_;

    $slash = 'div';

    # return string
    return join '', $ope, $delimiter, $string, $end_delimiter;
}

#
# escape here document (<<"HEREDOC", <<HEREDOC, <<`HEREDOC`)
#
sub e_heredoc {
    my($string) = @_;

    $slash = 'm//';

    my $metachar = qr/[\@\\|]/oxms; # '|' is for <<`HEREDOC`

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m/ \G ([\x81-\xFE\\][\x00-\xFF]|[\x00-\xFF]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape character
        if ($char[$i] =~ m/\A ([\x81-\xFE]) ($metachar) \z/oxms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ebig5plus::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ebig5plus::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
    }

    # return string
    if ($left_e > $right_e) {
        return join '', @char, '>]}' x ($left_e - $right_e);
    }
    else {
        return join '', @char;
    }
}

#
# escape regexp (m//)
#
sub e_m {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{2,3}      |
        \\x [0-9A-Fa-f]{2}  |
        \\c [\x40-\x5F]     |
        \\  (?:[\x81-\xFE][\x00-\xFF] | [\x00-\xFF]) |
        [\$\@] $qq_variable |
        \[\:\^ [a-z]+ \:\]  |
        \[\:   [a-z]+ \:\]  |
        \[\^                |
            (?:[\x81-\xFE\\][\x00-\xFF] | [\x00-\xFF])
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A \\? ([\x81-\xFE]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated double octet
        elsif ($char[$i] =~ m/\A \\ (?:2[0-7][1-7]|3[0-7][0-6]) \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice @char, $i+1, 1;
            }
        }
        elsif ($char[$i] =~ m/\A \\x (?:8[1-9A-Fa-f]|[9A-Ea-e][0-9A-Fa-f]|[Ff][0-9A-Ea-e]) \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => ($modifier =~ /s/) ?
                    '(?:[\x81-\xFE][\x00-\xFF]|[\x00-\xFF])' :
                    '(?:[\x81-\xFE][\x00-\xFF]|[^\n])',
            '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
            '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
            '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
            '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
            '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ebig5plus::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ebig5plus::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '@{[Ebig5plus::ignorecase(' . e_string($char[$i]) . ')]}';
            }
            else {
                $char[$i] =                           e_string($char[$i]);
            }
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A 
                (?:
                        [\x81-\xFE] | 
                    \\  (?:2[0-7][1-7]|3[0-7][0-6]) |
                    \\x (?:8[1-9A-Fa-f]|[9A-Ea-e][0-9A-Fa-f]|[Ff][0-9A-Ea-e])
                )
                (?:
                        [\x00-\xFF] |
                    \\  [0-7]{2,3} |
                    \\x [0-9-A-Fa-f]{1,2}
                )
             \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    # make regexp string
    my $re;
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        $re = join '', $ope, $delimiter, $your_gap, @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
    }
    else {
        $re = join '', $ope, $delimiter, $your_gap, @char,                               $end_delimiter, $modifier;
    }
    return $re;
}

#
# escape regexp (m'')
#
sub e_m_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
            (?:[\x81-\xFE\\][\x00-\xFF] | [\x00-\xFF])
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A ([\x81-\xFE]) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => ($modifier =~ /s/) ?
                    '(?:[\x81-\xFE][\x00-\xFF]|[\x00-\xFF])' :
                    '(?:[\x81-\xFE][\x00-\xFF]|[^\n])',
            '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
            '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
            '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
            '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
            '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\xFE] \\? [\x00-\xFF] \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    $modifier =~ tr/i//d;
    return join '', $ope, $delimiter, $your_gap, @char, $end_delimiter, $modifier;
}

#
# escape regexp (s/here//)
#
sub e_s1 {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{1,3}      |
        \\x [0-9A-Fa-f]{2}  |
        \\c [\x40-\x5F]     |
        \\  (?:[\x81-\xFE][\x00-\xFF] | [\x00-\xFF]) |
        [\$\@] $qq_variable |
        \[\:\^ [a-z]+ \:\]  |
        \[\:   [a-z]+ \:\]  |
        \[\^                |
            (?:[\x81-\xFE\\][\x00-\xFF] | [\x00-\xFF])
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A \\? ([\x81-\xFE]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

#
# your script:                             \1        \2        \3
#                s/                       (aaa) BBB (ccc) DDD (eee) /   ...   /;
#                                           :         :         :
# escaped script:              \1          \2        \3        \4
#                s/ \G ((?:$your_char)*?) (aaa) BBB (ccc) DDD (eee) /${1} ... /;
# (and so on)
#

        # rewrite \1,\2,\3 ... --> \2,\3,\4 ...
        elsif ($char[$i] =~ m/\A (\\) ((\d)\d*) \z/oxms) {
            if (($3 eq '0') or ($2 >= 40)) {

                # join separated double octet
                if ($char[$i] =~ m/\A \\ (?:2[0-7][1-7]|3[0-7][0-6]) \z/oxms) {
                    if ($i < $#char) {
                        $char[$i] .= $char[$i+1];
                        splice @char, $i+1, 1;
                    }
                }
            }
            else {
                $char[$i] = $1 . ($2 + 1);
            }
        }

        # join separated double octet
        elsif ($char[$i] =~ m/\A \\x (?:8[1-9A-Fa-f]|[9A-Ea-e][0-9A-Fa-f]|[Ff][0-9A-Ea-e]) \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => ($modifier =~ /s/) ?
                    '(?:[\x81-\xFE][\x00-\xFF]|[\x00-\xFF])' :
                    '(?:[\x81-\xFE][\x00-\xFF]|[^\n])',
            '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
            '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
            '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
            '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
            '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ebig5plus::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ebig5plus::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '@{[Ebig5plus::ignorecase(' . e_string($char[$i]) . ')]}';
            }
            else {
                $char[$i] =                           e_string($char[$i]);
            }
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A 
                (?:
                        [\x81-\xFE] | 
                    \\  (?:2[0-7][1-7]|3[0-7][0-6]) |
                    \\x (?:8[1-9A-Fa-f]|[9A-Ea-e][0-9A-Fa-f]|[Ff][0-9A-Ea-e])
                )
                (?:
                        [\x00-\xFF] |
                    \\  [0-7]{2,3} |
                    \\x [0-9-A-Fa-f]{1,2}
                )
             \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    # make regexp string
    my $re;
    if ($left_e > $right_e) {
        $re = join '', $ope, $delimiter, qq{\\G((?:$your_char)*?)}, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    else {
        $re = join '', $ope, $delimiter, qq{\\G((?:$your_char)*?)}, @char,                               $end_delimiter;
    }
    return $re;
}

#
# escape regexp (s$here$$)
#
sub e_s1_dol {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{1,3}      |
        \\x [0-9A-Fa-f]{2}  |
        \\c [\x40-\x5F]     |
        \\  (?:[\x81-\xFE][\x00-\xFF] | [\x00-\xFF]) |
        [\$\@] $qq_variable |
        \[\:\^ [a-z]+ \:\]  |
        \[\:   [a-z]+ \:\]  |
        \[\^                |
            (?:[\x81-\xFE\\][\x00-\xFF] | [\x00-\xFF])
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A \\? ([\x81-\xFE]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # escape single octet
        elsif ($char[$i] =~ m/\A (\Q$end_delimiter\E) \z/xms) {
            $char[$i] = '\\' . $1;
        }

#
# your script:                             \1        \2        \3
#                s/                       (aaa) BBB (ccc) DDD (eee) /   ...   /;
#                                           :         :         :
# escaped script:              \1          \2        \3        \4
#                s/ \G ((?:$your_char)*?) (aaa) BBB (ccc) DDD (eee) /${1} ... /;
# (and so on)
#

        # rewrite \1,\2,\3 ... --> \2,\3,\4 ...
        elsif ($char[$i] =~ m/\A (\\) ((\d)\d*) \z/oxms) {
            if (($3 eq '0') or ($2 >= 40)) {

                # join separated double octet
                if ($char[$i] =~ m/\A \\ (?:2[0-7][1-7]|3[0-7][0-6]) \z/oxms) {
                    if ($i < $#char) {
                        $char[$i] .= $char[$i+1];
                        splice @char, $i+1, 1;
                    }
                }
            }
            else {
                $char[$i] = $1 . ($2 + 1);
            }
        }

        # join separated double octet
        elsif ($char[$i] =~ m/\A \\x (?:8[1-9A-Fa-f]|[9A-Ea-e][0-9A-Fa-f]|[Ff][0-9A-Ea-e]) \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => ($modifier =~ /s/) ?
                    '(?:[\x81-\xFE][\x00-\xFF]|[\x00-\xFF])' :
                    '(?:[\x81-\xFE][\x00-\xFF]|[^\n])',
            '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
            '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
            '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
            '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
            '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ebig5plus::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ebig5plus::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '@{[Ebig5plus::ignorecase(' . e_string($char[$i]) . ')]}';
            }
            else {
                $char[$i] =                           e_string($char[$i]);
            }
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A 
                (?:
                        [\x81-\xFE] | 
                    \\  (?:2[0-7][1-7]|3[0-7][0-6]) |
                    \\x (?:8[1-9A-Fa-f]|[9A-Ea-e][0-9A-Fa-f]|[Ff][0-9A-Ea-e])
                )
                (?:
                        [\x00-\xFF] |
                    \\  [0-7]{2,3} |
                    \\x [0-9-A-Fa-f]{1,2}
                )
             \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    # make regexp string
    my $re;
    if ($left_e > $right_e) {
        $re = join '', $ope, $delimiter, qq{\\G((?:$your_char)*?)}, @char, '>]}' x ($left_e - $right_e), $end_delimiter;
    }
    else {
        $re = join '', $ope, $delimiter, qq{\\G((?:$your_char)*?)}, @char,                               $end_delimiter;
    }
    return $re;
}

#
# escape regexp (s'here'')
#
sub e_s1_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{1,3}     |
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
            (?:[\x81-\xFE\\][\x00-\xFF] | [\x00-\xFF])
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A ([\x81-\xFE]) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # rewrite \1,\2,\3 ... --> \2,\3,\4 ...
        elsif ($char[$i] =~ m/\A (\\) ((\d)\d*) \z/oxms) {
            if (($3 eq '0') or ($2 >= 40)) {
                $char[$i] = '\\' . $1 . $2;
            }
            else {
                $char[$i] = $1 . ($2 + 1);
            }
        }

        # escape single octet
        elsif ($char[$i] =~ m/\A (\\|\$|\@|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = '\\' . $1;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => ($modifier =~ /s/) ?
                    '(?:[\x81-\xFE][\x00-\xFF]|[\x00-\xFF])' :
                    '(?:[\x81-\xFE][\x00-\xFF]|[^\n])',
            '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
            '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
            '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
            '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
            '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\xFE] \\? [\x00-\xFF] \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }
    return join '', $ope, $delimiter, qq{\\G((?:$your_char)*?)}, @char, $end_delimiter;
}

#
# escape string (s//here/)
#
sub e_s2 {
    my($delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    my $metachar = qr/[\@\\]/oxms;

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m/ \G (\$\d+|\\\d+|[\x81-\xFE\\][\x00-\xFF]|[\x00-\xFF]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A ([\x81-\xFE]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

#
# your script:                             $1        $2        $3
#                s/                       (aaa) BBB (ccc) DDD (eee) / ...     /
#                                           :         :         :
# escaped script:              $1          $2        $3        $4
#                s/ \G ((?:$your_char)*?) (aaa) BBB (ccc) DDD (eee) /${1} ... /
#

        # rewrite $1,$2,$3 ... --> $2,$3,$4 ...
        elsif ($char[$i] =~ m/\A (\$) ((\d)\d*) \z/oxms) {
            if (($3 eq '0') or ($2 >= 40)) {
            }
            else {
                $char[$i] = $1 . ($2 + 1);
            }
        }

#
# your script:                             \1        \2        \3
#                s/                       (aaa) BBB (ccc) DDD (eee) /   ...   /
#                                           :         :         :
# escaped script:              \1          \2        \3        \4
#                s/ \G ((?:$your_char)*?) (aaa) BBB (ccc) DDD (eee) /${1} ... /
#

        # rewrite \1,\2,\3 ... --> \2,\3,\4 ...
        elsif ($char[$i] =~ m/\A (\\) ((\d)\d*) \z/oxms) {
            if (($3 eq '0') or ($2 >= 40)) {
            }
            else {
                $char[$i] = $1 . ($2 + 1);
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ebig5plus::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ebig5plus::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
    }

    # return string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        if ($modifier =~ /e/) {
            return join '', $delimiter, '${1}.', @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
        }
        else {
            return join '', $delimiter, '${1}',  @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
        }
    }
    else {
        if ($modifier =~ /e/) {
            return join '', $delimiter, '${1}.', @char,                               $end_delimiter, $modifier;
        }
        else {
            return join '', $delimiter, '${1}',  @char,                               $end_delimiter, $modifier;
        }
    }
}

#
# escape string (s$$here$)
#
sub e_s2_dol {
    my($delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    my $metachar = qr/[\@\\]/oxms;

    # escape character
    my $left_e  = 0;
    my $right_e = 0;
    my @char = $string =~ m/ \G (\$\d+|\\\d+|[\x81-\xFE\\][\x00-\xFF]|[\x00-\xFF]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A ([\x81-\xFE]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # escape single octet
        elsif ($char[$i] =~ m/\A (\Q$end_delimiter\E) \z/xms) {
            $char[$i] = '\\' . $1;
        }

#
# your script:                             $1        $2        $3
#                s/                       (aaa) BBB (ccc) DDD (eee) / ...     /
#                                           :         :         :
# escaped script:              $1          $2        $3        $4
#                s/ \G ((?:$your_char)*?) (aaa) BBB (ccc) DDD (eee) /${1} ... /
#

        # rewrite $1,$2,$3 ... --> $2,$3,$4 ...
        elsif ($char[$i] =~ m/\A (\$) ((\d)\d*) \z/oxms) {
            if (($3 eq '0') or ($2 >= 40)) {
            }
            else {
                $char[$i] = $1 . ($2 + 1);
            }
        }

#
# your script:                             \1        \2        \3
#                s/                       (aaa) BBB (ccc) DDD (eee) /   ...   /
#                                           :         :         :
# escaped script:              \1          \2        \3        \4
#                s/ \G ((?:$your_char)*?) (aaa) BBB (ccc) DDD (eee) /${1} ... /
#

        # rewrite \1,\2,\3 ... --> \2,\3,\4 ...
        elsif ($char[$i] =~ m/\A (\\) ((\d)\d*) \z/oxms) {
            if (($3 eq '0') or ($2 >= 40)) {
            }
            else {
                $char[$i] = $1 . ($2 + 1);
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ebig5plus::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ebig5plus::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }
    }

    # return string
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        if ($modifier =~ /e/) {
            return join '', $delimiter, '${1}.', @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
        }
        else {
            return join '', $delimiter, '${1}',  @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
        }
    }
    else {
        if ($modifier =~ /e/) {
            return join '', $delimiter, '${1}.', @char,                               $end_delimiter, $modifier;
        }
        else {
            return join '', $delimiter, '${1}',  @char,                               $end_delimiter, $modifier;
        }
    }
}

#
# escape q string (s''here')
#
sub e_s2_q {
    my($delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    my @char = $string =~ m/ \G ([\x81-\xFE][\x00-\xFF]|[\x00-\xFF]) /oxmsg;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A ([\x81-\xFE]) (\\|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # escape single octet
        elsif ($char[$i] =~ m/\A (\\|\$|\@|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = '\\' . $1;
        }
    }

    $modifier =~ tr/i//d;
    if ($modifier =~ /e/) {
        return join '', $delimiter, '${1}.', @char, $end_delimiter, $modifier;
    }
    else {
        return join '', $delimiter, '${1}',  @char, $end_delimiter, $modifier;
    }
}

#
# escape regexp (qr//)
#
sub e_qr {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    my $metachar = qr/[\@\\|[\]{^]/oxms;

    # split regexp
    my @char = $string =~ m{\G(
        \\  [0-7]{2,3}      |
        \\x [0-9A-Fa-f]{2}  |
        \\c [\x40-\x5F]     |
        \\  (?:[\x81-\xFE][\x00-\xFF] | [\x00-\xFF]) |
        [\$\@] $qq_variable |
        \[\:\^ [a-z]+ \:\]  |
        \[\:   [a-z]+ \:\]  |
        \[\^                |
            (?:[\x81-\xFE\\][\x00-\xFF] | [\x00-\xFF])
    )}oxmsg;

    # unescape character
    my $left_e  = 0;
    my $right_e = 0;
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A \\? ([\x81-\xFE]) ($metachar|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # join separated double octet
        elsif ($char[$i] =~ m/\A \\ (?:2[0-7][1-7]|3[0-7][0-6]) \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice @char, $i+1, 1;
            }
        }
        elsif ($char[$i] =~ m/\A \\x (?:8[1-9A-Fa-f]|[9A-Ea-e][0-9A-Fa-f]|[Ff][0-9A-Ea-e]) \z/oxms) {
            if ($i < $#char) {
                $char[$i] .= $char[$i+1];
                splice @char, $i+1, 1;
            }
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => ($modifier =~ /s/) ?
                    '(?:[\x81-\xFE][\x00-\xFF]|[\x00-\xFF])' :
                    '(?:[\x81-\xFE][\x00-\xFF]|[^\n])',
            '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
            '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
            '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
            '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
            '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # \L \U \Q \E
        elsif ($char[$i] =~ m/\A ([<>]) \z/oxms) {
            if ($right_e < $left_e) {
                $char[$i] = '\\' . $char[$i];
            }
        }
        elsif ($char[$i] eq '\L') {
            $char[$i] = '@{[Ebig5plus::lc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\U') {
            $char[$i] = '@{[Ebig5plus::uc qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\Q') {
            $char[$i] = '@{[CORE::quotemeta qq<';
            $left_e++;
        }
        elsif ($char[$i] eq '\E') {
            if ($right_e < $left_e) {
                $char[$i] = '>]}';
                $right_e++;
            }
            else {
                $char[$i] = '';
            }
        }

        # $scalar or @array
        elsif ($char[$i] =~ m/\A [\$\@].+ /oxms) {
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '@{[Ebig5plus::ignorecase(' . e_string($char[$i]) . ')]}';
            }
            else {
                $char[$i] =                           e_string($char[$i]);
            }
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A 
                (?:
                        [\x81-\xFE] | 
                    \\  (?:2[0-7][1-7]|3[0-7][0-6]) |
                    \\x (?:8[1-9A-Fa-f]|[9A-Ea-e][0-9A-Fa-f]|[Ff][0-9A-Ea-e])
                )
                (?:
                        [\x00-\xFF] |
                    \\  [0-7]{2,3} |
                    \\x [0-9-A-Fa-f]{1,2}
                )
             \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    # make regexp string
    my $re;
    $modifier =~ tr/i//d;
    if ($left_e > $right_e) {
        $re = join '', $ope, $delimiter, $your_gap, @char, '>]}' x ($left_e - $right_e), $end_delimiter, $modifier;
    }
    else {
        $re = join '', $ope, $delimiter, $your_gap, @char,                               $end_delimiter, $modifier;
    }
    return $re;
}

#
# escape regexp (qr'')
#
sub e_qr_q {
    my($ope,$delimiter,$end_delimiter,$string,$modifier) = @_;
    $modifier ||= '';

    $slash = 'div';

    # split regexp
    my @char = $string =~ m{\G(
        \[\:\^ [a-z]+ \:\] |
        \[\:   [a-z]+ \:\] |
        \[\^               |
            (?:[\x81-\xFE\\][\x00-\xFF] | [\x00-\xFF])
    )}oxmsg;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape second octet of double octet
        if ($char[$i] =~ m/\A ([\x81-\xFE]) ([\\|\[\{\^]|\Q$delimiter\E|\Q$end_delimiter\E) \z/xms) {
            $char[$i] = $1 . '\\' . $2;
        }

        # open character class [...]
        elsif ($char[$i] eq '[') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [...]
                    splice @char, $left, $right-$left+1, charlist_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # open character class [^...]
        elsif ($char[$i] eq '[^') {
            my $left = $i;
            while (1) {
                if (++$i > $#char) {
                    die "$0: unmatched [] in regexp";
                }
                if ($char[$i] eq ']') {
                    my $right = $i;

                    # [^...]
                    splice @char, $left, $right-$left+1, charlist_not_qr(@char[$left+1..$right-1], $modifier);

                    $i = $left;
                    last;
                }
            }
        }

        # rewrite character class or escape character
        elsif (my $char = {
            '.'  => ($modifier =~ /s/) ?
                    '(?:[\x81-\xFE][\x00-\xFF]|[\x00-\xFF])' :
                    '(?:[\x81-\xFE][\x00-\xFF]|[^\n])',
            '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
            '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
            '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
            '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
            '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$char[$i]}
        ) {
            $char[$i] = $char;
        }

        # /i modifier
        elsif ($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                $char[$i] = '[' . CORE::uc($c) . CORE::lc($c) . ']';
            }
        }

        # quote double octet character before ? + * {
        elsif (
            ($i >= 1) and
            ($char[$i] =~ m/\A [\?\+\*\{] \z/oxms) and
            ($char[$i-1] =~ m/\A [\x81-\xFE] \\? [\x00-\xFF] \z/oxms)
        ) {
            $char[$i-1] = '(?:' . $char[$i-1] . ')';
        }
    }

    $modifier =~ tr/i//d;
    return join '', $ope, $delimiter, $your_gap, @char, $end_delimiter, $modifier;
}

#
# Big5Plus open character list for qr
#
sub charlist_qr {
    my $modifier = pop @_;
    my @char = @_;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = chr oct $1;
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{2}) \z/oxms) {
            $char[$i] = chr hex $1;
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = chr(ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ m/\A (\\ [0nrtfbaedDhHsSvVwW]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
                '\d' => '\d',
                '\h' => '\h',
                '\s' => '\s',
                '\v' => '\v',
                '\w' => '\w',
                '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
                '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
                '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
                '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
                '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$1};
        }
        elsif ($char[$i] =~ m/\A \\ ([\x81-\xFE][\x00-\xFF] | [\x00-\xFF]) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet = ();
    my @charlist    = ();
    if ((scalar(@char) == 1) or ((scalar(@char) >= 2) and ($char[1] ne '...'))) {
        if ($char[0] =~ m/\A [\x00-\xFF] \z/oxms) {
            push @singleoctet, $char[0];
        }
        else {
            push @charlist, $char[0];
        }
    }
    for (my $i=1; $i <= $#char-1; ) {

        # escaped -
        if ($char[$i] eq '...') {

            # range of single octet code
            if (
                ($char[$i-1] =~ m/\A [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x00-\xFF] \z/oxms)
            ) {
                my $begin = unpack 'C', $char[$i-1];
                my $end   = unpack 'C', $char[$i+1];
                if ($begin > $end) {
                    die "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
                }
                else {
                    if ($modifier =~ m/i/oxms) {
                        my %range = ();
                        for my $c ($begin .. $end) {
                            $range{ord CORE::uc chr $c} = 1;
                            $range{ord CORE::lc chr $c} = 1;
                        }

                        my @lt = grep {$_ < $begin} sort {$a <=> $b} keys %range;
                        if (scalar(@lt) == 1) {
                            push @singleoctet, sprintf(q{\\x%02X},         $lt[0]);
                        }
                        elsif (scalar(@lt) >= 2) {
                            push @singleoctet, sprintf(q{\\x%02X-\\x%02X}, $lt[0], $lt[-1]);
                        }

                        push @singleoctet, sprintf(q{\\x%02X-\\x%02X},     $begin, $end);

                        my @gt = grep {$_ > $end  } sort {$a <=> $b} keys %range;
                        if (scalar(@gt) == 1) {
                            push @singleoctet, sprintf(q{\\x%02X},         $gt[0]);
                        }
                        elsif (scalar(@gt) >= 2) {
                            push @singleoctet, sprintf(q{\\x%02X-\\x%02X}, $gt[0], $gt[-1]);
                        }
                    }
                    else {
                        push @singleoctet, sprintf(q{\\x%02X-\\x%02X},     $begin, $end);
                    }
                }
            }

            # range of double octet code
            elsif (
                ($char[$i-1] =~ m/\A [\x81-\xFE] [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x81-\xFE] [\x00-\xFF] \z/oxms)
            ) {
                my($begin1,$begin2) = unpack 'CC', $char[$i-1];
                my($end1,  $end2)   = unpack 'CC', $char[$i+1];
                my $begin = $begin1 * 0x100 + $begin2;
                my $end   = $end1   * 0x100 + $end2;
                if ($begin > $end) {
                    die "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
                }
                elsif ($begin1 == $end1) {
                    push @charlist, sprintf(q{\\x%02X[\\x%02X-\\x%02X]}, $begin1, $begin2, $end2);
                }
                elsif (($begin1 + 1) == $end1) {
                    push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},   $begin1, $begin2);
                    push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},   $end1,   $end2);
                }
                else {
                    my @middle = ();
                    for my $c ($begin1+1 .. $end1-1) {
                        my $char = chr($c);
                        if ($char =~ /\A [\x81-\xFE] \z/oxms) {
                            push @middle, $c;
                        }
                    }
                    if (scalar(@middle) == 0) {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                    elsif (scalar(@middle) == 1) {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\xFF]},           $middle[0]);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                    else {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{[\\x%02X-\\x%02X][\\x00-\\xFF]}, $middle[0], $middle[-1]);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                }
            }

            # range error
            else {
                die "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
            }

            $i += 2;
        }

        # /i modifier
        elsif (($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) and (($i+1 > $#char) or ($char[$i+1] ne '...'))) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                push @singleoctet, CORE::uc $c, CORE::lc $c;
            }
            else {
                push @singleoctet, $c;
            }
            $i += 1;
        }

        # single character
        elsif ($char[$i] =~ m/\A (?: [\x00-\xFF] | \\d | \\h | \\s | \\v | \\w )  \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }
        else {
            push @charlist, $char[$i];
            $i += 1;
        }
    }
    if ((scalar(@char) >= 2) and ($char[-2] ne '...')) {
        if ($char[-1] =~ m/\A [\x00-\xFF] \z/oxms) {
            push @singleoctet, $char[-1];
        }
        else {
            push @charlist, $char[-1];
        }
    }

    # quote metachar
    for (@singleoctet) {
        if (m/\A \n \z/oxms) {
            $_ = '\n';
        }
        elsif (m/\A \r \z/oxms) {
            $_ = '\r';
        }
        elsif (m/\A ([\x00-\x1F\x7F-\xFF]) \z/oxms) {
            $_ = sprintf(q{\\x%02X}, ord $1);
        }
        elsif (m/\A ([\x00-\xFF]) \z/oxms) {
            $_ = quotemeta $1;
        }
    }
    for (@charlist) {
        if (m/\A ([\x81-\xFE]) ([\x00-\xFF]) \z/oxms) {
            $_ = $1 . quotemeta $2;
        }
    }

    # return character list
    if (scalar(@singleoctet) == 0) {
    }
    elsif ((scalar(@singleoctet) == 1) and ($singleoctet[0] !~ m/\A .-. \z/oxms)) {
        push @charlist, $singleoctet[0];
    }
    else {
        push @charlist, '[' . join('',@singleoctet) . ']';
    }
    if (scalar(@charlist) >= 2) {
        return '(?:' . join('|', @charlist) . ')';
    }
    else {
        return @charlist;
    }
}

#
# Big5Plus open character list for not qr
#
sub charlist_not_qr {
    my $modifier = pop @_;
    my @char = @_;

    # unescape character
    for (my $i=0; $i <= $#char; $i++) {

        # escape - to ...
        if ($char[$i] eq '-') {
            if ((0 < $i) and ($i < $#char)) {
                $char[$i] = '...';
            }
        }
        elsif ($char[$i] =~ m/\A \\ ([0-7]{2,3}) \z/oxms) {
            $char[$i] = chr oct $1;
        }
        elsif ($char[$i] =~ m/\A \\x ([0-9A-Fa-f]{2}) \z/oxms) {
            $char[$i] = chr hex $1;
        }
        elsif ($char[$i] =~ m/\A \\c ([\x40-\x5F]) \z/oxms) {
            $char[$i] = chr(ord($1) & 0x1F);
        }
        elsif ($char[$i] =~ m/\A (\\ [0nrtfbaedDhHsSvVwW]) \z/oxms) {
            $char[$i] = {
                '\0' => "\0",
                '\n' => "\n",
                '\r' => "\r",
                '\t' => "\t",
                '\f' => "\f",
                '\b' => "\x08", # \b means backspace in character class
                '\a' => "\a",
                '\e' => "\e",
                '\d' => '\d',
                '\h' => '\h',
                '\s' => '\s',
                '\v' => '\v',
                '\w' => '\w',
                '\D' => '(?:[\x81-\xFE][\x00-\xFF]|[^\d])',
                '\H' => '(?:[\x81-\xFE][\x00-\xFF]|[^\h])',
                '\S' => '(?:[\x81-\xFE][\x00-\xFF]|[^\s])',
                '\V' => '(?:[\x81-\xFE][\x00-\xFF]|[^\v])',
                '\W' => '(?:[\x81-\xFE][\x00-\xFF]|[^\w])',
            }->{$1};
        }
        elsif ($char[$i] =~ m/\A \\ ([\x81-\xFE][\x00-\xFF] | [\x00-\xFF]) \z/oxms) {
            $char[$i] = $1;
        }
    }

    # open character list
    my @singleoctet = ();
    my @charlist    = ();
    if ((scalar(@char) == 1) or ((scalar(@char) >= 2) and ($char[1] ne '...'))) {
        if ($char[0] =~ m/\A [\x00-\xFF] \z/oxms) {
            push @singleoctet, $char[0];
        }
        else {
            push @charlist, $char[0];
        }
    }
    for (my $i=1; $i <= $#char-1; ) {

        # escaped -
        if ($char[$i] eq '...') {

            # range of single octet code
            if (
                ($char[$i-1] =~ m/\A [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x00-\xFF] \z/oxms)
            ) {
                my $begin = unpack 'C', $char[$i-1];
                my $end   = unpack 'C', $char[$i+1];
                if ($begin > $end) {
                    die "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
                }
                else {
                    if ($modifier =~ m/i/oxms) {
                        my %range = ();
                        for my $c ($begin .. $end) {
                            $range{ord CORE::uc chr $c} = 1;
                            $range{ord CORE::lc chr $c} = 1;
                        }

                        my @lt = grep {$_ < $begin} sort {$a <=> $b} keys %range;
                        if (scalar(@lt) == 1) {
                            push @singleoctet, sprintf(q{\\x%02X},         $lt[0]);
                        }
                        elsif (scalar(@lt) >= 2) {
                            push @singleoctet, sprintf(q{\\x%02X-\\x%02X}, $lt[0], $lt[-1]);
                        }

                        push @singleoctet, sprintf(q{\\x%02X-\\x%02X},     $begin, $end);

                        my @gt = grep {$_ > $end  } sort {$a <=> $b} keys %range;
                        if (scalar(@gt) == 1) {
                            push @singleoctet, sprintf(q{\\x%02X},         $gt[0]);
                        }
                        elsif (scalar(@gt) >= 2) {
                            push @singleoctet, sprintf(q{\\x%02X-\\x%02X}, $gt[0], $gt[-1]);
                        }
                    }
                    else {
                        push @singleoctet, sprintf(q{[\\x%02X-\\x%02X]},   $begin, $end);
                    }
                }
            }

            # range of double octet code
            elsif (
                ($char[$i-1] =~ m/\A [\x81-\xFE] [\x00-\xFF] \z/oxms) and
                ($char[$i+1] =~ m/\A [\x81-\xFE] [\x00-\xFF] \z/oxms)
            ) {
                my($begin1,$begin2) = unpack 'CC', $char[$i-1];
                my($end1,  $end2)   = unpack 'CC', $char[$i+1];
                my $begin = $begin1 * 0x100 + $begin2;
                my $end   = $end1   * 0x100 + $end2;
                if ($begin > $end) {
                    die "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
                }
                elsif ($begin1 == $end1) {
                    push @charlist, sprintf(q{\\x%02X[\\x%02X-\\x%02X]}, $begin1, $begin2, $end2);
                }
                elsif (($begin1 + 1) == $end1) {
                    push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},   $begin1, $begin2);
                    push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},   $end1,   $end2);
                }
                else {
                    my @middle = ();
                    for my $c ($begin1+1 .. $end1-1) {
                        my $char = chr($c);
                        if ($char =~ /\A [\x81-\xFE] \z/oxms) {
                            push @middle, $c;
                        }
                    }
                    if (scalar(@middle) == 0) {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                    elsif (scalar(@middle) == 1) {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\xFF]},           $middle[0]);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                    else {
                        push @charlist, sprintf(q{\\x%02X[\\x%02X-\\xFF]},         $begin1,    $begin2);
                        push @charlist, sprintf(q{[\\x%02X-\\x%02X][\\x00-\\xFF]}, $middle[0], $middle[-1]);
                        push @charlist, sprintf(q{\\x%02X[\\x00-\\x%02X]},         $end1,      $end2);
                    }
                }
            }

            # range error
            else {
                die "$0: invalid [] range \"\\x" . unpack('H*',$char[$i-1]) . '-\\x' . unpack('H*',$char[$i+1]) . '" in regexp';
            }

            $i += 2;
        }

        # /i modifier
        elsif (($char[$i] =~ m/\A ([A-Za-z]) \z/oxms) and (($i+1 > $#char) or ($char[$i+1] ne '...'))) {
            my $c = $1;
            if ($modifier =~ m/i/oxms) {
                push @singleoctet, CORE::uc $c, CORE::lc $c;
            }
            else {
                push @singleoctet, $c;
            }
            $i += 1;
        }

        # single character
        elsif ($char[$i] =~ m/\A (?: [\x00-\xFF] | \\d | \\h | \\s | \\v | \\w )  \z/oxms) {
            push @singleoctet, $char[$i];
            $i += 1;
        }
        else {
            push @charlist, $char[$i];
            $i += 1;
        }
    }
    if ((scalar(@char) >= 2) and ($char[-2] ne '...')) {
        if ($char[-1] =~ m/\A [\x00-\xFF] \z/oxms) {
            push @singleoctet, $char[-1];
        }
        else {
            push @charlist, $char[-1];
        }
    }

    # quote metachar
    for (@singleoctet) {
        if (m/\A \n \z/oxms) {
            $_ = '\n';
        }
        elsif (m/\A \r \z/oxms) {
            $_ = '\r';
        }
        elsif (m/\A ([\x00-\x1F\x7F-\xFF]) \z/oxms) {
            $_ = sprintf(q{\\x%02X}, ord $1);
        }
        elsif (m/\A ([\x00-\xFF]) \z/oxms) {
            $_ = quotemeta $_;
        }
    }
    for (@charlist) {
        if (m/\A ([\x81-\xFE]) ([\x00-\xFF]) \z/oxms) {
            $_ = $1 . quotemeta $2;
        }
    }

    # return character list
    if (scalar(@charlist) >= 1) {
        if (scalar(@singleoctet) >= 1) {
            return '(?!' . join('|', @charlist) . ')(?:[\x81-\xFE][\x00-\xFF]|[^'. join('', @singleoctet) . '])';
        }
        else {
            return '(?!' . join('|', @charlist) . ')(?:[\x81-\xFE][\x00-\xFF])';
        }
    }
    else {
        if (scalar(@singleoctet) >= 1) {
            return                                 '(?:[\x81-\xFE][\x00-\xFF]|[^'. join('', @singleoctet) . '])';
        }
        else {
            return                                 '(?:[\x81-\xFE][\x00-\xFF])';
        }
    }
}

1;

__END__

=pod

=head1 NAME

ebig5plus.pl - Source code filter to escape Big5Plus

=head1 SYNOPSIS

  C:\>perl ebig5plus.pl Big5Plus_script.pl > Escaped_script.pl.e

  Big5Plus_script.pl  --- script written in Big5Plus
  Escaped_script.pl.e --- escaped script

=head1 ABSTRACT

Let's start with a bit of history: jperl 4.019+1.3 introduced Big5Plus support.
You could apply chop() and regexps even to complex CJK characters -- so long as
the script was written in Big5Plus.

Since Perl5.8, Encode module is supported for multilingual processing, and it was
said that jperl became unnecessary. But is it really so?

The UTF-8 is still rare on the Microsoft Windows -- most popular operating systems
we're loving, so many users hope to write scripts in Big5Plus encodings; without
giving up a whole new feature of Perl5.8/5.10.

The Big5Plus was developed in order to maintain backward compatibility. In general,
the operating systems and the programming language keep old interface. To maintain
backward compatibility is an effective solution still now.

Shall we escape from the encode problem?

=head1 THE FUTURE OF JPERL

JPerl is very useful software.
However, the last version of JPerl is 5.005_04 and is not maintained now.

Japanization modifier Hirofumi Watanabe said,

  "Because Watanabe am tired I give over maintaing JPerl."

at Slide #15: "The future of JPerl"
of L<ftp://ftp.oreilly.co.jp/pcjp98/watanabe/jperlconf.ppt>
in The Perl Confernce Japan 1998.

When I heard it, I thought that someone excluding me would maintain JPerl.
And I slept every night hanging a sock. Night and day, I kept having hope.
After 10 years, I noticed that white beard exists in the sock.

So I made this software for I want.

This software is a source code filter to escape Perl script encoded by Big5Plus
given from STDIN or command line parameter. The character code is never converted
by escaping the script. Neither the value of the character nor the length of the
character string change even if it escapes.

I need this software for ...

=over 2

=item * Handling raw Big5Plus values

=item * Handling real length of Big5Plus string

=item * No UTF8 flag

=item * No C programming

=back

Let's make the future of JPerl.

=head1 SOFTWARE COMPOSITION

    jperl55.bat  --- jperl emulator by perl5.5 with ebig5plus.pl
    jperl58.bat  --- jperl emulator by perl5.8 with ebig5plus.pl
    perl58.bat   --- find and run perl5.8 without %PATH% settings
    jperl510.bat --- jperl emulator by perl5.10 with ebig5plus.pl
    perl510.bat  --- find and run perl5.10 without %PATH% settings
    ebig5plus.pl     --- source code filter to escape Big5Plus
    Ebig5plus.pm     --- run-time routines for ebig5plus.pl
    Big5Plus.pm      --- Source code filter for Big5Plus script

=head1 SOFTWARE COMBINATION

This software can be used by the following combinations.

=over 2

=item * COMBINATION #1

    ebig5plus.pl + Ebig5plus.pm
    source code filter to escape Big5Plus

=item * COMBINATION #2

    jperl55.bat + ebig5plus.pl + Ebig5plus.pm
    jperl emulator by perl5.5 with ebig5plus.pl, Ebig5plus.pm (I)

=item * COMBINATION #3

    Big5Plus.pm + ebig5plus.pl + Ebig5plus.pm
    jperl emulator by perl with ebig5plus.pl, Ebig5plus.pm (II)

=item * COMBINATION #4

    jperl58.bat + perl58.bat + ebig5plus.pl + Ebig5plus.pm
    jperl emulator by perl5.8 with ebig5plus.pl, Ebig5plus.pm without %PATH% settings (I)

=item * COMBINATION #5

    perl58.bat + Big5Plus.pm + ebig5plus.pl + Ebig5plus.pm
    jperl emulator by perl5.8 with ebig5plus.pl, Ebig5plus.pm without %PATH% settings (II)

=item * COMBINATION #6

    jperl510.bat + perl510.bat + ebig5plus.pl + Ebig5plus.pm
    jperl emulator by perl5.10 with ebig5plus.pl, Ebig5plus.pm without %PATH% settings (I)

=item * COMBINATION #7

    perl510.bat + Big5Plus.pm + ebig5plus.pl + Ebig5plus.pm
    jperl emulator by perl5.10 with ebig5plus.pl, Ebig5plus.pm without %PATH% settings (II)

=back

=head1 JPerl COMPATIBLE FUNCTIONS

The following functions function as much as JPerl.
A part of function in the script is written and changes by this software.

=over 2

=item * handle double octet string in single quote

=item * handle double octet string in double quote

=item * handle double octet regexp in single quote

=item * handle double octet regexp in double quote

=item * chop --> Ebig5plus::chop

=item * split --> Ebig5plus::split

=item * length

=item * substr

=item * index --> Ebig5plus::index

=item * rindex --> Ebig5plus::rindex

=item * pos

=item * lc --> Ebig5plus::lc

=item * uc --> Ebig5plus::uc

=item * tr/// or y///

/b and /B modifier can also be used.

=item * chr

=item * ord

=item * reverse

=back

=head1 JPerl NOT COMPATIBLE FUNCTIONS

The following functions are not compatible with JPerl. It is the same as
original Perl. 

=over 2

=item * format

It is the same as the function of original Perl.

=item * -B

It is the same as the function of original Perl.

=item * -T

It is the same as the function of original Perl.

=back

=head1 BUGS AND LIMITATIONS

Please patches and report problems to author are welcome.

=over 2

=item * LIMITATION #1

File test operator -T and -B are same as original Perl.

=item * LIMITATION #2

Function "format" can't handle double octet code.

=item * LIMITATION #3

When two or more delimiters of here documents are in one line, if any one is
a double quote type(<<"END", <<END or <<`END`), then all here documents will
escape for double quote type.

    ex.1
        print <<'END';
        ============================================================
        Escaped for SINGLE quote document.   --- OK
        ============================================================
        END

    ex.2
        print <<\END;
        ============================================================
        Escaped for SINGLE quote document.   --- OK
        ============================================================
        END

    ex.3
        print <<"END";
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END

    ex.4
        print <<END;
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END

    ex.5
        print <<`END`;
        ============================================================
        Escaped for DOUBLE quote command.   --- OK
        ============================================================
        END

    ex.6
        print <<'END1', <<'END2';
        ============================================================
        Escaped for SINGLE quote document.   --- OK
        ============================================================
        END1
        ============================================================
        Escaped for SINGLE quote document.   --- OK
        ============================================================
        END2

    ex.7
        print <<"END1", <<"END2";
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END1
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END2

    ex.8
        print <<'END1', <<"END2", <<'END3';
        ============================================================
        Escaped for DOUBLE quote document 'END1', "END2", 'END3'.
        'END1' and 'END3' see string rewritten for "END2".
        ============================================================
        END1
        ============================================================
        Escaped for DOUBLE quote document "END2", 'END3'.
        'END3' see string rewritten for "END2".
        ============================================================
        END2
        ============================================================
        Escaped for DOUBLE quote document "END3".
        'END3' see string rewritten for "END2".
        ============================================================
        END3

    ex.9
        print <<"END1", <<'END2', "END3";
        ============================================================
        Escaped for DOUBLE quote document "END1", 'END2', "END3".
        'END2' see string rewritten for "END1" and "END3".
        ============================================================
        END1
        ============================================================
        Escaped for DOUBLE quote document 'END2', "END3".
        'END2' see string rewritten for "END3".
        ============================================================
        END2
        ============================================================
        Escaped for DOUBLE quote document.   --- OK
        ============================================================
        END3

=item * LIMITATION #4

This software can not escape recursively script loaded by do, require and use.

=back

=head1 HISTORY

This ebig5plus.pl software first appeared in ActivePerl Build 522 Built under
MSWin32 Compiled at Nov 2 1999 09:52:28, created from 'jcode.pl' and the
target is to achieve the same function as 'Jperl.exe'.

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

=head1 MY GOAL

See chapter 15: Unicode
of ISBN 0-596-00027-8 Programming Perl Third Edition.

Before the introduction of utf8 support in perl, The eq operator
just compared the strings represented by two scalars. Beginning
with perl 5.8, eq compares two strings with simultaneous consideration
of the utf8 flag. To explain why I made back it so, I will quote
page 402 of Programming Perl, 3rd ed.

Ideally, I'd like to achieve these five Goals:

=over 2

=item Goal #1:

Old byte-oriented programs should not spontaneously break on the old
byte-oriented data they used to work on.

It has already been achieved by Big5Plus designed for combining with
old byte-oriented ASCII.

=item Goal #2:

Old byte-oriented programs should magically start working on the new
character-oriented data when appropriate.

Still now, 1 octet is counted with 1 by embedded functions length,
substr, index, rindex and pos that handle length and position of string.
In this part, there is no change. The length of 1 character of 2 octet
code is 2.

On the other hand, the regular expression in the script is added the
multibyte anchoring processing with this software. This software does
the rewriting instead of you.

figure of Goal #1 and Goal #2.

                               GOAL#1  GOAL#2
                        (a)     (b)     (c)     (d)     (e)
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New character-oriented

There is a combination from (a) to (e) in data, script and interpreter
of old and new. Let's add the Encode module and this software did not
exist at time of be written this document and JPerl did exist.

                        (a)     (b)     (c)     (d)     (e)
                                      JPerl           Encode,Big5Plus
      +--------------+-------+-------+-------+-------+-------+
      | data         |  Old  |  Old  |  New  |  Old  |  New  |
      +--------------+-------+-------+-------+-------+-------+
      | script       |  Old  |      Old      |      New      |
      +--------------+-------+---------------+---------------+
      | interpreter  |  Old  |              New              |
      +--------------+-------+-------------------------------+
      Old --- Old byte-oriented
      New --- New character-oriented

The reason why JPerl is very excellent is that it is at the position of
(c). That is, it is not necessary to do a special description to the
script to process Japanese.

Contrasting is Encode module and describing "use Big5Plus;" on this software,
in this case, a new description is necessary.

=item Goal #3:

Programs should run just as fast in the new character-oriented mode
as in the old byte-oriented mode.

It is impossible. Because the following time is necessary.

(1) Time of escape script for old byte-oriented perl.

(2) Time of processing regular expression by escaped script while
    multibyte anchoring.

=item Goal #4:

Perl should remain one language, rather than forking into a
byte-oriented Perl and a character-oriented Perl.

A character-oriented Perl is not necessary to make it specially,
because a byte-oriented Perl can already treat the binary data.
This software is only an application program of Perl, a filter program.
If perl can be executed, this software will be able to be executed.

=item Goal #5:

JPerl users will be able to maintain JPerl by Perl.

It means the Perl programmer exists if there are needs of JPerl, I hope
I get peaceful sleep at night.

=back

Back when Programming Perl, 3rd ed. was written, UTF-8 flag was not born
and Perl was designed to make the easy jobs easy. This software provide
programming environment like at that time.

=head1 SEE ALSO

 C<Programming Perl, Third Edition>
 By Larry Wall, Tom Christiansen, Jon Orwant
 Third Edition  July 2000
 Pages: 1104
 ISBN 10: 0-596-00027-8 | ISBN 13:9780596000271
 L<http://www.oreilly.com/catalog/pperl3/index.html>
 ISBN 4-87311-096-3
 L<http://www.oreilly.co.jp/books/4873110963/>
 ISBN 4-87311-097-1
 L<http://www.oreilly.co.jp/books/4873110971/>

 C<Perl Cookbook, Second Edition>
 By Tom Christiansen, Nathan Torkington
 Second Edition  August 2003
 Pages: 964
 ISBN 10: 0-596-00313-7 | ISBN 13: 9780596003135
 L<http://oreilly.com/catalog/9780596003135/index.html>

 C<Perl in a Nutshell, Second Edition>
 By Stephen Spainhour, Ellen Siever, Nathan Patwardhan
 Second Edition  June 2002
 Pages: 760
 Series: In a Nutshell
 ISBN 10: 0-596-00241-6 | ISBN 13: 9780596002411
 L<http://oreilly.com/catalog/9780596002411/index.html>

 C<CJKV Information Processing>
 Chinese, Japanese, Korean & Vietnamese Computing
 By Ken Lunde
 First Edition  January 1999
 Pages: 1128
 ISBN 10: 1-56592-224-7 | ISBN 13:9781565922242
 L<http://www.oreilly.com/catalog/cjkvinfo/index.html>
 ISBN 4-87311-108-0
 L<http://www.oreilly.co.jp/books/4873111080/>

 C<Mastering Regular Expressions, Second Edition>
 By Jeffrey E. F. Friedl
 Second Edition  July 2002
 Pages: 484
 ISBN 10: 0-596-00289-0 | ISBN 13: 9780596002893
 L<http://oreilly.com/catalog/9780596002893/index.html>

 C<Mastering Regular Expressions, Third Edition>
 By Jeffrey E. F. Friedl
 Third Edition  August 2006
 Pages: 542
 ISBN 10: 0-596-52812-4 | ISBN 13:9780596528126
 L<http://www.oreilly.com/catalog/regex3/index.html>
 ISBN 978-4-87311-359-3
 L<http://www.oreilly.co.jp/books/9784873113593/>

 C<PERL PUROGURAMINGU>
 Larry Wall, Randal L.Schwartz, Yoshiyuki Kondo
 December 1997
 ISBN 4-89052-384-7
 L<http://www.context.co.jp/~cond/books/old-books.html>

 C<JIS KANJI JITEN>
 Kouji Shibano
 Pages: 1456
 ISBN 4-542-20129-5
 L<http://www.webstore.jsa.or.jp/lib/lib.asp?fn=/manual/mnl01_12.htm>

=head1 ACKNOWLEDGEMENTS

This software was made, thanks to the following hackers or persons.
Especially this POD was written referring from the Encode module.
I am thankful to all persons.

 Rick Yamashita, Big5Plus
 http://furukawablog.spaces.live.com/Blog/cns!1pmWgsL289nm7Shn7cS0jHzA!2225.entry

 Larry Wall, Perl
 L<http://www.perl.org/>

 Kazumasa Utashiro, jcode.pl
 L<http://www.srekcah.org/jcode/>

 Jeffrey E. F. Friedl, Mastering Regular Expressions
 L<http://www.oreilly.com/catalog/regex/index.html>

 SADAHIRO Tomoyuki, The right way of using Big5Plus
 L<http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm>

 jscripter, For jperl users
 L<http://homepage1.nifty.com/kazuf/jperl.html>

 Hiroaki Izumi, Perl5.8/Perl5.10 is not useful on the Windows.
 L<http://www.aritia.org/hizumi/perl/perlwin.html>

 SUZUKI Norio, Jperl
 L<http://homepage2.nifty.com/kipp/perl/jperl/>

 Hirofumi Watanabe, Jperl
 L<http://search.cpan.org/~watanabe/>

 Dan Kogai, Encode module
 L<http://search.cpan.org/dist/Encode/>

=cut

