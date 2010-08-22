use 5.010;
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq);

open my $file, "<", "../var/starnames.txt";
my @contents = <$file>;
close $file;

my @unified;
foreach my $name (@contents) {
    push @unified, join ' ', map {  ucfirst lc $_ } split '\s', $name;
}

my @unique = uniq(@unified);

open my $file, ">", "../var/starnames-fixed.txt";
say {$file} join("\n", @unique);
close $file;

