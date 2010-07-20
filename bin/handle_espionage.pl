use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date to_seconds);
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


my %skills = (
    'Gather Resource Intelligence'  => 'intel_xp',
    'Gather Empire Intelligence'    => 'intel_xp',
    'Gather Operative Intelligence' => 'intel_xp',
    'Hack Network 19'               => 'politics_xp',
    'Appropriate Technology'        => 'theft_xp',
    'Sabotage Probes'               => 'mayhem_xp',
    'Rescue Comrades'               => 'intel_xp',
    'Sabotage Resources'            => 'mayhem_xp',
    'Appropriate Resources'         => 'theft_xp',
    'Assassinate Operatives'        => 'mayhem_xp',
    'Sabotage Infrastructure'       => 'mayhem_xp',
    'Incite Mutiny'                 => 'politics_xp',
    'Incite Rebellion'              => 'politics_xp',    
);

my @offense_tasks = keys %skills;

my %outcomes = (
    'Gather Resource Intelligence'  => 'gather_resource_intel',
    'Gather Empire Intelligence'    => 'gather_empire_intel',
    'Gather Operative Intelligence' => 'gather_operative_intel',
    'Hack Network 19'               => 'hack_network_19',
    'Appropriate Technology'        => 'appropriate_tech',
    'Sabotage Probes'               => 'sabotage_probes',
    'Rescue Comrades'               => 'rescue_comrades',
    'Sabotage Resources'            => 'sabotage_resources',
    'Appropriate Resources'         => 'appropriate_resources',
    'Assassinate Operatives'        => 'assassinate_operatives',
    'Sabotage Infrastructure'       => 'sabotage_infrastructure',
    'Incite Mutiny'                 => 'incite_mutany',
    'Incite Rebellion'              => 'incite_rebellion',    
);


out('Processing planets');
my $planets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({ empire_id   => {'>' => 0} });
while (my $planet = $planets->next) {
    out('Ticking '.$planet->name);
    $planet->tick;
    my $espionage = determine_espionage($planet);
    unless ($espionage->{has_spies}) {
       out('No Spies On Planet');
       next;
    }
    
    # handle spy vs spy
    my $spy = pop @{$espionage->{offense}};
    unless (defined $spy) {
	out('No Attackers');
	next;
    }
    my $spy_task = $spy->task;
    my $skill_method = $skills{$spy_task}; # determined by attacker
    my $offense_rating = $spy->offense + $spy->$skill_method;
    my $cop = pop @{$espionage->{defense}};
    my $defense_rating = $cop->defense + $cop->$skill_method if defined $cop;

    for (1..5) {
        my $vs = (defined $spy) ? $spy->name : 'NOBODY';
        $vs .= ' vs ';
        $vs .= (defined $cop) ? $cop->name : 'NOBODY';
        out($vs);
        out("Spy Task: ". $spy_task);
        if (defined $spy && $offense_rating > $defense_rating) { # offense wins
            # adjust stats
            $offense_rating -= $defense_rating;
            $spy->$skill_method( $spy->$skill_method + 3 );
            
            # handle outcome
            $spy->offense_mission_successes( $spy->offense_mission_successes + 1 );
            my $outcome = main->can($outcomes{$spy_task});
            $outcome->($planet, $espionage, $spy, $cop);
            if ($spy->task ~~ ['Travelling', 'Unconscious']) {
                $spy->update;
                $spy = pop @{$espionage->{offense}};
                if (defined $spy) {
                    $spy_task = $spy->task;
                    $skill_method = $skills{$spy_task};
                    $offense_rating = $spy->offense + $spy->$skill_method;
                }
            }
            
            # get a new cop
            if (defined $cop) {
                $cop->update;
                $cop = pop @{$espionage->{defense}};
                if (defined $cop) {
                    $defense_rating = $cop->defense + $cop->$skill_method;
                }
            }
        }
        elsif (defined $cop) { # defense wins
            # adjust stats
            $defense_rating -= $offense_rating;
            $cop->$skill_method( $cop->$skill_method + 3 );
            
            # handle outcome
            $cop->defense_mission_successes( $cop->defense_mission_successes + 1 );
            my $outcome = main->can($outcomes{$spy_task} . '_loss');
            $outcome->($planet, $espionage, $spy, $cop);
            if ($cop->task ~~ ['Travelling', 'Unconscious']) {
                $cop->update;
                $cop = pop @{$espionage->{defense}};
                if (defined $cop) {
                    $defense_rating = $cop->defense + $cop->$skill_method;
                }
            }
            
            # get a new spy
            if (defined $spy) {
                $spy->update;
                $spy = pop @{$espionage->{offense}};
                if (defined $spy) {
                   $spy_task = $spy->task;
                   $skill_method = $skills{$spy_task};
                   $offense_rating = $spy->offense + $spy->$skill_method;
                }
            }
        }
    }
    
    # update left over spies
    $spy->update if defined $spy;
    $cop->update if defined $cop; 
}

out('Clearing Kills');
$db->resultset('Lacuna::DB::Result::Spies')->search({task => 'Killed In Action'})->delete_all;

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

# MISSIONS

sub gather_resource_intel {
    given (randint(1,4)) {
        when (1) { ship_report(@_) }
        when (2) { travel_report(@_) }
        when (3) { economic_report(@_) }
        when (4) { knock_cop_unconscious(@_) }
    }
}


sub gather_resource_intel_loss {
    given (randint(1,2)) {
        when (1) { thwart_intelligence(@_) }
        when (2) { knock_spy_unconscious(@_) }
    }
}


sub gather_empire_intel {
    given (randint(1,4)) {
        when (1) { build_queue_report(@_) }
        when (2) { surface_report(@_) }
        when (3) { colony_report(@_) }
        when (4) { knock_cop_unconscious(@_) }
    }
}


sub gather_empire_intel_loss {
    given (randint(1,2)) {
        when (1) { thwart_intelligence(@_) }
        when (2) { knock_spy_unconscious(@_) }
    }
}


