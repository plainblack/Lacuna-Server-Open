use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use List::Util qw(max shuffle);
use UUID::Tiny ':std';
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,
);

out('Started');
my $start = time;

my $config = Lacuna->config;
my $server_url = $config->get('server_url');

out('Loading Empires');
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');
my $cache = Lacuna->cache;
my $lec = Lacuna::DB::Result::Empire->lacuna_expanse_corp;

# it'll only run on servers that have the configuration
my $tourney20stars = $config->get('tournament/20Stars');
if ($tourney20stars) {
    my $zone = $tourney20stars->{zone};
    my $stars_over = $cache->get('tournament', '20Stars');
    out('stars_over: ' . $stars_over);
    if ($stars_over ne 'Tournament Over') {
        my $search = { class => 'Lacuna::DB::Result::Map::Body::Planet::Station' };
        $search->{zone} = $zone if $server_url =~ /us1/;

        out('Checking space stations.');
        my %victory_empire;
        my $victory_empire;
        my $stations = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search($search);
        my $message = '';
        while (my $station = $stations->next) {
            my $stars = $station->influence_spent;
            $message .= sprintf("The station {Starmap %s %s %s}, owned by {Empire %s %s}, controls %d stars.\n", 
            $station->x, $station->y, $station->name, $station->empire_id, $station->empire->name, $stars);
            if ( $stars >= 20 ) {
                $victory_empire{$station->empire_id} = $stars;
                $victory_empire = $station->empire_id;
            }
        }

        if (scalar keys %victory_empire) {
            # us2 doesn't use the zone information
            if ($server_url =~ /us2/) {
                $cache->set('server','status','Game Over', 60 * 60 * 24 * 30);
            }
            else {
                $cache->set('tournament', '20Stars','Tournament Over', 60 * 60 * 24 * 30);
                out('victory empire id: ' . $victory_empire);
                my $empire = $empires->find($victory_empire);
                out('victory empire name: ' . $empire->name);
                my $alliance = Lacuna->db->resultset('Lacuna::DB::Result::Alliance')->find($empire->alliance_id);
                if (defined $alliance) {
                    out('victory alliance: ' . $alliance->name);
                    my @allies = $alliance->members->get_column('id')->all;
                    for my $id ( @allies ) {
                        my $allie = $empires->find($id);
                        out('Giving medals to ' . $allie->name);
                        $allie->add_medal('20Stars');
                        $allie->add_medal('TournamentVictory');
                    }
                    out('setting announcement');
                    set_announcement("The '" . $alliance->name . "' alliance has won the Twenty Stars tournament!")
                } 
                else {
                    out('Giving medals to ' . $victory_empire->name);
                    $victory_empire->add_medal('20Stars');
                    $victory_empire->add_medal('TournamentVictory');
                    out('setting announcement');
                    set_announcement("The '" . $victory_empire->name . "' empire has won the Twenty Stars tournament single-handedly!")
                }
            }

            out('The tournament is over; time to pick a new zone');
            my $map_size = $config->get('map_size');

            # x and y coords
            my @x = @{ $map_size->{x} };
            my @y = @{ $map_size->{y} };

            # convert x and y coords to zones
            @x = ( zone_coord($x[0]), zone_coord($x[1]) );
            @y = ( zone_coord($y[0]), zone_coord($y[1]) );

            # get old_zones and skip_zones
            my $old_zones = $tourney20stars->{'old_zones'};
            my $old_zone = $tourney20stars->{'zone'};
            out("Adding $old_zone to old_zones");
            push @{ $old_zones }, $zone;
            my $skip_zones = $tourney20stars->{'skip_zones'};

            # create a list of possible zones for the next tournament
            my @zones;
            for my $x ( $x[0] .. $x[1] ) {
                for my $y ( $y[0] .. $y[1] ) {
                    my $zone = join '|', $x, $y;
                    if ( $zone ~~ $old_zones || $zone ~~ $skip_zones ) {
                        out("Skipping $zone");
                        next;
                    }
                    push @zones, $zone;
                }
            }
            if ( @zones ) {
                @zones = shuffle @zones;
                $zone = unshift @zones;
                out("Picked $zone");
                $tourney20stars->{'zone'} = $zone;

                # clear out the tournament end condition
                $cache->delete('tournament', '20Stars');

                # and announce the start of the next tournament
                out('setting announcement');
                set_announcement("A new 20 Stars tournament has started in zone $zone.")
            }
            else {
                out('*** No zones left for a 20 Stars tournament! ***');
            }
        }
        elsif (DateTime->now->hour == 3 ) {
            while (my $empire = $empires->next) {
                if ( $message ) {
                    $empire->send_message(
                    tags        => ['Alert'],
                    from        => $lec,
                    body        => $message,
                    subject     => 'Situation Update',
                    );
                }
            }
        }
    }
    else {
        # It shouldn't be possible to get here on us2 due to game over condition.
        # It should only be possible to get here on us1 when we have run out of zones for a 20 Stars tournament.
        out('The 20 Stars tournaments have all ended.');
    }
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");

###############
## SUBROUTINES
###############

sub zone_coord {
    my $coord = shift;
    return int($coord / 250);
}

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

sub set_announcement {
    my $message = shift;
    my $cache = Lacuna->cache;
    my $announcement = $cache->get('announcement','message');
    $announcement .= '<br>' . $message;
    $cache->set('announcement','alert', create_uuid_as_string(UUID_V4), 60*60*24);
    $cache->set('announcement','message', $announcement, 60*60*24);
}



