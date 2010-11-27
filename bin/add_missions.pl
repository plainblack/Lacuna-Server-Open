use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use List::Util qw(shuffle);
$|=1;
our $quiet;
our $mission;
our $zone;
GetOptions(
    'quiet'         => \$quiet,
    'mission=s'     => \$mission,
    'zone=s'        => \$zone,
);


out('Started');
my $start = time;

out('Finding Mission Files');
my @mission_files = get_mission_files();

out('Loading DB...');
our $db = Lacuna->db;
our $missions = $db->resultset('Lacuna::DB::Result::Mission');

out('Deleting missions nobody has completed...');
my $old = $missions->search({date_posted => { '<' => DateTime->now->subtract( hours => 72 )}});
while (my $mission = $old->next) {
    $mission->incomplete;
}

if ($mission ne '' && $zone ne '') {
    out('Adding specific mission...');
    my $mission = $missions->initialize($zone, $mission);
    say $mission->params->get('name').' added to '.$zone.'!';
}
else {
    out('Adding missions...');
    my @zones = $db->resultset('Lacuna::DB::Result::Map::Body')->search(
        { empire_id => { '>' => 0 }},
        { distinct => 1 })->get_column('zone')->all;
    foreach my $zone (@zones) {
        out($zone);
        foreach (1..3) {
            my $mission = $missions->initialize($zone, $mission_files[rand @mission_files]);
            say $mission->params->get('name');
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
    opendir my $dir, '/data/Lacuna-Mission/missions/';
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


