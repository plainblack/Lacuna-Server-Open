package Lacuna::AI::DeLambert;

use Moose;
use 5.010;
use utf8;
no warnings qw(uninitialized);
use Data::Dumper;
use Lacuna::Util qw(randint random_element);
use Lacuna::Constants qw(ORE_TYPES);

extends 'Lacuna::AI';

use constant empire_id  => -9;

sub spy_missions {
    return (
        'Appropriate Resources',
    );
}

sub ship_building_priorities {
    my ($self, $colony) = @_;

    my $status = $self->scratch->pad->{status};
    print "    Status is [$status]\n";

    my $scratch = $self->get_colony_scratchpad($colony);
    my $level = $scratch->pad->{level};

    my $quota = {
        peace => {
            5 => [
                ['galleon',  50],
                ['sweeper', 300],
            ],
            10 => [
                ['galleon',  50],
                ['sweeper', 700],
            ],
            15 => [
                ['galleon',  50],
                ['sweeper',1000],
            ],
            20 => [
                ['galleon',  50],
                ['sweeper',1500],
            ],
            25 => [
                ['galleon',  50],
                ['sweeper',1900],
            ],
            30 => [
                ['galleon',  50],
                ['sweeper',2200],
            ],
        },
        war => {
            5 => [
                ['galleon',                   50],
                ['sweeper',                  300],
                ['scow',                      70],
                ['security_ministry_seeker',  10],
                ['snark2',                    20],
            ],
            10 => [
                ['galleon',                   50],
                ['sweeper',                  700],
                ['scow',                     190],
                ['security_ministry_seeker',  20],
                ['snark2',                    40],
            ],
            15 => [
                ['galleon',                   50],
                ['sweeper',                 1000],
                ['scow',                     680],
                ['security_ministry_seeker',  40],
                ['snark2',                    70],
            ],
            20 => [
                ['galleon',                   50],
                ['sweeper',                 1500],
                ['scow',                     800],
                ['security_ministry_seeker',  50],
                ['snark2',                   100],
            ],
            25 => [
                ['galleon',                   50],
                ['sweeper',                 1900],
                ['scow',                    1000],
                ['security_ministry_seeker',  50],
                ['snark2',                   120],
            ],
            30 => [
                ['galleon',                   50],
                ['sweeper',                 2200],
                ['scow',                    1000],
                ['security_ministry_seeker', 100],
                ['snark2',                   430],
            ],
        },
    };

    return ( @{$quota->{$status}{$level}} );
}

sub run_hourly_colony_updates {
    my ($self, $colony) = @_;
    $self->demolish_bleeders($colony);
    $self->set_defenders($colony);
    $self->pod_check($colony, 20);
    $self->repair_buildings($colony);
    $self->train_spies($colony, 100, 1);
    $self->build_ships_max($colony);
    $self->run_missions($colony);
    $self->buy_trade($colony);
    $self->sell_glyph_trade($colony);
    $self->sell_plan_trade($colony);
    $self->check_enemy_spy_action($colony);
}

sub run_hourly_empire_updates {
    my ($self, $empire) = @_;

    $self->process_email($empire);
    $self->retaliate($empire);
}

sub get_colony_scratchpad {
    my ($self, $colony) = @_;

    my ($scratch) = Lacuna::db->resultset('Lacuna::DB::Result::AIScratchPad')->search({
        ai_empire_id    => $self->empire_id,
        body_id         => $colony->id,
    });

    return $scratch;
}


