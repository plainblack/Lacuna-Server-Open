package Lacuna::DB::Trades;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util qw(format_date);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

__PACKAGE__->set_domain_name('trades');
__PACKAGE__->add_attributes(
    body_id                 => { isa => 'Str' },
    zone                    => { isa => 'Str' },
    only_in_zone            => { isa => 'Str' },
    transfer_type           => { isa => 'Str' },
    only_same_transfer_type => { isa => 'Str' },
    cargo_ship_count        => { isa => 'Int' },
    smuggler_ship_count     => { isa => 'Int' },
    resources               => { isa => 'HashRef' },
    cargo_space_needed      => { isa => 'Int' },
    ratio                   => { isa => 'Str' },
    ratio_sort              => { isa => 'Int' },
    ask_types               => { isa => 'ArrayRefOfStr'},
    offer_types             => { isa => 'ArrayRefOfStr'},
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body::Planet', 'body_id');

sub add_trade {
    my ($class, %options) = @_;
    my $body = $options{body};
    $body->tick;

    # trading
    my $ask_tally;
    my $ask = $options{ask};
    my @ask_types;
    my $offer_tally;
    my $offer = $options{offer};
    my @offer_types;
    
    # basic resources
    foreach my $type (qw(energy water waste food ore)) {
        if ($offer->{$type} > 0) {
            my $stored = $type.'_stored';
            unless ($body->$stored >= $offer->{$type}) {
                confess [1011, 'Not enough '.$type.' in storage.', $type];
            }
            $offer_tally += $offer->{$type};
            push @offer_types, $type;
        }
        if ($ask->{$type} > 0) {
            $ask_tally += $ask->{$type};
            push @ask_types, $type;
        }
    }

    # trade essentia
    if ($ask->{essentia} > 0) {
        $ask_tally += $ask->{essentia};
        push @ask_types, 'essentia';
    }
    if ($offer->{essentia} > 0) {
        $offer_tally += $offer->{essentia};
        push @offer_types, 'essentia';
    }
    
    # specific foods
    my $offer_foods = $offer->{fooods};
    my $ask_foods = $ask->{foods};
    foreach my $type (FOOD_TYPES) {
        if ($offer_foods->{$type} > 0) {
            $offer_tally += $offer_foods->{$type};
            my $stored = $type.'_stored';
            unless ($body->$stored >= $offer_foods->{$type}) {
                confess [1011, 'Not enough '.$type.' in storage.', $type];
            }
            $offer_tally += $offer->{$type};
            push @offer_types, $type;
        }
        if ($ask_foods->{$type} > 0) {
            $ask_tally += $ask_foods->{$type};
            push @ask_types, $type;
        }
    }
    
    # specific ores
    my $offer_ores = $offer->{ores};
    my $ask_ores = $ask->{ores};
    foreach my $type (ORE_TYPES) {
        if ($offer_ores->{$type} > 0) {
            my $stored = $type.'_stored';
            unless ($body->$stored >= $offer_ores->{$type}) {
                confess [1011, 'Not enough '.$type.' in storage.', $type];
            }
            $offer_tally += $offer_ores->{$type};
            push @offer_types, $type;
        }
        if ($ask_ores->{$type} > 0) {
            $ask_tally += $ask_ores->{$type};
            push @ask_types, $type;
        }
    }
    
    # transfer type    
    my $spaceport = $body->spaceport;
    
    # set up the trade
    return $options{simpledb}->domain('trades')->insert({
        body_id                 => $body->id,
        zone                    => $body->zone,
        only_in_zone            => $options{only_in_zone} || 0,
        transfer_type           => $options{transfer_type},
        only_same_transfer_type => $options{only_same_transfer_type},
        resources               => { ask => $options{ask}, offer => $options{offer} },
        ask_types               => \@ask_types,
        cargo_space_needed      => $ask_tally,
        offer_types             => \@offer_types,
    });
}

no Moose;
__PACKAGE__->meta->make_immutable;
