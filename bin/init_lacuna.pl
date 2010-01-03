use lib '../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq);
use String::Random;
use Lacuna::DB;
use DateTime;
use Coro;
use AnyEvent;

my $access = $ENV{SIMPLEDB_ACCESS_KEY};
my $secret = $ENV{SIMPLEDB_SECRET_KEY};
my $db = Lacuna::DB->new(access_key=>$access, secret_key=>$secret, cache_servers=>[{host=>127.0.0.1, port=>11211}]);

#create_species();
#create_empires();
create_star_map();


sub create_empires {
    my $empires = $db->domain('empire');
    say "Deleting existing empire domain.";
    $empires->delete;
    say "Creating new empire domain.";
    $empires->create;
}

sub create_species {
    my $species = $db->domain('species');
    say "Deleting existing species domain.";
    $species->delete;
    say "Creating new species domain.";
    $species->create;
    say "Adding humans.";
    $species->insert({
        name                    => 'Human',
        description             => 'A race of average intellect, and weak constitution.',
        habitable_orbits        => [3],
        construction_affinity   => 4, # cost of building new stuff
        deception_affinity      => 4, # spying ability
        research_affinity       => 4, # cost of upgrading
        management_affinity     => 4, # speed to build
        farming_affinity        => 4, # food
        mining_affinity         => 4, # minerals
        science_affinity        => 4, # energy, propultion, and other tech
        environmental_affinity  => 4, # waste and water
        political_affinity      => 4, # happiness
        trade_affinity          => 4, # speed of cargoships, and amount of cargo hauled
        growth_affinity         => 4, # price and speed of colony ships, and planetary command center start level
    }, 'human_species');
}

sub create_star_map {
    my $start_x = my $start_y = my $start_z = -5;
    my $end_x = my $end_y = my $end_z = 5;
    my $star_count = abs($end_x - $start_x) * abs($end_y - $start_y) * abs($end_z - $start_z);
    my @star_colors = (qw(magenta red green blue yellow white));
    my $stars = $db->domain('star');
    say "Deleting existing stars domain.";
    $stars->delete;
    say "Creating new stars domain.";
    $stars->create;
    my $bodies = $db->domain('body');
    say "Deleting existing bodies domain.";
    $bodies->delete;
    say "Creating new bodies domain.";
    $bodies->create;
    say "Generating star names.";
    my @star_names = get_star_names($star_count);
    say "Have ".scalar(@star_names)." star names";

    say "Adding stars.";
    for my $x ($start_x .. $end_x) {
        for my $y ($start_y .. $end_y) {
            for my $z ($start_z .. $end_z) {
                if (rand(100) <= 15) { # 15% chance of no star
                    say "No star at $x, $y, $z!";
                }
                else {
#                    async {
                        my $name = pop @star_names;
                        say "Creating star $name at $x, $y, $z.";
                        my $star = $stars->insert({
                            name        => $name,
                            date_created=> DateTime->now,
                            color       => $star_colors[rand(scalar(@star_colors))],
                            x           => $x,
                            y           => $y,
                            z           => $z,
                        });
                        add_bodies($bodies, $star);
 #                   	cede;
   #                 }
                }
            }
  #          cede;
        }
    }
}


