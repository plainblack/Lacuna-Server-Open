use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint);

my $config = Lacuna->config;
my $age = DateTime->now->subtract(hours=>24);
my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached')); 

my $planets = $db->domain('Lacuna::DB::Body::Planet')->search(
    where   => {
        empire_id   => ['!=', 'None'],
    }
);

while (my $planet = $planets->next) {
    $planet->determine_espionage;
    ship_report($planet);
    travel_report($planet);
    economic_report($planet);
    colony_report($planet);
    spy_report($planet);
    interrogation_report($planet);
    surface_report($planet);
    hack_local_probes($planet);
    hack_network19($planet);
    hack_observatory_probes($planet);
    $planet->tick; # do explosions and theft
    incite_rebellion($planet);
    turn_spy($planet);
}

sub random_spy {
    my $spies = shift;
    my @random = shuffle @{$spies};
    return $random[0];
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
        $loss = 10_000 if ($loss < 10_000);
        $planet->spend_happiness( $loss )->put;
        $spy->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'we_incited_a_rebellion.txt',
            params      => [$planet->empire->name, $planet->name, $loss, $spy->name],
        );
        $spy->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'uprising.txt',
            params      => [$spy->name,$planet->name,$loss],
        );
        $planet->add_news(100,'Led by %s, the citizens of %s are rebelling against %s.', $spy->name, $planet->name, $planet->empire->name);
        $planet->interception_score( $planet->interception_score + 20);
    }
    else {
        $planet->defeat_rebellion;
    }
}

sub hack_network19 {
    my $planet = shift;
    my $hacker = random_spy($planet->hackers);
    return undef unless defined $hacker;
    my $network19 = $db->domain('Lacuna::DB::Building::Network19')->search(where=>{body_id => $planet->id }, limit=>1)->next;
    return undef unless defined $network19;
    my $chance = $hacker->offense - $network19->level;
    my $empire = $planet->empire;
    if ($hacker->empire_id eq $planet->empire_id) {
        $planet->add_news($chance,'%s is the greatest, best, most free empire in the Expanse, ever.', $empire->name);
        $planet->add_news($chance,'If %s had not inhabited %s, the planet would likely have reverted to a barren rock.', $empire->name, $planet->name);
        $planet->add_news($chance,'%s is the ultimate power in the Expanse right now. It is unlikely to be challenged any time soon.', $empire->name);
    }
    else {
        $planet->add_news($chance,'%s is the smallest, worst, least free empire in the Expanse, ever.', $empire->name);
        $planet->add_news($chance,'%s is unable to keep its economy strong. Sources inside say it will likely fold in a few days.', $empire->name);
        $planet->add_news($chance,'An inside source has revealed that the leader of %s has lost all mental faculty.', $empire->name);
    }
}

sub hack_local_probes {
    my $planet = shift;
    my $hacker = random_spy($planet->hackers);
    return undef unless defined $hacker;
    my $probe = $db->domain('probes')->search(where=>{star_id => $planet->star_id, empire_id => ['!=', $hacker->empire_id] }, limit=>1)->next;
    return undef unless defined $probe;
    if ($hacker->empire_id eq $planet->empire_id) {
        if ($hacker->defense > randint(1,100)) {
            $probe->destroy;
            $hacker->empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'we_destroyed_a_probe.txt',
                params      => [$probe->star->name, $hacker->name],
            );
        }
    }
    else {
        if ($planet->check_hack) {
            $probe->destroy;
            $hacker->empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'we_destroyed_a_probe.txt',
                params      => [$probe->star->name, $probe->empire->name, $hacker->name],
            );
            $planet->interception_score( $planet->interception_score + 5);
        }
        else {
            $planet->defeat_hack;
        }
    }
}

sub hack_observatory_probes {
    my $planet = shift;
    my $hacker = random_spy($planet->hackers);
    return undef unless defined $hacker;
    return undef if ($hacker->empire_id eq $planet->empire_id);
    my $probe = $db->domain('probes')->search(where=>{body_id => $planet->id }, limit=>1)->next;
    return undef unless defined $probe;
    if ($planet->check_hack) {
        $probe->destroy;
        $hacker->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'we_destroyed_a_probe.txt',
            params      => [$probe->star->name, $hacker->name],
        );
        $planet->interception_score( $planet->interception_score + 5);
    }
    else {
        $planet->defeat_hack;
    }
}

sub travel_report {
    my $planet = shift;
    my $spy = random_spy($planet->investigators);
    return undef unless defined $spy;
    return undef if ($spy->empire_id eq $planet->empire_id);
    if ($planet->check_intel) {
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
                tags        => ['Alert'],
                filename    => 'intel_report.txt',
                params      => ['Travel Report', $spy->name],
                attach_table=> \@travelling,
            );
        }
    }
    else {
        $planet->defeat_intel;
    }
}

