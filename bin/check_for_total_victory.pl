use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use List::Util qw(max);
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

my $stars_over = $cache->get('20Stars');
out('stars_over: ' . $stars_over);
if ($stars_ver ne 'Tournament Over') {
	my $search = { class => 'Lacuna::DB::Result::Map::Body::Planet::Station' };
	$search->{zone} = '-2|-2' if $server_url =~ /us1/;

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
	    if ($server_url =~ /us2/) {
            $cache->set('server','status','Game Over', 60 * 60 * 24 * 30);
	    }
	    elsif ($server_url =~ /us1/) {
            $cache->set('20Stars','Tournament Over', 60 * 60 * 24 * 30);
            out('victory empire id: ' . $victory_empire);
            my $empire = $empires->find($victory_empire);
            out('victory empire name: ' . $empire->name);
            my $alliance = Lacuna->db->resultset('Lacuna::DB::Result::Alliance')->find($empire->alliance_id);
            if (defined $alliance) {
                while (my $empire = $alliance->members->next) {
                    out('Giving medals to ' . $empire->name);
                    $empire->add_medal('20Stars');
                    $empire->add_medal('TournamentVictory');
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
	    else {
            out('Not configured to run on ' . $server_url);
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
    out('The tournament is already over');
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



