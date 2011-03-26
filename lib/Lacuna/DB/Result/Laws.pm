package Lacuna::DB::Result::Laws;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('laws');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    station_id              => { data_type => 'int', size => 11, is_nullable => 0 },
    description             => { data_type => 'text', is_nullable => 1 },
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    scratch                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
    date_enacted            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
); 

__PACKAGE__->typecast_map(type => {
    EnactWrit           => 'Lacuna::DB::Result::Laws::Writ',
});

__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_date_enacted', fields => ['date_enacted']);
}

before delete => sub {
    my $self = shift;
    # notify about repeal
};

after insert => sub {
    my $self = shift;
    # notify about act
};

sub get_status {
    my ($self, $empire) = @_;
    my $out = {
        id          => $self->id,
        name        => $self->name,
        description => $self->description,
        date_enacted   => $self->date_enacted_formatted,
    };
    return $out;
}

sub date_enacted_formatted {
    my ($self) = @_;
    return format_date($self->date_enacted);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
