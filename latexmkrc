# RC file of latexmk

if ( $^O eq "cygwin" ) {
    $latex_silent_switch    = '-interaction=batchmode -c-style-errors';
    $pdflatex_silent_switch = '-interaction=batchmode -c-style-errors';
}
elsif ( ! $^O eq "MSWin32" ) {
    $latex_silent_switch    = '-interaction=batchmode -file-line-error';
    $pdflatex_silent_switch = '-interaction=batchmode -file-line-error';
}

our $xelatex = 'xelatex %O %S';

sub UseXeTeX ()
{
    $pdflatex = $xelatex;
}

# vim: ft=perl :
