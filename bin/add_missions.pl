use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;

out('Finding Mission Files');
my @mission_files = get_mission_files();

out('Loading DB...');
our $db = Lacuna->db;
our $missions = $db->resultset('Lacuna::DB::Result::Mission');
our $news = $db->resultset('Lacuna::DB::Result::News');

out('Deleting missions nobody has completed...');
$missions->search({
    date_posted => { '<' => DateTime->now->subtract( hours => 72 )}
})->delete;

out('Adding missions...');
my @zones = $db->resultset('Lacuna::DB::Result::Map::Body')->search(
    { empire_id => { '>' => 0 }},
    { distinct => 1 })->get_column('zone')->all;
foreach my $zone (@zones) {
    out($zone);
    if ($missions->search({zone=>$zone})->count < 51) {
        foreach (1..3) {
            my $mission = $missions->new({
                zone                 => $zone,
                mission_file_name    => $mission_files[rand @mission_files],
            });
            $mission->max_university_level($mission->params->get('max_university_level'));
            $mission->insert;
            say $mission->params->get('name');
            $news->new({
                zone                => $zone,
                headline            => $mission->params->get('network_19_headline'),
            })->insert;
        }
    }
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############


sub get_mission_files {
    opendir my $dir, '/data/Lacuna-Server/var/missions/';
    my @files = readdir $dir;
    closedir $dir;
    my @missions;
    foreach my $file (@files) {
        next unless $file =~ m/\.mission$/;
        push @missions, $file;
    }
    return @missions;
}


sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


