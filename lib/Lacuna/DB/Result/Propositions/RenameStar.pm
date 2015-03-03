package Lacuna::DB::Result::Propositions::RenameStar;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $station = $self->station;
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($self->scratch->{star_id});
    my $name = $self->scratch->{name};
    if (!defined($star) or $star->station_id != $station->id) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the star was no longer under the jurisdiction of this station, effectively nullifying the vote.');
    }
    elsif (Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({name=>$name, 'id'=>{'!='=>$star->id}})->count) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the name *'.$name.'* had already been taken, effectively nullifying the vote.');
    }
    else {
        $star->name($name);
        $star->update;
        my $elaw = $station->laws->search({type => 'Jurisdiction', star_id => $star->id})->first;
        if ($elaw) {
            $elaw->name('Seize '.$name);
            $elaw->description('Seize control of {Starmap '.$star->x.' '.$star->y.' '.$name.'} by {Planet '.$station->id.' '.
                              $station->name.'}, and apply all present laws to said star and its inhabitants.');
            $elaw->update;
        }
        else {
            my $law = Lacuna->db->resultset('Lacuna::DB::Result::Laws')->new({
                name        => 'Seize '.$name,
                description => 'Seize control of {Starmap '.$star->x.' '.$star->y.' '.$name.'} by {Planet '.$station->id.' '.
                              $station->name.'}, and apply all present laws to said star and its inhabitants.',
                type        => 'Jurisdiction',
                station_id  => $station->id,
                star_id     => $star->id,
            });
            $law->star($star);
            $law->insert;
        }
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