sub check_enemy_spy_action {
    my ($self, $colony) = @_;

    say "#### CHECK ENEMY SPY ACTION ####";

    my $scratchpad = $self->scratch->pad;

    my $enemy_spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({
        task    => ['Incite Mutiny','Incite Rebellion','Appropriate Technology','Sabotage Resources','Infiltrating','Incite Insurrection','Appropriate Resources','Abduct Operatives','Gather Operative Intelligence','Sabotage Probes','Rescue Comrades','Assassinate Operatives','Debriefing','Sabotage Infrastructure',],
        on_body_id => $colony->id,
        empire_id  => {'!=' => -9},
    });

    my $spy_ref;
    while (my $spy = $enemy_spies->next) {
        if (defined $spy_ref->{$spy->empire_id}) {
            $spy_ref->{$spy->empire_id}++;
        }
        else {
            $spy_ref->{$spy->empire_id} = 1;
        }
    }

    for my $empire_id (keys %$spy_ref) {
        my ($ai_battle_summary) = Lacuna->db->resultset('Lacuna::DB::Result::AIBattleSummary')->search({
            attacking_empire_id => $empire_id,
            defending_empire_id => -9,
        });
        if (not $ai_battle_summary) {
            $ai_battle_summary = Lacuna->db->resultset('Lacuna::DB::Result::AIBattleSummary')->create({
                attacking_empire_id => $empire_id,
                defending_empire_id => -9,
                attack_victories    => 0,
                defense_victories   => 0,
                attack_spy_hours    => 0,
            });
        }
        my $add_hours = $spy_ref->{$empire_id};
        say "    adding $add_hours spy attack hours from empire $empire_id";
        $ai_battle_summary->attack_spy_hours($ai_battle_summary->attack_spy_hours + $add_hours);
        $ai_battle_summary->update;
    }
}

sub sell_glyph_trade {
    my ($self, $colony) = @_;

    say "#### SELL GLYPH TRADE ####";

    my $scratchpad = $self->scratch->pad;
    my $trade_min = $colony->get_building_of_class('Lacuna::DB::Result::Building::Trade');

    if (not $trade_min) {
        say "    ERROR: No trade ministry found on ".$colony->name;
        return;
    }

    if (not defined $scratchpad->{sell_glyph_probability}) {
        $scratchpad->{sell_glyph_probability} = 1;
        $scratchpad->{sell_glyph_min_e} = 2;
        $scratchpad->{sell_glyph_max_e} = 5;
        $scratchpad->{sell_glyph_max_batch} = 10;
        $scratchpad->{sell_plan_probability} = 1;
        $scratchpad->{sell_plan_min_level} = 6;
        $scratchpad->{sell_plan_max_level} = 7;
        $scratchpad->{sell_plan_max_batch} = 4;
        $scratchpad->{sell_plan_min_hall_factor} = 4;
        $scratchpad->{sell_plan_max_hall_factor} = 6;
        $scratchpad->{sell_max_glyph_trades_in_zone} = 25;
        $scratchpad->{sell_max_plan_trades_in_zone} = 25;

        $self->scratch->pad($scratchpad);
        $self->scratch->update;
    }
    if (randint(1,100) <= $scratchpad->{sell_glyph_probability}) {
        # sell some glyphs
        my $ship = $self->get_trade_ship($colony);
        return unless $ship;

        # check how many trades there are in range at the moment
        my $trades_in_zone = $trade_min->local_market({
            has_glyph => 1,
        })->count;
        if ($trades_in_zone >= $scratchpad->{sell_max_glyph_trades_in_zone}) {
            say "Already enough trades ($trades_in_zone) in zone!";
            return;
        }
        my $quantity = randint(1,$scratchpad->{sell_glyph_max_batch});
        my $cost_per = rand($scratchpad->{sell_glyph_max_e} - $scratchpad->{sell_glyph_min_e}) + $scratchpad->{sell_glyph_min_e};
        if ($quantity * $cost_per > 100) {
            $quantity = int(100 / $cost_per);
        }
# Instead of random assortment, quantity of one glyph
        my $ore = random_element([ORE_TYPES]);
        my $glyphs = [ {
          name => $ore,
          quantity => $quantity,
#          glyph_id => 0,
        } ];
        if ($quantity) {
            say "Creating a trade for $quantity glyphs";
            $ship->task('Waiting On Trade');
            $ship->update;
            my %trade = (
                offer_cargo_space_needed  => $quantity * 100,
                has_glyph       => 1,
                payload         => {glyphs => $glyphs},
                ask             => $cost_per * $quantity,
                ship_id         => $ship->id,
                body_id         => $colony->id,
                transfer_type   => 'trade',
                x               => $colony->x,
                y               => $colony->y,
                speed           => $ship->speed,
                trade_range     => 600,
            );
            Lacuna->db->resultset('Lacuna::DB::Result::Market')->create(\%trade);
        }
    }
}

