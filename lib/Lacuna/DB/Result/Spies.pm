package Lacuna::DB::Result::Spies;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date randint random_element);
use DateTime;
use feature "switch";
use Lacuna::Constants qw(ORE_TYPES FOOD_TYPES SHIP_TYPES);

__PACKAGE__->table('spies');
__PACKAGE__->add_columns(
    empire_id               => { data_type => 'int', is_nullable => 0 },
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0, default_value => 'Agent Null' },
    from_body_id            => { data_type => 'int', is_nullable => 0 },
    on_body_id              => { data_type => 'int', is_nullable => 0 },
    task                    => { data_type => 'varchar', size => 30, is_nullable => 0, default_value => 'Idle' },
    started_assignment      => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    available_on            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    offense                 => { data_type => 'int', default_value => 1 },
    defense                 => { data_type => 'int', default_value => 1 },
    date_created            => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    offense_mission_count   => { data_type => 'int', default_value => 0 },
    defense_mission_count   => { data_type => 'int', default_value => 0 },
    offense_mission_successes => { data_type => 'int', default_value => 0 },
    defense_mission_successes => { data_type => 'int', default_value => 0 },
    times_captured          => { data_type => 'int', default_value => 0 },
    times_turned            => { data_type => 'int', default_value => 0 },
    seeds_planted           => { data_type => 'int', default_value => 0 },
    spies_killed            => { data_type => 'int', default_value => 0 },
    spies_captured          => { data_type => 'int', default_value => 0 },
    spies_turned            => { data_type => 'int', default_value => 0 },
    things_destroyed        => { data_type => 'int', default_value => 0 },
    things_stolen           => { data_type => 'int', default_value => 0 },
    intel_xp                => { data_type => 'int', default_value => 0 },
    mayhem_xp               => { data_type => 'int', default_value => 0 },
    politics_xp             => { data_type => 'int', default_value => 0 },
    theft_xp                => { data_type => 'int', default_value => 0 },
    level                   => { data_type => 'tinyint', default_value => 0 },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');
__PACKAGE__->belongs_to('from_body', 'Lacuna::DB::Result::Map::Body', 'from_body_id');
__PACKAGE__->belongs_to('on_body', 'Lacuna::DB::Result::Map::Body', 'on_body_id');

sub xp {
    my $self = shift;
    return $self->offense + $self->defense + $self->intel_xp + $self->mayhem_xp + $self->politics_xp + $self->theft_xp;
}

sub calculate_level {
    my $self = shift;
    return sprintf('%.0f', ($self->xp) / 200);
}

sub update_level {
    my $self = shift;
    $self->level( $self->calculate_level );
    return $self;
}

sub get_status {
    my $self = shift;
    return {
        is_available        => $self->is_available, # first so that it can update task, etc if needed
        id                  => $self->id,
        name                => $self->name,
        level               => $self->level,
        offense_rating      => $self->offense,
        defense_rating      => $self->defense,
        intel               => $self->intel_xp,
        mayhem              => $self->mayhem_xp,
        politics            => $self->politics_xp,
        theft               => $self->theft_xp,
        assignment          => $self->task,
        possible_assignments=> $self->get_possible_assignments,
        assigned_to         => {
            body_id => $self->on_body_id,
            name    => $self->on_body->name,
        },
        available_on        => $self->format_available_on,
        started_assignment  => $self->format_started_assignment,
        seconds_remaining   => $self->seconds_remaining_on_assignment,
    };
}

# ASSIGNMENT STUFF

sub recovery_time {
    my ($self, $base) = @_;
    my $seconds = $base - $self->xp;
    return ($seconds > 5 * 60) ? $seconds : 5 * 60;
}

sub offensive_assignments {
    my $self = shift;
    my @assignments = (
        {
            task        =>'Gather Resource Intelligence',
            recovery    => $self->recovery_time(60 * 60 * 1),
            skill       => 'intel',
        },
        {
            task        =>'Gather Empire Intelligence',
            recovery    => $self->recovery_time(60 * 60 * 1),
            skill       => 'intel',
        },
        {
            task        =>'Gather Operative Intelligence',
            recovery    => $self->recovery_time(60 * 60 * 1),
            skill       => 'intel',
        },
        {
            task        =>'Hack Network 19',
            recovery    => $self->recovery_time(60 * 60 * 2),
            skill       => 'politics',
        },
        {
            task        =>'Sabotage Probes',
            recovery    => $self->recovery_time(60 * 60 * 4),
            skill       => 'mayhem',
        },
        {
            task        =>'Rescue Comrades',
            recovery    => $self->recovery_time(60 * 60 * 6),
            skill       => 'intel',
        },
        {
            task        =>'Sabotage Resources',
            recovery    => $self->recovery_time(60 * 60 * 8),
            skill       => 'mayhem',
        },
        {
            task        =>'Appropriate Resources',
            recovery    => $self->recovery_time(60 * 60 * 8),
            skill       => 'theft',
        },
        {
            task        =>'Sabotage Infrastructure',
            recovery    => $self->recovery_time(60 * 60 * 8),
            skill       => 'mayhem',
        },
        {
            task        =>'Assassinate Operatives',
            recovery    => $self->recovery_time(60 * 60 * 8),
            skill       => 'mayhem',
        },
        {
            task        =>'Incite Mutiny',
            recovery    => $self->recovery_time(60 * 60 * 12),
            skill       => 'politics',
        },
        {
            task        =>'Abduct Operatives',
            recovery    => $self->recovery_time(60 * 60 * 12),
            skill       => 'theft',
        },
        {
            task        =>'Incite Rebellion',
            recovery    => $self->recovery_time(60 * 60 * 18),
            skill       => 'politics',
        },
    );
    if (eval{$self->can_conduct_advanced_missions}) {
        push @assignments, (
            {
                task        =>'Appropriate Technology',
                recovery    => $self->recovery_time(60 * 60 * 18),
                skill       => 'theft',
            },
            {
                task        =>'Incite Insurrection',
                recovery    => $self->recovery_time(60 * 60 * 24),
                skill       => 'politics',
            },
        );    
    }
    return @assignments;
}

sub defensive_assignments {
    my $self = shift;
    return (
        {
            task        => 'Counter Espionage',
            recovery    => 0,
            skill       => '*',
        },
        {
            task        => 'Security Sweep',
            recovery    => $self->recovery_time(60 * 60 * 6),
            skill       => 'intel',
        },
    );
}

sub neutral_assignments {
    my $self = shift;
    return (
        {
            task        => 'Idle',
            recovery    => 0,
            skill       => 'none',
        },
    );
}

sub get_possible_assignments {
    my $self = shift;
    
    # can't be assigned anything right now
    unless ($self->task ~~ ['Counter Espionage','Idle']) {
        return [{ task => $self->task, recovery => $self->seconds_remaining_on_assignment }];
    }
    
    my @assignments = $self->neutral_assignments;
    
    # at home you can defend
    if ($self->on_body->empire_id == $self->from_body->empire_id) {
        push @assignments, $self->defensive_assignments;
    }
    
    # at allies you can defend and attack
    elsif ($self->on_body->empire->alliance_id && $self->on_body->empire->alliance_id == $self->from_body->empire->alliance_id) {
        push @assignments, $self->defensive_assignments, $self->offensive_assignments;
    }
    
    # at hostiles you can attack
    else {
        push @assignments, $self->offensive_assignments;
    }
    return \@assignments;
}

sub format_available_on {
    my ($self) = @_;
    return format_date($self->available_on);
}

sub format_started_assignment {
    my ($self) = @_;
    return format_date($self->started_assignment);
}

sub seconds_remaining_on_assignment {
    my $self = shift;
    my $now = time;
    if ($self->available_on->epoch > $now) {
        return $self->available_on->epoch - $now;
    }
    else {
        return 0;
    }
}

sub is_available {
    my ($self) = @_;
    my $task = $self->task;
    if ($task ~~ ['Idle','Counter Espionage']) {
        return 1;
    }
    elsif (time > $self->available_on->epoch) {
        if ($task eq 'Debriefing') {
            $self->task('Counter Espionage');
            $self->update;
            return 1;
        }
        elsif ($task eq 'Unconscious') {
            $self->task('Idle');
            $self->update;
            $self->empire->send_predefined_message(
                tags        => ['Intelligence'],
                filename    => 'must_have_been_knocked_out.txt',
                params      => [$self->format_from],
            );
            return 1;
        }
        elsif ($task eq 'Waiting On Trade') {
            my $trade = Lacuna->db->resultset('Lacuna::DB::Result::Trades')->search({
               offer_object_id  => $self->id,
               offer_type       => 'prisoner',
            });
            $trade->withdraw if defined $trade;
        }
        elsif ($task eq 'Travelling') {
            my $infiltration_time = $self->available_on->clone->add(hours => 1);
            if ($infiltration_time->epoch > time && $self->empire_id ne $self->on_body->empire_id) {
                $self->task('Infiltrating');
                $self->started_assignment(DateTime->now);
                $self->available_on($infiltration_time);
                $self->update;
                return 0;
            }
        }
        $self->task('Idle');
        $self->update;
        return 1;
    }
    return 0;
}

use constant assignments => (
    'Idle',
    'Counter Espionage',
    'Security Sweep',
    'Gather Resource Intelligence',
    'Gather Empire Intelligence',
    'Gather Operative Intelligence',
    'Hack Network 19',
    'Sabotage Probes',
    'Rescue Comrades',
    'Sabotage Resources',
    'Appropriate Resources',
    'Sabotage Infrastructure',
    'Assassinate Operatives',
    'Incite Mutiny',
    'Abduct Operatives',
    'Incite Rebellion',
    'Appropriate Technology',
    'Incite Insurrection',
);

