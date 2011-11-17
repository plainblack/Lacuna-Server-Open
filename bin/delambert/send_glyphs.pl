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

out('Loading AI');
my $ai = Lacuna::AI::DeLambert->new;

my $de_lambert = $ai->empire;

out("Empire name is ".$de_lambert->name);

# Process all received emails

my $messages = $de_lambert->received_messages->search({},
    {
        order_by => 'date_sent',
    }
);
for my $message ($messages->next) {
    out("Subject: ".$message->subject);
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


