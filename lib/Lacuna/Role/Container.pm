package Lacuna::Role::Container;

use Moose::Role;

sub unload {
    my ($self, $payload, $body) = @_;
    if (exists $payload->{prisoners}) {
        foreach my $id (@{$payload->{prisoners}}) {
            my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($id);
            $prisoner->task('Captured');
            $prisoner->on_body_id($body->id);
            $prisoner->update;
        }
    }
    if (exists $payload->{ships}) {
        foreach my $id (@{$payload->{ships}}) {
            my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($id);
            $ship->task('Docked');
            $ship->body_id($body->id);
            $ship->update;
        }
    }
    if (exists $payload->{essentia}) {
        $body->empire->add_essentia($payload->{essentia});
        $body->empire->update;
    }
    if (exists $payload->{resources}) {
        my %resources = %{$payload->{resources}};
        foreach my $type (keys %resources) {
            my $add = 'add_'.$type;
            $body->$add($resources{$type});
        }
        $body->update;
    }
    if (exists $payload->{plans}) {
        foreach my $plan (@{$payload->{plans}}) {
            $body->add_plan($plan->{class}, $plan->{level}, $plan->{extra_build_level});
        }
    }
    if (exists $payload->{glyphs}) {
        foreach my $glyph (@{$payload->{glyphs}}) {
            $body->add_glyph($glyph);
        }
    }
}


1;
