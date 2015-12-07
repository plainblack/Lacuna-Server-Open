package Lacuna::RPC::Building::Intelligence;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Util qw(randint);

sub app_url {
    return '/intelligence';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Intelligence';
}

sub view_spies {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    $page_number ||= 1;
    my @spies;
    my $body = $building->body;
    my %planets = ( $body->id => $body );
    my $spy_list = $building->get_spies->search(
                                                {}, {
                                                    rows => 30,
                                                    page => $page_number,
                                                    # match the order_by in L::RPC::B::SpacePort::prepare_send_spies
                                                    # and in L::RPC::B::MercinariesGuild::get_spies
                                                    order_by => {
                                                        -asc => [ qw/name id/ ]
                                                    }
                                                });
    my $cost_to_subsidize = 0;
    while (my $spy = $spy_list->next) {
        if (exists $planets{$spy->on_body_id}) {
            $spy->on_body($planets{$spy->on_body_id});
        }
        else {
            $planets{$spy->on_body_id} = $spy->on_body;
        }
        $cost_to_subsidize++ if ($spy->task eq 'Training');
        push @spies, $spy->get_status;
    }
    my @assignments = Lacuna::DB::Result::Spies->assignments;
    return {
        status                  => $self->format_status($session, $body),
        spies                   => \@spies,
        possible_assignments    => \@assignments,
        spy_count               => $spy_list->pager->total_entries,
        cost_to_subsidize       => $cost_to_subsidize,
    };
}

sub view_all_spies {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my @spies;
    my $body = $building->body;
    my %planets = ( $body->id => $body );
    my $spy_list = $building->get_spies->search();
    my $cost_to_subsidize = 0;
    while (my $spy = $spy_list->next) {
        if (exists $planets{$spy->on_body_id}) {
            $spy->on_body($planets{$spy->on_body_id});
        }
        else {
            $planets{$spy->on_body_id} = $spy->on_body;
        }
        $cost_to_subsidize++ if ($spy->task eq 'Training');
        push @spies, $spy->get_status;
    }
    my @assignments = Lacuna::DB::Result::Spies->assignments;
    return {
        status                  => $self->format_status($session, $body),
        spies                   => \@spies,
        possible_assignments    => \@assignments,
        spy_count               => scalar @spies,
        cost_to_subsidize       => $cost_to_subsidize,
    };
}

# This call is too intensive for server at this time. Disabled
# sub view_empire_spies {
#     my ($self, $session_id, $building_id) = @_;
#    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
#    my $empire   = $session->current_empire;
#    my $building = $session->current_building;
#     my @spies;
#     my $body = $building->body;
#     my %planets = ( $body->id => $body );
#     my $spy_list = $building->get_empire_spies->search();
#     my $cost_to_subsidize = 0;
#     while (my $spy = $spy_list->next) {
#         if (exists $planets{$spy->on_body_id}) {
#             $spy->on_body($planets{$spy->on_body_id});
#         }
#         else {
#             $planets{$spy->on_body_id} = $spy->on_body;
#         }
#         $cost_to_subsidize++ if ($spy->task eq 'Training');
#         push @spies, $spy->get_status;
#     }
#     my @assignments = Lacuna::DB::Result::Spies->assignments;
#     return {
#         status                  => $self->format_status($session, $body),
#         spies                   => \@spies,
#         possible_assignments    => \@assignments,
#         spy_count               => scalar @spies,
#         cost_to_subsidize       => $cost_to_subsidize,
#     };
# }

sub subsidize_training {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    unless ($building->efficiency == 100) {
        confess [1010, "You can not subsidize spies when the Intelligence Ministry is in need of repair."];
    }
    my $body = $building->body;

    my $spies = $building->get_spies->search({ task => 'Training' });

    my $cost = $spies->count;
    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];    
    }

    $empire->spend_essentia({
        amount  => $cost, 
        reason  => 'spy training subsidy after the fact',
    });    
    $empire->update;

    my $now = DateTime->now;
    while (my $spy = $spies->next) {
        $spy->available_on($now);
        $spy->task('Idle');
        $spy->update;
    }
    $building->finish_work->update;

    return $self->view($session, $building);
}


