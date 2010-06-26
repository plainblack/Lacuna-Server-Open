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

out('Processing planets');
my $planets = $db->resultset('Lacuna::DB::Result::Map::Body')->search({ empire_id   => {'>' => 0} });
while (my $planet = $planets->next) {
    out('Ticking '.$planet->name);
    $planet->tick;
    my $espionage = determine_espionage($planet);
    unless ($espionage->{_has_spies}) {
       out('No Spies On Planet');
       next;
    }

    if (calculate_mission_score($espionage, 'Gather Shipping Intelligence', 20) > 0) {
        gather_shipping_intel($planet, $espionage);
    }
    else {
        gather_shipping_intel_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Gather Empire Intelligence', 15) > 0) {
        gather_empire_intel($planet, $espionage);
    }
    else {
        gather_empire_intel_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Gather Operative Intelligence', 10) > 0) {
        gather_operative_intel($planet, $espionage);
    }
    else {
        gather_operative_intel_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Hack Network 19', 5) > 0) {
        hack_network_19($planet, $espionage);
    }
    else {
        hack_network_19_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Appropriate Technology', 0) > 0) {
        appropriate_tech($planet, $espionage);
    }
    else {
        appropriate_tech_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Sabotage Probes', -5) > 0) {
        sabotage_probes($planet, $espionage);
    }
    else {
        sabotage_probes_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Rescue Comrades', -10) > 0) {
        rescue_comrades($planet, $espionage);
    }
    else {
        rescue_comrades_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Sabotage Ships', -15) > 0) {
        sabotage_ships($planet, $espionage);
    }
    else {
        sabotage_ships_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Appropriate Ships', -20) > 0) {
        appropriate_ships($planet, $espionage);
    }
    else {
        appropriate_ships_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Assassinate Operatives', -25) > 0) {
        assassinate_operatives($planet, $espionage);
    }
    else {
        assassinate_operatives_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Sabotage Infrastructure', -30) > 0) {
        sabotage_infrastructure($planet, $espionage);
    }
    else {
        sabotage_infrastructure_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Incite Mutany', -35) > 0) {
        incite_mutany($planet, $espionage);
    }
    else {
        incite_mutany_loss($planet, $espionage);
    }

    if (calculate_mission_score($espionage, 'Incite Rebellion', -40) > 0) {
        incite_rebellion($planet, $espionage);
    }
    else {
        incite_rebellion_loss($planet, $espionage);
    }

}

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

# MISSIONS

sub gather_shipping_intel {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { ship_report($planet, $espionage) }
        when (2) { travel_report($planet, $espionage) }
    }
}


sub gather_shipping_intel_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { thwart_intelligence($planet, $espionage, 'Gather Shipping Intelligence') }
        when (2) { increase_security($planet, $espionage, 100) }
    }
}


sub gather_empire_intel {
    my ($planet, $espionage) = @_;
    given (randint(1,4)) {
        when (1) { build_queue_report($planet, $espionage) }
        when (2) { economic_report($planet, $espionage) }
        when (3) { surface_report($planet, $espionage) }
        when (4) { colony_report($planet, $espionage) }
    }
}


sub gather_empire_intel_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { thwart_intelligence($planet, $espionage, 'Gather Empire Intelligence') }
        when (2) { increase_security($planet, $espionage, 100) }
    }
}


sub gather_operative_intel {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { false_interrogation_report($planet, $espionage) }
        when (2) { spy_report($planet, $espionage) }
    }
}


sub gather_operative_intel_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,3)) {
        when (1) { counter_intel_report($planet, $espionage) }
        when (2) { interrogation_report($planet, $espionage) }
        when (3) { thwart_intelligence($planet, $espionage, 'Gather Operative Intelligence') }
    }
}


sub hack_network_19 {
    my ($planet, $espionage) = @_;
    given (randint(1,5)) {
        when (1) { network19_defamation1($planet, $espionage) }
        when (2) { network19_defamation2($planet, $espionage) }
        when (3) { network19_defamation3($planet, $espionage) }
        when (4) { network19_defamation4($planet, $espionage) }
        when (5) { network19_defamation5($planet, $espionage) }
    }
}


sub hack_network_19_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,9)) {
        when (1) { capture_hacker($planet, $espionage) }
        when (2) { network19_propaganda1($planet, $espionage) }
        when (3) { network19_propaganda2($planet, $espionage) }
        when (4) { network19_propaganda3($planet, $espionage) }
        when (5) { network19_propaganda4($planet, $espionage) }
        when (6) { network19_propaganda5($planet, $espionage) }
        when (7) { network19_propaganda6($planet, $espionage) }
        when (8) { network19_propaganda7($planet, $espionage) }
        when (9) { thwart_hacker($planet, $espionage) }
    }
}


sub appropriate_tech {
    my ($planet, $espionage) = @_;
    given (randint(1,1)) {
        when (1) { steal_building($planet, $espionage) }
    }
}


sub appropriate_tech_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,3)) {
        when (1) { capture_thief($planet, $espionage, 'Appropriate Ships') }
        when (2) { thwart_thief($planet, $espionage, 'Appropriate Ships') }
        when (3) { increase_security($planet, $espionage, 500) }
    }
}


sub sabotage_probes {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { hack_local_probes($planet, $espionage) }
        when (2) { hack_observatory_probes($planet, $espionage) }
    }
}


sub sabotage_probes_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,3)) {
        when (1) { hack_offending_probes($planet, $espionage) }
        when (2) { kill_hacker($planet, $espionage) }
        when (3) { increase_security($planet, $espionage, 750) }
    }
}


sub rescue_comrades {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { escape_prison($planet, $espionage) }
        when (2) { kill_guard_and_escape_prison($planet, $espionage) }
    }
}


sub rescue_comrades_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,3)) {
        when (1) { kill_suspect($planet, $espionage) }
        when (2) { increase_security($planet, $espionage, 1000) }
        when (3) { capture_rescuer($planet, $espionage) }
    }
}


sub sabotage_ships {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { destroy_mining_ship($planet, $espionage) }
        when (2) { destroy_ships($planet, $espionage, randint(1,3)) }
    }
}


sub sabotage_ships_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,3)) {
        when (1) { capture_saboteurs($planet, $espionage, randint(1,2), 'Sabotage Ships') }
        when (2) { thwart_saboteur($planet, $espionage, 'Sabotage Ships') }
        when (3) { kill_saboteurs($planet, $espionage, 1, 'Sabotage Ships') }
    }
}


sub appropriate_ships {
    my ($planet, $espionage) = @_;
    given (randint(1,3)) {
        when (1) { steal_ships($planet, $espionage) }
        when (2) { steal_resources($planet, $espionage) }
        when (3) { take_control_of_probe($planet, $espionage) }
    }
}


sub appropriate_ships_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { capture_thief($planet, $espionage, 'Appropriate Ships') }
        when (2) { kill_thief($planet, $espionage, 'Appropriate Ships') }
    }
}


sub assassinate_operatives {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { kill_cop($planet, $espionage, 'Assassinate Operatives') }
        when (2) { kill_cops($planet, $espionage, randint(2,4)) }
    }
}


sub assassinate_operatives_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,1)) {
        when (1) { kill_intelligence($planet, $espionage, randint(1,4)) }
    }
}


