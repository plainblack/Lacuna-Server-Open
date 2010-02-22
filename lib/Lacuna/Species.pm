package Lacuna::Species;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(cname);

has simpledb => (
    is      => 'ro',
    required=> 1,
);

sub is_name_available {
    my ($self, $name) = @_;
    if ( $name eq '' ) {
        return 0;
    }
    else {
        my $count = $self->simpledb->domain('species')->count({cname=>cname($name)});
        warn $name . " = ". $count;
        return ($count) ? 0 : 1;
    }
}

sub create {
    my ($self, %me) = @_;
    $me{name} =~ s{^\s+(.*)\s+$}{$1}xms; # remove extra white space
    if ( $me{name} eq '' || length($me{name}) > 30 || $me{name} =~ m/[@&<>;]/ || !$self->is_name_available($me{name})) {
        confess [1000,'Species name not available.', 'name'];
    }
    if ($me{description} =~ m/[@&<>;]/) {
        confess [1005, 'Description contains invalid characters.','description'];
    }
    my $points = scalar(@{$me{habitable_orbits}});
    if ($points > 7) {
        confess [1007, 'Too many orbits.', 'habitable_orbits'];
    }
    elsif ($points < 1) {
        confess [1008, 'Too few orbits.', 'habitable_orbits'];
    }
    my $previous;
    foreach my $orbit (sort @{$me{habitable_orbits}}) {
        $orbit += 0; #ensure it's a number
        if ($orbit < 1 || $orbit > 7) {
            confess [1009, 'Not a valid orbit.', 'habitable_orbits'];
        }
        if ($previous) {
            if ($orbit != $previous+1) {
                confess [1009, 'Orbits must be consecutive.', 'habitable_orbits'];
            }
        }
        $previous = $orbit;
    }
    foreach my $attr (qw(construction_affinity deception_affinity research_affinity management_affinity farming_affinity mining_affinity science_affinity environmental_affinity political_affinity trade_affinity growth_affinity)) {
        $me{$attr} += 0; # ensure it's a number
        if ($me{$attr} < 1) {
            confess [1008, 'Too little to an affinity.', $attr];
        }
        elsif ($me{$attr} > 7) {
            confess [1007, 'Too much to an affinity.', $attr];
        }
        $points += $me{$attr};
    }
    if ($points > 45) {
        confess [1007, 'Overspend.'];
    }
    elsif ($points < 45) {
        confess [1008, 'Underspend.'];
    }
    my $species = $self->simpledb->domain('species')->insert({ # specify each attribute to avaid data injection
        name                    => $me{name},
        description             => $me{description},
        habitable_orbits        => $me{habitable_orbits},
        construction_affinity   => $me{construction_affinity},
        deception_affinity      => $me{deception_affinity},
        research_affinity       => $me{research_affinity},
        management_affinity     => $me{management_affinity},
        farming_affinity        => $me{farming_affinity},
        mining_affinity         => $me{mining_affinity},
        science_affinity        => $me{science_affinity},
        environmental_affinity  => $me{environmental_affinity},
        political_affinity      => $me{political_affinity},
        trade_affinity          => $me{trade_affinity},
        growth_affinity         => $me{growth_affinity},
    });
    return $species->id;
}

__PACKAGE__->register_rpc_method_names(qw(is_name_available create));


no Moose;
__PACKAGE__->meta->make_immutable;

