package Lacuna::DB::Result::Plan;

use 5.010;
use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('plan');
__PACKAGE__->add_columns(
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    class                   => { data_type => 'varchar', size => 255, is_nullable => 0 },
    level                   => { data_type => 'tinyint', is_nullable => 0 },
    extra_build_level       => { data_type => 'tinyint', is_nullable => 1, default_value => 0 },
    quantity                => { data_type => 'int', size => 11, is_nullable => 0 },
);

sub level_formatted {
    my ($self) = @_;

    my $level = $self->level;
    if ($self->extra_build_level) {
        $level .= '+'.$self->extra_build_level;
    }
    return $level;
}

my $recipes = {
    'Lacuna::DB::Result::Building::Permanent::LibraryOfJith'        => [qw(anthracite bauxite beryl chalcopyrite)],
    'Lacuna::DB::Result::Building::Permanent::BeeldebanNest'        => [qw(anthracite trona kerogen)],
    'Lacuna::DB::Result::Building::Permanent::Sand'                 => [qw(bauxite)],
#    'Lacuna::DB::Result::Building::Permanent::MassadsHenge'         => [qw(bauxite trona kerogen monazite)],
    'Lacuna::DB::Result::Building::Permanent::CitadelOfKnope'       => [qw(beryl sulfur monazite galena)],
    'Lacuna::DB::Result::Building::Permanent::AmalgusMeadow'        => [qw(beryl trona)],
    'Lacuna::DB::Result::Building::Permanent::Lagoon'               => [qw(chalcopyrite)],
    'Lacuna::DB::Result::Building::Permanent::GeoThermalVent'       => [qw(chalcopyrite sulfur)],
    'Lacuna::DB::Result::Building::Permanent::GratchsGauntlet'      => [qw(chromite bauxite gold kerogen)],
    'Lacuna::DB::Result::Building::Permanent::MalcudField'          => [qw(fluorite kerogen)],
    'Lacuna::DB::Result::Building::Permanent::KalavianRuins'        => [qw(galena gold)],
    'Lacuna::DB::Result::Building::Permanent::Lake'                 => [qw(goethite)],
    'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk A'     => [qw(goethite halite gypsum trona)],
    'Lacuna::DB::Result::Building::Permanent::OracleOfAnid'         => [qw(gold uraninite bauxite goethite)],
    'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk B'     => [qw(gold anthracite uraninite bauxite)],
    'Lacuna::DB::Result::Building::Permanent::Beach1'               => [qw(gypsum)],
    'Lacuna::DB::Result::Building::Permanent::Beach9'               => [qw(gypsum anthracite)],
    'Lacuna::DB::Result::Building::Permanent::Beach7'               => [qw(gypsum chalcopyrite)],
    'Lacuna::DB::Result::Building::Permanent::Beach11'              => [qw(gypsum chromite)],
    'Lacuna::DB::Result::Building::Permanent::Beach13'              => [qw(gypsum galena)],
    'Lacuna::DB::Result::Building::Permanent::Beach12'              => [qw(gypsum goethite)],
    'Lacuna::DB::Result::Building::Permanent::Beach2'               => [qw(gypsum gypsum)],
    'Lacuna::DB::Result::Building::Permanent::Beach5'               => [qw(gypsum halite)],
    'Lacuna::DB::Result::Building::Permanent::Beach3'               => [qw(gypsum magnetite)],
    'Lacuna::DB::Result::Building::Permanent::Beach10'              => [qw(gypsum methane)],
    'Lacuna::DB::Result::Building::Permanent::Beach6'               => [qw(gypsum rutile)],
    'Lacuna::DB::Result::Building::Permanent::Beach8'               => [qw(gypsum sulfur)],
    'Lacuna::DB::Result::Building::Permanent::PantheonOfHagness'    => [qw(gypsum trona beryl anthracite)],
    'Lacuna::DB::Result::Building::Permanent::Beach4'               => [qw(gypsum uraninite)],
    'Lacuna::DB::Result::Building::Permanent::LapisForest'          => [qw(halite anthracite)],
    'Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator'   => [qw(kerogen beryl anthracite monazite)],
    'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk C'     => [qw(kerogen methane sulfur zircon)],
    'Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites'=> [qw(kerogen rutile chromite chalcopyrite)],
    'Lacuna::DB::Result::Building::Permanent::NaturalSpring'        => [qw(magnetite halite)],
    'Lacuna::DB::Result::Building::Permanent::Volcano'              => [qw(magnetite uraninite)],
    'Lacuna::DB::Result::Building::Permanent::Grove'                => [qw(methane)],
    'Lacuna::DB::Result::Building::Permanent::InterDimensionalRift' => [qw(methane zircon fluorite)],
    'Lacuna::DB::Result::Building::Permanent::TerraformingPlatform' => [qw(methane zircon magnetite beryl)],
    'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk D'     => [qw(monazite fluorite beryl magnetite)],
    'Lacuna::DB::Result::Building::Permanent::CrashedShipSite'      => [qw(monazite trona gold bauxite)],
#    'Lacuna::DB::Result::Building::Permanent::KasternsKeep'         => [qw(monazite uraninite sulfur trona)],
    'Lacuna::DB::Result::Building::Permanent::Crater'               => [qw(rutile)],
    'Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk E'     => [qw(rutile chromite chalcopyrite galena)],
    'Lacuna::DB::Result::Building::Permanent::DentonBrambles'       => [qw(rutile goethite)],
    'Lacuna::DB::Result::Building::Permanent::GasGiantPlatform'     => [qw(sulfur methane galena anthracite)],
    'Lacuna::DB::Result::Building::Permanent::RockyOutcrop'         => [qw(trona)],
    'Lacuna::DB::Result::Building::Permanent::AlgaePond'            => [qw(uraninite methane)],
    'Lacuna::DB::Result::Building::Permanent::Ravine'               => [qw(zircon methane galena fluorite)],
};

# given a plan class, return the glyph recipe
# (note, Halls must specify A,B,C,D or E)
#
sub get_glyph_recipe {
    my ($class,$plan_class) = @_;

    return $recipes->{$plan_class};
}

# Given glyphs, return the plan (if any)
sub check_glyph_recipe {
    my ($class, $glyphs) = @_;

    my ($plan_class) = grep {@{$recipes->{$_}} ~~ @$glyphs} keys %$recipes;
    if (defined $plan_class) {
        # Sort out different Halls recipes
        $plan_class =~ s/HallsOfVrbansk.*$/HallsOfVrbansk/;
    }

    return $plan_class;
}

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
