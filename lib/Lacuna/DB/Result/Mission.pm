package Lacuna::DB::Result::Mission;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date commify);
use UUID::Tiny ':std';
use Config::JSON;
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);

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
    $self->delete;
}

sub skip {
    my ($self, $body) = @_;
    Lacuna->cache->set($self->mission_file_name, $body->empire_id, 1, 60 * 60 * 24 * 30);
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
    if (-f '/data/Lacuna-Mission/missions/'.$name) {
        $self->initialize($self->zone, $name);
    }
}

sub add_rewards {
    my ($self, $body) = @_;
    my $rewards = $self->params->get('mission_reward');
    # essentia
    if (exists $rewards->{essentia}) {
        $body->empire->add_essentia($rewards->{essentia}, 'mission reward')->update;
    }
    
    # resources
    if (exists $rewards->{resources}) {
        foreach my $resource (keys %{$rewards->{resources}}) {
            $body->add_type($resource, $rewards->{resources}{$resource});
        }
        $body->update;
    }

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
                speed       => $ship->{speed},
                stealth     => $ship->{stealth},
                hold_size   => $ship->{hold_size},
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
    
    # resources
    if (exists $objectives->{resources}) {
        foreach my $resource (keys %{$objectives->{resources}}) {
            $body->spend_type($resource, $objectives->{resources}{$resource});
        }
        $body->update;
    }

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
            confess [1011, 'You do not have the essentia needed to complete this mission.'];
        }
    }
    
    # resources
    if (exists $objectives->{resources}) {
        foreach my $resource (keys %{$objectives->{resources}}) {
            if ($body->type_stored($resource) < $objectives->{resources}{$resource}) {
                confess [1011, 'You do not have the '.$resource.' needed to complete this mission.'];
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
                confess [1011, 'You do not have the '.$glyph.' glyph needed to complete this mission.'];
            }
        }
    }

    # ships
    if (exists $objectives->{ships}) {
        my @ids;
        foreach my $ship (@{$objectives->{ships}}) {
            my $this = $body->ships->search({
                    type        => $ship->{type},
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
                my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>$ship->{type}});
                confess [1011, 'You do not have the '.$ship->type_formatted.' needed to complete this mission.'];
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
                confess [1011, 'You do not have the '.$plan->{classname}->name.' plan needed to complete this mission.'];
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
        my $pattern = $is_objective ? '%s (speed >= %s, stealth >= %s, hold size >= %s)' : '%s (speed: %s, stealth: %s, hold size: %s)' ;
        push @items, sprintf($pattern, $ship->type_formatted, commify($stats->{speed}), commify($stats->{stealth}), commify($stats->{hold_size}));
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
    my $mission = Lacuna->db->resultset('Lacuna::DB::Result::Mission')->new({
        zone                => $zone,
        mission_file_name   => $filename,
    });
    $mission->max_university_level($mission->params->get('max_university_level'));
    $mission->insert;
    Lacuna->db->resultset('Lacuna::DB::Result::News')->new({
        zone                => $mission->zone,
        headline            => $mission->params->get('network_19_headline'),
    })->insert;
    return $mission;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
