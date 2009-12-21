package Lacuna::DB::Message;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('message');
__PACKAGE__->add_attributes({
    subject         => { isa => 'Str' },
    message         => { isa => 'Str' },
    date_sent       => { isa => 'DateTime' },
    from            => { isa => 'Str' },
    to              => { isa => 'Str' },
    type            => { isa => 'Str' },
    has_read        => { isa => 'Str', default=>0 },
    has_replied     => { isa => 'Str', default=>0 },
    has_archived    => { isa => 'Str', default=>0 },
    has_deleted     => { isa => 'Str', default=>0 },
});

__PACKAGE__->belongs_to('sender', 'Lacuna::DB::Empire', 'from');
__PACKAGE__->belongs_to('receiver', 'Lacuna::DB::Empire', 'to');

no Moose;
__PACKAGE__->meta->make_immutable;
