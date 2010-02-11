package Lacuna::Constants;

use strict;
use base 'Exporter';

use constant INFLATION => 1.8847;
use constant GROWTH => 1.292;
use constant FOOD_TYPES => (qw(lapis potato apple root corn cider wheat bread soup chip pie pancake milk meal algae syrup fungus burger shake beetle));
use constant ORE_TYPES => (qw(rutile chromite chalcopyrite galena gold uraninite bauxite limonite halite gypsum trona kerogen petroleum anthracite sulfate zircon monazite fluorite beryl magnetite));

our @EXPORT_OK = qw(
    INFLATION
    GROWTH
    FOOD_TYPES
    ORE_TYPES
);

our %EXPORT_TAGS = (
    all =>  [qw(
        INFLATION
        GROWTH
        FOOD_TYPES
        ORE_TYPES
        )],
);

1;
