package Lacuna::DB::Result::Building::Food;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Resources Food));
};

my %levels = (
              5  => 'a quiet',
              10 => 'an extravagant',
              15 => 'a lavish',
              20 => 'a magnificent',
              25 => 'a historic',
              30 => 'a magical',
             );

sub finish_upgrade_news
{
    my ($self, $new_level, $empire) = @_;
    if (my $msg = $levels{$new_level}) {
        $self->body->add_news($new_level*4,"The hungry citizens of %s celebrated with a %s thanksgiving feast, thanks to its newly augmented %s.", $empire->name, $msg, lc $self->name);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
