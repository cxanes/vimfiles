# RC file of latexmk

if ( $^O eq "cygwin" ) {
    $latex_silent_switch    = '-interaction=batchmode -c-style-errors -synctex=-1';
    $pdflatex_silent_switch = '-interaction=batchmode -c-style-errors -synctex=-1';
}
elsif ( ! $^O eq "MSWin32" ) {
    $latex_silent_switch    = '-interaction=batchmode -file-line-error -synctex=-1';
    $pdflatex_silent_switch = '-interaction=batchmode -file-line-error -synctex=-1';
}

our $xelatex = 'xelatex %O %S';

sub UseXeTeX ()
{
    $pdflatex = $xelatex;
}

# vim: ft=perl :
