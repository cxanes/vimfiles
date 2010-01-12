package My::Devel::IntelliPerl::Editor;

use Exporter qw(import);
our @EXPORT = qw(run);

use Devel::IntelliPerl;

sub run {
    my @data = <STDIN>;
    my ($line_number, $column, $filename, @source) = @data;

    $filename =~ s/\s+$//g;

    my $ip = Devel::IntelliPerl->new(
        line_number => $line_number+0,
        column      => $column+0,
        filename    => $filename,
        source      => join('', @source),
    );

    if (my $error = $ip->error) {
        die "$error\n";
    }


    my @methods = $ip->methods;
    print join("\n", @methods);
}
