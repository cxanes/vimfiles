#!/usr/bin/perl

use warnings;
use strict;

open(my $cscope, '|-', "cscope @ARGV");
binmode($cscope);
select((select($cscope), $| = 1)[0]);

while (defined(my $cmd = <STDIN>))
{
    # strip '\r' in Win32, since it will be included 
    # as part of pattern.
    $cmd =~ s{\r}{}g;

    print {$cscope} $cmd;
    exit if $cmd =~ /^\x04/ || $cmd =~ /^q/;
}
