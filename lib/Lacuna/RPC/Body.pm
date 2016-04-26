package Lacuna::RPC::Body;

use utf8;
no warnings qw(uninitialized);

use Moose;
use Lacuna::Verify;
use Lacuna::Constants qw(BUILDABLE_CLASSES);
use DateTime;
use Lacuna::Util qw(randint);
use List::Util qw(all);
use List::MoreUtils qw(uniq);
use Carp;
use Data::Dumper;

use feature 'switch';

extends 'Lacuna::RPC';

with "Lacuna::RPC::Role::Building";

sub get_status {
    my $self        = shift;
    my $args        = shift;

    if (ref($args) ne "HASH") {
        $args = {
            session_id  => $args,
            body_id     => shift,
        };
    }

    my $empire  = $self->get_empire($args);
    my $session = $self->get_session($args);
    my $body    = $self->get_body($session, $empire, $args->{body_id});
    return $self->format_status($empire, $body);
}

sub get_body_status {
    my ($self, %args) = @_;

    my $session = $self->get_session({session_id => $args{session_id}});
    my $body    = Lacuna->db->resultset('Map::Body')->find($args{body_id});
    confess [1000, 'Cannot find that body.'] unless $body;

    return {
        body    => $body->get_status,
        status  => $self->format_status($session),
    };
}

sub abandon {
    my ($self, $session_id, $body_id) = @_;
    my $session = $self->get_session({session_id => $session_id, body_id => $body_id});
    my $empire = $session->current_empire;
    my $body   = $session->current_body;
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) { 
        my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
            type            => 'AbandonStation',
            name            => 'Abandon Station',
            description     => 'Abandon the station named {Planet '.$body->id.' '.$body->name.'}.',            
            proposed_by_id  => $empire->id,
        });
        $proposition->station($body);
        $proposition->proposed_by($empire);
        $proposition->insert;
        confess [1017, 'The abandon has been delayed pending a parliamentary vote.'];
    }
    $body->abandon;
    $empire->add_medal('abandoned_colony');
    return $self->format_status($session);
}

sub rename {
    my ($self, $session_id, $body_id, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Name not available.',$name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->no_padding
        ->not_ok(Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({name=>$name, 'id'=>{'!='=>$body_id}})->count); # name available
    
    my $session = $self->get_session({session_id => $session_id, body_id => $body_id});
    my $empire = $session->current_empire;
    my $body   = $session->current_body;

    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        unless ($body->parliament->effective_level >= 3) {
            confess [1013, 'You need to have a level 3 Parliament to rename a station.'];
        }
        my $proposition = Lacuna->db->resultset('Lacuna::DB::Result::Propositions')->new({
            type            => 'RenameStation',
            name            => 'Rename Station',
            scratch         => { name => $name },
            description     => 'Rename the station from {Planet '.$body->id.' '.$body->name.'} to "'.$name.'".',            
            proposed_by_id  => $empire->id,
        });
        $proposition->station($body);
        $proposition->proposed_by($empire);
        $proposition->insert;
        confess [1017, 'The rename has been delayed pending a parliamentary vote.'];
    }

    return 1 if $name eq $body->name;

    my $cache = Lacuna->cache;
    unless ($cache->get('body_rename_spam_lock',$body->id)) {
        $cache->set('body_rename_spam_lock',$body->id, 1, 60*60);
        $body->add_news(200,"In a bold move to show its growing power, %s renamed %s to %s.",$empire->name, $body->name, $name);
    }
    $body->update({name => $name});
    return 1;
}

sub get_buildings {
    my ($self, %args) = @_;

    my $session = $self->get_session(\%args);
    my $empire  = $session->current_empire;
    my $body    = $session->current_body;

    if ($body->needs_surface_refresh) {
        $body->needs_surface_refresh(0);
        $body->update;
    }

    return {
        buildings   => $self->out_buildings($body),
        body        => {
            surface_image   => $body->surface,
        },
        status      => $self->format_status($session, $body),
    };
}

sub repair_list {
    my ($self, $session_id, $body_id, $building_ids) = @_;

    my $session = $self->get_session({session_id => $session_id, body_id => $body_id});
    my $empire = $session->current_empire;
    my $body   = $session->current_body;

    if (scalar @$building_ids > 121) {
        confess [1002, 'Invalid number of buildings in argument.'];
    }
    
    if ($body->needs_surface_refresh) {
        $body->needs_surface_refresh(0);
        $body->update;
    }
    my @buildings = @{$body->building_cache};
    my %all_ids = map { $_->id => $_ } @buildings;

    my %out;
    for my $bld_id (@{$building_ids}) {
        my $building = $all_ids{$bld_id};
        next unless $building;
        next unless $building->efficiency < 100;
        my $return;
        my $ok = eval { $return = $building->repair };
        $out{$building->id} = {
            url     => $building->controller_class->app_url,
            image   => $building->image_level,
            name    => $building->name,
            x       => $building->x,
            y       => $building->y,
            level   => $building->level,
            efficiency => $building->efficiency,
        };
        if ($building->is_upgrading) {
            $out{$building->id}{pending_build} = $building->upgrade_status;
        }
        if ($building->is_working) {
            $out{$building->id}{work} = {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            };
        }
        if ($building->efficiency < 100) {
            $out{$building->id}{repair_costs} = $building->get_repair_costs;
        }
    }
    return {
        buildings=>\%out,
        status=>$self->format_status($session, $body)
    };
}

