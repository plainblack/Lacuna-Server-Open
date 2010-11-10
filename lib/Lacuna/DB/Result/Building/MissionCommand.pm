package Lacuna::DB::Result::Building::MissionCommand;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant controller_class => 'Lacuna::RPC::Building::MissionCommand';

use constant university_prereq => 7;

use constant max_instances_per_planet => 1;

use constant image => 'missioncommand';

use constant name => 'Mission Command';

use constant food_to_build => 85;

use constant energy_to_build => 90;

use constant ore_to_build => 110;

use constant water_to_build => 90;

use constant waste_to_build => 40;

use constant time_to_build => 120;

use constant food_consumption => 7;

use constant energy_consumption => 10;

use constant ore_consumption => 3;

use constant water_consumption => 10;

use constant waste_production => 2;


sub missions {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Mission')->search({
        zone                    => $self->body->zone,
    },{
        order_by   => ['max_university_level','date_posted'],
    });
}



no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
