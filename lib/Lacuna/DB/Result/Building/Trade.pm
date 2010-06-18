package Lacuna::DB::Result::Building::Trade;

use Moose;
extends 'Lacuna::DB::Result::Building';
use feature "switch";
use Lacuna::Constants qw(ORE_TYPES);
use Lacuna::Constants qw(FOOD_TYPES);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Ships));
};

use constant controller_class => 'Lacuna::RPC::Building::Trade';

use constant max_instances_per_planet => 1;

use constant university_prereq => 5;

use constant image => 'trade';

use constant name => 'Trade Ministry';

use constant food_to_build => 75;

use constant energy_to_build => 75;

use constant ore_to_build => 75;

use constant water_to_build => 75;

use constant waste_to_build => 80;

use constant time_to_build => 300;

use constant food_consumption => 5;

use constant energy_consumption => 28;

use constant ore_consumption => 2;

use constant water_consumption => 5;

use constant waste_production => 1;

sub add_trade {
    my ($self, $offer, $ask) = @_;
    my $available_cargo_space = $self->determine_available_cargo_space;
    $ask = $self->structure_ask($ask);
    $offer = $self->structure_offer($offer, $available_cargo_space);
    my %trade = (
        %{$ask},
        %{$offer},
        body_id         => $self->body_id,
        transfer_type   => $self->body->zone,
    );
    return Lacuna->db->resultset('Lacuna::DB::Result::Trades')->new(\%trade)->insert;
}

sub load_offer_on_ships {
    my ($self, $cargo_space_used, $cargo) = @_;
    my $ships = $self->available_trade_ships;
    my $first = 1;
    my @used;
    while (my $ship = $ships->next) {
        push @used, $ship->id;
        $ship->task('Waiting On Trade');
        if ($first) {
            $first = 0;
            $ship->payload($cargo);
        }
        $ship->update;
    }
    return \@used;
}

sub available_trade_ships {
    my $self = shift;
    return Lacuna->db
        ->resultset('Lacuna::DB::Result::Ships')
        ->search({
            task    => 'Docked',
            type    => { in => ['cargo_ship','smuggler_ship'] },
            body_id => $self->body_id,
        }, {
            order_by=> ['type']
        });
}

sub determine_available_cargo_space {
    my ($self) = @_;
    return $self->available_trade_ships->get_column('hold_size')->sum;
}

my $have_exception = [1011, 'You cannot offer to trade something you do not have.'];
my $cargo_exception = 'You need %s cargo space to trade that.';
my $offer_nothing_exception = [1013, 'It appears that you have offered nothing.'];
my $ask_nothing_exception = [1013, 'It appears that you have asked for nothing.'];

