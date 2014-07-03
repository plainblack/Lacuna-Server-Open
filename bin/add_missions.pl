use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use List::Util qw(shuffle);
$|=1;
our $quiet;
our $mission;
our $zone;
our $number = 3;
GetOptions(
    'quiet'         => \$quiet,
    'mission=s'     => \$mission,
    'zone=s'        => \$zone,
    'number=i'      => \$number,
);


out('Started');
my $start = time;

out('Finding Mission Files');
my @mission_files = get_mission_files();

out('Loading DB...');
our $db = Lacuna->db;
our $dtf = $db->storage->datetime_parser;
our $missions = $db->resultset('Lacuna::DB::Result::Mission');

out('Deleting missions nobody has completed...');
my $old = $missions->search({date_posted => { '<' => $dtf->format_datetime(DateTime->now->subtract( hours => 72 ))}});
while (my $mission = $old->next) {
    $mission->incomplete;
}

if ($mission ne '' && $zone ne '') {
    out('Adding specific mission...');
    my $mission = Lacuna::DB::Result::Mission->initialize($zone, $mission);
    say $mission->params->get('name').' added to '.$zone.'!';
}
else {
    out('Adding missions...');
    out(scalar @mission_files. " mission files");
    my @zones;
    if ($zone ne '') {
        @zones = ($zone);
    }
    else {
        @zones = $db->resultset('Lacuna::DB::Result::Map::Body')->search(
            { empire_id => { '>' => 0 }},
            { distinct => 1 })->get_column('zone')->all;
    }
    foreach my $zone (@zones) {
        out($zone);
        my $current_missions = $db->resultset('Lacuna::DB::Result::Mission')->search(
            { zone => "$zone" });
        my @current;
        while (my $mission = $current_missions->next) {
          push @current, $mission->mission_file_name;
        }
        out(scalar @current. " current missions");
        my @avail;
        for my $mission (@mission_files) {
          push @avail, $mission unless ( grep { $mission eq $_ } @current);
        }
        out(scalar @avail. " to pick from");

        foreach (1..$number) {
            last unless scalar @avail > 0;
            my $mission_file = splice(@avail, rand(@avail), 1);
            my $mission = Lacuna::DB::Result::Mission->initialize($zone, $mission_file);
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


