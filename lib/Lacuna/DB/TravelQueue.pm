package Lacuna::DB::TravelQueue;

use Moose;
extends 'SimpleDB::Class::Item';
use DateTime;
use Lacuna::Util qw(to_seconds format_date);

__PACKAGE__->set_domain_name('travel_queue');
__PACKAGE__->add_attributes(
    date_started        => { isa => 'DateTime' },
    date_arrives        => { isa => 'DateTime' },
    ship_type           => { isa => 'Str' },
    payload             => { isa => 'HashRef' },
#    roundtrip           => { isa => 'Int' },
    body_id             => { isa => 'Str' },
    direction           => { isa => 'Str' }, # outgoing || incoming
    foreign_body_id     => { isa => 'Str' },
    foreign_star_id     => { isa => 'Str' },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body', 'body_id');
__PACKAGE__->belongs_to('foreign_star', 'Lacuna::DB::Star', 'foreign_star_id');
__PACKAGE__->belongs_to('foreign_body', 'Lacuna::DB::Body', 'foreign_body_id');


sub date_arrives_formatted {
    my $self = shift;
    return format_date($self->date_arrives);
}

sub send {
    my ($class, %options ) = @_;
    my %params = (
        date_started        => $options{date_started} || DateTime->now,
        body_id             => $options{body}->id,
        date_arrives        => $options{date_arrives},
        ship_type           => $options{ship_type},
        payload             => $options{payload},
#        roundtrip           => $options{roundtrip},
        direction           => $options{direction},
    );
    my %insert_options = (
        set     => {
            body    => $options{body},
        },
    );
    if (exists $options{foreign_body}) {
        $params{foreign_body_id} = $options{foreign_body}->id;
        $insert_options{foreign_body} = $options{foreign_body};
    }
    if (exists $options{foreign_star}) {
        $params{foreign_star_id} = $options{foreign_star}->id;
        $insert_options{foreign_star} = $options{foreign_star};
    }
    return $options{simpledb}->domain($class)->insert(\%params, %insert_options);
}

sub seconds_remaining {
    my $self = shift;
    return to_seconds(DateTime->now - $self->date_arrives);
}

sub turn_around {
    my $self = shift;
    $self->direction( ($self->direction eq 'outgoing') ? 'incoming' : 'outgoing' );
    $self->date_arrives->add_duration( $self->date_arrives - $self->date_started );
    $self->date_started(DateTime->now);
    $self->put;
}

sub arrive {
    my ($self) = @_;
    my $empire = $self->body->empire;
    if ($self->ship_type eq 'probe') {
        $empire->add_probe($self->foreign_star_id, $self->body_id);
        $empire->trigger_full_update;
    }
    elsif ($self->ship_type eq 'spy_pod') {
        # trigger spy event on remote world
    }
    elsif ($self->ship_type eq 'colony_ship') {
        if ($self->direction eq 'outgoing') {
            my $planet = $self->foreign_body;
            if ($planet->is_locked) {
                $self->turn_around;
                $empire->send_predefined_message(
                    tags        => ['Alert'],
                    filename    => 'cannot_colonize.txt',
                    params      => [$planet->name, $planet->name],
                );
            }
            else {
                $planet->lock;
                $planet->found_colony($empire);
            }
        }
        else {
            $self->body->spaceport->add_ship($self->ship_type)->put;
        }
    }
    elsif ($self->ship_type eq 'terraforming_platform_ship') {
    }
    elsif ($self->ship_type eq 'gas_giant_settlement_platform_ship') {
    }
    elsif ($self->ship_type eq 'mining_platform_ship') {
    }
    elsif ($self->ship_type eq 'cargo_ship') {
    }
    elsif ($self->ship_type eq 'smuggler_ship') {
    }
    elsif ($self->ship_type eq 'space_station') {
    }
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable;
