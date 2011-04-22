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

# select p.id, p.empire_id, p.star_id, p.body_id, p.alliance_id, b.empire_id from probes as p, body as b where p.body_id = b.id and p.empire_id != ( select b.empire_id from body as b where b.id = p.body_id );

my $bad = $db->resultset('Lacuna::DB::Result::Probes')->search(
    {
        'body.id' => { '=' => 'probe.body_id' },
        'body.empire_id' => { '!=' => 'probe.empire_id' },
    },
    {
        join => [ qw/body/ ],
        order_by => [ qw/body.id body.empire_id/ ],
    }
);

while (my $probe = $bad->next) {
    print $probe->id, ' ', $probe->empire_id, ' ', $probe->star_id, ' ', $probe->body_id, "\n";
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


