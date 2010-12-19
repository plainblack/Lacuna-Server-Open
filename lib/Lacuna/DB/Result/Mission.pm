package Lacuna::DB::Result::Mission;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date commify);
use UUID::Tiny ':std';
use Config::JSON;
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use feature 'switch';

__PACKAGE__->table('mission');
__PACKAGE__->add_columns(
    mission_file_name       => { data_type => 'varchar', size => 100, is_nullable => 0 },
    zone                    => { data_type => 'varchar', size => 16, is_nullable => 0 },
    date_posted             => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    max_university_level    => { data_type => 'tinyint', is_nullable => 0 },
    scratch                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
);

has params => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Config::JSON->new('/data/Lacuna-Mission/missions/'. $self->mission_file_name);
    },
);

sub log {
    my $self = shift;
    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Mission');
    my $log = $logs->search({filename => $self->mission_file_name},{rows => 1})->single;
    unless (defined $log) {
        $log = $logs->new({filename => $self->mission_file_name})->insert;
    }
    return $log;
}

sub incomplete {
    my $self = shift;
    my $log = $self->log;
    $log->update({ incompletes => $log->incompletes + 1});
    $self->delete;
}

sub complete {
    my ($self, $body) = @_;
    $self->spend_objectives($body);
    $self->add_rewards($body);
    Lacuna->cache->set($self->mission_file_name, $body->empire_id, 1, 60 * 60 * 24 * 30);
    Lacuna->db->resultset('Lacuna::DB::Result::News')->new({
        zone                => $self->zone,
        headline            => sprintf($self->params->get('network_19_completion'), $body->empire->name),
    })->insert;
    $self->add_next_part;
    my $log = $self->log;
    $log->update({
        completes           => $log->completes + 1,
        complete_uni_level  => $log->complete_uni_level + $body->empire->university_level,
        seconds_to_complete => $log->seconds_to_complete + time() - $self->date_posted->epoch,
    });
    $self->delete;
}

sub skip {
    my ($self, $body) = @_;
    Lacuna->cache->set($self->mission_file_name, $body->empire_id, 1, 60 * 60 * 24 * 30);
    my $log = $self->log;
    $log->update({
        skips           => $log->skips + 1,
        skip_uni_level  => $log->skip_uni_level + $body->empire->university_level,
    });
}

sub add_next_part {
    my $self = shift;
    $self->mission_file_name =~ m/^([a-z0-9\-\_]+)\.((mission)|(part\d+))$/i;
    my ($name, $ext) = ($1, $2);
    if ($ext eq 'mission') {
        $name .= '.part2';
    }
    else {
        $ext =~ m/^part(\d+)$/;
        $name .= '.part'.$1;
    }
    return Lacuna::DB::Result::Mission->initialize($self->zone, $name);
}

sub add_rewards {
    my ($self, $body) = @_;
    my $rewards = $self->params->get('mission_reward');
    # essentia
    if (exists $rewards->{essentia}) {
        $body->empire->add_essentia($rewards->{essentia}, 'mission reward')->update;
    }
    
    # happiness
    if (exists $rewards->{happiness}) {
        $body->add_happiness($rewards->{happiness});
    }

    # resources
    if (exists $rewards->{resources}) {
        foreach my $resource (keys %{$rewards->{resources}}) {
            $body->add_type($resource, $rewards->{resources}{$resource});
        }
    }
    $body->update;

    # glyphs
    if (exists $rewards->{glyphs}) {
        foreach my $glyph (@{$rewards->{glyphs}}) {
            $body->add_glyph($glyph);
        }
    }

    # ships
    if (exists $rewards->{ships}) {
        foreach my $ship (@{$rewards->{ships}}) {
            $body->ships->new({
                type        => $ship->{type},
                name        => $ship->{type},
                speed       => $ship->{speed} || 0,
                combat      => $ship->{combat} || 0,
                stealth     => $ship->{stealth} || 0,
                hold_size   => $ship->{hold_size} || 0,
                body_id     => $body->id,
                task        => 'Docked',
            })->insert;
        }
    }

    # plans
    if (exists $rewards->{plans}) {
        foreach my $plan (@{$rewards->{plans}}) {
            $body->add_plan($plan->{classname}, $plan->{level}, $plan->{extra_build_level});
        }
    }
}