sub assign {
    my ($self, $assignment) = @_;

    # determine mission
    my $mission;
    foreach my $possible (@{$self->get_possible_assignments}) {
        if ($possible->{task} eq $self->task) {
            $mission = $possible;
        }
    }
    if (!$mission->{skill} || !$self->is_available) {
        return { result =>'Failure', reason => random_element(['I am busy just now.','It will have to wait.','Can\'t right now.','Maybe later.']) };
    }
    
    # set assignment
    $self->task($assignment);
    $self->started_assignment(DateTime->now);
    $self->available_on(DateTime->now->add(seconds => $mission->{recovery}));
    
    # run mission
    if ($assignment ~~ ['Idle','Counter Espionage']) {
        $self->update;
        return {result => 'Accepted', reason => random_element(['I am ready to serve.','I\'m on it.','Consider it done.','Will do.','Yes.'])};
    }
    if ($assignment eq 'Security Sweep') {
        return $self->run_security_sweep($mission);
    }
    else {
        return $self->run_mission($mission);
    }
}

sub burn {
    my $self = shift;
    my $old_empire = $self->empire;
    my $body = $self->from_body;
    if ($body->add_news(10, 'This reporter has just learned that %s has a policy of burning its own loyal spies.', $old_empire->name)) {
        $body->spend_happiness(5000);
        $body->update;
    }
    if ($self->on_body->empire_id != $old_empire->id) {
        if (randint(1,100) < $self->level) {
            my $new_empire = $self->on_body->empire;
            $old_empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'you_cant_burn_me.txt',
                params      => [$new_empire->id, $new_empire->name, $self->name],
            );
            $new_empire->send_predefined_message(
                tags        => ['Alert'],
                filename    => 'id_like_to_join_you.txt',
                params      => [$old_empire->id, $old_empire->name, $self->name, $self->on_body->id, $self->on_body->name],
            );
            $self->from_body_id($self->on_body_id);
            $self->empire_id($new_empire->id);
            $self->task('Idle');
            $self->available_on(DateTime->now);
            $self->times_turned( $self->times_turned + 1 );
            $self->update;
        }
        else {
            $self->delete;
        }
    }
    else {
        $self->delete;
    }
}

# MISSION STUFF

my %outcomes = (
    'Gather Resource Intelligence'  => 'gather_resource_intel',
    'Gather Empire Intelligence'    => 'gather_empire_intel',
    'Gather Operative Intelligence' => 'gather_operative_intel',
    'Hack Network 19'               => 'hack_network_19',
    'Appropriate Technology'        => 'appropriate_tech',
    'Sabotage Probes'               => 'sabotage_probes',
    'Rescue Comrades'               => 'rescue_comrades',
    'Sabotage Resources'            => 'sabotage_resources',
    'Appropriate Resources'         => 'appropriate_resources',
    'Assassinate Operatives'        => 'assassinate_operatives',
    'Sabotage Infrastructure'       => 'sabotage_infrastructure',
    'Incite Mutiny'                 => 'incite_mutany',
    'Abduct Operatives'             => 'abduct_operatives',
    'Incite Rebellion'              => 'incite_rebellion',    
    'Incite Insurrection'           => 'incite_insurrection',    
);

my @offense_tasks = keys %outcomes;

sub run_mission {
    my ($self, $mission) = @_;

    # can't run missions on your own planets
    if ($self->empire_id == $self->on_body->empire_id) {
        return { result => 'Failure', reason => random_element(['I will not run offensive missions against my own people.','No!','Do you really want me to attack our own citizens?','This would not make Mom proud.','I have moral objections.']) };
    }

    # calculate success, failure, or bounce
    my $mission_skill = $mission->{skill}.'_xp';
    my $power = $self->offense + $self->$mission_skill;
    my $toughness = 0;
    my $defender = $self->get_defender;
    if (defined $defender) {
        $toughness = $defender->defense + $defender->$mission_skill;
    }
    my $breakthru = (($power - $toughness) / 100) * (($toughness == 0) ? 6 : 1);
    
    # handle outcomes and xp
    my $out;
    if ($breakthru < 0) {
        $defender->$mission_skill( $defender->$mission_skill + 10 );
        $defender->update_level;
        $defender->defense_mission_successes( $defender->defense_mission_successes + 1 );
        $self->$mission_skill( $self->$mission_skill + 6 );
        $self->update_level;
        my $outcome = $outcomes{$self->task} . '_loss';
        my $message_id = $self->$outcome($defender);
        $out = { result => 'Failure', message_id => $message_id, reason => random_element(['Intel shmintel.','Code red!','It has just gone pear shaped.','I\'m pinned down and under fire.','I\'ll do better next time, if there is a next time.','The fit has just hit the shan.','I want my mommy!','No time to talk! Gotta run.','Why do they always have dogs?','Did you even plan this mission?']) };
    }
    elsif (randint(1,100) > $breakthru) {
        if (defined $defender) {
            $defender->task('Debriefing');
            $defender->started_assignment(DateTime->now);
            $defender->available_on(DateTime->now->add(seconds => int($mission->{recovery} / 2)));
            $defender->$mission_skill( $defender->$mission_skill + 2 );
            $defender->update_level;
        }
        $self->$mission_skill( $self->$mission_skill + 2 );
        $self->update_level;
        $out = { result => 'Bounce', reason => random_element(['I could not find a way to complete my mission, but I will give it another try.','Missed it by that much.','Better luck next time.','I was stopped by an enemy spy.','Let\'s try that again later.','Hrmmm.','Could not get it done this time.','I\'m being shadowed.','Gotta ditch my tail.','Lost the target.','They have some good security.','Maybe next time.']) };
    }
    else {
        if (defined $defender) {
            $defender->task('Debriefing');
            $defender->started_assignment(DateTime->now);
            $defender->available_on(DateTime->now->add(seconds => int($mission->{recovery} / 2)));
            $defender->$mission_skill( $defender->$mission_skill + 6 );
            $defender->update_level;
        }
        $self->offense_mission_successes( $self->offense_mission_successes + 1 );
        $self->$mission_skill( $self->$mission_skill + 10 );
        $self->update_level;
        my $outcome = $outcomes{$self->task};
        my $message_id = $self->$outcome($defender);
        $out = { result => 'Success', message_id => $message_id, reason => random_element(['I did it!','Mom would have been proud.','Done.','It is done.','That is why you pay me the big bucks.','I did it, but that one was close.','Mission accomplished.', 'Wahoo!', 'All good.','We\'re good.', 'I\'ll be ready for a new mission soon.', 'On my way back now.', 'I will be ready for another mission soon.']) };
    }
    $self->update;
    $defender->update if defined $defender;
    return $out;
}

sub run_security_sweep {
    my $self = shift;

    # calculate success, failure, or bounce
    my $mission_skill = 'intel_xp';
    my $power = $self->defense + $self->$mission_skill;
    my $toughness = 0;
    my $attacker = $self->get_attacker;
    if (defined $attacker) {
        $toughness = $attacker->offense + $attacker->$mission_skill;
    }
    my $breakthru = (($power - $toughness) / 100) * (($toughness == 0) ? 6 : 1);
    
    # handle outcomes and xp
    my $out;
    if ($breakthru < 0) {
        if (defined $attacker) {
            $attacker->$mission_skill( $attacker->$mission_skill + 10 );
            $attacker->update_level;
            $attacker->defense_mission_successes( $attacker->defense_mission_successes + 1 );
        }
        $self->$mission_skill( $self->$mission_skill + 6 );
        $self->update_level;
        my $outcome = $outcomes{$self->task} . '_loss';
        my $message_id = $self->$outcome($attacker);
        $out = { result => 'Failure', message_id => $message_id, reason => random_element(['Didn\'t find anyone.','It has just gone pear shaped.','I\'m pinned down and under fire.','I\'ll do better next time, if there is a next time.','The fit has just hit the shan.','I want my mommy!']) };
    }
    elsif (randint(1,100) > $breakthru) {
        if (defined $attacker) {
            $attacker->$mission_skill( $attacker->$mission_skill + 2 );
        }
        $self->$mission_skill( $self->$mission_skill + 2 );
        $out = { result => 'Bounce', reason => random_element(['Better luck next time.','Let\'s try that again later.','Hrmmm.','Could not get it done this time.','Lost the target.','They\'re good. Real good.','Maybe next time.']) };
    }
    else {
        my $message_id;
        if (defined $attacker) {
            $message_id = $self->detain_a_spy($attacker)->id;
            $attacker->$mission_skill( $self->$mission_skill + 6);
            $attacker->update_level;
        }
        else {
            $message_id = $self->no_target->id;
        }
        $self->offense_mission_successes( $self->offense_mission_successes + 1 );
        $self->$mission_skill( $self->$mission_skill + 10 );
        $self->update_level;
        $out = { result => 'Success', message_id => $message_id, reason => random_element(['Mom would have been proud.','Done.','That is why you pay me the big bucks.']) };
    }
    $self->update;
    $attacker->update if defined $attacker;
    return $out;
}

sub get_defender {
    my $self = shift;
    my $defender = Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search(
            { on_body_id  => $self->on_body_id, task => 'Counter Espionage' },
            { rows => 1 }
        )
        ->single;
    $defender->on_body($self->on_body) if defined $defender;
    return $defender;
}

