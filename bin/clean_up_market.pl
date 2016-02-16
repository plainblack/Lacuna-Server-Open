use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;
my $date_ended = DateTime->now->subtract( hours => 168);

out('Loading DB');
our $db = Lacuna->db;

out('Deleting Outdated Market Items');
my $market = $db->resultset('Lacuna::DB::Result::Market');
my @to_be_deleted = $market->search({ date_offered => { '<' => $date_ended }})->get_column('id')->all;
foreach my $id (@to_be_deleted) {
    out('Withdrawing '.$id);
    my $trade = $market->find($id);
    next unless defined $trade;
    $trade->body->empire->send_predefined_message(
        filename    => 'trade_withdrawn.txt',
        params      => [join("\n",@{$trade->format_description_of_payload}), $trade->ask.' essentia'],  
        tags        => ['Trade','Alert'],
    );
    $trade->withdraw;
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


