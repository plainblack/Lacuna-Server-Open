package Lacuna::Empire;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(cname);
use Lacuna::Map;
use Digest::SHA;
use Lacuna::Verify;

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub is_name_available {
    my ($self, $name) = @_;
    if ( $name eq '' ) {
        return 0;
    }
    else {
        my $count = $self->simpledb->domain('empire')->count({cname=>cname($name)});
        return ($count) ? 0 : 1;
    }
}

sub logout {
    my ($self, $session_id) = @_;
    $self->get_session($session_id)->delete;
    return 1;
}

sub login {
    my ($self, $name, $password) = @_;
    my $empire = $self->simpledb->domain('empire')->search({cname=>cname($name)})->next;
    if (defined $empire) {
        if ($empire->password eq $self->encrypt_password($password)) {
            return { session_id => $empire->start_session->id, status => $empire->get_status };
        }
        else {
            confess [1004, 'Password incorrect.', $password];
        }
    }
    else {
         confess [1002, 'Empire does not exist.', $name];
    }
}

sub create {
    my ($self, %account) = @_;
    Lacuna::Verify->new(content=>\$account{name}, throws=>[1000,'Empire name not available.', $account{name}])
        ->length_lt(31)
        ->length_gt(3)
        ->no_restricted_chars
        ->no_profanity
        ->ok($self->is_name_available($account{name}));

    Lacuna::Verify->new(content=>\$account{password}, throws=>[1001,'Invalid password.', $account{password}])
        ->length_gt(5)
        ->eq($account{password1});

    $account{species_id} ||= 'human_species';
    my $db = $self->simpledb;
    my $species = $self->simpledb->domain('species')->find($account{species_id});
    if ($account{species_id} eq '' || !$species)  {
        confess [1002, 'Invalid species.', $account{species_id}];
    }
    else {
        my $map = Lacuna::Map->new(simpledb=>$db);
        my $orbits = $species->habitable_orbits;
        unless (ref $orbits eq 'ARRAY') {
            $orbits = [$orbits];
        }
        my $possible_planets = $db->domain('body')->search({
            empire_id   => 'None',
            class       => ['like','Lacuna::DB::Body::Planet::P%'],
            orbit       => ['in',@{$orbits}],
            x           => ['between', ($map->get_min_x_inhabited - 2), ($map->get_max_x_inhabited + 2)],
            y           => ['between', ($map->get_min_y_inhabited - 2), ($map->get_max_y_inhabited + 2)],
            z           => ['between', ($map->get_min_z_inhabited - 2), ($map->get_max_z_inhabited + 2)],
        });
        my $home_planet = $possible_planets->next;
        unless (defined $home_planet) {
            confess [1002, 'Could not find a home planet.'];
        }
        
        # create empire
        my $empire = $db->domain('empire')->insert({
            name                => $account{name},
            date_created        => DateTime->now,
            password            => $self->encrypt_password($account{password}),
            species_id          => $species->id,
            current_planet_id   => $home_planet->id,
            home_planet_id      => $home_planet->id,
            probed_stars        => $home_planet->star->id,
        });
        
        # set home planet
        $home_planet->empire_id($empire->id);
        $home_planet->last_tick(DateTime->now);
        $home_planet->put;
        
        # add command building
        my $command = Lacuna::DB::Building::PlanetaryCommand->new(simpledb => $empire->simpledb)->update({
            x               => 0,
            y               => 0,
            class           => 'Lacuna::DB::Building::PlanetaryCommand',
            date_created    => DateTime->now,
            body_id         => $home_planet->id,
            empire_id       => $empire->id,
            level           => $species->growth_affinity - 1,
        });
        $home_planet->build_building($command);
        $command->finish_upgrade;
        $home_planet = $command->body; # our current reference is out of date
        
        # add starting resources
        $home_planet->add_algae(5000);
        $home_planet->add_energy(5000);
        $home_planet->add_water(5000);
        $home_planet->add_magnetite(5000);
        $home_planet->put;
        
        # return status
        my $status = $empire->get_status;
        my $session_id = $empire->start_session->id;
        return { empire_id => $empire->id, session_id => $session_id, status => $status };
    }
}

sub encrypt_password {
    my ($self, $password) = @_;
    return Digest::SHA::sha256_base64($password);
}


__PACKAGE__->register_rpc_method_names(qw(is_name_available create login logout));


no Moose;
__PACKAGE__->meta->make_immutable;