sub spend_objectives {
    my ($self, $body) = @_;
    my $objectives = $self->params->get('mission_objective');
    # essentia
    if (exists $objectives->{essentia}) {
        $body->empire->spend_essentia($objectives->{essentia},'mission objective')->update;
    }
    
    # happiness
    if (exists $objectives->{happiness}) {
        $body->spend_happiness($objectives->{happiness});
    }
    
    # resources
    if (exists $objectives->{resources}) {
        foreach my $resource (keys %{$objectives->{resources}}) {
            $body->spend_type($resource, $objectives->{resources}{$resource});
        }
    }
    $body->update;

    # glyphs
    if (exists $objectives->{glyphs}) {
        foreach my $glyph (@{$objectives->{glyphs}}) {
            $body->glyphs->search({ type => $glyph },{rows => 1})->single->delete;
        }
    }

    # ships
    if (exists $objectives->{ships}) {
        foreach my $ship (@{$objectives->{ships}}) {
            $body->ships->search(
                {
                    task        => 'Docked',
                    type        => $ship->{type},
                    combat      => {'>=' => $ship->{combat}},
                    speed       => {'>=' => $ship->{speed}},
                    stealth     => {'>=' => $ship->{stealth}},
                    hold_size   => {'>=' => $ship->{hold_size}},
                },
                {rows => 1, order_by => 'id'}
                )->single->delete;
        }
    }

    # plans
    if (exists $objectives->{plans}) {
        foreach my $plan (@{$objectives->{plans}}) {
            $body->plans->search(
                { class => $plan->{classname}, level => {'>=' => $plan->{level}}, extra_build_level => {'>=' => $plan->{extra_build_level}} },
                {rows => 1, order_by => 'id'},
                )->single->delete;
        }
    }
}

sub check_objectives {
    my ($self, $body) = @_;
    my $objectives = $self->params->get('mission_objective');
    
    # essentia
    if (exists $objectives->{essentia}) {
        if ($body->empire->essentia < $objectives->{essentia}) {
            confess [1013, 'You do not have the essentia needed to complete this mission.'];
        }
    }
    
    # happiness
    if (exists $objectives->{happiness}) {
        if ($body->happiness < $objectives->{happiness}) {
            confess [1013, 'You do not have the happiness needed to complete this mission.'];
        }
    }
    
    # resources
    if (exists $objectives->{resources}) {
        foreach my $resource (keys %{$objectives->{resources}}) {
            if ($body->type_stored($resource) < $objectives->{resources}{$resource}) {
                confess [1013, 'You do not have the '.$resource.' needed to complete this mission.'];
            }
        }
    }

    # glyphs
    if (exists $objectives->{glyphs}) {
        my %glyphs;
        foreach my $glyph (@{$objectives->{glyphs}}) {
            $glyphs{$glyph}++;
        }
        foreach my $glyph (@{$objectives->{glyphs}}) {
            unless ($body->glyphs->search({ type => $glyph })->count) {
                confess [1013, 'You do not have the '.$glyph.' glyph needed to complete this mission.'];
            }
        }
    }

    # ships
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    if (exists $objectives->{ships}) {
        my @ids;
        foreach my $ship (@{$objectives->{ships}}) {
            my $this = $body->ships->search({
                    type        => $ship->{type},
                    combat      => {'>=' => $ship->{combat}},
                    speed       => {'>=' => $ship->{speed}},
                    stealth     => {'>=' => $ship->{stealth}},
                    hold_size   => {'>=' => $ship->{hold_size}},
                    task        => 'Docked',
                    id          => { 'not in' => \@ids },
                },{
                   rows     =>1,
                   order_by => 'id',
                })->single;
            if (defined $this) {
                push @ids, $this->id;
            }
            else {
                my $ship = $ships->new({type=>$ship->{type}});
                confess [1013, 'You do not have the '.$ship->type_formatted.' needed to complete this mission.'];
            }
        }
    }

    # fleet movement
    if (exists $objectives->{fleet_movement}) {
        my $bodies = Lacuna->db->resultset("Lacuna::DB::Result::Map::Body");
        my $stars = Lacuna->db->resultset("Lacuna::DB::Result::Map::Star");
        foreach my $movement (@{$self->scratch->{fleet_movement}}) {
            unless (Lacuna->cache->get($movement->{ship_type}.'_arrive_'.$movement->{target_body_id}.$movement->{target_star_id}, $body->empire_id)) {
                my $ship =  $ships->new({type=>$movement->{ship_type}});
                my $target;
                if ($movement->{target_body_id}) {
                    $target = $bodies->find($movement->{target_body_id});
                }
                else {
                    $target = $stars->find($movement->{target_star_id});
                }
                confess [1013, 'Have not sent '.$ship->type_formatted.' to '.$target->name.' ('.$target->x.','.$target->y.').'];
            }
        }
    }

    # plans
    if (exists $objectives->{plans}) {
        my @ids;
        foreach my $plan (@{$objectives->{plans}}) {
            my $this = $body->plans->search({
                    class => $plan->{classname},
                    level => {'>=' => $plan->{level}},
                    extra_build_level => {'>=' => $plan->{extra_build_level}},
                    id  => { 'not in' => \@ids },
                },{
                    rows => 1, order_by => 'id'
                })->single;
            if (defined $this) {
                push @ids, $this->id;
            }
            else {
                confess [1013, 'You do not have the '.$plan->{classname}->name.' plan needed to complete this mission.'];
            }
        }
    }

    return 1;
}

