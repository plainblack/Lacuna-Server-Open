use 5.010;
use lib ('../lib', '../t');
use Lacuna::DB;
use Module::Find;
use TestHelper;

my $tester = TestHelper->new->generate_test_empire;
my $db = Lacuna->db;
my $empire = $tester->empire;

open my $file, '>', '/tmp/stats.csv';
print {$file} 'Name,Energy Hour,Food Hour,Ore Hour,Water Hour,Waste Hour,Happiness Hour,Energy Cost,Food Cost,Ore Cost,Water Cost,Waste Cost,Time Cost,Energy Storage,Food Storage,Ore Storage,Water Storage,Waste Storage'."\n";
foreach my $module (findallmod Lacuna::DB::Result::Building) {
    my @row;
    my $object = $db->resultset('Lacuna::DB::Result::Building')->new({ class=>$module, body=>$empire->home_planet});
    $object->level(1);
    next if $object->name eq 'Building';
    push @row, $object->name;
    push @row, $object->energy_hour;
    push @row, $object->food_hour;
    push @row, $object->ore_hour;
    push @row, $object->water_production - $object->water_consumption; # depends on planet, so faking it
    push @row, $object->waste_hour;
    push @row, $object->happiness_hour;
    push @row, $object->energy_to_build;
    push @row, $object->food_to_build;
    push @row, $object->ore_to_build;
    push @row, $object->water_to_build;
    push @row, $object->waste_to_build;
    push @row, $object->time_to_build;
    push @row, $object->energy_storage;
    push @row, $object->food_storage;
    push @row, $object->ore_storage;
    push @row, $object->water_storage;
    push @row, $object->waste_storage;
    print {$file} join(",", @row)."\n";
}
close $file;
$tester->cleanup;