sub get_attacker {
    my $self = shift;
    my @tasks = qw('Infiltrating');
    foreach my $task ($self->offensive_assignments) {
        push @tasks, $task->{task};
    }
    my $attacker = Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search(
            { on_body_id  => $self->on_body_id, task => {  in => \@tasks }},
            { rows => 1 }
        )
        ->single;
    $attacker->on_body($self->on_body) if defined $attacker;
    return $attacker;
}

sub get_random_prisoner {
    my $self = shift;
    my @prisoners = Lacuna
        ->db
        ->resultset('Lacuna::DB::Result::Spies')
        ->search(
            { on_body_id  => $self->on_body_id, task => 'Captured' },
        )
        ->all;
    my $prisoner = random_element(\@prisoners);
    $prisoner->on_body($self->on_body) if defined $prisoner;
    return $prisoner;
}


# SPECIAL EVENTS

sub get_spooked {
    my ($self) = @_;
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'narrow_escape.txt',
        params      => [$self->on_body->empire->name, $self->name, $self->from_body->id, $self->from_body->name],
    );
}

sub thwart_a_spy {
    my ($self, $suspect) = @_;
    $self->on_body->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_missed_a_spy.txt',
        params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $self->format_from],
        from        => $self->empire,
    );
    return $suspect->get_spooked;
}

sub escape {
    my ($self) = shift;
    $self->available_on(DateTime->now);
    $self->task('Idle');
    $self->update;
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'you_cant_hold_me.txt',
        params      => [$self->name],
    );
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'i_have_escaped.txt',
        params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
    );
}

sub go_to_jail {
    my $self = shift;
    $self->available_on(DateTime->now->add(days=>7));
    $self->task('Captured');
    $self->started_assignment(DateTime->now);
    $self->times_captured( $self->times_captured + 1 );
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_captured.txt',
        params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $self->format_from],
    );
}

sub capture_a_spy {
    my ($self, $prisoner) = @_;
    $self->spies_captured( $self->spies_captured + 1 );
    $self->on_body->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_captured_a_spy.txt',
        params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $self->format_from($self->on_body->empire_id)],
        from        => $self->empire,
    );
    return $prisoner->go_to_jail;
}

sub detain_a_spy {
    my ($self, $prisoner) = @_;
    $self->spies_captured( $self->spies_captured + 1 );
    $prisoner->go_to_jail;
    return $self->on_body->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_captured_a_spy.txt',
        params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $self->format_from($self->on_body->empire_id)],
        from        => $self->empire,
    );
}

sub format_from {
    my ($self, $empire_id) = @_;
    $empire_id ||= $self->empire_id;
    if ($empire_id == $self->from_body->empire_id) {
        return sprintf '%s of {Planet %s %s}', $self->name, $self->from_body->id, $self->from_body->name;
    }
    else {
        return sprintf '%s of {Starmap %s %s %s}', $self->name, $self->from_body->x, $self->from_body->y, $self->from_body->name;
    }
}

sub turn {
    my ($self, $new_home) = @_;
    $self->times_turned( $self->times_turned + 1 );
    my $message = $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'goodbye.txt',
        params      => [$self->name, $self->from_body->id, $self->from_body->name],
    );
    $self->task('Idle');
    $self->empire_id($new_home->empire_id);
    $self->from_body_id($new_home->id);
    return $message;
}

sub turn_a_spy {
    my ($self, $traitor) = @_;
    $self->spies_turned( $self->spies_turned + 1 );
    $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'new_recruit.txt',
        params      => [$traitor->empire->id, $traitor->empire->name, $traitor->name, $self->name, $self->from_body->id, $self->from_body->name],
    );
    return $traitor->turn($self->from_body);
}

sub knock_out {
    my ($self) = @_;
    $self->available_on(DateTime->now->add(seconds => randint(60, 60 * 60 * 24)));
    $self->task('Unconscious');
}

sub sow_discontent {
    my ($self, $amount) = @_;
    $self->seeds_planted( $self->seeds_planted + 1 );
    $self->on_body->spend_happiness($amount)->update;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'created_disturbance.txt',
        params      => [$self->on_body->name, $amount, $self->on_body->happiness, $self->format_from],
    );
}

sub sow_bliss {
    my ($self, $amount) = @_;
    $self->seeds_planted( $self->seeds_planted + 1 );
    $self->on_body->add_happiness($amount)->update;
}

sub killed_in_action {
    my ($self) = @_;
    $self->available_on(DateTime->now->add(years => 5));
    $self->task('Killed In Action');
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_killed.txt',
        params      => [$self->name, $self->from_body->id, $self->from_body->name, $self->on_body->x, $self->on_body->y, $self->on_body->name],
    );
}

sub no_contact {
    my ($self) = @_;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'no_contact.txt',
        params      => [$self->format_from],
    );
}

sub no_target {
    my ($self) = @_;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'no_target.txt',
        params      => [$self->format_from],
    );
}

sub building_not_found {
    my ($self) = @_;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'could_not_find_building.txt',
        params      => [$self->format_from],
    );
}

sub mission_objective_not_found {
    my ($self, $objective) = @_;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'could_not_find_mission_objective.txt',
        params      => [$objective, $self->format_from],
    );
}

sub ship_not_found {
    my ($self) = @_;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'could_not_find_ship.txt',
        params      => [$self->format_from],
    );
}

sub probe_not_found {
    my ($self) = @_;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'could_not_find_probe.txt',
        params      => [$self->format_from],
    );
}

sub hack_successful {
    my ($self, $amount) = @_;
    $self->on_body->spend_happiness(250)->update;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'hack_successful.txt',
        params      => [$self->on_body->name, $amount, $self->on_body->happiness, $self->format_from],
    );
}

sub hack_filtered {
    my ($self) = @_;
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'hack_filtered.txt',
        params      => [$self->on_body->name, $self->format_from],
    );
}

sub kill_a_spy {
    my ($self, $dead) = @_;
    $self->spies_killed( $self->spies_killed + 1 );
    $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_killed_a_spy.txt',
        params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $self->format_from],
        from        => $self->empire,
    );
    return $dead->killed_in_action;
}


# MISSION SUCCESSES & FAILURES

sub gather_resource_intel {
    my $self = shift;
    given (randint(1,4)) {
        when (1) { return $self->ship_report(@_) }
        when (2) { return $self->travel_report(@_) }
        when (3) { return $self->economic_report(@_) }
        when (4) { return $self->knock_defender_unconscious(@_) }
    }
}

sub gather_resource_intel_loss {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->thwart_intelligence(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
    }
}

sub gather_empire_intel {
    my $self = shift;
    given (randint(1,4)) {
        when (1) { return $self->build_queue_report(@_) }
        when (2) { return $self->surface_report(@_) }
        when (3) { return $self->colony_report(@_) }
        when (4) { return $self->knock_defender_unconscious(@_) }
    }
}

sub gather_empire_intel_loss {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->thwart_intelligence(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
    }
}

sub gather_operative_intel {
    my $self = shift;
    given (randint(1,3)) {
        when (1) { return $self->false_interrogation_report(@_) }
        when (2) { return $self->spy_report(@_) }
        when (3) { return $self->knock_defender_unconscious(@_) }
    }
}

sub gather_operative_intel_loss {
    my $self = shift;
    given (randint(1,4)) {
        when (1) { return $self->counter_intel_report(@_) }
        when (2) { return $self->interrogation_report(@_) }
        when (3) { return $self->thwart_intelligence(@_) }
        when (4) { return $self->knock_attacker_unconscious(@_) }
    }
}

sub hack_network_19 {
    my $self = shift;
    given (randint(1,6)) {
        when (1) { return $self->network19_defamation1(@_) }
        when (2) { return $self->network19_defamation2(@_) }
        when (3) { return $self->network19_defamation3(@_) }
        when (4) { return $self->network19_defamation4(@_) }
        when (5) { return $self->network19_defamation5(@_) }
        when (6) { return $self->knock_defender_unconscious(@_) }
    }
}

sub hack_network_19_loss {
    my $self = shift;
    given (randint(1,10)) {
        when (1) { return $self->capture_hacker(@_) }
        when (2) { return $self->network19_propaganda1(@_) }
        when (3) { return $self->network19_propaganda2(@_) }
        when (4) { return $self->network19_propaganda3(@_) }
        when (5) { return $self->network19_propaganda4(@_) }
        when (6) { return $self->network19_propaganda5(@_) }
        when (7) { return $self->network19_propaganda6(@_) }
        when (8) { return $self->network19_propaganda7(@_) }
        when (9) { return $self->thwart_hacker(@_) }
        when (10) { return $self->knock_attacker_unconscious(@_) }
    }
}

sub appropriate_tech {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->steal_building(@_) }
        when (2) { return $self->steal_plan(@_) }
    }
}

sub appropriate_tech_loss {
    my $self = shift;
    given (randint(1,3)) {
        when (1) { return $self->capture_thief(@_) }
        when (2) { return $self->thwart_thief(@_) }
        when (3) { return $self->kill_thief(@_) }
    }
}

sub sabotage_probes {
    my $self = shift;
    given (randint(1,3)) {
        when (1) { return $self->hack_local_probes(@_) }
        when (2) { return $self->hack_observatory_probes(@_) }
        when (3) { return $self->knock_defender_unconscious(@_) }
    }
}

sub sabotage_probes_loss {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->hack_offending_probes(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
        #when (2) { return $self->kill_hacker(@_) }
    }
}

sub rescue_comrades {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->escape_prison(@_) }
        when (2) { return $self->knock_defender_unconscious(@_) }
#        when (2) { return $self->kill_guard_and_escape_prison(@_) }
    }
}

