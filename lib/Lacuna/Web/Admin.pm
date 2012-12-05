package Lacuna::Web::Admin;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use feature "switch";
use Module::Find;
use UUID::Tiny ':std';
use Lacuna::Util qw(format_date);
use List::Util qw(sum);
use Data::Dumper;

sub www_send_test_message {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('empire_id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    if ($empire->id <= 1) {
        confess [400, 'That empire is required.'];
    }

    $empire->send_message(
    from        => $empire,
    body        => 'This is a test message that contains all the components possible in a message.
     {food} {water} {ore} {energy} {waste} {happiness} {essentia} {build} {time}
    {Empire 1 Lacuna Expanse Corp}
    {Planet '.$empire->home_planet->id.' '.$empire->home_planet->name.'}
    {Alliance 1 Fake Alliance}
    {Starmap 0 0 The Center of the Map}
    [http://www.lacunaexpanse.com]
    ',
    subject        => 'Test Message',
    tags        => ['Alert'],
    attachments => {
        table => [
                ['Header 1', 'Header 2'],
                ['Row 1 Field 1', 'Row 1 Field 2'],
                ['Row 2 Field 1', 'Row 2 Field 2'],
                ],
        image => {
                url => 'http://bloximages.chicago2.vip.townnews.com/host.madison.com/content/tncms/assets/editorial/8/ec/604/8ec6048a-998e-11de-b821-001cc4c002e0.preview-300.jpg',
                title => 'JT Rocks',
                link => 'http://host.madison.com/wsj/business/article_bd9f8c96-998d-11de-87d3-001cc4c002e0.html',
                },
        link => {
                url => 'http://www.plainblack.com/',
                label => 'Plain Black',
                },
        map => {
                surface => 'surface-p12',
                buildings => [
                        {
                            x => 0,
                            y => 0,
                            image => 'command4',
                        },
                        {
                            x => -4,
                            y => 2,
                            image => 'apples9',
                        },
                    ]
                }
       }
    );

    return $self->wrap('Sent!');
}


sub www_search_essentia_codes {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $codes = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->search(undef, {order_by => { -desc => 'amount' }, rows => 25, page => $page_number });
    my $code = $request->param('code') || '';
    if ($code) {
        $codes = $codes->search({code => { like => $code.'%' }});
    }
    my $out = '<h1>Search Essentia Codes</h1>';
    $out .= '<form method="post" action="/admin/search/essentia/codes"><input name="code" value="'.$code.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Code</th><th>Amount</th><th>Description</th><th>Date Created</th><td>Used</td></tr>';
    while (my $code = $codes->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $code->id, $code->code, $code->amount, $code->description, $code->date_created, $code->used);
    }
    $out .= '<form method="post" action="/admin/add/essentia/code"><tr>';
    $out .= '<td></td>';
    $out .= '<td></td>';
    $out .= '<td><input name="amount" value="100" size="4"></td>';
    $out .= '<td><input name="description" value="Admin Gift" size="30"></td>';
    $out .= '<td></td>';
    $out .= '<td><input type="submit" value="add code"></td>';
    $out .= '</tr></form>';
    $out .= '</table>';
    $out .= $self->format_paginator('search/essentia/codes', 'code', $code, $page_number);
    return $self->wrap($out);
}

sub www_add_essentia_code {
    my ($self, $request) = @_;
    my $code = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->new({
        date_created    => DateTime->now,
        amount          => $request->param('amount'),
        description     => $request->param('description'),
        code            => create_uuid_as_string(UUID_V4),
    })->insert;
    return $self->wrap('<p>Essentia Code: '. $code->code.'</p><p><a href="/admin/search/essentia/codes">Back To Essentia Codes</a></a>');
}

sub www_view_essentia_log {
    my ($self, $request) = @_;
    my $empire_id = $request->param('empire_id');
    my $transactions = Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia')->search({empire_id => $empire_id}, {order_by => { -desc => 'date_stamp' }});
    my $out = '<h1>Essentia Transaction Log</h1>';
    $out .= sprintf('<a href="/admin/view/empire?id=%s">Back To Empire</a>', $empire_id);
    $out .= '<table style="width: 100%;"><tr><th>Date</th><th>Amount</th><th>Description</th><th>From ID</th><th>From</th><th>Transaction ID</th></tr>';
    while (my $transaction = $transactions->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%d</td><td>%s</td><td>%s</td></tr>',
                        $transaction->date_stamp, $transaction->amount, $transaction->description,
                        $transaction->from_id, $transaction->from_name, $transaction->transaction_id);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_search_empires {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    if ($name) {
        $empires = $empires->search({name => { like => $name.'%' }});
    }
    my $out = '<h1>Search Empires</h1>';
    $out .= '<form method="post" action="/admin/search/empires"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>Species</th><th>Home</th><th>Last Login</th></tr>';
    while (my $empire = $empires->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/empire?id=%s">%s</a></td><td>%s</td><td>%s</td><td><a href="/admin/view/body?id=%s">%s</a></td><td>%s</td></tr>', $empire->id, $empire->id, $empire->name, $empire->species_name, $empire->home_planet_id, $empire->home_planet_id, $empire->last_login);
    }
    $out .= '</table>';
    $out .= $self->format_paginator('search/empires', 'name', $name, $page_number);
    return $self->wrap($out);
}

sub www_search_bodies {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    if ($name) {
        $bodies = $bodies->search({name => { like => $name.'%' }});
    }
    if ($request->param('empire_id')) {
        $bodies = $bodies->search({empire_id => $request->param('empire_id')});
    }
    if ($request->param('zone')) {
        $bodies = $bodies->search({zone => $request->param('zone')});
    }
    if ($request->param('star_id')) {
        $bodies = $bodies->search({star_id => $request->param('star_id')});
    }
    my $out = '<h1>Search Bodies</h1>';
    $out .= '<form method="post" action="/admin/search/bodies"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>O</th><th>Zone</th><th>Star</th><th>Empire</th></tr>';
    while (my $body = $bodies->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/body?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><a href="/admin/view/empire?id=%s">%s</a></td></tr>', $body->id, $body->id, $body->name, $body->x, $body->y, $body->orbit, $body->zone, $body->star_id, $body->empire_id || '', $body->empire_id || '');
    }
    $out .= '</table>';
    $out .= $self->format_paginator('search/bodies', 'name', $name, $page_number);
    return $self->wrap($out);
}

sub www_search_stars {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $stars = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    if ($name) {
        $stars = $stars->search({name => { like => $name.'%' }});
    }
    if ($request->param('zone')) {
        $stars = $stars->search({zone => $request->param('zone')});
    }
    my $out = '<h1>Search Stars</h1>';
    $out .= '<form method="post" action="/admin/search/stars"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Zone</th></tr>';
    while (my $star = $stars->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/star?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $star->id, $star->id, $star->name, $star->x, $star->y, $star->zone);
    }
    $out .= '</table>';
    $out .= $self->format_paginator('search/stars', 'name', $name, $page_number);
    return $self->wrap($out);
}

sub www_complete_builds {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    foreach my $building (@{$body->building_cache}) {
        next unless ( $building->is_upgrading );
        $building->is_upgrading(0);
        $building->upgrade_ends($building->upgrade_started);
        $building->level($building->level + 1);
        $building->update;
    }
    $body->needs_recalc(1);
    $body->needs_surface_refresh(1);
    $body->update;
    return $self->wrap(sprintf('All building constuction completed! <a href="/admin/view/body?id=%s">Back To Body</a>', $request->param('body_id')));
}

