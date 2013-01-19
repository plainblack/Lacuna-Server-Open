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

out('Loading DB');
our $db = Lacuna->db;

out('Getting Seized Stars');
my %seized_stars = map { $_->id => 1 } $db->resultset('Map::Star')->search({
                    station_id => {'!=' => undef},
                    });

my $laws = $db->resultset('Lacuna::DB::Result::Laws')->search({
                             type => 'Jurisdiction',
                         });

while ( my $law = $laws->next) {
    my $station = $db->resultset('Map::Body')->find($law->station_id);
    if ($station) {
        if ($station->in_range_of_influence($law->star)) {
            my $star = $law->star;
            if ($seized_stars{$law->star_id} == 1) {
                my $name = 'Seize '.$star->name;
                my $desc = 'Seize control of {Starmap '.$star->x.' '.$star->y.' '.$star->name.'} by {Planet '.$station->id.' '.
                        $station->name.'}, and apply all present laws to said star and its inhabitants.',
                $seized_stars{$law->star_id} = 2;
                if ($law->name ne $name or $law->description ne $desc) {
                    out($name." - ".$desc.".");
                    $seized_stars{$law->star_id} = 3;
                    $law->name($name);
                    $law->description($desc);
                    $law->update;
                }
            }
            else {
                out("Law #".$law->id." is a duplicate from ".$law->station_id.".");
                $law->delete;
            }
        }
        else {
            out("Law #".$law->id." of ".$law->station_id." is for out of range star".$law->star_id.".");
            $seized_stars{$law->star_id} = -1;
            $law->delete;
        }
    }
    else {
        out("Law #".$law->id." is attached to non-station ".$law->station_id.".");
        $seized_stars{$law->star_id} = -2;
        $law->delete;
    }
}

for my $star_id (sort keys %seized_stars) {
    if ($seized_stars{$star_id} == -2) {
        out($star_id." was seized by a bogus law.");
    }
    elsif ($seized_stars{$star_id} == -1) {
        out($star_id." was out of range.");
    }
    elsif ($seized_stars{$star_id} == 1) {
        out($star_id." needs a law to be inserted.");
        my $star = $db->resultset('Map::Star')->find($star_id);
        my $station_id = $star->station_id;
        my $station = $db->resultset('Map::Body')->find($station_id);
        my $law = Lacuna->db->resultset('Lacuna::DB::Result::Laws')->new({
            name        => 'Seize '.$star->name,
            description => 'Seize control of {Starmap '.$star->x.' '.$star->y.' '.$star->name.'} by {Planet '.$station->id.' '.
                          $station->name.'}, and apply all present laws to said star and its inhabitants.',
            type        => 'Jurisdiction',
            station_id  => $station->id,
            star_id     => $star->id,
        });
        $law->star($star);
        $law->insert;
    }
    elsif ($seized_stars{$star_id} == 2) {
        out($star_id." was in no need of change.");
    }
    elsif ($seized_stars{$star_id} == 3) {
        out($star_id." needed the name and desc to be updated.");
    }
}

###############
## SUBROUTINES
###############

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}
