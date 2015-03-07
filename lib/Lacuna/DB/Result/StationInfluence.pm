package Lacuna::DB::Result::StationInfluence;

use Moose;
use utf8;
extends 'Lacuna::DB::Result';
use POSIX qw(ceil);

__PACKAGE__->table('stationinfluence');
__PACKAGE__->add_columns(
    station_id              => { data_type => 'int', is_nullable => 0 },
    star_id                 => { data_type => 'int', is_nullable => 0 },
    alliance_id             => { data_type => 'int', is_nullable => 0 },
    oldinfluence            => { data_type => 'int', is_nullable => 0, default => 0 },
    oldstart                => { data_type => 'datetime', is_nullable => 0 },
    influence               => { data_type => 'int', is_nullable => 0, default => 0 },
    started_influence       => { data_type => 'datetime', is_nullable => 0 },
);

__PACKAGE__->belongs_to('station',  'Lacuna::DB::Result::Map::Body',    'station_id', { on_delete => 'cascade' });
__PACKAGE__->belongs_to('star',     'Lacuna::DB::Result::Map::Star',    'star_id');
__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Result::Alliance',     'alliance_id');

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    my $schema = $sqlt_table->schema;

    # when we clear rows here, ensure we set the original star for cleanup.
    $schema->add_trigger(
                         name => 'stationinfluence_cleanup',
                         perform_action_when => 'after',
                         database_events     => [qw/delete/],
                         on_table => 'stationinfluence',
                         scope => 'row',
                         action => q[UPDATE star s SET s.needs_recalc = 1 WHERE s.id = OLD.star_id;],
                        );
}

# try to keep this up to date with the one in SQL in ResultSet
sub current_influence {
    my ($self) = @_;

    return 0 if $self->star->in_neutral_area or $self->star->in_starter_zone;

    return $self->influence if $self->oldstart < DateTime->now->subtract(seconds => 24 * 60 * 60);

    my $now = DateTime->now->set_time_zone('GMT');
    my $sec = $now->subtract_datetime_absolute($self->oldstart->set_time_zone('GMT'))->seconds();
    ceil(
         $self->oldinfluence +
         ($self->influence - $self->oldinfluence) * ($sec / (24 * 60 * 60))
        );
}

sub currentinfluence {
    my ($self) = @_;

    # either we got it from the query, or we calculate it ourselves.
    eval { $self->get_column('currentinfluence') } // $self->current_influence;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
