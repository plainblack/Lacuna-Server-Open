package Lacuna::DB::Result::Building::Security;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence));
};

use constant controller_class => 'Lacuna::RPC::Building::Security';

use constant max_instances_per_planet => 1;

use constant building_prereq => {'Lacuna::DB::Result::Building::Intelligence'=>1};

use constant image => 'security';

use constant name => 'Security Ministry';

use constant food_to_build => 90;

use constant energy_to_build => 100;

use constant ore_to_build => 120;

use constant water_to_build => 90;

use constant waste_to_build => 70;

use constant time_to_build => 150;

use constant food_consumption => 5;

use constant energy_consumption => 10;

use constant ore_consumption => 2;

use constant water_consumption => 7;

use constant waste_production => 5;

use constant happiness_consumption => 5;


sub foreign_spies {
    my $self = shift;
    return Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search({ level => { '<=' => $self->effective_level },
                   task => { 'not in' => [ 'Captured', 'Prisoner Transport'] },
                   on_body_id => $self->body_id, empire_id => { '!=' => $self->body->empire_id } });
}

sub prisoners {
    my $self = shift;

    my $dt_parser = Lacuna->db->storage->datetime_parser;
    my $now = $dt_parser->format_datetime( DateTime->now );

    return  Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search(
            {
                on_body_id  => $self->body_id,
                task        => { 'in' => [ 'Captured', 'Prisoner Transport' ] },
                available_on=> { '>' => $now },
            }
        );
}

after finish_upgrade => sub {
    my $self = shift;
    my $defense = ($self->body->empire->deception_affinity * 50) + ($self->effective_level * 75);
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({
        on_body_id      => $self->body_id,
        from_body_id    => $self->body_id,
        defense         => { '<' => $defense },
    });
    while (my $spy = $spies->next) {
        $spy->defense($defense);
        $spy->update_level;
        $spy->update;
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
