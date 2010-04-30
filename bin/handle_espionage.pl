use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date to_seconds);
use Getopt::Long;

our $skip_sleep;
our $quiet;

GetOptions(
    'skip-sleep'    => \$skip_sleep,  
    'quiet'         => \$quiet,  
);


my $start = DateTime->now;
out('Started');

unless ($skip_sleep) { # start at a random interval
    my $sleep = randint(1,1800);
    out("sleeping $sleep seconds to provide a random interval for espionage");
    sleep(randint(1,1800));
}

out('Loading config and DB');
my $config = Lacuna->config;
our $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached')); 

out('Processing planets');
my $planets = $db->domain('Lacuna::DB::Body::Planet')->search(
    where   => {
        empire_id   => ['!=', 'None'],
    }
);

while (my $planet = $planets->next) {
    out('Ticking '.$planet->name);
    $planet->tick;
    my $espionage = determine_espionage($planet);
    intel($planet, $espionage);
    hack($planet, $espionage);
    steal($planet, $espionage);
    sabotage($splanet, $espionage);
    rebel($planet, $espionage);
}

my $finish = DateTime->now;
out('Finished');
out((to_seconds($finish - $start)/60)." minutes have elapsed");


###############
## SUBROUTINES
###############

# MISSIONS

sub intel {
    my ($planet, $espionage) = @_;
    out('Intellgence Missions');
    my $mission = calculate_mission_score($espionage, 'intel');
    if ($mission < -50) {
        counter_intel_report($planet, $espionage, 50);
    }
    elsif ($mission < -45) {
        counter_intel_report($planet, $espionage, 40);
    }
    elsif ($mission < -40) {
        counter_intel_report($planet, $espionage, 30);
    }
    elsif ($mission < -35) {
        counter_intel_report($planet, $espionage, 20);
    }
    elsif ($mission < -30) {
        capture_intelligence($planet, $espionage);
    }
    elsif ($mission < -25) {
        interrogation_report($planet, $espionage);
    }
    elsif ($mission < -20) {
        counter_intel_report($planet, $espionage, 10);
    }
    elsif ($mission < -15) {
        kill_intelligence($planet, $espionage);
    }
    elsif ($mission < -10) {
        thwart_intelligence($planet, $espionage);
    }
    elsif ($mission < -5 ) {
        kill_suspect($planet, $espionage);
    }
    elsif ($mission < 5) {
        # nothing
    }
    elsif ($mission < 5 ) {
        false_interrogation_report($planet, $espionage);
    }
    elsif ($mission < 10 ) {
        escape_prison($planet, $espionage);
    }
    elsif ($mission < 15 ) {
        kill_guard_and_escape_prison($planet, $espionage);
    }
    elsif ($mission < 20 ) {
        build_queue_report($planet, $espionage);
    }
    elsif ($mission < 25 ) {
        ship_report($planet, $espionage);
    }
    elsif ($mission < 30 ) {
        travel_report($planet, $espionage);
    }
    elsif ($mission < 35 ) {
        economic_report($planet, $espionage);
    }
    elsif ($mission < 40 ) {
        spy_report($planet, $espionage);
    }
    elsif ($mission < 45 ) {
        surface_report($planet, $espionage);
    }
    elsif ($mission < 50 ) {
        colony_report($planet, $espionage);
    }
    else {
        kill_cop($planet, $espionage, 'intel'); 
    }
}

sub hack {
    my ($planet, $espionage) = @_;
    out('Hacking Missions');
    my $mission = calculate_mission_score($espionage, 'hacking');
    if ($mission < -55) {
        network19_prapaganda7($planet, $espionage);
    }
    elsif ($mission < -50) {
        network19_prapaganda6($planet, $espionage);
    }
    elsif ($mission < -45) {
        network19_prapaganda5($planet, $espionage);
    }
    elsif ($mission < -40) {
        network19_prapaganda4($planet, $espionage);
    }
    elsif ($mission < -35) {
        network19_prapaganda3($planet, $espionage);
    }
    elsif ($mission < -30) {
        hack_offending_probes($planet, $espionage);
    }
    elsif ($mission < -25) {
        capture_hacker($planet, $espionage);
    }
    elsif ($mission < -20) {
        network19_prapaganda2($planet, $espionage);
    }
    elsif ($mission < -15) {
        kill_hacker($planet, $espionage);
    }
    elsif ($mission < -10) {
        network19_propaganda1($planet, $espionage);
    }
    elsif ($mission < -5) {
        thwart_hacker($planet, $espionage);
    }
    elsif ($mission < 5) {
        # nothing    
    }
    elsif ($mission < 10) {
        network19_defamation1($planet, $espionage);
    }
    elsif ($mission < 15) {
        hack_local_probes($planet);
    }
    elsif ($mission < 20) {
        network19_defamation2($planet, $espionage);
    }
    elsif ($mission < 25) {
        hack_observatory_probes($planet);
    }
    elsif ($mission < 30) {
        network19_defamation3($planet, $espionage);
    }
    elsif ($mission < 35) {
        network19_defamation4($planet, $espionage);
    }
    elsif ($mission < 40) {
        kill_contact_with_mining_platform($planet, $espionage);
    }
    elsif ($mission < 45) {
        take_control_of_probe($planet, $espionage);
    }
    elsif ($mission < 50) {
        network19_defamation5($planet, $espionage);
    }
    elsif ($mission < 55) {
        shut_down_building($planet, $espionage);
    }
    else {
        kill_cop($planet, $espionage, 'hacking');
    }
}

