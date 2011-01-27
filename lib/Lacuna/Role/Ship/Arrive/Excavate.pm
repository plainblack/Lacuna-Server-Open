package Lacuna::Role::Ship::Arrive::Excavate;

use strict;
use Moose::Role;
use Lacuna::Util qw(randint random_element);
use Lacuna::Constants qw(ORE_TYPES FINDABLE_PLANS FOOD_TYPES);

after handle_arrival_procedures => sub {
    my ($self) = @_;
    
    # we're coming home
    return if ($self->direction eq 'in');

    # what are our chances
    my $remote_body = $self->foreign_body;
    my $body = $self->body;
    my $distance_modifier = int($body->calculate_distance_to_target($remote_body) / 7500);
    my $find = randint(1,100) - $distance_modifier;

    # found a plan
    my $empire = $body->empire;
    if ($find < 5) {
        my $class = random_element([FINDABLE_PLANS]);
        my $plan = $body->add_plan($class, 1, ($find == 1) ? randint(1,4) : 0);
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'plan_discovered_by_excavator.txt',
            params      => [$remote_body->x, $remote_body->y, $remote_body->name, ($plan->level + $plan->extra_build_level), $class->name, $body->id, $body->name],
        );
    }
    
    # found a glyph
    elsif ($find < 16) {
        my $ore = random_element([ORE_TYPES]);
        $body->add_glyph($ore);
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'glyph_discovered_by_excavator.txt',
            params      => [$remote_body->x, $remote_body->y, $remote_body->name, $ore, $body->id, $body->name],
            attachments => {
                image => {
                    title   => $ore,
                    url     => 'https://d16cbq0l6kkf21.cloudfront.net/assets/glyphs/'.$ore.'.png',
                }
            }
        );
        $empire->add_medal($ore.'_glyph');
        $body->add_news(70, sprintf('%s has uncovered a rare and ancient %s glyph on %s.',$empire->name, $ore, $remote_body->name));
    }
    
    # found some resources
    elsif ($find < 80) {
        $distance_modifier *= 75;
        my $type = random_element([ORE_TYPES, FOOD_TYPES, qw(water energy)]);
        my $amount = randint(100 + $distance_modifier, 2500 + $distance_modifier);
        $body->add_type($type, $amount)->update;
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'resources_discovered_by_excavator.txt',
            params      => [$remote_body->x, $remote_body->y, $remote_body->name, $amount, $type, $body->id, $body->name],
        );
    }
    
    # wha wha wha wahaa - nothing!
    else {
        $empire->send_predefined_message(
            tags        => ['Correspondence'],
            filename    => 'glyph_not_discovered_by_excavator.txt',
            params      => [$remote_body->x, $remote_body->y, $remote_body->name, $body->id, $body->name],
        );
    }
    
    # all pow
    $self->delete;
    confess [-1];
};

after send => sub {
    my $self = shift;
    Lacuna->cache->set('excavator_'.$self->foreign_body_id, $self->body->empire_id, 1, 60 * 60 * 24 * 30);
};


after can_send_to_target => sub {
    my ($self, $target) = @_;
    confess [1010, 'You have already sent an Excavator there in the past 30 days.'] if (Lacuna->cache->get('excavator_'.$target->id, $self->body->empire->id));
};

1;