sub add_bodies {
    my $bodies = shift;
    my $star = shift;
    my @body_types = ('habitable', 'asteroid', 'gas giant');
    my @body_type_weights = (qw(60 15 15));
    my @planet_classes = qw(Lacuna::DB::Body::Planet::P1 Lacuna::DB::Body::Planet::P2 Lacuna::DB::Body::Planet::P3 Lacuna::DB::Body::Planet::P4
        Lacuna::DB::Body::Planet::P5 Lacuna::DB::Body::Planet::P6 Lacuna::DB::Body::Planet::P7 Lacuna::DB::Body::Planet::P8 Lacuna::DB::Body::Planet::P9
        Lacuna::DB::Body::Planet::P10 Lacuna::DB::Body::Planet::P11 Lacuna::DB::Body::Planet::P12 Lacuna::DB::Body::Planet::P13
        Lacuna::DB::Body::Planet::P14 Lacuna::DB::Body::Planet::P15 Lacuna::DB::Body::Planet::P16 Lacuna::DB::Body::Planet::P17
        Lacuna::DB::Body::Planet::P18 Lacuna::DB::Body::Planet::P19 Lacuna::DB::Body::Planet::P20);
    my @gas_giant_classes = qw(Lacuna::DB::Body::Planet::GasGiant::G1 Lacuna::DB::Body::Planet::GasGiant::G2 Lacuna::DB::Body::Planet::GasGiant::G3
        Lacuna::DB::Body::Planet::GasGiant::G4 Lacuna::DB::Body::Planet::GasGiant::G5);
    my @asteroid_classes = qw(Lacuna::DB::Body::Asteroid::A1 Lacuna::DB::Body::Asteroid::A2 Lacuna::DB::Body::Asteroid::A3
        Lacuna::DB::Body::Asteroid::A4 Lacuna::DB::Body::Asteroid::A5);
    say "\tAdding bodies.";
    for my $orbit (1..7) {
        my $name = $star->name."-".$orbit;
        if (rand(100) <= 10) { # 10% chance of no body in an orbit
            say "\tNo body at $name!";
        } 
        else {
          #  async {
                my $type = choose_weighted(\@body_types, \@body_type_weights);
                say "\tAdding a $type at $name.";
                my $class;
                my $size;
                if ($type eq 'habitable') {
                    $class = $planet_classes[rand(scalar(@planet_classes))];
                    $size = rand(50) + 20;
                }
                elsif ($type eq 'asteroid') {
                    $class = $asteroid_classes[rand(scalar(@asteroid_classes))];
                    $size = rand(10);
                }
                else {
                    $class = $gas_giant_classes[rand(scalar(@gas_giant_classes))];
                    $size = rand(50)+70;
                }
                $bodies->insert({
                    name    => $name,
                    orbit   => $orbit,
                    class   => $class,
                    size    => $size,
                    star_id => $star->id,
                });
           #     cede;
           # };
        }
    }
}


sub get_star_names {
    my $star_count = shift;
    open my $file, "<", "../var/starnames.txt";
    my @contents;
    while (my $name = <$file>) {
	chomp $name;
        push @contents, $name;
    }
    close $file;

    my $rs = String::Random->new;

    $rs->{e} = [qw(a e i o u ea ee oa oo io ia ae ou ie oe ai ui eu ow)];
    $rs->{E} = [qw(A E I O U Ea Ee Oa Oo Io Ia Ae Ou)];
    $rs->{b} = [qw(b c d f g h j k l m n p qu r s t v w x y z ch sh fl fr bl sl st gr th xy tr tch sch sn pl pr sph ph str ly gl gh ll nd rv gg mb ck hl ckl pp ss mp nt nd rn ng tt ss dd cc ndl zz rn)];
    $rs->{B} = [qw(B C D F G H J K L M N P Qu R S T V W X Y Z Ch Sh Fl Fr Bl Sl St Gr Th Xy Tr Tch Sch Sn Pl Pr Sph Ph Str Ly Gl Gh Ll Rh Kl Cl Vl Kn)];
    $rs->{' '} = [' '];

    my $name_count = ($star_count / 10) + 1;

    for (1..$name_count) {
        push @contents, $rs->randpattern('Ebe');
        push @contents, $rs->randpattern('Beb');
        push @contents, $rs->randpattern('Bebe');
        push @contents, $rs->randpattern('Ebeb');
        push @contents, $rs->randpattern('Ebebe');
        push @contents, $rs->randpattern('Ebebeb');
        push @contents, $rs->randpattern('Eb Beb');
        push @contents, $rs->randpattern('Be Ebe');
        push @contents, $rs->randpattern('Eb Bebe');
        push @contents, $rs->randpattern('Be Ebeb');
    }

    return shuffle( uniq( @contents ));
}