sub sabotage_infrastructure {
    my ($planet, $espionage) = @_;
    given (randint(1,4)) {
        when (1) { kill_contact_with_mining_platform($planet, $espionage) }
        when (2) { shut_down_building($planet, $espionage) }
        when (3) { destroy_upgrades($planet, $espionage, randint(1,5)) }
        when (3) { destroy_infrastructure($planet, $espionage, randint(1,5)) }
    }
}


sub sabotage_infrastructure_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { capture_saboteurs($planet, $espionage, randint(1,10), 'Sabotage Infrastructure') }
        when (2) { kill_saboteurs($planet, $espionage, randint(1,6), 'Sabotage Ships') }
    }
}


sub incite_mutany {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { turn_spies($planet, $espionage, randint(1,5), 'Counter Espionage', 'Incite Mutany') }
        when (2) { kill_cop($planet, $espionage, 'Incite Mutany') }
    }
}


sub incite_mutany_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,2)) {
        when (1) { turn_spies($planet, $espionage, randint(1,5), 'Incite Mutany', 'Counter Espionage') }
        when (2) { kill_mutaneer($planet, $espionage) }
    }
}


sub incite_rebellion {
    my ($planet, $espionage) = @_;
    given (randint(1,8)) {
        when (1) { civil_unrest($planet, $espionage) }
        when (2) { protest($planet, $espionage) }
        when (3) { violent_protest($planet, $espionage) }
        when (4) { march_on_capitol($planet, $espionage) }
        when (5) { small_rebellion($planet, $espionage) }
        when (6) { turn_riot_police($planet, $espionage, randint(1,3)) }
        when (7) { kill_cop($planet, $espionage, 'Incite Rebellion') }
        when (8) { uprising($planet, $espionage) }
    }
}


sub incite_rebellion_loss {
    my ($planet, $espionage) = @_;
    given (randint(1,9)) {
        when (1) { day_of_rest($planet, $espionage) }
        when (2) { festival($planet, $espionage) }
        when (3) { capture_rebel($planet, $espionage) }
        when (4) { kill_rebel($planet, $espionage) }
        when (5) { peace_talks($planet, $espionage) }
        when (6) { calm_the_rebels($planet, $espionage) }
        when (7) { thwart_rebel($planet, $espionage) }
        when (8) { turn_rebel($planet, $espionage) }
        when (9) { turn_rebels($planet, $espionage, randint(1,3)) }
    }
}



# OUTCOMES

sub uprising {
    my ($planet, $espionage) = @_;
    out('Uprising');
    my $spy = random_spy($espionage->{'Incite Rebellion'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $spy->update;
    my $loss = sprintf('%.0f', $planet->happiness * 0.10 );
    $loss = 10000 unless ($loss > 10000);
    $planet->spend_happiness( $loss )->update;
    my @spies = pick_a_spy_per_empire($espionage->{'Incite Rebellion'}{spies});
    foreach my $rebel (@spies) {
        $rebel->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_incited_a_rebellion.txt',
            params      => [$planet->empire->name, $planet->name, $loss, $rebel->name, $espionage->{_mission_score}],
        );
    }
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'uprising.txt',
        params      => [$spy->name, $planet->name, $loss],
    );
    $planet->add_news(100,'Led by %s, the citizens of %s are rebelling against %s.', $spy->name, $planet->name, $planet->empire->name);
}

sub turn_cops {
    my ($planet, $espionage, $quantity) = @_;
    out('Turn Cops');
    my $rebel = random_spy($espionage->{'Incite Mutany'}{spies});
    return undef unless defined $rebel;
    my $got;
    for (1..$quantity) {
        my $cop = shift @{$espionage->{'Counter Espionage'}{spies}};
        last unless defined $cop;
        $espionage->{'Counter Espionage'}{rating} -= $cop->offense;
        turn_a_spy($planet, $cop, $rebel, $espionage->{_mission_score});
        $got = 1;
    }
    if ($got) {
        $planet->add_news(70,'Military leaders on %s are calling for a no confidence vote about the Governor.', $planet->name);
    }
}

sub turn_riot_police {
    my ($planet, $espionage, $quantity) = @_;
    out('Turn Riot Police');
    my $rebel = random_spy($espionage->{'Incite Rebellion'}{spies});
    return undef unless defined $rebel;
    my $got;
    for (1..$quantity) {
        my $cop = shift @{$espionage->{'Counter Espionage'}{spies}};
        last unless defined $cop;
        $espionage->{'Counter Espionage'}{rating} -= $cop->offense;
        turn_a_spy($planet, $cop, $rebel, $espionage->{_mission_score});
        $got = 1;
    }
    if ($got) {
        $planet->add_news(70,'In a shocking turn of events, police could be seen leaving their posts to join the protesters on %s today.', $planet->name);
    }
}

