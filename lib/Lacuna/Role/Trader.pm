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
    my $captcha = Lacuna->db->resultset('Lacuna::DB::Result::Captcha')->find(randint(1,65664));
    Lacuna->cache->set('trade_captcha', $empire->id, { guid => $captcha->guid, solution => $captcha->solution }, 60 * 30 );
    return {
        guid    => $captcha->guid,
        url     => $captcha->uri,
    };
}

sub validate_captcha {
    my ($self, $empire, $guid, $solution, $trade_id) = @_;
    if (defined $guid && defined $solution) {                                               # offered a solution
        my $captcha = Lacuna->cache->get_and_deserialize('trade_captcha', $empire->id);
        if (ref $captcha eq 'HASH') {                                                       # a captcha has been set
            if ($captcha->{guid} eq $guid) {                                                # the guid is the one set
                if ($captcha->{solution} eq $solution) {                                    # the solution is correct
                    return 1;
                }
            }
        }
    }
    Lacuna->cache->delete('trade_lock',$trade_id);
    confess [1014, 'Captcha not valid.', $self->assign_captcha($empire)];
}

sub market {
    return Lacuna->db->resultset('Lacuna::DB::Result::Market');
}

sub my_market { 
    my $self = shift;
    return $self->market->search({body_id => $self->body_id, transfer_type => $self->transfer_type});
}

sub available_market {
    my $self = shift;
    return $self->market->search(
        {
            body_id         => {'!=' => $self->body_id},
            transfer_type   => $self->transfer_type,
        },
    )
}

sub check_payload {
    my ($self, $items, $available_cargo_space, $space_exception, $transfer_ship) = @_;
    my $body = $self->body;
    $space_exception ||= $cargo_exception;
    
    # validate
    unless (ref $items eq 'ARRAY') {
        confess 'The list of items you want to trade needs to be formatted as an array of hashes.';
    }
    
    my $space_used;
    foreach my $item (@{$items}) {
        given($item->{type}) {
            when ([qw(water energy waste), ORE_TYPES, FOOD_TYPES]) {
                 confess $offer_nothing_exception unless ($item->{quantity} > 0);
                 confess $have_exception unless ($body->type_stored($item->{type}) >= $item->{quantity});
                 $space_used += $item->{quantity};
             }
            when ('glyph') {
                confess [1002, 'You must specify a glyph_id if you are pushing a glyph.'] unless $item->{glyph_id};
                my $glyph = Lacuna->db->resultset('Lacuna::DB::Result::Glyphs')->find($item->{glyph_id});
                confess $have_exception unless (defined $glyph && $self->body_id eq $glyph->body_id);
                $space_used += 100;
            }
            when ('plan') {
                confess [1002, 'You must specify a plan_id if you are pushing a plan.'] unless $item->{plan_id};
                my $plan = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->find($item->{plan_id});
                confess $have_exception unless (defined $plan && $self->body_id eq $plan->body_id);
                $space_used += 10000;
            }
            when ('prisoner') {
                confess [1002, 'You must specify a prisoner_id if you are pushing a prisoner.'] unless $item->{prisoner_id};
                my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($item->{prisoner_id});
                confess $have_exception unless (defined $prisoner && $self->body_id eq $prisoner->on_body_id && $prisoner->task eq 'Captured');
                $space_used += 350;
            }
            when ('ship') {
                confess [1002, 'You must specify a ship_id if you are pushing a ship.'] unless $item->{ship_id};
                if (defined $transfer_ship && $transfer_ship->id == $item->{ship_id}) {
                    confess [1010, 'You cannot push a ship with itself. Use the "stay" option instead.'];
                }
                my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($item->{ship_id});
                confess $have_exception unless (defined $ship && $self->body_id eq $ship->body_id && $ship->task eq 'Docked');
                $space_used += 50000;
            }
        }
    }
    confess $offer_nothing_exception unless $space_used;
    confess [1011, sprintf($space_exception,$space_used)] unless ($space_used <= $available_cargo_space);
    return $space_used;
}

sub structure_payload {
    my ($self, $items, $space_used) = @_;
    my $body = $self->body;
    my $payload;
    my %meta = ( offer_cargo_space_needed => $space_used );
    foreach my $item (@{$items}) {
        given($item->{type}) {
            when ([qw(water energy waste)]) {
                $body->spend_type($item->{type}, $item->{quantity});
                $body->update;
                $payload->{resources}{$item->{type}} += $item->{quantity};
                $meta{'has_'.$item->{type}} = 1;
             }
            when ([ORE_TYPES]) {
                $body->spend_type($item->{type}, $item->{quantity});
                $body->update;
                $payload->{resources}{$item->{type}} += $item->{quantity};
                $meta{has_ore} = 1;
             }
            when ([FOOD_TYPES]) {
                $body->spend_type($item->{type}, $item->{quantity});
                $body->update;
                $payload->{resources}{$item->{type}} += $item->{quantity};
                $meta{has_food} = 1;
             }
            when ('glyph') {
                my $glyph = Lacuna->db->resultset('Lacuna::DB::Result::Glyphs')->find($item->{glyph_id});
                $glyph->delete;
                push @{$payload->{glyphs}}, $glyph->type;
                $meta{has_glyph} = 1;
            }
            when ('plan') {
                my $plan = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->find($item->{plan_id});
                $plan->delete;
                push @{$payload->{plans}}, { class => $plan->class, level => $plan->level, extra_build_level => $plan->extra_build_level };
                $meta{has_plan} = 1;
            }
            when ('prisoner') {
                my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($item->{prisoner_id});
                $prisoner->task('Prisoner Transport');
                $prisoner->update;
                push @{$payload->{prisoners}}, $prisoner->id;
                $meta{has_prisoner} = 1;
            }
            when ('ship') {
                my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($item->{ship_id});
                $ship->task('Waiting On Trade');
                $ship->update;
                push @{$payload->{ships}}, $ship->id;
                $meta{has_ship} = 1;
            }
        }
    }
    return ($payload, \%meta);
}


1;
