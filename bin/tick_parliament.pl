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

out('Ticking parliament');
my $propositions_rs = $db->resultset('Lacuna::DB::Result::Propositions');
my $dtf = $db->storage->datetime_parser;
my @propositions = $propositions_rs->search({ status => 'Pending', date_ends => { '<' => $dtf->format_datetime(DateTime->now)} })->get_column('id')->all;
foreach my $id (@propositions) {
    my $proposition = $propositions_rs->find($id);
    out('Ticking '.$proposition->name);
    $proposition->check_status;
}
@propositions = $propositions_rs->search({ status => 'Passed' })->get_column('id')->all;
foreach my $id (@propositions) {
    my $proposition = $propositions_rs->find($id);
    if ($proposition->name eq 'Abandon Station') {
        out($proposition->description);
        $proposition->station->sanitize;
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