sub small_rebellion {
    my ($planet, $espionage) = @_;
    out('Small Rebellion');
    my $spy = random_spy($espionage->{'Incite Rebellion'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $spy->update;
    $planet->spend_happiness(randint(5000,10000))->update;
    $planet->add_news(100,'Hundreds are dead at this hour after a protest turned into a small, but violent, rebellion on %s.', $planet->name);
}

sub march_on_capitol {
    my ($planet, $espionage) = @_;
    out('March On Capitol');
    my $spy = random_spy($espionage->{'Incite Rebellion'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $spy->update;
    $planet->spend_happiness(randint(4000,8000))->update;
    $planet->add_news(100,'Protesters now march on the %s Planetary Command Center, asking for the Governor\'s resignation.', $planet->name);
}

sub violent_protest {
    my ($planet, $espionage) = @_;
    out('Violent Protest');
    my $spy = random_spy($espionage->{'Incite Rebellion'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $spy->update;
    $planet->spend_happiness(randint(3000,6000))->update;
    $planet->add_news(100,'The protests at the %s Ministries have turned violent. An official was rushed to hospital in critical condition.', $planet->name);
}

sub protest {
    my ($planet, $espionage) = @_;
    out('Protest');
    my $spy = random_spy($espionage->{'Incite Rebellion'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $spy->update;
    $planet->spend_happiness(randint(2000,4000))->update;
    $planet->add_news(100,'Protesters can be seen jeering outside nearly every Ministry at this hour on %s.', $planet->name);
}

sub civil_unrest {
    my ($planet, $espionage) = @_;
    out('Civil Unrest');
    my $spy = random_spy($espionage->{'Incite Rebellion'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted( $spy->seeds_planted + 1 );
    $spy->update;
    $planet->spend_happiness(randint(1000,2000))->update;
    $planet->add_news(100,'In recent weeks there have been rumblings of political discontent on %s.', $planet->name);
}

sub calm_the_rebels {
    my ($planet, $espionage) = @_;
    out('Calm the Rebels');
    $planet->add_happiness(randint(250,2500))->update;
    $planet->add_news(100,'In an effort to bring an swift end to the rebellion, the %s Governor delivered an eloquent speech about hope.', $planet->name);
}

sub peace_talks {
    my ($planet, $espionage) = @_;
    out('Peace Talks');
    $planet->add_happiness(randint(500,5000))->update;
    $planet->add_news(100,'Officials from both sides of the rebellion are at the Planetary Command Center on %s today to discuss peace.', $planet->name);
}

sub day_of_rest {
    my ($planet, $espionage) = @_;
    out('Day of Rest');
    $planet->add_happiness(randint(2500,25000))->update;
    $planet->add_news(100,'The Governor of %s declares a day of rest and peace. Citizens rejoice.', $planet->name);
}

sub festival {
    my ($planet, $espionage) = @_;
    out('Festival');
    $planet->add_happiness(randint(1000,10000))->update;
    $planet->add_news(100,'The %s Governor calls it the %s festival. Whatever you call it, people are happy.', $planet->name, $planet->star->name);
}

sub turn_spies {
    my ($planet, $espionage, $quantity, $lose_type, $win_type) = @_;
    out('Turn Rebels');
    my $winner = random_spy($espionage->{$win_type}{spies});
    return undef unless defined $winner;
    for (1..$quantity) {
        my $loser = shift @{$espionage->{$lose_type}{spies}};
        last unless defined $loser;
        turn_a_spy($planet, $loser, $winner);
        $planet->add_news(60,'%s has just announced plans to defect from %s to %s.', $loser->name, $loser->empire->name, $winner->empire->name);
    }
}

sub turn_rebels {
    my ($planet, $espionage, $quantity) = @_;
    out('Turn Rebels');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $got;
    for (1..$quantity) {
        my $rebel = shift @{$espionage->{'Incite Rebellion'}{spies}};
        last unless defined $rebel;
        $espionage->{'Incite Rebellion'}{rating} -= $rebel->offense;
        turn_a_spy($planet, $rebel, $cop);
        $got = 1;
    }
    if ($got) {
        $planet->add_news(70,'The %s Governor\'s call for peace appears to be working. Several rebels told this reporter they are going home.', $planet->name);
    }
}

sub capture_rebel {
    my ($planet, $espionage) = @_;
    out('Capture Rebel');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $rebel = shift @{$espionage->{'Incite Rebellion'}{spies}};
    return undef unless defined $rebel;
    $espionage->{'Incite Rebellion'}{rating} -= $rebel->offense;
    capture_a_spy($planet, $rebel, $cop, $espionage->{_mission_score});
    $planet->add_news(50,'Police say they have crushed the rebellion on %s by apprehending %s.', $planet->name, $rebel->name);
}

sub kill_rebel {
    my ($planet, $espionage) = @_;
    out('Kill Rebel');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $rebel = shift @{$espionage->{'Incite Rebellion'}{spies}};
    last unless defined $rebel;
    kill_a_spy($planet, $rebel, $cop, $espionage->{_mission_score});
    $planet->add_news(80,'The leader of the rebellion to overthrow %s was killed in a firefight today on %s.', $planet->empire->name, $planet->name);
}

sub kill_mutaneer {
    my ($planet, $espionage) = @_;
    out('Kill Mutaneer');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $rebel = shift @{$espionage->{'Incite Mutany'}{spies}};
    last unless defined $rebel;
    $espionage->{'Incite Mutany'}{rating} -= $rebel->offense;
    kill_a_spy($planet, $rebel, $cop, $espionage->{_mission_score});
    $planet->add_news(80,'Double agent %s of %s was executed on %s today.', $rebel->name, $rebel->empire->name, $planet->name);
}

sub thwart_rebel {
    my ($planet, $espionage, $quantity) = @_;
    out('Thwart Rebels');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $rebel = shift @{$espionage->{'Incite Rebellion'}{spies}};
    last unless defined $rebel;
    miss_a_spy($planet, $rebel, $cop, $espionage->{_mission_score});
    $planet->add_news(20,'The rebel leader, known as %s, is still eluding authorities on %s at this hour.', $rebel->name, $planet->name);
}

sub destroy_infrastructure {
    my ($planet, $espionage, $quantity) = @_;
    out('Destroy Infrastructure');
    my $got;
    for (1..$quantity) {
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
        last unless defined $building;
        $espionage->{'Counter Espionage'}{rating} += 25;
        $planet->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'building_kablooey.txt',
            params      => [$building->level, $building->name, $planet->name],
        );
        my @spies = pick_a_spy_per_empire($espionage->{'Sabotage Infrastructure'}{spies});
        foreach my $spy (@spies) {
            $spy->things_destroyed( $spy->things_destroyed + 1 );
            $spy->update;
            $spy->empire->send_predefined_message(
                tags        => ['Intelligence'],
                filename    => 'sabotage_report.txt',
                params      => ['a level of their level '.($building->level).' '.$building->name, $planet->name, $spy->name, $espionage->{_mission_score}],
            );
        }
        $planet->add_news(90,'%s was rocked today when the %s exploded, sending people scrambling for their lives.', $planet->name, $building->name);
        $got = 1;
        if ($building->level <= 1) {
            $building->delete;
        }
        else {
            $building->level( $building->level - 1);
            $building->update;
        }
    }
    if ($got) {
        $planet->needs_surface_refresh(1);
        $planet->needs_recalc(1);
        $planet->update;
    }
}

sub destroy_upgrades {
    my ($planet, $espionage, $quantity) = @_;
    out('Destroy Upgrades');
    my $builds = $planet->builds(1);
    my $got;
    for (1..$quantity) {
        my $building = $builds->next;
        last unless defined $building;
        $building->body($planet);
        $espionage->{'Counter Espionage'}{rating} += 20;
        $planet->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'building_kablooey.txt',
            params      => [$building->level + 1, $building->name, $planet->name],
        );
        my @spies = pick_a_spy_per_empire($espionage->{sabotage}{spies});
        foreach my $spy (@spies) {
            $spy->things_destroyed( $spy->things_destroyed + 1 );
            $spy->update;
            $spy->empire->send_predefined_message(
                tags        => ['Intelligence'],
                filename    => 'sabotage_report.txt',
                params      => ['a level of their level '.($building->level + 1).' '.$building->name, $planet->name, $spy->name, $espionage->{_mission_score}],
            );
        }
        $planet->add_news(90,'%s was rocked today when a construction crane toppled into the %s.', $planet->name, $building->name);
        if ($building->level == 0) {
            $building->delete;
            $got = 1;
        }
        else {
            $building->is_upgrading(0);
            $building->update;
        }
    }
    if ($got) {
        $planet->needs_surface_refresh(1);
        $planet->needs_recalc(1);
        $planet->update;
    }
}

sub destroy_ships {
    my ($planet, $espionage, $quantity) = @_;
    out('Destroy Ships');
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $planet->id, task => 'Docked'});
    for (1..$quantity) {
        my $ship = $ships->next;
        last unless (defined $ship);
        $espionage->{'Counter Espionage'}{rating} += 500;
        my @spies = pick_a_spy_per_empire($espionage->{sabotage}{spies});
        foreach my $spy (@spies) {
            $spy->things_destroyed( $spy->things_destroyed + 1 );
            $spy->update;
            $spy->empire->send_predefined_message(
                tags        => ['Intelligence'],
                filename    => 'sabotage_report.txt',
                params      => [$ship->type_formatted, $planet->name, $spy->name, $espionage->{_mission_score}],
            );
        }
        $planet->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'ship_blew_up_at_port.txt',
            params      => [$ship->type_formatted, $planet->name],
        );
        $planet->add_news(90,'Today, officials on %s are investigating the explosion of a %s at the Space Port.', $planet->name, $ship->type_formatted);
        $ship->delete;
    }
}

sub destroy_mining_ship {
    my ($planet, $espionage) = @_;
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
    my @spies = pick_a_spy_per_empire($espionage->{sabotage}{spies});
    foreach my $spy (@spies) {
        $spy->things_destroyed( $spy->things_destroyed + 1 );
        $spy->update;
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'sabotage_report.txt',
            params      => ['mining cargo ship', $planet->name, $spy->name, $espionage->{_mission_score}],
        );
    }
    $planet->add_news(90,'Today, officials on %s are investigating the explosion of a mining cargo ship at the Space Port.', $planet->name);
    $espionage->{'Counter Espionage'}{rating} += 5;
}

sub capture_saboteurs {
    my ($planet, $espionage, $quantity, $type) = @_;
    out('Capture Saboteurs');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $got;
    for (1..$quantity) {
        my $saboteur = shift @{$espionage->{$type}{spies}};
        last unless defined $saboteur;
        $espionage->{$type}{rating} -= $saboteur->offense;
        capture_a_spy($planet, $saboteur, $cop, $espionage->{_mission_score});
        $got = 1;
    }
    if ($got) {
        $planet->add_news(40,'A saboteur was apprehended on %s today by %s authorities.', $planet->name, $planet->empire->name);
    }
}

sub kill_saboteurs {
    my ($planet, $espionage, $quantity, $type) = @_;
    out('Kill Saboteurs');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $got;
    for (1..$quantity) {
        my $saboteur = shift @{$espionage->{$type}{spies}};
        last unless defined $saboteur;
        $espionage->{$type}{rating} -= $saboteur->offense;
        kill_a_spy($planet, $saboteur, $cop, $espionage->{_mission_score});
        $got = 1;
    }
    if ($got) {
        $planet->add_news(70,'%s told us that a lone saboteur was killed on %s before he could carry out his plot.', $planet->empire->name, $planet->name);
    }
}

sub thwart_saboteur {
    my ($planet, $espionage, $type) = @_;
    out('Thwart Saboteurs');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $saboteur = random_spy($espionage->{$type}{spies});
    return undef unless defined $saboteur;
    $espionage->{'Counter Espionage'}{rating} += 200;
    miss_a_spy($planet, $saboteur, $cop, $espionage->{_mission_score});
    $planet->add_news(20,'%s authorities on %s are conducting a manhunt for a suspected saboteur.', $planet->empire->name, $planet->name);
}

sub steal_resources {
    my ($planet, $espionage, $quantity) = @_;
    out('Steal Resources');
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $planet->id, task => 'Docked', type => {'in' => ['cargo_ship','smuggler_ship']}});
    for (1..$quantity) {
        my $thief = shift @{$espionage->{'Appropriate Ships'}{spies}};
        last unless defined $thief;
        my $ship = $ships->next;
        last unless defined $ship;
        $espionage->{'Appropriate Ships'}{rating} -= $thief->offense;
        $espionage->{'Counter Espionage'}{rating} += $thief->offense;
        my $home = $thief->from_body;
        $ship->body_id($home->id);
        $ship->body($home);
        $ship->send(
            target      => $planet,
            direction   => 'in',
            payload     => {
                spies => [ $thief->id ],
                resources   => {},
                # FINISH THIS AFTER CARGO SHIPS ARE IMPLEMENTED
            },
        );
        $thief->available_on($ship->date_available->clone);
        $thief->on_body_id($home->id);
        $thief->task('Travelling');
        $thief->things_stolen( $thief->things_stolen + 1 );
        $thief->update;
        $thief->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'ship_theft_report.txt',
            params      => [$ship->type_formatted, $thief->name, $espionage->{_mission_score}],
            ## ATTACH RESOURCE TABLE
        );
        $planet->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'ship_stolen.txt',
            params      => [$ship->type_formatted, $planet->name],
        );
        $planet->add_news(50,'In a daring robbery a thief absconded with a %s from %s today.', $ship->type_formatted, $planet->name);
    }
}

