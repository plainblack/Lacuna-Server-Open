package Lacuna::DB::ResultSet::StationInfluence;

use Moose;
use utf8;
no warnings qw(uninitialized);
#use Lacuna;

extends 'Lacuna::DB::ResultSet';

# try to keep this up to date with the one in perl in Result
sub sql_currentinfluence() {
    'CASE WHEN TIMESTAMPADD(HOUR,24,me.oldstart) < UTC_TIMESTAMP() THEN me.influence ELSE CEIL(me.oldinfluence + (me.influence - me.oldinfluence) * timestampdiff(second,me.oldstart,UTC_TIMESTAMP()) / (24 * 60 * 60)) END'
}

sub with_currentinfluence
{
    my ($self) = @_;
    $self->search(
                {},
                {
                    '+select' => \[ sql_currentinfluence . ' as currentinfluence' ],
                    '+as' => 'currentinfluence'
                });
}

1;

