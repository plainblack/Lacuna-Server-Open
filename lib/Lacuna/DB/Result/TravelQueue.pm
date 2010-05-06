package Lacuna::DB::Result::TravelQueue;

use Moose;
extends 'Lacuna::DB::Result';
use DateTime;
use Lacuna::Util qw(to_seconds format_date);

__PACKAGE__->table('travel_queue');
__PACKAGE__->add_columns(
    date_started            => { data_type => 'datetime', is_nullable => 0 },
    date_arrives            => { data_type => 'datetime', is_nullable => 0 },
    name                    => { data_type => 'char', size => 30, is_nullable => 0 },
    payload                 => { data_type => 'mediumtext', is_nullable => 1, 'serializer_class' => 'JSON' },
#    roundtrip              => { data_type => 'int', size => 11, default_value => 0 },
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    direction               => { data_type => 'char', size => 8, is_nullable => 0 }, # outgoing || incoming
    foreign_body_id         => { data_type => 'int', size => 11, is_nullable => 1 },
    foreign_star_id         => { data_type => 'int', size => 11, is_nullable => 1 },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Body', 'body_id');
__PACKAGE__->belongs_to('foreign_star', 'Lacuna::DB::Result::Star', 'foreign_star_id');
__PACKAGE__->belongs_to('foreign_body', 'Lacuna::DB::Result::Body', 'foreign_body_id');


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
                $empire->send_predefined_message(
                    tags        => ['Alert'],
                    filename    => 'colony_founded.txt',
                    params      => [$planet->name, $planet->name],
                );
                $empire->is_isolationist(0);
                $empire->trigger_full_update(skip_put=>1);
                $empire->put;
            }
        }
        else {
            $self->body->spaceport->add_ship($self->ship_type)->put;
        }
    }
    
    elsif ($self->ship_type eq 'terraforming_platform_ship') {
        if ($self->direction eq 'outgoing') {
            my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::TerraformingLab');
            if (defined $lab) {
                $self->foreign_body->add_freebie('Lacuna::DB::Result::Building::Permanent::TerraformingPlatform', $lab->level)->put;
            }
        }
        else {
            $self->body->spaceport->add_ship($self->ship_type)->put;
        }
    }
    
    elsif ($self->ship_type eq 'gas_giant_settlement_platform_ship') {
        if ($self->direction eq 'outgoing') {
            my $lab = $self->body->get_building_of_class('Lacuna::DB::Result::Building::GasGiantLab');
            if (defined $lab) {
                $self->foreign_body->add_freebie('Lacuna::DB::Result::Building::Permanent::GasGiantPlatform', $lab->level)->put;
            }
        }
        else {
            $self->body->spaceport->add_ship($self->ship_type)->put;
        }
    }
    
    elsif ($self->ship_type eq 'mining_platform_ship') {
        if ($self->direction eq 'outgoing') {
            my $ministry = $self->body->mining_ministry;
            if (eval{$ministry->can_add_platform} && !$@) {
                $ministry->add_platform($self->foreign_body)->put;
            }
            else {
                $self->turn_around;
            }
        }
        else {
            $self->body->spaceport->add_ship($self->ship_type)->put;
        }
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
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
