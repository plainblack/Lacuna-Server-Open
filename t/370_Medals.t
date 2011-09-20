use lib '../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use 5.010;
$|=1;


use TestHelper;

my @medals = keys %{Lacuna::DB::Result::Medals::MEDALS()};
plan tests => scalar @medals;

my $assets = '/data/Lacuna-Assets/medal/';

opendir(my $dir, $assets);
my @images = readdir $dir;
closedir $dir;

foreach my $key (@medals) {
    my $file = $key.'.png';
    ok($file ~~ @images, $key);
}




