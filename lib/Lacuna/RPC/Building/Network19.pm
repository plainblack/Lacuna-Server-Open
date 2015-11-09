package Lacuna::RPC::Building::Network19;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use DateTime;

sub app_url {
    return '/network19';
}

sub model_class {
    return 'Lacuna::DB::Result::Building::Network19';
}

sub view_news {
    my ($self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $body = $building->body;
    my @all = ($body->zone, $body->adjacent_zones);
    my @zones;
    foreach (1..(($building->effective_level + 1) / 2)) {
        last if !@all;
        push @zones, shift @all;
    }
    my $news = Lacuna->db->resultset('Lacuna::DB::Result::News')->search(
        {
            zone        => {'in' => \@zones},
        },
        {
            rows       => 100,
            order_by    => { -desc => 'date_posted' },
        }
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
        $feeds{$zone} = Lacuna::DB::Result::News->feed_url($zone);
    }
    return {
        news    => \@stories,
        feeds   => \%feeds,
        status  => $self->format_status($empire, $body),
    };
}

sub restrict_coverage {
    my ($self, $session_id, $building_id, $onoff) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    if ($onoff ne '0' && $onoff ne '1') {
        confess [1009, 'The valid values for onoff are 1 or 0.'];
    }
    my $body = $building->body;
    my $cache = Lacuna->cache;
    unless ($cache->get('restrict_coverage_spam_lock',$body->id)) {
        $cache->set('restrict_coverage_spam_lock',$body->id, 1, 60*60);
        if ($onoff) {
            $body->add_news(100,'Network 19 has just learned that %s intends to restrict our coverage on %s!', $empire->name, $body->name);
        }
        else {
            $body->add_news(90,'In an act of divine wisdom, %s has restored our full coverage on %s!', $empire->name, $body->name);
        }
    }
    $body->restrict_coverage($onoff);
    $body->update;
    return {
        status  => $self->format_status($empire, $body),
    };
}

around 'view' => sub {
    my ($orig, $self, $session_id, $building_id) = @_;
    my $session  = $self->get_session({session_id => $session_id, building_id => $building_id, skip_offline => 1 });
    my $empire   = $session->current_empire;
    my $building = $session->current_building;
    my $out = $orig->($self, $session, $building);
    $out->{restrict_coverage} = $building->body->restrict_coverage;
    return $out;
};


__PACKAGE__->register_rpc_method_names(qw(view_news restrict_coverage));

no Moose;
__PACKAGE__->meta->make_immutable;