sub structure_offer {
    my ($self, $offer, $available_cargo_space) = @_;

    given($offer->{type}) {
        when ([qw(water energy waste)]) {
            $self->offer_resources($offer->{type}, $offer, $available_cargo_space);
        }
        when ('essentia') {
            confess $offer_nothing_exception unless ($offer->{quantity} > 0);
            confess [1011, sprintf($cargo_exception,$offer->{quantity})] unless ($offer->{quantity} <= $available_cargo_space);
            confess $have_exception unless ($self->body->empire->essentia >= $offer->{quantity});
            $self->body->empire->spend_essentia($offer->{quantity},'trade');
            $self->body->empire->update;
            return {
                offer_type                  => $offer->{type},
                offer_sub_type              => $offer->{type},
                offer_quantity              => $offer->{quantity},
                offer_description           => $offer->{quantity}.' Essentia',
                offer_cargo_space_needed    => $offer->{quantity},
            };
        }
        when ([ORE_TYPES]) {
            $self->offer_resources('ore', $offer, $available_cargo_space);
        }
        when ([FOOD_TYPES]) {
            $self->offer_resources('food', $offer, $available_cargo_space);
        }
        when ('ship') {
            confess $offer_nothing_exception if ($offer->{ship_id} eq '');
            confess [1011, sprintf($cargo_exception,10000)] unless (10_000 <= $available_cargo_space);
            my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($offer->{ship_id});
            confess $have_exception unless (defined $ship && $self->body_id eq $ship->body_id && $ship->task eq 'Docked');
            $ship->task('Waiting On Trade');
            $ship->update;
            return {
                offer_type                  => $offer->{type},
                offer_sub_type              => $ship->type,
                offer_quantity              => 1,
                offer_description           => $ship->type_formatted.' (Cargo: '.$ship->hold_size.', Speed: '.$ship->speed.')',
                offer_cargo_space_needed    => 10_000,
                offer_rank_1                => $ship->hold_size,
                offer_rank_2                => $ship->speed,
                offer_object_id             => $ship->id,
            };
        }
        #when ('glyph') {
        #    
        #}
        when ('prisoner') {
            confess $offer_nothing_exception if ($offer->{prisoner_id} eq '');
            confess [1011, sprintf($cargo_exception,100)] unless (100 <= $available_cargo_space);
            my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($offer->{prisoner_id});
            confess $have_exception unless (defined $prisoner && $self->body_id eq $prisoner->on_body_id && $prisoner->task eq 'Captured');
            $prisoner->task('Waiting On Trade');
            $prisoner->update;
            return {
                offer_type                  => $offer->{type},
                offer_sub_type              => $offer->{type},
                offer_quantity              => 1,
                offer_description           => 'Prisoner '.$prisoner->name.' (Level '.$prisoner->level.')',
                offer_cargo_space_needed    => 100,
                offer_rank_1                => $prisoner->level,
                offer_object_id             => $prisoner->id,
            };
        }
        when ('plan') {
            confess $offer_nothing_exception if ($offer->{plan_id} eq '');
            my $space = 10000;
            confess [1011, sprintf($cargo_exception,$space)] unless ($space <= $available_cargo_space);
            my $plan = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->find($offer->{plan_id});
            confess $have_exception unless (defined $plan && $self->body_id eq $plan->body_id);
            $plan->delete;
            return {
                offer_type                  => $offer->{type},
                offer_sub_type              => $plan->class->name,
                offer_quantity              => 1,
                offer_description           => $plan->class->name.' (Level '.$plan->level.')',
                offer_cargo_space_needed    => $space,
                ships_holding_goods         => $self->load_offer_on_ships($space, {plan => {$plan->class => {level => $plan->level, extra_build_level => $plan->extra_build_level}}}),
            };
        }
    }
    confess $offer_nothing_exception;
}

sub offer_resources {
    my ($self, $type, $offer, $available_cargo_space) = @_;
    confess $offer_nothing_exception unless ($offer->{quantity} > 0);
    my $stored = $offer->{type}.'_stored';
    confess [1011, sprintf($cargo_exception,$offer->{quantity})] unless ($offer->{quantity} <= $available_cargo_space);
    confess $have_exception unless ($self->body->$stored >= $offer->{quantity});
    my $spend = 'spend_'.$offer->{type};
    $self->body->$spend($offer->{quantity});
    $self->body->update;
    return {
        offer_type                  => $type,
        offer_sub_type              => $offer->{type},
        offer_quantity              => $offer->{quantity},
        offer_description           => $offer->{quantity}.' '.ucfirst($offer->{type}),
        offer_cargo_space_needed    => $offer->{quantity},
        ships_holding_goods         => $self->load_offer_on_ships($offer->{quantity}, {resources => {$offer->{type} => $offer->{quantity}}}),
    };
}

sub structure_ask {
    my ($self, $ask) = @_;
    confess $ask_nothing_exception unless ($ask->{quantity} > 0);
    given($ask->{type}) {
        when ([qw(water energy waste ore food)]) {
            $self->ask_resources($ask);
        }
        when ('essentia') {
            return {
                ask_type                  => $ask->{type},
                ask_quantity              => $ask->{quantity},
                ask_description           => $ask->{quantity}.' Essentia',
            };
        }
        when ([ORE_TYPES]) {
            $self->ask_resources($ask);
        }
        when ([FOOD_TYPES]) {
            $self->ask_resources($ask);
        }
    }
    confess $ask_nothing_exception;
}

sub ask_resources {
    my ($self, $ask) = @_;
    return {
        ask_type                  => $ask->{type},
        ask_quantity              => $ask->{quantity},
        ask_description           => $ask->{quantity}.' '.ucfirst($ask->{type}),
    };
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