sub steal {
    my ($planet, $espionage) = @_;
    out('Theft Missions');
    my $mission = calculate_mission_score($espionage, 'theft');
    if ($mission < -50) {
        increase_security($planet, $espionage, 50);
    }
    elsif ($mission < -45) {
        increase_security($planet, $espionage, 45);
    }
    elsif ($mission < -40) {
        increase_security($planet, $espionage, 40);
    }
    elsif ($mission < -35) {
        increase_security($planet, $espionage, 35);
    }
    elsif ($mission < -30) {
        capture_thief($planet, $espionage);
    }
    elsif ($mission < -25) {
        increase_security($planet, $espionage, 25);
    }
    elsif ($mission < -20) {
        increase_security($planet, $espionage, 20);
    }
    elsif ($mission < -15) {
        kill_thief($planet, $espionage);
    }
    elsif ($mission < -10) {
        increase_security($planet, $espionage, 10);
    }
    elsif ($mission < -5) {
        thwart_thief($planet, $espionage);
    }
    elsif ($mission < 5) {
        # nothing
    }
    elsif ($mission < 10) {
        steal_building($planet, $espionage,3);
    }
    elsif ($mission < 15) {
        steal_building($planet, $espionage,6);
    }
    elsif ($mission < 20) {
        steal_ships($planet, $espionage, 1);
    }
    elsif ($mission < 25) {
        steal_building($planet, $espionage,10);
    }
    elsif ($mission < 30) {
        steal_resources($planet, $espionage,1);
    }
    elsif ($mission < 35) {
        steal_building($planet, $espionage,20);
    }
    elsif ($mission < 40) {
        steal_ships($planet, $espionage, 3);
    }
    elsif ($mission < 45) {
        steal_resources($planet, $espionage,2);
    }
    elsif ($mission < 50) {
        steal_building($planet, $espionage,100);
    }
    else {
        kill_cop($planet, $espionage, 'theft')
    }
}

sub sabotage {
    my ($planet, $espionage) = @_;
    out('Sabotage Missions');
    my $mission = calculate_mission_score($espionage, 'sabotage');
    if ($mission < -50) {
        capture_saboteurs($planet, $espionage,6);
    }
    elsif ($mission < -45) {
        capture_saboteurs($planet, $espionage,5);
    }
    elsif ($mission < -40) {
        capture_saboteurs($planet, $espionage,4);
    }
    elsif ($mission < -35) {
        capture_saboteurs($planet, $espionage,3);
    }
    elsif ($mission < -30) {
        capture_saboteurs($planet, $espionage,2);
    }
    elsif ($mission < -25) {
        capture_saboteur($planet, $espionage);
    }
    elsif ($mission < -20) {
        kill_saboteurs($planet, $espionage, 3);
    }
    elsif ($mission < -15) {
        kill_saboteurs($planet, $espionage, 2);
    }
    elsif ($mission < -10) {
        kill_saboteur($planet, $espionage);
    }
    elsif ($mission < -5) {
        thwart_saboteur($planet, $espionage);
    }
    elsif ($mission < 5) {
        # nothing
    }
    elsif ($mission < 10) {
        destroy_mining_ship($planet, $espionage);
    }
    elsif ($mission < 15) {
        destroy_ship($planet, $espionage);
    }
    elsif ($mission < 20) {
        destroy_ships($planet, $espionage, 2);
    }
    elsif ($mission < 25) {
        destroy_upgrade($planet, $espionage);
    }
    elsif ($mission < 30) {
        destroy_ships($planet, $espionage,3);
    }
    elsif ($mission < 35) {
        destroy_upgrades($planet, $espionage, 2);
    }
    elsif ($mission < 40) {
        destroy_infrastructure($planet, $espionage, 1);
    }
    elsif ($mission < 45) {
        destroy_infrastructure($planet, $espionage, 2);
    }
    elsif ($mission < 50) {
        destroy_infrastructure($planet, $espionage, 3);
    }
    else {
        kill_cop($planet, $espionage, 'sabotage');
    }
}