sub steal_ships {
    my ($planet, $espionage, $quantity) = @_;
    out('Steal Ships');
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $planet->id, task => 'Docked', type => {'!=' => 'probe'}});
    for (1..$quantity) {
        my $thief = shift @{$espionage->{'Appropriate Ships'}{spies}};
        last unless defined $thief;
        my $ship = $ships->next;
        last unless defined $ship;
        $espionage->{'Appropriate Ships'}{rating} -= $thief->offense;
        $espionage->{'Counter Espionage'}{rating} += $thief->offense;
        my $home = $thief->from_body;
        $ship->body_id($home->id);
        $ship->body($home);
        $ship->send(
            target      => $planet,
            direction   => 'in',
            payload     => { spies => [ $thief->id ] }
        );
        $thief->available_on($ship->date_available->clone);
        $thief->on_body_id($home->id);
        $thief->things_stolen( $thief->things_stolen + 1 );
        $thief->task('Travelling');
        $thief->update;
        $thief->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'ship_theft_report.txt',
            params      => [$ship->type_formatted, $thief->name, $espionage->{_mission_score}],
        );
        $planet->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'ship_stolen.txt',
            params      => [$ship->type_formatted, $planet->name],
        );
        $planet->add_news(50,'In a daring robbery a thief absconded with a %s from %s today.', $ship->type_formatted, $planet->name);
    }
}

sub steal_building {
    my ($planet, $espionage) = @_;
    out('Steal Building');
    my $thief = random_spy($espionage->{'Appropriate Technology'}{spies});
    return undef unless defined $thief;
    my $level = randint(1,20);
    my $building = $db->resultset('Lacuna::DB::Result::Building')->search(
        { body_id => $planet->id, level => {'>=' => $level}, class => { 'not like' => 'Lacuna::DB::Result::Building::Permanent%' } },
        { rows=>1, order_by => { -desc => 'upgrade_started' }}
        )->single;
    return undef unless defined $building;
    $thief->things_stolen( $thief->things_stolen + 1 );
    $thief->update;
    $thief->from_body->add_plan($building->class, $level);
    $thief->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_theft_report.txt',
        params      => [$level, $building->name, $thief->name, $espionage->{_mission_score}],
    );
}

sub kill_thief {
    my ($planet, $espionage, $type) = @_;
    out('Kill Thief');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $thief = shift @{$espionage->{$type}{spies}};
    return undef unless defined $thief;
    $espionage->{$type}{rating} -= $thief->offense;
    kill_a_spy($planet, $thief, $cop, $espionage->{_mission_score});
    $planet->add_news(70,'%s police caught and killed a thief on %s during the commission of the hiest.', $planet->empire->name, $planet->name);
}

sub capture_thief {
    my ($planet, $espionage, $type) = @_;
    out('Capture Thief');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $thief = shift @{$espionage->{$type}{spies}};
    return undef unless defined $thief;
    $espionage->{$type}{rating} -= $thief->offense;
    capture_a_spy($planet, $thief, $cop, $espionage->{_mission_score});
    $planet->add_news(40,'%s announced the incarceration of a thief on %s today.', $planet->empire->name, $planet->name);
}

sub thwart_thief {
    my ($planet, $espionage, $type) = @_;
    out('Thwart Thief');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $thief = random_spy($espionage->{$type}{spies});
    return undef unless defined $thief;
    miss_a_spy($planet, $thief, $cop, $espionage->{_mission_score});
    $planet->add_news(20,'A thief evaded %s authorities on %s. Citizens are warned to lock their doors.', $planet->empire->name, $planet->name);
}