sub gather_operative_intel {
    given (randint(1,3)) {
        when (1) { false_interrogation_report(@_) }
        when (2) { spy_report(@_) }
        when (3) { knock_cop_unconscious(@_) }
    }
}


sub gather_operative_intel_loss {
    given (randint(1,4)) {
        when (1) { counter_intel_report(@_) }
        when (2) { interrogation_report(@_) }
        when (3) { thwart_intelligence(@_) }
        when (4) { knock_spy_unconscious(@_) }
    }
}


sub hack_network_19 {
    given (randint(1,6)) {
        when (1) { network19_defamation1(@_) }
        when (2) { network19_defamation2(@_) }
        when (3) { network19_defamation3(@_) }
        when (4) { network19_defamation4(@_) }
        when (5) { network19_defamation5(@_) }
        when (6) { knock_cop_unconscious(@_) }
    }
}


sub hack_network_19_loss {
    given (randint(1,10)) {
        when (1) { capture_hacker(@_) }
        when (2) { network19_propaganda1(@_) }
        when (3) { network19_propaganda2(@_) }
        when (4) { network19_propaganda3(@_) }
        when (5) { network19_propaganda4(@_) }
        when (6) { network19_propaganda5(@_) }
        when (7) { network19_propaganda6(@_) }
        when (8) { network19_propaganda7(@_) }
        when (9) { thwart_hacker(@_) }
        when (10) { knock_spy_unconscious(@_) }
    }
}


sub appropriate_tech {
    given (randint(1,2)) {
        when (1) { steal_building(@_) }
        when (2) { knock_cop_unconscious(@_) }
    }
}


sub appropriate_tech_loss {
    given (randint(1,3)) {
        when (1) { capture_thief(@_) }
        when (2) { thwart_thief(@_) }
        when (3) { knock_spy_unconscious(@_) }
    }
}


sub sabotage_probes {
    given (randint(1,3)) {
        when (1) { hack_local_probes(@_) }
        when (2) { hack_observatory_probes(@_) }
        when (3) { knock_cop_unconscious(@_) }
    }
}


sub sabotage_probes_loss {
    given (randint(1,3)) {
        when (1) { hack_offending_probes(@_) }
        when (2) { kill_hacker(@_) }
        when (3) { knock_spy_unconscious(@_) }
    }
}


sub rescue_comrades {
    given (randint(1,3)) {
        when (1) { escape_prison(@_) }
        when (2) { kill_guard_and_escape_prison(@_) }
        when (3) { knock_cop_unconscious(@_) }
    }
}


sub rescue_comrades_loss {
    given (randint(1,4)) {
        when (1) { kill_suspect(@_) }
        when (2) { capture_rescuer(@_) }
        when (3) { knock_spy_unconscious(@_) }
        when (4) { thwart_intelligence(@_) }
    }
}


sub sabotage_resources {
    given (randint(1,4)) {
        when (1) { destroy_mining_ship(@_) }
        when (2) { destroy_ship(@_) }
        when (3) { kill_contact_with_mining_platform(@_) }
        when (4) { knock_cop_unconscious(@_) }
    }
}


sub sabotage_resources_loss {
    given (randint(1,4)) {
        when (1) { capture_saboteur(@_) }
        when (2) { thwart_saboteur(@_) }
        when (3) { kill_saboteur(@_) }
        when (4) { knock_spy_unconscious(@_) }
    }
}


sub appropriate_resources {
    given (randint(1,4)) {
        when (1) { steal_ships(@_) }
        when (2) { steal_resources(@_) }
        when (3) { take_control_of_probe(@_) }
        when (4) { knock_cop_unconscious(@_) }
    }
}


sub appropriate_resources_loss {
    given (randint(1,3)) {
        when (1) { capture_thief(@_) }
        when (2) { kill_thief(@_) }
        when (3) { knock_spy_unconscious(@_) }
    }
}


sub assassinate_operatives {
    given (randint(1,2)) {
        when (1) { kill_cop(@_) }
        when (2) { knock_cop_unconscious(@_) }
    }
}


sub assassinate_operatives_loss {
    given (randint(1,2)) {
        when (1) { kill_intelligence(@_) }
        when (2) { knock_spy_unconscious(@_) }
    }
}


sub sabotage_infrastructure {
    given (randint(1,4)) {
        when (1) { shut_down_building(@_) }
        when (2) { destroy_upgrade(@_) }
        when (3) { destroy_infrastructure(@_) }
        when (4) { knock_cop_unconscious(@_) }
    }
}


sub sabotage_infrastructure_loss {
    given (randint(1,3)) {
        when (1) { capture_saboteur(@_) }
        when (2) { kill_saboteur(@_) }
        when (3) { knock_spy_unconscious(@_) }
    }
}


sub incite_mutany {
    given (randint(1,3)) {
        when (1) { turn_cop(@_) }
        when (2) { kill_cop(@_) }
        when (3) { knock_cop_unconscious(@_) }
    }
}


sub incite_mutany_loss {
    given (randint(1,3)) {
        when (1) { turn_spy(@_) }
        when (2) { kill_mutaneer(@_) }
        when (3) { knock_spy_unconscious(@_) }
    }
}


sub incite_rebellion {
    given (randint(1,9)) {
        when (1) { civil_unrest(@_) }
        when (2) { protest(@_) }
        when (3) { violent_protest(@_) }
        when (4) { march_on_capitol(@_) }
        when (5) { small_rebellion(@_) }
        when (6) { turn_riot_cop(@_) }
        when (7) { kill_cop(@_) }
        when (8) { uprising(@_) }
        when (9) { knock_cop_unconscious(@_) }
    }
}


