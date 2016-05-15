package Lacuna::DB::Result::Building::ThemePark;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use DateTime;
use Lacuna::Constants qw(FOOD_TYPES GROWTH_F INFLATION_F CONSUME_F WASTE_F HAPPY_F TINFLATE_F);

use constant prod_rate => GROWTH_F;
use constant consume_rate => CONSUME_F;
use constant cost_rate => INFLATION_F;
use constant waste_prod_rate => WASTE_F;
use constant happy_prod_rate => HAPPY_F;
use constant time_inflation => TINFLATE_F;


around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness));
};


use constant controller_class => 'Lacuna::RPC::Building::ThemePark';

use constant university_prereq => 16;

use constant image => 'themepark';

use constant name => 'Theme Park';

use constant food_to_build => 500;

use constant energy_to_build => 1005;

use constant ore_to_build => 900;

use constant water_to_build => 715;

use constant waste_to_build => 995;

use constant time_to_build => 300;

use constant max_instances_per_planet => 2;

sub food_consumption {
    my $self = shift;
    return ($self->is_working) ? 300 : 5;
}

sub energy_consumption {
    my $self = shift;
    return ($self->is_working) ? 500 : 5;
}

sub ore_consumption {
    my $self = shift;
    return ($self->is_working) ? 100 : 5;
}

sub water_consumption {
    my $self = shift;
    return ($self->is_working) ? 500 : 5;
}

sub waste_production {
    my $self = shift;
    if ($self->is_working) {
        return $self->work->{food_type_count} * 35;
    }
    return 2;
}

sub happiness_production {
    my $self = shift;
    if ($self->is_working) {
        return $self->work->{food_type_count} * 35;
    }
    return 0;
}

sub can_operate {
    my ($self) = @_;
    if ($self->effective_level < 1) {
        confess [1010, "You can't operate the Theme Park until it is built."];
    }
    my $types;
    my $body = $self->body;
    foreach my $food (FOOD_TYPES) {
        $types++ if $body->type_stored($food) >= 1000;
    }
    if ($self->is_working) {
        my $current_types = $self->work->{food_type_count};
        if ($types < $current_types) {
            confess [1011, "This Theme Park was started with ".$current_types." types of food so you need at least ".$current_types." types of food to continue its operation."];
        }
    }
    elsif ($types < 5) {
        confess [1011, "You need at least 5 types of food in quantities of at least 1,000 to start operating the Theme Park."];
    }
    return 1;
}

sub operate {
    my ($self) = @_;
    $self->can_operate;
    
    my $body = $self->body;
    my $types = 0;
    foreach my $food (FOOD_TYPES) {
        if ($body->type_stored($food) >= 1000) {
            $types++;
            $body->spend_food_type($food, 1000, 0);
        }
    }
    $body->needs_recalc(1);
    $body->update;
    
    if ($self->is_working) {
        my $new_work_ends = $self->work_ends->clone->add(seconds => 3600);
        $self->work({ food_type_count => $types });
        $self->reschedule_work($new_work_ends);
    }
    else {
        $self->start_work({ food_type_count => $types }, 60*60)->update;
    }
}

after finish_work => sub {
    my $self = shift;
    my $planet = $self->body;
    $planet->needs_recalc(1);
    $planet->update;
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
