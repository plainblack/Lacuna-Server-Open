package Lacuna::DB::Result::Proposition::RenameStar;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Proposition';

before pass => sub {
    my ($self) = @_;
    my $alliance = $self->alliance;
    my $star = Lacuna->db->resultset('Map::Star')->find($self->scratch->{star_id});
    my $name = $self->scratch->{name};
    if (!defined($star) or $star->alliance_id != $alliance->id or $star->influence < 50) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the star was no longer under the jurisdiction of this alliance, effectively nullifying the vote.');
    }
    elsif (Lacuna->db->resultset('Map::Star')->search({name=>$name, 'id'=>{'!='=>$star->id}})->count) {
        $self->pass_extra_message('Unfortunately, by the time the proposition passed, the name *'.$name.'* had already been taken, effectively nullifying the vote.');
    }
    else {
        $star->name($name);
        $star->update;
        my $elaw = $alliance->laws->search({type => 'Jurisdiction', star_id => $star->id})->single;
        if ($elaw) {
            $elaw->name('Seize '.$name);
            $elaw->description('Seize control of {Starmap '.$star->x.' '.$star->y.' '.$name.'} by {Alliance '.$alliance->id.' '.
                              $alliance->name.'}, and apply all present laws to said star and its inhabitants.');
            $elaw->update;
        }
        else {
            my $law = Lacuna->db->resultset('Law')->new({
                name        => 'Seize '.$name,
                description => 'Seize control of {Starmap '.$star->x.' '.$star->y.' '.$name.'} by {Alliance '.$alliance->id.' '.
                              $alliance->name.'}, and apply all present laws to said star and its inhabitants.',
                type        => 'Jurisdiction',
                alliance_id => $alliance->id,
                star_id     => $star->id,
            });
            $law->star($star);
            $law->insert;
        }
    }
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