sub rearrange_buildings {
  my ($self, $session_id, $body_id, $arrangement) = @_;
  confess [1002, "Arrangement must be an array reference of hashes" ]
      unless $arrangement &&
      ref $arrangement eq 'ARRAY' &&
      all { ref $_ eq 'HASH' && exists $_->{id} && exists $_->{x} && exists $_->{y} } @$arrangement;


  my $session = $self->get_session({session_id => $session_id, body_id => $body_id});
  my $empire = $session->current_empire;
  my $body   = $session->current_body;
  my %cur_lay; my %new_lay;
  my %cur_ids; my %new_ids;
  my @miss_in_new; my @miss_in_cur;
  for my $building (@$arrangement) {
    my $id = $building->{id};
    my $x  = int( $building->{x} );
    my $y  = int( $building->{y} );
    $new_ids{$id} = {
      x     => $x,
      y     => $y,
    };
  }
  foreach my $building (@{$body->building_cache}) {
    my $id   = $building->id;
    my $x    = $building->x;
    my $y    = $building->y;
    my $name = $building->name;
    my $class = $building->class;
    $cur_ids{$id} = {
      x     => $x,
      y     => $y,
      name  => $name,
      class => $class,
    };
    my $spot = sprintf("%d:%d",$x,$y);
    $cur_lay{$spot} = $id;
    if (defined($new_ids{$id})) {
      $new_ids{$id}->{name} = $name;
      $new_ids{$id}->{class} = $class;
    }
    else {
      $new_ids{$id} = {
        x     => $x,
        y     => $y,
        name  => $name,
        class => $class,
      };
    }
  }
  for my $id (keys %new_ids) {
    my $spot = sprintf("%d:%d", $new_ids{$id}->{x}, $new_ids{$id}->{y});
    push @miss_in_cur, $id unless defined($cur_ids{$id});
    if (defined($new_lay{$spot})) {
      confess [1013,
        sprintf("Trying to place %s (%s) in %s, where you already have %s (%s)",
                $new_ids{$id}->{name}, $id, $spot, $new_ids{$new_lay{$spot}}->{name}, $new_lay{$spot})
      ];
    }
    $new_lay{$spot} = $id;
    if ($spot eq "0:0") {
      if ($new_ids{$id}->{class} ne "Lacuna::DB::Result::Building::PlanetaryCommand" and
          $new_ids{$id}->{class} ne "Lacuna::DB::Result::Building::Module::StationCommand") {
        confess [1013, "Position 0:0 needs to be occupied by PCC or Station Command" ];
      }
    }
  }
  if (scalar @miss_in_cur) {
    confess [1013, sprintf("Ids in new layout, not in current: %s\n",
                   join(":",@miss_in_cur))
    ];
  }
  my $position_err = check_positions(\%new_ids, \%new_lay);
  if (scalar @$position_err) {
    confess [1013, sprintf("Position Errors: %s", join("\n", @$position_err)) ];
  }
# Done with checks, let's set new locations.
  my @moved;
  for my $id (keys %new_ids) {
    my $new_spot = sprintf("%d:%d", $new_ids{$id}->{x}, $new_ids{$id}->{y});
    my $old_spot = sprintf("%d:%d", $cur_ids{$id}->{x}, $cur_ids{$id}->{y});
    if ($new_spot ne $old_spot) {
      my $building =
           Lacuna->db->resultset('Lacuna::DB::Result::Building')->
           find({body_id => $body_id, id => $id});
      $building->update({
        x => $new_ids{$id}->{x},
        y => $new_ids{$id}->{y},
      });
      my $move = {
        id   => $id,
        x    => $new_ids{$id}->{x},
        y    => $new_ids{$id}->{y},
        name => $new_ids{$id}->{name},
      };
      push @moved, $move;
    }
  }
  return { moved => \@moved,
           body => {surface_image => $body->surface},
           status => $self->format_status($session, $body)};
}

