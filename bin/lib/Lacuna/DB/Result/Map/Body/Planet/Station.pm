package Lacuna::DB::Result::Map::Body::Planet::Station;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map::Body::Planet';

use Data::Dumper;
use List::Util qw(sum);

__PACKAGE__->has_many('stars','Lacuna::DB::Result::Map::Star','station_id');

has total_influence => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_total_influence',
);

sub _build_total_influence {
    my ($self) = @_;

    my @buildings = $self->_buildings->search({
        class => [
            'Lacuna::DB::Result::Building::Module::IBS',
            'Lacuna::DB::Result::Building::Module::OperaHouse',
            'Lacuna::DB::Result::Building::Module::CulinaryInstitute',
            'Lacuna::DB::Result::Building::Module::ArtMuseum',
        ],
    });
    my $influence = sum 0, map {$_->level} @buildings;
    return $influence;
}
    
has range_of_influence => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_range_of_influence',
);

sub _build_range_of_influence {
    my ($self) = @_;

    my $range = 0;
    my ($ibs) = $self->_buildings->search({
        class => 'Lacuna::DB::Result::Building::Module::IBS'
    });
    if (defined $ibs) {
        $range = $ibs->level * 1000;
    }
    return $range;
}

#sub in_range_of_influence {
#    my ($self, $star) = @_;
#    if ($self->calculate_distance_to_target($star) > $self->range_of_influence) {
#        return;
#    }
#    return 1;
#}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

