use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use JSON;
use SOAP::Amazon::S3;
use Lacuna::Constants qw(SHIP_TYPES ORE_TYPES);
use utf8;


  $|=1;

  our $quiet;
  our $from;
  our $to;
  our $move_p;
  our $move_g;

  GetOptions(
    'quiet'   => \$quiet,  
    'from=i'  => \$from,
    'to=i'    => \$to,
  );

  die "Must give from and to body ids\n" unless ($from and $to);
  die "to and from must be different!\n" if ($from == $to);
  out('Started');
  my $start = DateTime->now;

  out('Loading DB');
  our $db = Lacuna->db;

  my $body_from = $db->resultset('Map::Body')->search({id => $from})->single;
  my $body_dest = $db->resultset('Map::Body')->search({id => $to})->single;

  out(sprintf("%s at %d/%d -> %s at %d/%d",
              $body_from->name, $body_from->x, $body_from->y,
              $body_dest->name, $body_dest->x, $body_dest->y)); 
  my $return = bhg_swap($body_from,$body_dest);

exit;

sub bhg_swap {
    my ($body, $target) = @_;
    my $return;
    my $old_data = {
        x       => $body->x,
        y       => $body->y,
        zone    => $body->zone,
        star_id => $body->star_id,
        orbit   => $body->orbit,
    };
    my $new_data;
    if (ref $target eq 'HASH') {
        $new_data = {
            id      => $target->{id},
            name    => $target->{name},
            orbit   => $target->{orbit},
            star_id => $target->{star_id},
            type    => $target->{type},
            x       => $target->{x},
            y       => $target->{y},
            zone    => $target->{zone},
        };
    }
    else {
        $new_data = {
            id      => $target->id,
            name    => $target->name,
            orbit   => $target->orbit,
            star_id => $target->star_id,
            type    => $target->get_type,
            x       => $target->x,
            y       => $target->y,
            zone    => $target->zone,
        };
    }
    $body->update({
        needs_recalc => 1,
        x       => $new_data->{x},
        y       => $new_data->{y},
        zone    => $new_data->{zone},
        star_id => $new_data->{star_id},
        orbit   => $new_data->{orbit},
    });
    
    unless ($new_data->{type} eq "empty") {
        $target->update({
            needs_recalc => 1,
            x       => $old_data->{x},
            y       => $old_data->{y},
            zone    => $old_data->{zone},
            star_id => $old_data->{star_id},
            orbit   => $old_data->{orbit},
        });
        if ($new_data->{type} ne 'asteroid') {
            my $target_waste = Lacuna->db->resultset('Lacuna::DB::Result::WasteChain')
                ->search({ planet_id => $target->id });
            if ($target_waste->count > 0) {
                while (my $chain = $target_waste->next) {
                    $chain->update({
                        star_id => $old_data->{star_id}
                    });
                }
            }
            if ($new_data->{type} eq 'space station') {
                drop_stars_beyond_range($target);
            }
        }
        if (defined($target->empire)) {
            my $mbody = Lacuna->db
                ->resultset('Lacuna::DB::Result::Map::Body')
                ->find($target->id);
            my $fbody = Lacuna->db
                ->resultset('Lacuna::DB::Result::Map::Body')
                ->find($body->id);
            my $mess = sprintf("{Starmap %s %s %s} is now at %s/%s in orbit %s around {Starmap %s %s %s}.",
                    $fbody->x, $fbody->y, $fbody->name,
                    $fbody->x, $fbody->y, $fbody->orbit,
                    $fbody->star->x, $fbody->star->y, $fbody->star->name);
            $target->empire->send_predefined_message(
                tags     => ['Alert'],
                filename => 'planet_moved.txt',
                params   => [
                    $mbody->x,
                    $mbody->y,
                    $mbody->name,
                    $mbody->x,
                    $mbody->y,
                    $mbody->orbit,
                    $mbody->star->x,
                    $mbody->star->y,
                    $mbody->star->name,
                    $mess,
                ],
            );
        }
    }
    if ($body->get_type ne 'asteroid') {
        my $waste_chain = Lacuna->db->resultset('Lacuna::DB::Result::WasteChain')
            ->search({ planet_id => $body->id });
        if ($waste_chain->count > 0) {
            while (my $chain = $waste_chain->next) {
                $chain->update({
                    star_id => $new_data->{star_id}
                });
            }
        }
        if ($body->get_type eq 'space station') {
            drop_stars_beyond_range($body);
        }
    }
    if (defined($body->empire)) {
        my $mbody = Lacuna->db
            ->resultset('Lacuna::DB::Result::Map::Body')
            ->find($body->id);
        my $mess;
        unless ($new_data->{type} eq "empty") {
            my $fbody = Lacuna->db
                ->resultset('Lacuna::DB::Result::Map::Body')
                ->find($target->id);
            $mess = sprintf("{Starmap %s %s %s} took our place at %s/%s in orbit %s around {Starmap %s %s %s}.",
                    $fbody->x, $fbody->y, $fbody->name,
                    $fbody->x, $fbody->y, $fbody->orbit,
                    $fbody->star->x, $fbody->star->y, $fbody->star->name);
        }
        else {
            my $star = Lacuna->db->
                       resultset('Lacuna::DB::Result::Map::Star')->find($old_data->{star_id});
            $mess = sprintf("There is now an empty orbit at %s/%s in orbit %s around {Starmap %s %s %s}",
                    $old_data->{x}, $old_data->{y}, $old_data->{orbit},
                    $star->x, $star->y, $star->name);
        }
        $body->empire->send_predefined_message(
            tags     => ['Alert'],
            filename => 'planet_moved.txt',
            params   => [
                    $mbody->x,
                    $mbody->y,
                    $mbody->name,
                    $mbody->x,
                    $mbody->y,
                    $mbody->orbit,
                    $mbody->star->x,
                    $mbody->star->y,
                    $mbody->star->name,
                    $mess,
            ],
        );
    }
    unless ($new_data->{type} eq "empty" or $new_data->{type} eq 'asteroid') {
        $target->recalc_chains; # Recalc all chains
        recalc_incoming_supply($target);
    }
    if ($body->get_type ne 'asteroid') {
        $body->recalc_chains; # Recalc all chains
        recalc_incoming_supply($body);
    }
    $body->update({needs_recalc => 1});
    $target->update({needs_recalc => 1});
    
    return {
        id       => $body->id,
        message  => "Swapped Places",
        name     => $body->name,
        orbit    => $new_data->{orbit},
        star_id  => $new_data->{star_id},
        swapname => $new_data->{name},
        swapid   => $new_data->{id},
    };
}

sub drop_stars_beyond_range {
    my ($station) = @_;

    return 0 if ($station->get_type ne 'space station');
    my $laws = $station->laws->search({type => 'Jurisdiction'});
    while (my $law = $laws->next) {
        unless ($station->in_range_of_influence($law->star)) {
            $law->delete;
        }
    }
    return 1;
}

sub recalc_incoming_supply {
    my ($body) = @_;

    my $all_chains = $body->in_supply_chains;

    my %bids;
    while (my $chain = $all_chains->next) {
        my $bid = $chain->planet_id;
        next if defined($bids{$bid});
        $bids{$bid} = 1;
        my $sender = Lacuna->db
            ->resultset('Lacuna::DB::Result::Map::Body')
            ->find($bid);
        if (defined($sender->empire)) {
            $sender->recalc_chains; # Recalc all chains
        }
    }
}

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}
