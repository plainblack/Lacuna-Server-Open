package Lacuna::RPC::Body;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Verify;
use Lacuna::Constants qw(BUILDABLE_CLASSES);
use DateTime;
use Lacuna::Util qw(randint);
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
    my $body = $self->get_body($empire, $body_id);
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) { 
        my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
            type            => 'AbandonStation',
            name            => 'Abandon Station',
            description     => 'Abandon the station named {Planet '.$body->id.' '.$body->name.'}.',            
            proposed_by_id  => $empire->id,
        });
        $proposition->station($body);
        $proposition->proposed_by($empire);
        $proposition->insert;
        confess [1017, 'The abandon has been delayed pending a parliamentary vote.'];
    }
    $body->abandon;
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
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        unless ($body->parliament->level >= 3) {
            confess [1013, 'You need to have a level 3 Parliament to rename a station.'];
        }
        my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
            type            => 'RenameStation',
            name            => 'Rename Station',
            scratch         => { name => $name },
            description     => 'Rename the station from {Planet '.$body->id.' '.$body->name.'} to "'.$name.'".',            
            proposed_by_id  => $empire->id,
        });
        $proposition->station($body);
        $proposition->proposed_by($empire);
        $proposition->insert;
        confess [1017, 'The rename has been delayed pending a parliamentary vote.'];
    }

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
            efficiency      => 100,
            body            => $body,
            date_created    => DateTime->now,
    );

    my %out;
    my @buildable = BUILDABLE_CLASSES;
    
    # build queue
    my $dev = $body->development;
    my $max_items_in_build_queue = 1;
    if (defined $dev) {
        $max_items_in_build_queue += $dev->level;
    }
    my $items_in_build_queue = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({body_id => $body_id, is_upgrading=>1})->count;
    
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) { 
        @buildable = ();
        $max_items_in_build_queue = 99;
    }

    # plans
    my %plans;
    my $plan_rs = $body->plans->search({level => 1},{ group_by => ['class'], order_by => { -desc => 'extra_build_level' }});
    while (my $plan = $plan_rs->next) {
        push @buildable, $plan->class->controller_class;
        $plans{$plan->class} = $plan->extra_build_level;
    }
    
    foreach my $class (uniq @buildable) {
        $properties{class} = $class->model_class;
        my $building = $building_rs->new(\%properties);
        my @tags = $building->build_tags;
        if ($properties{class} ~~ [keys %plans]) {
            push @tags, 'Plan',
        }
        if ($tag) {
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
                no_plot_use => $building->isa('Lacuna::DB::Result::Building::Permanent'),
            },
            production  => $building->stats_after_upgrade,
        };
        if (exists $plans{$properties{class}}) {
            my $building_tmp = $building;
            $building_tmp->level( $plans{$properties{class}} );
            $cost = $building_tmp->cost_to_upgrade;
            $out{$building->name}{build}{cost}{time} = $cost->{time};
            $out{$building->name}{build}{extra_level} = $plans{$properties{class}};
        }
    }

    return {buildable=>\%out, build_queue => { max => $max_items_in_build_queue, current => $items_in_build_queue}, status=>$self->format_status($empire, $body)};
}


__PACKAGE__->register_rpc_method_names(qw(abandon rename get_buildings get_buildable get_status));

no Moose;
__PACKAGE__->meta->make_immutable;

