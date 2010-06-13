package Lacuna::RPC::Stats;

use Moose;
extends 'Lacuna::RPC';
use Lacuna::Constants qw(SHIP_TYPES);

sub credits {
    return [
            { 'Game Design'         => ['JT Smith','Jamie Vrbsky']},
            { 'Web Client'          => ['John Rozeske']},
            { 'iPhone Client'       => ['Kevin Runde']},
            { 'Game Server'         => ['JT Smith']},
            { 'Art and Icons'       => ['Ryan Knope','JT Smith','Joseph Wain / glyphish.com','Keegan Runde']},
            { 'Geology Consultant'  => ['Geofuels, LLC / geofuelsllc.com']},
            { 'Playtesters'         => ['John Oettinger','Jamie Vrbsky','Mike Kastern','Chris Burr','Eric Patterson','Frank Dillon','Kristi McCombs','Ryan McCombs','Mike Helfman','Tavis Parker','Sarah Bownds']},
            { 'Game Support'        => ['Plain Black Corporation / plainblack.com']},
            ];
}

sub empire_rank {
    my ($self, $session_id, $by, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(empire_size_rank university_level_rank offense_success_rate_rank defense_success_rate_rank dirtiest_rank)]) {
        $by = 'empire_size_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Empire')->search(undef,{order_by => {-desc => $by}});
    unless ($page_number) {
        my $me = $ranks->find($empire->id);
        $page_number = int($me->$by / 25);
        if ( $me->$by % 25 ) {
            $page_number++;
        }
    }
    $ranks = $ranks->search(undef,{rows => 25, page => $page_number});
    my @empires;
    while (my $rank = $ranks->next) {
        push @empires, {
            empire_id                   => $rank->empire_id,
            empire_name                 => $rank->empire_name,
            colony_count                => $rank->colony_count,
            colony_count_delta          => $rank->colony_count_delta,
            population                  => $rank->population,
            population_delta            => $rank->population_delta,
            empire_size                 => $rank->empire_size,
            empire_size_delta           => $rank->empire_size_delta,
            building_count              => $rank->building_count,
            university_level            => $rank->university_level,
            average_building_level      => $rank->average_building_level,
            highest_building_level      => $rank->highest_building_level,
            food_hour                   => $rank->food_hour,
            energy_hour                 => $rank->energy_hour,
            waste_hour                  => $rank->waste_hour,
            ore_hour                    => $rank->ore_hour,
            water_hour                  => $rank->water_hour,
            happiness_hour              => $rank->happiness_hour,
            spy_count                   => $rank->spy_count,
            offense_success_rate        => $rank->offense_success_rate,
            offense_success_rate_delta  => $rank->offense_success_rate_delta,
            defense_success_rate        => $rank->defense_success_rate,
            defense_success_rate_delta  => $rank->defense_success_rate_delta,
            dirtiest                    => $rank->dirtiest,
            dirtiest_delta              => $rank->dirtiest_delta,
        };
    }
    return {
        status  	=> $self->format_status($empire),
        empires 	=> \@empires,
	total_empires	=> $ranks->pager->total_entries
	page_number	=> $page_number,
    };
}

sub find_empire_rank {
    my ($self, $session_id, $by, $empire_name) = @_;
    unless (length($empire_name) >= 3) {
        confess [1009, 'Empire name too short. Your search must be at least 3 characters.'];
    }
    unless ($by ~~ [qw(empire_size_rank university_level_rank offense_success_rate_rank defense_success_rate_rank dirtiest_rank)]) {
        $by = 'empire_size_rank';
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Empire')->search(undef,{order_by => {-desc => $by}, rows=>25});
    my $ranked = $ranks->search({empire_name => { like => '%'.$empire_name.'%'}});
    my @empires;
    while (my $rank = $ranked->next) {
        my $page_number = int($rank->$by / 25);
        if ( $rank->$by % 25 ) {
            $page_number++;
        }
        push @empires, {
            empire_id   => $rank->empire_id,
            empire_name => $rank->empire_name,
            page_number => $rank->page_number,
        };
    }
    return {
        status  => $self->format_status($empire),
        empires => \@empires,
    };
}

sub colony_rank {
    my ($self, $session_id, $by, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(population_rank)]) {
        $by = 'population_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Colony')->search(undef,{order_by => {-desc => $by}, rows=>25, page=>$page_number});
    my @colonies;
    while (my $rank = $ranks->next) {
        push @colonies, {
            empire_id                   => $rank->empire_id,
            empire_name                 => $rank->empire_name,
            planet_id                   => $rank->planet_id,
            planet_name                 => $rank->planet_name,
            population                  => $rank->population,
            population_delta            => $rank->population_delta,
            building_count              => $rank->building_count,
            average_building_level      => $rank->average_building_level,
            highest_building_level      => $rank->highest_building_level,
            food_hour                   => $rank->food_hour,
            energy_hour                 => $rank->energy_hour,
            waste_hour                  => $rank->waste_hour,
            ore_hour                    => $rank->ore_hour,
            water_hour                  => $rank->water_hour,
            happiness_hour              => $rank->happiness_hour,
            spy_count                   => $rank->spy_count,
            offense_success_rate        => $rank->offense_success_rate,
            offense_success_rate_delta  => $rank->offense_success_rate_delta,
            defense_success_rate        => $rank->defense_success_rate,
            defense_success_rate_delta  => $rank->defense_success_rate_delta,
            dirtiest                    => $rank->dirtiest,
            dirtiest_delta              => $rank->dirtiest_delta,
        }
    }
    return {
        status      	=> $self->format_status($empire),
        colonies    	=> \@colonies,
	total_colonies	=> $ranks->pager->total_entries
	page_number	=> $page_number,
    };
}

