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

sub check_payload {
  my ($self, $items, $available_cargo_space, $space_exception, $transfer_ship) = @_;
  my $body = $self->body;
  $space_exception ||= $cargo_exception;
    
  # validate
  unless (ref $items eq 'ARRAY') {
    confess [ 9999, 'The list of items you want to trade needs to be formatted as an array of hashes.'];
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
        confess $offer_nothing_exception unless ($item->{quantity} > 0);
        confess $fractional_offer_exception if ($item->{quantity} != int($item->{quantity}));
        confess [1002, 'you must specify a glyph name with a quantity.'] unless $item->{name};
        my $glyph = Lacuna->db->resultset('Lacuna::DB::Result::Glyph')->search({
            type    => $item->{name},
            body_id => $self->body_id,
            })->first;
        my $gquant = 0;
        if (defined $glyph) {
            $gquant = $glyph->quantity;
        }
        confess [1002, "You don't have ".$item->{quantity}." glyphs of type ".
                        $item->{name}." you only have ".$gquant]
                      unless $gquant >= $item->{quantity};
        push @expanded_items, $item;
        $space_used += 100 * $item->{quantity};
      }
            when ('plan') {
                if ($item->{plan_id}) {
                    confess [1002, 'Plan IDs are no longer supported'];
                }
                elsif ($item->{quantity}) {
                    confess $offer_nothing_exception unless ($item->{quantity} > 0);
                    confess $fractional_offer_exception if ($item->{quantity} != int($item->{quantity}));
                    confess [1002, 'you must specify a plan_type if you specify a quantity.'] unless $item->{plan_type};
                    confess [1002, 'you must specify a level if you specify a quantity.'] unless $item->{level};
                    confess [1002, 'you must specify an extra_build_level if you specify a quantity.'] unless defined $item->{extra_build_level};

                    my $plan_class = $item->{plan_type};
                    $plan_class =~ s/_/::/g;
                    $plan_class = "Lacuna::DB::Result::Building::$plan_class";
                    my ($plan) = grep {
                            $_->class eq $plan_class 
                        and $_->level == $item->{level} 
                        and $_->extra_build_level == $item->{extra_build_level}
                        } @{$body->plan_cache};
                    confess [1002, "You don't have ".$item->{quantity}." plans of type ".$item->{plan_type}] unless defined $plan and $plan->quantity >= $item->{quantity};
                    
                    push @expanded_items, {type => 'plan', plan_id => $plan->id, quantity => $item->{quantity} };
                    $space_used += 10000 * $item->{quantity};
                }
                else {
                    confess [1002, 'You must specify a quantity if you are pushing a plan.'];
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
          confess [1002, 'you must specify a hold_size if you specify a quantity.'] unless defined $item->{hold_size};
          confess [1002, 'you must specify a speed if you specify a quantity.'] unless defined $item->{speed};
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
            $transfer_ship->task('Holding Trade Goods');
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
  $items = \@expanded_items;
  confess $offer_nothing_exception unless $space_used;
  confess [1011, sprintf($space_exception,$space_used)] unless ($space_used <= $available_cargo_space);
  return $space_used, $items;
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
                if ($item->{name}) {
                    my $num_used = $body->use_glyph($item->{name}, $item->{quantity});
                    if ($num_used) {
                        push @{$payload->{glyphs}}, {
                            name     => $item->{name},
                            quantity => $num_used,
                        };
                        $meta{has_glyph} = 1;
                    }
                }
            }
            when ('plan') {
                if ($item->{plan_id}) {
                    my ($plan) = grep {$_->id == $item->{plan_id}} @{$body->plan_cache};

                    $body->delete_many_plans($plan, $item->{quantity});
                    push @{$payload->{plans}}, {
                        class               => $plan->class,
                        level               => $plan->level,
                        extra_build_level   => $plan->extra_build_level,
                        quantity            => $item->{quantity},
                        };
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
                    $ship->task('Offered For Trade');
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