sub sell_plan_trade {
    my ($self, $colony) = @_;

    say "#### SELL PLAN TRADE ####";

    my $trade_min = $colony->get_building_of_class('Lacuna::DB::Result::Building::Trade');

    if (not $trade_min) {
        say "    ERROR: No trade ministry found on ".$colony->name;
        return;
    }

    my $scratchpad = $self->scratch->pad;

    if (randint(1,100) <= $scratchpad->{sell_plan_probability}) {
        # sell some plans
        my $ship = $self->get_trade_ship($colony);
        if ( not $ship ) {
            say "No Ship to use for trade!";
            return;
        }

        # check how many trades there are in the zone at the moment (including our own)
        my $trades_in_zone = $trade_min->local_market({
            has_plan            => 1,
        })->count;

        if ($trades_in_zone >= $scratchpad->{sell_max_plan_trades_in_zone}) {
            say "Already enough trades ($trades_in_zone) in zone!";
            return;
        }
        my $level = randint($scratchpad->{sell_plan_min_level},$scratchpad->{sell_plan_max_level});
        say "Offering level ($level) plan";
        my $hall_factor = rand( $scratchpad->{sell_plan_max_hall_factor} - $scratchpad->{sell_plan_min_hall_factor} ) + $scratchpad->{sell_plan_min_hall_factor};
        my $cost_per = $hall_factor * $level;
        my $quantity = randint(1, $scratchpad->{sell_plan_max_batch});
        if ($quantity * $cost_per > 100) {
            $quantity = int(100 / $cost_per);
        }
        my @plans;
        for (1..$quantity) {
            # randomly select from the various plans we sell
            my @types = qw(AlgaePond AmalgusMeadow BeeldebanNest CrashedShipSite DentonBrambles GeoThermalVent GratchsGauntlet GreatBallOfJunk InterDimensionalRift JunkHengeSculpture KalavianRuins LapisForest MalcudField MetalJunkArches NaturalSpring PyramidJunkSculpture Ravine Volcano
);
            my $type = $types[randint(0,scalar(@types)-1)];
            push @plans, {
                class               => "Lacuna::DB::Result::Building::Permanent::$type",
                level               => $level,
                quantity            => 1,
                extra_build_level   => 0,
            };
        }
        if ($quantity) {
            say "Creating a trade for $quantity plans";
            $ship->task('Waiting On Trade');
            $ship->update;
            my %trade = (
                offer_cargo_space_needed    => $quantity * 10000,
                has_plan                    => 1,
                payload                     => {plans => \@plans},
                ask                         => $cost_per * $quantity,
                ship_id                     => $ship->id,
                body_id                     => $colony->id,
                transfer_type               => 'trade',
                x                           => $colony->x,
                y                           => $colony->y,
                speed                       => $ship->speed,
                trade_range                 => 600,
            );
            Lacuna->db->resultset('Lacuna::DB::Result::Market')->create(\%trade);
        }
    }
}

sub get_trade_ship {
    my ($self, $colony) = @_;

    my ($ship) = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
        task    => 'Docked',
        type    => 'galleon',
        body_id => $colony->id,
    });
    return $ship;
}

