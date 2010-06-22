package Lacuna::RPC::Body;

use Moose;
extends 'Lacuna::RPC';
use Lacuna::Verify;
use Lacuna::Constants qw(BUILDABLE_CLASSES);
use DateTime;
use List::MoreUtils qw(uniq);

sub get_status {
    my ($self, $session_id, $body_id) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    unless (defined $body) {
        confess [1002, 'Body does not exist.', $body_id];
    }
    my $empire = $self->get_empire_by_session($session_id);
    return $self->format_status($empire, $body);
}

sub rename {
    my ($self, $session_id, $body_id, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Name not available.',$name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->no_padding
        ->not_ok(Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({name=>$name, 'id'=>{'!='=>$body_id}})->count); # name available
    
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    $body->add_news(200,"In a bold move to show its growing power, %s renamed %s to %s.",$empire->name, $body->name, $name);
    $body->update({name => $name});
    return 1;
}

sub get_buildings {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    if ($body->needs_surface_refresh) {
        $body->needs_surface_refresh(0);
        $body->update;
    }
    my %out;
    my $buildings = $body->buildings;
    while (my $building = $buildings->next) {
        $out{$building->id} = {
            url     => $building->controller_class->app_url,
            image   => $building->image_level,
            name    => $building->name,
            x       => $building->x,
            y       => $building->y,
            level   => $building->level,
        };
    }
    
    return {buildings=>\%out, body=>{surface_image => $body->surface}, status=>$self->format_status($empire, $body)};
}

sub get_build_queue {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my %queue;
    my $builds = $body->builds;
    while (my $build = $builds->next) {
        my $status = $build->upgrade_status;
        if ($status) {
            $queue{$build->id} = $status;
        }
    }
    return { build_queue => \%queue, status => $self->format_status($empire, $body) };
}

sub get_buildable {
    my ($self, $session_id, $body_id, $x, $y) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    my $building_rs = Lacuna->db->resultset('Lacuna::DB::Result::Building');

    $body->check_for_available_build_space($x, $y);

    # dummy building properties
    my %properties = (
            x               => $x,
            y               => $y,
            level           => 0,
            body_id         => $body->id,
            body            => $body,
            date_created    => DateTime->now,
    );

    my %out;
    my @buildable = BUILDABLE_CLASSES;
    
    # plans
    my $plans = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->search({body_id => $body_id, level => 1});
    while (my $plan = $plans->next) {
        push @buildable, $plan->class;
    }
    
    foreach my $class (uniq @buildable) {
        $properties{class} = $class->model_class;
        my $building = $building_rs->new(\%properties);
        my $cost = $building->cost_to_upgrade;
        my $can_build = eval{$body->has_met_building_prereqs($building, $cost)};
        my $reason = $@;
        my @extra_tags;
        if ($can_build) {
            push @extra_tags, 'Now';          
        }
        elsif ($reason->[0] == 1011) {
            push @extra_tags, 'Soon';
        }
        else {
            push @extra_tags, 'Later';
        }
        $out{$building->name} = {
            url         => $class->app_url,
            image       => $building->image_level,
            build       => {
                can         => ($can_build) ? 1 : 0,                
                cost        => $cost,
                reason      => $reason,
                tags        => [$building->build_tags, @extra_tags],
            },
            production  => $building->stats_after_upgrade,
        };
    }

    return {buildable=>\%out, status=>$self->format_status($empire, $body)};
}


__PACKAGE__->register_rpc_method_names(qw(rename get_build_queue get_buildings get_buildable get_status));

no Moose;
__PACKAGE__->meta->make_immutable;