sub incite_rebellion_loss {
    given (randint(1,9)) {
        when (1) { day_of_rest(@_) }
        when (2) { festival(@_) }
        when (3) { capture_rebel(@_) }
        when (4) { kill_rebel(@_) }
        when (5) { peace_talks(@_) }
        when (6) { calm_the_rebels(@_) }
        when (7) { thwart_rebel(@_) }
        when (8) { turn_rebel(@_) }
        when (9) { knock_spy_unconscious(@_) }
    }
}



# OUTCOMES

sub uprising {
    my ($planet, $espionage, $spy, $cop) = @_;
    return undef unless defined $spy;
    out('Uprising');
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    my $loss = sprintf('%.0f', $planet->happiness * 0.10 );
    $loss = 10000 unless ($loss > 10000);
    $planet->spend_happiness( $loss )->update;
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_incited_a_rebellion.txt',
        params      => [$planet->empire->name, $planet->name, $loss, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'uprising.txt',
        params      => [$spy->name, $planet->name, $loss],
    );
    $planet->add_news(100,'Led by %s, the citizens of %s are rebelling against %s.', $spy->name, $planet->name, $planet->empire->name);
}

sub knock_cop_unconscious {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop);
    out('Knock Cop Unconscious');
    knock_out($planet, $cop);
}

sub knock_spy_unconscious {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    out('Knock Spy Unconscious');
    knock_out($planet, $spy);
}

sub turn_cop {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Turn Cop');
    turn_a_spy($planet, $cop, $spy);
    $planet->add_news(70,'Military leaders on %s are calling for a no confidence vote about the Governor.', $planet->name);
}

sub turn_riot_cop {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Turn Riot Police');
    turn_a_spy($planet, $cop, $spy);
    $planet->add_news(70,'In a shocking turn of events, police could be seen leaving their posts to join the protesters on %s today.', $planet->name);
}

sub small_rebellion {
    my ($planet, $espionage, $spy, $cop) = @_;
    return undef unless defined $spy;
    out('Small Rebellion');
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $planet->spend_happiness(randint(5000,10000))->update;
    $planet->add_news(100,'Hundreds are dead at this hour after a protest turned into a small, but violent, rebellion on %s.', $planet->name);
}

sub march_on_capitol {
    my ($planet, $espionage, $spy, $cop) = @_;
    return undef unless defined $spy;
    out('March On Capitol');
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $planet->spend_happiness(randint(4000,8000))->update;
    $planet->add_news(100,'Protesters now march on the %s Planetary Command Center, asking for the Governor\'s resignation.', $planet->name);
}

sub violent_protest {
    my ($planet, $espionage, $spy, $cop) = @_;
    return undef unless defined $spy;
    out('Violent Protest');
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $planet->spend_happiness(randint(3000,6000))->update;
    $planet->add_news(100,'The protests at the %s Ministries have turned violent. An official was rushed to hospital in critical condition.', $planet->name);
}

sub protest {
    my ($planet, $espionage, $spy, $cop) = @_;
    return undef unless defined $spy;
    out('Protest');
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $planet->spend_happiness(randint(2000,4000))->update;
    $planet->add_news(100,'Protesters can be seen jeering outside nearly every Ministry at this hour on %s.', $planet->name);
}

sub civil_unrest {
    my ($planet, $espionage, $spy, $cop) = @_;
    return undef unless defined $spy;
    out('Civil Unrest');
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $planet->spend_happiness(randint(1000,2000))->update;
    $planet->add_news(100,'In recent weeks there have been rumblings of political discontent on %s.', $planet->name);
}

sub calm_the_rebels {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Calm the Rebels');
    $planet->add_happiness(randint(250,2500))->update;
    $planet->add_news(100,'In an effort to bring an swift end to the rebellion, the %s Governor delivered an eloquent speech about hope.', $planet->name);
}

sub peace_talks {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Peace Talks');
    $planet->add_happiness(randint(500,5000))->update;
    $planet->add_news(100,'Officials from both sides of the rebellion are at the Planetary Command Center on %s today to discuss peace.', $planet->name);
}

sub day_of_rest {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Day of Rest');
    $planet->add_happiness(randint(2500,25000))->update;
    $planet->add_news(100,'The Governor of %s declares a day of rest and peace. Citizens rejoice.', $planet->name);
}

sub festival {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Festival');
    $planet->add_happiness(randint(1000,10000))->update;
    $planet->add_news(100,'The %s Governor calls it the %s festival. Whatever you call it, people are happy.', $planet->name, $planet->star->name);
}

sub turn_spy {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Turn Spy');
    turn_a_spy($planet, $spy, $cop);
    $planet->add_news(60,'%s has just announced plans to defect from %s to %s.', $spy->name, $spy->empire->name, $cop->empire->name);
}

sub turn_rebel {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Turn Rebels');
    turn_a_spy($planet, $spy, $cop);
    $planet->add_news(70,'The %s Governor\'s call for peace appears to be working. Several rebels told this reporter they are going home.', $planet->name);
}

sub capture_rebel {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Capture Rebel');
    capture_a_spy($planet, $spy, $cop);
    $planet->add_news(50,'Police say they have crushed the rebellion on %s by apprehending %s.', $planet->name, $spy->name);
}

sub kill_rebel {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Kill Rebel');
    kill_a_spy($planet, $spy, $cop);
    $planet->add_news(80,'The leader of the rebellion to overthrow %s was killed in a firefight today on %s.', $planet->empire->name, $planet->name);
}

sub kill_mutaneer {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Kill Mutaneer');
    kill_a_spy($planet, $spy, $cop);
    $planet->add_news(80,'Double agent %s of %s was executed on %s today.', $spy->name, $spy->empire->name, $planet->name);
}

sub thwart_rebel {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Thwart Rebel');
    miss_a_spy($planet, $spy, $cop);
    $planet->add_news(20,'The rebel leader, known as %s, is still eluding authorities on %s at this hour.', $spy->name, $planet->name);
}

