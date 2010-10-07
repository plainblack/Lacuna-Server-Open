package Lacuna::DB::Result::Building::Archaeology;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(ORE_TYPES);
use Clone qw(clone);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Construction));
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
    return $self->level;
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
        my $stored = $body->type_stored($type);
        if ($stored >= 10_000) {
            $available{ $type } = $stored;
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
    unless ($self->body->type_stored($ore) >= 10_000) {
        confess [1011, 'Not enough '.$ore.' in storage. You need 10,000.'];
    }
    return 1;
}

sub search_for_glyph {
    my ($self, $ore) = @_;
    $self->can_search_for_glyph($ore);
    my $body = $self->body;
    $body->spend_ore_type($ore, 10_000);
    $body->add_waste(5000);
    $body->update;
    $self->start_work({
        ore_type    => $ore,
    }, 60*60*6)->update;
}

before finish_work => sub {
    my $self = shift;
    if ($self->is_glyph_found) {
        my $ore = $self->work->{ore_type};
        my $body = $self->body;
        $body->add_glyph($ore);
        my $empire = $body->empire;
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'glyph_discovered.txt',
            params      => [$body->name, $ore],
            attachments => {
                image => {
                    title   => $ore,
                    url     => Lacuna->config->get('feeds/surl').'assets/glyphs/'.$ore.'.png',
                }
            }
        );
        $empire->add_medal($ore.'_glyph');
        $body->add_news(70, sprintf('%s has uncovered a rare and ancient %s glyph on %s.',$empire->name, $ore, $body->name));
    }
};

my %recipies = (
    anthracite     => {
        trona       => {
            kerogen     => {
                plan        => 'Lacuna::DB::Result::Building::Permanent::BeeldebanNest',
            },
        },
    },
    bauxite     => {
        plan        => 'Lacuna::DB::Result::Building::Permanent::Sand',
        trona       => {
            kerogen     => {
                monazite    => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::MassadsHenge',
                },
            },
        },
    },
    beryl       => {
        
    },
    chalcopyrite=> {
        plan        => 'Lacuna::DB::Result::Building::Permanent::Lagoon',
        sulfur      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::GeoThermalVent',
        },
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
    fluorite    => {
        kerogen     => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::MalcudField',
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
    gold        => {
        uraninite   => {
            bauxite     => {
                goethite    => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::OracleOfAnid',
                },
            },
        },
    },
    gypsum      => {
        plan        => 'Lacuna::DB::Result::Building::Permanent::Beach1',
        anthracite     => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach9',
        },
        chalcopyrite      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach7',
        },
        chromite     => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach11',
        },
        galena     => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach13',
        },
        goethite     => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach12',
        },
        gypsum      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach2',
        },
        halite      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach5',
        },
        magnetite      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach3',
        },
        methane     => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach10',
        },
        rutile      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach6',
        },
        sulfur       => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach8',
        },
        uraninite      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Beach4',
        },
    },
    halite     => {
        anthracite      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::LapisForest',
        },
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
    magnetite   => {
        halite      => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::NaturalSpring',
        },
        uraninite   => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::Volcano',
        },
    },
    methane     => {
        plan        => 'Lacuna::DB::Result::Building::Permanent::Grove',
        zircon      => {
            fluorite    => {
                plan        => 'Lacuna::DB::Result::Building::Permanent::InterDimensionalRift',
            },
            magnetite   => {
                beryl       => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform',
                },
            },
        },
    },
    monazite    => {
        
    },
    rutile      => {
        plan        => 'Lacuna::DB::Result::Building::Permanent::Crater',
    },
    sulfur          => {
        methane         => {
            galena          => {
                anthracite      => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform',
                },
            },
        },
    },
    trona       => {
        plan        => 'Lacuna::DB::Result::Building::Permanent::RockyOutcrop',
    },
    uraninite   => {
        methane         => {
            plan        => 'Lacuna::DB::Result::Building::Permanent::AlgaePond',
        },
    },
    zircon      => {
        methane         => {
            galena          => {
                fluorite        => {
                    plan        => 'Lacuna::DB::Result::Building::Permanent::Ravine',
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
    my $match = clone(\%recipies);
    my $glyphs = $self->body->glyphs;
    foreach my $id (@{$ids}) {
        my $glyph = $glyphs->find($id);
        last unless exists $match->{$glyph->type};
        $match = $match->{$glyph->type};
    }
    unless (exists $match->{plan}) {
        confess [1002, 'The glyphs specified do not fit together in that manner.'];
    }
    $glyphs->search({ id => { in => $ids}})->delete;
    return $self->body->add_plan($match->{plan}, 1);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