sub rebel {
    my ($planet, $espionage) = @_;
    out('Rebellion Missions');
    my $mission = calculate_mission_score($espionage, 'rebellion');
    if ($mission < -50) {
        turn_rebels($planet, $espionage,3);
    }
    elsif ($mission < -45) {
        turn_rebels($planet, $espionage,2);
    }
    elsif ($mission < -40) {
        turn_rebel($planet, $espionage,1);
    }
    elsif ($mission < -35) {
        day_of_rest($planet, $espionage);
    }
    elsif ($mission < -30) {
        festival($planet, $espionage);
    }
    elsif ($mission < -25) {
        capture_rebel($planet, $espionage);
    }
    elsif ($mission < -20) {
        kill_rebel($planet, $espionage);
    }
    elsif ($mission < -15) {
        thwart_rebellion($planet, $espionage);
    }
    elsif ($mission < -10) {
        peace_talks($planet, $espionage);
    }
    elsif ($mission < -5) {
        calm_the_rebels($planet, $espionage);
    }
    elsif ($mission < 5) {
        # nothing
    }
    elsif ($mission < 10) {
        civil_unrest($planet, $espionage);
    }
    elsif ($mission < 15) {
        protest($planet, $espionage);
    }
    elsif ($mission < 20) {
        strike($planet, $espionage);
    }
    elsif ($mission < 25) {
        violent_protest($planet, $espionage);
    }
    elsif ($mission < 30) {
        small_rebellion($planet, $espionage);
    }
    elsif ($mission < 35) {
        kill_cop($planet, $espionage, 'rebellion');
    }
    elsif ($mission < 40) {
        turn_cops($planet, $espionage,1);
    }
    elsif ($mission < 45) {
        turn_cops($planet, $espionage,2);
    }
    elsif ($mission < 50) {
        turn_cops($planet, $espionage,3);
    }
    else {
        uprising($planet, $espionage);
    }
}



# OUTCOMES

sub shut_down_building {
    my ($planet, $espionage) = @_;
    out('Shut Down Building');
    my @classnames = (
        'Lacuna::DB::Building::PlanetaryCommand',
        'Lacuna::DB::Building::Shipyard',
        'Lacuna::DB::Building::Waste::Recycling',
        'Lacuna::DB::Building::Development',
        'Lacuna::DB::Building::Intelligence',
        'Lacuna::DB::Building::Trade',
        'Lacuna::DB::Building::Transporter',
    );
    my $building_class = @classnames[randint(0,6)];
    my $building = $planet->get_building_of_class($building_class);
    return undef unless defined $building;
    $building->offline(DateTime->now->add(randint(600,3600)));
    $building->put;
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_loss_of_power.txt',
        params      => [$building->name, $planet->name],
    );
    my @spies = pick_a_spy_per_empire($espionage->{hacking}{spies});
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_disabled_a_building.txt',
            params      => [$building->name, $planet->name, $spy->name],
        );
    }
    $planet->add_news(25,'Employees at the %s on %s were left in the dark today during a power outage.', $building->name, $planet->name);    
}

sub take_control_of_probe {
    my ($planet, $espionage) = @_;
    out('Take Control Of Probe');
    my $spy = random_spy($espionage->{hacking}{spies});
    return undef unless defined $spy;
    my $probe = $db->domain('probes')->search(where=>{body_id => $planet->id }, limit=>1)->next;
    return undef unless defined $probe;
    $probe->body_id($spy->from_body_id);
    $probe->empire_id($spy->empire_id);
    $probe->put;
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_have_taken_control_of_a_probe.txt',
        params      => [$probe->star->name, $planet->empire->name, $spy->name],
    );
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$planet->star->name],
    );
    $espionage->{police}{score} += 5;
    $planet->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $planet->empire->name, $probe->star->name);    
}

sub kill_contact_with_mining_platform {
    my ($planet, $espionage) = @_;
    out('Kill Contact With Mining Platform');
    my $ministry = $planet->mining_ministry;
    return undef unless defined $ministry;
    my $platform = $ministry->asteroid_ids->[0];
    return undef unless defined $platform;
    my $asteroid = $db->domain('Lacuna::DB::Body::Asteroid')->find($platform);
    return undef unless defined $asteroid;
    $ministry->remove_platform($asteroid);
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'we_lost_contact_with_a_mining_platform.txt',
        params      => [$asteroid->name],
    );
    my @spies = pick_a_spy_per_empire($espionage->{hacking}{spies});
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_disabled_a_mining_platform.txt',
            params      => [$asteroid->name, $planet->empire->name, $spy->name],
        );
    }
    $planet->add_news(50,'The %s controlled mining outpost on %s went dark. Our thoughts are with the miners.', $planet->empire->name, $asteroid->name);    
    $espionage->{police}{score} += 5;
}

