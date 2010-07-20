package Lacuna::Role::TraderRpc;

use Moose::Role;
use feature "switch";
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use Lacuna::Util qw(randint);

sub view_my_trades {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||=1;
    my $my_trades = $building->my_trades->search(undef, { rows => 25, page => $page_number });
    my @trades;
    while (my $trade = $my_trades->next) {
        push @trades, {
            id                      => $trade->id,
            date_offered            => $trade->date_offered_formatted,
            ask_description         => $trade->ask_description,
            ask_type                => $trade->ask_type,
            ask_quantity            => $trade->ask_quantity,
            offer_description       => $trade->offer_description,
            offer_type              => $trade->offer_sub_type,
            offer_quantity          => $trade->offer_quantity,
        };
    }
    return {
        trades      => \@trades,
        trade_count => $my_trades->pager->total_entries,
        page_number => $page_number,
        status      => $self->format_status($empire, $building->body),
    };
}

sub view_available_trades {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $all_trades = $building->available_trades->search(undef, { rows => 25, page => $page_number });
    $page_number ||=1;
    my @trades;
    while (my $trade = $all_trades->next) {
        push @trades, {
            id                      => $trade->id,
            date_offered            => $trade->date_offered_formatted,
            ask_description         => $trade->ask_description,
            ask_type                => $trade->ask_type,
            ask_quantity            => $trade->ask_quantity,
            offer_description       => $trade->offer_description,
            offer_type              => $trade->offer_sub_type,
            offer_quantity          => $trade->offer_quantity,
        };
    }
    return {
        trades      => \@trades,
        trade_count => $all_trades->pager->total_entries,
        page_number => $page_number,
        captcha     => $building->assign_captcha,
        status      => $self->format_status($empire, $building->body),
    };
}

sub get_ships {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {body_id => $building->body_id, task => 'docked'},
        {order_by => [ 'type', 'hold_size', 'speed']}
        );
    my @out;
    while (my $ship = $ships->next) {
        push @out, {
            id          => $ship->id,
            name        => $ship->name,
            type        => $ship->type,
            hold_size   => $ship->hold_size,
            speed       => $ship->speed,
        };
    }
    return {
        ships                   => \@out,
        cargo_space_used_each   => 50_000,
        status                  => $self->format_status($empire, $building->body),
    };
}

sub get_prisoners {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $prisoners = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        {on_body_id => $building->body_id, task => 'Captured'},
        {order_by => [ 'name' ]}
        );
    my @out;
    while (my $prisoner = $prisoners->next) {
        push @out, {
            id          => $prisoner->id,
            name        => $prisoner->name,
            level       => $prisoner->level,
        };
    }
    return {
        prisoners               => \@out,
        cargo_space_used_each   => 300,
        status                  => $self->format_status($empire, $building->body),
    };
}

sub get_plans {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $plans = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->search(
        {body_id => $building->body_id},
        {order_by => [ 'class', 'level']}
        );
    my @out;
    while (my $plan = $plans->next) {
        push @out, {
            id                      => $plan->id,
            name                    => $plan->class->name,
            level                   => $plan->level,
            extended_build_level    => $plan->extended_build_level,
        };
    }
    return {
        plans                   => \@out,
        cargo_space_used_each   => 10_000,
        status                  => $self->format_status($empire, $building->body),
    };
}

sub get_glyphs {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $glyphs = $building->body->glyphs;
    my @out;
    while (my $glyph = $glyphs->next) {
        push @out, {
            id                      => $glyph->id,
            type                    => $glyph->type,
        };
    }
    return {
        glyphs                  => \@out,
        cargo_space_used_each   => 100,
        status                  => $self->format_status($empire, $building->body),
    };
}

sub get_stored_resources {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my @types = (FOOD_TYPES, ORE_TYPES, qw(water waste energy));
    my @out;
    my $body = $building->body;
    foreach my $type (@types) {
        my $stored = $type.'_stored';
        push @out, {
            $type   => $body->$stored,
        }
    }
    return {
        resources               => \@out,
        cargo_space_used_each   => 1,
        status                  => $self->format_status($empire, $body),
    };
}

1;


