package My::Devel::Installed;

use Exporter qw(import);
our @EXPORT = qw(show_installed show list_installed list);

# http://perldoc.perl.org/perlfaq3.html

sub list_installed
{
    use ExtUtils::Installed;
    use Module::CoreList;

    my @inc = grep { $_ ne '.' } @INC;

    my @installed = ExtUtils::Installed->new(inc_override => \@inc)->modules;
    @installed = grep { $_ ne 'Perl' } @installed;

    push @installed, Module::CoreList->find_modules();

    my %installed = map { $_ => 1 } @installed;
    return sort keys %installed;
}

sub show_installed
{
    print join "\n", list_installed();
}

sub _read_from_file_handle
{
    my $fh = shift;

    my @list = <$fh>;
    s/^\s+|\s+$//g for @list;

    return @list;
}

sub show
{
    print join "\n", list(@_);
}

sub list
{
    use File::Find;

    my @dirs = ();
    if (@_) {
        if (ref($_[0]) eq 'GLOB') {
            @dirs = _read_from_file_handle($_[0]);
        } 
        else {
            @dirs = @_;
        }
    }
    else {
        use Cwd;
        push @dirs, scalar getcwd();
    }

    my @all_files = ();

    for my $dir (@dirs) {
        $dir =~ s/[\\\/]+$//g;

        my @files = ();

        find(
            {
                wanted => sub {
                    push @files, $File::Find::name
                    if -f $File::Find::name && /\.pm$/
                },
                follow => 1,
                follow_skip => 2,
            },
            $dir
        );

        for my $file (@files) {
            $file = substr $file, length($dir)+1;
            $file =~ s/[\/\\]/::/g;
            $file =~ s/\.pm$//;
        }

        push @all_files, @files;
    }

    return @all_files;
}

1;
