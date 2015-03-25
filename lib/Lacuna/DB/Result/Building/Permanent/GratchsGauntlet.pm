package Lacuna::DB::Result::Building::Permanent::GratchsGauntlet;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(randint);

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::GratchsGauntlet';

use constant image => 'gratchsgauntlet';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, 'The agents on %s use techniques handed down for millenia, which they say makes them unbeatable.', $self->body->name);
};

before 'repair' => sub {
    my $self = shift;
    my $db = Lacuna->db;
    my $now = DateTime->now;
    my $dtf = $db->storage->datetime_parser;
    my $i_spies = $db->resultset('Spies')
                    ->search( { on_body_id => $self->body->id,
                                empire_id  => { '!=' => $self->body->empire_id },
                                available_on  => { '<' => $dtf->format_datetime($now) },
                                task => 'Travelling',
                              });
    while (my $spy = $i_spies->next) {
        my $starting_task = $spy->task;
        $spy->is_available;
        if ($spy->task eq 'Idle' && $starting_task ne 'Idle') {
            if (!$spy->empire->skip_spy_recovery) {
                $spy->empire->send_predefined_message(
                    tags        => ['Intelligence'],
                    filename    => 'ready_for_assignment.txt',
                    params      => [$spy->name, $spy->from_body->id, $spy->from_body->name],
                );
            }
        }
    }
};

use constant name => 'Gratch\'s Gauntlet';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
