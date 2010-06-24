package Lacuna::Role::Trader;

use Moose::Role;
use feature "switch";
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use Lacuna::Util qw(randint);

my $have_exception = [1011, 'You cannot offer to trade something you do not have.'];
my $cargo_exception = 'You need %s cargo space to trade that.';
my $offer_nothing_exception = [1013, 'It appears that you have offered nothing.'];
my $ask_nothing_exception = [1013, 'It appears that you have asked for nothing.'];

sub assign_captcha {
    my ($self, $empire) = @_;
    my $captcha = Lacuna->db->resultset('Lacuna::DB::Result::Captcha')->find(randint(1,72792));
    Lacuna->cache->set('trade_captcha', $empire->id, { guid => $captcha->guid, solution => $captcha->solution }, 60 * 30 );
    return {
        guid    => $captcha->guid,
        url     => 'https://extras.lacunaexpanse.com.s3.amazonaws.com/captcha/'.substr($captcha->guid,0,2).'/'.$captcha->guid.'.png',
    };
}

sub validate_captcha {
    my ($self, $empire, $guid, $solution) = @_;
    if ($guid && $solution) {                                                               # offered a solution
        my $captcha = Lacuna->cache->get_and_deserialize('trade_captcha', $empire->id);
        if (ref $captcha eq 'HASH') {                                                       # a captcha has been set
            if ($captcha->{guid} eq $guid) {                                                # the guid is the one set
                if ($captcha->{solution} eq $solution) {                                    # the solution is correct
                    return 1;
                }
            }
        }
    }
    confess [1014, 'Captcha not valid.', $self->assign_captcha($empire)];
}

sub trades {
    return Lacuna->db->resultset('Lacuna::DB::Result::Trades');
}

sub my_trades {
    my $self = shift;
    return $self->trades->search({body_id => $self->body_id, transfer_type => $self->transfer_type}, {order_by => ['date_offered']});
}

sub available_trades {
    my $self = shift;
    return $self->trades->search(
        {
            body_id         => {'!=' => $self->body_id},
            transfer_type   => $self->transfer_type,
        },
        {
            order_by        => {-desc => ['offer_sub_type','offer_quantity','offer_rank_1','offer_rank_2','offer_description'] }
        }
    )
}

sub structure_offer {
    my ($self, $offer) = @_;
    my $available_cargo_space = $self->determine_available_cargo_space;
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
                payload                     => {essentia => $offer->{quantity} },
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
            my $space = 10000;
            confess [1011, sprintf($cargo_exception,$space)] unless ($space <= $available_cargo_space);
            my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($offer->{ship_id});
            confess $have_exception unless (defined $ship && $self->body_id eq $ship->body_id && $ship->task eq 'Docked');
            $ship->task('Waiting On Trade');
            $ship->update;
            return {
                offer_type                  => $offer->{type},
                offer_sub_type              => $ship->type,
                offer_quantity              => 1,
                offer_description           => $ship->type_formatted.' (Cargo: '.$ship->hold_size.', Speed: '.$ship->speed.')',
                offer_cargo_space_needed    => $space,
                offer_rank_1                => $ship->hold_size,
                offer_rank_2                => $ship->speed,
                offer_object_id             => $ship->id,
                payload                     => {ships => [$ship->id] },
            };
        }
        #when ('glyph') {
        #    
        #}
        when ('prisoner') {
            confess $offer_nothing_exception if ($offer->{prisoner_id} eq '');
            my $space = 100;
            confess [1011, sprintf($cargo_exception,$space)] unless ($space <= $available_cargo_space);
            my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($offer->{prisoner_id});
            confess $have_exception unless (defined $prisoner && $self->body_id eq $prisoner->on_body_id && $prisoner->task eq 'Captured');
            $prisoner->task('Waiting On Trade');
            $prisoner->update;
            return {
                offer_type                  => $offer->{type},
                offer_sub_type              => $offer->{type},
                offer_quantity              => 1,
                offer_description           => 'Prisoner '.$prisoner->name.' (Level '.$prisoner->level.')',
                offer_cargo_space_needed    => $space,
                offer_rank_1                => $prisoner->level,
                offer_object_id             => $prisoner->id,
                payload                     => {prisoners => [$prisoner->id] },
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
                payload                     => {plans => [{class => $plan->class, level => $plan->level, extra_build_level => $plan->extra_build_level}]},
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
        payload                     => {resources => {$offer->{type} => $offer->{quantity}}},
    };
}

sub structure_ask {
    my ($self, $ask) = @_;
    confess $ask_nothing_exception unless ($ask->{quantity} > 0);
    given($ask->{type}) {
        when ([qw(water energy waste)]) {
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

1;