sub destroy_infrastructure {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Destroy Infrastructure');
    my @classes = (
        'Lacuna::DB::Result::Building::Waste::Recycling',
        'Lacuna::DB::Result::Building::EntertainmentDistrict',
        'Lacuna::DB::Result::Building::Park',
        'Lacuna::DB::Result::Building::Waste::Sequestration',
        'Lacuna::DB::Result::Building::Propulsion',
        'Lacuna::DB::Result::Building::Oversight',
        'Lacuna::DB::Result::Building::Network19',
        'Lacuna::DB::Result::Building::Espionage',
        'Lacuna::DB::Result::Building::Security',
        'Lacuna::DB::Result::Building::Development',
        'Lacuna::DB::Result::Building::MiningMinistry',
        'Lacuna::DB::Result::Building::Intelligence',
        'Lacuna::DB::Result::Building::Trade',
        'Lacuna::DB::Result::Building::Transporter',
        'Lacuna::DB::Result::Building::Shipyard',
        'Lacuna::DB::Result::Building::SpacePort',
        'Lacuna::DB::Result::Building::Observatory',
        );
    my $building = $db->resultset('Lacuna::DB::Result::Building')->search(
        { body_id => $planet->id, class => { in => \@classes } },
        { rows=>1, order_by => { -desc => 'level' } }
        )->single;
    return unless defined $building;
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_kablooey.txt',
        params      => [$building->level, $building->name, $planet->name],
    );
    $spy->things_destroyed( $spy->things_destroyed + 1 );
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => ['a level of their level '.($building->level).' '.$building->name, $planet->name, $spy->name],
    );
    $planet->add_news(90,'%s was rocked today when the %s exploded, sending people scrambling for their lives.', $planet->name, $building->name);
    if ($building->level <= 1) {
        $building->delete;
    }
    else {
        $building->level( $building->level - 1);
        $building->update;
    }
    $planet->needs_surface_refresh(1);
    $planet->needs_recalc(1);
    $planet->update;
}

sub destroy_upgrade {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    my $builds = $planet->builds(1);
    my $building = $builds->next;
    return unless defined $building;
    $building->body($planet);
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_kablooey.txt',
        params      => [$building->level + 1, $building->name, $planet->name],
    );
    $spy->things_destroyed( $spy->things_destroyed + 1 );
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => ['a level of their level '.($building->level + 1).' '.$building->name, $planet->name, $spy->name],
    );
    $planet->add_news(90,'%s was rocked today when a construction crane toppled into the %s.', $planet->name, $building->name);
    if ($building->level == 0) {
        $building->delete;
    }
    else {
        $building->is_upgrading(0);
        $building->update;
    }
    $planet->needs_surface_refresh(1);
    $planet->needs_recalc(1);
    $planet->update;
}

sub destroy_ship {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Destroy Ships');
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $planet->id, task => 'Docked'});
    my $ship = $ships->next;
    return unless (defined $ship);
    $spy->things_destroyed( $spy->things_destroyed + 1 );
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => [$ship->type_formatted, $planet->name, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_blew_up_at_port.txt',
        params      => [$ship->type_formatted, $planet->name],
    );
    $planet->add_news(90,'Today officials on %s are investigating the explosion of a %s at the Space Port.', $planet->name, $ship->type_formatted);
    $ship->delete;
}

sub destroy_mining_ship {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Destroy Mining Cargo Ship');
    my $ministry = $planet->mining_ministry;
    return undef unless defined $ministry;
    return undef unless $ministry->ship_count > 0;
    $ministry->ship_count($ministry->ship_count - 1);
    $ministry->recalc_ore_production;
    $ministry->update;
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_blew_up_at_port.txt',
        params      => ['mining cargo ship',$planet->name],
    );
    $spy->things_destroyed( $spy->things_destroyed + 1 );
    $spy->update;
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => ['mining cargo ship', $planet->name, $spy->name],
    );
    $planet->add_news(90,'Today, officials on %s are investigating the explosion of a mining cargo ship at the Space Port.', $planet->name);
}

sub capture_saboteur {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Capture Saboteur');
    capture_a_spy($planet, $spy, $cop);
    $planet->add_news(40,'A saboteur was apprehended on %s today by %s authorities.', $planet->name, $planet->empire->name);
}

sub kill_saboteur {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Kill Saboteur');
    kill_a_spy($planet, $spy, $cop);
    $planet->add_news(70,'%s told us that a lone saboteur was killed on %s before he could carry out his plot.', $planet->empire->name, $planet->name);
}

sub thwart_saboteur {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Thwart Saboteur');
    miss_a_spy($planet, $spy, $cop);
    $planet->add_news(20,'%s authorities on %s are conducting a manhunt for a suspected saboteur.', $planet->empire->name, $planet->name);
}

sub steal_resources {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    out('Steal Resources');
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {body_id => $planet->id, task => 'Docked', type => {'in' => ['cargo_ship','smuggler_ship']}},
        { rows => 1}
        )->single;
    last unless defined $ship;
    my $home = $spy->from_body;
    $ship->body_id($home->id);
    $ship->body($home);
    $ship->send(
        target      => $planet,
        direction   => 'in',
#        payload     => {
#            spies => [ $spy->id ],
#            resources   => {},
#            # FINISH THIS AFTER CARGO SHIPS ARE IMPLEMENTED
        },
    );
    $spy->available_on($ship->date_available->clone);
    $spy->on_body_id($home->id);
    $spy->task('Travelling');
    $spy->things_stolen( $spy->things_stolen + 1 );
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_theft_report.txt',
        params      => [$ship->type_formatted, $spy->name],
        ## ATTACH RESOURCE TABLE
    );
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_stolen.txt',
        params      => [$ship->type_formatted, $planet->name],
    );
    $planet->add_news(50,'In a daring robbery a thief absconded with a %s from %s today.', $ship->type_formatted, $planet->name);
}

