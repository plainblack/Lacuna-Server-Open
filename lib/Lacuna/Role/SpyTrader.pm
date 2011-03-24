package Lacuna::Role::SpyTrader;

use Moose::Role;
use feature "switch";
use Lacuna::Util qw(randint);

my $have_exception = [1011, 'You cannot offer to trade something you do not have.'];
my $offer_nothing_exception = [1013, 'It appears that you have offered nothing.'];

sub market {
    return Lacuna->db->resultset('Lacuna::DB::Result::Market');
}

sub my_market { 
    my $self = shift;
    return $self->market->search({body_id => $self->body_id, transfer_type => $self->transfer_type, has_spy => 1 });
}

sub available_market {
    my $self = shift;
    return $self->market->search(
        {
            body_id         => {'!=' => $self->body_id},
            transfer_type   => $self->transfer_type,
            has_spy         => 1,
        },
    )
}

sub check_payload {
    my ($self, $item, $transfer_ship) = @_;
    my $body = $self->body;
    
    # validate
    unless (ref $item eq 'HASH') {
        confess 'The item you want to trade needs to be formatted as a hash reference.';
    }

    my $spy_ids = [];
    given($item->{type}) {
        when ('spy') {
            confess [1002, 'You must specify a spy_id if you are pushing a spy.'] unless $item->{spy_id};
            my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($item->{spy_id});
            confess $have_exception unless (defined $spy && $self->body_id eq $spy->on_body_id && $spy->task ~~ ['Counter Espionage','Idle']);
            push @{$spy_ids}, $item->{spy_id};
        }
    }
    confess $offer_nothing_exception unless scalar @{$spy_ids};

    return 350 * scalar @{$spy_ids};
}

sub structure_payload {
    my ($self, $item, $space_used) = @_;
    my $body = $self->body;
    my $payload;
    my %meta = ( offer_cargo_space_needed => $space_used );
    given($item->{type}) {
        when ('spy') {
            my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($item->{spy_id});
            $spy->task('Mercenary Transport');
            $spy->update;
            push @{$payload->{spies}}, $spy->id;
            $meta{has_spy} = 1;
        }
    }
    return ($payload, \%meta);
}

1;