sub hack_observatory_probes {
    my ($planet, $espionage) = @_;
    out('Hack Observatory Probes');
    my $probe = $db->domain('probes')->search(where=>{body_id => $planet->id }, limit=>1)->next;
    return undef unless defined $probe;
    my @spies = pick_a_spy_per_empire($espionage->{hacking}{spies});
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_destroyed_a_probe.txt',
            params      => [$probe->star->name, $planet->empire->name, $spy->name],
        );
    }
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$probe->star->name],
    );
    $probe->delete;
    $espionage->{police}{score} += 5;
    $planet->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $planet->empire->name, $probe->star->name);    
}

sub hack_offending_probes {
    my ($planet, $espionage) = @_;
    out('Hack Offensive Probes');
    my $hacker = random_spy($espionage->{hacking}{spies});
    return undef unless defined $spy;
    my $probe = $db->domain('probes')->search(where=>{star_id => $planet->star_id, empire_id => ['!=', $hacker->empire_id] }, limit=>1)->next;
    return undef unless defined $probe;
    $hacker->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_destroyed_a_probe.txt',
        params      => [$planet->star->name, $hacker->name],
    );
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
    my $probe = $db->domain('probes')->search(where=>{star_id => $planet->star_id, empire_id => $planet->empire_id }, limit=>1)->next;
    return undef unless defined $probe;
    my @spies = pick_a_spy_per_empire($espionage->{hacking}{spies});
    foreach my $spy (@spies) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'we_destroyed_a_probe.txt',
            params      => [$planet->star->name, $planet->empire->name, $spy->name],
        );
    }
    $planet->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$planet->star->name],
    );
    $probe->delete;
    $espionage->{police}{score} += 5;
    $planet->add_news(25,'%s scientists say they have lost control of a research probe in the %s system.', $planet->empire->name, $planet->star->name);    
}

sub colony_report {
    my ($planet, $espionage) = @_;
    out('Colony Report');
    my $spy = random_spy($espionage->{intel}{spies});
    return undef unless defined $spy;
    my @colonies = (['Name','X','Y','Z','Orbit']);
    my $planets = $planet->empire->planets;
    while (my $colony = $planets->next) {
        push @colonies, [
            $colony->name,
            $colony->x,
            $colony->y,
            $colony->z,
            $colony->orbit,
        ];
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Colony Report', $spy->name],
        attach_table=> \@colonies,
    );
}

sub surface_report {
    my ($planet, $espionage) = @_;
    out('Surface Report');
    my $spy = random_spy($espionage->{intel}{spies});
    return undef unless defined $spy;
    my @map;
    foreach my $buildings ($planet->buildings) {
        while (my $building = $buildings->next) {
            push @map, {
                image   => $building->image_level,
                x       => $building->x,
                y       => $building->y,
            };
        }
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Surface Report', $spy->name],
        attach_map  => {
                        surface_image   => $planet->surface,
                        buildings       => \@map
                       },
    );
}

sub spy_report {
    my ($planet, $espionage) = @_;
    out('Spy Report');
    my $spook = random_spy($espionage->{intel}{spies});
    return undef unless defined $spook;
    my @peeps = (['From','Assignment']);
    my %planets = ( $planet->id => $planet->name );
    my @spies = shuffle(@{get_full_spies_list($espionage)});
    my $i = 0;
    my $count = randint(1,50);
    while (my $spy = pop @spies) {
        next if ($spy->empire_id eq $spook->empire_id); # skip our own
        unless (exists $planets{$spy->from_body_id}) {
            $planets{$spy->from_body_id} = $spy->from_body->name;
        }
        push @peeps, [$planets{$spy->from_body_id}, $spy->task];
        $i++;
        last if ($i >= $count);
    }
    if ($i) {
        $spook->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Spy Report', $spook->name],
            attach_table=> \@peeps,
        );
    }
}

sub economic_report {
    my ($planet, $espionage) = @_;
    out('Economic Report');
    my $spy = random_spy($espionage->{intel}{spies});
    return undef unless defined $spy;
    my @resources = (['Resource', 'Per Hour', 'Stored']);
    push @resources, [ 'Food', $planet->food_hour, $planet->food_stored ];
    push @resources, [ 'Water', $planet->water_hour, $planet->water_stored ];
    push @resources, [ 'Energy', $planet->energy_hour, $planet->energy_stored ];
    push @resources, [ 'Ore', $planet->ore_hour, $planet->ore_stored ];
    push @resources, [ 'Waste', $planet->waste_hour, $planet->waste_stored ];
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Economic Report', $spy->name],
        attach_table=> \@resources,
    );
}

sub travel_report {
    my ($planet, $espionage) = @_;
    out('Travel Report');
    my $spy = random_spy($espionage->{intel}{spies});
    return undef unless defined $spy;
    my @travelling = (['From','To','Type']);
    my $ships = $planet->ships_travelling;
    my $got;
    while (my $ship = $ships->next) {
        my $target = ($ship->foreign_body_id) ? $ship->foreign_body : $ship->foreign_star;
        my $from = $planet->name;
        my $to = $target->name;
        if ($ship->direction ne 'outgoing') {
            my $temp = $from;
            $from = $to;
            $to = $temp;
        }
        my $type = $ship->ship_type;
        $type =~ s/_/ /g;
        push @travelling, [
            $planet->name,
            $target->name,
        ];
        $got = 1;
    }
    if ($got) {
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Travel Report', $spy->name],
            attach_table=> \@travelling,
        );
    }
}

