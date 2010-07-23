package Lacuna::DB::Result::Building::Archaeology;

use Moose;
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(ORE_TYPES);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure));
};

use constant max_instances_per_planet => 1;
use constant controller_class => 'Lacuna::RPC::Building::Archaeology';

use constant university_prereq => 10;

use constant image => 'archaeology';

use constant name => 'Archaeology Ministry';

use constant food_to_build => 210;

use constant energy_to_build => 240;

use constant ore_to_build => 210;

use constant water_to_build => 190;

use constant waste_to_build => 250;

use constant time_to_build => 500;

use constant food_consumption => 20;

use constant energy_consumption => 5;

use constant ore_consumption => 5;

use constant water_consumption => 30;

use constant waste_production => 20;

sub chance_of_glyph {
    my $self = shift;
    return ($self->level * 0.5) + 0.5;
}

sub is_glyph_found {
    my $self = shift;
    return rand(100) <= $self->chance_of_glyph;
}

sub get_ores_available_for_processing {
    my ($self) = @_;
    my $body = $self->body;
    my %available;
    foreach my $type (ORE_TYPES) {
        my $stored = $type.'_stored';
        if ($body->$stored >= 10_000) {
            $available{ $type } = $body->$stored;
        }
    }
    return \%available;
}

sub can_search_for_glyph {
    my ($self, $ore) = @_;
    unless ($self->level > 0) {
        confess [1010, 'The Archaeology Ministry is not finished building yet.'];
    }
    unless ($ore ~~ [ ORE_TYPES ]) {
        confess [1005, $ore.' is not a valid type of ore.'];
    }
    if ($self->is_working) {
        confess [1010, 'The Archaeology Ministry is already searching for a glyph.'];
    }
    my $stored = $ore.'_stored';
    unless ($self->body->$stored >= 10_000) {
        confess [1011, 'Not enough '.$ore.' in storage. You need 10,000.'];
    }
    return 1;
}

sub search_for_glyph {
    my ($self, $ore) = @_;
    $self->can_search_for_glyph($ore);
    my $body = $self->body;
    my $stored = $ore.'_stored';
    $body->$stored( $body->$stored - 10_000 );
    $body->add_waste(5000);
    $body->update;
    $self->start_work({
        ore_type    => $ore,
    }, 60*60*3)->update;
}

before finish_work => sub {
    my $self = shift;
    if ($self->is_glyph_found) {
        my $ore = $self->work->{ore_type};
        $self->body->add_glyph($ore);
        my $empire = $self->body->empire;
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'glyph_discovered.txt',
            params      => [$self->body->name, $ore],
        );
        $empire->add_medal($ore.'_glyph');
    }
};

my %recipies = (
#    gypsum      => {
#        plan        => 'Lacuna::DB::Result::Building::Permanent::BeachA',
#        gypsum      => {
#            plan        => 'Lacuna::DB::Result::Building::Permanent::BeachB',
#        },
#    },
    magnetite   => {
        uraninite   => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Volcano',
        },
        halite      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::NaturalSpring',
        }
    },
    rutile      => {
        plan        => 'Lacuna::DB::Result::Building::Permanent::Crater',
    },
    chalcopyrite=> {
        sulfur      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::GeoThermalVent',
        },
    },
    sulfur          => {
        methane         => {
            galena          => {
                anthracite      => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform',
                }
            }
        }
    },
    methane     => {
        zircon      => {
            fluorite    => {
                plan        => 'Lacuna::DB::Result::Building::Permanent::InterDimensionalRift',
            },
            magnetite   => {
                beryl       => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',
                }
            },
        },
    },
    galena      => {
        gold        => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::KalavianRuins',
        },
    },
    goethite    => {
        plan        => 'Lacuna::DB::Result::Building::Permanent::Lake',
    },
    chromite    => {
        halite      => {
            anthracite  =>  {
                beryl       => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::LibraryOfJith',
                },
            },
        },
    },
    bauxite     => {
        trona       => {
            kerogen     => {
                monazite    => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::MassadsHenge',
                },
            },
        },
    },
    gold        => {
        uraninite   => {
            bauxite     => {
                goethite    => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::OracleOfAnid',
                },
            },
        },
    },
    trona       => {
        plan        => 'Lacuna::DB::Result::Building::Permanent::RockyOutcrop',
    },
    kerogen     => {
        rutile      => {
            chromite    => {
                chalcopyrite=> {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites',
                },
            },
        },
    },
);
#rutile chromite chalcopyrite galena gold uraninite bauxite goethite halite
#gypsum trona kerogen methane anthracite sulfur zircon monazite fluorite beryl magnetite

sub make_plan {
    my ($self, $ids) = @_;
    unless (ref $ids eq 'ARRAY' && scalar(@{$ids}) < 5) {
        confess [1009, 'The ids field needs to be an array reference of no more than 4 elements.'];
    }
    my $glyphs = $self->body->glyphs->search({id => { in => $ids }});
    my $match = \%recipies;
    while (my $glyph = $glyphs->next) {
        last unless exists $match->{$glyph->type};
        $match = $match->{$glyph->type};
    }
    unless (exists $match->{plan}) {
        confess [1002, 'The glyphs specified do not fit together in that manner.'];
    }
    $glyphs->reset->delete;
    return $self->body->add_plan($match->{plan}, 1);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
