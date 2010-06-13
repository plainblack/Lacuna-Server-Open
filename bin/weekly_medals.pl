use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date to_seconds);
use Getopt::Long;
$|=1;

our $quiet;

GetOptions(
    'quiet'         => \$quiet,  
);

out('Started');
my $start = DateTime->now;

out('Loading DB');
our $db = Lacuna->db;

spies();
colonies();
empires();

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############


sub colonies {
    my $colonies = $db->resultset('Lacuna::DB::Result::Log::Colony');
    
    # fastest growing
    my $colony = $colonies->search(undef, {order_by => { -desc => 'population_delta'}, rows => 1})->single;
    get_empire($colony->empire_id)->add_medal('fastest_growing_colony');

    # largest
    $colony = $colonies->search(undef, {order_by => { -desc => 'population'}, rows => 1})->single;
    get_empire($colony->empire_id)->add_medal('largest_colony');

    # reset deltas
    $colonies->update({
        population_delta   => 0,
    });
}

sub empires {
    my $empires = $db->resultset('Lacuna::DB::Result::Log::Empire');
    
    # best attacker in the game 
    my $empire = $empires->search(undef, {order_by => { -desc => 'offense_success_rate'}, rows => 1})->single;
    get_empire($empire->empire_id)->add_medal('best_attacker_in_the_game');
    
    # best attacker of the week 
    $empire = $empires->search(undef, {order_by => { -desc => 'offense_success_rate_delta'}, rows => 1})->single;
    get_empire($empire->empire_id)->add_medal('best_attacker_of_the_week');

    # best defender in the game 
    $empire = $empires->search(undef, {order_by => { -desc => 'defense_success_rate'}, rows => 1})->single;
    get_empire($empire->empire_id)->add_medal('best_defender_in_the_game');
    
    # best defender of the week 
    $empire = $empires->search(undef, {order_by => { -desc => 'defense_success_rate_delta'}, rows => 1})->single;
    get_empire($empire->empire_id)->add_medal('best_defender_of_the_week');

    # dirtiest player in the game 
    $empire = $empires->search(undef, {order_by => { -desc => 'dirtiest'}, rows => 1})->single;
    get_empire($empire->empire_id)->add_medal('dirtiest_empire_in_the_game');
    
    # dirtiest player of the week 
    $empire = $empires->search(undef, {order_by => { -desc => 'dirtiest_delta'}, rows => 1})->single;
    get_empire($empire->empire_id)->add_medal('dirtiest_empire_of_the_week');

    # fastest growing empire
    $empire = $empires->search(undef, {order_by => { -desc => 'empire_size_delta'}, rows => 1})->single;
    get_empire($empire->empire_id)->add_medal('fastest_growing_empire');

    # largest empire
    $empire = $empires->search(undef, {order_by => { -desc => 'empire_size'}, rows => 1})->single;
    get_empire($empire->empire_id)->add_medal('largest_empire');

    # reset deltas
    $empires->update({
        empire_size_delta   => 0,
    });
}

sub spies {
    my $spies = $db->resultset('Lacuna::DB::Result::Log::Spies');
    
    # best in the game
    my $spy = $spies->search(undef,{order_by => { -desc => 'success_rate'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('best_spy_in_the_game');
    
    # best of the week
    $spy = $spies->search(undef,{order_by => { -desc => 'success_rate_delta'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('best_spy_of_the_week');

    # best offender in the game
    $spy = $spies->search(undef,{order_by => { -desc => 'offense_success_rate'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('best_offensive_spy_in_the_game');
    
    # best offender of the week
    $spy = $spies->search(undef,{order_by => { -desc => 'offense_success_rate_delta'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('best_offensive_spy_of_the_week');

    # best defender in the game
    $spy = $spies->search(undef,{order_by => { -desc => 'defense_success_rate'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('best_defensive_spy_in_the_game');
    
    # best defender of the week
    $spy = $spies->search(undef,{order_by => { -desc => 'defense_success_rate_delta'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('best_defensive_spy_of_the_week');

    # dirtiest in the game
    $spy = $spies->search(undef,{order_by => { -desc => 'dirtiest'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('dirtiest_spy_in_the_game');

    # dirtiest of the week
    $spy = $spies->search(undef,{order_by => { -desc => 'dirtiest_delta'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('dirtiest_spy_of_the_week');

    # most improved of the week
    $spy = $spies->search(undef,{order_by => { -desc => 'level_delta'}, rows=>1})->single;
    get_empire($spy->empire_id)->add_medal('most_improved_spy_of_the_week');

    # reset deltas 
    $spies->update({
        offense_success_rate_delta  => 0,
        defense_success_rate_delta  => 0,
        dirtiest_delta              => 0,
        level_delta                 => 0,
    });
}


# UTILITIES

sub get_empire {
    my $id = shift;
    return $db->resultset('Lacuna::DB::Result::Empire')->find($id);
}

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


