use lib '../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use Lacuna::DB;
use DateTime;
use Coro;
use AnyEvent;

my $access = $ENV{SIMPLEDB_ACCESS_KEY};
my $secret = $ENV{SIMPLEDB_SECRET_KEY};
my $db = Lacuna::DB->new(access_key=>$access, secret_key=>$secret, cache_servers=>[{host=>127.0.0.1, port=>11211}]);

my $start_x = my $start_y = my $start_z = -5;
my $end_x = my $end_y = my $end_z = 5;

my @star_colors = (qw(red green blue yellow white));
my @planet_types = ('habitable planet', 'asteroid', 'gas giant');
my @planet_type_weights = (qw(60 15 15));


my $stars = $db->domain('star');
say "Deleting existing stars domain.";
$stars->delete;
say "Creating new stars domain.";
$stars->create;
my $planets = $db->domain('planet');
say "Deleting existing planets domain.";
$planets->delete;
say "Creating new planets domain.";
$planets->create;

say "Adding stars.";
for my $x ($start_x .. $end_x) {
    for my $y ($start_y .. $end_y) {
        for my $z ($start_z .. $end_z) {
            if (rand(100) <= 15) { # 15% chance of no star
                say "No star at $x, $y, $z!";
            }
            else {
            async {
                say "Creating star at $x, $y, $z.";
                my $star = $stars->insert({
                    name        => sprintf("%d-%d-%d", $x, $y, $z),
                    date_created=> DateTime->now,
                    color       => $star_colors[rand(scalar(@star_colors))],
                    x           => $x,
                    y           => $y,
                    z           => $z,
                });
                async { 
                add_planets($star);
                cede;
                };
            }
            cede;
            }
        }
        cede;
    }
}

# 15 empty


sub add_planets {
    my $star = shift;
    say "\tAdding planets.";
    for my $orbit (1..7) {
        if (rand(100) <= 10) { # 10% chance of no planet in an orbit
            say "\tNo planet at orbit $orbit!";
        } 
        else {
            async {
            my $type = choose_weighted(\@planet_types, \@planet_type_weights);
            say "\tAdding a $type at orbit $orbit.";
            $planets->insert({
                name    => $star->name."-".$orbit,
                orbit   => $orbit,
                type    => $type,
            });
            cede;
            };
        }
    }
}

# 5 empty
# 10 gas
# 20 asteroid
# 65 inhabitable