sub buy_trade {
    my ($self, $colony) = @_;

    say "#### BUY TRADE ####";

    my $scratchpad = $self->scratch->pad;

    # The probability of each colony doing a buy trade per hour
    # where 100 is 100%
    if (not defined $scratchpad->{buy_trades_probability}) {
        $scratchpad->{buy_trades_probability} = 1;    # percentage chance of buying per hour
        $scratchpad->{buy_max_price_per_plan} = 3;    # max price that the DeL pay per plan
        $self->scratch->pad($scratchpad);
        $self->scratch->update;
    }
    if (randint(1,100) > $scratchpad->{buy_trades_probability}) {
        return;
    }

    # get all trades with plans by other empires in this zone
    my $market = Lacuna->db->resultset('Lacuna::DB::Result::Market')->search({
        'body.empire_id'  => {'!=' => $self->empire_id},
        transfer_type   => $colony->zone,
        has_plan        => 1,
        has_water       => 0,
        has_energy      => 0,
        has_ore         => 0,
        has_waste       => 0,
        has_ship        => 0,
        has_prisoner    => 0,
        has_glyph       => 0,
        has_food        => 0,
    },
    {
        join => 'body',
    });
    # we are only interested in trades just for plans level 1+0
    my $best_trade_id;
    my $best_price_per_plan = 999999;

    TRADE:
    while (my $trade = $market->next) {
        my @plans = @{$trade->payload->{plans}};
        my $good_plans = 0;
        for my $plan (@plans) {
            if ($plan->{level} == 1 
                and $plan->{extra_build_level} == 0 
                and $plan->{class} =~ m/AlgaePond|AmalgusMeadow|BeeldebanNest|CrashedShipSite|DentonBrambles|GeoThermalVent|LapisForest|MalcudField|NaturalSpring|Ravine|Volcano/) {
                $good_plans++;
            }
        }
        next TRADE if $good_plans == 0;
        my $price_per_plan = $trade->ask / $good_plans;
        if ($price_per_plan < $best_price_per_plan) {
            $best_price_per_plan = $price_per_plan;
            $best_trade_id = $trade->id;
        }
    }
    return unless $best_trade_id;

    # purchase the best value trade
    if ($best_price_per_plan <= $scratchpad->{buy_max_price_per_plan}) {
        my $trade = Lacuna->db->resultset('Lacuna::DB::Result::Market')->find($best_trade_id);
        return if not defined $trade;

        my $offer_ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($trade->ship_id);
        return if not defined $offer_ship;

        $self->empire->transfer_essentia({
            amount      => $trade->ask,
            from_reason => 'Trade Price',
            to_empire   => $trade->body->empire,
            to_reason   => 'Trade Income',
        });
        $self->empire->update;
       
        $offer_ship->send(
            target  => $colony,
            payload => $trade->payload,
        );

        $trade->body->empire->send_predefined_message(
            tags        => ['Trade','Alert'],
            filename    => 'trade_accepted.txt',
            params      => [join("; ",@{$trade->format_description_of_payload}), $trade->ask.' essentia', $self->empire->id, $self->empire->name],
        );
        $trade->delete;
    }
}