sub steal_ships {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    out('Steal Ships');
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {body_id => $planet->id, task => 'Docked', type => {'!=' => 'probe'}},
        {rows => 1}
        )->single;
    last unless defined $ship;
    my $home = $spy->from_body;
    $ship->body_id($home->id);
    $ship->body($home);
    $ship->send(
        target      => $planet,
        direction   => 'in',
        payload     => { spies => [ $spy->id ] }
    );
    $spy->available_on($ship->date_available->clone);
    $spy->on_body_id($home->id);
    $spy->things_stolen( $spy->things_stolen + 1 );
    $spy->task('Travelling');
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_theft_report.txt',
        params      => [$ship->type_formatted, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_stolen.txt',
        params      => [$ship->type_formatted, $planet->name],
    );
    $planet->add_news(50,'In a daring robbery a thief absconded with a %s from %s today.', $ship->type_formatted, $planet->name);
}

sub steal_building {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    out('Steal Building');
    my $level = randint(1,30);
    my $building = $db->resultset('Lacuna::DB::Result::Building')->search(
        { body_id => $planet->id, level => {'>=' => $level}, class => { 'not like' => 'Lacuna::DB::Result::Building::Permanent%' } },
        { rows=>1, order_by => { -desc => 'upgrade_started' }}
        )->single;
    return undef unless defined $building;
    $spy->things_stolen( $spy->things_stolen + 1 );
    $spy->update;
    $spy->from_body->add_plan($building->class, $level);
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_theft_report.txt',
        params      => [$level, $building->name, $spy->name],
    );
}

sub kill_thief {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Kill Thief');
    kill_a_spy($planet, $spy, $cop);
    $planet->add_news(70,'%s police caught and killed a thief on %s during the commission of the hiest.', $planet->empire->name, $planet->name);
}

sub capture_thief {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Capture Thief');
    capture_a_spy($planet, $spy, $cop);
    $planet->add_news(40,'%s announced the incarceration of a thief on %s today.', $planet->empire->name, $planet->name);
}

sub thwart_thief {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Thwart Thief');
    miss_a_spy($planet, $spy, $cop);
    $planet->add_news(20,'A thief evaded %s authorities on %s. Citizens are warned to lock their doors.', $planet->empire->name, $planet->name);
}

sub shut_down_building {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    out('Shut Down Building');
    my @classnames = (
        'Lacuna::DB::Result::Building::PlanetaryCommand',
        'Lacuna::DB::Result::Building::Shipyard',
        'Lacuna::DB::Result::Building::Park',
        'Lacuna::DB::Result::Building::Waste::Recycling',
        'Lacuna::DB::Result::Building::Development',
        'Lacuna::DB::Result::Building::Intelligence',
        'Lacuna::DB::Result::Building::Trade',
        'Lacuna::DB::Result::Building::Transporter',
    );
    my $building_class = @classnames[randint(0,scalar(@classnames) - 1)];
    my $building = $planet->get_building_of_class($building_class);
    return undef unless defined $building;
    $building->offline(DateTime->now->add(seconds => randint(60 * 10 , 60 * 60 * 3)));
    $building->update;
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_loss_of_power.txt',
        params      => [$building->name, $planet->name],
    );
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_disabled_a_building.txt',
        params      => [$building->name, $planet->name, $spy->name],
    );
    $planet->add_news(25,'Employees at the %s on %s were left in the dark today during a power outage.', $building->name, $planet->name);    
}

sub take_control_of_probe {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    my $probe = $db->resultset('Lacuna::DB::Result::Probes')->search({body_id => $planet->id }, {rows=>1})->single;
    return undef unless defined $probe;
    $probe->body_id($spy->from_body_id);
    $probe->empire_id($spy->empire_id);
    $probe->update;
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_have_taken_control_of_a_probe.txt',
        params      => [$probe->star->name, $planet->empire->name, $spy->name],
    );
    $spy->things_stolen( $spy->things_stolen + 1 );
    $spy->update;
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$planet->star->name],
    );
    $planet->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $planet->empire->name, $probe->star->name);    
}

sub kill_contact_with_mining_platform {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    out('Kill Contact With Mining Platform');
    my $ministry = $planet->mining_ministry;
    return undef unless defined $ministry;
    my $platform = $db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({planet_id => $planet->id});
    return undef unless defined $platform;
    my $asteroid = $platform->asteroid;
    return undef unless defined $asteroid;
    $ministry->remove_platform($platform);
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'we_lost_contact_with_a_mining_platform.txt',
        params      => [$asteroid->name],
    );
    $spy->things_destroyed( $spy->things_destroyed + 1 );
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_disabled_a_mining_platform.txt',
        params      => [$asteroid->name, $planet->empire->name, $spy->name],
    );
    $planet->add_news(50,'The %s controlled mining outpost on %s went dark. Our thoughts are with the miners.', $planet->empire->name, $asteroid->name);    
}

sub hack_observatory_probes {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    out('Hack Observatory Probes');
    my $probe = $db->resultset('Lacuna::DB::Result::Probes')->search({body_id => $planet->id }, {rows=>1})->single;
    return undef unless defined $probe;
    $spy->things_destroyed( $spy->things_destroyed + 1 );
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_destroyed_a_probe.txt',
        params      => [$probe->star->name, $planet->empire->name, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$probe->star->name],
    );
    $probe->delete;
    $planet->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $planet->empire->name, $probe->star->name);    
}

sub hack_offending_probes {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Hack Offensive Probes');
    my @safe = ($planet->empire_id, $cop->empire_id);
    foreach my $other_cop (@{$espionage->{'Counter Espionage'}{spies}}) {
        push @safe, $other_cop->empire_id;
    }
    my $probe = $db->resultset('Lacuna::DB::Result::Probes')->search({star_id => $planet->star_id, empire_id => {'not in' => \@safe} }, {rows=>1})->single;
    return undef unless defined $probe;
    $cop->things_destroyed( $cop->things_destroyed + 1 );
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_destroyed_a_probe.txt',
        params      => [$planet->star->name, $cop->name],
    );
    $probe->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$planet->star->name],
    );
    $probe->delete;
    $planet->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $probe->empire->name, $planet->star->name);    
}