sub colony_report {
    my $planet = shift;
    my $spy = random_spy($planet->investigators);
    return undef unless defined $spy;
    return undef if ($spy->empire_id eq $planet->empire_id);
    if ($planet->check_intel) {
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
            tags        => ['Alert'],
            filename    => 'intel_report.txt',
            params      => ['Colony Report', $spy->name],
            attach_table=> \@colonies,
        );
    }
    else {
        $planet->defeat_intel;
    }
}

sub ship_report {
    my $planet = shift;
    my $spy = random_spy($planet->investigators);
    return undef unless defined $spy;
    return undef if ($spy->empire_id eq $planet->empire_id);
    if ($planet->check_intel) {
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
                tags        => ['Alert'],
                filename    => 'intel_report.txt',
                params      => ['Ship Report', $spy->name],
                attach_table=> \@ships,
            );
        }
    }
    else {
        $planet->defeat_intel;
    }
}


sub economic_report {
    my $planet = shift;
    my $spy = random_spy($planet->investigators);
    return undef unless defined $spy;
    return undef if ($spy->empire_id eq $planet->empire_id);
    if ($planet->check_intel) {
        my @resources = (['Resource', 'Per Hour', 'Stored']);
        push @resources, [ 'Food', $planet->food_hour, $planet->food_stored ];
        push @resources, [ 'Water', $planet->water_hour, $planet->water_stored ];
        push @resources, [ 'Energy', $planet->energy_hour, $planet->energy_stored ];
        push @resources, [ 'Ore', $planet->ore_hour, $planet->ore_stored ];
        push @resources, [ 'Waste', $planet->waste_hour, $planet->waste_stored ];
        $spy->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'intel_report.txt',
            params      => ['Economic Report', $spy->name],
            attach_table=> \@resources,
        );
    }
    else {
        $planet->defeat_intel;
    }
}

sub interrogation_report {
    my $planet = shift;
    my $interrogator = random_spy($planet->investigators);
    return undef unless (defined $interrogator && $interrogator->empire_id eq $planet->empire_id);
    my $suspect = $db->domain('spies')->search(where=>{on_body_id=>$planet->id, task=>'Captured', 'itemName()' => ['!=','None']}, order_by=>'itemName()', limit=>1)->next;
    return undef unless (defined $suspect);
    if ($interrogator->offense > $suspect->defense) {
        my $suspect_home = $suspect->from_body;
        my $suspect_empire = $suspect->empire;
        my $suspect_species = $suspect_empire->species;
        $interrogator->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'intel_report.txt',
            params      => ['Interrogation Report', $interrogator->name],
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
    else {
        my $event = randint(1,100);
        if ($event < 10) {
            $interrogator->kill($planet);
            $suspect->escape;
            $planet->add_news(70,'An inmate killed his interrogator, and escaped the prison on %s today.', $planet->name);
        }
        elsif ($event < 20) {
            $suspect->escape;
            $planet->add_news(50,'At this hour police on %s are flabbergasted as to how an inmate escaped earlier in the day.', $planet->name);
        }
        elsif ($event < 30) {
            $suspect->kill($planet);
            $planet->add_news(50,'Allegations of police brutality are being made on %s after an inmate was killed in custody today.', $planet->name);
        }
    }
}

sub surface_report {
    my $planet = shift;
    my $spy = random_spy($planet->investigators);
    return undef unless defined $spy;
    return undef if ($spy->empire_id eq $planet->empire_id);
    if ($planet->check_intel) {
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
            tags        => ['Alert'],
            filename    => 'intel_report.txt',
            params      => ['Surface Report', $spy->name],
            attach_map  => {
                            surface_image   => $planet->surface,
                            buildings       => \@map
                           },
        );
    }
    else {
        $planet->defeat_intel;
    }
}

sub spy_report {
    my $planet = shift;
    my $spy = random_spy($planet->investigators);
    return undef unless defined $spy;
    my @peeps = (['From','Assignment']);
    my %planets = ( $planet->id => $planet->name );
    my $spy_list = $db->domain('spies')->search(where=>{ on_body_id => $planet->id, empire_id => ['!=', $spy->empire_id] });
    while (my $spy = $spy_list->next) {
        unless (exists $planets{$spy->from_body_id}) {
            $planets{$spy->from_body_id} = $spy->from_body->name;
        }
        push @peeps, [$planets{$spy->from_body_id}, $spy->task];
    }
    $spy->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'intel_report.txt',
        params      => ['Counter Intelligence Report', $spy->name],
        attach_table=> \@peeps,
    );
}

