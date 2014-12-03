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
my $winners = $db->resultset('Lacuna::DB::Result::Log::WeeklyMedalWinner');

$winners->delete;

spies();
colonies();
empires();

my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############


sub colonies {
    my $colonies = $db->resultset('Lacuna::DB::Result::Log::Colony');
    
    # fastest growing
    my $colony = $colonies->search(undef, {order_by => [{ -desc => 'population_delta'},'rand()']})->first;
    add_medal($colony->empire_id,'fastest_growing_colony');

    # largest
    $colony = $colonies->search(undef, {order_by => [{ -desc => 'population'},'rand()']})->first;
    add_medal($colony->empire_id,'largest_colony');

    # reset deltas
    $colonies->update({
        population_delta   => 0,
    });
}

sub empires {
    my $empires = $db->resultset('Lacuna::DB::Result::Log::Empire');
    
    # best attacker in the game 
    my $empire_log = $empires->search(undef, {order_by => [{ -desc => 'offense_success_rate'},'rand()']})->first;
    add_medal($empire_log->empire_id,'best_attacker_in_the_game');
    
    # best attacker of the week 
    $empire_log = $empires->search(undef, {order_by => [{ -desc => 'offense_success_rate_delta'},'rand()']})->first;
    add_medal($empire_log->empire_id, 'best_attacker_of_the_week');

    # best defender in the game 
    $empire_log = $empires->search(undef, {order_by => [{ -desc => 'defense_success_rate'},'rand()']})->first;
    add_medal($empire_log->empire_id, 'best_defender_in_the_game');
    
    # best defender of the week 
    $empire_log = $empires->search(undef, {order_by => [{ -desc => 'defense_success_rate_delta'},'rand()']})->first;
    add_medal($empire_log->empire_id,'best_defender_of_the_week');

    # dirtiest player in the game 
    $empire_log = $empires->search(undef, {order_by => [{ -desc => 'dirtiest'},'rand()']})->first;
    add_medal($empire_log->empire_id,'dirtiest_empire_in_the_game');
    
    # dirtiest player of the week 
    $empire_log = $empires->search(undef, {order_by => [{ -desc => 'dirtiest_delta'},'rand()']})->first;
    add_medal($empire_log->empire_id,'dirtiest_empire_of_the_week');

    # fastest growing empire
    $empire_log = $empires->search(undef, {order_by => [{ -desc => 'empire_size_delta'},'rand()']})->first;
    add_medal($empire_log->empire_id,'fastest_growing_empire');

    # largest empire
    $empire_log = $empires->search(undef, {order_by => [{ -desc => 'empire_size'},'rand()']})->first;
    add_medal($empire_log->empire_id,'largest_empire');

    # reset deltas
    $empires->update({
        empire_size_delta   => 0,
    });
}

sub spies {
    my $spies = $db->resultset('Lacuna::DB::Result::Log::Spies');
    
    # best in the game
    my $spy = $spies->search(undef,{order_by => [{ -desc => 'success_rate'}, 'rand()']})->first;
    add_medal($spy->empire_id,'best_spy_in_the_game');
    
    # best of the week
    $spy = $spies->search(undef,{order_by => [{ -desc => 'success_rate_delta'},'rand()']})->first;
    add_medal($spy->empire_id,'best_spy_of_the_week');

    # best offender in the game
    $spy = $spies->search(undef,{order_by => [{ -desc => 'offense_success_rate'},'rand()']})->first;
    add_medal($spy->empire_id,'best_offensive_spy_in_the_game');
    
    # best offender of the week
    $spy = $spies->search(undef,{order_by => [{ -desc => 'offense_success_rate_delta'},'rand()']})->first;
    add_medal($spy->empire_id,'best_offensive_spy_of_the_week');

    # best defender in the game
    $spy = $spies->search(undef,{order_by => [{ -desc => 'defense_success_rate'},'rand()']})->first;
    add_medal($spy->empire_id,'best_defensive_spy_in_the_game');
    
    # best defender of the week
    $spy = $spies->search(undef,{order_by => [{ -desc => 'defense_success_rate_delta'},'rand()']})->first;
    add_medal($spy->empire_id,'best_defensive_spy_of_the_week');

    # dirtiest in the game
    $spy = $spies->search(undef,{order_by => [{ -desc => 'dirtiest'},'rand()']})->first;
    add_medal($spy->empire_id,'dirtiest_spy_in_the_game');

    # dirtiest of the week
    $spy = $spies->search(undef,{order_by => [{ -desc => 'dirtiest_delta'},'rand()']})->first;
    add_medal($spy->empire_id,'dirtiest_spy_of_the_week');

    # most improved of the week
    $spy = $spies->search(undef,{order_by => [{ -desc => 'level_delta'},'rand()']})->first;
    add_medal($spy->empire_id,'most_improved_spy_of_the_week');

    # reset deltas 
    $spies->update({
        offense_success_rate_delta  => 0,
        defense_success_rate_delta  => 0,
        dirtiest_delta              => 0,
        level_delta                 => 0,
    });
}

# UTILITIES

sub add_medal {
    my ($empire_id, $medal_name) = @_;
    printf "%s -> %s\n", $empire_id, $medal_name;
    my $empire = $db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    return 0 unless $empire;
    my $medal = $empire->add_medal($medal_name, 1);
    $winners->new({
        empire_id   => $empire->id,
        empire_name => $empire->name,
        medal_id    => $medal->id,
        times_earned=> $medal->times_earned,
        medal_name  => $medal->name,
        medal_image => $medal->image,
    })->insert;
}

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