sub retaliate {
    my ($self) = @_;

    say "#### Retaliate! ####";
    my $empire = $self->empire;
    $self->scratch->discard_changes;
    my $scratch_pad = $self->scratch->pad;
    my $attack = $scratch_pad->{attack};

    my @del_colonies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({
        empire_id   => -9,
    });

    say "    Checking daily attack time '".DateTime->now->hour."'";
    my $attack_daily = DateTime->now->hour eq 14;

TARGET:
    foreach my $target_id (keys %$attack) {
       my $target = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($target_id);
       if ($target) {
           my $freq = $attack->{$target_id}{frequency} || 'never';
           say "    Target empire '".$target->name."' frequency '$freq'";
           if ($freq eq 'hourly' or $freq eq 'once' or ($freq eq 'daily' and $attack_daily)) {
               my $target_colony_id    = $attack->{$target_id}{colony_id};
               my $num_sweepers        = $attack->{$target_id}{sweepers};
               my $num_scows           = $attack->{$target_id}{scows};
               my $num_snarks          = $attack->{$target_id}{snarks};
               my $target_colony       = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($target_colony_id);
               next TARGET unless $target_colony;
               next TARGET if $target_colony->empire_id != $target_id;
               say "    Attack '".$target_colony->name."' with $num_sweepers sweepers, $num_scows scows, $num_snarks snarks";

               # Sort the DeLamberti colonies, closest to the target first
               @del_colonies = sort {$self->distance_comp($a,$b,$target_colony)} @del_colonies;
               # Get a percentage of ships from the closest colonies.
               my @sweepers;
               my @scows;
               my @snarks;
DEL_COLONY:
               foreach my $del_colony (@del_colonies) {
                   # Don't attack from the Neutral Zone
                   next DEL_COLONY if $del_colony->x == -3 and $del_colony->y == 0;

                   # Send damaged sweepers by preference, leaving undamaged ones to defend!
                   if (@sweepers < $num_sweepers) {
                       my @ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
                           type     => 'sweeper',
                           task     => 'Docked',
                           body_id  => $del_colony->id,
                       },
                       {
                           order_by => 'combat',
                       });
                       # 20% of sweepers
                       my $quantity = int(@ships / 5);
                       say "    Colony has ".scalar(@ships)." sweepers";
                       if (@sweepers + $quantity > $num_sweepers) {
                           $quantity = $num_sweepers - @sweepers;
                       }
                       say "    taking $quantity sweepers from ".$del_colony->name;
                       @sweepers = (@sweepers,  splice(@ships, 0, $quantity));
                       say "    Now got ".scalar(@sweepers)." sweepers";
                   }
                   if (@scows < $num_scows) {
                       my @ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
                           type     => 'scow',
                           task     => 'Docked',
                           body_id  => $del_colony->id,
                       });
                       # 50% of scows
                       my $quantity = int(@ships / 2);
                       if (@scows + $quantity > $num_scows) {
                           $quantity = $num_scows - @scows;
                       }
                       say "    taking $quantity scows from ".$del_colony->name;
                       @scows = (@scows, splice(@ships, 0, $quantity));
                   }
                   if (@snarks < $num_snarks) {
                       my @ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({
                           type     => {like => "snark%"},
                           task     => 'Docked',
                           body_id  => $del_colony->id,
                       });
                       # 50% of snarks
                       my $quantity = int(@ships / 2);
                       if (@snarks + $quantity > $num_snarks) {
                           $quantity = $num_snarks - @snarks;
                       }
                       say "    taking $quantity snarks from ".$del_colony->name;
                       @snarks = (@snarks, splice(@ships, 0, $quantity));
                   }
               }
               # Send all the ships and adjust their travel time to the latest arrival
               my $arrival_time;
               for my $ship (@snarks,@sweepers,@scows) {
                   say "    sending ship ID".$ship->id;
                   $ship->send(target => $target_colony);
                   if (not defined $arrival_time or $ship->date_available > $arrival_time) {
                       $arrival_time = $ship->date_available;
                   }
               }
               say "    Latest arrival time is $arrival_time";
               for my $ship (@sweepers,@snarks,@scows) {
                   $ship->date_available($arrival_time);
                   $ship->update;
               }
               if ($freq eq 'once') {
                   $scratch_pad->{attack}{$target_id}{frequency} = 'never';
                   $self->scratch->pad($scratch_pad);
                   $self->scratch->update;
               }
           }
       }
    }
}

sub distance_comp {
    my ($self, $left, $right, $target) = @_;

    my $distance_left = ($left->x - $target->x) * ($left->x - $target->x) + ($left->y - $target->y) * ($left->y - $target->y);
    my $distance_right = ($right->x - $target->x) * ($right->x - $target->x) + ($right->y - $target->y) * ($right->y - $target->y);
    return $distance_left <=> $distance_right;
}