sub rescue_comrades_loss {
    my $self = shift;
    given (randint(1,3)) {
        when (1) { return $self->capture_rescuer(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
        when (3) { return $self->thwart_intelligence(@_) }
#        when (1) { return $self->kill_suspect(@_) }
    }
}

sub abduct_operatives {
    my $self = shift;
    given (randint(1,1)) {
        when (1) { return $self->abduct_operative(@_) }
    }
}

sub abduct_operatives_loss {
    my $self = shift;
    given (randint(1,4)) {
        when (1) { return $self->capture_kidnapper(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
        when (3) { return $self->thwart_intelligence(@_) }
        when (4) { return $self->kill_intelligence(@_) }
    }
}

sub sabotage_resources {
    my $self = shift;
    given (randint(1,7)) {
        when (1) { return $self->destroy_mining_ship(@_) }
        when (2) { return $self->destroy_ship(@_) }
        when (3) { return $self->kill_contact_with_mining_platform(@_) }
        when (4) { return $self->knock_defender_unconscious(@_) }
        when (5) { return $self->destroy_resources(@_) }
        when (6) { return $self->destroy_plan(@_) }
        when (7) { return $self->destroy_glyph(@_) }
    }
}

sub sabotage_resources_loss {
    my $self = shift;
    given (randint(1,3)) {
        when (1) { return $self->capture_saboteur(@_) }
        when (2) { return $self->thwart_saboteur(@_) }
        when (3) { return $self->knock_attacker_unconscious(@_) }
#        when (3) { return $self->kill_saboteur(@_) }
    }
}

sub appropriate_resources {
    my $self = shift;
    given (randint(1,5)) {
        when (1) { return $self->steal_ships(@_) }
        when (2) { return $self->steal_resources(@_) }
        when (3) { return $self->take_control_of_probe(@_) }
        when (4) { return $self->knock_defender_unconscious(@_) }
        when (5) { return $self->steal_glyph(@_) }
    }
}

sub appropriate_resources_loss {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->capture_thief(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
    }
}

sub assassinate_operatives {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->kill_cop(@_) }
        when (2) { return $self->knock_defender_unconscious(@_) }
    }
}

sub assassinate_operatives_loss {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->kill_intelligence(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
    }
}

sub sabotage_infrastructure {
    my $self = shift;
    given (randint(1,3)) {
        when (1) { return $self->shut_down_building(@_) }
        when (2) { return $self->destroy_infrastructure(@_) }
        when (3) { return $self->knock_defender_unconscious(@_) }
#        when (2) { return $self->destroy_upgrade(@_) }
    }
}

sub sabotage_infrastructure_loss {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->capture_saboteur(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
        #when (2) { return $self->kill_saboteur(@_) }
    }
}

sub incite_mutany {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->turn_defender(@_) }
        when (2) { return $self->knock_defender_unconscious(@_) }
        #when (2) { return $self->kill_cop(@_) }
    }
}

sub incite_mutany_loss {
    my $self = shift;
    given (randint(1,2)) {
        when (1) { return $self->turn_defector(@_) }
        when (2) { return $self->knock_attacker_unconscious(@_) }
        #when (2) { return $self->kill_mutaneer(@_) }
    }
}

sub incite_rebellion {
    my $self = shift;
    given (randint(1,8)) {
        when (1) { return $self->civil_unrest(@_) }
        when (2) { return $self->protest(@_) }
        when (3) { return $self->violent_protest(@_) }
        when (4) { return $self->march_on_capitol(@_) }
        when (5) { return $self->small_rebellion(@_) }
        when (6) { return $self->turn_riot_cop(@_) }
        when (7) { return $self->uprising(@_) }
        when (8) { return $self->knock_defender_unconscious(@_) }
#        when (7) { return $self->kill_cop(@_) }
    }
}

sub incite_rebellion_loss {
    my $self = shift;
    given (randint(1,8)) {
        when (1) { return $self->day_of_rest(@_) }
        when (2) { return $self->festival(@_) }
        when (3) { return $self->capture_rebel(@_) }
        when (4) { return $self->peace_talks(@_) }
        when (5) { return $self->calm_the_rebels(@_) }
        when (6) { return $self->thwart_rebel(@_) }
        when (7) { return $self->turn_rebel(@_) }
        when (8) { return $self->knock_attacker_unconscious(@_) }
#        when (4) { return $self->kill_rebel(@_) }
    }
}

sub incite_insurrection {
    my $self = shift;
    given (randint(1,1)) {
        when (1) { return $self->steal_planet(@_) }
    }
}

sub incite_insurrection_loss {
    my $self = shift;
    given (randint(1,1)) {
        when (1) { return $self->prevent_insurrection(@_) }
    }
}

sub can_conduct_advanced_missions {
    my $self = shift;
    my $defender_capitol_id = $self->on_body->empire->home_planet_id;
    if ($defender_capitol_id == $self->on_body_id ) {
        confess [1010, 'You cannot use this assignment on a capitol planet.'];
    }
    return 1 if ($self->on_body->empire_id < 2); # you can hit AI's all day long
    my $ranks = Lacuna->db->resultset('Lacuna::DB::Result::Log::Empire');
    my $defender_rank = $ranks->search({empire_id => $self->on_body->empire_id },{rows => 1})->get_column('empire_size_rank')->single;
    my $attacker_rank = $ranks->search({empire_id => $self->empire_id },{rows => 1})->get_column('empire_size_rank')->single;
    unless ($attacker_rank + 50 > $defender_rank ) { # remember that the rank is inverted 1 is higher than 2.
        confess [1010, 'This empire is more than 50 away from you in empire rank, and is therefore immune to this attack.'];
    }
    return 1;
}

# OUTCOMES

sub steal_planet {
    my ($self, $defender) = @_;
    $self->can_conduct_advanced_missions;
    my $next_colony_cost = $self->empire->next_colony_cost;
    my $planet_happiness = $self->on_body->happiness;
    my $chance = abs($planet_happiness * 100) / $next_colony_cost;
    my $failure = randint(1,100) > $chance;
    if ($planet_happiness > 0 || $failure) { # lose
        $self->on_body->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'insurrection_luck.txt',
            params      => [$self->on_body_id, $self->on_body->name],
        );
        return $self->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'insurrection_failed.txt',
            params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $self->format_from],
        )->id;
    }
    else { # win
        $self->on_body->empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'lost_planet_to_insurrection.txt',
            params      => [$self->on_body->name, $self->on_body->x, $self->on_body->y, $self->on_body->name],
        );
        $self->on_body->add_news(100,'Led by %s, the citizens of %s have overthrown %s!', $self->name, $self->on_body->name, $self->on_body->empire->name);
        my $defender_capitol_id = $self->on_body->empire->home_planet_id;
        Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({from_body_id => $self->on_body_id})->update({from_body_id => $defender_capitol_id });
        $self->on_body->empire_id($self->empire_id);
        $self->on_body->add_happiness(int(abs($planet_happiness) / 10));
        $self->on_body->update;
        return $self->empire->send_predefined_message(
            tags        => ['Intelligence'],
            filename    => 'insurrection_complete.txt',
            params      => [$self->on_body_id, $self->on_body->name, $self->format_from],
        )->id;
    }
}


sub uprising {
    my ($self, $defender) = @_;
    $self->seeds_planted( $self->seeds_planted + 1 );
    my $loss = sprintf('%.0f', $self->on_body->happiness * 0.10 );
    $loss = 15000 unless ($loss > 15000);
    $self->on_body->spend_happiness( $loss )->update;
    my $message = $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_incited_a_rebellion.txt',
        params      => [$self->on_body->empire_id, $self->on_body->empire->name, $self->on_body->x, $self->on_body->y, $self->on_body->name, $loss, $self->on_body->happiness, $self->format_from],
    );
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'uprising.txt',
        params      => [$self->name, $self->on_body->id, $self->on_body->name, $loss],
    );
    $self->on_body->add_news(100,'Led by %s, the citizens of %s are rebelling against %s.', $self->name, $self->on_body->name, $self->on_body->empire->name);
    return $message->id;
}

sub knock_defender_unconscious {
    my ($self, $defender) = @_;
    return $self->no_contact->id unless (defined $defender);
    $defender->knock_out;
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'knocked_out_a_defender.txt',
        params      => [$self->name, $self->from_body->id, $self->from_body->name],
    )->id;
}

sub knock_attacker_unconscious {
    my ($self, $defender) = @_;
    $self->knock_out;
    return undef;
}

sub turn_defender {
    my ($self, $defender) = @_;
    return $self->no_contact->id unless (defined $defender);
    $self->on_body->add_news(70,'Military leaders on %s are calling for a no confidence vote about the Governor.', $self->on_body->name);
    return $self->turn_a_spy($defender)->id;
}

sub turn_riot_cop {
    my ($self, $defender) = @_;
    return $self->no_contact->id unless (defined $defender);
    $self->on_body->add_news(70,'In a shocking turn of events, police could be seen leaving their posts to join the protesters on %s today.', $self->on_body->name);
    return $self->turn_a_spy($defender)->id;
}

sub small_rebellion {
    my ($self, $defender) = @_;
    $self->on_body->add_news(100,'Hundreds are dead at this hour after a protest turned into a small, but violent, rebellion on %s.', $self->on_body->name);
    return $self->sow_discontent(13000)->id;
}

sub march_on_capitol {
    my ($self, $defender) = @_;
    $self->on_body->add_news(100,'Protesters now march on the %s Planetary Command Center, asking for the Governor\'s resignation.', $self->on_body->name);
    return $self->sow_discontent(11000)->id;
}

