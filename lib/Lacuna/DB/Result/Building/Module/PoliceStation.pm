package Lacuna::DB::Result::Building::Module::PoliceStation;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Module';

use constant controller_class => 'Lacuna::RPC::Building::PoliceStation';
use constant image => 'policestation';
use constant name => 'Police Station';
use constant max_instances_per_planet => 1;

sub foreign_spies {
    my $self = shift;
    return Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search({ level => { '<=' => $self->level}, task => { '!=' => 'Captured'}, on_body_id => $self->body_id, empire_id => { '!=' => $self->body->empire_id } });
}

sub prisoners {
    my $self = shift;
    return  Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search(
            {
                on_body_id  => $self->body_id,
                task        => 'Captured',
                available_on=> { '>' => DateTime->now },
            }
        );
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
