package TestHelper;

use Moose;
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

sub generate_test_empire {
    my $self = shift;
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

sub build_infrastructure {
    my $self = shift;
    my $home = $self->empire->home_planet;
    foreach my $type ('Lacuna::DB::Result::Building::Food::Algae','Lacuna::DB::Result::Building::Energy::Hydrocarbon',
        'Lacuna::DB::Result::Building::Water::Purification','Lacuna::DB::Result::Building::Ore::Mine') {
        my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
            x               => -5,
            y               => -5,
            class           => $type,
            level           => 10,
        });
        $home->build_building($building);
        $building->finish_upgrade;
    }
    $home->empire->university_level(30);
    $home->empire->update;
    foreach my $type ('Lacuna::DB::Result::Building::Energy::Reserve',
        'Lacuna::DB::Result::Building::Food::Reserve','Lacuna::DB::Result::Building::Ore::Storage',
        'Lacuna::DB::Result::Building::Water::Storage') {
        my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
            x               => -5,
            y               => -5,
            class           => $type,
            level           => 5,
        });
        $home->build_building($building);
        $building->finish_upgrade;
    }

    $home->algae_stored(100_000);
    $home->bauxite_stored(100_000);
    $home->energy_stored(100_000);
    $home->water_stored(100_000);
    
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
    return from_json($response->content);
}

sub cleanup {
    my $self = shift;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name=>$self->empire_name});
    while (my $empire = $empires->next) {
        say "Found a test empire.";
        $empire->delete;
        say "Deleted it.";
    }
}


1;