sub hack_local_probes {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Hack Local Probes');
    my $probe = $db->resultset('Lacuna::DB::Result::Probes')->search({star_id => $planet->star_id, empire_id => $planet->empire_id }, {rows=>1})->single;
    return undef unless defined $probe;
    $spy->things_destroyed( $spy->things_destroyed + 1 );
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_destroyed_a_probe.txt',
        params      => [$planet->star->name, $planet->empire->name, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$planet->star->name],
    );
    $probe->delete;
    $planet->add_news(25,'%s scientists say they have lost control of a research probe in the %s system.', $planet->empire->name, $planet->star->name);    
}

sub colony_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Colony Report');
    my @colonies = (['Name','X','Y','Orbit']);
    my $planets = $planet->empire->planets;
    while (my $colony = $planets->next) {
        push @colonies, [
            $colony->name,
            $colony->x,
            $colony->y,
            $colony->orbit,
        ];
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Colony Report', $planet->name, $spy->name],
        attach_table=> \@colonies,
    );
}

sub surface_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Surface Report');
    my @map;
    my $buildings = $planet->buildings;
    while (my $building = $buildings->next) {
        push @map, {
            image   => $building->image_level,
            x       => $building->x,
            y       => $building->y,
        };
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Surface Report', $planet->name, $spy->name],
        attach_map  => {
            surface_image   => $planet->surface,
            buildings       => \@map
        },
    );
}

sub spy_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Spy Report');
    my @peeps = (['Name','From','Assignment','Level']);
    my %planets = ( $planet->id => $planet->name );
    my @spooks = @{get_full_spies_list($espionage)};
    while (my $spook = pop @spooks) {
        next if ($spy->empire_id eq $spook->empire_id); # skip our own
        unless (exists $planets{$spook->from_body_id}) {
            $planets{$spook->from_body_id} = $spook->from_body->name;
        }
        push @peeps, [$spook->name, $planets{$spook->from_body_id}, $spook->task, $spook->level];
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Spy Report', $planet->name, $spy->name],
        attach_table=> \@peeps,
    );
}

sub economic_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Economic Report');
    my @resources = (
        ['Resource', 'Per Hour', 'Stored'],
        [ 'Food', $planet->food_hour, $planet->food_stored ],
        [ 'Water', $planet->water_hour, $planet->water_stored ],
        [ 'Energy', $planet->energy_hour, $planet->energy_stored ],
        [ 'Ore', $planet->ore_hour, $planet->ore_stored ],
        [ 'Waste', $planet->waste_hour, $planet->waste_stored ],
        [ 'Happiness', $planet->happiness_hour, $planet->happiness ],
    );
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Economic Report', $planet->name, $spy->name],
        attach_table=> \@resources,
    );
}

sub travel_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Travel Report');
    my @travelling = (['Ship Name','Type','From','To','Arrival']);
    my $ships = $planet->ships_travelling;
    while (my $ship = $ships->next) {
        my $target = ($ship->foreign_body_id) ? $ship->foreign_body : $ship->foreign_star;
        my $from = $planet->name;
        my $to = $target->name;
        if ($ship->direction ne 'out') {
            my $temp = $from;
            $from = $to;
            $to = $temp;
        }
        push @travelling, [
            $ship->name,
            $ship->type_formatted,
            $planet->name,
            $target->name,
            $ship->date_available_formatted,
        ];
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Travel Report', $planet->name, $spy->name],
        attach_table=> \@travelling,
    );
}

sub ship_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Ship Report');
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $planet->id, task => 'Docked'});
    my @ships = (['Name', 'Type', 'Speed', 'Hold Size']);
    while (my $ship = $ships->next) {
        push @ships, [$ship->name, $ship->type_formatted, $ship->speed, $ship->hold_size];
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Docked Ships Report', $planet->name, $spy->name],
        attach_table=> \@ships,
    );
}

sub build_queue_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Build Queue Report');
    my @report = (['Building', 'Level', 'Expected Completion']);
    my $builds = $planet->builds;
    while (my $build = $builds->next) {
        push @report, [
            $build->name,
            $build->level + 1,
            format_date($build->upgrade_ends),
        ];
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Build Queue Report', $planet->name, $spy->name],
        attach_table=> \@report,
    );
}

sub false_interrogation_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('False Interrogation Report');
    my $suspect = random_spy($espionage->{captured});
    return unless defined $suspect;
    my $suspect_home = $suspect->from_body;
    my $suspect_empire = $suspect->empire;
    my $suspect_species = $suspect_empire->species;
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Interrogation Report', $planet->name, $cop->name],
        attach_table=> [
            ['Question', 'Response'],
            ['Name', $suspect->name],
            ['Offense Rating', randint(0,27)],
            ['Defense Rating', randint(0,27)],
            ['Allegiance', $suspect_empire->name],
            ['Home World', $suspect_home->name],
            ['Species Name', $suspect_species->name],
            ['Species Description', $suspect_species->description],
            ['Habitable Orbits', join(' - ',randint(1,3), randint(3,7))],
            ['Manufacturing Affinity', randint(1,7)],
            ['Deception Affinity', randint(1,7)],
            ['Research Affinity', randint(1,7)],
            ['Management Affinity', randint(1,7)],
            ['Farming Affinity', randint(1,7)],
            ['Mining Affinity', randint(1,7)],
            ['Science Affinity', randint(1,7)],
            ['Environmental Affinity', randint(1,7)],
            ['Political Affinity', randint(1,7)],
            ['Trade Affinity', randint(1,7)],
            ['Growth Affinity', randint(1,7)],
            ],
    );
}