sub increase_security {
    my ($planet, $espionage, $amount) = @_;
    out('Increase Security');
    $espionage->{'Counter Espionage'}{rating} += $amount;
    $planet->add_news(15,'Officials on %s are ramping up security based on what they call "credible threats".', $planet->name);    
}

sub shut_down_building {
    my ($planet, $espionage) = @_;
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
    $building->offline(DateTime->now->add(randint(60 * 10 , 60 * 60 * 3)));
    $building->update;
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_loss_of_power.txt',
        params      => [$building->name, $planet->name],
    );
    my @spies = pick_a_spy_per_empire($espionage->{'Sabotage Infrastructure'}{spies});
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_disabled_a_building.txt',
            params      => [$building->name, $planet->name, $spy->name, $espionage->{_mission_score}],
        );
    }
    $espionage->{'Counter Espionage'}{rating} += 250;
    $planet->add_news(25,'Employees at the %s on %s were left in the dark today during a power outage.', $building->name, $planet->name);    
}

sub take_control_of_probe {
    my ($planet, $espionage) = @_;
    out('Take Control Of Probe');
    my $spy = random_spy($espionage->{'Appropriate Ships'}{spies});
    return undef unless defined $spy;
    my $probe = $db->resultset('Lacuna::DB::Result::Probes')->search({body_id => $planet->id }, {rows=>1})->single;
    return undef unless defined $probe;
    $probe->body_id($spy->from_body_id);
    $probe->empire_id($spy->empire_id);
    $probe->update;
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_have_taken_control_of_a_probe.txt',
        params      => [$probe->star->name, $planet->empire->name, $spy->name, $espionage->{_mission_score}],
    );
    $spy->things_stolen( $spy->things_stolen + 1 );
    $spy->update;
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$planet->star->name],
    );
    $espionage->{'Counter Espionage'}{rating} += 300;
    $planet->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $planet->empire->name, $probe->star->name);    
}

sub kill_contact_with_mining_platform {
    my ($planet, $espionage) = @_;
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
    my @spies = pick_a_spy_per_empire($espionage->{'Sabotage Infrastructure'}{spies});
    foreach my $spy (@spies) {
        $spy->things_destroyed( $spy->things_destroyed + 1 );
        $spy->update;
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_disabled_a_mining_platform.txt',
            params      => [$asteroid->name, $planet->empire->name, $spy->name, $espionage->{_mission_score}],
        );
    }
    $planet->add_news(50,'The %s controlled mining outpost on %s went dark. Our thoughts are with the miners.', $planet->empire->name, $asteroid->name);    
    $espionage->{'Counter Espionage'}{rating} += 500;
}

sub hack_observatory_probes {
    my ($planet, $espionage) = @_;
    out('Hack Observatory Probes');
    my $probe = $db->resultset('Lacuna::DB::Result::Probes')->search({body_id => $planet->id }, {rows=>1})->single;
    return undef unless defined $probe;
    my @spies = pick_a_spy_per_empire($espionage->{'Sabotage Probes'}{spies});
    foreach my $spy (@spies) {
        $spy->things_destroyed( $spy->things_destroyed + 1 );
        $spy->update;
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_destroyed_a_probe.txt',
            params      => [$probe->star->name, $planet->empire->name, $spy->name, $espionage->{_mission_score}],
        );
    }
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$probe->star->name],
    );
    $probe->delete;
    $espionage->{'Counter Espionage'}{rating} += 200;
    $planet->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $planet->empire->name, $probe->star->name);    
}

sub hack_offending_probes {
    my ($planet, $espionage) = @_;
    out('Hack Offensive Probes');
    return undef unless defined scalar(@{$espionage->{'Counter Espionage'}{spies}});
    my $hacker = random_spy($espionage->{'Sabotage Probes'}{spies});
    return undef unless defined $hacker;
    my @safe = ($planet->empire_id);
    foreach my $cop (@{$espionage->{'Counter Espionage'}{spies}}) {
        push @safe, $cop->empire_id;
    }
    my $probe = $db->resultset('Lacuna::DB::Result::Probes')->search({star_id => $planet->star_id, empire_id => {'not in' => \@safe} }, {rows=>1})->single;
    return undef unless defined $probe;
    my @spies = pick_a_spy_per_empire($espionage->{'Counter Espionage'}{spies});
    foreach my $spy (@spies) {
        $spy->things_destroyed( $spy->things_destroyed + 1 );
        $spy->update;
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_destroyed_a_probe.txt',
            params      => [$planet->star->name, $spy->name, $espionage->{_mission_score}],
        );
    }
    $hacker->empire->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$planet->star->name],
    );
    $probe->delete;
    $planet->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $hacker->empire->name, $planet->star->name);    
}

sub hack_local_probes {
    my ($planet, $espionage) = @_;
    out('Hack Local Probes');
    my $probe = $db->resultset('Lacuna::DB::Result::Probes')->search({star_id => $planet->star_id, empire_id => $planet->empire_id }, {rows=>1})->single;
    return undef unless defined $probe;
    my @spies = pick_a_spy_per_empire($espionage->{'Sabotage Probes'}{spies});
    foreach my $spy (@spies) {
        $spy->things_destroyed( $spy->things_destroyed + 1 );
        $spy->update;
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_destroyed_a_probe.txt',
            params      => [$planet->star->name, $planet->empire->name, $spy->name, $espionage->{_mission_score}],
        );
    }
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$planet->star->name],
    );
    $probe->delete;
    $espionage->{'Counter Espionage'}{rating} += 200;
    $planet->add_news(25,'%s scientists say they have lost control of a research probe in the %s system.', $planet->empire->name, $planet->star->name);    
}

sub colony_report {
    my ($planet, $espionage) = @_;
    out('Colony Report');
    my @spies = pick_a_spy_per_empire($espionage->{'Gather Empire Intelligence'}{spies});
    return undef unless scalar(@spies);
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
    foreach my $spy (@spies) {
    	$spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Colony Report', $planet->name, $spy->name, $espionage->{_mission_score}],
            attach_table=> \@colonies,
        );
    }
}

sub surface_report {
    my ($planet, $espionage) = @_;
    out('Surface Report');
    my @spies = pick_a_spy_per_empire($espionage->{'Gather Empire Intelligence'}{spies});
    return undef unless scalar(@spies);
    my @map;
    my $buildings = $planet->buildings;
    while (my $building = $buildings->next) {
        push @map, {
            image   => $building->image_level,
            x       => $building->x,
            y       => $building->y,
        };
    }
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Surface Report', $planet->name, $spy->name, $espionage->{_mission_score}],
            attach_map  => {
                            surface_image   => $planet->surface,
                            buildings       => \@map
                           },
        );
    }
}

