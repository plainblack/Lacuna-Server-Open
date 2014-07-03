use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Lacuna::AI::DeLambert;
use Getopt::Long;
use List::MoreUtils qw(uniq);

use utf8;
$|=1;
our $quiet;
our $to_all;
our $to_alliance;
our $to_empire;
our $filename;
our $empire_name;
our @params;
our $dry_run;
GetOptions(
    'quiet'          => \$quiet,  
    'all'            => \$to_all,
    'alliance=s'     => \$to_alliance,
    'empire=s'       => \$to_empire,
    'filename=s'     => \$filename,
    'from=s'         => \$empire_name,
    'param=s'        => \@params,
    'dry_run'        => \$dry_run,
);

out('Started');
my $start = time;

die "ERROR: Must specify a filename" if not $filename;
die "ERROR: You must specify an empire to email from" if not $empire_name;

my ($from_empire) = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
    name => $empire_name,
});
die "ERROR: Cannot find empire '$empire_name'" if not $from_empire;

out('Loading DB');
our $db = Lacuna->db;
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search;

while (my $empire = $empires->next) {
    my $send_email = 0;
    if ($to_all) {
        $send_email = 1;
    }
    if ($empire->name eq 'icd' or $empire->name eq 'icydee' or $empire->name eq 'Sweden' or $empire->name eq 'Norway') {
        $send_email = 1;
    }
    if ($to_empire and $to_empire eq $empire->name) {
        $send_email = 1;
    }
    if ($to_alliance and $empire->alliance and $empire->alliance->name eq $to_alliance) {
        $send_email = 1;
    }
    if ($send_email) {
        out("Email to ".$empire->name);
        $empire->send_predefined_message(
            tags        => ['Correspondence'],
            filename    => $filename,
            params      => \@params,
        );
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


