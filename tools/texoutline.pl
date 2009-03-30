#!/usr/bin/perl

use warnings;
use strict;

use Cwd qw(abs_path);
use File::Spec;

# Modified from 
#  http://macromates.com/svn/Bundles/trunk/Bundles/Latex.tmbundle/Commands/Show%20Outline.tmCommand

my $REGEX = qr/\\(part|chapter|section|subsection|subsubsection|paragraph|subparagraph)\*?(?:%.*\n[ \t]*)?(?:(?>\[(.*?)\])|\{([^{}]*(?:\{[^}]*\}[^}]*?)*)\})/;
my $INCLUDE_REGEX = qr/\\(?:input|include)(?:%.*\n[ \t]*)?(?>\{(.*?)\})/;
my $NON_COMMENT_REGEX = qr/^((?:[^%]|\\%)*)(?=%|$)/;

sub adjust_end
{

    my ($path, $filename) = @_;
    $path =~ s{[^\\/]*$}{$filename};
    $path .= '.tex' unless $path =~ /\.tex$/;
    return $path;
}

sub outline_points
{
    my $filename = shift;
    my @points = ();

    my @lines = ();
    my $name = '';

    if (ref($filename) eq 'GLOB') {
        @lines = <$filename>;
        $filename = File::Spec->join(getcwd(), 'dummy')
    }
    else {
        my $fh;
        if (open $fh, $filename) {
            @lines = <$fh>;
            close $fh;
        }

        $name = $filename;
    }

    my $i = 1;
    for my $line (@lines) {
        $line = $line =~ /$NON_COMMENT_REGEX/ ? $1 : '';
        push @points, [$name, $i, $1, $2 ? $2 : $3] if $line =~ /$REGEX/;
        push @points, outline_points(adjust_end($filename, $1)) if $line =~ /$INCLUDE_REGEX/;
        ++$i;
    }

    return @points;
}

my @points = outline_points(abs_path($ARGV[0]));
for my $point (@points)
{
    print join "\t", @$point;
    print "\n";
}
