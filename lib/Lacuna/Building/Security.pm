package Lacuna::Building::Security;

use Moose;
extends 'Lacuna::Building';

sub app_url {
    return '/security';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Security';
}


sub view_prisoners {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    $page_number ||= 1;
    my @spies;
    my %options = (
        consistent  => 1,
        where       => { on_body_id => $building->body_id, task => 'Captured', available_on => ['>=', DateTime->now->subtract(months=>1)] },
        order_by    => 'available_on',
    );
    my $count = Lacuna->db->resultset('spies')->count(%options);
    my $spy_list = Lacuna->db->resultset('spies')->search(%options)->paginate(25, $page_number);
    while (my $spy = $spy_list->next) {
        my $available_on = $spy->format_available_on;
        push @spies, {
            id                  => $spy->id,
            name                => $spy->name,
            sentence_expires    => $available_on,
        };
    }
    return {
        status                  => $empire->get_status,
        prisoners               => \@spies,
        captured_count          => $count,
    };
}

__PACKAGE__->register_rpc_method_names(qw(view_prisoners));



no Moose;
__PACKAGE__->meta->make_immutable;