sub violent_protest {
    my ($self, $defender) = @_;
    $self->on_body->add_news(100,'The protests at the %s Ministries have turned violent. An official was rushed to hospital in critical condition.', $self->on_body->name);
    return $self->sow_discontent(9000)->id;
}

sub protest {
    my ($self, $defender) = @_;
    $self->on_body->add_news(100,'Protesters can be seen jeering outside nearly every Ministry at this hour on %s.', $self->on_body->name);
    return $self->sow_discontent(7000)->id;
}

sub civil_unrest {
    my ($self, $defender) = @_;
    $self->on_body->add_news(100,'In recent weeks there have been rumblings of political discontent on %s.', $self->on_body->name);
    return $self->sow_discontent(5000)->id;
}

sub calm_the_rebels {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $self->sow_bliss(randint(250,2500));
    $self->on_body->add_news(100,'In an effort to bring an swift end to the rebellion, the %s Governor delivered an eloquent speech about hope.', $self->on_body->name);
    return undef;
}

sub peace_talks {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $self->sow_bliss(randint(500,5000));
    $self->on_body->add_news(100,'Officials from both sides of the rebellion are at the Planetary Command Center on %s today to discuss peace.', $self->on_body->name);
    return undef;
}

sub day_of_rest {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $self->sow_bliss(randint(2500,25000));
    $self->on_body->add_news(100,'The Governor of %s declares a day of rest and peace. Citizens rejoice.', $self->on_body->name);
    return undef;
}

sub festival {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $self->sow_bliss(randint(1000,10000));
    $self->on_body->add_news(100,'The %s Governor calls it the %s festival. Whatever you call it, people are happy.', $self->on_body->name, $self->on_body->star->name);
    return undef;
}

sub turn_defector {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(60,'%s has just announced plans to defect from %s to %s.', $self->name, $self->empire->name, $defender->empire->name);
    return $defender->turn_a_spy($self)->id;
}

sub turn_rebel {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(70,'The %s Governor\'s call for peace appears to be working. Several rebels told this reporter they are going home.', $self->on_body->name);
    return $defender->turn_a_spy($self)->id;
}

sub capture_rebel {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(50,'Police say they have crushed the rebellion on %s by apprehending %s.', $self->on_body->name, $self->name);
    return $defender->capture_a_spy($self)->id;
}

sub prevent_insurrection {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(50,'Officials prevented a coup d\'Žtat today on on %s by capturing %s and comrades.', $self->on_body->name, $self->name);
    $defender->capture_a_spy($self)->id;
    my $alliance_id = $defender->empire->alliance_id;
    if ($alliance_id) {
        my @member_ids = $defender->empire->alliance->members->get_column('id')->all;
        my $conspirators = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({ on_body_id => $self->on_body_id, task => { 'not in' => ['Idle','Travelling','Captured'] }, empire_id => { 'in' => \@member_ids } });
        while (my $conspirator = $conspirators->next ) {
            $defender->capture_a_spy($conspirator);
        }
    }
    return $defender->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'prevented_insurrection.txt',
        params      => [$self->on_body_id, $self->on_body->name, $defender->format_from],
    );
}

sub capture_kidnapper {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(50,'Police say they have captured the notorious %s-time kidnapper %s on %s.', randint(10,20), $self->on_body->name, $self->name);
    return $defender->capture_a_spy($self)->id;
}

sub abduct_operative {
    my ($self, $defender) = @_;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {body_id => $self->on_body->id, task => 'Docked', hold_size => { '>=' => 700 }},
        {rows => 1}
        )->single;
    return $self->ship_not_found unless (defined $ship);
    return $self->get_spooked->id unless (defined $defender);
    $defender->task('Waiting On Trade');
    $defender->update;
    $ship->send(
        target      => $self->from_body,
        direction   => 'in',
        payload     => { spies => [ $self->id ], prisoners => [$defender->id] }
    );
    $defender->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'spy_abducted.txt',
        params      => [$defender->format_from, $defender->name],
    );
    return $self->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'bringing_home_abductee.txt',
        params      => [$defender->format_from, $self->format_from],
    )->id;
}

#sub kill_rebel {
#    my ($self, $defender) = @_;
#    return $self->get_spooked->id unless (defined $defender);
#    kill_a_spy($self->on_body, $self, $defender);
#    $self->on_body->add_news(80,'The leader of the rebellion to overthrow %s was killed in a firefight today on %s.', $self->on_body->empire->name, $self->on_body->name);
#}
#
#sub kill_mutaneer {
#    my ($self, $defender) = @_;
#    return $self->get_spooked->id unless (defined $defender);
#    kill_a_spy($self->on_body, $self, $defender);
#    $self->on_body->add_news(80,'Double agent %s of %s was executed on %s today.', $self->name, $self->empire->name, $self->on_body->name);
#}

sub thwart_rebel {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(20,'The rebel leader, known as %s, is still eluding authorities on %s at this hour.', $self->name, $self->on_body->name);
    return $defender->thwart_a_spy($self)->id;
}


sub destroy_infrastructure {
    my ($self, $defender) = @_;
    my $building = $self->on_body->buildings->search(
        { efficiency => { '>' => 0 }, class => { 'not like' => 'Lacuna::DB::Result::Bulding::Permanent%' } },
        { rows=>1, order_by => 'rand()' }
        )->single;
    return $self->building_not_found unless defined $building;
    return $self->building_not_found if ($building->class eq 'Lacuna::DB::Result::PlanetaryCommand');
    $building->body($self->on_body);
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_kablooey.txt',
        params      => [$building->level, $building->name, $self->on_body->id, $self->on_body->name],
    );
    $self->things_destroyed( $self->things_destroyed + 1 );
    $self->on_body->add_news(90,'%s was rocked today when the %s exploded, sending people scrambling for their lives.', $self->on_body->name, $building->name);
    $building->spend_efficiency($self->level)->update;
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => ['level '.($building->level).' '.$building->name, $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
    )->id;
}

#sub destroy_upgrade {
#    my ($self, $defender) = @_;
#    my $builds = $self->on_body->builds(1);
#    my $building = $builds->next;
#    return $self->building_not_found unless defined $building;
#    $building->body($self->on_body);
#    $self->on_body->empire->send_predefined_message(
#        tags        => ['Alert'],
#        filename    => 'building_kablooey.txt',
#        params      => [$building->level + 1, $building->name, $self->on_body->id, $self->on_body->name],
#    );
#    $self->things_destroyed( $self->things_destroyed + 1 );
#    $self->empire->send_predefined_message(
#        tags        => ['Intelligence'],
#        filename    => 'sabotage_report.txt',
#        params      => ['a level of their level '.($building->level + 1).' '.$building->name, $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
#    );
#    $self->on_body->add_news(90,'%s was rocked today when a construction crane toppled into the %s.', $self->on_body->name, $building->name);
#    if ($building->level == 0) {
#        $building->delete;
#    }
#    else {
#        $building->is_upgrading(0);
#        $building->update;
#    }
#    $self->on_body->needs_surface_refresh(1);
#    $self->on_body->needs_recalc(1);
#    $self->on_body->update;
#}

sub destroy_ship {
    my ($self, $defender) = @_;
    my $ship = $self->on_body->ships->search(
        {task => 'Docked'},
        {rows => 1, order_by => 'rand()' }
        )->single;
    return $self->ship_not_found unless (defined $ship);
    $self->things_destroyed( $self->things_destroyed + 1 );
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_blew_up_at_port.txt',
        params      => [$ship->type_formatted, $self->on_body->id, $self->on_body->name],
    );
    my $message = $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => [$ship->type_formatted, $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
    );
    $self->on_body->add_news(90,'Today officials on %s are investigating the explosion of a %s at the Space Port.', $self->on_body->name, $ship->type_formatted);
    $ship->delete;
    return $message->id;
}

sub destroy_plan {
    my ($self, $defender) = @_;
    my $plan = $self->on_body->plans->search(undef, {rows => 1, order_by => 'rand()'})->single;
    return $self->mission_objective_not_found('plan') unless defined $plan;
    $self->things_destroyed( $self->things_destroyed + 1 );
    my $stolen = 'level '.$plan->level_formatted.' '.$plan->class->name.' plan';
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'item_destroyed.txt',
        params      => [$stolen, $self->on_body->id, $self->on_body->name],
    );
    my $message = $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => [$stolen, $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
    );
    $self->on_body->add_news(70,'The Planetary Command on %s was torched. While the building itself survived a critical plan was lost.', $self->on_body->name);
    $plan->delete;
    return $message->id;
}

sub destroy_glyph {
    my ($self, $defender) = @_;
    my $glyph = $self->on_body->glyphs->search(undef, {rows => 1, order_by => 'rand()'})->single;
    return $self->mission_objective_not_found('glyph') unless defined $glyph;
    $self->things_destroyed( $self->things_destroyed + 1 );
    my $stolen = $glyph->type.' glyph';
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'item_destroyed.txt',
        params      => [$stolen, $self->on_body->id, $self->on_body->name],
    );
    my $message = $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => [$stolen, $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
    );
    $self->on_body->add_news(70,'A museum was broken into on %s and a rare artifact was smashed to pieces.', $self->on_body->name);
    $glyph->delete;
    return $message->id;
}

sub destroy_resources {
    my ($self, $defender) = @_;
    $self->things_destroyed( $self->things_destroyed + 1 );
    my @types = qw(food water energy ore);
    my $resource = $types[ rand @types ];
    my $stolen = 'bunch of '. $resource;
    $self->on_body->spend_type($resource, int($self->on_body->type_stored($resource) / 2))->update;
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'item_destroyed.txt',
        params      => [$stolen, $self->on_body->id, $self->on_body->name],
    );
    my $message = $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => [$stolen, $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
    );
    $self->on_body->add_news(70,'A train carrying a load of %s on %s derailed destroying the cargo.', $resource, $self->on_body->name);
    return $message->id;
}

