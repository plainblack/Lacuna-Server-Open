use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
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

check_sz();


my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############


sub check_sz {
    my $sz_param = Lacuna->config->get('starter_zone');
    unless ($sz_param and $sz_param->{max_colonies}) {
        out("No starter zone configured.");
        return;
    }

    my $empires = $db->resultset('Empire')->search({ id => { '>' => 1 }});

    my $cache = Lacuna->cache;
    while (my $empire = $empires->next)
    {
        my $bodies = $empire->planets;
        my @starter_bodies;
        while (my $body = $bodies->next) {
            push @starter_bodies, $body->id if ($body->in_starter_zone);
        }
        if (scalar @starter_bodies > $sz_param->{max_colonies}) {
            $empire->send_predefined_message(
                tags      => ['Alert'],
                filename  => 'zoning_board_warning.txt',
                params    => [ $sz_param->{max_colonies} ],
            );
            out(sprintf("%s:%d has more than %d colonies in the starter zones.",
                        $empire->name, $empire->id, $sz_param->{max_colonies}));
            
            for my $bid (@starter_bodies) {
              $cache->set('sz_exceeded', $bid, 1, 60*60*24);
            }
        }
    }
}

# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