sub ship_report {
    my ($planet, $espionage) = @_;
    out('Ship Report');
    my $spy = random_spy($espionage->{intel}{spies});
    return undef unless defined $spy;
    my $ports = $planet->get_buildings_of_class('Lacuna::DB::Building::SpacePort');
    my $got;
    my %tally;
    while (my $port = $ports->next) {
        $got = 1;
        $tally{probes} += $port->probe_count;
        $tally{'colony ships'} += $port->colony_ship_count;
        $tally{'spy pods'} += $port->spy_pod_count;
        $tally{'cargo ships'} += $port->cargo_ship_count;
        $tally{'space stations'} += $port->space_station_count;
        $tally{'smuggler ships'} += $port->smuggler_ship_count;
        $tally{'mining platform ships'} += $port->mining_platform_ship_count;
        $tally{'terraforming platform ships'} += $port->terraforming_platform_ship_count;
        $tally{'gas giant settlement platform ships'} += $port->gas_giant_settlement_platform_ship_count;
    }
    if ($got) {
        my @ships = (['Type','Quantity']);
        foreach my $ship (keys %tally) {
            push @ships, [$ship, $tally{$ship}];
        }
        $spy->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Ship Report', $spy->name],
            attach_table=> \@ships,
        );
    }
}

sub build_queue_report {
    my ($planet, $espionage) = @_;
    out('Build Queue Report');
    my $spy = random_spy($espionage->{intel}{spies});
    return undef unless defined $spy;
    my @report = (['Building', 'Level', 'Expected Completion']);
    my $builds = $planet->builds;
    while (my $build = $builds->next) {
        push @report, [
            $build->building->name,
            $build->building->level + 1,
            $build->date_complete_formatted,
        ];
    }
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Build Queue Report', $spy->name],
        attach_table=> \@report,
    );
}

sub false_interrogation_report {
    my ($planet, $espionage) = @_;
    out('False Interrogation Report');
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    my $suspect = random_spy($espionage->{prison}{spies});
    return undef unless defined $suspect;
    my $suspect_home = $suspect->from_body;
    my $suspect_empire = $suspect->empire;
    my $suspect_species = $suspect_empire->species;
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Interrogation Report', $cop->name],
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
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    my $suspect = random_spy($espionage->{prison}{spies});
    return undef unless defined $suspect;
    my $suspect_home = $suspect->from_body;
    my $suspect_empire = $suspect->empire;
    my $suspect_species = $suspect_empire->species;
    $cop->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Interrogation Report', $cop->name],
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
    my $cop = shift @{$espionage->{police}{spies}};
    return undef unless defined $cop;
    my $suspect = shift @{$espionage->{prison}{spies}};
    return undef unless defined $suspect;
    $espionage->{police}{score} -= $cop->offense;
    $cop->kill($planet);
    $suspect->escape;
    $planet->add_news(70,'An inmate killed his interrogator, and escaped the prison on %s today.', $planet->name);
}

sub escape_prison {
    my ($planet, $espionage) = @_;
    out('Escape Prison');
    my $suspect = shift @{$espionage->{prison}{spies}};
    return undef unless defined $suspect;
    $suspect->escape;
    $planet->add_news(50,'At this hour police on %s are flabbergasted as to how an inmate escaped earlier in the day.', $planet->name);    
}

sub kill_suspect {
    my ($planet, $espionage) = @_;
    out('Kill Suspect');
    my $suspect = shift @{$espionage->{prison}{spies}};
    return undef unless defined $suspect;
    $suspect->kill($planet);
    $planet->add_news(50,'Allegations of police brutality are being made on %s after an inmate was killed in custody today.', $planet->name);
}

sub kill_intelligence {
    my ($planet, $espionage) = @_;
    out('Kill Intelligence Agent');
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    my $intel = shift @{$espionage->{intel}{spies}};
    return undef unless defined $intel;
    $espionage->{intel}{score} -= $intel->offense;
    kill_a_spy($planet, $intel, $cop);
    $planet->add_news(60,'A suspected spy known only as %s was killed in a struggle with police on %s today.', $intel->name, $planet->name);
}

sub capture_intelligence {
    my ($planet, $espionage) = @_;
    out('Capture Intelligence Agent');
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    my $intel = shift @{$espionage->{intel}{spies}};
    return undef unless defined $intel;
    $espionage->{intel}{score} -= $intel->offense;
    capture_a_spy($planet, $intel, $cop);
    $planet->add_news(30,'An individual is behing held for questioning on %s at this hour for looking suspicious.', $planet->name);
}