sub check_positions {
  my ($new_ids, $new_lay) = @_;

  my @position_err;
  for my $id (keys %$new_ids) {
    my $spot_chk;
    if (abs($new_ids->{$id}->{x}) > 5 or abs($new_ids->{$id}->{y}) > 5) {
      push @position_err,
               sprintf("Trying to place %s at %d,%d which is outside of bounds",
                        $new_ids->{$id}->{name},
                        abs($new_ids->{$id}->{x}),
                        abs($new_ids->{$id}->{y}) );
      next;
    }
    given ($new_ids->{$id}->{class}) {
      when("Lacuna::DB::Result::Building::PlanetaryCommand") {
        unless ($new_ids->{$id}->{x} == 0 &&
            $new_ids->{$id}->{y} == 0) {
          push @position_err,
               sprintf("%s can not be placed anywhere but 0,0", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::Module::StationCommand") {
        unless ($new_ids->{$id}->{x} == 0 &&
            $new_ids->{$id}->{y} == 0) {
          push @position_err,
               sprintf("%s can not be placed anywhere but 0,0", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::SSLa") {
        if ($new_ids->{$id}->{x} == 5 || $new_ids->{$id}->{y} == -5 ||
            ( $new_ids->{$id}->{x} == -1 && ( $new_ids->{$id}->{y} == 0 || $new_ids->{$id}->{y} == 1)) ||
            ( $new_ids->{$id}->{x} == 0 && $new_ids->{$id}->{y} == 1 ) ) {
          push @position_err,
               sprintf("%s can not be placed in that position", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::SSLb") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x} - 1, $new_ids->{$id}->{y});
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::SSLa") {
          push @position_err,
               sprintf("%s needs SSLa to the left of it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::SSLc") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x}, $new_ids->{$id}->{y}+1);
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::SSLb") {
          push @position_err,
               sprintf("%s needs SSLb above it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::SSLd") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x} + 1, $new_ids->{$id}->{y});
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::SSLc") {
          push @position_err,
               sprintf("%s needs SSLc to the right of it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTa") {
        if ($new_ids->{$id}->{x} ~~ [ -5, 5 ] ||
            $new_ids->{$id}->{y} ~~ [ -5, 5 ] ||
           ($new_ids->{$id}->{x} ~~ [ -1, 0, 1 ] &&
            $new_ids->{$id}->{y} ~~ [ -1, 0, 1 ])) {
          push @position_err,
               sprintf("%s can not be placed in that position", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTb") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x} + 1, $new_ids->{$id}->{y});
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::LCOTa") {
          push @position_err,
               sprintf("%s needs LCOTa to the right of it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTc") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x}, $new_ids->{$id}->{y}-1);
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::LCOTb") {
          push @position_err,
               sprintf("%s needs LCOTb below it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTd") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x} - 1, $new_ids->{$id}->{y});
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::LCOTc") {
          push @position_err,
               sprintf("%s needs LCOTc to the left of it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTe") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x} - 1, $new_ids->{$id}->{y});
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::LCOTd") {
          push @position_err,
               sprintf("%s needs LCOTd to the left of it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTf") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x}, $new_ids->{$id}->{y}+1);
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::LCOTe") {
          push @position_err,
               sprintf("%s needs LCOTe above it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTg") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x}, $new_ids->{$id}->{y}+1);
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::LCOTf") {
          push @position_err,
               sprintf("%s needs LCOTg above it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTh") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x} + 1, $new_ids->{$id}->{y});
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::LCOTg") {
          push @position_err,
               sprintf("%s needs LCOTg to the right of it.", $new_ids->{$id}->{name});
        }
      }
      when("Lacuna::DB::Result::Building::LCOTi") {
        $spot_chk = sprintf("%d:%d", $new_ids->{$id}->{x} + 1, $new_ids->{$id}->{y});
        if ($new_ids->{$new_lay->{$spot_chk}}->{class} ne
            "Lacuna::DB::Result::Building::LCOTh") {
          push @position_err,
               sprintf("%s needs LCOTh to the right of it.", $new_ids->{$id}->{name});
        }
      }
    }
  }
  return \@position_err;
}

