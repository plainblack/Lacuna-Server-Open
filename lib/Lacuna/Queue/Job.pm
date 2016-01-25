package Lacuna::Queue::Job;

use Moose;
use YAML;


has 'job' => (
    is          => 'ro',
    isa         => 'Beanstalk::Job',
    required    => 1,
    handles     => [qw(id buried reserved data error stats delete touch peek release bury args tube ttr priority)],
);

sub payload {
    my ($self) = @_;

    my $args    = $self->job->args;

    if (defined $args && $args->{parent_table}) {
        my $class   = $args->{parent_table};
        my $id      = $args->{parent_id};
        print STDERR "class = [$class] id = [$id]\n";
        my $thing   = Lacuna->db->resultset($class)->find($id);
        return $thing;
    }
    return {};
}

__PACKAGE__->meta->make_immutable;
1;

