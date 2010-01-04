package Lacuna::Map;

use Moose;
extends 'JSON::RPC::Dispatcher::App';

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub get_stars {
    my ($self, $session_id, $x1, $y1, $x2, $y2, $z) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ((abs($x2 - $x1) * abs($y2 - $y1)) > 100) {
        confess [1003, 'Requested area too large.'];
    }
    else {
        my $stars = $self->simpledb->domain('star')->search({z=>$z, y=>['between', $y1, $y2], x=>['between', $x1, $x2]});
        my @out;
        while (my $star = $stars->next) {
            push @out, {
                name        => $star->name,
                x           => $star->x,
                y           => $star->y,
                z           => $star->z,
                color       => $star->color,
                alignments  => ["unprobed"],
                can_rename  => 1,
            };
        }
        return { stars=>\@out, status=>$empire->get_status };
    }
}

sub get_max_x_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},['x'],1);
    return (defined $planet)  ? $planet->x : 0;
}

sub get_min_x_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},'x',1);
    return (defined $planet)  ? $planet->x : 0;
}

sub get_max_y_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},['y'],1);
    return (defined $planet)  ? $planet->y : 0;
}

sub get_min_y_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},'y',1);
    return (defined $planet)  ? $planet->y : 0;
}

sub get_max_z_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},['z'],1);
    return (defined $planet)  ? $planet->z : 0;
}

sub get_min_z_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},'z',1);
    return (defined $planet)  ? $planet->z : 0;
}


__PACKAGE__->register_rpc_method_names(qw(get_stars));

no Moose;
__PACKAGE__->meta->make_immutable;