sub process_email {
    my ($self) = @_;

    my $empire = $self->empire;
    my $messages = $self->empire->received_messages->search({
        has_read    => 0,
#        tag         => 'Correspondence',
    });
    MESSAGE:
    while (my $message = $messages->next) {
        print("Received message [".$message->subject."]\n");
        if ($message->from_id == $self->empire->id) {
            if ($message->subject eq "Trade Withdrawn") {
                $message->has_read(1);
                $message->has_trashed(1);
                $message->update;
            }
            next MESSAGE;
        }
        my $request_empire = Lacuna::db->resultset('Lacuna::DB::Result::Empire')->find($message->from_id);
        if (not $request_empire) {
            # empire seems to have disapeared
            $message->has_read(1);
            $message->update;
            next MESSAGE;
        }

        # Check for special offer
        if ($message->subject eq "Re: Special Offer") {
            print("Special offer request from ".$message->from_name."\n");
            # Check if this user has received an offer previously

            $self->scratch->discard_changes;
            if ($self->scratch->pad->{offer_empire}{$message->from_id}) {
                $message->has_read(1);
                $message->update;
                $self->duplicate_order_email($request_empire);
                next MESSAGE;
            }
            my $total_glyphs = 0;
            my $asked_for_too_many = 0;
            my $payload;
            # If not, send the order
            my @lines = split(/\n/, $message->body);
            for my $line (@lines) {
                my ($quantity,$glyph) = $line =~ m/(\d+)\s*(anthracite|bauxite|beryl|chalcopyrite|chromite|fluorite|galena|goethite|gold|gypsum|halite|kerogen|magnetite|methane|monazite|rutile|sulfur|trona|uraninite|zircon)/i;
                print("    [$glyph][$quantity]\n") if $quantity;

                if ($total_glyphs + $quantity > 20) {
                    $quantity = 20 - $total_glyphs;
                    $asked_for_too_many = 1;
                }
                $quantity = 0 if $quantity < 0;
                push @{$payload->{glyphs}}, [{
                  name => lc $glyph,
                  quantity => $quantity,
                  glyph_id => 0,
                }];
                $total_glyphs += $quantity;
            }

            if ($total_glyphs < 20) {
                # asked for too few, possible problem with order
                print "### TOO FEW GLYPHS\n";
                $self->spoiled_order_email($request_empire,"100: Less than 20 glyphs on order form");
                $self->special_offer_email($request_empire);
                $message->has_read(1);
                $message->update;
            }
            elsif ($asked_for_too_many) {
                # asked for too many, possible problem with order
                print "### TOO MANY GLYPHS\n";
                $self->spoiled_order_email($request_empire,"101: More than 20 glyphs on order form");
                $self->special_offer_email($request_empire);
                $message->has_read(1);
                $message->update;
            }
            else {
                # asked for correct number, fulfill the order
                #
                # Send to the home-world of the person making the order
                #

                my $to_x = $request_empire->home_planet->x;
                my $to_y = $request_empire->home_planet->y;

                # find the closest ship that can fulfill the order
                my ($ship) = Lacuna::db->resultset('Lacuna::DB::Result::Ships')->search({
                    'body.empire_id'    => -9,
                    task                => 'Docked',
                    type                => 'galleon',
                },
                {
                    join        => 'body',
                    order_by    => \"(($to_x - body.x)*($to_x - body.x) + ($to_y - body.y)*($to_y - body.y))",
                });

                if ($ship) {
                    print "Sending ship from ".$ship->body->name."\n";
                    $ship->send(
                        target  => $request_empire->home_planet,
                        payload => $payload
                    );
                    $self->order_dispatched_email($request_empire);
                    my $scratchpad = $self->scratch->pad;
                    $scratchpad->{offer_empire}{$message->from_id} = 1;
                    $self->scratch->pad($scratchpad);
                    $self->scratch->update;
                    $message->has_read(1);
                    $message->update;
                }
                else {
                    print "Cannot find ship to send\n";
                }
                # Mark this user as having received their order
            }
        }
        else {
            $self->unsolicited_email($request_empire);
            $message->has_read(1);
            $message->update;
        }
    }
}

