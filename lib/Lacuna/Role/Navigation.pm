package Lacuna::Role::Navigation;

use Moose::Role;

# Find a 'target' based on a number of methods
#
sub find_target {
    my ($self, $target_params) = @_;
    unless (ref $target_params eq 'HASH') {
        confess [-32602, 'The target parameter should be a hash reference. For example { "star_id" : 9999 }.'];
    }
    my $target;
    if (exists $target_params->{star_id}) {
        $target = Lacuna->db->resultset('Map::Star')->find($target_params->{star_id});
    }
    elsif (exists $target_params->{star_name}) {
        $target = Lacuna->db->resultset('Map::Star')->search({ name => $target_params->{star_name} })->first;
    }
    if (exists $target_params->{body_id}) {
        $target = Lacuna->db->resultset('Map::Body')->find($target_params->{body_id});
    }
    elsif (exists $target_params->{body_name}) {
        $target = Lacuna->db->resultset('Map::Body')->search({ name => $target_params->{body_name} })->first;
    }
    elsif (exists $target_params->{x}) {
        $target = Lacuna->db->resultset('Map::Body')->search({ x => $target_params->{x}, y => $target_params->{y} })->first;
        unless (defined $target) {
            $target = Lacuna->db->resultset('Map::Star')->search({ x => $target_params->{x}, y => $target_params->{y} })->first;
        }
    }
    unless (defined $target) {
        confess [ 1002, 'Could not find the target.', $target];
    }
    return $target;
}
1;

