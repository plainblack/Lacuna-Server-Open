package Lacuna::RPC::Building::Security;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/security';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Security';
}

sub view_foreign_spies {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @out;
    my $spies = $building->foreign_spies->search(undef,
        {
            rows        => 25,
            page        => $page_number,
            order_by    => 'available_on',
        }
    );
    while (my $spy = $spies->next) {
        my $available_on = $spy->format_available_on;
        push @out, {
            name                => $spy->name,
            level               => $spy->level,
            next_mission        => $available_on,
            task                => $spy->task,
        };
    }
    return {
        status                  => $self->format_status($empire, $building->body),
        spies                   => \@out,
        spy_count               => $spies->pager->total_entries,
    };
}

sub execute_prisoner {
    my ($self, $session_id, $building_id, $prisoner_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $prisoner = $building->prisoners->find($prisoner_id);
    unless (defined $prisoner) {
        confess [1002,'Could not find that prisoner.'];
    }
    unless (!$prisoner->is_available && $prisoner->task eq 'Captured' && $prisoner->on_body_id == $building->body_id) {
        confess [1010,'That person is not a prisoner.'];
    }
    my $body = $building->body;
    $body->spend_happiness($prisoner->level * 10_000)->update;
    $body->add_news(60, '%s was executed on %s today. Citizens were outraged at the lack of compassion.', $prisoner->name, $body->name);
    $prisoner->empire->send_predefined_message(
        from        => $empire,
        tags        => ['Spies','Alert'],
        filename    => 'spy_executed.txt',
        params      => [$prisoner->name, $prisoner->from_body->id, $prisoner->from_body->name, $body->x, $body->y, $body->name, $empire->id, $empire->name],
    );
    $prisoner->delete;
    return {
        status                  => $self->format_status($empire, $body),
    }
}

sub release_prisoner {
    my ($self, $session_id, $building_id, $prisoner_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $prisoner = $building->prisoners->find($prisoner_id);
    unless (defined $prisoner) {
        confess [1002,'Could not find that prisoner.'];
    }
    unless (!$prisoner->is_available && $prisoner->task eq 'Captured' && $prisoner->on_body_id == $building->body_id) {
        confess [1010,'That person is not a prisoner.'];
    }
    my $body = $building->body;
    $prisoner->task('Idle');
    $prisoner->available_on(DateTime->now);
    $prisoner->update;
    $prisoner->empire->send_predefined_message(
        tags        => ['Spies','Alert'],
        filename    => 'spy_released.txt',
        params      => [$empire->id, $empire->name, $body->x, $body->y, $body->name, $prisoner->name, $prisoner->from_body->id, $prisoner->from_body->name],
    );
    return {
        status                  => $self->format_status($empire, $body),
    }
}

sub view_prisoners {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||= 1;
    my @out;
    my $spies = $building->prisoners->search(undef,
        {
            rows        => 25,
            page        => $page_number,
            order_by    => 'available_on',
        }
    );
    while (my $spy = $spies->next) {
        my $available_on = $spy->format_available_on;
        push @out, {
            id                  => $spy->id,
            name                => $spy->name,
            level               => $spy->level,
            task                => $spy->task,
            sentence_expires    => $available_on,
        };
    }
    return {
        status                  => $self->format_status($empire, $building->body),
        prisoners               => \@out,
        captured_count          => $spies->pager->total_entries,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_prisoners view_foreign_spies execute_prisoner release_prisoner));



no Moose;
__PACKAGE__->meta->make_immutable;

