use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
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

out('Loading AI');
my $ai = Lacuna::AI::Trelvestian->new;

out('Loading Empires');
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');
my $cache = Lacuna->cache;
my $lec = Lacuna::DB::Result::Empire->lacuna_expanse_corp;

if ($cache->get('tournament', 'FourTrel') ne 'Tournament Over') {
	out('Checking victory planets.');
	my %victory_points;
	my $victory_empire;
	my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body');
	foreach my $id (@{Lacuna->config->get('win/alliance_control')}) {
	    my $planet = $bodies->find($id);
	    if ($planet->empire_id eq '' || $planet->empire_id > 1) {
            if ($cache->get('victory_planet'.$id) ne $planet->empire_id) {
                my $controlled = '{Starmap '.$planet->x.' '.$planet->y.' '.$planet->name.'}';
                my $controller = $planet->empire_id ? '{Empire '.$planet->empire_id.' '.$planet->empire->name.'}' : 'No one';
                while (my $empire = $empires->next) {
                    $empire->send_message(
                        tags        => ['Alert'],
                        from        => $lec,
                        body        => $controller.q{ now controls the Trelvestian planet named }.$controlled.q{.},
                        subject     => 'Control Changed Hands',
                    );
                }
            }
            if ($planet->empire_id) {
                $victory_points{$planet->empire_id}++;
                $victory_empire = $planet->empire;
            }
	    }
	    $cache->set('victory_planet'.$id, $planet->empire_id, 60 * 60 * 24 * 7);
	}

	if (defined $victory_empire) {
	    if ($victory_points{$victory_empire->id} >= 4) {
            if ($server_url =~ /us2/) {
                $cache->set('server','status','Game Over', 60 * 60 * 24 * 30);
            }
            elsif ($server_url =~ /us1/) {
                $cache->set('tournament', 'FourTrel','Tournament Over', 60 * 60 * 24 * 30);
                out('victory empire: ' . $victory_empire->name);
                my $alliance = Lacuna->db->resultset('Lacuna::DB::Result::Alliance')->find($victory_empire->alliance_id);
                if (defined $alliance) {
                    out('victory alliance: ' . $alliance->name);
                    my @allies = $alliance->members->get_column('id')->all;
                    for my $id ( @allies ) {
                        my $allie = $empires->find($id);
                        out('Giving medals to ' . $allie->name);
                        $allie->add_medal('TrelDefeated');
                        $allie->add_medal('TournamentVictory');
                    }
                    out('setting announcement');
                    set_announcement("The '" . $alliance->name . "' alliance has won the Four Trel Colonies tournament!")
                } 
                else {
                    out('Giving medals to ' . $victory_empire->name);
                    $victory_empire->add_medal('TrelDefeated');
                    $victory_empire->add_medal('TournamentVictory');
                    out('setting announcement');
                    set_announcement("The '" . $victory_empire->name . "' empire has won the Four Trel Colonies tournament single-handedly!")
                }
            }
            else {
                out('Not configured to run on ' . $server_url);
            }
	    }
	}
}
else {
    out('Tournament is already over');
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

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


