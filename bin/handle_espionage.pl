use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);

my $config = Lacuna->config;
my $age = DateTime->now->subtract(hours=>24);
my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached')); 

my $planets = $db->domain('Lacuna::DB::Body::Planet')->search(
    where   => {
        empire_id   => ['!=', 'None'],
    }
);

while (my $planet = $planets->next) {
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
    incite_rebellion($planet);
    turn_spy($planet);
}

sub random_spy {
    my $spies = shift;
    my @random = shuffle @{$spies};
    return $random[0];
}

sub travel_report {
    my $planet = shift;
    my $spy = random_spy($planet->investigators);
    return undef if ($spy->empire_id eq $planet->empire_id);
    if ($planet->check_intel) {
        my @travelling = (['From','To','Type']);
        my $ships = $planet->ships_travelling;
        my $got;
        while (my $ship = $ships->next) {
            my $target = ($ship->foreign_body_id) ? $ship->foreign_body : $ship->foreign_star;
            my $from = $body->name;
            my $to = $target->name;
            if ($ship->direction ne 'outgoing') {
                my $temp = $from;
                $from = $to;
                $to = $temp;
            }
            my $type = $ship->ship_type;
            $type =~ s/_/ /g;
            push @travelling, [
                $body->name,
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
    my $interrogator = random_spy($planet->investigator);
    return undef unless (defined $interrogator && $interrogator->empire_id eq $planet->empire_id);
    my $suspect = $db->domain('spies')->search(where=>{on_body_id=>$planet->id, task=>'Captured', 'itemName()' => ['!=','None']}, order_by=>'itemName()')->next;
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
        }
        elsif ($event < 20) {
            $suspect->escape;
        }
        elsif ($event < 30) {
            $suspect->kill($planet);
        }
    }
}

sub surface_report {
    my $planet = shift;
    my $spy = random_spy($planet->investigators);
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