sub format_objectives {
    my $self = shift;
    return $self->format_items($self->params->get('mission_objective'), 1);
}

sub format_rewards {
    my $self = shift;
    return $self->format_items($self->params->get('mission_reward'));
}

sub format_items {
    my ($self, $items, $is_objective) = @_;
    my @items;
    
    # essentia
    push @items, sprintf('%s essentia.', commify($items->{essentia})) if ($items->{essentia});
    
    # happiness
    push @items, sprintf('%s happiness.', commify($items->{happiness})) if ($items->{happiness});
    
    # resources
    foreach my $resource (keys %{ $items->{resources}}) {
        push @items, sprintf('%s %s', commify($items->{resources}{$resource}), $resource);
    }
    
    # glyphs
    foreach my $glyph (@{$items->{glyphs}}) {
        push @items, $glyph.' glyph';
    }
    
    # ships
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    foreach my $stats (@{ $items->{ships}}) {
        my $ship = $ships->new({type=>$stats->{type}});
        my $pattern = $is_objective ? '%s (speed >= %s, stealth >= %s, hold size >= %s, combat >= %s)' : '%s (speed: %s, stealth: %s, hold size: %s, combat: %s)' ;
        push @items, sprintf($pattern, $ship->type_formatted, commify($stats->{speed}), commify($stats->{stealth}), commify($stats->{hold_size}), commify($stats->{combat}));
    }

    # fleet movement
    if ($is_objective && exists $items->{fleet_movement}) {
        my $bodies = Lacuna->db->resultset("Lacuna::DB::Result::Map::Body");
        my $stars = Lacuna->db->resultset("Lacuna::DB::Result::Map::Star");
        foreach my $movement (@{$self->scratch->{fleet_movement}}) {
            my $ship =  $ships->new({type=>$movement->{ship_type}});
            my $target;
            if ($movement->{target_body_id}) {
                $target = $bodies->find($movement->{target_body_id});
            }
            else {
                $target = $stars->find($movement->{target_star_id});
            }
            push @items, 'Send '.$ship->type_formatted.' to '.$target->name.' ('.$target->x.','.$target->y.').';
        }
    }

    # plans
    foreach my $stats (@{ $items->{plans}}) {
        my $level = $stats->{level};
        if ($stats->{extra_build_level}) {
            $level = '+'.$stats->{extra_build_level};
        }
        my $pattern = $is_objective ? '%s (>= %s) plan' : '%s (%s) plan'; 
        push @items, sprintf($pattern, $stats->{classname}->name, $level);
    }
    
    return \@items;
}

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_zone_date_posted', fields => ['zone','date_posted']);
}

