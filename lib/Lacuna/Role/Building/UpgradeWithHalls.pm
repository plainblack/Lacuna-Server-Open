package Lacuna::Role::Building::UpgradeWithHalls;

use Moose::Role;

use constant build_with_halls => 1;

around can_upgrade => sub {
    my $orig = shift;
    my $self = shift;

    my $body = $self->body;
    if ($body->get_plan(ref $self, $self->level + 1)) {
        return $self->$orig(@_);
    }

    # Do we have enough hall (plans) to upgrade?
    my ($plan) = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk'} @{$body->plan_cache};
    my $plans = defined $plan ? $plan->quantity : 0;
    
    if ($plans < $self->level + 1) {
        confess [1013,
                 sprintf ("You can't upgrade this %s, you have %d Halls of Vrbansk plan%s but need %d.",
                          $self->name, $plans, $plans == 1 ? "" : "s", $self->level + 1),
                ];
    }
    return $self->$orig(@_);
};

before start_upgrade => sub {
    my ($self, $cost) = @_;

    my ($plans) = grep {$_->class eq 'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk'} @{$self->body->plan_cache};
    if (defined $cost and $cost->{halls}) {
        $self->body->delete_many_plans($plans, $cost->{halls});
    }
};

1;