sub thwart_intelligence {
    my ($planet, $espionage) = @_;
    out('Thwart Intelligence Agent');
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    my $intel = random_spy($espionage->{intel}{spies});
    return undef unless defined $intel;
    miss_a_spy($planet, $spy, $interceptor);
    $planet->add_news(25,'Corporate espionage has become a real problem on %s.', $planet->name);
}

sub counter_intel_report {
    my ($planet, $espionage, $count) = @_;
    out('Counter Intelligence Report');
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    my @peeps = (['From','Assignment']);
    my %planets = ( $planet->id => $planet->name );
    my @spies = shuffle(@{get_full_spies_list($espionage)});
    my $i = 0;
    while (my $spy = pop @spies) {
        next if ($spy->empire_id eq $planet->empire_id); # skip our own
        unless (exists $planets{$spy->from_body_id}) {
            $planets{$spy->from_body_id} = $spy->from_body->name;
        }
        push @peeps, [$planets{$spy->from_body_id}, $spy->task];
        $i++;
        last if ($i >= $count);
    }
    if ($i) {
        $cop->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'intel_report.txt',
            params      => ['Counter Intelligence Report', $cop->name],
            attach_table=> \@peeps,
        );
    }
}

sub kill_cop {
    my ($planet, $espionage, $enemy) = @_;
    out('Kill Cop');
    my $spy = random_spy($espionage->{$enemy}{spies});
    my $cop = shift @{$espionage->{police}{spies}};
    return undef unless defined $cop;
    $spy->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_killed_a_spy.txt',
        params      => [$planet->name, $spy->name],
        from        => $interceptor->empire,
    );
    $espionage->{police}{score} += 5 - $cop->defense;
    $planet->add_news(60,'An officer named %s was killed in the line of duty on %s.', $cop->name, $planet->name);
    $cop->kill($planet);
}

capture_hacker {
    my ($planet, $espionage) = @_;
    out('Capture Hacker');
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    my $hacker = shift @{$espionage->{hacking}{spies}};
    return undef unless defined $hacker;
    $espionage->{hacking}{score} -= $hacker->offense;
    $planet->add_news(30,'Alleged hacker %s is awaiting arraignment on %s today.', $hacker->name, $planet->name);
    capture_a_spy($planet, $hacker, $cop);
}

kill_hacker {
    my ($planet, $espionage) = @_;
    out('Kill Hacker');
    my $cop = random_spy($espionage->{police}{spies});
    return undef unless defined $cop;
    my $hacker = shift @{$espionage->{hacking}{spies}};
    return undef unless defined $hacker;
    $espionage->{hacking}{score} -= $hacker->offense;
    $planet->add_news(60,'A suspected hacker, age '.randint(16,60).', was found dead in his home today on %s.', $planet->name);
    kill_a_spy($planet, $hacker, $cop);    
}

thwart_hacker {
    my $cop = random_spy($espionage->{police}{spies});
    out('Thwart Hacker');
    return undef unless defined $cop;
    my $hacker = shift @{$espionage->{hacking}{spies}};
    return undef unless defined $hacker;
    miss_a_spy($hacker, $cop);
    $planet->add_news(10,'Identity theft has become a real problem on %s.', $planet->name);  
    $espionage->{police}{score} += 3;
}



sub network19_propaganda1 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 1');
    if ($planet->add_news(50,'A resident of %s has won the Lacuna Expanse talent competition.', $planet->name)) {
        $planet->add_happiness(250)->put;
    }
}

sub network19_propaganda2 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 2');
    if ($planet->add_news(50,'The economy of %s is looking strong, showing GDP growth of nearly 10%% for the past quarter.',$planet->name)) {
        $planet->add_happiness(500)->put;
    }
}

sub network19_propaganda3 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 3');
    if ($planet->add_news(50,'The governor of %s has set aside 1000 square kilometers as a nature preserve.', $planet->name)) {
        $planet->add_happiness(750)->put;
    }
}

sub network19_propaganda4 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 4');
    if ($planet->add_news(50,'If %s had not inhabited %s, the planet would likely have reverted to a barren rock.', $planet->empire->name, $planet->name)) {
        $planet->add_happiness(1000)->put;
    }
}

sub network19_propaganda5 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 5');
    if ($planet->add_news(50,'The benevolent leader of %s is a gift to the people of %s.', $planet->empire->name, $planet->name)) {
        $planet->add_happiness(1250)->put;
    }
}

sub network19_propaganda6 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 6');
    if ($planet->add_news(50,'%s is the greatest, best, most free empire in the Expanse, ever.', $planet->empire->name)) {
        $planet->add_happiness(1500)->put;
    }
}

sub network19_propaganda7 {
    my ($planet, $espionage) = @_;
    out('Network 19 Propaganda 7');
    if ($planet->add_news(50,'%s is the ultimate power in the Expanse right now. It is unlikely to be challenged any time soon.', $planet->empire->name)) {
        $planet->add_happiness(1750)->put;
    }
}