sub assign_spy {
    my ($self, $session_id, $building_id, $spy_id, $assignment) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    unless ($building->efficiency == 100) {
        confess [1010, "You can not communicate with your spy when the Intelligence Ministry is in need of repair."];
    }
    $empire->current_session->check_captcha;
    my $spy = $building->get_spy($spy_id);
    unless (defined $spy) {
        confess [1002, "Spy not found."];
    }
    my $mission = $spy->assign($assignment);
    return {
        status  => $self->format_status($session, $building->body),
        mission => $mission,
        spy     => $spy->get_status,
    };
}

sub burn_spy {
    my ($self, $session_id, $building_id, $spy_id, $assignment) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $spy = $building->get_spy($spy_id);
    unless (defined $spy) {
        confess [1002, "Spy not found."];
    }
    if ($spy->task eq 'Waiting On Trade' || $spy->task eq 'Mercenary Transport') {
        confess [1010, "You can't burn a spy involved in a trade. You must wait for the trade to complete."];
    }
    if ($spy->task eq 'Captured' or $spy->task eq 'Prisoner Transport') {
        confess [1010, "You can't burn a spy that has been captured. If you did he would have no reason not to tell your enemy all your secrets."];
    }
    if ($spy->task eq 'Killed In Action') {
        confess [1010, "You can't burn a spy that has been killed in action; he's dead, Jim."];
    }
    $spy->burn;
    return {
        status  => $self->format_status($session, $building->body),
    };
}

sub train_spy {
    my ($self, $session_id, $building_id, $quantity) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    unless ($building->efficiency == 100) {
        confess [1010, "You can not train spies when the Intelligence Ministry is in need of repair."];
    }
    $quantity ||= 1;
    if ($quantity > 5) {
        confess [1009, "You can only train 5 spies at a time."];
    }
    my $trained = 0;
    my $body = $building->body;
    if ($building->effective_level < 1) {
        confess [1013, "You can't train spies until your Intelligence Ministry is completed."];
    }
    my $costs = $building->training_costs;
    my $reason;
    SPY: foreach my $i (1..$quantity) {
        if (eval{$building->can_train_spy($costs)}) {
            $building->spend_resources_to_train_spy($costs);
            $building->train_spy($costs->{time});
            $trained++;
        }
        else {
            my ( $code, $message ) = @{$@};
            $reason = { code => $code, message => $message };
            last SPY;
        }
    }
    if ($trained) {
        $body->update;
        if ($trained >= 3) {
            $body->add_news(50, '%s has just approved a massive intelligence budget increase.', $empire->name);
        }
    }
    my $ret = {
        status  => $self->format_status($session, $body),
        trained => $trained,
        not_trained => $quantity - $trained,
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
    $ret->{reason_not_trained} = $reason;
    return $ret;
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    $out->{spies} = {
        maximum         => $building->max_spies,
        current         => $building->spy_count,
        training_costs  => $building->training_costs,
        in_training     => $building->spies_in_training_count,
    };
    return $out;
};

sub name_spy {
    my ($self, $session_id, $building_id, $spy_id, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1005, 'Invalid name for a spy.'])
        ->not_empty
        ->no_profanity
        ->length_lt(31)
        ->length_gt(2)
        ->no_restricted_chars;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $spy      = $building->get_spy($spy_id);
    $spy->name($name);
    $spy->update;
    return {
        status  => $self->format_status($session, $building->body),
    };
    
}

__PACKAGE__->register_rpc_method_names(qw(view_spies view_all_spies assign_spy train_spy burn_spy name_spy subsidize_training));


no Moose;
__PACKAGE__->meta->make_immutable;

