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

sub format_objectives {
    my $self = shift;
    my $objectives = $self->params->get('mission_objective');
    my @objectives;
    
    # essentia
    push @objectives, sprintf('Provide %d essentia.', $objectives->{essentia}) if ($objectives->{essentia});
    
    # resources
    my @resources;
    foreach my $resource (keys %{ $objectives->{resources}}) {
        push @resources, sprintf('%d %s', $objectives->{resources}{$resource});
    }
    push @objectives, $self->format_list(@resources);
    
    # ships
    my @ships;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    foreach my $stats (@{ $objectives->{ships}}) {
        my $ship = $ships->new({type=>$stats->{type}});
        push @ships, sprintf('%s (speed: %d, stealth: %d, hold size: %d)', $ship->name, $stats->{speed}, $stats->{stealth}, $stats->{hold_size});
    }
    push @objectives, $self->format_list(@ships);

    # plans
    my @plans;
    foreach my $stats (@{ $objectives->{plans}}) {
        push @plans, sprintf('%s (%s)', $stats);
    }
    push @objectives, $self->format_list(@plans);

    
    return \@objectives;
}

sub format_list {
    my ($self, @list) = @_;
    my @out;
    if (scalar(@list) == 1) {
        push @out, sprintf('Provide %s.', $list[0]);
    }
    elsif (scalar(@list) > 1) {
        my $last = pop @list;
        push @out, sprintf('Provide %s and %s', join(',', @list), $last);
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
