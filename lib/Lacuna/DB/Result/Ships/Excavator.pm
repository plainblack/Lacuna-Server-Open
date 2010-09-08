package Lacuna::DB::Result::Ships::Excavator;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';
use Lacuna::Util qw(randint random_element);
use Lacuna::Constants qw(ORE_TYPES FINDABLE_PLANS);

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Archaeology',  level => 15 };
use constant base_food_cost      => 400;
use constant base_water_cost     => 1000;
use constant base_energy_cost    => 8500;
use constant base_ore_cost       => 11000;
use constant base_time_cost      => 20000;
use constant base_waste_cost     => 1200;
use constant base_speed     => 1800;
use constant base_stealth   => 0;
use constant base_hold_size => 80;


sub arrive {
    my ($self) = @_;
    my $find = randint(1,100);
    my $remote_body = $self->foreign_body;
    my $body = $self->body;
    my $empire = $body->empire;
    if ($find < 5) {
        my $class = random_element([FINDABLE_PLANS]);
        my $plan = $body->add_plan($class, 1, ($find < 3) ? 1 : 0);
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'plan_discovered_by_excavator.txt',
            params      => [$remote_body->name, ($plan->level + $plan->extra_build_level), $class->name, $body->name],
        );
    }
    elsif ($find < 15) {
        my $ore = random_element([ORE_TYPES]);
        $body->add_glyph($ore);
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'glyph_discovered_by_excavator.txt',
            params      => [$remote_body->name, $ore, $body->name],
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
    $self->delete;
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to bodies.'] unless ($target->isa('Lacuna::DB::Result::Map::Body'));
    confess [1013, 'Can only be sent to uninhabited bodies.'] if ($target->empire_id);
    confess [1010, 'You have already sent an Excavator there in the past 30 days.'] if (Lacuna->cache->get('excavator_'.$target->id, $self->body->empire->id));
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
