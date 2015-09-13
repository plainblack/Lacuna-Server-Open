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
    elsif ($id =~ /^#?(-?\d+)$/) {
        $where{id} = $1;
    }
    # or just the name (hopefully no names are purely numeric)
    else {
        $id =~ s/^\s+//;
        $id =~ s/\s+$//;
        $where{$type} = $id;
    }
    \%where;
}

# Simplifies many scripts, especially one-liners, for testing purposes as well
# as for the bin scripts:
# perl -MLacuna -E '$e=Lacuna->db->empire(1); say $e->id, ": ", $e->name'
# 1: Lacuna Expanse Corp
sub empire {
    shift->X(Empire=>@_)
}

sub empires {
    shift->XX(Empire=>@_);
}

sub body {
    shift->X('Map::Body'=>@_);
}

sub bodies {
    shift->XX('Map::Body'=>@_);
}

sub star {
    shift->X('Map::Star'=>@_);
}

sub stars {
    shift->XX('Map::Star'=>@_);
}

# similarly, a lot of typing can be saved with Lacuna->db->building($id)
sub building {
    my $self = shift;
    $self->resultset('Building')->find(@_);
}


sub buildings {
    my $self = shift;
    $self->resultset('Building')->search(@_);
}

sub ship {
    my $self = shift;
    $self->resultset('Ships')->find(@_);
}

sub ships {
    my $self = shift;
    $self->resultset('Ships')->search(@_);
}

sub X {
    my $self = shift;
    my $type = shift;
    my $where = $self->_where(name => shift);
    $self->resultset($type)->find($where, @_);
}

sub XX {
    my $self = shift;
    my $type = shift;
    my $where = $self->_where(name => shift);
    $self->resultset($type)->search($where, @_);
}

no Moose;
__PACKAGE__->meta->make_immutable;