sub www_send_stellar_flare {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    foreach my $building (@{$body->building_cache}) {
        next unless ('Infrastructure' ~~ [$building->build_tags]);
        next if ( $building->class eq 'Lacuna::DB::Result::Building::PlanetaryCommand' );
        $building->efficiency(0);
        $building->update;
    }
    $body->needs_recalc(1);
    $body->needs_surface_refresh(1);
    $body->update;
    $body->add_news(99, sprintf('%s has just belched a massive stellar flare. %s bore the brunt of it.', $body->star->name, $body->name));
    $body->empire->send_message(
        subject     => 'Stellar Flare',
        body        => "A stellar flare has disabled most of the infrastructure on ".$body->name.".\n\nRegards,\n\nYour Humble Assistant",
        tag         => 'Alert',
    );
    return $self->wrap('Stellar flare sent!');
}

sub www_send_meteor_shower {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    foreach my $building (@{$body->building_cache}) {
        next unless ('Infrastructure' ~~ [$building->build_tags]);
        next if ( $building->class eq 'Lacuna::DB::Result::Building::PlanetaryCommand' );
        $building->class('Lacuna::DB::Result::Building::Permanent::Crater');
        $building->level(1);
        $building->is_upgrading(0);
        $building->is_working(0);
        $building->update;
    }
    $body->needs_recalc(1);
    $body->needs_surface_refresh(1);
    $body->update;
    $body->add_news(99, sprintf('A meteor shower rained hell on %s today, and much of its infrastructure was destroyed.', $body->name));
    $body->empire->send_message(
        subject     => 'Meteor Shower',
        body        => "A meteor shower has just destroyed most of the infrastructure on ".$body->name.".\n\nRegards,\n\nYour Humble Assistant",
        tag         => 'Alert',
    );
    return $self->wrap('Meteor shower sent!');
}

sub www_send_pestilence {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    if ($body->id == $body->empire->home_planet_id) {
        confess [401, 'You cannot send pestilence to someone\'s home planet.'];
    }
    $body->add_news(99, sprintf('Yesterday there was an outbreak of Derni Pestilence on %s. Today %s has gone dark.', $body->name, $body->name));
    $body->empire->send_message(
        subject     => 'Pestilence',
        body        => "Derni Pestilence has broken out on ".$body->name.". The colony is lost.\n\nRegards,\n\nYour Humble Assistant",
        tag         => 'Alert',
    );
    $body->sanitize;
    return $self->wrap('Pestilence sent!');
}

