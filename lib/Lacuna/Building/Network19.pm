package Lacuna::Building::Network19;

use Moose;
extends 'Lacuna::Building';
use DateTime;

sub app_url {
    return '/network19';
}

sub model_class {
    return 'Lacuna::DB::Building::Network19';
}

sub view_news {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $body = $building->body;
    my @all = ($body->zone, $body->adjacent_zones);
    my @zones;
    foreach (1..(($building->level + 1) / 2)) {
        push @zones, shift @all;
    }
    my $news = $self->simpledb->domain('news')->search(
        where   => {
            zone        => ['in',@zones],
            date_posted => [ '>=', DateTime->now->subtract(hours=>24)],
        },
        limit       => 100,
        order_by    => ['date_posted'],
    );
    my @stories;
    while (my $story = $news->next) {
        push @stories, {
            headline    => $story->headline,
            date        => $story->date_posted_formatted,
        };
    }
    my %feeds;
    foreach my $zone (@zones) {
        $feeds{$zone} = Lacuna::DB::News->feed_url($zone);
    }
    return {
        news    => \@stories,
        feeds   => \%feeds,
        status  => $empire->get_status,
    };
}

sub restrict_coverage {
    my ($self, $session_id, $building_id, $onoff) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    if ($onoff ne '0' && $onoff ne '1') {
        confess [1009, 'The valid values for onoff are 1 or 0.'];
    }
    my $body = $building->body;
    if ($onoff == 1 && !$building->restrict_coverage && $building->restrict_coverage_delta_in_seconds > 60*60) {
        $body->add_news(100,'Network 19 has just learned that %s intends to restrict our coverage on %s!', $empire->name, $body->name);
    }
    elsif ($onoff == 0 && $building->restrict_coverage && $building->restrict_coverage_delta_in_seconds > 60*60) {
        $body->add_news(90,'In an act of devine wisdom, %s has restored our full coverage on %s!', $empire->name, $body->name);
    }
    $building->restrict_coverage($onoff);
    $building->restrict_coverage_delta(DateTime->now);
    $building->put;
    return {
        status  => $empire->get_status,
    };
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $empire->get_building($self->model_class, $building_id);
    my $out = $orig->($self, $empire, $building);
    $out->{restrict_coverage} = $building->restrict_coverage;
    return $out;
};


__PACKAGE__->register_rpc_method_names(qw(view_news restrict_coverage));

no Moose;
__PACKAGE__->meta->make_immutable;

