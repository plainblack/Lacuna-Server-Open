package Lacuna::DB::Result::MercenaryMarket;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);

__PACKAGE__->table('mercenary_market');
__PACKAGE__->add_columns(
    date_offered            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    body_id                 => { data_type => 'int', is_nullable => 0 },
    ship_id                 => { data_type => 'int', is_nullable => 0 },
    ask                     => { data_type => 'float', size => [11,1], is_nullable => 0},
    cost                    => { data_type => 'float', size => [11,1], is_nullable => 0},
    payload                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
);

__PACKAGE__->belongs_to('body', 'Lacuna::DB::Result::Map::Body', 'body_id');

with 'Lacuna::Role::Container';

sub date_offered_formatted {
    my $self = shift;
    return format_date($self->date_offered);
}

sub format_description_of_payload {
  my ($self) = @_;
  my $payload = $self->payload;
    
  my $item_arr = [];
  if (exists $payload->{mercenary}) {
    my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($payload->{mercenary});
    if (defined $spy) {
      $item_arr = [ sprintf( "Level %d spy named %s (Mercenary Transport) Offense: %d, Defense: %d, Intel: %d, Mayhem: %d, Politics: %d, Theft: %d, Mission Count Offensive: %d Defensive: %d)",
                    $spy->level, $spy->name, $spy->offense, $spy->defense,
                     $spy->intel_xp, $spy->mayhem_xp, $spy->politics_xp, $spy->theft_xp,
                     $spy->offense_mission_count, $spy->defense_mission_count) ];
    }
  }
  return $item_arr;
}

sub withdraw {
    my ($self, $body) = @_;
    $body ||= $self->body;
    $self->unload($body,'withdraw'); # set the withdraw flag because mercs get special treatment
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($self->ship_id);
    $ship->land->update if defined $ship;
    $body->empire->add_essentia({
        amount  => $self->cost, 
        reason  => 'Withdrew Mercenary Trade',
        type    => 'free',
    });
    $body->empire->update;
    $self->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