sub destroy_mining_ship {
    my ($self, $defender) = @_;
    my $ministry = $self->on_body->mining_ministry;
    return $self->building_not_found unless defined $ministry;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search(
        {body_id => $self->on_body->id, task => 'Mining'},
        {rows => 1}
        )->single;
    return $self->ship_not_found unless $ship;
    $ship->delete;
    $ministry->recalc_ore_production;
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_blew_up_at_port.txt',
        params      => ['mining '.$ship->type_formatted, $self->on_body->id, $self->on_body->name],
    );
    $self->things_destroyed( $self->things_destroyed + 1 );
    $self->on_body->add_news(90,'Today, officials on %s are investigating the explosion of a mining cargo ship at the Space Port.', $self->on_body->name);
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'sabotage_report.txt',
        params      => ['mining cargo ship', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
    )->id;
}

sub capture_saboteur {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(40,'A saboteur was apprehended on %s today by %s authorities.', $self->on_body->name, $self->on_body->empire->name);
    return $defender->capture_a_spy($self)->id;
}

#sub kill_saboteur {
#    my ($self, $defender) = @_;
#    return $self->get_spooked unless (defined $defender);
#    kill_a_spy($self->on_body, $self, $defender);
#    $self->on_body->add_news(70,'%s told us that a lone saboteur was killed on %s before he could carry out his plot.', $self->on_body->empire->name, $self->on_body->name);
#}

sub thwart_saboteur {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(20,'%s authorities on %s are conducting a manhunt for a suspected saboteur.', $self->on_body->empire->name, $self->on_body->name);
    return $defender->thwart_a_spy($self)->id;
}

sub steal_resources {
    my ($self, $defender) = @_;
    my $on_body = $self->on_body;
    my $ship = $on_body->ships->search(
        {task => 'Docked', type => {'in' => ['cargo_ship','smuggler_ship','galleon','freighter','hulk','dory','barge']}},
        { rows => 1}
        )->single;
    return $self->ship_not_found unless defined $ship;
    my $space = $ship->hold_size;
    my @types = (FOOD_TYPES, ORE_TYPES, 'water', 'energy');
    my %resources;
    foreach my $type (@types) {
        if ($on_body->type_stored($type) >= $space) {
            $resources{$type} = $space;
            $on_body->spend_type($type, $space);
            last;
        }
        else {
            $resources{$type} = $on_body->type_stored($type);
            $on_body->spend_type($type, $resources{$type});
        }
    }
    $on_body->update;
    $ship->send(
        target      => $self->on_body,
        direction   => 'in',
        payload     => {
            spies => [ $self->id ],
            resources   => \%resources,
        },
    );
    my $home = $self->from_body;
    $ship->body_id($home->id);
    $ship->body($home);
    $ship->update;
    $self->available_on($ship->date_available->clone);
    $self->on_body_id($home->id);
    $self->task('Travelling');
    $self->things_stolen( $self->things_stolen + 1 );
    my @table = (['Resource','Amount']);
    foreach my $type (keys %resources) {
        push @table, [ $type, $resources{$type} ];
    }
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_stolen.txt',
        params      => [$ship->type_formatted, $self->on_body->id, $self->on_body->name],
        attachments=> { table => \@table},
    );
    $self->on_body->add_news(50,'In a daring robbery today a thief absconded with a %s full of resources from %s.', $ship->type_formatted, $self->on_body->name);
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'ship_theft_report.txt',
        params      => [$ship->type_formatted, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => \@table},
    )->id;
}

sub steal_glyph {
    my ($self, $defender) = @_;
    my $on_body = $self->on_body;
    my $ship = $on_body->ships->search(
        {task => 'Docked', type => {'in' => ['cargo_ship','smuggler_ship','galleon','freighter','hulk','barge']}},
        { rows => 1}
        )->single;
    return $self->ship_not_found unless defined $ship;
    my $glyph = $on_body->glyphs->search(undef, {rows => 1, order_by => 'rand()'})->single;
    return $self->ship_not_found unless defined $glyph;
    $ship->send(
        target      => $self->on_body,
        direction   => 'in',
        payload     => {
            spies => [ $self->id ],
            glyphs   => [$glyph->type],
        },
    );
    my $home = $self->from_body;
    $ship->body_id($home->id);
    $ship->body($home);
    $ship->update;
    $self->available_on($ship->date_available->clone);
    $self->on_body_id($home->id);
    $self->task('Travelling');
    $self->things_stolen( $self->things_stolen + 1 );
    my @table = (['Glyph'],$glyph->type);
    $glyph->delete;
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_stolen.txt',
        params      => [$ship->type_formatted, $self->on_body->id, $self->on_body->name],
        attachments=> { table => \@table},
    );
    $self->on_body->add_news(50,'In a daring robbery today a thief absconded with a %s carrying a glyph from %s.', $ship->type_formatted, $self->on_body->name);
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'ship_theft_report.txt',
        params      => [$ship->type_formatted, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => \@table},
    )->id;
}

sub steal_ships {
    my ($self, $defender) = @_;
    my @types;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships');
    foreach my $type (SHIP_TYPES) {
        my $ship = $ships->new({type => $type});
        if ($ship->pilotable) {
            push @types, $type;
        }
    }
    my $ship = $ships->search(
        {body_id => $self->on_body->id, task => 'Docked', type => {'in' => \@types}},
        {rows => 1}
        )->single;
    last unless defined $ship;
    my $home = $self->from_body;
    $ship->body_id($home->id);
    $ship->body($home);
    $ship->send(
        target      => $self->on_body,
        direction   => 'in',
        payload     => { spies => [ $self->id ] }
    );
    $self->available_on($ship->date_available->clone);
    $self->on_body_id($home->id);
    $self->things_stolen( $self->things_stolen + 1 );
    $self->task('Travelling');
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'ship_stolen.txt',
        params      => [$ship->type_formatted, $self->on_body->id, $self->on_body->name],
    );
    $self->on_body->add_news(50,'In a daring robbery a thief absconded with a %s from %s today.', $ship->type_formatted, $self->on_body->name);
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'ship_theft_report.txt',
        params      => [$ship->type_formatted, $self->name, $self->from_body->id, $self->from_body->name],
    )->id;
}

sub steal_building {
    my ($self, $defender) = @_;
    my $building = $self->on_body->buildings->search(
        { level => { '>' => 1 } },
        { rows=>1, order_by => 'rand()' }
        )->single;
    return $self->building_not_found unless defined $building;
    $self->things_stolen( $self->things_stolen + 1 );
    my $max = ($self->level > $building->level) ? $building->level : $self->level;
    my $level = randint(1,$max);
    $building->level( $building->level - 1 );
    $self->from_body->add_plan($building->class, $level);
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_level_stolen.txt',
        params      => [$building->name, $self->on_body->id, $self->on_body->name],
    );
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'building_theft_report.txt',
        params      => [$level, $building->name, $self->name, $self->from_body->id, $self->from_body->name],
    )->id;
}

sub steal_plan {
    my ($self, $defender) = @_;
    my $plan = $self->on_body->plans->search(undef,{ rows=>1, order_by => 'rand()' })->single;
    return $self->building_not_found unless defined $plan;
    $self->things_stolen( $self->things_stolen + 1 );
    $plan->body_id($self->from_body_id);
    $plan->update;
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'plan_stolen.txt',
        params      => [$plan->level_formatted, $plan->class->name, $self->on_body->id, $self->on_body->name],
    );
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'building_theft_report.txt',
        params      => [$plan->level_formatted, $plan->class->name, $self->name, $self->from_body->id, $self->from_body->name],
    )->id;
}

sub kill_thief {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(70,'%s police caught and killed a thief on %s during the commission of the hiest.', $self->on_body->empire->name, $self->on_body->name);
    return $defender->kill_a_spy($self)->id;
}

sub capture_thief {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(40,'%s announced the incarceration of a thief on %s today.', $self->on_body->empire->name, $self->on_body->name);
    return $defender->capture_a_spy($self)->id;
}

sub thwart_thief {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(20,'A thief evaded %s authorities on %s. Citizens are warned to lock their doors.', $self->on_body->empire->name, $self->on_body->name);
    return $defender->thwart_a_spy($self)->id;
}

sub shut_down_building {
    my ($self, $defender) = @_;
    my @classnames = (
        'Lacuna::DB::Result::Building::Shipyard',
        'Lacuna::DB::Result::Building::Park',
        'Lacuna::DB::Result::Building::Waste::Recycling',
        'Lacuna::DB::Result::Building::Development',
        'Lacuna::DB::Result::Building::Intelligence',
        'Lacuna::DB::Result::Building::Trade',
        'Lacuna::DB::Result::Building::Transporter',
    );
    my $building_class = random_element(\@classnames);
    my $building = $self->on_body->get_building_of_class($building_class);
    return $self->building_not_found unless defined $building;
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'building_loss_of_power.txt',
        params      => [$building->name, $self->on_body->id, $self->on_body->name],
    );
    $building->body($self->on_body);
    $building->spend_efficiency($self->level)->update;
    $self->on_body->add_news(25,'Employees at the %s on %s were left in the dark today during a power outage.', $building->name, $self->on_body->name);    
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_disabled_a_building.txt',
        params      => [$building->name, $self->on_body->name, $self->format_from],
    )->id;
}

