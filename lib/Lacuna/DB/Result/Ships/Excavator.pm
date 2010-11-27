package Lacuna::DB::Result::Ships::Excavator;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';
use Lacuna::Util qw(randint random_element);
use Lacuna::Constants qw(ORE_TYPES FINDABLE_PLANS FOOD_TYPES);

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Archaeology',  level => 15 };
use constant base_food_cost      => 400;
use constant base_water_cost     => 1000;
use constant base_energy_cost    => 8500;
use constant base_ore_cost       => 11000;
use constant base_time_cost      => 20000;
use constant base_waste_cost     => 1200;
use constant base_speed     => 1800;
use constant base_stealth   => 0;
use constant base_hold_size => 0;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Exploration));
};

sub arrive {
    my ($self) = @_;
    $self->note_arrival;
    my $find = randint(1,100);
    my $remote_body = $self->foreign_body;
    my $body = $self->body;
    my $empire = $body->empire;
    if ($find < 5) {
        my $class = random_element([FINDABLE_PLANS]);
        my $plan = $body->add_plan($class, 1, ($find == 1) ? randint(1,3) : 0);
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'plan_discovered_by_excavator.txt',
            params      => [$remote_body->x, $remote_body->y, $remote_body->name, ($plan->level + $plan->extra_build_level), $class->name, $body->id, $body->name],
        );
    }
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
                    url     => Lacuna->config->get('feeds/surl').'assets/glyphs/'.$ore.'.png',
                }
            }
        );
        $empire->add_medal($ore.'_glyph');
        $body->add_news(70, sprintf('%s has uncovered a rare and ancient %s glyph on %s.',$empire->name, $ore, $remote_body->name));
    }
    elsif ($find < 66) {
        my $type = random_element([ORE_TYPES, FOOD_TYPES, qw(water energy)]);
        my $amount = randint(100,2500);
        $body->add_type($type, $amount)->update;
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'resources_discovered_by_excavator.txt',
            params      => [$remote_body->x, $remote_body->y, $remote_body->name, $amount, $type, $body->id, $body->name],
        );
    }
    else {
        $empire->send_predefined_message(
            tags        => ['Correspondence'],
            filename    => 'glyph_not_discovered_by_excavator.txt',
            params      => [$remote_body->x, $remote_body->y, $remote_body->name, $body->id, $body->name],
        );
    }
    $self->delete;
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to bodies.'] unless ($target->isa('Lacuna::DB::Result::Map::Body'));
    confess [1013, 'Can only be sent to uninhabited bodies.'] if ($target->empire_id);
    confess [1010, 'You have already sent an Excavator there in the past 30 days.'] if (Lacuna->cache->get('excavator_'.$target->id, $self->body->empire->id));
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
