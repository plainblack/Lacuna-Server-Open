package Lacuna::Role::SpyTraderRpc;

use Moose::Role;
use feature "switch";
use Lacuna::Util qw(randint);

with 'Lacuna::Role::TraderRpc' => {
    -excludes => [ 
        'view_market', 'get_ships', 'get_prisoners', 
        'get_plans', 'get_glyphs', 'get_stored_resources', 
    ],
};

sub view_market {
    my ($self, $session_id, $building_id, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    $page_number ||=1;
    my $all_trades = $building->available_market->search(
        { 'has_spy' => 1 },
        { rows => 25, page => $page_number, join => 'body', order_by => 'ask' }
    );
    my @trades;
    while (my $trade = $all_trades->next) {
        if ($trade->body->empire_id eq '') {
            $trade->delete;
            next;
        }
        push @trades, {
            id                      => $trade->id,
            date_offered            => $trade->date_offered_formatted,
            ask                     => $trade->ask,
            offer                   => $trade->format_description_of_payload,
            body                    => {
                id      => $trade->body_id,
            },
            empire                  => {
                id      => $trade->body->empire->id,
                name    => $trade->body->empire->name,
            },
        };
    }
    return {
        trades      => \@trades,
        trade_count => $all_trades->pager->total_entries,
        page_number => $page_number,
        status      => $self->format_status($empire, $building->body),
    };
}

sub get_spies {
    my ($self, $session_id, $building_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search(
        { on_body_id => $building->body_id, task => { in => ['Counter Espionage','Idle'] } },
        { order_by => 'name' }
    );
    my @out;
    while (my $spy = $spies->next) {
        push @out, {
            id          => $spy->id,
            name        => $spy->name,
            level       => $spy->level,
        };
    }
    return {
        spies                   => \@out,
        cargo_space_used_each   => 350,
        status                  => $self->format_status($empire, $building->body),
    };
}

1;


