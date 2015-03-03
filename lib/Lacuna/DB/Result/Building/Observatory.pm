package Lacuna::DB::Result::Building::Observatory;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

sub max_probes {
    my $self = shift;
    return $self->effective_level * 3;
}

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships Intelligence Colonization));
};

sub probes {
    my $self = shift;
    return Lacuna->db->resultset('Probes')->search_observatory( {
        body_id     => $self->body->id,
    } );
}

use constant controller_class => 'Lacuna::RPC::Building::Observatory';

use constant university_prereq => 3;

use constant max_instances_per_planet => 1;

use constant image => 'observatory';

use constant name => 'Observatory';

use constant food_to_build => 63;

use constant energy_to_build => 63;

use constant ore_to_build => 63;

use constant water_to_build => 63;

use constant waste_to_build => 100;

use constant time_to_build => 150;

use constant food_consumption => 1;

use constant energy_consumption => 45;

use constant ore_consumption => 1;

use constant water_consumption => 1;

use constant waste_production => 1;

before 'can_downgrade' => sub {
    my $self = shift;
    if ($self->probes->count > ($self->level - 1) * 3) {
        confess [1013, 'You must abandon some probes to downgrade the Observatory.'];
    }
};

before delete => sub {
    my ($self) = @_;
    $self->probes->delete_all;
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
