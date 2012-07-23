package Lacuna::DB::Result::Building::Permanent::TheDillonForge;

use Moose;
use List::Util qw(shuffle);
use Data::Dumper;

use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(randint);

use constant controller_class => 'Lacuna::RPC::Building::TheDillonForge';

use constant subsidy_cost => 2;

around can_build => sub {
    my ($orig, $self, $body) = @_;
    confess [1013,"You can't build The Dillon Forge by any known process. How the hell did you manage to get a plan!?"];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    confess [1013,"You can't upgrade the Dillon Forge, the technology to do so is beyond your scientific ability."];
};

around can_downgrade => sub {
    my ($orig, $self) = @_;
    confess [1013,"You can't downgrade the Dillon Forge, it is impervious to your current level of technology."];
};

around can_demolish => sub {
    my ($orig, $self) = @_;
    confess [1013,"You can't demolish the Dillon Forge, it is impervious to your current level of technology."];
};

use constant image => 'thedillonforge';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('It is hard to believe that after going unused for nearly '.randint(10,99).',000 years, The Dillon Forge still works on %s.', $self->body->name));
};

use constant name => 'The Dillon Forge';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

sub split_plan {
    my ($self, $plan_class, $level, $extra_build_level) = @_;

    my $halls   = $self->equivalent_halls($level, $extra_build_level);
    my $class   = 'Lacuna::DB::Result::Building::'.$plan_class;
    my $body    = $self->body;
    my ($plan) = grep {
            $_->level               == $level
        and $_->class               eq $class
        and $_->extra_build_level   == $extra_build_level
    } @{$body->plan_cache};

    if (not $plan) {
        confess [1002, 'You cannot split a plan you do not have.'];
    }
    my $glyphs = Lacuna::DB::Result::Plan->get_glyph_recipe($class);
    if (not $glyphs) {
        confess [1002, 'You can only split plans that have a glyph recipe.'];
    }
    if ($class =~ m/Platform$/) {
        confess [1002, 'You cannot split a Platform plan.'];
    }
    $body->delete_one_plan($plan);

    my $build_secs = int($halls * 30 * 3600 / $self->level);
    $self->start_work({task => 'split_plan', class => $class, level => $level, extra_build_level => $extra_build_level}, $build_secs)->update;
}

sub make_plan {
    my ($self, $plan_class, $level) = @_;

    if ($level > $self->level) {
        confess [1002, 'Your Dillon Forge level is not high enough to build that high a plan level.'];
    }
    if ($plan_class =~ m/HallsOfVrbansk/) {
        confess [1002, 'It is not a good idea to create a plan you cannot use.'];
    }

    my $body = $self->body;
    # Do we have the requisite number of level 1 plans?
    my $class = 'Lacuna::DB::Result::Building::'.$plan_class;

    my ($plan) = grep {
        $_->level               => 1,
        $_->extra_build_level   => 0,
        $_->class               eq $class
    } @{$body->plan_cache};

    my $quantity_to_delete = $level * 2;

    if (not defined $plan or $plan->quantity < $quantity_to_delete) {
        confess [1002, 'You do not have enough level 1+0 plans.'];
    }

    $body->delete_many_plans($plan, $quantity_to_delete);
    
    $self->start_work({task => 'make_plan', level => $level, class => $class}, ($level * 5000))->update;
}

sub equivalent_halls {
    my ($self, $level, $extra_build_level) = @_;

    my $arg_k   = int($extra_build_level / 2 + 0.5);
    my $arg_l   = $level * 2 + $extra_build_level;
    my $arg_m   = ($extra_build_level % 2) ? 0 : $level + $extra_build_level / 2;
    my $halls   = $arg_k * $arg_l + $arg_m;

    return $halls;
}

before finish_work => sub {
    my $self = shift;

    my $work        = $self->work;
    my $body        = $self->body;
    my $empire      = $body->empire;
    my $plan_class  = $work->{class};

    if ($work->{task} eq 'make_plan') {
        $body->add_plan($plan_class, $work->{level}, 0, 1);
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'plan_created_by_forge.txt',
            params      => [$body->id, $body->name, $work->{level}, $plan_class->name],
        );
        $body->add_news(100, sprintf('%s used the Dillon Forge to create a %s plan level %s on %s.', $empire->name, $plan_class->name, $work->{level}, $body->name));
    }
    if ($work->{task} eq 'split_plan') {
        # calculate the probability of success
        my $success_percent = $self->level * 3;
        my $halls = $self->equivalent_halls($work->{level}, $work->{extra_build_level});
        
        if ($plan_class =~ m/HallsOfVrbansk$/) {
            # create a random A,B,C or D hall
            my @hall_types = ('A', 'B', 'C', 'D', 'E');
            my $hall_type = $hall_types[randint(0,4)];
            $plan_class .= " $hall_type";
        }
        my $glyphs = Lacuna::DB::Result::Plan->get_glyph_recipe($plan_class);
        my @many_glyphs = shuffle map { @$glyphs } (1..$halls);
        my $glyphs_built;
        my $total_glyphs = 0;
        for my $glyph (@many_glyphs) {
            if ($success_percent > rand(100)) {
                $glyphs_built->{$glyph} = $glyphs_built->{$glyph} ? $glyphs_built->{$glyph}+1 : 1;
                $total_glyphs++;
            }
        }
        for my $glyph (keys %{$glyphs_built}) {
          $self->body->add_glyph($glyph, $glyphs_built->{$glyph});
        }
        my @report = map { [ $glyphs_built->{$_}, $_ ]} keys %$glyphs_built;
        unshift (@report, ['Quantity','Glyph']);

        if ($total_glyphs > 0) {
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'plan_split_by_forge.txt',
                params      => [$body->id, $body->name, $work->{level}, $work->{extra_build_level}, $plan_class->name],
                attachments => { table  => \@report },
            );
            $body->add_news(100, sprintf('%s used the Dillon Forge to split a %s level %s + %s plan into %s glyphs today on %s', $empire->name, $plan_class->name, $work->{level}, $work->{extra_build_level}, $total_glyphs, $body->name));
        }
        else {
            $empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'plan_split_by_forge_failure.txt',
                params      => [$body->id, $body->name, $work->{level}, $work->{extra_build_level}, $plan_class->name],
            );
            $body->add_news(100, sprintf('%s failed miserably in an attempt to run the Dillon Forge today on %s', $empire->name, $body->name));
        }
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
