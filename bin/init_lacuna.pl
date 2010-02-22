use lib '../lib';
use strict;
use 5.010;
use List::Util::WeightedChoice qw( choose_weighted );
use List::Util qw(shuffle);
use Lacuna;
use Lacuna::Util qw(randint);
use List::MoreUtils qw(uniq);
use String::Random;
use DateTime;

my $access = $ENV{SIMPLEDB_ACCESS_KEY};
my $secret = $ENV{SIMPLEDB_SECRET_KEY};
my $db = Lacuna::DB->new(access_key=>$access, secret_key=>$secret, cache_servers=>[{host=>127.0.0.1, port=>11211}]);

create_species();
create_aux_domains();
create_star_map();

sub create_aux_domains {
    foreach my $name (qw(empire session build_queue)) {
        my $domain = $db->domain($name);
        say "Deleting existing $name domain.";
        $domain->delete;
        say "Creating new $name domain.";
        $domain->create;
    }
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
        habitable_orbits        => 3,
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
    my $start_x = my $start_y = my $start_z = -15;
    my $end_x = my $end_y = my $end_z = 15;
    my $star_count = abs($end_x - $start_x) * abs($end_y - $start_y) * abs($end_z - $start_z);
    my @star_colors = (qw(magenta red green blue yellow white));
    my %domains;
    foreach my $domain (qw(star body ore water building waste energy food permanent)) {
        $domains{$domain} = $db->domain($domain);
        say "Deleting existing $domain domain.";
        $domains{$domain}->delete;
        say "Create new $domain domain.";
        $domains{$domain}->create;
    }
    say "Generating star names.";
    my @star_names = get_star_names($star_count);
    say "Have ".scalar(@star_names)." star names";

    say "Adding stars.";
    for my $x ($start_x .. $end_x) {
        say "Start X $x";
        for my $y ($start_y .. $end_y) {
            say "Start Y $y";
            for my $z ($start_z .. $end_z) {
                say "Start Z $z";
                if (rand(100) <= 15) { # 15% chance of no star
                    say "No star at $x, $y, $z!";
                }
                else {
                    my $name = pop @star_names;
                    say "Creating star $name at $x, $y, $z.";
                    my $star = $domains{star}->insert({
                        name        => $name,
                        date_created=> DateTime->now,
                        color       => $star_colors[rand(scalar(@star_colors))],
                        x           => $x,
                        y           => $y,
                        z           => $z,
                    });
                    add_bodies(\%domains, $star);
                }
                say "End Z $z";
            }
            say "End Y $y";
        }
        say "End X $x";
    }
}


sub add_bodies {
    my $domains = shift;
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
        if (randint(1,100) <= 10) { # 10% chance of no body in an orbit
            say "\tNo body at $name!";
        } 
        else {
            my $type = choose_weighted(\@body_types, \@body_type_weights);
            say "\tAdding a $type at $name (".$star->x.",".$star->y.",".$star->z.").";
            my $params = {
                name        => $name,
                orbit       => $orbit,
                x           => $star->x,
                y           => $star->y,
                z           => $star->z,
                star_id     => $star->id,
            };
            if ($type eq 'habitable') {
                $params->{class} = $planet_classes[rand(scalar(@planet_classes))];
                $params->{empire_id} = 'None';
                $params->{size} = randint(25,100);
            }
            elsif ($type eq 'asteroid') {
                $params->{class} = $asteroid_classes[rand(scalar(@asteroid_classes))];
                $params->{size} = randint(1,10);
            }
            else {
                $params->{class} = $gas_giant_classes[rand(scalar(@gas_giant_classes))];
                $params->{empire_id} = 'None';
                $params->{size} = randint(70,121);
            }
            my $body = $domains->{body}->insert($params);
            my $now = DateTime->now;
            if ($body->isa('Lacuna::DB::Body::Planet') && !$body->isa('Lacuna::DB::Body::Planet::GasGiant')) {
                say "\t\tAdding features to body.";
                foreach  my $x (-3, -1, 2, 4, 1) {
                    my $chance = randint(1,100);
                    my $y = randint(-5,5);
                    if ($chance <= 5) {
                        say "\t\t\tAdding lake.";
                        $domains->{permanent}->insert({
                            date_created    => $now,
                            level           => 1,
                            x               => $x,
                            y               => $y,
                            class           => 'Lacuna::DB::Building::Permanent::Lake',
                            body_id         => $body->id,
                        });
                    }
                    elsif ($chance > 45 && $chance <= 50) {
                        say "\t\t\tAdding rocky outcropping.";
                        $domains->{permanent}->insert({
                            date_created    => $now,
                            level           => 1,
                            x               => $x,
                            y               => $y,
                            class           => 'Lacuna::DB::Building::Permanent::RockyOutcrop',
                            body_id         => $body->id,
                        });
                    }
                    elsif ($chance > 95) {
                        say "\t\t\tAdding crater.";
                        $domains->{permanent}->insert({
                            date_created    => $now,
                            level           => 1,
                            x               => $x,
                            y               => $y,
                            class           => 'Lacuna::DB::Building::Permanent::Crater',
                            body_id         => $body->id,
                        });
                    }
                }
            }
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

