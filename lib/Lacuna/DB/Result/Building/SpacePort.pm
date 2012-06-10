package Lacuna::DB::Result::Building::SpacePort;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(SHIP_TYPES);
use List::Util qw(shuffle);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

sub ships {
    my $self = shift;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
        body_id     => $self->body_id,  
    });
}

# show all ships incoming to this planet
sub incoming_fleets {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Fleet')->search(
        {
            foreign_body_id => $self->body_id,
            direction       => 'out',
            task            => 'Travelling',
        }
    );
}

sub orbiting_ships {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {
            foreign_body_id => $self->body_id,
            task            => { in => ['Defend','Orbiting'] },
        }
    );
}

sub battle_logs {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Log::Battles')->search(
        {
            -or => [
                { attacking_empire_id => $self->body->empire_id },
                { defending_empire_id => $self->body->empire_id },
            ],
        }
    );
}

sub send_ship {
    my ($self, $target, $type, $payload) = @_;
    my $ship = $self->find_ship($type);
    return $ship->send(
        target      => $target,
        payload     => $payload,   
    );
}

sub number_of_ships {
    my $self = shift;
    return $self->ships->get_column('number_of_docks')->sum;
}

has max_ships => (
    is  => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $levels = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search( { 
            class       => $self->class, 
            body_id     => $self->body_id,
            efficiency  => 100,
        } )->get_column('level')->sum;
        return $levels * 2;
    },
);

sub docks_available {
    my $self = shift;
    if ($self->max_ships > $self->number_of_ships) {
        return $self->max_ships - $self->number_of_ships;
    }
    return 0;
}

sub is_full {
    my ($self) = @_;
    return $self->docks_available ? 0 : 1;
}

sub find_ship {
    my ($self, $type) = @_;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $self->body_id, task => 'Docked', type => $type} )->first;
    unless (defined $ship ) {
        $type =~ s/_/ /g;
        confess [ 1002, 'You do not have enough '.$type.'s.'];
    }
    return $ship;
}

before delete => sub {
  my ($self) = @_;
  unless (Lacuna->db->resultset('Lacuna::DB::Result::Building')
                ->search( { class => $self->class,
                            body_id => $self->body_id,
                            id => {'!=', $self->id } } )->count) {
    my $markets = [
                    { market => 'Lacuna::DB::Result::Market',
                      search => { body_id => $self->body_id, transfer_type => 'trade' }
                    },
                    { market => 'Lacuna::DB::Result::MercenaryMarket',
                      search => { body_id => $self->body_id }
                    },
                  ];

    for my $market_hash ( @{$markets} ) {
      my $market = Lacuna->db->resultset($market_hash->{market});
      my @to_be_deleted = $market->search($market_hash->{search})->get_column('id')->all;
      foreach my $id (@to_be_deleted) {
        my $trade = $market->find($id);
        next unless defined $trade;
        $trade->body->empire->send_predefined_message(
                filename    => 'trade_withdrawn.txt',
                params      => [join("\n",@{$trade->format_description_of_payload}), $trade->ask.' essentia'],
                tags        => ['Trade','Alert'],
        );
        $trade->withdraw;
      }
    }
    $self->ships->delete_all;
  }
};

before 'can_downgrade' => sub {
    my $self = shift;
    if ( ($self->max_ships - $self->number_of_ships) <  2) {
        confess [1013, 'You must scuttle some ships to downgrade the Spaceport.'];
    }
};

use constant controller_class   => 'Lacuna::RPC::Building::SpacePort';
use constant university_prereq  => 3;
use constant image              => 'spaceport';
use constant name               => 'Space Port';
use constant food_to_build      => 160;
use constant energy_to_build    => 180;
use constant ore_to_build       => 220;
use constant water_to_build     => 160;
use constant waste_to_build     => 100;
use constant time_to_build      => 150;
use constant food_consumption   => 10;
use constant energy_consumption => 70;
use constant ore_consumption    => 20;
use constant water_consumption  => 12;
use constant waste_production   => 20;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
