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

# SELECT me.id, me.empire_id, me.star_id, me.body_id, me.alliance_id FROM probes me JOIN body body ON body.id = me.body_id WHERE ( ( body.empire_id != me.empire_id AND body.id = me.body_id ) ) ORDER BY body.id; 
my $bad = $db->resultset('Lacuna::DB::Result::Probes')->search(
    {
        'me.body_id' => { '=' => 'body.id' },
        'me.empire_id' => { '!=' => 'body.empire_id' },
    },
    {
        join => [ qw/body/ ],
        order_by => [ qw/body.id/ ],
    }
);

while (my $probe = $bad->next) {
    print join( ', ', $probe->id, $probe->empire_id, $probe->star_id,  $probe->body_id ), "\n";
}

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