sub get_buildable {
    my ($self, $session_id, $body_id, $x, $y, $tag) = @_;
    my $session = $self->get_session({session_id => $session_id, body_id => $body_id});
    my $empire = $session->current_empire;
    my $body   = $session->current_body;
    
    my $building_rs = Lacuna->db->resultset('Lacuna::DB::Result::Building');

    $body->check_for_available_build_space($x, $y);

    # dummy building properties
    my %properties = (
            x               => $x,
            y               => $y,
            level           => 0,
            body_id         => $body->id,
            efficiency      => 100,
            body            => $body,
            date_created    => DateTime->now,
    );

    my %out;
    my @buildable = BUILDABLE_CLASSES;
    
    # build queue
    my $dev = $body->development;
    my $max_items_in_build_queue = $body->build_queue_size;
    my $items_in_build_queue = $body->build_queue_length;
    
    if ($body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) { 
        @buildable = ();
        $max_items_in_build_queue = 99;
    }

    # plans
    #
    my %plans;
    my @buildable_plans = sort {$a->extra_build_level <=> $b->extra_build_level} grep{$_->level == 1} @{$body->plan_cache};
    for my $plan (@buildable_plans) {
        next unless eval { $plan->class->can_really_be_built };
        push @buildable, $plan->class->controller_class;
        $plans{$plan->class} = $plan->extra_build_level;
    }

    foreach my $class (uniq @buildable) {
        $properties{class} = $class->model_class;
        my $building = $building_rs->new(\%properties);
        my @tags = $building->build_tags;
        if ($properties{class} ~~ [keys %plans]) {
            push @tags, 'Plan';
        }
        if ($tag) {
            next unless ($tag ~~ \@tags);
        }
        my $cost = $building->cost_to_upgrade;
        my $can_build = eval{$body->has_met_building_prereqs($building, $cost)};
        my $reason = $@;
        if ($can_build) {
            push @tags, 'Now';
        }
        elsif (ref $reason ne 'ARRAY') {
            confess $reason;
        }
        elsif ($reason->[0] == 1011) {
            push @tags, 'Soon';
        }
        else {
            push @tags, 'Later';
        }
        $out{$building->name} = {
            url         => $class->app_url,
            image       => $building->image_level,
            build       => {
                can         => ($can_build) ? 1 : 0,
                cost        => $cost,
                reason      => $reason,
                tags        => \@tags,
                no_plot_use => $building->isa('Lacuna::DB::Result::Building::Permanent'),
            },
            production  => $building->stats_after_upgrade,
        };
        if (exists $plans{$properties{class}}) {
            my $building_tmp = $building;
            $building_tmp->level( $plans{$properties{class}} );
            $cost = $building_tmp->cost_to_upgrade;
            $out{$building->name}{build}{cost}{time} = $cost->{time};
            $out{$building->name}{build}{extra_level} = $plans{$properties{class}};
        }
    }

    return {buildable=>\%out, build_queue => { max => $max_items_in_build_queue, current => $items_in_build_queue}, status=>$self->format_status($session, $body)};
}

sub get_buildable_locations {
    my ($self, $opts) = @_;
    my $session = $self->get_session($opts);
    my $empire = $session->current_empire;
    my $body   = $session->current_body;

    my %args;
    $args{size} = $opts->{size} if $opts->{size} and $opts->{size} ~~ [1,4,9];

    return {
        status => $self->format_status($session, $body),
        unoccupied => $body->find_free_spaces(\%args),
    }
}

sub view_laws {
    my ($self, $session_id, $body_id) = @_;
    my $session = $self->get_session({session_id => $session_id});
    my $empire = $session->current_empire;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')
                ->find($body_id);
    if ($body and $body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
        my @out;
        my $laws = $body->laws;
        while (my $law = $laws->next) {
            push @out, $law->get_status($empire);
        }
        return {
            status          => $self->format_status($session, $body),
            laws            => \@out,
            station         => {
                id   => $body->id,
                name => $body->name,
                zone => $body->zone,
                x    => $body->x,
                y    => $body->y,,,
                empire => {
                    id   => $body->empire_id,
                    name => $body->empire->name,
                },
                alliance => {
                    id   => $body->alliance_id,
                    name => $body->alliance->name,
                },
            },
        };
    }
    else {
        return {
            status => $self->format_status($session, $body),
            laws   => [ { name => "Not a Station",
                          descripition => "Not a Station",
                          date_enacted => "00 00 0000 00:00:00 +0000",
                          id => 0
                        } ],
        },
    }
}

sub set_colony_notes
{
    my ($self, $session_id, $body_id, $opts) = @_;
    my $session = $self->get_session({session_id => $session_id, body_id => $body_id});
    my $empire = $session->current_empire;
    my $body   = $session->current_body;
    my $notes = $opts->{notes};

    #Lacuna::Verify->new(content=>\$notes, throws=>[1000,'Content may not have any of the following characters: @&<>;{}()',$notes])
    #    ->no_restricted_chars;

    $body->notes($notes);
    $body->update;

    return {
        status => $self->format_status($session, $body),
    };
}

__PACKAGE__->register_rpc_method_names(qw(
    abandon
    rename
    get_buildings
    get_buildable
    get_buildable_locations
    get_status
    get_body_status
    repair_list
    rearrange_buildings
    set_colony_notes
    view_laws));

no Moose;
__PACKAGE__->meta->make_immutable;