sub network19_defamation1 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 1');
    if ($planet->add_news(50,'A financial report for %s shows that many people are out of work as the unemployment rate approaches 10%%.', $planet->name)) {
        $planet->spend_happiness(250)->put;
    }
}

sub network19_defamation2 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 2');
    if ($planet->add_news(50,'An outbreak of the Dultobou virus was announced on %s today. Citizens are encouraged to stay home from work and school.', $planet->name)) {
        $planet->spend_happiness(500)->put;
    }
}

sub network19_defamation3 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 3');
    if ($planet->add_news(50,'%s is unable to keep its economy strong. Sources inside say it will likely fold in a few days.', $planet->empire->name)) {
        $planet->spend_happiness(750)->put;
    }
}

sub network19_defamation4 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 4');
    if ($planet->add_news(50,'The governor of %s has lost her mind. She is a raving mad lunatic! The Emperor could not be reached for comment.', $planet->name)) {
        $planet->spend_happiness(1250)->put;
    }
}

sub network19_defamation5 {
    my ($planet, $espionage) = @_;
    out('Network 19 Defamation 5');
    if ($planet->add_news(50,'%s is the smallest, worst, least free empire in the Expanse, ever.', $planet->empire->name)) {
        $planet->spend_happiness(1250)->put;
    }
}






sub turn_spy {
    my $planet = shift;
    my $spy = random_spy($planet->interceptors);
    return undef unless defined $spy;
    return undef if ($spy->empire_id eq $planet->empire_id);
    if ($planet->check_rebellion) {
        my $rebel = random_spy($planet->rebels);
        $spy->turn($rebel);
        $planet->interception_score( $planet->interception_score + 50);
    }
    else {
        $planet->defeat_rebellion;
    }
}

sub incite_rebellion {
    my $planet = shift;
    my $spy = random_spy($planet->rebels);
    return undef unless defined $spy;
    return undef if ($spy->empire_id eq $planet->empire_id);
    if ($planet->check_rebellion) {
        my $loss = sprintf('%.0f', $planet->happiness * 0.10 );
        $planet->spend_happiness( $loss )->put;
        my @spies = $planet->pick_a_spy_per_empire($planet->rebels);
        foreach my $rebel (@spies) {
            $rebel->empire->send_predefined_message(
                tags        => ['Intelligence'],
                filename    => 'we_incited_a_rebellion.txt',
                params      => [$planet->empire->name, $planet->name, $loss, $rebel->name],
            );
        }
        $planet->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'uprising.txt',
            params      => [$spy->name,$planet->name,$loss],
        );
        $planet->add_news(90,'Led by %s, the citizens of %s are rebelling against %s.', $spy->name, $planet->name, $planet->empire->name);
        $planet->interception_score( $planet->interception_score + 20);
    }
    else {
        $planet->defeat_rebellion;
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
    my $spies = $db->domain('spies')->search(
        where => {
            on_body_id  => $planet->id,
        }
    );
    while (my $spy = $spies->next) {
        if ($spy->task eq 'Counter Espionage') {
            $interception += $spy->defense;
            push @interceptors, $spy;
        }
        elsif ($spy->task eq 'Idle') {
            push @idle, $spy;
        }
        elsif ($spy->task eq 'Training') {
            push @trainees, $spy;
        }
        elsif ($spy->task eq 'Travelling') {
            push @travellers, $spy;
        }
        elsif ($spy->empire_id eq $planet->empire_id) {
            next; # someone is trying to pull some funny business
        }
        elsif ($spy->task eq 'Sabotage Infrastructure') {
            $sabotage += $spy->offense;
            push @saboteurs, $spy;
        }
        elsif ($spy->task eq 'Appropriate Technology') {
            $steal += $spy->offense;
            push @thieves, $spy;
        }
        elsif ($spy->task eq 'Gather Intelligence') {
            $intel += $spy->offense
            push @spies, $spy;
        }
        elsif ($spy->task eq 'Incite Rebellion') {
            $rebel += $spy->offense;
            push @rebels, $spy;
        }
        elsif ($spy->task eq 'Hack Networks') {
            $hack += $spy->offense;
            push @hackers, $spy;
        }
        elsif ($spy->task eq 'Captured') {
            push @prisoners, $spy;
        }
    }
    return {
        idle => {
            spies => \@idle,
        },
        prison => {
            spies => \@prisoners,
        },
        train => {
            spies => \@trainees,
        },
        travel => {
            spies => \@travellers,
        },
        theft => {
            spies => \@theives,
            score => $steal,
        },
        hacking => {
            spies => \@hackers,
            score => $hack,
        },
        rebellion => {
            spies => \@rebels,
            score => $rebel,
        },
        intel => {
            spies => \@spies,
            score => $intel,
        },
        sabotage => {
            spies => \@saboteurs,
            score => $sabotage,
        },
        police => {
            spies => \@interceptors,
            score => $interception,
        }
    };
};

