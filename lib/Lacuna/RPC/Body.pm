package Lacuna::RPC::Body;

use Moose;
extends 'Lacuna::RPC';
use Lacuna::Verify;
use Lacuna::Constants qw(BUILDABLE_CLASSES);
use DateTime;
use List::MoreUtils qw(uniq);

sub get_status {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->get_body($empire, $body_id);
    return $self->format_status($empire, $body);
}

sub abandon {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ($body_id eq $empire->home_planet_id) {
        confess [1010, 'You cannot abandon your home colony.'];
    }
    my $body = $self->get_body($empire, $body_id);
    $body->sanitize;
    return $self->format_status($empire);
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

    return 1 if $name eq $body->name;

    my $cache = Lacuna->cache;
    unless ($cache->get('body_rename_spam_lock',$body->id)) {
        $cache->set('body_rename_spam_lock',$body->id, 1, 60*60);
        $body->add_news(200,"In a bold move to show its growing power, %s renamed %s to %s.",$empire->name, $body->name, $name);
    }
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
            efficiency => $building->efficiency,
        };
        if ($building->is_upgrading) {
            $out{$building->id}{pending_build} = $building->upgrade_status;
        }
        if ($building->is_working) {
            $out{$building->id}{work} = {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            };
        }
    }
    
    return {buildings=>\%out, body=>{surface_image => $body->surface}, status=>$self->format_status($empire, $body)};
}


sub get_buildable {
    my ($self, $session_id, $body_id, $x, $y, $tag) = @_;
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
    my @plans;
    my $plan_rs = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->search({body_id => $body_id, level => 1});
    while (my $plan = $plan_rs->next) {
        push @buildable, $plan->class->controller_class;
        push @plans, $plan->class;
    }
    
    foreach my $class (uniq @buildable) {
        $properties{class} = $class->model_class;
        my $building = $building_rs->new(\%properties);
        my @tags = $building->build_tags;
        if ($properties{class} ~~ \@plans) {
            push @tags, 'Plan',
        }
if ($tag) { # REMOVE IF AFTER CLIENTS SUPPORT THIS
        next unless ($tag ~~ \@tags);
}
        my $cost = $building->cost_to_upgrade;
        my $can_build = eval{$body->has_met_building_prereqs($building, $cost)};
        my $reason = $@;
        if ($can_build) {
            push @tags, 'Now';          
        }
        elsif ($reason->[0] == 1011) {
            push @tags, 'Soon';
        }
        else {
            push @tags, 'Later';
        }
        $out{$building->name} = {
            url         => $class->app_url,
            image       => $building->image_level,
            build       => {
                can         => ($can_build) ? 1 : 0,                
                cost        => $cost,
                reason      => $reason,
                tags        => \@tags,
            },
            production  => $building->stats_after_upgrade,
        };
    }

    return {buildable=>\%out, status=>$self->format_status($empire, $body)};
}


__PACKAGE__->register_rpc_method_names(qw(abandon rename get_build_queue get_buildings get_buildable get_status));

no Moose;
__PACKAGE__->meta->make_immutable;

