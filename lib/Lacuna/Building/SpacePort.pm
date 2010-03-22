package Lacuna::Building::SpacePort;

use Moose;
extends 'Lacuna::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use Lacuna::Util qw(cname format_date);

sub app_url {
    return '/spaceport';
}

sub model_class {
    return 'Lacuna::DB::Building::SpacePort';
}

sub spaceports {
    my ($self, $body) = @_;
    return $self->simpledb->domain($self->model_class)->search(
        where   => { body_id => $body->id, class => $self->model_class },
        set     => { body => $body, empire => $body->empire }
    );
}

sub send_probe {
    my ($self, $session_id, $body_id, $target) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $empire->get_body($body_id);
    my $star;
    if (exists $target->{star_id}) {
        $star = $self->simpledb->domain('star')->find($target->{star_id});
    }
    elsif (exists $target->{star_name}) {
        $star = $self->simpledb->domain('star')->search(
            where   => { name_cname => cname($target->{star_name}) },
        )->next;
    }
    elsif (exists $target->{x}) {
        $star = $self->simpledb->domain('star')->search(
            where   => { x => $target->{x}, y => $target->{y}, z => $target->{z} },
        )->next;
    }
    unless (defined $star) {
        confess [ 1002, 'No such star.', $target];
    }
    my $ports = $self->spaceports($body);
    my $sent;
    while (my $port = $ports->next) {
        if ($port->probe_count) {
            $sent = $port->send_probe($star);
            last;
        }
    }
    unless ($sent) {
        confess [ 1002, 'You have no probes to send.'];
    }
    return { probe => { date_arrives => format_date($sent->date_arrives)}, status => $empire->get_status };
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $out = $orig->($self, $empire, $building);
    return $out unless $building->level > 0;
    $building->check_for_completed_ships($building);
    my %ships;
    foreach my $type (SHIP_TYPES) {
        my $count = $type.'_count';
        $ships{$type} = $building->$count;
    }
    $out->{docked_ships} = \%ships;
    return $out;
};

__PACKAGE__->register_rpc_method_names(qw(send_probe));


no Moose;
__PACKAGE__->meta->make_immutable;