sub kill_a_spy {
    my ($planet, $spy, $interceptor) = @_;
    $planet->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_killed_a_spy.txt',
        params      => [$planet->name, $interceptor->name],
        from        => $interceptor->empire,
    );
    $spy->kill($planet);
}

sub capture_a_spy {
    my ($planet, $spy, $interceptor) = @_;
    $spy->available_on(DateTime->now->add(months=>1));
    $spy->task('Captured');
    $spy->put;
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

sub defeat_theft {
    my ($self) = @_;
    if ($self->chance_of_theft > 0) {
        my $event = randint(1,100);
        my $spy = $self->thieves->[0];
        return undef unless defined $spy;
        my $interceptor = $self->interceptors->[0];
        return undef unless defined $interceptor;
        if ($event < 5) {
            $self->theft_score( $self->theft_score - $spy->offense );
            $self->kill_a_spy($spy, $interceptor);
            delete $self->thieves->[0];
            $self->add_news(70,'%s police caught and killed a thief on %s during the commission of the crime.', $self->empire->name, $self->name);
        }
        elsif ($event < 20) {
            $self->theft_score( $self->theft_score - $spy->offense );
            $self->capture_a_spy($spy, $interceptor);
            delete $self->thieves->[0];
            $self->add_news(40,'%s announced the incarceration of a thief on %s today.', $self->empire->name, $self->name);
        }
        else {
            $self->miss_a_spy($spy, $interceptor);
            $self->add_news(20,'A thief evaded %s authorities on %s. Citizens are warned to lock their doors.', $self->empire->name, $self->name);
        }
    }
}

sub defeat_sabotage {
    my ($self) = @_;
    if ($self->chance_of_sabotage > 0) {
        my $event = randint(1,100);
        my $spy = $self->saboteurs->[0];
        return undef unless defined $spy;
        my $interceptor = $self->interceptors->[0];
        return undef unless defined $interceptor;
            if ($event < 5) {
            $self->sabotage_score( $self->sabotage_score - $spy->offense );
            $self->kill_a_spy($spy, $interceptor);
            delete $self->saboteurs->[0];
            $self->add_news(70,'%s told us that a lone saboteur was killed on %s before he could carry out his plot.', $self->empire->name, $self->name);
        }
        elsif ($event < 30) {
            $self->sabotage_score( $self->sabotage_score - $spy->offense );
            $self->capture_a_spy($spy, $interceptor);
            delete $self->saboteurs->[0];
            $self->add_news(40,'A saboteur was apprehended on %s today by %s authorities.', $self->name, $self->empire->name);
        }
        else {
            $self->miss_a_spy($spy, $interceptor);
            $self->add_news(20,'%s authorities on %s are conducting a manhunt for a suspected saboteur.', $self->empire->name, $self->name);
        }
    }
}

sub defeat_rebellion {
    my ($self) = @_;
    if ($self->chance_of_rebellion > 0) {
        my $event = randint(1,100);
        my $spy = $self->rebels->[0];
        return undef unless defined $spy;
        my $interceptor = $self->interceptors->[0];
        return undef unless defined $interceptor;
        if ($event < 10) {
            $self->rebel_score( $self->rebel_score - $spy->offense );
            $self->kill_a_spy($spy, $interceptor);
            $self->add_news(80,'The leader of the rebellion to overthrow %s was killed in a firefight today on %s.', $self->empire->name, $self->name);
            delete $self->rebels->[0];
        }
        elsif ($event < 25) {
            $self->rebel_score( $self->rebel_score - $spy->offense );
            $self->capture_a_spy($spy, $interceptor);
            $self->add_news(50,'Police say they have crushed the rebellion on %s by apprehending %s.', $self->name, $spy->name);
            delete $self->rebels->[0];
        }
        else {
            $self->miss_a_spy($spy, $interceptor);
            $self->add_news(20,'The rebel leader, known as %s, is still eluding authorities on %s at this hour.', $spy->name, $self->name);
        }
    }
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

sub calculate_mission_score {
    my ($espionage, $type) = @_;
    return 0 if ($espionage->{$type}{score} == 0);
    return randint(0, $espionage->{$type}{score}) - randint(0, $espionage->{police}{score});
}

sub get_full_spies_list {
    my ($espionage) = @_;
    my @spies = (
        @{$espionage->{idle}{spies}},
        @{$espionage->{train}{spies}},
        @{$espionage->{prison}{spies}},
        @{$espionage->{travel}{spies}},
        @{$espionage->{theft}{spies}},
        @{$espionage->{hacking}{spies}},
        @{$espionage->{rebellion}{spies}},
        @{$espionage->{intel}{spies}},
        @{$espionage->{sabotage}{spies}},
        @{$espionage->{police}{spies}},
    );
    return \@spies;
}

# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}


