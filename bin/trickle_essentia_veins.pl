use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
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

trickle();


my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############


sub trickle {
    my $veins = $db->resultset('Lacuna::DB::Result::Building')->search({class => 'Lacuna::DB::Result::Building::Permanent::EssentiaVein'});
    while (my $vein = $veins->next) {
        my $body = $vein->body;
        if ($body->empire_id) {
            my $empire = $body->empire;
            if (defined $empire) {
                out($empire->name);
                $empire->add_essentia({
                    amount  => 4, 
                    reason  => 'Essentia Vein',
                });
                $empire->update;
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


