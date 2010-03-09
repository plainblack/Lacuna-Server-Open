package Lacuna::Empire;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(cname);
use Lacuna::Map;
use Lacuna::Verify;
use Lacuna::DB::Empire;

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
        my $count = $self->simpledb->domain('empire')->count(where=>{name_cname=>cname($name)}, consistent=>1);
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
    my $empire = $self->simpledb->domain('empire')->search(where=>{name_cname=>cname($name)})->next;
    if (defined $empire) {
        if ($empire->is_password_valid($password)) {
            return { session_id => $empire->start_session->id, status => $empire->get_full_status };
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
    if ($account{species_id} eq '' || !$species || $account{species_id} eq 'lacunan_species')  {
        confess [1002, 'Invalid species.', $account{species_id}];
    }
    else {
        my $map = Lacuna::Map->new(simpledb=>$db);
        my $orbits = $species->habitable_orbits;
        my $possible_planets = $db->domain('Lacuna::DB::Body::Planet')->search(
            where       => {
                usable_as_starter   => ['!=', 'No'],
                orbit               => ['in',@{$orbits}],
                x                   => ['between', ($map->get_min_x_inhabited - 2), ($map->get_max_x_inhabited + 2)],
                y                   => ['between', ($map->get_min_y_inhabited - 2), ($map->get_max_y_inhabited + 2)],
                z                   => ['between', ($map->get_min_z_inhabited - 2), ($map->get_max_z_inhabited + 2)],
            },
            order_by    => 'usable_as_starter',
            limit       => 1,
            );
        my $home_planet = $possible_planets->next;
        unless (defined $home_planet) {
            confess [1002, 'Could not find a home planet.'];
        }
        
        my $empire = Lacuna::DB::Empire->found($self->simpledb, $home_planet, $species, \%account);

        # return status
        my $status = $empire->get_full_status;
        my $session_id = $empire->start_session->id;
        return { empire_id => $empire->id, session_id => $session_id, status => $status };
    }
}

sub get_status {
    my ($self, $session_id) = @_;
    return $self->get_empire_by_session($session_id)->get_status;
}

sub get_full_status {
    my ($self, $session_id) = @_;
    return $self->get_empire_by_session($session_id)->get_full_status;
}


__PACKAGE__->register_rpc_method_names(qw(is_name_available create login logout get_full_status get_status));


no Moose;
__PACKAGE__->meta->make_immutable;

