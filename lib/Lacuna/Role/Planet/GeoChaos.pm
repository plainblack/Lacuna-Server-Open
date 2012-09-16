package Lacuna::Role::Planet::GeoChaos;

use Digest::MD5 qw(md5_hex);

use Moose::Role;
use Lacuna::Constants qw(SECONDS_IN_A_DAY ORE_TYPES);

foreach my $ore (ORE_TYPES) {
    around $ore => sub {
        my $orig = shift;
        my $self = shift;

        my $max     = $self->$orig(@_);

        # offset the day so all planets have a different start cycle
        my $day     = time / SECONDS_IN_A_DAY;
        $day       += $self->id * $self->orbit;

        # give ores a cycle of between 7 and 39 days
        my $period  = (hex substr md5_hex($ore.$self->id), 2, 1) % 32 + 7;

        my $radians = ($day / ($period / (2 * 3.14159)));
        return int(($max/2) + sin($radians) * ($max/2)) + 1;
    }
};



1;