sub attack_email {
    my ($self, $empire, $attackers) = @_;

    my $message = qq{
We are the DeLamberti.

It is with great sadness and anger that we have to inform you that we have recently been attacked
by $attackers with great loss of life at one of our trading posts.

We believed that The Lacuna Expanse was a peaceful place where we could trade to mutual benefit
but this was not meant to be.

While we are by nature a peaceful species, we will not stand by and let this unprovoked attack go
without a response.

We proclaim that from this day the DeLamberti are at war with $attackers. We will need time to
decide on an appropriate level of response, but be warned, respond we will!

To all other peaceful empires, understand that we will continue to trade with you, but any attacks
against our trading posts will be met with appropriate force.

Guilliame de Lambert 9th
};
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Declaration of war',
        from        => $self->empire,
        body        => $message,
    );

}


sub unsolicited_email {
    my ($self, $empire) = @_;

    my $message = qq{
We the DeLamberti greet you.

We regret that due to the huge amount of email we have received after our special offer we are unable to engage in correspondence at this time.

Your email will remain on file until such time as we are able to clear the backlog and provide you with a personal response.

However if you are looking for a job in our call center and you meet the following qualifications then please present yourself to our nearest trading post for an initial interview.

Your species must breath a methane/chlorine mix atmosphere at 20 degrees absolute, you must have an Intelligence Quotient no higher than that of a Dilurian slime worm, you must be prepared to work for 90% of the day for a basic pay of 15 DeLamberti cents per day. 

small print
(note pay may go down as well as up, the DeLamberti are free to define the terms 'day' as they see fit, the DeLamberti cent is not fixed against the standard currency of Essentia and is likely to be revalued from time to time).

Guillaume de Lambert 9th
};
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Unsolicited email.',
        from        => $self->empire,
        body        => $message,
    );

}

sub duplicate_order_email {
    my ($self, $empire) = @_;

    my $message = qq{
We the DeLamberti greet you.

Our automated trading system has received your order but unfortunately we have had to decline it. Our records show that you have previously accepted our once in a lifetime offer of 20 brand new, mint condition glyphs.

Of course if you can offer proof that your species is able to regenerate after death, a notarized death certificate from your previous life and a similarly notarized birth certificate for your new life, we will be more than willing to repeat this once in a lifetime offer.

Guillaume de Lambert 9th
};
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Your Order has been declined.',
        from        => $self->empire,
        body        => $message,
    );

}


# Order dispatched email
sub order_dispatched_email {
    my ($self, $empire) = @_;

    my $message = qq{
We the DeLamberti greet you.

Our automated trading system has received your order and has promptly dispatched 20 brand new, mint condition glyphs in a fantastic presentation case hand crafted from the exquisite wood of the rare Banyip tree of Epsilon Erandi 5.

Your order is being delivered by UGS (Universal Glyph Service) in one of our fleet of ultra-fast galleons from a DeLamberti trade post near you.

We thank you again for accepting our special introductory offer and hope that we can do business again when we fully open our trading posts in the near future.

Guillaume de Lambert 9th
};
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Your Order has been dispatched.',
        from        => $self->empire,
        body        => $message,
    );

}