sub find_colony_rank {
    my ($self, $session_id, $by, $colony_name) = @_;
    unless (length($colony_name) >= 3) {
        confess [1009, 'Colony name too short. Your search must be at least 3 characters.'];
    }
    unless ($by ~~ [qw(population_rank)]) {
        $by = 'population_rank';
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Colony')->search(undef,{order_by => {-desc => $by}, rows=>25});
    my $ranked = $ranks->search({planet_name => { like => '%'.$colony_name.'%'}});
    my @colonies;
    while (my $rank = $ranked->next) {
        my $page_number = int($rank->$by / 25);
        if ( $rank->$by % 25 ) {
            $page_number++;
        }
        push @colonies, {
            page_number => $rank->page_number,
            planet_name => $rank->planet_name,
            planet_id   => $rank->planet_id,
        };
    }
    return {
        status      => $self->format_status($empire),
        colonies    => \@colonies,
    };
}

sub spy_rank {
    my ($self, $session_id, $by, $page_number) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    unless ($by ~~ [qw(level_rank success_rate_rank dirtiest_rank)]) {
        $by = 'level_rank';
    }
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Spies')->search(undef,{order_by => {-desc => $by}, rows=>25, page=>$page_number});
    my @spies;
    while (my $rank = $ranks->next) {
        push @spies, {
            empire_id                   => $rank->empire_id,
            empire_name                 => $rank->empire_name,
            spy_id                      => $rank->spy_id,
            spy_name                    => $rank->spy_name,
            age                         => $rank->level,
            level                       => $rank->level,
            level_delta                 => $rank->level_delta,
            success_rate                => $rank->success_rate,
            success_rate_delta          => $rank->success_rate_delta,
            dirtiest                    => $rank->dirtiest,
            dirtiest_delta              => $rank->dirtiest_delta,
        }
    }
    return {
        status      	=> $self->format_status($empire),
        spies       	=> \@spies,
	total_spies	=> $ranks->pager->total_entries
	page_number	=> $page_number,
    };
}

sub find_spy_rank {
    my ($self, $session_id, $by, $spy_name) = @_;
    unless (length($spy_name) >= 3) {
        confess [1009, 'Spy name too short. Your search must be at least 3 characters.'];
    }
    unless ($by ~~ [qw(level_rank success_rate_rank dirtiest_rank)]) {
        $by = 'level_rank';
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Spies')->search(undef,{order_by => {-desc => $by}, rows=>25});
    my $ranked = $ranks->search({spy_name => { like => '%'.$spy_name.'%'}});
    my @spies;
    while (my $rank = $ranked->next) {
        my $page_number = int($rank->$by / 25);
        if ( $rank->$by % 25 ) {
            $page_number++;
        }
        push @spies, {
            page_number => $rank->page_number,
            spy_name    => $rank->spy_name,
            empire_name => $rank->empire_name,
            spy_id      => $rank->spy_id,
        };
    }
    return {
        status  => $self->format_status($empire),
        spies   => \@spies,
    };
}

    
__PACKAGE__->register_rpc_method_names(qw(find_spy spy_rank find_colony_rank colony_rank find_empire_rank empire_rank credits));

no Moose;
__PACKAGE__->meta->make_immutable;

