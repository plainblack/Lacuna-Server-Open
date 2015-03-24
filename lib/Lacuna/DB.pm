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

sub _where
{
    my ($self, $type, $id) = @_;

    my %where;
    # set the where hash
    if (ref $id && ref $id eq 'HASH') {
        %where = %$id;
    }
    # or a C<like> for name
    elsif ($id =~ /[%_]/) {
        $where{$type} = { like => $id };
    }
    # or the numeric ID (probably most useful for testing)
    elsif ($id =~ /^#?-?\d+$/) {
        $where{id} = $id;
    }
    # or just the name (hopefully no names are purely numeric)
    else {
        $where{$type} = $id;
    }
    \%where;
}

# Simplifies many scripts, especially one-liners, for testing purposes as well
# as for the bin scripts:
# perl -MLacuna -E '$e=Lacuna->db->empire(1); say $e->id, ": ", $e->name'
# 1: Lacuna Expanse Corp
sub empire {
    my ($self, $id) = @_;

    my $empires = $self->resultset('Empire');
    my $where = $self->_where(name => $id);

    $empires->find($where);
}

sub empires {
    my ($self, $id) = @_;

    my $empires = $self->resultset('Empire');
    my $where = $self->_where(name => $id);

    $empires->search($where);
}


sub body {
    my ($self, $id) = @_;

    my $bodies = $self->resultset('Map::Body');
    my $where = $self->_where(name => $id);

    $bodies->find($where);
}

sub bodies {
    my ($self, $id) = @_;

    my $bodies = $self->resultset('Map::Body');
    my $where = $self->_where(name => $id);

    $bodies->search($where);
}

sub star {
    my ($self, $id) = @_;

    my $bodies = $self->resultset('Map::Star');
    my $where = $self->_where(name => $id);

    $bodies->find($where);
}

sub stars {
    my ($self, $id) = @_;

    my $bodies = $self->resultset('Map::Star');
    my $where = $self->_where(name => $id);

    $bodies->search($where);
}

# similarly, a lot of typing can be saved with Lacuna->db->building($id)
sub building {
    my ($self, $building_id) = @_;
    $self->resultset('Building')->find($building_id);
}


sub buildings {
    my ($self, $id) = @_;
    my $where = $self->_where(name => $id);
    $self->resultset('Building')->search($where);
}

sub ship {
    my ($self, $building_id) = @_;
    $self->resultset('Ships')->find($building_id);
}


sub ships {
    my ($self, $id) = @_;
    my $where = $self->_where(name => $id);
    $self->resultset('Ships')->search($where);
}

sub X {
    my ($self, $type, $id) = @_;
    my $where = $self->_where(name => $id);
    $self->resultset($type)->find($where);
}

sub XX {
    my ($self, $type, $id) = @_;
    my $where = $self->_where(name => $id);
    $self->resultset($type)->search($where);
}

no Moose;
__PACKAGE__->meta->make_immutable;
