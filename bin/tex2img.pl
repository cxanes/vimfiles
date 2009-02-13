#!/usr/bin/perl
# vim: fdm=marker :
# Author: Frank Chang <frank.nevermind@gmail.com>

use warnings;
use strict;

use File::Path qw/mkpath/;
use File::Spec;
use File::Basename;
use Getopt::Long;
use Cwd;
use File::Copy;
use IO::File;

Getopt::Long::Configure ("bundling");
our $PROGRAM = basename($0);
my $img_viewer0 ='preview';
$img_viewer0 .= '.bat' if $^O eq 'cygwin';
my $img_viewer = $ENV{IMG_VIEWER} ? $ENV{IMG_VIEWER} : $img_viewer0;

#{{{ exist_file()
sub exist_file ($) 
{
    my $fn = shift;
    return 0 if not $fn;

    if (File::Spec->file_name_is_absolute($fn)) {
        return -e $fn ? 1 : 0;
    }
    else {
        for my $dir (File::Spec->path()) {
            return 1 if -e File::Spec->catfile($dir, $fn);
        }
    }

    return 0
}
#}}}
#{{{ error_mesg()
sub error_mesg (@)
{
    print "$PROGRAM: error: ", @_, "\n";
    return 1;
}
#}}}
#{{{ shellescape()
sub shellescape (@)
{
    my @args = @_;
    for my $arg (@args) {
        $arg =~ s/'/"'"/g;
        $arg = "'$arg'";
    }
    return wantarray ? @args : join(' ', @args);
}
#}}}
#{{{ program_check()
sub program_check (@)
{
    for my $prog (@_) {
        if (!exist_file($prog)) {
            error_mesg qq{"$prog" doesn't exist};
            exit 1;
        }
    }
}
#}}}
#{{{ run_and_check()
sub run_and_check (@) 
{
    system @_;
    if ($?) {
        error_mesg @_;
        exit 1
    }
}
#}}}
#{{{ print_usage()
sub print_usage ()
{
print <<END_USAGE;
Usage: $PROGRAM [OPTIONS] [FILE]
Generate image from TeX FILE.
TeX file contains only the body of the document (without preamble).

If FILE is omitted, read TeX code from stdin.

Options:
    -p <preamble>   The file containing specified preamble.
    -x <preamble>   The file containing extra preamble

    -t <tex>        Generate image fomr <tex> code directly.
                    FILE will be ignored.

    -o <file>       Place the output into <file>.

                    The image format is detected by the extension
                    of <file>.

                    If <file> is omitted, view the image directly
                    using program "$img_viewer" (specified by the 
                    environment variable \$IMG_VIEWER).

    -f              The image format (if -o is not set, default is png,
                    otherwise the format is detected by the extension of
                    output filename).

    -c <type>       <type> = 1: dvipng   (default if divpng exists and
                                          output format is not eps)
                    <type> = 2: dvips

                    If output format is eps, always use dvips.

    -m <opts>       Options which are passed to 'convert'.

    --help
    -h              Print this help and exit.
END_USAGE
    exit 1
}
#}}}
#{{{ get_filehandle()
sub get_filehandle ($)
{
    my $filename = shift;
    return $filename eq '-' ? *STDIN : IO::File->new($filename);
}
#}}}
#{{{ create_tex_file()
sub create_tex_file (@)
{
    my ($input, $preamble, $tex_file) = @_;

    open my $output, '>', $tex_file;
    print {$output} "$preamble\n\\begin{document}\n";
    if (ref($input) eq 'CODE') {
        print {$output} &$input;
    }
    else {
        my $fh = get_filehandle($input);
        my $content = '';
        while (read $fh, $content, 4096) {
            print {$output} $content;
        }
    }
    print {$output} '\end{document}';
    return;
}
#}}}
#{{{ read_file()
sub read_file ($)
{
    my $fh = shift;
    if (ref($fh) ne 'GLOB') {
        $fh = get_filehandle($fh);
    }

    local $/;
    return readline($fh);
}
#}}}
#{{{ get_preamble()
sub get_preamble (@)
{
    my ($opt, $dir) = @_;

    my $tex_fmt='preamble';
    my $preamble = read_file($opt->{preamble} ? $opt->{preamble} : \*DATA) . "\n";

    if ($opt->{extra_preamble}) {
        $preamble .= read_file($opt->{extra_preamble}) . "\n";
    }

    return $preamble if !$dir;

    my $preamble_file  = File::Spec->catfile($dir, "${tex_fmt}.tex");
    my $preamble_old = '';
    if (-e $preamble_file) {
        $preamble_old = read_file($preamble_file);
    }

    if ($preamble eq $preamble_old 
        && -e File::Spec->catfile($dir, "${tex_fmt}.fmt")) {
        return "%&$tex_fmt\n";
    }

    open my $fh, '>', $preamble_file or return $preamble;
    print {$fh} $preamble;
    close $fh;

    # http://magic.aladdin.cs.cmu.edu/2007/11/02/precompiled-preamble-for-latex/
    {
        my $cwd = getcwd;
        chdir $dir;

        # system 'latex', '-ini', '-interaction=batchmode', '-jobname', $tex_fmt,
        #     "&latex $tex_fmt.tex\\dump";
        system sprintf('latex -ini -interaction=batchmode -jobname %s %s >/dev/null 2>&1',
            shellescape($tex_fmt, "&latex $tex_fmt.tex\\dump"));

        chdir $cwd;
        return "%&$tex_fmt\n" if !$?;
    }

    return $preamble;
}
#}}}
#{{{ cygpath()
sub cygpath (@)
{
    my @args = @_;
    return qx/cygpath @{[shellescape @args]}/;
}
#}}}
#{{{ validate_opt()
sub validate_opt ($)
{
    my $opt = shift;

    my $preamble = $opt->{preamble};
    if ($preamble && !-e $preamble) {
        error_mesg qq{The preamble file "$preamble" doesn't exist.};
        return 0;
    }

    my $extra_preamble = $opt->{extra_preamble};
    if ($extra_preamble && ! -e $extra_preamble) {
        error_mesg qq{The extra preamble file "$extra_preamble" doesn't exist.};
        return 0;
    }

    my $input = $opt->{input};

    if (!$input && !$opt->{tex_text}) {
        error_mesg 'The input filename is empty.';
        return 0;
    }

    if ((grep { defined($_) && $_ eq '-' } $preamble, $extra_preamble, $input) > 1) {
        error_mesg 'Multiple resources read from stdin.';
        return 0;
    }

    return 1;
}
#}}}
#{{{ get_opt()
sub get_opt ()
{
    my %opt = (
        conv_type => exist_file('dvipng') ? 1 : 2,
    );

    GetOptions(
        'p=s'    => \$opt{preamble},
        'x=s'    => \$opt{extra_preamble},
        't=s'    => \$opt{tex_text},
        'o=s'    => \$opt{output},
        'f=s'    => \$opt{output_ext},
        'l=s'    => \$opt{position},
        'c=i'    => \$opt{conv_type},
        'm=s'    => \$opt{conv_opts},
        'help|h' => sub { print_usage; exit 0 }
    ) or do {
        error_mesg qq{Type "$PROGRAM -h" to see possible options};
        exit 1
    };

    $opt{input} = $ARGV[0] if $ARGV[0];

    for my $field ('input', 'output', 'preamble', 'extra_preamble') {
        my $value = $opt{$field};
        if ($value && $value ne '-') {
            # $value = cygpath($value) if $^O eq 'cygwin';
            $opt{$field} = File::Spec->rel2abs($value);
        }
    }

    validate_opt(\%opt) or exit 1;
    return \%opt;
}
#}}}
#{{{ dvieps()
sub dvieps ($)
{
    my $input = shift;

    program_check 'dvips';
    run_and_check 'dvips', '-q', '-o', "${input}.ps", "${input}.dvi";

    if (exist_file('/usr/bin/ps2epsi')) {
        run_and_check '/usr/bin/ps2epsi', "${input}.ps", "${input}.eps";
    }
    else {
        program_check 'ps2epsi';
        run_and_check 'ps2epsi', "${input}.ps", "${input}.eps";
    }
    return;
}
#}}}
#{{{ imgimg()
sub imgimg ($$$)
{
    program_check 'convert';
    my ($opts, $in, $out) = @_;

    run_and_check sprintf("convert $opts %s %s", shellescape($in, $out));
}
#}}}
#{{{ dvipng()
sub dvipng ($)
{
    my $input = shift;

    my $dvipng = exist_file('/usr/bin/dvipng') ? '/usr/bin/dvipng'
               : exist_file('dvipng')          ? 'dvipng'
               :                                 ''
               ;
    if ($dvipng) {
        program_check '/usr/bin/dvipng', 'dvipng';
    }

    # system $dvipng, '-bgWhite', '-Ttight',  '--noghostscript', 
    #     '-l1', '-Q8', "${input}.dvi";
    system sprintf("$dvipng -bgWhite -Ttight --noghostscript -l1 -Q8 %s >/dev/null 2>&1",
        shellescape("${input}.dvi"));
    move "${input}1.png", "${input}.png";
}
#}}}
#{{{ latex()
sub latex ($)
{
    my ($tex_file, $dir) = fileparse(shift(), qr{\.tex});

    my $cwd = getcwd;
    chdir $dir;
    
    # system 'latex', '-parse-first-line', '-interaction=batchmode',  $tex_file;
    system sprintf('latex -parse-first-line -interaction=batchmode %s >/dev/null 2>&1',
        shellescape($tex_file));

    if ($? || !-e "${tex_file}.dvi") {
        error_mesg 'latex ran but failed';
        exit 1
    }
    chdir $cwd;
    return File::Spec->catfile($dir, "$tex_file.dvi");
}

sub dviimg (@)
{
    my ($input, $opt) = @_;
    my ($dvi_file, $dir) = fileparse($input, qr{\.dvi});

    my $img_ext = 'png';
    if ($opt->{ouput} && $opt->{ouput} =~ m{\.([^.\\/]+)$}) {
        $img_ext = $1;
    }

    if ($opt->{output_ext}) {
        $img_ext = $opt->{output_ext};
    }

    my $img_ext_lc = lc $img_ext;
    my $out_tmp = "${dvi_file}.${img_ext}";

    my $cwd = getcwd;
    chdir $dir;

    if ($img_ext_lc eq 'eps') {
        dvieps $dvi_file;
    }
    elsif ($opt->{conv_type} == 1) {
        dvipng $dvi_file;
        if ($img_ext_lc ne 'png') {
            my $conv_opts = $opt->{conv_opts} ? $opt->{conv_opts} : '';
            imgimg $conv_opts, "${dvi_file}.png", $out_tmp; 
        }
    }
    else {
        dvieps $dvi_file;
        my $conv_opts = $opt->{conv_opts} ? $opt->{conv_opts} : '';
        imgimg $conv_opts, "${dvi_file}.eps", $out_tmp;
    }

    chdir $cwd;
    return (File::Spec->catfile($dir, $out_tmp), $img_ext);
}
#}}}
#{{{ show_img()
sub show_img (@)
{
    my ($img_file, $opt) = @_;

    # In win32, Vim uses DeleteFile()
    # <http://msdn2.microsoft.com/en-us/library/aa363915(VS.85).aspx> to
    # delete output tempfile, but it fails when file is still open for
    # normal I/O.
    #
    # We redirect STDIN and STDERR to /dev/null, so the output tempfile
    # created by Vim can be deleted successfully.
    my $dir;
    ($img_file, $dir) = fileparse($img_file);
    chdir $dir;
    if ($img_viewer eq $img_viewer0) {
        if ($opt->{position}) {
            system sprintf('%s -s %s -p %s >/dev/null 2>&1 &', 
                shellescape($img_viewer, $img_file, $opt->{position}));
        }
        else {
            system sprintf('%s -s %s >/dev/null 2>&1 &', 
                shellescape($img_viewer, $img_file));
        }
    }
    else {
        system sprintf('%s %s >/dev/null 2>&1 &', 
            shellescape($img_viewer, $img_file));
    }
}
#}}}
#{{{ main()
sub main()
{
    program_check 'latex';

    my $cwd = getcwd;
    if ($^O eq 'cygwin' && -d '/cygdrive/c/texmf/miktex/bin') {
        $ENV{PATH} = '/cygdrive/c/texmf/miktex/bin' . ($ENV{PATH} ? ":$ENV{PATH}" : '');
        my $path = $cwd;
        $path =~ s{^/cygdrive/(.)/}{$1:/};
        $path =~ y{/}{\\};
        $ENV{TEXINPUTS} = '.;' . $path . ($ENV{TEXINPUTS} ? ";$ENV{TEXINPUTS}" : '');
    }
    else {
        $ENV{TEXINPUTS} = ".:$cwd" . ($ENV{TEXINPUTS} ? ":$ENV{TEXINPUTS}" : '');
    }

    my $temp_dir = "/tmp/$PROGRAM.tmp";
    mkpath($temp_dir) if not -d $temp_dir;

    my $temp = 'image';
    unlink glob "$temp_dir/${temp}*";

    my $opt = get_opt;
    my $input = defined($opt->{tex_text}) ? sub { $opt->{tex_text} }
              :                             $opt->{input}
              ;

    my $preamble = get_preamble($opt, $temp_dir);
    my $tex_file= File::Spec->catfile($temp_dir, "${temp}.tex");

    create_tex_file $input, $preamble => $tex_file;
    my $dvi_file = latex $tex_file;
    my ($img_file, $img_ext) = dviimg $dvi_file, $opt;

    if ($opt->{output}) {
        if ($opt->{output} eq '-') {
            binmode(STDOUT);
            print read_file($img_file);
        }
        elsif ($opt->{output} =~ /^\Q.$img_ext\E$/i) {
            move $img_file, 
                ($opt->{output} . ($opt->{output} =~ /^\Q.$img_ext\E$/i ? '' : ".$img_ext"));
        }
    }
    else {
        show_img $img_file, $opt;
    }

    return;
}
#}}}
#===================================
main;

__DATA__
\documentclass[12pt]{article}
\usepackage{type1cm}
\usepackage{amsmath,amsmath,amsthm,amssymb}
\usepackage{graphicx}
\usepackage{color}
\pagestyle{empty}
