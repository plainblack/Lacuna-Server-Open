package Lacuna::DB::Result::Building::University;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Happiness Construction));
};

use constant controller_class => 'Lacuna::RPC::Building::University';

use constant max_instances_per_planet => 1;

use constant image => 'university';

use constant name => 'University';

use constant food_to_build => 190;

use constant energy_to_build => 190;

use constant ore_to_build => 190;

use constant water_to_build => 190;

use constant waste_to_build => 100;

use constant time_to_build => 300;

use constant food_consumption => 20;

use constant energy_consumption => 20;

use constant ore_consumption => 4;

use constant water_consumption => 22;

use constant waste_production => 26;

use constant happiness_production => 15;

after finish_upgrade => sub {
    my $self = shift;
    my $empire = $self->body->empire;
    my $tech_lvl = $empire->university_level;
    my $bld_lvl  = $self->level;
    if ($tech_lvl < $bld_lvl) {
        $empire->university_level(++$tech_lvl);
        $empire->update;
        if ($tech_lvl > 4) {
            my $invite = Lacuna->db->resultset('Lacuna::DB::Result::Invite')->search({invitee_id => $empire->id})->first;
            if (defined $invite) {
                my $inviter = $invite->inviter;
                if (defined $inviter) {
                    $inviter->add_essentia({
                        amount          => 5, 
                        type            => 'free',
                        reason          => 'invited friend university upgrade',
                        other_empire    => $empire,
                    });
                    $inviter->update;
                    $inviter->send_predefined_message(
                        filename    => 'friend_essentia.txt',
                        params      => [$empire->id, $empire->name],
                        tags        => ['Alert'], 
                    );
                }
            }
        }
    }
};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
