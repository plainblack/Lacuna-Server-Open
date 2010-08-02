package Lacuna::RPC::Species;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';



sub is_name_available {
    my ($self, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Species name not available.', 'name'])
        ->length_lt(31)
        ->length_gt(2)
        ->not_empty
        ->no_restricted_chars
        ->no_profanity
        ->ok( !Lacuna->db->resultset('Lacuna::DB::Result::Species')->search({name=>$name})->count );
    return 1;
}

sub create {
    my ($self, $empire_id, $me) = @_;
    Lacuna::Verify->new(content=>\$me->{description}, throws=>[1005,'Description invalid.', 'description'])
        ->length_lt(1025)
        ->no_restricted_chars
        ->no_profanity;  
    
    # deal with point allocation
    my $points = scalar(@{$me->{habitable_orbits}});
    if ($points > 7) {
        confess [1007, 'Too many orbits.', 'habitable_orbits'];
    }
    elsif ($points < 1) {
        confess [1008, 'Too few orbits.', 'habitable_orbits'];
    }
    my $previous;
    foreach my $orbit (sort @{$me->{habitable_orbits}}) {
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
    foreach my $attr (qw(manufacturing_affinity deception_affinity research_affinity management_affinity farming_affinity mining_affinity science_affinity environmental_affinity political_affinity trade_affinity growth_affinity)) {
        $me->{$attr} += 0; # ensure it's a number
        if ($me->{$attr} < 1) {
            confess [1008, 'Too little to an affinity.', $attr];
        }
        elsif ($me->{$attr} > 7) {
            confess [1007, 'Too much to an affinity.', $attr];
        }
        $points += $me->{$attr};
    }
    if ($points > 45) {
        confess [1007, 'Overspend.'];
    }
    elsif ($points < 45) {
        confess [1008, 'Underspend.'];
    }

    # make sure it's a valid empire
    my $empire = $self->validate_empire($empire_id);
    
    # make sure the name is unique
    $me->{name} =~ s{^\s+(.*)\s+$}{$1}xms; # remove extra white space
    $self->is_name_available($me->{name});

    my $species = Lacuna->db->resultset('Lacuna::DB::Result::Species')->new({ # specify each attribute to avaid data injection
        empire_id               => $empire_id,
        name                    => $me->{name},
        description             => $me->{description},
        min_orbit               => $me->{habitable_orbits}->[0],
        max_orbit               => $me->{habitable_orbits}->[-1],
        manufacturing_affinity  => $me->{manufacturing_affinity},
        deception_affinity      => $me->{deception_affinity},
        research_affinity       => $me->{research_affinity},
        management_affinity     => $me->{management_affinity},
        farming_affinity        => $me->{farming_affinity},
        mining_affinity         => $me->{mining_affinity},
        science_affinity        => $me->{science_affinity},
        environmental_affinity  => $me->{environmental_affinity},
        political_affinity      => $me->{political_affinity},
        trade_affinity          => $me->{trade_affinity},
        growth_affinity         => $me->{growth_affinity},
    })->insert;
    
    $empire->species_id($species->id);
    $empire->update;
    
    return $species->id;
}

sub view_stats {
    my ($self, $session_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $species = $empire->species;
    my @orbits;
    push(@orbits, $_) foreach ($species->min_orbit .. $species->max_orbit);
    return {
        species => {
            name                    => $species->name,
            description             => $species->description,
            habitable_orbits        => \@orbits,
            manufacturing_affinity  => $species->manufacturing_affinity,
            deception_affinity      => $species->deception_affinity,
            research_affinity       => $species->research_affinity,
            management_affinity     => $species->management_affinity,
            farming_affinity        => $species->farming_affinity,
            mining_affinity         => $species->mining_affinity,
            science_affinity        => $species->science_affinity,
            environmental_affinity  => $species->environmental_affinity,
            political_affinity      => $species->political_affinity,
            trade_affinity          => $species->trade_affinity,
            growth_affinity         => $species->growth_affinity,
        },
        status  => $self->format_status($empire),
    };
}

sub validate_empire {
    my ($self, $empire_id) = @_;
    
    # make sure it's a valid empire
    unless ($empire_id ne '') {
        confess [1002, "You must specify an empire id."];
    }
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $empire) {
        confess [1002, "Not a valid empire.",'empire_id'];
    }

    # deal with an empire in motion
    if ($empire->stage ne 'new') {
        confess [1010, "You can't establish a new species for an empire that's already founded.",'empire_id'];
    }

    # deal with previously created species
    Lacuna->db->resultset('Lacuna::DB::Result::Species')->search({empire_id=>$empire->id})->delete_all;
    
    return $empire;
}

sub set_human {
    my ($self, $empire_id) = @_;
    my $empire = $self->validate_empire($empire_id);
    $empire->species(2);
    $empire->update;
    return 1;    
}

__PACKAGE__->register_rpc_method_names(qw(is_name_available create set_human view_stats));


no Moose;
__PACKAGE__->meta->make_immutable;

