use 5.10.0;
use strict;
use lib '/data/Lacuna-Server/lib';
use Getopt::Long;

use L;

GetOptions(
    'quiet!'        => \$quiet,
);

out("Started");

my $rs = LD->bodies(
                    {
                        class => 'Lacuna::DB::Result::Map::Body::Planet::Station',
                    }
                   );

# because we're initialising it, let's give everything a 12-hour head start.
my $starttime = DateTime->now->subtract(hours => 12);
while(my $station = $rs->next)
{
    out("..." . $station->name);
    $station->update_influence({starttime=>$starttime});
}

out("Recalculating all control (will take a while).");
LD->resultset("Map::Star")->recalc_control;

out("Done.");
