package Lacuna::AI::DeLambert;

use Moose;
use utf8;
no warnings qw(uninitialized);
use Data::Dumper;

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
    $self->repair_buildings($colony);
    $self->train_spies($colony, 1);
    $self->build_ships_max($colony);
    $self->run_missions($colony);
}

sub run_hourly_empire_updates {
    my ($self, $empire) = @_;

    $self->process_email($empire);
}

sub get_colony_scratchpad {
    my ($self, $colony) = @_;

    my ($scratch) = Lacuna::db->resultset('Lacuna::DB::Result::AIScratchPad')->search({
        ai_empire_id    => $self->empire_id,
        body_id         => $colony->id,
    });

    return $scratch;
}

sub process_email {
    my ($self) = @_;

    my $empire = $self->empire;
    my $messages = $self->empire->received_messages->search({
        has_read    => 0,
        tag         => 'Correspondence',
    });
    MESSAGE:
    while (my $message = $messages->next) {
        print("Received message [".$message->subject."]\n");
        if ($message->from_id == $self->empire->id) {
            # message is from oneself
            $message->has_read(1);
            $message->update;
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
                for (1..$quantity) {
                    push @{$payload->{glyphs}}, lc $glyph;
                }
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