sub www_view_buildings {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $buildings = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({ body_id => $body_id }, {order_by => ['x','y'] });
    my $out = '<h1>View Buildings</h1>';
    $out .= sprintf('<a href="/admin/view/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Level</th><th>InProgress</th><th>Efficiency</th></tr>';
    while (my $building = $buildings->next) {
        $out .= sprintf('<form method="get" action="/admin/set/efficiency"><tr>');
        $out .= sprintf('<td>%s</td><td>%s</td>',$building->id,$building->name);
        $out .= sprintf('<td><input name="x" type="text" size="3" value="%s"></td>',$building->x);
        $out .= sprintf('<td><input name="y" type="text" size="3" value="%s"></td>',$building->y);
        $out .= sprintf('<td><input name="level" type="text" size="5" value="%s"></td>',$building->level);
        $out .= sprintf('<td>%s</td><td><input type="hidden" name="building_id" value="%s">',$building->is_upgrading, $building->id);
        $out .= sprintf('<input name="efficiency" type="text" size="3" value="%s">', $building->efficiency);
        $out .= sprintf('<input type="submit" value="submit"></td></form>');
        $out .= sprintf('<form method="post" action="/admin/delete/building">');
        $out .= sprintf('<input type="hidden" name="building_id" value="%s"/>', $building->id);
        $out .= sprintf('<td><input type="submit" value="delete"/></td></form></tr>');
    }   
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_set_efficiency {
    my ($self, $request) = @_;
    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($request->param('building_id'));
    $building->update({
        efficiency      => $request->param('efficiency'),
        x               => $request->param('x'),
        y               => $request->param('y'),
        level           => $request->param('level'),
    });
    return $self->www_view_buildings($request, $building->body_id);
}

sub www_delete_building {
    my ($self, $request) = @_;
    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($request->param('building_id'));
    my $body = $building->body;
    $building->delete;
    $body->needs_recalc(1);
    $body->needs_surface_refresh(1);
    $body->update;
    $body->tick;
    return $self->www_view_buildings($request, $building->body_id);
}

sub www_view_fleets {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $fleets = Lacuna->db->resultset('Fleet')->search({ body_id => $body_id });
    my $out = '<h1>View Fleets</h1>';
    $out .= sprintf('<a href="/admin/view/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>Quantity</th><th>Type</th><th>Stealth</th><th>Hold Size</th><th>Speed</th><th>Combat</th><th>Task</th><th>Delete</td></tr>';
    while (my $fleet = $fleets->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>', $fleet->id, $fleet->name, $fleet->quantity, $fleet->type_formatted, $fleet->stealth, $fleet->hold_size, $fleet->speed, $fleet->combat);
        if ($fleet->task eq 'Travelling') {
            $out .= sprintf('<td>%s<form method="post" action="/admin/zoom/fleet"><input type="hidden" name="fleet_id" value="%s"><input type="hidden" name="body_id" value="%s"><input type="submit" value="zoom"></form></td>', $fleet->task, $fleet->id, $body_id);
        }
        elsif ($fleet->task ~~ [qw(Defend Orbiting)]) {
            my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($fleet->foreign_body_id);
            $out .= sprintf('<td>%s<br>%s (%d, %d)<form method="post" action="/admin/recall/fleet"><input type="hidden" name="fleet_id" value="%s"><input type="hidden" name="body_id" value="%s"><input type="submit" value="recall"></form></td>', $fleet->task, $target->name, $target->x, $target->y, $fleet->id, $body_id);
        }
        elsif ($fleet->task ne 'Docked') {
            $out .= sprintf('<td>%s<form method="post" action="/admin/dock/fleet"><input type="hidden" name="fleet_id" value="%s"><input type="hidden" name="body_id" value="%s"><input type="submit" value="dock" onclick="return confirm(\'Doing this without knowing the implications can cause unintended side effects. Are you sure?\');"></form></td>', $fleet->task, $fleet->id, $body_id);            
        }
        else {
            $out .= sprintf('<td>%s</td>', $fleet->task);            
        }
        $out .= sprintf('<form method="post" action="/admin/delete/fleet"><td><input type="hidden" name="fleet_id" value="%s"><input type="hidden" name="body_id" value="%s"><input type="submit" value="delete"></td></form></tr>', $fleet->id, $body_id);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_zoom_fleet {
    my ($self, $request) = @_;
    my $fleet_id = $request->param('fleet_id');
    my $fleet = Lacuna->db->resultset('Fleet')->find($fleet_id);
    my $body = $fleet->body;
    $fleet->update({date_available => DateTime->now});
    $body->tick;
    return $self->www_view_fleets($request);
}

sub www_recall_fleet {
    my ($self, $request) = @_;
    my $fleet_id = $request->param('fleet_id');
    my $fleet = Lacuna->db->resultset('Fleet')->find($fleet_id);
    my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($fleet->foreign_body_id);

    my $body = $fleet->body;
    $fleet->send(
        target      => $target,
        direction   => 'in',
    );
    $body->tick;
    return $self->www_view_fleets($request);
}

sub www_dock_fleet {
    my ($self, $request) = @_;
    my $fleet_id = $request->param('fleet_id');
    my $fleet = Lacuna->db->resultset('Fleet')->find($fleet_id);
    $fleet->land->update;
    return $self->www_view_fleets($request);
}

sub www_delete_fleet {
    my ($self, $request) = @_;
    my $fleet = Lacuna->db->resultset('Fleet')->find($request->param('fleet_id'));
    $fleet->delete;
    return $self->www_view_fleets($request);
}

sub www_view_resources {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    my @types = (FOOD_TYPES, ORE_TYPES, qw(water energy waste));
    my $out = '<h1>View Resources</h1>';
    $out .= sprintf('<a href="/admin/view/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Type</th><th>Stored</th><th>Add</th></tr>';
    foreach my $resource (@types) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><form method="post" action="/admin/add/resources"><td><input name="amount"><input type="submit" value="add"><input type="hidden" name="body_id" value="%s"><input type="hidden" name="resource" value="%s"</td></form></tr>', $resource, $body->type_stored($resource), $body_id, $resource);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_add_resources {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->add_type($request->param('resource'), $request->param('amount'));
    $body->update;
    return $self->www_view_resources($request, $body->id);
}

sub www_view_glyphs {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $glyphs = Lacuna->db->resultset('Lacuna::DB::Result::Glyph')->search({ body_id => $body_id }, {order_by => ['type'] });
    my $out = '<h1>View Glyphs</h1>';
    $out .= sprintf('<a href="/admin/view/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Type</th><th>Quantity</th><th>Action</th></tr>';
    while (my $glyph = $glyphs->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td><a href="/admin/delete/glyph?body_id=%s&glyph_id=%s">Delete</a></td></tr>', $glyph->id, $glyph->type, $glyph->quantity, $body_id, $glyph->id);
    }
    $out .= '<form method="post" action="/admin/add/glyph"><tr>';
    $out .= '<td><input type="hidden" name="body_id" value="'.$body_id.'"></td>';
    $out .= '<td><select name="type">';
    foreach my $name (sort(ORE_TYPES())) {
        $out .= '<option value="'.$name.'">'.$name.'</option>';
    }
    $out .= '</select></td>';
    $out .= '<td><input type="submit" value="add glyph"></td>';
    $out .= '</tr></form>';
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_add_glyph {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->add_glyph($request->param('type'));
    return $self->www_view_glyphs($request, $body->id);
}

sub www_delete_glyph {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->glyphs->find($request->param('glyph_id'))->delete;
    return $self->www_view_glyphs($request, $body->id);
}

sub www_view_plans {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    my $plans = $body->sorted_plans;

    my $out = '<h1>View Plans</h1>';
    $out .= sprintf('<a href="/admin/view/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Level</th><th>Name</th><th>Extra Build Level</th><th>Quantity</th><th>Action</th></tr>';
    for my $plan (@$plans) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>',$plan->level, $plan->class->name, $plan->extra_build_level, $plan->quantity);
        $out .= sprintf('<form method="get" action="/admin/delete/plan">');
        $out .= sprintf('<input type="hidden" name="level" value="%s">',$plan->level);
        $out .= sprintf('<input type="hidden" name="class" value="%s">',$plan->class);
        $out .= sprintf('<input type="hidden" name="extra" value="%s">',$plan->extra_build_level);
        $out .= sprintf('<input type="hidden" name="body_id" value="%s">',$body_id);
        $out .= sprintf('<input type="submit" name="delete_one" value="Delete One">');
        $out .= sprintf('<input type="submit" name="delete_all" value="Delete All">');
        $out .= sprintf('</form>');
    }
    $out .= '<form method="post" action="/admin/add/plan"><tr>';
    $out .= '<input type="hidden" name="body_id" value="'.$body_id.'">';
    $out .= '<td><input name="level" value="1" size="2"></td>';
    $out .= '<td><select name="class">';
    my %buildings = map { $_->name => $_ } findallmod Lacuna::DB::Result::Building;
    foreach my $name (sort keys %buildings) {
        next if $name eq 'Building';
        $out .= '<option value="'.$buildings{$name}.'">'.$name.'</option>';
    }
    $out .= '</select></td>';
    $out .= '<td><input name="extra_build_level" value="0" size="2"></td>';
    $out .= '<td><input name="quantity" value="1" size="2"></td>';
    $out .= '<td><input type="submit" value="add plan"></td>';
    $out .= '</tr></form>';
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_add_plan {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->add_plan($request->param('class'), $request->param('level'), $request->param('extra_build_level'), $request->param('quantity'));
    return $self->www_view_plans($request, $body->id);
}

sub www_delete_plan {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    # Find a plan
    my ($plan) = grep {
            $_->level               == $request->param('level')
        and $_->class               eq $request->param('class')
        and $_->extra_build_level   == $request->param('extra')
    } @{$body->plan_cache};
    
    if (not defined $plan) {
        confess [404, 'Plan not found.'];
    }
    if ($request->param('delete_one')) {
        $body->delete_one_plan($plan);
    }
    if ($request->param('delete_all')) {
        $body->delete_many_plans($plan, $plan->quantity);
    }
    return $self->www_view_plans($request, $body->id);
}

sub www_recalc_body {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->update({needs_recalc=>1});
    return $self->wrap(sprintf('Done! <a href="/admin/view/body?id=%s">Back To Body</a>', $request->param('body_id')));
}

sub format_paginator {
    my ($self, $method, $key, $value, $page_number) = @_;
    my $out = '<fieldset><legend>Page: '.$page_number.'</legend>';
    $out .= '<a href="/admin/'.$method.'?'.$key.'='.$value.';page_number='.($page_number - 1).'">&lt; Previous</a> | ';
    $out .= '<a href="/admin/'.$method.'?'.$key.'='.$value.';page_number='.($page_number + 1).'">Next &gt;</a> ';
    $out .= '<form method="post" style="display: inline;" action="/admin/'.$method.'"><input name="page_number" value="'.$page_number.'" style="width: 30px;"><input type="hidden" name="'.$key.'" value="'.$value.'"><input type="submit" value="go"></form>';
    $out .= '</fieldset>';
    return $out;
}

sub www_delete_empire {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('empire_id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    unless ($empire->self_destruct_active) {
        if ($empire->id <= 1) {
            confess [400, 'That empire is required.'];
        }
    }
    $empire->delete;
    return $self->www_search_empires($request);
}

sub www_toggle_isolationist {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    if ($empire->is_isolationist) {
        $empire->update({is_isolationist => 0});
    }
    else {
        $empire->update({is_isolationist => 1});
    }
    return $self->www_view_empire($request, $id);
}

sub www_toggle_admin {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    if ($empire->is_admin) {
        $empire->update({is_admin => 0});
    }
    else {
        $empire->update({is_admin => 1});
    }
    return $self->www_view_empire($request, $id);
}

sub www_toggle_mission_curator {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    if ($empire->is_mission_curator) {
        $empire->update({is_mission_curator => 0});
    }
    else {
        $empire->update({is_mission_curator => 1});
    }
    return $self->www_view_empire($request, $id);
}

sub www_become_empire {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('empire_id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    my $uri = Lacuna->config->get('server_url');
    $uri .= '#session_id=%s';
    $uri = sprintf $uri, $empire->start_session({ api_key => 'admin_console' })->id;
    [$uri, { status => 302 } ]
}

sub www_view_empire {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    my $out = '<h1>Manage Empire</h1>';
    $out .= '<table style="width: 100%">';
    $out .= sprintf('<tr><th>Id</th><td>%s</td><td></td></tr>', $empire->id);
    $out .= sprintf('<tr><th>RPC Requests</th><td>%s</td><td></td></tr>', $empire->rpc_count);
    $out .= sprintf('<tr><th>Name</th><td>%s</td><td></td></tr>', $empire->name);
    $out .= sprintf('<tr><th>Email</th><td>%s</td><td></td></tr>', $empire->email);
    $out .= sprintf('<tr><th>Created</th><td>%s</td><td></td></tr>', $empire->date_created);
    $out .= sprintf('<tr><th>Stage</th><td>%s</td><td></td></tr>', $empire->stage);
    $out .= sprintf('<tr><th>Last Login</th><td>%s</td><td></td></tr>', $empire->last_login);
    $out .= sprintf('<tr><th>Essentia</th><td>%s</td><td><form method="post" style="display: inline" action="/admin/add/essentia">
<input type="hidden" name="id" value="%s">
<input name="amount" style="width: 30px;" value="0">
<input name="description" value="Administrative Privilege">
<input type="submit" value="add essentia"></form>', $empire->essentia, $empire->id); 
    $out .= sprintf('<a href="/admin/view/essentia/log?empire_id=%s">View Log</a></td></tr>',$empire->id);
    $out .= sprintf('<tr><th>Species</th><td>%s</td><td></td></tr>', $empire->species_name);
    $out .= sprintf('<tr><th>Home</th><td>%s</td><td></td></tr>', $empire->home_planet_id);
    $out .= sprintf('<tr><th>Description</th><td>%s</td><td></td></tr>', $empire->description);
    $out .= sprintf('<tr><th>University Level</th><td>%s</td><td><form method="post" style="display: inline" action="/admin/change/university/level"><input type="hidden" name="id" value="%s"><input name="university_level" style="width: 30px;" value="0"><input type="submit" value="change"></form></td></tr>', $empire->university_level, $empire->id);
    $out .= sprintf('<tr><th>Isolationist</th><td>%s</td><td><a href="/admin/toggle/isolationist?id=%s">Toggle</a></td></tr>', $empire->is_isolationist, $empire->id);
    $out .= sprintf('<tr><th>Admin</th><td>%s</td><td><a href="/admin/toggle/admin?id=%s">Toggle</a></td></tr>', $empire->is_admin, $empire->id);
    $out .= sprintf('<tr><th>Mission Curator</th><td>%s</td><td><a href="/admin/toggle/mission/curator?id=%s">Toggle</a></td></tr>', $empire->is_mission_curator, $empire->id);
    $out .= '</table><ul>';
    $out .= sprintf('<li><a href="/admin/become/empire?empire_id=%s">Become This Empire In-Game</a></li>', $empire->id);
    $out .= sprintf('<li><a href="/admin/search/bodies?empire_id=%s">View All Colonies</a></li>', $empire->id);
    $out .= sprintf('<li><a href="/admin/send/test/message?empire_id=%s">Send Developer Test Email</a></li>', $empire->id);
    $out .= sprintf('<li><a href="/admin/delete/empire?empire_id=%s" onclick="return confirm(\'Are you sure?\')">Delete Empire</a> (Be Careful)</li>', $empire->id);
    $out .= '</ul>';
    return $self->wrap($out);
}

sub www_view_body {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($id);
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    my $out = '<h1>Manage Body</h1>';
    $out .= '<table style="width: 100%">';
    $out .= sprintf('<tr><th>Id</th><td>%s</td><td></td></tr>', $body->id);
    $out .= sprintf('<tr><th>Class</th><td>%s</td><td></td></tr>', $body->class);
    $out .= sprintf('<tr><th>Name</th><td>%s</td><td></td></tr>', $body->name);
    $out .= sprintf('<tr><th>Zone</th><td>%s</td><td><a href="/admin/search/bodies?zone=%s">Bodies In This Zone</a></td></tr>', $body->zone, $body->zone);
    $out .= sprintf('<tr><th>X</th><td>%s</td><td></td></tr>', $body->x);
    $out .= sprintf('<tr><th>Y</th><td>%s</td><td></td></tr>', $body->y);
    $out .= sprintf('<tr><th>Orbit</th><td>%s</td><td></td></tr>', $body->orbit);
    $out .= sprintf('<tr><th>Happiness</th><td>%s</td><td><form method="post" style="display: inline" action="/admin/add/happiness"><input type="hidden" name="id" value="%s"><input name="amount" style="width: 30px;" value="0"><input type="submit" value="add happiness"></form></td></tr>', $body->happiness, $body->id);
    $out .= sprintf('<tr><th>Star</th><td><a href="/admin/view/star?id=%s">%s</a></td><td><a href="/admin/search/bodies?star_id=%s">Bodies Orbiting This Star</a></td></tr>', $body->star_id, $body->star_id, $body->star_id);
    $out .= sprintf('<tr><th>Empire</th><td><a href="/admin/view/empire?id=%s">%s</a></td><td></td></tr>', $body->empire_id, $body->empire_id);
    $out .= '</table><ul>';
    $out .= sprintf('<li><a href="/admin/view/resources?body_id=%s">View Resources</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/buildings?body_id=%s">View Buildings</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/fleets?body_id=%s">View Fleets</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/plans?body_id=%s">View Plans</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/glyphs?body_id=%s">View Glyphs</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/recalc/body?body_id=%s">Recalculate Body Stats</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/complete/builds?body_id=%s">Complete All Builds</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/send/stellar/flare?body_id=%s" onclick="return confirm(\'Are you sure?\')">Send Stellar Flare</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/send/meteor/shower?body_id=%s" onclick="return confirm(\'Are you sure?\')">Send Meteor Shower</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/send/pestilence?body_id=%s" onclick="return confirm(\'Are you sure?\')">Send Pestilence</a></li>', $body->id);
    $out .= '</ul>';
    return $self->wrap($out);
}

sub www_view_star {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($id);
    unless (defined $star) {
        confess [404, 'Star not found.'];
    }
    my $out = '<h1>Manage Star</h1>';
    $out .= '<table style="width: 100%">';
    $out .= sprintf('<tr><th>Id</th><td>%s</td><td></td></tr>', $star->id);
    $out .= sprintf('<tr><th>Color</th><td>%s</td><td></td></tr>', $star->color);
    $out .= sprintf('<tr><th>Name</th><td>%s</td><td></td></tr>', $star->name);
    $out .= sprintf('<tr><th>Zone</th><td>%s</td><td><a href="/admin/search/stars?zone=%s">Stars In This Zone</a></td></tr>', $star->zone, $star->zone);
    $out .= sprintf('<tr><th>X</th><td>%s</td><td></td></tr>', $star->x);
    $out .= sprintf('<tr><th>Y</th><td>%s</td><td></td></tr>', $star->y);
    $out .= '</table><ul>';
    $out .= sprintf('<li><a href="/admin/search/bodies?star_id=%s">Bodies Orbiting This Star</a></li>', $star->id);
    $out .= '</ul>';
    return $self->wrap($out);
}

sub www_add_essentia {
    my ($self, $request) = @_;
    my $id = $request->param('id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    $empire->add_essentia($request->param('amount'), $request->param('description'))->update;
    return $self->www_view_empire($request, $id);
}

sub www_change_university_level {
    my ($self, $request) = @_;
    my $id = $request->param('id');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    $empire->university_level($request->param('university_level'));
    $empire->update;
    return $self->www_view_empire($request, $id);
}

sub www_add_happiness {
    my ($self, $request) = @_;
    my $id = $request->param('id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($id);
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->add_happiness($request->param('amount'))->update;
    return $self->www_view_body($request, $id);
}


sub www_view_logs {
    my ($self, $request) = @_;
    my $list = '
    <a href="/admin/view/logs?file=request">Request</a>
    | <a href="/admin/view/logs?file=summary">Summary</a>
    | <a href="/admin/view/logs?file=weekmedals">Weekly Medals</a>
    ';
    my $log = 'Choose a log file.';
    given ($request->param('file')) {
        when ('request') {
            $log = `tail -50 /tmp/lacuna.log`;
        }
        when ('weekmedals') {
            $log = `tail -100 /tmp/weekly_medals.log`;
        }
        when ('summary') {
            $log = `tail -1000 /tmp/summarize_server.log`;
        }
    }
    my $file = '/tmp/lacuna.log';
    return $self->wrap($list.'<hr><pre>'.$log.'</pre>');
}

sub www_view_virality {
    my ($self, $request) = @_;
    my $out = '<h1>Virality</h1>';

    my (@accepts, @abandons, @creates, @invites, @dates, @deletes, @users, @stay, @vc, @gr, @cr, $previous, $max_viral, $max_change, $max_users, $max_stay);
    my $past30 = Lacuna->db->resultset('Lacuna::DB::Result::Log::Viral')->search({date_stamp => { '>=' => DateTime->now->subtract(days => 31)}}, { order_by => 'date_stamp'});
    while (my $day = $past30->next) {
        unless (defined $previous) {
            $previous = $day;
            next;
        }
        push @dates, $day->date_stamp->month.'/'.$day->date_stamp->day;
        
        # users chart
        push @users, $day->total_users;
        $max_users = $users[-1] if ($max_users < $users[-1]);
        
        # stay chart
        push @stay, $day->active_duration / (60 * 60 * 24);
        $max_stay = $stay[-1] if ($max_stay < $stay[-1]);
        
        # viral chart
        push @vc, sprintf('%.0f', ($day->accepts / $previous->total_users) * 100);
        $max_viral = $vc[-1] if ($max_viral < $vc[-1]);
        push @gr, sprintf('%.0f', (($day->total_users - $previous->total_users) / $previous->total_users) * 100);
        $max_viral = $gr[-1] if ($max_viral < $gr[-1]);
        push @cr, sprintf('%.0f', ($day->deletes / $previous->total_users) * 100);
        $max_viral = $cr[-1] if ($max_viral < $cr[-1]);
        
        # change chart
        push @accepts, $day->accepts;
        $max_change = $accepts[-1] if ($max_change < $accepts[-1]);
        push @deletes, $day->deletes;
        $max_change = $deletes[-1] if ($max_change < $deletes[-1]);
        push @invites, $day->invites;
        $max_change = $invites[-1] if ($max_change < $invites[-1]);
        push @creates, $day->creates;
        $max_change = $creates[-1] if ($max_change < $creates[-1]);
        push @abandons, $day->abandons;
        $max_change = $abandons[-1] if ($max_change < $abandons[-1]);
        
        $previous = $day;
    }
    
    my $users_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_users
        .'&chxt=x,y&chds=0,'.$max_users
        .'&chdl=Users&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3&chxtc=1,-900&chs=900x300&cht=ls&chco=ffffff&chd=t:'
        .join(',', @users)
        .'&chxl='
        .join('|', '0:', @dates);

    my $stay_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_stay
        .'&chxt=x,y&chds=0,'.$max_stay.',0,'.$max_stay
        .'&chdl=Days|Deletes&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3&chxtc=1,-900&chs=900x300&cht=ls&chco=ffffff,000000&chd=t:'
        .join('|',
            join(',', @stay),
            join(',', @deletes),
        )
        .'&chxl='
        .join('|', '0:', @dates);

    my $viral_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_viral
        .'&chxt=x,y&chds=0,'.$max_viral.',0,'.$max_viral.',0,'.$max_viral
        .'&chdl=Viral%20Coefficient|Growth%20Rate|Churn%20Rate&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3|3&chxtc=1,-900&chs=900x300&cht=ls&chco=00ff00,ffb400,b400ff&chd=t:'
        .join('|',
            join(',', @vc),
            join(',', @gr),
            join(',', @cr),
        )
        .'&chxl='
        .join('|', '0:', @dates);

    my $change_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_change
        .'&chxt=x,y&chds=0,'.$max_change.',0,'.$max_change.',0,'.$max_change.',0,'.$max_change.',0,'.$max_change
        .'&chdl=Invites|Accepts|Creates|Deletes|Abandons&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3|3|3|3&chxtc=1,-900&chs=900x300&cht=ls&chco=ff8888,88ff88,8888ff,ff88ff,000000&chd=t:'
        .join('|',
            join(',', @invites),
            join(',', @accepts),
            join(',', @creates),
            join(',', @deletes),
            join(',', @abandons),
        )
        .'&chxl='
        .join('|', '0:', @dates);
    
    my $avg_vc = sprintf('%.2f', sum(@vc) / 100 / scalar(@vc));
    my $avg_gr = sprintf('%.2f', sum(@gr) / 100 / scalar(@gr));
    my $avg_cr = sprintf('%.2f', sum(@cr) / 100 / scalar(@cr));

    $out .= '
        <div style="text-align: center;">
        <div style="margin: 10px; text-align: center; float: left; border: 3px solid #00ff00;">
            <span style="font-size: 12px;">Viral Coefficient</span><br>
            <span style="font-size: 100px;">'.$avg_vc.'</span>
        </div>
        
        <div style="margin: 10px; text-align: center; float: left; border: 3px solid #ffb400;">
            <span style="font-size: 12px;">Growth Rate</span><br>
            <span style="font-size: 100px;">'.$avg_gr.'</span>
        </div>

        <div style="margin: 10px;text-align: center; float: left; border: 3px solid #b400ff;">
            <span style="font-size: 12px;">Churn Rate</span><br>
            <span style="font-size: 100px;">'.$avg_cr.'</span>
        </div>
        <div style="clear: both"></div>
        <img src="'.$viral_chart.'" alt="viral chart">
        
        <br>
        <h2>Change</h2>
        <img src="'.$change_chart.'" alt="change chart">
        
        <br>
        <h2>Total Users</h2>
        <img src="'.$users_chart.'" alt="users chart">
        
        <br>
        <h2>Stay</h2>
        <img src="'.$stay_chart.'" alt="users chart">
        
        </div>
    ';
    
    return $self->wrap($out);
}


sub www_view_economy {
    my ($self, $request) = @_;
    my $out = '<h1>Economy</h1>';

    my (@dates, $previous, @arpu, $max_purchases, @p30, @p100, @p200, @p600, @p1300, $max_revenue, @revenue, @r30, @r100, @r200, @r600, @r1300);
    my ($max_out, @out_boost, @out_mission, @out_recycle, @out_ship, @out_spy, @out_glyph, @out_party, @out_building, @out_trade, @out_delete, @out_other);        
    my ($max_in, @in_mission, @in_purchase, @in_trade, @in_redemption, @in_vein, @in_vote, @in_tutorial, @in_other);
    my $past30 = Lacuna->db->resultset('Lacuna::DB::Result::Log::Economy')->search({date_stamp => { '>=' => DateTime->now->subtract(days => 31)}}, { order_by => 'date_stamp'});
    while (my $day = $past30->next) {
        unless (defined $previous) {
            $previous = $day;
            next;
        }
        push @dates, $day->date_stamp->month.'/'.$day->date_stamp->day;

        # average revenue per user
        if ($day->total_users) {
            push @arpu, ((
                ($day->purchases_30 * 3) +
                ($day->purchases_100 * 6) +
                ($day->purchases_200 * 10) +
                ($day->purchases_600 * 25) +
                ($day->purchases_1300 + 50)
                ) / $day->total_users);
        }
        else {
            push @arpu, 0;
        }

        # purchases chart
        push @p30, $day->purchases_30;
        my $sum_purchases = $day->purchases_30;
        push @p100, $day->purchases_100;
        $sum_purchases += $day->purchases_100;
        push @p200, $day->purchases_200;
        $sum_purchases += $day->purchases_200;
        push @p600, $day->purchases_600;
        $sum_purchases += $day->purchases_600;
        push @p1300, $day->purchases_1300;
        $sum_purchases += $day->purchases_1300;
        $max_purchases = $sum_purchases if ($max_purchases < $sum_purchases);

        # revenue chart
        push @r30, $day->purchases_30 * 3;
        my $sum_revenue = $day->purchases_30 *3;
        push @r100, $day->purchases_100 * 6;
        $sum_revenue += $day->purchases_100 *6;
        push @r200, $day->purchases_200 * 10;
        $sum_revenue += $day->purchases_200 * 10;
        push @r600, $day->purchases_600 * 25;
        $sum_revenue += $day->purchases_600 * 25;
        push @r1300, $day->purchases_1300 * 50;
        $sum_revenue += $day->purchases_1300 * 50;
        push @revenue, $sum_revenue;
        $max_revenue = $sum_revenue if ($max_revenue < $sum_revenue);

        # in chart
        push @in_purchase, $day->in_purchase;
        my $sum_in = $in_purchase[-1];
        push @in_trade, $day->in_trade;
        $sum_in += $in_trade[-1];
        push @in_redemption, $day->in_redemption;
        $sum_in += $in_redemption[-1];
        push @in_vein, $day->in_vein;
        $sum_in += $in_vein[-1];
        push @in_vote, $day->in_vote;
        $sum_in += $in_vote[-1];
        push @in_tutorial, $day->in_tutorial;
        $sum_in += $in_tutorial[-1];
        push @in_mission, $day->in_mission;
        $sum_in += $in_mission[-1];
        push @in_other, $day->in_other;
        $sum_in += $in_other[-1];
        $max_in = $sum_in if ($max_in < $sum_in);

        # out chart
        push @out_boost, $day->out_boost;
        my $sum_out = $out_boost[-1];
        push @out_recycle, $day->out_recycle;
        $sum_out += $out_recycle[-1];
        push @out_ship, $day->out_ship;
        $sum_out += $out_ship[-1];
        push @out_spy, $day->out_spy;
        $sum_out += $out_spy[-1];
        push @out_glyph, $day->out_glyph;
        $sum_out += $out_glyph[-1];
        push @out_party, $day->out_party;
        $sum_out += $out_party[-1];
        push @out_building, $day->out_building;
        $sum_out += $out_building[-1];
        push @out_trade, $day->out_trade;
        $sum_out += $out_trade[-1];
        push @out_delete, $day->out_delete;
        $sum_out += $out_delete[-1];
        push @out_mission, $day->out_mission;
        $sum_out += $out_mission[-1];
        push @out_other, $day->out_other;        
        $sum_out += $out_other[-1];
        $max_out = $sum_out if ($max_out < $sum_out);

    }
    
    my $in_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_in
        .'&chxt=x,y&chds=0,'.$max_in.',0,'.$max_in.',0,'.$max_in.',0,'.$max_in.',0,'.$max_in.',0,'.$max_in.',0,'.$max_in.',0,'.$max_in
        .'&chdl=Purchased|Trade|Redemption|Vein|Vote|Tutorial|Mission|Other&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3|3|3|3|3|3|3&chxtc=1,-900&chs=900x300'
        .'&cht=bvs&chco=00b4ff,00ff00,009900,ffff00,ff7700,b400ff,ffaaff,ff0000&chd=t:'
        .join('|',
            join(',', @in_purchase),
            join(',', @in_trade),
            join(',', @in_redemption),
            join(',', @in_vein),
            join(',', @in_vote),
            join(',', @in_tutorial),
            join(',', @in_mission),
            join(',', @in_other),
        )
        .'&chxl='
        .join('|', '0:', @dates);

    my $out_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_out
        .'&chxt=x,y&chds=0,'.$max_out.',0,'.$max_out.',0,'.$max_out.',0,'.$max_out.',0,'.$max_out.',0,'.$max_out.',0,'.$max_out.',0,'.$max_out.',0,'.$max_out.',0,'.$max_out.',0,'.$max_out
        .'&chdl=Boosts|Recyling|Ships|Spies|Glyphs|Parties|Construction|Trade|Mission|Delete|Other&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3|3|3|3|3|3|3|3|3|3&chxtc=1,-900&chs=900x300'
        .'&cht=bvs&chco=00b4ff,00ff00,009900,ffff00,ff7700,ff0000,ffaaff,b400ff,ffffff,999999,000000&chd=t:'
        .join('|',
            join(',', @out_boost),
            join(',', @out_recycle),
            join(',', @out_ship),
            join(',', @out_spy),
            join(',', @out_glyph),
            join(',', @out_party),
            join(',', @out_building),
            join(',', @out_trade),
            join(',', @out_mission),
            join(',', @out_delete),
            join(',', @out_other),
        )
        .'&chxl='
        .join('|', '0:', @dates);

    my $revenue_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_revenue
        .'&chxt=x,y&chds=0,'.$max_revenue.',0,'.$max_revenue.',0,'.$max_revenue.',0,'.$max_revenue.',0,'.$max_revenue
        .'&chdl=$3|$6|$10|$25|$50&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3|3|3|3'
        .'&chxtc=1,-900&chs=900x300&cht=bvs&chco=00ff00,ffb400,b400ff,00b4ff,ff0000&chd=t:'
        .join('|',
            join(',', @r30),
            join(',', @r100),
            join(',', @r200),
            join(',', @r600),
            join(',', @r1300),
        )
        .'&chxl='
        .join('|', '0:', @dates);

    my $purchases_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_purchases
        .'&chxt=x,y&chds=0,'.$max_purchases.',0,'.$max_purchases.',0,'.$max_purchases.',0,'.$max_purchases.',0,'.$max_purchases
        .'&chdl=30|100|200|600|1300&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3|3|3|3&chxtc=1,-900&chs=900x300&cht=bvs&chco=00ff00,ffb400,b400ff,00b4ff,ff0000&chd=t:'
        .join('|',
            join(',', @p30),
            join(',', @p100),
            join(',', @p200),
            join(',', @p600),
            join(',', @p1300),
        )
        .'&chxl='
        .join('|', '0:', @dates);

    my $arpu_chart = 'http://chart.apis.google.com/chart?chxr=1,0,1'
        .'&chxt=x,y&chds=0,1'
        .'&chdl=Dollars&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3&chxtc=1,-900&chs=900x300&cht=ls&chco=ffffff&chd=t:'
        .join(',', @arpu)
        .'&chxl='
        .join('|', '0:', @dates);

    $out .= '
        <div style="text-align: center;">

        <h2>Revenue</h2>
        <img src="'.$revenue_chart.'" alt="revenue chart">
        <br>
        
        <h2>User Purchases</h2>
        <img src="'.$purchases_chart.'" alt="purchases chart">
        <br>
        
        <h2>Average Revenue Per User</h2>
        <img src="'.$arpu_chart.'" alt="arpu chart">
        <br>
        
        <h2>Essentia Spent</h2>
        <img src="'.$out_chart.'" alt="out chart">
        <br>
        
        <h2>Essentia Earned</h2>
        <img src="'.$in_chart.'" alt="in chart">
        <br>
        
        </div>
    ';
    
    return $self->wrap($out);
}

sub www_default {
    my ($self, $request) = @_;
    my $announcement = Lacuna->cache->get('announcement','message');
    $announcement =~ s/\>/&gt;/xmsg;
    $announcement =~ s/\</&lt;/xmsg;
    return $self->wrap('<h1>Lacuna Expanse Admin Console</h1>
            Server Version: '.Lacuna->version.'
        <ul>
        <li><a href="/">Play Game</a></li>
        <li><a href="/api/">API</a></li>
        <li><a href="http://www.lacunaexpanse.com/">Lacuna Web Site</a></li>
        </ul>
        
        <fieldset><legend>Announcement</legend>
        <form method="post" action="/admin/change/announcement">
        <textarea name="message" rows="10" cols="80">'.$announcement.'</textarea><br>
        <input type="submit" name="change">
        </form>
        <p>Announcements last for 24 hours. HTML head and body are provided, you just need to type the content. Make sure links target "_new".</p>
        <a href="/admin/delete/announcement">Delete this announcement.</a>
        </fieldset>

        <fieldset><legend>Server Utilities</legend>
        <ul>
            <li><a href="/admin/server/wide/recalc">Force Server Wide Recalc Of Planets</a></li>
        </ul>
        </fieldset>
        ');
}

sub www_change_announcement {
    my ($self, $request) = @_;
    my $cache = Lacuna->cache;
    $cache->set('announcement','alert', create_uuid_as_string(UUID_V4), 60*60*24);
    $cache->set('announcement','message', $request->param('message'), 60*60*24);
    return $self->wrap('Announcement saved.');
}

sub www_delete_announcement {
    my ($self, $request) = @_;
    my $cache = Lacuna->cache;
    $cache->delete('announcement','alert');
    $cache->delete('announcement','message');
    return $self->wrap('Announcement deleted.');
}


sub www_server_wide_recalc {
    my ($self, $request) = @_;
    Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({empire_id => {'>', 0}})->update({needs_recalc=>1});
    return $self->wrap('Done!');
}

sub www_delambert {
    my ($self, $request) = @_;

    my ($scratch) = Lacuna->db->resultset('Lacuna::DB::Result::AIScratchPad')->search({ai_empire_id => -9, body_id => 0});
    my $scratchpad = $scratch->pad;

    if ($request->param('submit')) {
        $scratchpad->{status} = lc $request->param('status') eq 'war' ? 'war' : 'peace';
        $scratchpad->{buy_max_price_per_plan}    = $request->param('buy_max_price_per_plan');
        $scratchpad->{buy_trades_probability}    = $request->param('buy_trades_probability');
        $scratchpad->{sell_glyph_probability}    = $request->param('sell_glyph_probability');
        $scratchpad->{sell_glyph_type}           = $request->param('sell_glyph_type');
        $scratchpad->{sell_glyph_min_e}          = $request->param('sell_glyph_min_e');
        $scratchpad->{sell_glyph_max_e}          = $request->param('sell_glyph_max_e');
        $scratchpad->{sell_glyph_max_batch}      = $request->param('sell_glyph_max_batch');
        $scratchpad->{sell_plan_probability}     = $request->param('sell_plan_probability');
        $scratchpad->{sell_plan_min_level}       = $request->param('sell_plan_min_level');
        $scratchpad->{sell_plan_max_level}       = $request->param('sell_plan_max_level');
        $scratchpad->{sell_plan_max_batch}       = $request->param('sell_plan_max_batch');
        $scratchpad->{sell_plan_min_hall_factor} = $request->param('sell_plan_min_hall_factor');
        $scratchpad->{sell_plan_max_hall_factor} = $request->param('sell_plan_max_hall_factor');
        $scratchpad->{sell_max_glyph_trades_in_zone}   = $request->param('sell_max_glyph_trades_in_zone');
        $scratchpad->{sell_max_plan_trades_in_zone}   = $request->param('sell_max_plan_trades_in_zone');
        $scratch->pad($scratchpad);
        $scratch->update;
    }   
    my $out = ''; 
    my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({
            empire_id => -9,
        },
        {
            order_by => ['name'],
        });
    $out   .= '<h1>DeLamberti</h1>';
    $out   .= '<form method="post" action="/admin/delambert"><table>';
    $out   .= '<tr><td><b>Status</b></td><td><input name="status" value="'.$scratchpad->{status}.'"></td></tr>';
    $out   .= '<tr><td><b>Max Plan Buy Price</b></td><td><input name="buy_max_price_per_plan" value="'.$scratchpad->{buy_max_price_per_plan}.'"></td></tr>';
    $out   .= '<tr><td><b>Probability of Colony Buying each hour (100=100%)</b></td><td><input name="buy_trades_probability" value="'.$scratchpad->{buy_trades_probability}.'"></td></tr>';
    $out   .= '<tr><td><b>Probability of Colony selling glyphs each hour (%)</b></td><td><input name="sell_glyph_probability" value="'.$scratchpad->{sell_glyph_probability}.'"></td></tr>';
    $out   .= '<tr><td><b>Minimum selling price per glyph</b></td><td><input name="sell_glyph_min_e" value="'.$scratchpad->{sell_glyph_min_e}.'"></td></tr>';
    $out   .= '<tr><td><b>Maximum selling price per glyph</b></td><td><input name="sell_glyph_max_e" value="'.$scratchpad->{sell_glyph_max_e}.'"></td></tr>';
    $out   .= '<tr><td><b>Maximum number of glyphs to batch in sale</b></td><td><input name="sell_glyph_max_batch" value="'.$scratchpad->{sell_glyph_max_batch}.'"></td></tr>';
    $out   .= '<tr><td><b>Glyphs to sell, comma separate</b></td><td><input name="sell_glyph_type" value="'.$scratchpad->{sell_glyph_type}.'"></td></tr>';
    $out   .= '<tr><td><b>Probability of Colony selling plans each hour (%)</b></td><td><input name="sell_plan_probability" value="'.$scratchpad->{sell_plan_probability}.'"></td></tr>';
    $out   .= '<tr><td><b>Minimum plan level to sell</b></td><td><input name="sell_plan_min_level" value="'.$scratchpad->{sell_plan_min_level}.'"></td></tr>';
    $out   .= '<tr><td><b>Maximum plan level to sell</b></td><td><input name="sell_plan_max_level" value="'.$scratchpad->{sell_plan_max_level}.'"></td></tr>';
    $out   .= '<tr><td><b>Maximum number of plans to batch is sale</b></td><td><input name="sell_plan_max_batch" value="'.$scratchpad->{sell_plan_max_batch}.'"></td></tr>';
    $out   .= '<tr><td><b>Minimum Hall equivalent costing factor</b></td><td><input name="sell_plan_min_hall_factor" value="'.$scratchpad->{sell_plan_min_hall_factor}.'"></td></tr>';
    $out   .= '<tr><td><b>Maximum Hall equivalent costing factor</b></td><td><input name="sell_plan_max_hall_factor" value="'.$scratchpad->{sell_plan_max_hall_factor}.'"></td></tr>';
    $out   .= '<tr><td><b>Maximum sell glyph trades in any one zone</b></td><td><input name="sell_max_glyph_trades_in_zone" value="'.$scratchpad->{sell_max_glyph_trades_in_zone}.'"></td></tr>';
    $out   .= '<tr><td><b>Maximum sell plan trades in any one zone</b></td><td><input name="sell_max_plan_trades_in_zone" value="'.$scratchpad->{sell_max_plan_trades_in_zone}.'"></td></tr>';
    $out   .= '<tr><td><input type="submit" name="submit" value="submit"></td><td>&nbsp;</td></tr></table></form>';
    $out   .= '<p><a href="/admin/delambert_war">War Status</a></p>';


    $out   .= '<h2>DeLamberti Colonies</h2>';
    $out   .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Zone</th></tr>';
    while (my $body = $bodies->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/body?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $body->id, $body->id, $body->name, $body->x, $body->y, $body->zone);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_delambert_war {
    my ($self, $request) = @_;

    my ($scratch) = Lacuna->db->resultset('Lacuna::DB::Result::AIScratchPad')->search({ai_empire_id => -9, body_id => 0});
    my $scratchpad = $scratch->pad;

    if ($request->param('submit')) {
        $scratchpad->{attack}{$request->param('attacker_id')} = {
            sweepers    => $request->param('sweepers'),
            scows       => $request->param('scows'),
            snarks      => $request->param('snarks'),
            colony_id   => $request->param('colony_id'),
            frequency   => $request->param('frequency'),
        };
        $scratch->pad($scratchpad);
        $scratch->update;
    }

    my $out = '';
    $out .= "<h1>DeLamberti war status</h1>\n";
    my @ai_defence = Lacuna->db->resultset('Lacuna::DB::Result::AIBattleSummary')->search({
        defending_empire_id => -9,
    });
    my @ai_attack = Lacuna->db->resultset('Lacuna::DB::Result::AIBattleSummary')->search({
        attacking_empire_id => -9,
    });
    # If the AI is attacked, we don't care who won or lost, just that there was an action against the AI
    my %defence = map {
        $_->attacking_empire_id => {
            attack_victories    => $_->attack_victories,
            defense_victories   => $_->defense_victories,
            attack_spy_hours    => $_->attack_spy_hours,
            weight              => $_->attack_victories + $_->defense_victories + $_->attack_spy_hours * 2,
        }
    } @ai_defence;

    # If the AI attacks, we just care about when the AI wins the attack
    my %attack  = map { 
        $_->defending_empire_id => {
            attack_victories    => $_->attack_victories,
            defense_victories   => $_->defense_victories,
            attack_spy_hours    => $_->attack_spy_hours,
            weight              => ($_->attack_victories / 2) + $_->attack_spy_hours,
        }
    } @ai_attack;

    # Sort the attackers so that those who have done the most un-retaliated damage are shown first
    my @worst_attackers = sort {( $defence{$a}{weight} - defined $attack{$a} ? $attack{$a}{weight} : 0) <=> ( $defence{$b}{weight} - defined $attack{$b} ? $attack{$b}{weight} : 0 ) } keys %defence;

    $out .= "<table border='1'><tr><th>Attacker</th><th>A-Victories</th><th>A-Defeats</th><th>A-Spy Hours</th><th>Attack Weight</th><th>R-Victories</th><th>R-Defeats</th><th>R-Spy Hours</th><th>Retaliate Weight</th><th>Colony</th><th>Frequency</th><th>Attack Sweepers</th><th>Attack Scows</th><th>Attack Snark</th><th>Action</th></tr>\n";
ATTACKER:
    foreach my $attacker (@worst_attackers) {
        my $attack_empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($attacker);
        next ATTACKER unless $attack_empire;

        # Obtain all colonies of the attacking empire, sorted by population desc.
        my @colonies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({
            empire_id       => $attacker,
        });
        @colonies = sort {$b->population <=> $a->population} @colonies;

        if (not defined $scratchpad->{attack}{$attacker}) {
            $scratchpad->{attack}{$attacker} = {
                colony_id   => $colonies[0]->id,
                sweepers    => 1000,
                snarks      => 200,
                scows       => 200,
                frequency   => 'Once',
            };
            $scratch->pad($scratchpad);
            $scratch->update;
        }

        my $sweepers    = $scratchpad->{attack}{$attacker}{sweepers};
        my $snarks      = $scratchpad->{attack}{$attacker}{snarks};
        my $scows       = $scratchpad->{attack}{$attacker}{scows};
        my $frequency   = $scratchpad->{attack}{$attacker}{frequency};
        my $counter = {attack_victories=>0, defense_victories=>0, attack_spy_hours=>0, weight=>0};
        if (defined $attack{$attacker}) {
            $counter = {
                attack_victories  => $attack{$attacker}{attack_victories},
                defense_victories => $attack{$attacker}{defense_victories},
                attack_spy_hours  => $attack{$attacker}{attack_spy_hours},
                weight            => $attack{$attacker}{weight},
            };
        }
        $out .= "<tr><td>".$attack_empire->name."</td><td>".$defence{$attacker}{attack_victories}."</td><td>".$defence{$attacker}{defense_victories}."</td>";
        $out .= "<td>".$defence{$attacker}{attack_spy_hours}."</td><td>".$defence{$attacker}{weight}."</td>";
        $out .= "<td>".$counter->{attack_victories}."</td><td>".$counter->{defense_victories}."</td>";
        $out .= "<td>".$counter->{attack_spy_hours}."</td><td>".$counter->{weight}."</td>";
        $out .= "<form action='/admin/delambert_war'>";
        $out .= "<td><select name='colony_id'>";
        foreach my $colony (@colonies) {
            my $selected = ' selected ' if $colony->id == $scratchpad->{attack}{$attacker}{colony_id};
            $out .= "<option value='".$colony->id."' $selected>".$colony->name."</option>";
        }
        $out .= "</select></td>";
        $out .= "<td><select name='frequency'>";
        foreach my $freq (qw(never once hourly daily)) {
            my $selected = ' selected ' if $scratchpad->{attack}{$attacker}{frequency} eq $freq;
            $out .= "<option value='$freq' $selected>$freq</option>";
        }
        $out .= "</select></td>";
        $out .= "<td><input type='text' name='sweepers' value='$sweepers'></td>";
        $out .= "<input type='hidden' name='attacker_id' value='$attacker'>";
        $out .= "<td><input type='text' name='scows' value='$scows'></td>";
        $out .= "<td><input type='text' name='snarks' value='$snarks'></td>";
        $out .= "<td><input type='submit' name='submit' value='Submit'></form></tr>";
    }
    $out .= "</table>\n";
    $out .= "<ul>\n";
    $out .= "<li>A-Victories, A-Defeats and A-Spy hours are attacks against the DeLamberti</li>";
    $out .= "<li>R-Victories, R-Defeats and R-Spy hours are retaliations by the DeLamberti</li>";
    $out .= "<li>Attack Weight, is a measure of the amount of attacks against the AI</li>";
    $out .= "<li>Retaliate Weight, is a measure of the AI Retaliation against those attacks</li>";
    $out .= "<li>The list is sorted so that those empires with the highest (Attack Weight - Retaliate Weight) are first</li>";
    $out .= "</ul>\n";


    return $self->wrap($out);
}

sub wrap {
    my ($self, $content) = @_;
    return $self->wrapper('<div style="width: 150px;">
    <ul class="admin_menu">
    <li><a href="/admin/search/empires">Empires</a></li>
    <li><a href="/admin/search/bodies">Bodies</a></li>
    <li><a href="/admin/search/stars">Stars</a></li>
    <li><a href="/admin/search/essentia/codes">Essentia Codes</a></li>
    <li><a href="/admin/view/virality">Virality</a></li>
    <li><a href="/admin/view/economy">Economy</a></li>
    <li><a href="/admin/view/logs">Logs</a></li>
    <li><a href="/admin/delambert">DeLamberti</a></li>
    <li><a href="/admin/default">Home</a></li>
    </ul>
    </div>
    <div style="position: absolute; top: 0; left: 160px; min-width: 600px; margin: 5px;">
    <div>'. $content .' </div></div>',
    { title => 'Admin Console'}
    );
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

