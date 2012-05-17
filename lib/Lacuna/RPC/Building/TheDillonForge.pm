package Lacuna::RPC::Building::TheDillonForge;

use Moose;
use utf8;
use List::Util qw(min max);

no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';

sub app_url {
    return '/thedillonforge';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Permanent::TheDillonForge';
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id, skip_offline => 1);
    my $out = $orig->($self, $empire, $building);
    if ($building->is_working) {
        $out->{tasks} = {
            seconds_remaining  => $building->work_seconds_remaining,
            can                => 0,
        };
    }
    else {
        $out->{tasks} = $self->_forge_tasks($building);
    }
    $out->{subsidy_cost} = $building->subsidy_cost;
    return $out;
};

# A number which represents how many Halls of Vrbansk it would take to build the plan
sub equivalent_halls {
    my ($self, $plan) = @_;

    my $arg_k   = int($plan->extra_build_level / 2 + 0.5);
    my $arg_l   = $plan->level * 2 + $plan->extra_build_level;
    my $arg_m   = ($plan->extra_build_level % 2) ? 0 : $plan->level + $plan->extra_build_level / 2;
    my $halls   = $arg_k * $arg_l + $arg_m;

    return $halls;
}

sub _forge_tasks {
    my ($self, $building) = @_;

    my $building_level = $building->level ? $building->level : 1;

    # How many plans do we have?
    my $plans_rs = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->search({
        body_id             => $building->body_id,
    }, {
        order_by => [qw(class)],
        group_by => [qw(class level extra_build_level)],
        select   => ['class','level','extra_build_level',{count => 'id', -as => 'count_plans'}],
        as       => ['class','level','extra_build_level','no_of_plans'],
    });
    my @split_plans;
PLAN:
    while (my $plan = $plans_rs->next) {
        # Can only split plans with recipes
        next PLAN if not Lacuna::DB::Result::Plans->get_glyph_recipe($plan->class);

        my ($class) = $plan->class =~ m/Lacuna::DB::Result::Building::(.*)$/;

        my $halls = $self->equivalent_halls($plan);

        push @split_plans, {
            name                => $plan->class->name,
            class               => $class,
            level               => $plan->level,
            extra_build_level   => $plan->extra_build_level,
            fail_chance         => 100 - ($building->level * 3),
            reset_seconds       => $halls * 30 * 3600 / $building->level,
        };
    }
    # now refine the search for level 1 plans only
    $plans_rs = $plans_rs->search({
        body_id             => $building->body_id,
        level               => 1,
        extra_build_level   => 0,
    });

    my @make_plans;
    while (my $plan = $plans_rs->next) {
        # It takes 2 level 1 plans for each level we are constructing.
        my $max_level = min(int($plan->get_column('no_of_plans') / 2), $building_level);
        if ($max_level >= 2) {
            my ($class) = $plan->class =~ m/Lacuna::DB::Result::Building::(.*)$/;
            push @make_plans, {
                name                => $plan->class->name,
                max_level           => $max_level,
                class               => $class,
                reset_sec_per_level => 5000,
            };
        }
    }

    return {
        can         => 1,
        make_plan   => \@make_plans,
        split_plan  => \@split_plans,
    };
}

sub split_plan {
    my ($self, $session_id, $building_id, $plan_class, $level, $extra_build_level) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    $building->split_plan($plan_class, $level, $extra_build_level);

    return $self->view($empire, $building);
}

sub make_plan {
    my ($self, $session_id, $building_id, $plan_class, $level) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    $building->make_plan($plan_class, $level);

    return $self->view($empire, $building);
}
        
sub subsidize {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);

    unless ($building->is_working) {
        confess [1010, "Nothing is being done!"];
    }

    my $subsidy_cost = $building->subsidy_cost;

    unless ($empire->essentia >= $subsidy_cost) {
        confess [1011, "Not enough essentia."];
    }

    $building->finish_work->update;
    $empire->spend_essentia($subsidy_cost, 'Dillon Forge subsidy after the fact');
    $empire->update;

    return $self->view($empire, $building);
}

__PACKAGE__->register_rpc_method_names(qw(split_plan make_plan subsidize));

no Moose;
__PACKAGE__->meta->make_immutable;
1;

