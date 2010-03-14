use lib '../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use 5.010;
$|=1;


use TestHelper;
use Lacuna::Constants qw(MEDALS);

my @medals = keys %{MEDALS()};
plan tests => scalar @medals;

my $assets = '/Users/jtsmith/Dropbox/lacuna/assets/medal/';

opendir(my $dir, $assets);
my @images = readdir $dir;
closedir $dir;

foreach my $key (@medals) {
    my $file = $key.'.png';
    ok($file ~~ @images, $key);
}