sub spy_report {
    my ($planet, $espionage) = @_;
    out('Spy Report');
    my @spooks = pick_a_spy_per_empire($espionage->{'Gather Operative Intelligence'}{spies});
    return undef unless scalar(@spooks);
    my @peeps = (['From','Assignment']);
    my %planets = ( $planet->id => $planet->name );
    my @spies = shuffle(@{get_full_spies_list($espionage)});
    while (my $spy = pop @spies) {
        unless (exists $planets{$spy->from_body_id}) {
            $planets{$spy->from_body_id} = $spy->from_body->name;
        }
        push @peeps, [$planets{$spy->from_body_id}, $spy->task];
    }
    foreach my $spook (@spooks) {
        $spook->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Spy Report', $planet->name, $spook->name, $espionage->{_mission_score}],
            attach_table=> \@peeps,
        );
    }
}

sub economic_report {
    my ($planet, $espionage) = @_;
    out('Economic Report');
    my @spies = pick_a_spy_per_empire($espionage->{'Gather Empire Intelligence'}{spies});
    return undef unless scalar(@spies);
    my @resources = (['Resource', 'Per Hour', 'Stored']);
    push @resources, [ 'Food', $planet->food_hour, $planet->food_stored ];
    push @resources, [ 'Water', $planet->water_hour, $planet->water_stored ];
    push @resources, [ 'Energy', $planet->energy_hour, $planet->energy_stored ];
    push @resources, [ 'Ore', $planet->ore_hour, $planet->ore_stored ];
    push @resources, [ 'Waste', $planet->waste_hour, $planet->waste_stored ];
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Economic Report', $planet->name, $spy->name, $espionage->{_mission_score}],
            attach_table=> \@resources,
        );
    }
}

sub travel_report {
    my ($planet, $espionage) = @_;
    out('Travel Report');
    my @spies = pick_a_spy_per_empire($espionage->{'Gather Shipping Intelligence'}{spies});
    return undef unless scalar(@spies);
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
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Travel Report', $planet->name, $spy->name, $espionage->{_mission_score}],
            attach_table=> \@travelling,
        );
    }
}

sub ship_report {
    my ($planet, $espionage) = @_;
    out('Ship Report');
    my @spies = pick_a_spy_per_empire($espionage->{'Gather Shipping Intelligence'}{spies});
    return undef unless scalar(@spies);
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $planet->id, task => 'Docked'});
    my @ships = (['Name', 'Type', 'Speed', 'Hold Size']);
    while (my $ship = $ships->next) {
        push @ships, [$ship->name, $ship->type_formatted, $ship->speed, $ship->hold_size];
    }
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Docked Ships Report', $planet->name, $spy->name, $espionage->{_mission_score}],
            attach_table=> \@ships,
        );
    }
}

sub build_queue_report {
    my ($planet, $espionage) = @_;
    out('Build Queue Report');
    my @spies = pick_a_spy_per_empire($espionage->{'Gather Empire Intelligence'}{spies});
    return undef unless scalar(@spies);
    my @report = (['Building', 'Level', 'Expected Completion']);
    my $builds = $planet->builds;
    while (my $build = $builds->next) {
        push @report, [
            $build->name,
            $build->level + 1,
            format_date($build->upgrade_ends),
        ];
    }
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Build Queue Report', $planet->name, $spy->name, $espionage->{_mission_score}],
            attach_table=> \@report,
        );
    }
}

sub false_interrogation_report {
    my ($planet, $espionage) = @_;
    out('False Interrogation Report');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $suspect = random_spy($espionage->{'Captured'}{spies});
    return undef unless defined $suspect;
    my $suspect_home = $suspect->from_body;
    my $suspect_empire = $suspect->empire;
    my $suspect_species = $suspect_empire->species;
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Interrogation Report', $planet->name, $cop->name, $espionage->{_mission_score}],
        attach_table=> [
            ['Question', 'Response'],
            ['Name', $suspect->name],
            ['Offense Rating', randint(0,27)],
            ['Defense Rating', randint(0,27)],
            ['Allegiance', $suspect_empire->name],
            ['Home World', $suspect_home->name],
            ['Species Name', $suspect_species->name],
            ['Species Description', $suspect_species->description],
            ['Habitable Orbits', randint(1,7)],
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
    my ($planet, $espionage) = @_;
    out('Interrogation Report');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $suspect = random_spy($espionage->{'Captured'}{spies});
    return undef unless defined $suspect;
    my $suspect_home = $suspect->from_body;
    my $suspect_empire = $suspect->empire;
    my $suspect_species = $suspect_empire->species;
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Interrogation Report', $planet->name, $cop->name, $espionage->{_mission_score}],
        attach_table=> [
            ['Question', 'Response'],
            ['Name', $suspect->name],
            ['Offense Rating', $suspect->offense],
            ['Defense Rating', $suspect->defense],
            ['Allegiance', $suspect_empire->name],
            ['Home World', $suspect_home->name],
            ['Species Name', $suspect_species->name],
            ['Species Description', $suspect_species->description],
            ['Habitable Orbits', join(', ', @{$suspect_species->habitable_orbits})],
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
    my ($planet, $espionage) = @_;
    out('Kill Guard and Escape Prison');
    my $cop = shift @{$espionage->{'Counter Espionage'}{spies}};
    return undef unless defined $cop;
    my $suspect = shift @{$espionage->{'Captured'}{spies}};
    return undef unless defined $suspect;
    $espionage->{'Counter Espionage'}{rating} -= $cop->offense;
    kill_a_spy($planet, $cop, $suspect, $espionage->{_mission_score});
    escape_a_spy($planet, $suspect, $espionage->{_mission_score});
    $planet->add_news(70,'An inmate killed his interrogator, and escaped the prison on %s today.', $planet->name);
}

sub escape_prison {
    my ($planet, $espionage) = @_;
    out('Escape Prison');
    my $suspect = shift @{$espionage->{'Captured'}{spies}};
    return undef unless defined $suspect;
    escape_a_spy($planet, $suspect,$espionage->{_mission_score});
    $planet->add_news(50,'At this hour police on %s are flabbergasted as to how an inmate escaped earlier in the day.', $planet->name);    
}

sub kill_suspect {
    my ($planet, $espionage) = @_;
    out('Kill Suspect');
    my $suspect = shift @{$espionage->{'Captured'}{spies}};
    return undef unless defined $suspect;
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    kill_a_spy($planet, $suspect, $cop, $espionage->{_mission_score});
    $planet->add_news(50,'Allegations of police brutality are being made on %s after an inmate was killed in custody today.', $planet->name);
}

sub capture_rescuer {
    my ($planet, $espionage) = @_;
    out('Capture Rescuer');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $intel = shift @{$espionage->{'Rescue Comrades'}{spies}};
    return undef unless defined $intel;
    $espionage->{'Rescue Comrades'}{rating} -= $intel->offense;
    capture_a_spy($planet, $intel, $cop, $espionage->{_mission_score});
    $planet->add_news(60,'%s was caught trying to break into prison today on %s. Police insisted he stay.', $intel->name, $planet->name);
}

sub thwart_intelligence {
    my ($planet, $espionage, $type) = @_;
    out('Thwart Intelligence Agent');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $intel = random_spy($espionage->{$type}{spies});
    return undef unless defined $intel;
    miss_a_spy($planet, $intel, $cop, $espionage->{_mission_score});
    $planet->add_news(25,'Corporate espionage has become a real problem on %s.', $planet->name);
}

sub counter_intel_report {
    my ($planet, $espionage) = @_;
    out('Counter Intelligence Report');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my @peeps = (['Name','From','Assignment']);
    my %planets = ( $planet->id => $planet->name );
    my @spies = shuffle(@{get_full_spies_list($espionage)});
    while (my $spy = pop @spies) {
        next if ($spy->empire_id eq $planet->empire_id); # skip our own
        unless (exists $planets{$spy->from_body_id}) {
            $planets{$spy->from_body_id} = $spy->from_body->name;
        }
        push @peeps, [$spy->name, $planets{$spy->from_body_id}, $spy->task];
    }
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Counter Intelligence Report', $planet->name, $cop->name, $espionage->{_mission_score}],
        attach_table=> \@peeps,
    );
}

sub kill_cop {
    my ($planet, $espionage, $enemy) = @_;
    out('Kill Cop');
    my $spy = random_spy($espionage->{$enemy}{spies});
    my $cop = shift @{$espionage->{'Counter Espionage'}{spies}};
    return undef unless defined $cop;
    $espionage->{'Counter Espionage'}{rating} += 1000 - $cop->defense;
    $planet->add_news(60,'An officer named %s was killed in the line of duty on %s.', $cop->name, $planet->name);
    kill_a_spy($planet, $cop, $spy, $espionage->{_mission_score});
}

sub kill_cops {
    my ($planet, $espionage, $quantity) = @_;
    out('Kill Cops');
    my $spy = random_spy($espionage->{'Assassinate Operatives'}{spies});
    return undef unless defined $spy;
    foreach (1..$quantity) {
        my $cop = shift @{$espionage->{'Counter Espionage'}{spies}};
        last unless defined $cop;
        $espionage->{'Counter Espionage'}{rating} += 1000 - $cop->defense;
        kill_a_spy($planet, $cop, $spy, $espionage->{_mission_score});
    }
    $planet->add_news(75,'At this hour, a group of government officials were gunned down in cold blood on %s as onlookers watched in horror.', $planet->name);
}

sub kill_intelligence {
    my ($planet, $espionage, $quantity) = @_;
    out('Kill Intelligence Agents');
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    foreach (1..$quantity) {
        my $intel = shift @{$espionage->{intel}{spies}};
        last unless defined $intel;
        $espionage->{intel}{score} -= $intel->offense;
        kill_a_spy($planet, $intel, $cop, $espionage->{_mission_score});
    }
    $planet->add_news(60,'A suspected spy was killed in a struggle with police on %s today.', $planet->name);
}

sub capture_hacker {
    my ($planet, $espionage) = @_;
    out('Capture Hacker');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $hacker = shift @{$espionage->{'Hack Network 19'}{spies}};
    return undef unless defined $hacker;
    $espionage->{'Hack Network 19'}{rating} -= $hacker->offense;
    $planet->add_news(30,'Alleged hacker %s is awaiting arraignment on %s today.', $hacker->name, $planet->name);
    capture_a_spy($planet, $hacker, $cop, $espionage->{_mission_score});
}

sub kill_hacker {
    my ($planet, $espionage) = @_;
    out('Kill Hacker');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $hacker = shift @{$espionage->{'Sabotage Probes'}{spies}};
    return undef unless defined $hacker;
    $espionage->{'Sabotage Probes'}{rating} -= $hacker->offense;
    $planet->add_news(60,'A suspected hacker, age '.randint(16,60).', was found dead in his home today on %s.', $planet->name);
    kill_a_spy($planet, $hacker, $cop, $espionage->{_mission_score});    
}

sub thwart_hacker {
    my ($planet, $espionage) = @_;
    out('Thwart Hacker');
    my $cop = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $cop;
    my $hacker = shift @{$espionage->{'Hack Network 19'}{spies}};
    return undef unless defined $hacker;
    miss_a_spy($planet, $hacker, $cop, $espionage->{_mission_score});
    $planet->add_news(10,'Identity theft has become a real problem on %s.', $planet->name);  
    $espionage->{'Counter Espionage'}{rating} += 3;
}

sub network19_propaganda1 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 1');
    my $spy = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'A resident of %s has won the Lacuna Expanse talent competition.', $planet->name)) {
        $planet->add_happiness(250)->update;
    }
}

