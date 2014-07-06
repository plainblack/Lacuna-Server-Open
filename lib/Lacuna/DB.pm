package Lacuna::DB;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

sub sqlt_deploy_hook {
    my ($self, $sqlt_schema) = @_;
    $sqlt_schema->drop_table('noexist_basetable');
    $sqlt_schema->drop_table('noexist_log');
    $sqlt_schema->drop_table('noexist_map');
}

# Simplifies many scripts, especially one-liners, for testing purposes as well
# as for the bin scripts:
# perl -MLacuna -E '$e=Lacuna->db->empire(1); say $e->id, ": ", $e->name'
# 1: Lacuna Expanse Corp
sub empire {
    my ($self, $id) = @_;
    my $empires = $self->resultset('Lacuna::DB::Result::Empire');
    my %where;

    # set the where hash
    if (ref $id && ref $id eq 'HASH')
    {
        %where = %$id;
    }
    # or a C<like> for name
    elsif ($id =~ /[%_]/)
    {
        $where{name} = { like => $id };
    }
    # or just the name (hopefully no names are purely numeric)
    elsif ($id =~ /\D/)
    {
        $where{name} = $id;
    }
    # or the numeric ID (probably most useful for testing)
    else
    {
        $where{id} = $id;
    }

    $empires->find(\%where);
}

# similarly, a lot of typing can be saved with Lacuna->db->building($id)
sub building {
    my ($self, $building_id) = @_;
    my $building = $self->resultset('Lacuna::DB::Result::Building')->find($building_id);
}

no Moose;
__PACKAGE__->meta->make_immutable;
