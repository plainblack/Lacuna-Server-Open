package Lacuna::DB::Result::Building::GeneticsLab;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Lacuna::Util qw(randint);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::RPC::Building::GeneticsLab';

use constant max_instances_per_planet => 1;

use constant university_prereq => 20;

use constant image => 'geneticslab';

use constant name => 'Genetics Lab';

use constant food_to_build => 315;

use constant energy_to_build => 330;

use constant ore_to_build => 300;

use constant water_to_build => 280;

use constant waste_to_build => 300;

use constant time_to_build => 500;

use constant food_consumption => 15;

use constant energy_consumption => 30;

use constant ore_consumption => 5;

use constant water_consumption => 30;

use constant waste_production => 20;

sub get_prisoners {
    my $self = shift;
    my $prisoners = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({
        task        => 'Captured',
        on_body_id  => $self->body_id,
    });
}

sub find_graftable {
    my ($self, $spy) = @_;
    my $spy_empire = $spy->empire;
    my $my_empire = $self->body->empire;
    my @graftable;
    if ($spy_empire->min_orbit < $my_empire->min_orbit) {
        push @graftable, 'min_orbit';
    }
    my @affinities = qw(max_orbit manufacturing_affinity deception_affinity research_affinity management_affinity farming_affinity mining_affinity science_affinity environmental_affinity political_affinity trade_affinity growth_affinity);
    foreach my $affinity (@affinities) {
        next unless ($spy_empire->$affinity > $my_empire->$affinity);
        push @graftable, $affinity;
    }
    return \@graftable;
}

sub get_possible_grafts {
    my $self = shift;
    my @grafts;
    foreach my $prisoner ($self->get_prisoners->all) {
        push @grafts, {
            spy                     => $prisoner->get_status,
            species                 => $prisoner->empire->get_species_stats,
            graftable_affinities    => $self->find_graftable($prisoner),
        };
    }
    return \@grafts;
}

sub graft_odds {
    my $self = shift;
    return $self->effective_level + $self->body->empire->effective_science_affinity;
}

sub is_graft_success {
    my $self = shift;
    return (randint(1, 100) <= $self->graft_odds);
}

sub survival_odds {
    my $self = shift;
    return ($self->effective_level * 3) + $self->body->empire->effective_science_affinity;
}

sub is_survival_success {
    my $self = shift;
    return (randint(1, 100) <= $self->survival_odds);
}

sub total_grafts {
    my $self = shift;
    my $empire = $self->body->empire;
    return $empire->max_orbit - $empire->min_orbit + 1
        + $empire->management_affinity
        + $empire->science_affinity
        + $empire->environmental_affinity
        + $empire->farming_affinity
        + $empire->mining_affinity
        + $empire->trade_affinity
        + $empire->political_affinity
        + $empire->manufacturing_affinity
        + $empire->growth_affinity
        + $empire->deception_affinity
        + $empire->research_affinity
        - 45;
}

sub can_experiment {
    my $self = shift;
    if ($self->total_grafts >= $self->effective_level) {
        confess [1013, 'You need to raise your genetics lab level to run more experiments.'];
    }
    return 1;
}

sub experiment {
    my ($self, $spy, $affinity) = @_;
    unless ($spy->on_body_id == $self->body_id && $spy->task eq 'Captured') {
        confess [1010, 'This spy is not a prisoner on your planet.'];
    }
    unless ($affinity ~~ $self->find_graftable($spy)) {
        confess [1013, 'This spy cannot help you with that type of graft.'];
    }
    my $empire = $self->body->empire;
    if ($empire->essentia < 2) {
        confess [1011, 'You need 2 essentia to perform a graft experiment.'];
    }
    $empire->spend_essentia({
        amount  => 2, 
        reason  => 'genetics lab graft experiment',
    });
    my $graft = 0;
    my $survival = 0;
    my $message;
    if ($self->is_graft_success) {
        if ($affinity eq 'min_orbit') {
            $empire->min_orbit( $empire->min_orbit - 1 );
        }
        else {
            $empire->$affinity( $empire->$affinity + 1 );
        }
        $graft = 1;
        $message = 'The graft was a success';
    }
    else {
        $message = 'The graft failed';
    }
    $empire->update;
    $empire->planets->update({needs_recalc=>1});
    if ($self->is_survival_success) {
        $survival = 1;
        $message .= ', and the prisoner survived the experiment.';
    }
    else {
        $spy->killed_in_action;
        $spy->delete;
        $message .= ', and the prisoner did not survive the experiment.';
    }
    return {
        graft   => $graft,
        survive => $survival,
        message => $message,
    };
}

sub rename_species {
    my ($self, $me) = @_;
    my $empire = $self->body->empire;
    $empire->species_name($me->{name});
    $empire->species_description($me->{description}) if $me->{description};
    $empire->update;
    return { success => 1 };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
