package Lacuna::DB::Result::Promotion::Bonus50;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Promotion::BonusEssentia';

use constant bonus_percent => 50;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