sub date_posted_formatted {
    my $self = shift;
    return format_date($self->date_posted);
}

sub feed_url {
    my ($class, $zone) = @_;
    my $config = Lacuna->config;
    Lacuna->config->get('feeds/url').$class->feed_filename($zone);
}

sub feed_filename {
    my ($class, $zone) = @_;
    return 'missioncommand/'.create_uuid_as_string(UUID_MD5, $zone.Lacuna->config->get('feeds/bucket')).'.rss';
}

sub initialize {
    my ($class, $zone, $filename) = @_;
    return undef unless (-f '/data/Lacuna-Mission/missions/'.$filename);
    my $mission = Lacuna->db->resultset('Lacuna::DB::Result::Mission')->new({
        zone                => $zone,
        mission_file_name   => $filename,
    });
    $mission->max_university_level($mission->params->get('max_university_level'));
    my $objectives = $mission->params->get('mission_objective');
    if (exists $objectives->{fleet_movement}) {
        my $scratch;
        foreach my $movement (@{$objectives->{fleet_movement}}) {
            if ($movement->{target}{type} eq 'star') {
                push @{$scratch->{fleet_movement}}, {
                    ship_type       => $movement->{ship_type},
                    target_star_id  => $class->find_star_target($movement, $zone),
                }
            }
            else {
                push @{$scratch->{fleet_movement}}, {
                    ship_type       => $movement->{ship_type},
                    target_body_id  => $class->find_body_target($movement, $zone),
                }
            }
        }
        $mission->scratch($scratch);
    }
    $mission->insert;
    my $log = $mission->log;
    $log->update({ offers => $log->offers + 1});
    Lacuna->db->resultset('Lacuna::DB::Result::News')->new({
        zone                => $mission->zone,
        headline            => $mission->params->get('network_19_headline'),
    })->insert;
    return $mission;
}

sub find_body_target {
    my ($class, $movement, $zone) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({size => { between => $movement->{target}{size}}});
    
    # body type
    given ($movement->{target}{type}) {
        when ('asteroid') { $body = $body->search({ class => { like => 'Lacuna::DB::Result::Map::Body::Asteroid%'} }) };
        when ('habitable') { $body = $body->search({ class => { like => 'Lacuna::DB::Result::Map::Body::Planet::P%'} }) };
        when ('gas_giant') { $body = $body->search({ class => { like => 'Lacuna::DB::Result::Map::Body::Planet::GasGiant%'} }) };
        when ('space_station') { $body = $body->search({ class => { like => 'Lacuna::DB::Result::Map::Body::Station%'} }) };
    }
    
    # zone
    if ($movement->{target}{in_zone}) {
        $body = $body->search({ zone => $zone});
    }
    else {
        $body = $body->search({ zone => { '!=' => $zone }});
    }

    # inhabited
    if ($movement->{target}{inhabited}) {
        $body = $body->search({ empire_id => { '>' => 1}});
        # isolationist
        if ($movement->{target}{isolationist}) {
            $body = $body->search({ is_isolationist => 1 }, { join => 'empire' });
        }
        else {
            $body = $body->search({ is_isolationist => 0 }, { join => 'empire' });
        }
    }
    else {
        $body = $body->search({ empire_id => undef });
    }
    
    return $body->search(undef,{rows => 1, order_by => 'rand()'})->get_column('id')->single;
}

sub find_star_target {
    my ($class, $movement, $zone) = @_;
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star');

    # zone
    if ($movement->{target}{in_zone}) {
        $star = $star->search({ zone => $zone});
    }
    else {
        $star = $star->search({ zone => { '!=' => $zone }});
    }

    # color
    if ($movement->{target}{color} ne 'any') {
        $star = $star->search({ color => $movement->{target}{color} });
    }

    return $star->search(undef,{rows => 1, order_by => 'rand()'})->get_column('id')->single;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
