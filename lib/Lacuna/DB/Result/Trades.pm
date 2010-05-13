package Lacuna::DB::Result::Trades;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);

__PACKAGE__->table('trades');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    zone                    => { data_type => 'char', size => 16, is_nullable => 0 },
    only_in_zone            => { data_type => 'int', size => 1, default_value => 1 },
    transfer_type           => { data_type => 'char', size => 11, is_nullable => 0 }, # ship | transporter
    only_same_transfer_type => { data_type => 'int', size => 1, default_value => 1 },
    cargo_ship_count        => { data_type => 'int', size => 11, default_value => 0 },
    smuggler_ship_count     => { data_type => 'int', size => 11, default_value => 0 },
    cargo_space_needed      => { data_type => 'int', size => 11, default_value => 0 },
    ask_ratio               => { data_type => 'float', default_value => 0 },
    offer_ratio             => { data_type => 'float', default_value => 0 },
    essentia                => { data_type => 'int', size => 11, default_value => 0 },
    energy                  => { data_type => 'int', size => 11, default_value => 0 },
    water                   => { data_type => 'int', size => 11, default_value => 0 },
    waste                   => { data_type => 'int', size => 11, default_value => 0 },
    food                    => { data_type => 'int', size => 11, default_value => 0 },
    ore                     => { data_type => 'int', size => 11, default_value => 0 },
    bean                    => { data_type => 'int', size => 11, default_value => 0 },
    lapis                   => { data_type => 'int', size => 11, default_value => 0 },
    potato                  => { data_type => 'int', size => 11, default_value => 0 },
    apple                   => { data_type => 'int', size => 11, default_value => 0 },
    root                    => { data_type => 'int', size => 11, default_value => 0 },
    corn                    => { data_type => 'int', size => 11, default_value => 0 },
    cider                   => { data_type => 'int', size => 11, default_value => 0 },
    wheat                   => { data_type => 'int', size => 11, default_value => 0 },
    bread                   => { data_type => 'int', size => 11, default_value => 0 },
    soup                    => { data_type => 'int', size => 11, default_value => 0 },
    chip                    => { data_type => 'int', size => 11, default_value => 0 },
    pie                     => { data_type => 'int', size => 11, default_value => 0 },
    pancake                 => { data_type => 'int', size => 11, default_value => 0 },
    milk                    => { data_type => 'int', size => 11, default_value => 0 },
    meal                    => { data_type => 'int', size => 11, default_value => 0 },
    algae                   => { data_type => 'int', size => 11, default_value => 0 },
    syrup                   => { data_type => 'int', size => 11, default_value => 0 },
    fungus                  => { data_type => 'int', size => 11, default_value => 0 },
    burger                  => { data_type => 'int', size => 11, default_value => 0 },
    shake                   => { data_type => 'int', size => 11, default_value => 0 },
    beetle                  => { data_type => 'int', size => 11, default_value => 0 },
    rutile                  => { data_type => 'int', size => 11, default_value => 0 },
    chromite                => { data_type => 'int', size => 11, default_value => 0 },
    chalcopyrite            => { data_type => 'int', size => 11, default_value => 0 },
    galena                  => { data_type => 'int', size => 11, default_value => 0 },
    gold                    => { data_type => 'int', size => 11, default_value => 0 },
    uraninite               => { data_type => 'int', size => 11, default_value => 0 },
    bauxite                 => { data_type => 'int', size => 11, default_value => 0 },
    goethite                => { data_type => 'int', size => 11, default_value => 0 },
    halite                  => { data_type => 'int', size => 11, default_value => 0 },
    gypsum                  => { data_type => 'int', size => 11, default_value => 0 },
    trona                   => { data_type => 'int', size => 11, default_value => 0 },
    kerogen                 => { data_type => 'int', size => 11, default_value => 0 },
    methane                 => { data_type => 'int', size => 11, default_value => 0 },
    anthracite              => { data_type => 'int', size => 11, default_value => 0 },
    sulfur                  => { data_type => 'int', size => 11, default_value => 0 },
    zircon                  => { data_type => 'int', size => 11, default_value => 0 },
    monazite                => { data_type => 'int', size => 11, default_value => 0 },
    fluorite                => { data_type => 'int', size => 11, default_value => 0 },
    beryl                   => { data_type => 'int', size => 11, default_value => 0 },
    magnetite               => { data_type => 'int', size => 11, default_value => 0 },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Body', 'body_id');

sub add_trade {
    my ($class, %options) = @_;
    my $body = $options{body};

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
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