sub take_control_of_probe {
    my ($self, $defender) = @_;
    my $probe = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({body_id => $self->on_body_id }, {rows=>1})->single;
    return $self->probe_not_found unless defined $probe;
    $self->things_stolen( $self->things_stolen + 1 );
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$probe->star->x, $probe->star->y, $probe->star->name],
    );
    $self->on_body->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $self->on_body->empire->name, $probe->star->name);    
    my $message = $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_have_taken_control_of_a_probe.txt',
        params      => [$probe->star->x, $probe->star->y, $probe->star->name, $probe->empire_id, $probe->empire->name, $self->format_from],
    );
    $probe->body_id($self->from_body_id);
    $probe->empire_id($self->empire_id);
    $probe->update;
    return $message->id;
}

sub kill_contact_with_mining_platform {
    my ($self, $defender) = @_;
    my $ministry = $self->on_body->mining_ministry;
    return $self->building_not_found unless defined $ministry;
    my $platform = Lacuna->db->resultset('Lacuna::DB::Result::MiningPlatforms')->search({planet_id => $self->on_body->id},{rows=>1})->single;
    return $self->building_not_found unless defined $platform;
    my $asteroid = $platform->asteroid;
    return $self->building_not_found unless defined $asteroid;
    $ministry->remove_platform($platform);
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'we_lost_contact_with_a_mining_platform.txt',
        params      => [$asteroid->x, $asteroid->y, $asteroid->name],
    );
    $self->things_destroyed( $self->things_destroyed + 1 );
    $self->on_body->add_news(50,'The %s controlled mining outpost on %s went dark. Our thoughts are with the miners.', $self->on_body->empire->name, $asteroid->name);    
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_disabled_a_mining_platform.txt',
        params      => [$asteroid->x, $asteroid->y, $asteroid->name, $self->on_body->empire->id, $self->on_body->empire->name, $self->format_from],
    )->id;
}

sub hack_observatory_probes {
    my ($self, $defender) = @_;
    my $probe = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({body_id => $self->on_body->id }, {rows=>1})->single;
    return $self->probe_not_found unless defined $probe;
    $self->things_destroyed( $self->things_destroyed + 1 );
    my $message = $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_destroyed_a_probe.txt',
        params      => [$probe->star->x, $probe->star->y, $probe->star->name, $probe->empire->id, $probe->empire->name, $self->format_from],
    );
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$probe->star->x, $probe->star->y, $probe->star->name],
    );
    $probe->delete;
    $self->on_body->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $self->on_body->empire->name, $probe->star->name);    
    return $message->id;
}

sub hack_offending_probes {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    my @safe = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({task=>'Counter Espionage', on_body_id=>$defender->on_body_id})->get_column('empire_id')->all;
    my $probe = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({star_id => $self->on_body->star_id, empire_id => {'not in' => \@safe} }, {rows=>1})->single;
    return $self->probe_not_found unless defined $probe;
    $defender->things_destroyed( $defender->things_destroyed + 1 );
    $defender->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_destroyed_a_probe.txt',
        params      => [$probe->star->x, $probe->star->y, $probe->star->name, $probe->empire->id, $probe->empire->name, $defender->format_from],
    );
    $self->on_body->add_news(25,'%s scientists say they have lost control of a research satellite in the %s system.', $probe->empire->name, $self->on_body->star->name);    
    my $message = $probe->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$probe->star->x, $probe->star->y, $probe->star->name],
    );
    $probe->delete;
    return $message->id;
}

sub hack_local_probes {
    my ($self, $defender) = @_;
    my $probe = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({star_id => $self->on_body->star_id, empire_id => $self->on_body->empire_id }, {rows=>1})->single;
    return $self->probe_not_found unless defined $probe;
    $self->things_destroyed( $self->things_destroyed + 1 );
    $self->on_body->empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'probe_destroyed.txt',
        params      => [$probe->star->x, $probe->star->y, $probe->star->name],
    );
    $self->on_body->add_news(25,'%s scientists say they have lost control of a research probe in the %s system.', $self->on_body->empire->name, $self->on_body->star->name);    
    my $message = $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'we_destroyed_a_probe.txt',
        params      => [$probe->star->x, $probe->star->y, $probe->star->name, $probe->empire->id, $probe->empire->name, $self->format_from],
    );
    $probe->delete;
    return $message->id;
}

sub colony_report {
    my ($self, $defender) = @_;
    my @report = (['Name','X','Y','Orbit']);
    my $colonies = $self->on_body->empire->planets;
    while (my $colony = $colonies->next) {
        push @report, [
            $colony->name,
            $colony->x,
            $colony->y,
            $colony->orbit,
        ];
    }
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Colony Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments=> { table => \@report},
    )->id;
}

sub surface_report {
    my ($self, $defender) = @_;
    my @map;
    my $buildings = $self->on_body->buildings;
    while (my $building = $buildings->next) {
        push @map, {
            image   => $building->image_level,
            x       => $building->x,
            y       => $building->y,
        };
    }
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Surface Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments  => { map => {
            surface         => $self->on_body->surface,
            buildings       => \@map
        }},
    )->id;
}

sub spy_report {
    my ($self, $defender) = @_;
    my @peeps = (['Name','From','Assignment','Level']);
    my %planets = ( $self->on_body->id => $self->on_body->name );
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({empire_id => {'!=' => $self->empire_id}, on_body_id=>$self->on_body_id});
    while (my $spook = $spies->next) {
        unless (exists $planets{$spook->from_body_id}) {
            $planets{$spook->from_body_id} = $spook->from_body->name;
        }
        push @peeps, [$spook->name, $planets{$spook->from_body_id}, $spook->task, $spook->level];
    }
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Spy Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments=> { table => \@peeps},
    )->id;
}

sub economic_report {
    my ($self, $defender) = @_;
    my @resources = (
        ['Resource', 'Per Hour', 'Stored'],
        [ 'Food', $self->on_body->food_hour, $self->on_body->food_stored ],
        [ 'Water', $self->on_body->water_hour, $self->on_body->water_stored ],
        [ 'Energy', $self->on_body->energy_hour, $self->on_body->energy_stored ],
        [ 'Ore', $self->on_body->ore_hour, $self->on_body->ore_stored ],
        [ 'Waste', $self->on_body->waste_hour, $self->on_body->waste_stored ],
        [ 'Happiness', $self->on_body->happiness_hour, $self->on_body->happiness ],
    );
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Economic Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => \@resources},
    )->id;
}

sub travel_report {
    my ($self, $defender) = @_;
    my @travelling = (['Ship Name','Type','From','To','Arrival']);
    my $ships = $self->on_body->ships_travelling;
    while (my $ship = $ships->next) {
        my $target = ($ship->foreign_body_id) ? $ship->foreign_body : $ship->foreign_star;
        my $from = $self->on_body->name;
        my $to = $target->name;
        if ($ship->direction ne 'out') {
            my $temp = $from;
            $from = $to;
            $to = $temp;
        }
        push @travelling, [
            $ship->name,
            $ship->type_formatted,
            $self->on_body->name,
            $target->name,
            $ship->date_available_formatted,
        ];
    }
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Travel Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => \@travelling},
    )->id;
}

sub ship_report {
    my ($self, $defender) = @_;
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({body_id => $self->on_body->id, task => 'Docked'});
    my @ships = (['Name', 'Type', 'Speed', 'Hold Size']);
    while (my $ship = $ships->next) {
        push @ships, [$ship->name, $ship->type_formatted, $ship->speed, $ship->hold_size];
    }
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Docked Ships Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => \@ships},
    )->id;
}

sub build_queue_report {
    my ($self, $defender) = @_;
    my @report = (['Building', 'Level', 'Expected Completion']);
    my $builds = $self->on_body->builds;
    while (my $build = $builds->next) {
        push @report, [
            $build->name,
            $build->level + 1,
            format_date($build->upgrade_ends),
        ];
    }
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Build Queue Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => \@report},
    )->id;
}

sub false_interrogation_report {
    my ($self, $defender) = @_;
    return $self->no_contact->id unless (defined $defender);
    my $suspect = $self->get_random_prisoner;
    return $self->no_contact->id unless defined $suspect;
    my $suspect_home = $suspect->from_body;
    my $suspect_empire = $suspect->empire;
    $defender->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Interrogation Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => [
            ['Question', 'Response'],
            ['Name', $suspect->name],
            ['Offense Rating', randint(0,27)],
            ['Defense Rating', randint(0,27)],
            ['Allegiance', $suspect_empire->name],
            ['Home World', $suspect_home->name],
            ['Species Name', $suspect_empire->species_name],
            ['Species Description', $suspect_empire->species_description],
            ['Habitable Orbits', join(' - ',randint(1,3), randint(3,7))],
            ['Manufacturing Affinity', randint(1,7)],
            ['Deception Affinity', randint(1,7)],
            ['Research Affinity', randint(1,7)],
            ['Management Affinity', randint(1,7)],
            ['Farming Affinity', randint(1,7)],
            ['Mining Affinity', randint(1,7)],
            ['Science Affinity', randint(1,7)],
            ['Environmental Affinity', randint(1,7)],
            ['Political Affinity', randint(1,7)],
            ['Trade Affinity', randint(1,7)],
            ['Growth Affinity', randint(1,7)],
            ]},
    );
    $suspect->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'false_interrogation.txt',
        params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $suspect->name, $suspect_home->id, $suspect_home->name],
    );
    return $self->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'interrogating_prisoners_failing.txt',
        params      => [$self->on_body->x, $self->on_body->y, $self->on_body->name, $suspect->name, $self->name, $self->from_body->id, $self->from_body->name],
    )->id;
}