sub network19_propaganda2 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 2');
    my $spy = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'The economy of %s is looking strong, showing GDP growth of nearly 10%% for the past quarter.',$planet->name)) {
        $planet->add_happiness(500)->update;
    }
}

sub network19_propaganda3 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 3');
    my $spy = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'The Governor of %s has set aside 1000 square kilometers as a nature preserve.', $planet->name)) {
        $planet->add_happiness(750)->update;
    }
}

sub network19_propaganda4 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 4');
    my $spy = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'If %s had not inhabited %s, the planet would likely have reverted to a barren rock.', $planet->empire->name, $planet->name)) {
        $planet->add_happiness(1000)->update;
    }
}

sub network19_propaganda5 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 5');
    my $spy = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'The benevolent leader of %s is a gift to the people of %s.', $planet->empire->name, $planet->name)) {
        $planet->add_happiness(1250)->update;
    }
}

sub network19_propaganda6 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 6');
    my $spy = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'%s is the greatest, best, most free empire in the Expanse, ever.', $planet->empire->name)) {
        $planet->add_happiness(1500)->update;
    }
}

sub network19_propaganda7 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 7');
    my $spy = random_spy($espionage->{'Counter Espionage'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'%s is the ultimate power in the Expanse right now. It is unlikely to be challenged any time soon.', $planet->empire->name)) {
        $planet->add_happiness(1750)->update;
    }
}

sub network19_defamation1 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 1');
    my $spy = random_spy($espionage->{'Hack Network 19'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'A financial report for %s shows that many people are out of work as the unemployment rate approaches 10%%.', $planet->name)) {
        $planet->spend_happiness(250)->update;
    }
}

sub network19_defamation2 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 2');
    my $spy = random_spy($espionage->{'Hack Network 19'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'An outbreak of the Dultobou virus was announced on %s today. Citizens are encouraged to stay home from work and school.', $planet->name)) {
        $planet->spend_happiness(500)->update;
    }
}

sub network19_defamation3 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 3');
    my $spy = random_spy($espionage->{'Hack Network 19'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'%s is unable to keep its economy strong. Sources inside say it will likely fold in a few days.', $planet->empire->name)) {
        $planet->spend_happiness(750)->update;
    }
}

sub network19_defamation4 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 4');
    my $spy = random_spy($espionage->{'Hack Network 19'}{spies});
    return undef unless defined $spy;
    $spy->seeds_planted($spy->seeds_planted + 1);
    $spy->update;
    if ($planet->add_news(50,'The Governor of %s has lost her mind. She is a raving mad lunatic! The Emperor could not be reached for comment.', $planet->name)) {
        $planet->spend_happiness(1250)->update;
    }
}

sub network19_defamation5 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 5');
    my $spy = random_spy($espionage->{'Hack Network 19'}{spies});
    return undef unless defined $spy;
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
    my $steal = my $sabotage = my $interception = my $rebel = my $hack = my $intel = 0;
    my (@thieves, @saboteurs, @interceptors, @spies, @hackers, @rebels, @idle, @prisoners, @trainees, @travellers);
    my $spies = $db->resultset('Lacuna::DB::Result::Spies')->search(
        {
            on_body_id  => $planet->id,
        }
    );
    my %espionage = ( _has_spies => 0, 'Counter Espionage' => { rating => 10 } );        # there's always a small chance of defense
    while (my $spy = $spies->next) {
        $espionage{_has_spies} = 1;
        if ($spy->task eq 'Counter Espionage') {                                        # use defense
            $espionage{$spy->task}{rating} += $spy->defense;
            push @{$espionage{$spy->task}{spies}}, $spy;
        }
        elsif ($spy->empire_id ne $planet->empire_id ) {                                # can't attack yourself
            $espionage{$spy->task}{rating} += $spy->offense;
            push @{$espionage{$spy->task}{spies}}, $spy;
        }
    }
    return \%espionage;
}

