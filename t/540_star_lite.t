use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;

my $db = Lacuna->db;

#my $rs = $db->resultset('Map::StarLite')->search({},
#{ bind => [0,422,-10,10,-10,10] }
#);


my $starmap = $db->resultset('Map::StarLite')->get_star_map(0, 422, -10, 10, -10, 10);

diag(Dumper($starmap));
exit;

my $rs;
my $star_id=0;
my $star;
my @out;
while (my $row = $rs->next) {
    if ($row->star_id != $star_id) {
        if ($star_id) {
            push @out, $star;
        }
        $star = {
            name    => $row->star_name,
            color   => $row->star_color,
            x       => $row->star_x,
            y       => $row->star_y,
            id      => $row->star_id,
            bodies  => [],
        };

        $star_id = $row->star_id;
    }
    if (defined $row->body_id) {
        my $body = {
            name    => $row->body_name,
            id      => $row->body_id,
            orbit   => $row->body_orbit,
            x       => $row->body_x,
            y       => $row->body_y,
            type    => $row->body_type,
            image   => $row->body_image,
            size    => $row->body_size,
        };
        push @{$star->{bodies}}, $body;
    }
}
push @out, $star;

diag(Dumper(\@out));
ok(1);

