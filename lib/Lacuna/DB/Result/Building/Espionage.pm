package Lacuna::DB::Result::Building::Espionage;

use Moose;
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence Ships));
};

use constant controller_class => 'Lacuna::RPC::Building::Espionage';

use constant max_instances_per_planet => 1;

use constant building_prereq => {'Lacuna::DB::Result::Building::Intelligence'=>1};

use constant image => 'espionage';

use constant name => 'Espionage Ministry';

use constant food_to_build => 78;

use constant energy_to_build => 77;

use constant ore_to_build => 77;

use constant water_to_build => 78;

use constant waste_to_build => 50;

use constant time_to_build => 150;

use constant food_consumption => 7;

use constant energy_consumption => 10;

use constant ore_consumption => 2;

use constant water_consumption => 7;

use constant waste_production => 1;

after finish_upgrade => sub {
    my $self = shift;
    Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({
        on_body_id      => $self->body_id,
        from_body_id    => $self->body_id,
    })->update({
        offense         => ($self->body->empire->species->deception_affinity * 50) + ($self->level + 75),
    });
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