sub kill_a_spy {
    my ($planet, $spy, $interceptor, $score) = @_;
    $interceptor->spies_killed( $interceptor->spies_killed + 1 );
    $interceptor->update;
    $interceptor->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_killed_a_spy.txt',
        params      => [$planet->name, $interceptor->name, $score],
        from        => $interceptor->empire,
    );
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_killed.txt',
        params      => [$spy->name, $planet->name],
    );
    $spy->delete;
}

sub capture_a_spy {
    my ($planet, $spy, $interceptor, $score) = @_;
    $spy->available_on(DateTime->now->add(months=>1));
    $spy->task('Captured');
    $spy->started_assignment(DateTime->now);
    $spy->times_captured( $spy->times_captured + 1 );
    $spy->update;
    $interceptor->spies_captured( $spy->spies_captured + 1 );
    $interceptor->update;
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_captured.txt',
        params      => [$planet->name, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_captured_a_spy.txt',
        params      => [$planet->name, $interceptor->name, $score],
        from        => $interceptor->empire,
    );
}

sub miss_a_spy {
    my ($planet, $spy, $interceptor, $score) = @_;
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'narrow_escape.txt',
        params      => [$planet->empire->name, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_missed_a_spy.txt',
        params      => [$planet->name, $interceptor->name, $score],
        from        => $interceptor->empire,
    );
}

sub escape_a_spy {
    my ($planet, $spy, $score) = @_;
    $spy->available_on(DateTime->now);
    $spy->task('Idle');
    $spy->update;
    my $evil_empire = $planet->empire;
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'i_have_escaped.txt',
        params      => [$evil_empire->name, $spy->name, $score],
    );
    $evil_empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'you_cant_hold_me.txt',
        params      => [$spy->name],
    );
}

sub turn_a_spy {
    my ($planet, $traitor, $spy, $score) = @_;
    my $evil_empire = $planet->empire;
    $spy->spies_turned( $spy->spies_turned + 1 );
    $spy->update;
    $traitor->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'goodbye.txt',
        params      => [$traitor->name],
    );
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'new_recruit.txt',
        params      => [$traitor->empire->name, $traitor->name, $spy->name, $score],
    );
    # could be abused to get lots of extra spies, may have to add a check for that.
    $traitor->times_turned( $traitor->times_turned + 1 );
    $traitor->task('Idle');
    $traitor->empire_id($spy->empire_id);
    $traitor->from_body_id($spy->from_body_id);
    $traitor->update;
}

sub pick_a_spy_per_empire {
    my ($spies) = @_;
    my %empires;
    foreach my $spy (@{$spies}) {
        unless (exists $empires{$spy->empire_id}) {
            $empires{$spy->empire_id} = $spy;
        }
    }
    return values %empires;
}

sub add_offense_xp {
    my ($spies, $amount) = @_;
    foreach my $spy (@{$spies}) {
        $spy->offense( $spy->offense + $amount );
    }
}

sub add_defense_xp {
    my ($spies, $amount) = @_;
    foreach my $spy (@{$spies}) {
        $spy->defense( $spy->defense + $amount );
    }
}

sub increment_offense_mission_count {
    my ($spies, $victorious) = @_;
    foreach my $spy (@{$spies}) {
        $spy->offense_mission_count( $spy->offense_mission_count + 1 );
        $spy->offense_mission_successes( $spy->offense_mission_successes + 1) if $victorious;
    }
}

sub increment_defense_mission_count {
    my ($spies, $victorious) = @_;
    foreach my $spy (@{$spies}) {
        $spy->defense_mission_count( $spy->defense_mission_count + 1 );
        $spy->defense_mission_successes( $spy->defense_mission_successes + 1) if $victorious;
    }
}

sub update_mission_score {
    my ($spies, $score) = @_;
    foreach my $spy (@{$spies}) {
        $spy->last_mission_score($score);
    }
}

sub save_changes_to_spies {
    my ($spies) = @_;
    foreach my $spy (@{$spies}) {
        $spy->update;
    }
}

sub calculate_mission_score {
    my ($espionage, $type, $offense_modifier) = @_;
    out('Mission: '.$type);

    # no battle unless somemone is attacking
    if ($espionage->{$type}{rating} == 0) {
        out('Espionage Suspended');
        $espionage->{_mission_score} = 0;
        return 0;
    }

   ## determine scoring
    my $offense = $espionage->{$type}{rating} + ($espionage->{$type}{rating} * ($offense_modifier / 100));
    my $defense = $espionage->{'Counter Espionage'}{rating};
    out('Offense Rating: '.$offense);
    out('Defense Rating: '.$defense);

   ## determine victory 
    my $score = randint(0, $offense) - randint(0, $defense);
    out('Mission Score: '.$score);
    increment_offense_mission_count($espionage->{$type}{spies}, ($score > 0));
    increment_defense_mission_count($espionage->{'Counter Espionage'}{spies}, ($score < 0));
    update_mission_score($espionage->{$type}{spies}, $score);
    update_mission_score($espionage->{'Counter Espionage'}{spies}, $score);
    
   ## determine experience
    my $xp;
    my $max_range = 4;                                              # 300%
    if ($score > 0) { 						                        # offense wins
        if ($offense < $defense) {                             		# offense was underdog
            $xp++; 							                        # win david vs goliath
            for my $range (2..$max_range) {				            # wins within close range
            	$xp++ if ($offense * $range >= $defense);   		# extra points for being closely matched
            }
        }
        else {								                        # offense was favored to win
            for my $range (2..$max_range) {				            # wins within close range
            	$xp++ if ($defense * $range >= $offense);   		# extra points for being closely matched
            }
        }
        add_offense_xp($espionage->{$type}{spies}, $xp);
    }
    else { 								                            # defense wins
        if ($offense > $defense) {                             		# defense was underdog
            $xp++; 							                        # win david vs goliath
            for my $range (2..$max_range) {				            # wins within close range
            	$xp++ if ($defense * $range >= $offense);   		# extra points for being closely matched
            }
        }
        else {								                        # defense was favored to win
            for my $range (2..$max_range) {				            # wins within close range
            	$xp++ if ($offense * $range >= $defense);   		# extra points for being closely matched
            }
        }
        add_defense_xp($espionage->{'Counter Espionage'}{spies}, $xp);
    }
    
   ## save
    save_changes_to_spies($espionage->{$type}{spies});
    save_changes_to_spies($espionage->{'Counter Espionage'}{spies});
    $espionage->{_mission_score} = $score;
    return $score;
}

sub get_full_spies_list {
    my ($espionage) = @_;
    my @spies;
    foreach my $type (keys %{$espionage}) {
        next if $type =~ m/^_/;
        @spies = (@spies, @{$espionage->{$type}});
    }
    return \@spies;
}

# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


