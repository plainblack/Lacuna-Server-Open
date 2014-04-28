package Lacuna::DB::Result::Proposition::EvictMiningPlatform;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $platform = Lacuna->db->resultset('MiningPlatforms')->find($self->scratch->{platform_id});   
    my $station = $self->station;
    my $bodies = Lacuna->db->resultset('Map::Body');
    my $asteroid = $bodies->find($self->scratch->{asteroid_id});
    my $name = $self->scratch->{name};
    if (! defined $platform) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the platform had already been destroyed, effectively nullifying the vote.');
    }
    elsif ($self->station_id != $platform->asteroid->star->station_id) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the asteroid was no longer under the jurisdiction of this station, effectively nullifying the vote.');
    }
    else {
        $platform->planet->empire->send_predefined_message(
            filename    => 'parliament_evict_mining_platform.txt',
            params      => [$station->alliance->name, $platform->asteroid->x, $platform->asteroid->y, $platform->asteroid->name],
            from        => $station->alliance->leader,
            tags        => ['Parliament','Correspondence'],
        );
        $platform->planet->get_building_of_class('Lacuna::DB::Result::Building::Ore::Ministry')->remove_platform($platform);
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
