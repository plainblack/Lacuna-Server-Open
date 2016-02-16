use 5.010;
use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
our $all;
GetOptions(
    'quiet' => \$quiet,
    'all'   => \$all,
);


out('Started');
my $start = time;

out('Loading DB');
our $db = Lacuna->db;
my $empires = $db->resultset('Empire');

my $lec = $empires->find(1);

if (not $all) {
    $empires = $empires->search({ is_admin => 1 });
}

$empires = $empires->search({ id => {'>' => 1}});

my $message = q{
Greetings, I am Cupid! ♥ ♥ ♥

I was invited here to The Lacuna Expase by The Lacuna Council.  Since this is the month of Love in the expanse, TLE has asked me to distribute 10 Game Essentia to every player!

Make sure you enter the TLE Love Fest Contest and the TLE For The Love of the Game Contest in your Contest Forum.  Spread the love all month long!

♥  Cupid  ♥
};

out('Sending Messages');
while (my $empire = $empires->next) {
    my $home = $empire->home_planet;
    next unless defined $home;
    out('Sending message to '.$empire->name);
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Cupid has Arrived',
        from        => $lec,
        body        => $message,
    );

    $empire->add_essentia({
        amount => 10,
        type   => 'game',
        reason => 'Cupid Gift',
    });
    $empire->update;
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


