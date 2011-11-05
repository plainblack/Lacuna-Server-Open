package TestHelper;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna::DB;
use Lacuna;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use Data::Dumper;
use 5.010;

has ua => (
    is  => 'ro',
    lazy => 1,
    default => sub {  my $ua = LWP::UserAgent->new; $ua->timeout(30); return $ua; },
);

has empire_name => (
    is => 'ro',
    default => 'TLE Test Empire',
);

has empire_password => (
    is => 'ro',
    default => '123qwe',
);

has empire => (
    is  => 'rw',
    lazy => 1,
    default => sub { my $self = shift; return Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$self->empire_name}, {rows=>1})->single; },
);

has session => (
    is => 'rw',
);

has x => (
    is => 'rw',
    default => -5,
);

has y => (
    is => 'rw',
    default => -5,
);

has big_producer => (
    is => 'rw',
    default => 0,
);

sub clear_all_test_empires {
    my ($class, $name) = @_;

    $name = 'TLE Test%' unless $name;

    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
        name => {like => $name},
    });
    while (my $empire = $empires->next) {

        my $planets = $empire->planets;
        while ( my $planet = $planets->next ) {
            $planet->buildings->search({class => { 'like' => 'Lacuna::DB::Result::Building::Permanent%' } })->delete_all;
        }


        $empire->delete;
    }
}


sub generate_test_empire {
    my $self = shift;
    # Make sure no other test empires are still around
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
        name                => $self->empire_name,
    });
    while (my $empire = $empires->next) {
        $empire->delete;
    }


    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
        name                => $self->empire_name,
        date_created        => DateTime->now,
        status_message      => 'Making Lacuna a better Expanse.',
        password            => Lacuna::DB::Result::Empire->encrypt_password($self->empire_password),
    })->insert;
    $empire->found;
    $self->session($empire->start_session({api_key => 'tester'}));
    $self->empire($empire);
    return $self;
}

sub get_building { 
    my ($self, $building_id) = @_;
    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($building_id);
    unless (defined $building) {
        confess 'Building does not exist.';
    }
    $building->body($self->empire->home_planet);
    return $building;
}

sub find_empty_plot {
     my ($self) = @_;

     my $home = $self->empire->home_planet;

     # Ensure we only build on an empty plot
     EXISTING_BUILDING:
     while (1) {
          my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({
               x       => $self->x,
               y       => $self->y,
               body_id => $home->id,
          });

          last EXISTING_BUILDING if $building == 0;
          $self->x($self->x + 1);
          if ($self->x == 6) {
               $self->x(-5);
               $self->y($self->y + 1);
          }
     }
}

sub build_building {
    my ($self, $class, $level) = @_;

    my $home = $self->empire->home_planet;
    $self->find_empty_plot;

    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => $self->x,
        y               => $self->y,
        class           => $class,
        level           => $level - 1,
    });
    $home->build_building($building);
    $building->finish_upgrade;
    return $building;
}

sub build_infrastructure {
    my $self = shift;
    my $home = $self->empire->home_planet;
    foreach my $type ('Lacuna::DB::Result::Building::Food::Algae','Lacuna::DB::Result::Building::Energy::Hydrocarbon',
        'Lacuna::DB::Result::Building::Water::Purification','Lacuna::DB::Result::Building::Water::Purification','Lacuna::DB::Result::Building::Water::Purification','Lacuna::DB::Result::Building::Ore::Mine','Lacuna::DB::Result::Building::Ore::Mine','Lacuna::DB::Result::Building::Ore::Mine','Lacuna::DB::Result::Building::Food::Algae','Lacuna::DB::Result::Building::Food::Algae','Lacuna::DB::Result::Building::Energy::Hydrocarbon','Lacuna::DB::Result::Building::Energy::Hydrocarbon') {

        $self->build_building($type, 20);
    }
    $home->empire->university_level(30);
    $home->empire->update;
    foreach my $type ('Lacuna::DB::Result::Building::Energy::Reserve',
        'Lacuna::DB::Result::Building::Food::Reserve','Lacuna::DB::Result::Building::Ore::Storage',
        'Lacuna::DB::Result::Building::Water::Storage') {

        $self->build_building($type, 20);

    }

    if ($self->big_producer) {
        $home->ore_hour(50000000);
        $home->water_hour(50000000);
        $home->energy_hour(50000000);
        $home->algae_production_hour(50000000);
        $home->ore_capacity(50000000);
        $home->energy_capacity(50000000);
        $home->food_capacity(50000000);
        $home->water_capacity(50000000);
        $home->bauxite_stored(50000000);
        $home->algae_stored(50000000);
        $home->energy_stored(50000000);
        $home->water_stored(50000000);
        $home->add_happiness(50000000);
        $home->monazite_stored(5000000);
    }
    else {
        $home->algae_stored(100_000);
        $home->bauxite_stored(100_000);
        $home->energy_stored(100_000);
        $home->water_stored(100_000);
    }

    $home->tick;
    return $self;
}

sub post {
    my ($self, $url, $method, $params) = @_;
    my $content = {
        jsonrpc     => '2.0',
        id          => 1,
        method      => $method,
        params      => $params,
    };
    say "REQUEST: ".to_json($content);
    my $response = $self->ua->post(Lacuna->config->get('server_url').$url,
        Content_Type    => 'application/json',
        Content         => to_json($content),
        Accept          => 'application/json',
        );
    say "RESPONSE: ".$response->content;
    sleep 2;
    return from_json($response->content);
}

sub cleanup {
    my $self = shift;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$self->empire_name});
    while (my $empire = $empires->next) {
        # delete any permanent buildings
        
        my $planets = $empire->planets;
        while ( my $planet = $planets->next ) {
            $planet->buildings->search({class => { 'like' => 'Lacuna::DB::Result::Building::Permanent%' } })->delete_all;
        }

        $empire->delete;
    }
}

sub finish_ships {
	my ( $self, $shipyard_id ) = @_;
	my $finish = DateTime->now;

	Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({shipyard_id=>$shipyard_id})->update({date_available=>$finish, task=>'Docked'});
}


1;
