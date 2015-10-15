package Lacuna::DB::ResultSet::Promotion;

use Moose;
use utf8;
no warnings qw(uninitialized);

extends 'Lacuna::DB::ResultSet';

sub current_promotions_rs
{
    my $self = shift;

    $self->search(
                  {
                      start_date => [ undef, { '<=' => \q{UTC_TIMESTAMP()} }],
                      end_date   => [ undef, { '>'  => \q{UTC_TIMESTAMP()} }],
                  });
}

sub current_promotions {
    my ($self) = @_;
    $self->current_promotions_rs->all;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
