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
say "Generating star names.";
my @star_names = get_star_names();

say "Adding stars.";
for my $x ($start_x .. $end_x) {
    for my $y ($start_y .. $end_y) {
        for my $z ($start_z .. $end_z) {
            if (rand(100) <= 15) { # 15% chance of no star
                say "No star at $x, $y, $z!";
            }
            else {
                async {
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
                    add_planets($star);
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
        my $name = $star->name."-".$orbit;
        if (rand(100) <= 10) { # 10% chance of no planet in an orbit
            say "\tNo planet at $name!";
        } 
        else {
            async {
                my $type = choose_weighted(\@planet_types, \@planet_type_weights);
                say "\tAdding a $type at $name.";
                $planets->insert({
                    name    => $name,
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


sub get_star_names {
    open my $file, "<", "../doc/starnames.txt";
    my @contents = <$file>;
    close $file;

    my $rs = String::Random->new;

    $rs->{e} = [qw(a e i o u ea ee oa oo io ia ae ou ie oe ai ui eu ow)];
    $rs->{E} = [qw(A E I O U Ea Ee Oa Oo Io Ia Ae Ou)];
    $rs->{b} = [qw(b c d f g h j k l m n p qu r s t v w x y z ch sh fl fr bl sl st gr th xy tr tch sch sn pl pr sph ph str ly gl gh ll nd rv gg mb ck hl ckl pp ss mp nt nd rn ng tt ss dd cc ndl zz rn)];
    $rs->{B} = [qw(B C D F G H J K L M N P Qu R S T V W X Y Z Ch Sh Fl Fr Bl Sl St Gr Th Xy Tr Tch Sch Sn Pl Pr Sph Ph Str Ly Gl Gh Ll Rh Kl Cl Vl Kn)];
    $rs->{' '} = [' '];

    my $star_count = abs($end_x - $start_x) * abs($end_y - $start_y) * abs($end_z - $start_z);
    my $name_count = (($star_count - 637) / 10) + 1;

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