sub interrogation_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop);
    out('Interrogation Report');
    my $suspect = random_spy($espionage->{captured});
    return unless defined $suspect;
    my $suspect_home = $suspect->from_body;
    my $suspect_empire = $suspect->empire;
    my $suspect_species = $suspect_empire->species;
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Interrogation Report', $planet->name, $cop->name],
        attach_table=> [
            ['Question', 'Response'],
            ['Name', $suspect->name],
            ['Offense Rating', $suspect->offense],
            ['Defense Rating', $suspect->defense],
            ['Allegiance', $suspect_empire->name],
            ['Home World', $suspect_home->name],
            ['Species Name', $suspect_species->name],
            ['Species Description', $suspect_species->description],
            ['Habitable Orbits', join(' - ', $suspect_species->min_orbit, $suspect_species->max_orbit)],
            ['Manufacturing Affinity', $suspect_species->manufacturing_affinity],
            ['Deception Affinity', $suspect_species->deception_affinity],
            ['Research Affinity', $suspect_species->research_affinity],
            ['Management Affinity', $suspect_species->management_affinity],
            ['Farming Affinity', $suspect_species->farming_affinity],
            ['Mining Affinity', $suspect_species->mining_affinity],
            ['Science Affinity', $suspect_species->science_affinity],
            ['Environmental Affinity', $suspect_species->environmental_affinity],
            ['Political Affinity', $suspect_species->political_affinity],
            ['Trade Affinity', $suspect_species->trade_affinity],
            ['Growth Affinity', $suspect_species->growth_affinity],
            ],
    );
}

sub kill_guard_and_escape_prison {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Kill Guard and Escape Prison');
    my $suspect = shift @{$espionage->{captured}};
    return undef unless defined $suspect;
    kill_a_spy($planet, $cop, $suspect);
    escape_a_spy($planet, $suspect);
    $planet->add_news(70,'An inmate killed his interrogator, and escaped the prison on %s today.', $planet->name);
}

sub escape_prison {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $spy);
    out('Escape Prison');
    my $suspect = shift @{$espionage->{captured}};
    return undef unless defined $suspect;
    escape_a_spy($planet, $suspect);
    $planet->add_news(50,'At this hour police on %s are flabbergasted as to how an inmate escaped earlier in the day.', $planet->name);    
}

sub kill_suspect {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop);
    out('Kill Suspect');
    my $suspect = shift @{$espionage->{'Captured'}{spies}};
    return undef unless defined $suspect;
    kill_a_spy($planet, $suspect, $cop);
    $planet->add_news(50,'Allegations of police brutality are being made on %s after an inmate was killed in custody today.', $planet->name);
}

sub capture_rescuer {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Capture Rescuer');
    capture_a_spy($planet, $spy, $cop);
    $planet->add_news(60,'%s was caught trying to break into prison today on %s. Police insisted he stay.', $spy->name, $planet->name);
}

sub thwart_intelligence {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Thwart Intelligence Agent');
    miss_a_spy($planet, $spy, $cop);
    $planet->add_news(25,'Corporate espionage has become a real problem on %s.', $planet->name);
}

sub counter_intel_report {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Counter Intelligence Report');
    my @peeps = (['Name','From','Assignment','Level']);
    my %planets = ( $planet->id => $planet->name );
    my @spooks = shuffle(@{get_full_spies_list($espionage)});
    while (my $spook = pop @spooks) {
        next if ($spook->empire_id eq $cop->empire_id); # skip our own
        unless (exists $planets{$spook->from_body_id}) {
            $planets{$spook->from_body_id} = $spook->from_body->name;
        }
        push @peeps, [$spook->name, $planets{$spook->from_body_id}, $spook->task, $spook->level];
    }
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Counter Intelligence Report', $planet->name, $cop->name],
        attach_table=> \@peeps,
    );
}

sub kill_cop {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Kill Cop');
    $planet->add_news(60,'An officer named %s was killed in the line of duty on %s.', $cop->name, $planet->name);
    kill_a_spy($planet, $cop, $spy);
}

sub kill_intelligence {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Kill Intelligence Agents');
    kill_a_spy($planet, $spy, $cop);
    $planet->add_news(60,'A suspected spy was killed in a struggle with police on %s today.', $planet->name);
}

sub capture_hacker {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Capture Hacker');
    $planet->add_news(30,'Alleged hacker %s is awaiting arraignment on %s today.', $spy->name, $planet->name);
    capture_a_spy($planet, $spy, $cop);
}

sub kill_hacker {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Kill Hacker');
    $planet->add_news(60,'A suspected hacker, age '.randint(16,60).', was found dead in his home today on %s.', $planet->name);
    kill_a_spy($planet, $spy, $cop);    
}

sub thwart_hacker {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless (defined $cop && defined $spy);
    out('Thwart Hacker');
    miss_a_spy($planet, $spy, $cop);
    $planet->add_news(10,'Identity theft has become a real problem on %s.', $planet->name);  
}

sub network19_propaganda1 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Network 19 Propaganda 1');
    $cop->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'A resident of %s has won the Lacuna Expanse talent competition.', $planet->name)) {
        $planet->add_happiness(250)->update;
    }
}

sub network19_propaganda2 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Network 19 Propaganda 2');
    $cop->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'The economy of %s is looking strong, showing GDP growth of nearly 10%% for the past quarter.',$planet->name)) {
        $planet->add_happiness(500)->update;
    }
}

sub network19_propaganda3 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Network 19 Propaganda 3');
    $cop->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'The Governor of %s has set aside 1000 square kilometers as a nature preserve.', $planet->name)) {
        $planet->add_happiness(750)->update;
    }
}

sub network19_propaganda4 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Network 19 Propaganda 4');
    $cop->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'If %s had not inhabited %s, the planet would likely have reverted to a barren rock.', $planet->empire->name, $planet->name)) {
        $planet->add_happiness(1000)->update;
    }
}

sub network19_propaganda5 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Network 19 Propaganda 5');
    $cop->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'The benevolent leader of %s is a gift to the people of %s.', $planet->empire->name, $planet->name)) {
        $planet->add_happiness(1250)->update;
    }
}

