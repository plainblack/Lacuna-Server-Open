use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
use utf8;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;

out('Ticking planets');
my $planets_rs = $db->resultset('Lacuna::DB::Result::Map::Body')->search({empire_id => {'!=' => 0}});
while (my $planet = $planets_rs->next) {
    out('Ticking '.$planet->name.' : '.$planet->id);
    eval{$planet->tick};
    my $reason = $@;
    if (ref $reason eq 'ARRAY' && $reason->[0] eq -1) {
        # this is an expected exception, it means one of the roles took over
    }
    elsif ( ref $reason eq 'ARRAY') {
        out('Ticking '.$planet->name);
        out(sprintf("Ticking %s resulted in errno: %d, %s\n", $planet->name, $reason->[0], $reason->[1]));
    }
    elsif ( $reason ) {
        out(sprintf("Ticking %s resulted in: %s\n", $planet->name, $reason));
    }
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


