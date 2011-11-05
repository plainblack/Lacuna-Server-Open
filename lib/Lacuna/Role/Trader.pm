package Lacuna::Role::Trader;

use Moose::Role;
use feature "switch";
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES);
use Lacuna::Util qw(randint);
use Data::Dumper;

my $have_exception = [1011, 'You cannot offer to trade something you do not have.'];
my $cargo_exception = 'You need %s cargo space to trade that.';
my $offer_nothing_exception = [1013, 'It appears that you have offered nothing.'];
my $ask_nothing_exception = [1013, 'It appears that you have asked for nothing.'];
my $fractional_offer_exception = [1013, 'You cannot offer a fraction of something.'];

sub market {
    return Lacuna->db->resultset('Lacuna::DB::Result::Market');
}

sub my_market { 
    my $self = shift;
    return $self->market->search({body_id => $self->body_id, transfer_type => $self->transfer_type });
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
    my @expanded_items;

    foreach my $item (@{$items}) {
        given($item->{type}) {
            when ([qw(water energy waste), ORE_TYPES, FOOD_TYPES]) {
                 confess $offer_nothing_exception unless ($item->{quantity} > 0);
                 confess $fractional_offer_exception if ($item->{quantity} != int($item->{quantity}));
                 confess $have_exception unless ($body->type_stored($item->{type}) >= $item->{quantity});
                 push @expanded_items, $item;
                 $space_used += $item->{quantity};
            }
            when ('glyph') {
                if ($item->{glyph_id}) {
                    my $glyph = Lacuna->db->resultset('Lacuna::DB::Result::Glyphs')->find($item->{glyph_id});
                    confess $have_exception unless (defined $glyph && $self->body_id eq $glyph->body_id);
                    push @expanded_items, $item;
                    $space_used += 100;
                }
                elsif ($item->{quantity}) {
                    confess $offer_nothing_exception unless ($item->{quantity} > 0);
                    confess $fractional_offer_exception if ($item->{quantity} != int($item->{quantity}));

                    confess [1002, 'you must specify a glyph name if you specify a quantity.'] unless $item->{name};
                    my @glyphs = Lacuna->db->resultset('Lacuna::DB::Result::Glyphs')->search({
                        type    => $item->{name},
                        body_id => $self->body_id,
                    });
                    confess [1002, "You don't have ".$item->{quantity}." glyphs of type ".$item->{name}." you only have ".scalar(@glyphs)] unless scalar(@glyphs) >= $item->{quantity};
                    push @expanded_items, map { {type => 'glyph', glyph_id => $_->id} } splice @glyphs, 0, $item->{quantity};
                    $space_used += 100 * $item->{quantity};
                }
                else {
                    confess [1002, 'You must specify either a glyph_id, or a quantity if you are pushing a glyph.'];
                }
            }
            when ('plan') {
                if ($item->{plan_id}) {
                    my $plan = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->find($item->{plan_id});
                    confess $have_exception unless (defined $plan && $self->body_id eq $plan->body_id);
                    push @expanded_items, $item;
                    $space_used += 10000;
                }
                elsif ($item->{quantity}) {
                    confess $offer_nothing_exception unless ($item->{quantity} > 0);
                    confess $fractional_offer_exception if ($item->{quantity} != int($item->{quantity}));
                    confess [1002, 'you must specify a class if you specify a quantity.'] unless $item->{class};
                    confess [1002, 'you must specify a level if you specify a quantity.'] unless $item->{level};
                    confess [1002, 'you must specify an extra_build_level if you specify a quantity.'] unless defined $item->{extra_build_level};

                    my @plans = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->search({
                        class   => $item->{class},
                        body_id => $self->body_id,
                        level   => $item->{level},
                        extra_build_level   => $item->{extra_build_level},
                    });
                    confess [1002, "You don't have ".$item->{quantity}." plans of type ".$item->{name}." you only have ".scalar(@plans)] unless scalar(@plans) >= $item->{quantity};
                    push @expanded_items, map { {type => 'plan',plan_id => $_->id} } splice @plans, 0, $item->{quantity};
                    $space_used += 10000 * $item->{quantity};

                }
                else {
                    confess [1002, 'You must specify either a plan_id, or a quantity if you are pushing a plan.'];
                }
            }
            when ('prisoner') {
                confess [1002, 'You must specify a prisoner_id if you are pushing a prisoner.'] unless $item->{prisoner_id};
                my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($item->{prisoner_id});
                confess $have_exception unless (defined $prisoner && $self->body_id eq $prisoner->on_body_id && $prisoner->task eq 'Captured');
                push @expanded_items, $item;
                $space_used += 350;
            }
            when ('ship') {
                if ($item->{ship_id}) {
                    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($item->{ship_id});
                    confess $have_exception unless (defined $ship && $self->body_id eq $ship->body_id && $ship->task eq 'Docked');
                    push @expanded_items, $item;
                    $space_used += 50000;
                }
                elsif ($item->{quantity}) {
                    confess $offer_nothing_exception unless ($item->{quantity} > 0);
                    confess $fractional_offer_exception if ($item->{quantity} != int($item->{quantity}));
                    confess [1002, 'you must specify a name if you specify a quantity.'] unless $item->{name};
                    confess [1002, 'you must specify a ship_type if you specify a quantity.'] unless $item->{ship_type};
                    confess [1002, 'you must specify a hold_size if you specify a quantity.'] unless $item->{hold_size};
                    confess [1002, 'you must specify a speed if you specify a quantity.'] unless $item->{speed};
                    my $ships_rs = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
                        name        => $item->{name},
                        body_id     => $self->body_id,
                        type        => $item->{ship_type},
                        hold_size   => $item->{hold_size},
                        speed       => $item->{speed},
                        task        => 'Docked',
                    });

                    if (defined $transfer_ship) {
                        $ships_rs = $ships_rs->search({
                            id      => {'!=' => $transfer_ship->id},
                        });
                    }
                    my @ships = $ships_rs->search->all;
                    confess [1002, "You don't have ".$item->{quantity}." ships of type ".$item->{ship_type}." you only have ".scalar(@ships)] unless @ships && scalar(@ships) >= $item->{quantity};
                    push @expanded_items, map { {type => "ship", ship_id => $_->id} } splice @ships, 0, $item->{quantity};
                    $space_used += 50000 * $item->{quantity};
                }
                else {
                    confess [1002, 'You must specify a ship_id or a quantity if you are pushing a ship.'];
                }
            }
        }
    }
    push @$items, @expanded_items;
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
                if ($item->{glyph_id}) {
                    my $glyph = Lacuna->db->resultset('Lacuna::DB::Result::Glyphs')->find($item->{glyph_id});
                    $glyph->delete;
                    push @{$payload->{glyphs}}, $glyph->type;
                    $meta{has_glyph} = 1;
                }
            }
            when ('plan') {
                if ($item->{plan_id}) {
                    my $plan = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->find($item->{plan_id});
                    $plan->delete;
                    push @{$payload->{plans}}, { class => $plan->class, level => $plan->level, extra_build_level => $plan->extra_build_level };
                    $meta{has_plan} = 1;
                }
            }
            when ('prisoner') {
                my $prisoner = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($item->{prisoner_id});
                $prisoner->task('Prisoner Transport');
                $prisoner->update;
                push @{$payload->{prisoners}}, $prisoner->id;
                $meta{has_prisoner} = 1;
            }
            when ('ship') {
                if ($item->{ship_id}) {
                    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($item->{ship_id});
                    $ship->task('Waiting On Trade');
                    $ship->update;
                    push @{$payload->{ships}}, $ship->id;
                    $meta{has_ship} = 1;
                }
            }
        }
    }
    return ($payload, \%meta);
}


1;
