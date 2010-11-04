package Lacuna::DB::Result::Mission;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use UUID::Tiny ':std';
use Config::JSON;
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);

__PACKAGE__->table('mission');
__PACKAGE__->add_columns(
    mission_file_name       => { data_type => 'varchar', size => 100, is_nullable => 0 },
    zone                    => { data_type => 'varchar', size => 16, is_nullable => 0 },
    date_posted             => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
);

has params => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return Config::JSON->new('/data/Lacuna-Server/var/missions/'. $self->mission_file_name);
    },
);

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
        foreach my $glyph (@{$objectives->{glyphs}}) {
            unless ($body->glyphs->search({ type => $glyph })->count) {
                confess [1011, 'You do not have the '.$glyph.' glyph needed to complete this mission.'];
            }
        }
    }

    # ships
    if (exists $objectives->{ships}) {
        foreach my $ship (@{$objectives->{ships}}) {
            unless ($body->ships->search({ type => $ship->{type}, speed => {'>=' => $ship->{speed}}, stealth => {'>=' => $ship->{stealth}}, hold_size => {'>=' => $ship->{hold_size}} })->count) {
                my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({type=>$ship->{type}});
                confess [1011, 'You do not have the '.$ship->type_formatted.' needed to complete this mission.'];
            }
        }
    }

    # plans
    if (exists $objectives->{plans}) {
        foreach my $plan (@{$objectives->{plans}}) {
            unless ($body->plans->search({ class => $plan->{classname}, level => {'>=' => $plan->{level}}, extra_build_level => {'>=' => $plan->{extra_build_level}} })->count) {
                confess [1011, 'You do not have the '.$plan->{classname}->name.' plan needed to complete this mission.'];
            }
        }
    }

    return 1;
}

sub format_objectives {
    my $self = shift;
    return $self->format_items($self->params->get('mission_objective'));
}

sub format_rewards {
    my $self = shift;
    return $self->format_items($self->params->get('mission_reward'));
}

sub format_items {
    my ($self, $items) = @_;
    my @items;
    
    # essentia
    push @items, sprintf('Essentia: %d essentia.', $items->{essentia}) if ($items->{essentia});
    
    # resources
    my @resources;
    foreach my $resource (keys %{ $items->{resources}}) {
        push @resources, sprintf('%d %s', $items->{resources}{$resource});
    }
    push @items, $self->format_list('Resources',@resources);
    
    # glyphs
    push @items, $self->format_list('Glyphs',@{$items->{glyphs}});
    
    # ships
    my @ships;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    foreach my $stats (@{ $items->{ships}}) {
        my $ship = $ships->new({type=>$stats->{type}});
        push @ships, sprintf('%s (speed: %d, stealth: %d, hold size: %d)', $ship->name, $stats->{speed}, $stats->{stealth}, $stats->{hold_size});
    }
    push @items, $self->format_list('Ships',@ships);

    # plans
    my @plans;
    foreach my $stats (@{ $items->{plans}}) {
        my $level = $stats->{level};
        if ($stats->{extra_build_level}) {
            $level = '+'.$stats->{extra_build_level};
        }
        push @plans, sprintf('%s (%s)', $stats->{classname}->name, $level);
    }
    push @items, $self->format_list('Plans',@plans);

    return \@items;
}

sub format_list {
    my ($self, $label, @list) = @_;
    my @out;
    if (scalar(@list) == 1) {
        push @out, sprintf($label.': %s.', $list[0]);
    }
    elsif (scalar(@list) > 1) {
        my $last = pop @list;
        push @out, sprintf($label.': %s and %s', join(',', @list), $last);
    }
    return @out;
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

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