sub interrogation_report {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    my $suspect = $self->get_random_prisoner;
    return $self->get_spooked->id unless defined $suspect;
    my $suspect_home = $suspect->from_body;
    my $suspect_empire = $suspect->empire;
    $defender->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Interrogation Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => [
            ['Question', 'Response'],
            ['Name', $suspect->name],
            ['Offense Rating', $suspect->offense],
            ['Defense Rating', $suspect->defense],
            ['Allegiance', $suspect_empire->name],
            ['Home World', $suspect_home->name],
            ['Species Name', $suspect_empire->species_name],
            ['Species Description', $suspect_empire->species_description],
            ['Habitable Orbits', join(' - ', $suspect_empire->min_orbit, $suspect_empire->max_orbit)],
            ['Manufacturing Affinity', $suspect_empire->manufacturing_affinity],
            ['Deception Affinity', $suspect_empire->deception_affinity],
            ['Research Affinity', $suspect_empire->research_affinity],
            ['Management Affinity', $suspect_empire->management_affinity],
            ['Farming Affinity', $suspect_empire->farming_affinity],
            ['Mining Affinity', $suspect_empire->mining_affinity],
            ['Science Affinity', $suspect_empire->science_affinity],
            ['Environmental Affinity', $suspect_empire->environmental_affinity],
            ['Political Affinity', $suspect_empire->political_affinity],
            ['Trade Affinity', $suspect_empire->trade_affinity],
            ['Growth Affinity', $suspect_empire->growth_affinity],
            ]},
    );
    return undef;
}

#sub kill_guard_and_escape_prison {
#    my ($self, $defender) = @_;
#    return $self->no_contact->id unless (defined $defender);
#    my $suspect = shift @{$espionage->{captured}};
#    return $self->no_contact->id unless defined $suspect;
#    kill_a_spy($self->on_body, $defender, $suspect);
#    escape_a_spy($self->on_body, $suspect);
#    $self->on_body->add_news(70,'An inmate killed his interrogator, and escaped the prison on %s today.', $self->on_body->name);
#}

sub escape_prison {
    my ($self, $defender) = @_;
    my $suspect = $self->get_random_prisoner;
    return $self->no_contact->id unless defined $suspect;
    $self->on_body->add_news(50,'At this hour police on %s are flabbergasted as to how an inmate escaped earlier in the day.', $self->on_body->name);    
    return $suspect->escape->id;
}

#sub kill_suspect {
#    my ($self, $defender) = @_;
#    return $self->get_spooked->id unless (defined $defender);
#    my $suspect = shift @{$espionage->{'Captured'}{spies}};
#    return $self->get_spooked->id unless defined $suspect;
#    kill_a_spy($self->on_body, $suspect, $defender);
#    $self->on_body->add_news(50,'Allegations of police brutality are being made on %s after an inmate was killed in custody today.', $self->on_body->name);
#}

sub capture_rescuer {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(60,'%s was caught trying to break into prison today on %s. Police insisted he stay.', $self->name, $self->on_body->name);
    return $defender->capture_a_spy($self)->id;
}

sub thwart_intelligence {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(25,'Corporate espionage has become a real problem on %s.', $self->on_body->name);
    return $defender->thwart_a_spy($self)->id;
}

sub counter_intel_report {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    my @peeps = (['Name','From','Assignment','Level']);
    my %planets = ( $self->on_body->id => $self->on_body->name );
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->search({empire_id => {'!=' => $defender->empire_id}, on_body_id=>$self->on_body_id});
    while (my $spook = $spies->next) {
        unless (exists $planets{$spook->from_body_id}) {
            $planets{$spook->from_body_id} = $spook->from_body->name;
        }
        push @peeps, [$spook->name, $planets{$spook->from_body_id}, $spook->task, $spook->level];
    }
    $defender->empire->send_predefined_message(
        tags        => ['Intelligence'],
        filename    => 'intel_report.txt',
        params      => ['Counter Intelligence Report', $self->on_body->x, $self->on_body->y, $self->on_body->name, $self->name, $self->from_body->id, $self->from_body->name],
        attachments => { table => \@peeps},
    );
    return undef;
}

sub kill_cop {
    my ($self, $defender) = @_;
    return $self->no_contact->id unless (defined $defender);
    $self->on_body->add_news(60,'An officer named %s was killed in the line of duty on %s.', $defender->name, $self->on_body->name);
    return $self->kill_a_spy($defender)->id;
}

sub kill_intelligence {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(60,'A suspected spy was killed in a struggle with police on %s today.', $self->on_body->name);
    return $defender->kill_a_spy($self)->id;
}

sub capture_hacker {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(30,'Alleged hacker %s is awaiting arraignment on %s today.', $self->name, $self->on_body->name);
    return $defender->capture_a_spy($self)->id;
}

#sub kill_hacker {
#    my ($self, $defender) = @_;
#    return $self->get_spooked->id unless (defined $defender);
#    $self->on_body->add_news(60,'A suspected hacker, age '.randint(16,60).', was found dead in his home today on %s.', $self->on_body->name);
#    kill_a_spy($self->on_body, $self, $defender);    
#}

sub thwart_hacker {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless (defined $defender);
    $self->on_body->add_news(10,'Identity theft has become a real problem on %s.', $self->on_body->name);  
    return $defender->thwart_a_spy($self)->id;
}

sub network19_propaganda1 {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $defender->seeds_planted($defender->seeds_planted + 1);
    if ($self->on_body->add_news(50,'A resident of %s has won the Lacuna Expanse talent competition.', $self->on_body->name)) {
        $self->on_body->add_happiness(250)->update;
    }
    return undef;
}

sub network19_propaganda2 {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $defender->seeds_planted($defender->seeds_planted + 1);
    if ($self->on_body->add_news(50,'The economy of %s is looking strong, showing GDP growth of nearly 10%% for the past quarter.',$self->on_body->name)) {
        $self->on_body->add_happiness(500)->update;
    }
    return undef;
}

sub network19_propaganda3 {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $defender->seeds_planted($defender->seeds_planted + 1);
    if ($self->on_body->add_news(50,'The Governor of %s has set aside 1000 square kilometers as a nature preserve.', $self->on_body->name)) {
        $self->on_body->add_happiness(750)->update;
    }
    return undef;
}

sub network19_propaganda4 {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $defender->seeds_planted($defender->seeds_planted + 1);
    if ($self->on_body->add_news(50,'If %s had not inhabited %s, the planet would likely have reverted to a barren rock.', $self->on_body->empire->name, $self->on_body->name)) {
        $self->on_body->add_happiness(1000)->update;
    }
    return undef;
}

sub network19_propaganda5 {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $defender->seeds_planted($defender->seeds_planted + 1);
    if ($self->on_body->add_news(50,'The benevolent leader of %s is a gift to the people of %s.', $self->on_body->empire->name, $self->on_body->name)) {
        $self->on_body->add_happiness(1250)->update;
    }
    return undef;
}

sub network19_propaganda6 {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $defender->seeds_planted($defender->seeds_planted + 1);
    if ($self->on_body->add_news(50,'%s is the greatest, best, most free empire in the Expanse, ever.', $self->on_body->empire->name)) {
        $self->on_body->add_happiness(1500)->update;
    }
    return undef;
}

sub network19_propaganda7 {
    my ($self, $defender) = @_;
    return $self->get_spooked->id unless defined $defender;
    $defender->seeds_planted($defender->seeds_planted + 1);
    if ($self->on_body->add_news(50,'%s is the ultimate power in the Expanse right now. It is unlikely to be challenged any time soon.', $self->on_body->empire->name)) {
        $self->on_body->add_happiness(1750)->update;
    }
    return undef;
}

sub network19_defamation1 {
    my ($self, $defender) = @_;
    $self->seeds_planted($self->seeds_planted + 1);
    if ($self->on_body->add_news(50,'A financial report for %s shows that many people are out of work as the unemployment rate approaches 10%%.', $self->on_body->name)) {
        $self->hack_successful(1000);
    }
    return $self->hack_filtered->id;
}

sub network19_defamation2 {
    my ($self, $defender) = @_;
    $self->seeds_planted($self->seeds_planted + 1);
    if ($self->on_body->add_news(50,'An outbreak of the Dultobou virus was announced on %s today. Citizens are encouraged to stay home from work and school.', $self->on_body->name)) {
        $self->hack_successful(2000);
    }
    return $self->hack_filtered->id;
}

sub network19_defamation3 {
    my ($self, $defender) = @_;
    $self->seeds_planted($self->seeds_planted + 1);
    if ($self->on_body->add_news(50,'%s is unable to keep its economy strong. Sources inside say it will likely fold in a few days.', $self->on_body->empire->name)) {
        $self->hack_successful(3000);
    }
    return $self->hack_filtered->id
}

sub network19_defamation4 {
    my ($self, $defender) = @_;
    $self->seeds_planted($self->seeds_planted + 1);
    if ($self->on_body->add_news(50,'The Governor of %s has lost her mind. She is a raving mad lunatic! The Emperor could not be reached for comment.', $self->on_body->name)) {
        $self->hack_successful(4000);
    }
    return $self->hack_filtered->id;
}

sub network19_defamation5 {
    my ($self, $defender) = @_;
    $self->seeds_planted($self->seeds_planted + 1);
    if ($self->on_body->add_news(50,'%s is the smallest, worst, least free empire in the Expanse, ever.', $self->on_body->empire->name)) {
        $self->hack_successful(5000);
    }
    return $self->hack_filtered->id;
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
