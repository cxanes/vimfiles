package My::Devel::IntelliPerl::Editor;

use Exporter qw(import);
our @EXPORT = qw(show_methods get_methods);

use Devel::IntelliPerl;

sub show_methods
{
    print join "\n", get_methods();
}

sub get_methods
{
    my @data = <STDIN>;
    my ($line_number, $column, $filename, @source) = @data;

    $filename =~ s/\s+$//g;

    my $ip = Devel::IntelliPerl->new(
        line_number => $line_number+0,
        column      => $column+0,
        filename    => $filename,
        source      => join('', @source),
    );

    my @methods = $ip->methods;
    if (my $error = $ip->error) {
        die "$error\n";
    }

    return @methods;
}
