package Lacuna::Building::Intelligence;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/intelligence';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Intelligence';
}

sub view_spies {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    $page_number ||= 1;
    my @spies;
    my $body = $building->body;
    my %planets = ( $body->id => $body->name );
    my $spy_list = $building->get_spies->search({}, { rows => 25, page => $page_number});
    while (my $spy = $spy_list->next) {
        unless (exists $planets{$spy->on_body_id}) {
            $planets{$spy->on_body_id} = $spy->on_body->name;
        }
        my $available = $spy->is_available;
        my $available_on = $spy->format_available_on;
        push @spies, {
            id          => $spy->id,
            name        => $spy->name,
            assignment  => $spy->task,
            assigned_to => {
                body_id => $spy->on_body_id,
                name    => $planets{$spy->on_body_id},
            },
            is_available=> $available,
            available_on=> $available_on,
        };
    }
    my @assignments = Lacuna::DB::Result::Spies->assignments;
    return {
        status                  => $empire->get_status,
        spies                   => \@spies,
        possible_assignments    => \@assignments,
        spy_count               => $spy_list->pager->total_entries,
    };
}

sub assign_spy {
    my ($self, $session_id, $building_id, $spy_id, $assignment) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    my $spy = $building->get_spy($spy_id);
    $spy->assign($assignment)->update;
    return {
        status  => $empire->get_status,
    };
}

sub burn_spy {
    my ($self, $session_id, $building_id, $spy_id, $assignment) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    my $spy = $building->get_spy($spy_id);
    my $body = $building->body;
    if ($body->add_news(10, 'This reporter has just learned that %s has a policy of burning its own loyal spies.', $empire->name)) {
        $body->spend_happiness(1000);
        $body->put;
        $empire->trigger_full_update;
    }
    $spy->delete;
    return {
        status  => $empire->get_status,
    };
}

sub train_spy {
    my ($self, $session_id, $building_id, $quantity) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    $quantity ||= 1;
    if ($quantity > 5) {
        confess [1009, "You can only train 5 spies at a time."];
    }
    my $trained = 0;
    my $body = $building->body;
    $body->tick;
    $building = $empire->get_building($self->model_class, $building_id); #might be stale
    $building->body($body);
    if ($building->level < 1) {
        confess [1013, "You can't train spies until your Intelligence Ministry is completed."];
    }
    my $costs = $building->training_costs;
    SPY: foreach my $i (1..$quantity) {
        foreach my $resource (qw(water ore food energy)) {
            my $stored = $resource.'_stored';
            unless ($body->$stored >= $costs->{$resource}) {
                last SPY;
            }
        }
        foreach my $resource (qw(water ore food energy)) {
            my $spend = 'spend_'.$resource;
            $body->$spend($costs->{$resource});
        }
        $body->add_waste($costs->{waste});
        $building->train_spy($costs->{time});
        $trained++;
    }
    if ($trained) {
        $body->put;
        if ($trained == 5) {
            $body->add_news(50, '%s has just approved a massive intelligence budget increase.', $empire->name);
        }
    }
    return {
        status  => $empire->get_status,
        trained => $trained,
        not_trained => $quantity - $trained,
    }
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_domain, $building_id);
    my $out = $orig->($self, $empire, $building);
    $out->{spies} = {
        maximum         => $building->max_spies,
        current         => $building->spy_count,
        training_costs  => $building->training_costs,
    };
    return $out;
};

sub name_spy {
    my ($self, $session_id, $building_id, $spy_id, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1005, 'Invalid name for a spy.'])
        ->not_empty
        ->no_profanity
        ->length_lt(31)
        ->no_restricted_chars;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $building->is_offline;
    my $spy = $building->get_spy($spy_id);
    $spy->name($name);
    $spy->update;
    return {
        status  => $empire->get_status,
    };
    
}

__PACKAGE__->register_rpc_method_names(qw(view_spies assign_spy train_spy burn_spy name_spy));


no Moose;
__PACKAGE__->meta->make_immutable;