# Spoiled order form
sub spoiled_order_email {
    my ($self, $empire, $reason) = @_;

    my $message = qq{
We the DeLamberti greet you.

Our automated trading system received your order unfortunately due to problems with the form we are unable to complete your order.

Reason code: $reason

This may be because of a corruption of the message introduced by the interface between your communication channel and ours or it may be a typo on the form itself.

We still aim to fulfill your order so we will resend the order form and we would urge you to take better care when filling it out.

This is an automated message, the DeLamberti will not enter into correspondence via the medium of email.

DATS (DeLambert Automated Trading System)
};
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Spoiled order form',
        from        => $self->empire,
        body        => $message,
    );
}

# Send introduction email
sub introduction_email {
    my ($self, $empire) = @_;

    my $message = qq{
We the DeLamberti greet you.

We have for some time been keeping a close watch on the Expanse and have been pleased that you now seem to have entered a peaceful phase of existance. (We of course do not count the likes of the Saban in this greeting but we see that you are more than able to contain their aggressive nature).

Let me tell you a little about ourselves.

Our species originally evolved on a high Gravitational world, a Gas Giant, and as such we are physically strong, but short in stature (please don't mock our height, we find it insulting and that's the one thing that will cause us to lose our peaceful composure). For that reason we prefer to set up trading posts on Gas Giants, but for strategic purposes we may from time to time set up smaller outposts on terrestrial type planets.

Due to a lack of resources on our original world we were forced to develop our skills as a trading species. That is our strongest ability and we have learned it over many eons through our contact with countless other species.

We now wish to enter into peaceful trade with you and we will shortly be setting up a number of trading posts close to your centres of population. To demonstrate our peaceful intent we will not occupy any system with populated planets.

Once established, we will connect to your sub-space transporter network and start to offer our goods. (The technology used by your sub-space transporter seems simple enough compaired to ours and our scientists assure us that it will pose no more problem than it took to break into this, your crude communication network).

Please let me assure you again, we are peaceful traders, we pose no threat to you so long as you keep your peace with us.

Watch this space for more news and for our imminent arrival.

Guillaume de Lambert 9th
};
    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'The DeLamberti',
        from        => $self->empire,
        body        => $message,
    );
}

# Send special offer email
sub special_offer_email {
    my ($self, $empire) = @_;

    my $message = qq{
We the DeLamberti greet you.

You may now have seen reports in your Network 19 news that several trading posts have been set up in your area.

We are pleased to tell you that all our trading posts are fully operational, have a full inventory of trade goods and a large fleet of super fast courier ships standing by ready to deliver your orders.

As a one-off, never-to-be-repeated, 30 day trial offer. We would like to make you a gift of a complete set of mint condition glyphs delivered promptly to your planet.

To accept this offer simply reply to this email.

Note, we have taken the liberty to fill in your order form with one gleaming mint condition glyph of each type. You may, if you wish, change the quantities and so long as the total number of glyphs does not exceed 20 we will do our best to honor your request. (should you exceed a total of 20, you will just receive the first 20 glyphs on the order form).

Guillaume de Lambert 9th

----

'Please send me the following mint condition glyphs, delivered to me by your super efficient courier service by return of post'.

1 anthracite
1 bauxite
1 beryl
1 chalcopyrite
1 chromite
1 fluorite
1 galena
1 goethite
1 gold
1 gypsum
1 halite
1 kerogen
1 magnetite
1 methane
1 monazite
1 rutile
1 sulfur
1 trona
1 uraninite
1 zircon

----
small print.
(Offer subject to availability while stocks last. This offer may be withdrawn at any time. No correspondence may be entered into concerning this offer. This offer not available to Diablotin, Saben, Trelvestian or other aggressive species. You must be over the age of consent for your species. Note that combining glyphs in random order may result in dangerous consequences. DeLamberti take no responsibility for subsequent damage, accident, personal injury or death (both permanent and temporary) caused by our products.)
};

    $empire->send_message(
        tag         => 'Correspondence',
        subject     => 'Special Offer',
        from        => $self->empire,
        body        => $message,
    );


}

no Moose;
__PACKAGE__->meta->make_immutable;