sub network19_propaganda6 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Network 19 Propaganda 6');
    $cop->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'%s is the greatest, best, most free empire in the Expanse, ever.', $planet->empire->name)) {
        $planet->add_happiness(1500)->update;
    }
}

sub network19_propaganda7 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $cop;
    out('Network 19 Propaganda 7');
    $cop->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'%s is the ultimate power in the Expanse right now. It is unlikely to be challenged any time soon.', $planet->empire->name)) {
        $planet->add_happiness(1750)->update;
    }
}

sub network19_defamation1 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Network 19 Defamation 1');
    $spy->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'A financial report for %s shows that many people are out of work as the unemployment rate approaches 10%%.', $planet->name)) {
        $planet->spend_happiness(250)->update;
    }
}

sub network19_defamation2 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Network 19 Defamation 2');
    $spy->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'An outbreak of the Dultobou virus was announced on %s today. Citizens are encouraged to stay home from work and school.', $planet->name)) {
        $planet->spend_happiness(500)->update;
    }
}

sub network19_defamation3 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Network 19 Defamation 3');
    $spy->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'%s is unable to keep its economy strong. Sources inside say it will likely fold in a few days.', $planet->empire->name)) {
        $planet->spend_happiness(750)->update;
    }
}

sub network19_defamation4 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Network 19 Defamation 4');
    $spy->seeds_planted($spy->seeds_planted + 1);
    if ($planet->add_news(50,'The Governor of %s has lost her mind. She is a raving mad lunatic! The Emperor could not be reached for comment.', $planet->name)) {
        $planet->spend_happiness(1250)->update;
    }
}

sub network19_defamation5 {
    my ($planet, $espionage, $spy, $cop) = @_;
    return unless defined $spy;
    out('Network 19 Defamation 5');
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'%s is the smallest, worst, least free empire in the Expanse, ever.', $planet->empire->name)) {
        $planet->spend_happiness(1500)->update;
    }
}




# SPIES

sub random_spy {
    my $spies = shift;
    my @random = shuffle @{$spies};
    return $random[0];
}

sub determine_espionage {
    my $planet = shift;
    my $spies = $db->resultset('Lacuna::DB::Result::Spies')->search( { on_body_id  => $planet->id } );
    my %espionage = ( has_spies => 0, offense => [], defense => [], captured => [], other => []);        
    while (my $spy = $spies->next) {
        $espionage{has_spies} = 1;
        if ($spy->task eq 'Counter Espionage') {                                        # use defense
            $spy->defense_mission_count( $spy->defense_mission_count );
            push @{$espionage{defense}}, $spy;
        }
        elsif ($spy->task eq 'Captured') {
            push @{$espionage{captured}}, $spy;
        }
        elsif ($spy->empire_id ne $planet->empire_id && $spy->task ~~ [@offense_tasks]) {                                # can't attack yourself
            $spy->offense_mission_count( $spy->offense_mission_count );
            push @{$espionage{offense}}, $spy;
        }
        else {
            push @{$espionage{other}}, $spy;
        }
    }
    $espionage{defense} = [ shuffle @{$espionage{defense}} ];
    $espionage{offense} = [ shuffle @{$espionage{offense}} ];
    return \%espionage;
}

sub kill_a_spy {
    my ($planet, $spy, $interceptor) = @_;
    $interceptor->spies_killed( $interceptor->spies_killed + 1 );
    $interceptor->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_killed_a_spy.txt',
        params      => [$planet->name, $interceptor->name],
        from        => $interceptor->empire,
    );
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_killed.txt',
        params      => [$spy->name, $planet->name],
    );
    $spy->available_on(DateTime->now->add(hours => 5));
    $spy->task('Killed In Action');
}

sub capture_a_spy {
    my ($planet, $spy, $interceptor) = @_;
    $spy->available_on(DateTime->now->add(months=>1));
    $spy->task('Captured');
    $spy->started_assignment(DateTime->now);
    $spy->times_captured( $spy->times_captured + 1 );
    $interceptor->spies_captured( $spy->spies_captured + 1 );
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_captured.txt',
        params      => [$planet->name, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_captured_a_spy.txt',
        params      => [$planet->name, $interceptor->name],
        from        => $interceptor->empire,
    );
}

sub miss_a_spy {
    my ($planet, $spy, $interceptor) = @_;
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'narrow_escape.txt',
        params      => [$planet->empire->name, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_missed_a_spy.txt',
        params      => [$planet->name, $interceptor->name],
        from        => $interceptor->empire,
    );
}

sub escape_a_spy {
    my ($planet, $spy) = @_;
    $spy->available_on(DateTime->now);
    $spy->task('Idle');
    $spy->update;
    my $evil_empire = $planet->empire;
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'i_have_escaped.txt',
        params      => [$evil_empire->name, $spy->name],
    );
    $evil_empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'you_cant_hold_me.txt',
        params      => [$spy->name],
    );
}

sub knock_out {
    my ($planet, $spy) = @_;
    $spy->available_on(DateTime->now->add(seconds => randint(60, 60 * 60 * 2)));
    $spy->task('Unconscious');
}

sub turn_a_spy {
    my ($planet, $traitor, $spy) = @_;
    my $evil_empire = $planet->empire;
    $spy->spies_turned( $spy->spies_turned + 1 );
    $traitor->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'goodbye.txt',
        params      => [$traitor->name],
    );
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'new_recruit.txt',
        params      => [$traitor->empire->name, $traitor->name, $spy->name],
    );
    # could be abused to get lots of extra spies, may have to add a check for that.
    $traitor->times_turned( $traitor->times_turned + 1 );
    $traitor->task('Idle');
    $traitor->empire_id($spy->empire_id);
    $traitor->from_body_id($spy->from_body_id);
}

sub get_full_spies_list {
    my ($espionage) = @_;
    my @spies = (@{$espionage->{captured}}, @{$espionage->{defense}}, @{$espionage->{offense}}, @{$espionage->{other}});
    return \@spies;
}

# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


