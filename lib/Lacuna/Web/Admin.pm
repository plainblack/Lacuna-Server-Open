package Lacuna::Web::Admin;

use Moose;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use feature "switch";
use Module::Find;
use UUID::Tiny;
use Lacuna::Util qw(format_date);
use List::Util qw(sum);


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
	from		=> $empire,
	body		=> 'This is a test message that contains all the components possible in a message.
     {food} {water} {ore} {energy} {waste} {happiness} {essentia} {build} {time}
    {Empire 1 Lacuna Expanse Corp}
    [http://www.lacunaexpanse.com]
    ',
	subject		=> 'Test Message',
	tags		=> ['Alert'],
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
    $out .= '<form action="/admin/search/essentia/codes"><input name="code" value="'.$code.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Code</th><th>Amount</th><th>Description</th><th>Date Created</th><td>Used</td><th>Action</th></tr>';
    while (my $code = $codes->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td></td></tr>', $code->id, $code->code, $code->amount, $code->description, $code->date_created, $code->used);
    }
    $out .= '<form action="/admin/add/essentia/code"><tr>';
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
        code            => create_UUID_as_string(UUID_V4),
    })->insert;
    return $self->wrap('<p>Essentia Code: '. $code->code.'</p><p><a href="/admin/search/essentia/codes">Back To Essentia Codes</a></a>');
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
    $out .= '<form action="/admin/search/empires"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
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
    $out .= '<form action="/admin/search/bodies"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Zone</th><th>Star</th><th>Empire</th></tr>';
    while (my $body = $bodies->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/body?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><a href="/admin/view/empire?id=%s">%s</a></td></tr>', $body->id, $body->id, $body->name, $body->x, $body->y, $body->zone, $body->star_id, $body->empire_id || '', $body->empire_id || '');
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
    $out .= '<form action="/admin/search/stars"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Zone</th></tr>';
    while (my $star = $stars->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/star?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $star->id, $star->id, $star->name, $star->x, $star->y, $star->zone);
    }
    $out .= '</table>';
    $out .= $self->format_paginator('search/stars', 'name', $name, $page_number);
    return $self->wrap($out);
}

my @infrastructure = (
    'Lacuna::DB::Result::Building::Archaeology',
    'Lacuna::DB::Result::Building::Development',
    'Lacuna::DB::Result::Building::Embassy',
    'Lacuna::DB::Result::Building::EntertainmentDistrict',
    'Lacuna::DB::Result::Building::Espionage',
    'Lacuna::DB::Result::Building::GasGiantLab',
    'Lacuna::DB::Result::Building::GeneticsLab',
    'Lacuna::DB::Result::Building::Intelligence',
    'Lacuna::DB::Result::Building::Network19',
    'Lacuna::DB::Result::Building::Observatory',
    'Lacuna::DB::Result::Building::Oversight',
    'Lacuna::DB::Result::Building::Park',
    'Lacuna::DB::Result::Building::Propulsion',
    'Lacuna::DB::Result::Building::Security',
    'Lacuna::DB::Result::Building::Shipyard',
    'Lacuna::DB::Result::Building::SpacePort',
    'Lacuna::DB::Result::Building::TerraformingLab',
    'Lacuna::DB::Result::Building::Trade',
    'Lacuna::DB::Result::Building::Transporter',
    'Lacuna::DB::Result::Building::University',
    'Lacuna::DB::Result::Building::Waste::Recycling',
    'Lacuna::DB::Result::Building::Waste::Sequestration',
);

sub www_send_stellar_flare {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    my $buildings = $body->buildings->search({ class => { in => \@infrastructure }});
    while (my $building = $buildings->next) {
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
    my $buildings = $body->buildings->search({ class => { in => \@infrastructure }});
    while (my $building = $buildings->next) {
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
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Level</th><th>Efficiency</th></tr>';
    while (my $building = $buildings->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><form action="/admin/set/efficiency"><td><input type="hidden" name="building_id" value="%s"><input name="efficiency" type="text" size="3" value="%s"><input type="submit" value="submit"></td></form></tr>', $building->id, $building->name, $building->x, $building->y, $building->level, $building->id, $building->efficiency);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_set_efficiency {
    my ($self, $request) = @_;
    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($request->param('building_id'));
    $building->update({efficiency => $request->param('efficiency')});
    return $self->www_view_buildings($request, $building->body_id);
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
        $out .= sprintf('<tr><td>%s</td><td>%s</td><form action="/admin/add/resources"><td><input name="amount"><input type="submit" value="add"><input type="hidden" name="body_id" value="%s"><input type="hidden" name="resource" value="%s"</td></form></tr>', $resource, $body->type_stored($resource), $body_id, $resource);
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
    my $glyphs = Lacuna->db->resultset('Lacuna::DB::Result::Glyphs')->search({ body_id => $body_id }, {order_by => ['type'] });
    my $out = '<h1>View Glyphs</h1>';
    $out .= sprintf('<a href="/admin/view/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Type</th><th>Action</th></tr>';
    while (my $glyph = $glyphs->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td><a href="/admin/delete/glyph?body_id=%s&glyph_id=%s">Delete</a></td></tr>', $glyph->id, $glyph->type, $body_id, $glyph->id);
    }
    $out .= '<form action="/admin/add/glyph"><tr>';
    $out .= '<td><input type="hidden" name="body_id" value="'.$body_id.'"></td>';
    $out .= '<td><select name="type">';
    foreach my $name (ORE_TYPES) {
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
    my $plans = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->search({ body_id => $body_id }, {order_by => ['class'] });
    my $out = '<h1>View Plans</h1>';
    $out .= sprintf('<a href="/admin/view/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Level</th><th>Name</th><th>Extra Build Level</th><th>Action</th></tr>';
    while (my $plan = $plans->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><a href="/admin/delete/plan?body_id=%s&plan_id=%s">Delete</a></td></tr>', $plan->id, $plan->level, $plan->class->name, $plan->extra_build_level, $body_id, $plan->id);
    }
    $out .= '<form action="/admin/add/plan"><tr>';
    $out .= '<td><input type="hidden" name="body_id" value="'.$body_id.'"></td>';
    $out .= '<td><input name="level" value="1" size="2"></td>';
    $out .= '<td><select name="class">';
    my %buildings = map { $_->name => $_ } findallmod Lacuna::DB::Result::Building;
    foreach my $name (sort keys %buildings) {
        next if $name eq 'Building';
        $out .= '<option value="'.$buildings{$name}.'">'.$name.'</option>';
    }
    $out .= '</select></td>';
    $out .= '<td><input name="extra_build_level" value="0" size="2"></td>';
    $out .= '<td><input type="submit" value="add plan"></td>';
    $out .= '</tr></form>';
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_add_plan {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->add_plan($request->param('class'), $request->param('level'), $request->param('extra_build_level'));
    return $self->www_view_plans($request, $body->id);
}

sub www_delete_plan {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->plans->find($request->param('plan_id'))->delete;
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
    $out .= '<form style="display: inline;" action="/admin/'.$method.'"><input name="page_number" value="'.$page_number.'" style="width: 30px;"><input type="hidden" name="'.$key.'" value="'.$value.'"><input type="submit" value="go"></form>';
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
    if ($empire->id <= 1) {
        confess [400, 'That empire is required.'];
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
    $out .= sprintf('<tr><th>RPC Requests</th><td>%s</td><td></td></tr>', Lacuna->cache->get('rpc_count_'.format_date(undef,'%d'),$empire->id));
    $out .= sprintf('<tr><th>Name</th><td>%s</td><td></td></tr>', $empire->name);
    $out .= sprintf('<tr><th>Created</th><td>%s</td><td></td></tr>', $empire->date_created);
    $out .= sprintf('<tr><th>Stage</th><td>%s</td><td></td></tr>', $empire->stage);
    $out .= sprintf('<tr><th>Last Login</th><td>%s</td><td></td></tr>', $empire->last_login);
    $out .= sprintf('<tr><th>Essentia</th><td>%s</td><td><form style="display: inline" action="/admin/add/essentia"><input type="hidden" name="id" value="%s"><input name="amount" style="width: 30px;" value="0"><input name="description" value="Administrative Privilege"><input type="submit" value="add essentia"></form></td></tr>', $empire->essentia, $empire->id);
    $out .= sprintf('<tr><th>Species</th><td>%s</td><td></td></tr>', $empire->species_name);
    $out .= sprintf('<tr><th>Home</th><td>%s</td><td></td></tr>', $empire->home_planet_id);
    $out .= sprintf('<tr><th>Description</th><td>%s</td><td></td></tr>', $empire->description);
    $out .= sprintf('<tr><th>University Level</th><td>%s</td><td></td></tr>', $empire->university_level);
    $out .= sprintf('<tr><th>Isolationist</th><td>%s</td><td><a href="/admin/toggle/isolationist?id=%s">Toggle</a></td></tr>', $empire->is_isolationist, $empire->id);
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
    $out .= sprintf('<tr><th>Star</th><td><a href="/admin/view/star?id=%s">%s</a></td><td><a href="/admin/search/bodies?star_id=%s">Bodies Orbiting This Star</a></td></tr>', $body->star_id, $body->star_id, $body->star_id);
    $out .= sprintf('<tr><th>Empire</th><td><a href="/admin/view/empire?id=%s">%s</a></td><td></td></tr>', $body->empire_id, $body->empire_id);
    $out .= '</table><ul>';
    $out .= sprintf('<li><a href="/admin/view/resources?body_id=%s">View Resources</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/buildings?body_id=%s">View Buildings</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/plans?body_id=%s">View Plans</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/glyphs?body_id=%s">View Glyphs</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/recalc/body?body_id=%s">Recalculate Body Stats</a></li>', $body->id);
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

    my (@accepts, @creates, @invites, @dates, @deletes, @users, @vc, @gr, @cr, $previous, $max_viral, $max_change, $max_users);
    my $past30 = $self->get_viral->search({date_stamp => { '>=' => DateTime->now->subtract(days => 31)}}, { order_by => 'date_stamp'});
    while (my $day = $past30->next) {
        unless (defined $previous) {
            $previous = $day;
            next;
        }
        push @dates, format_date($day->date_stamp, '%m/%d');
        
        # users chart
        push @users, $day->users;
        $max_users = $users[-1] if ($max_users < $users[-1]);
        
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
        
        $previous = $day;
    }
    
    my $users_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_users
        .'&chds=0,'.$max_users
        .'&chdl=Users&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3&chxtc=1,-750&chs=750x200&cht=ls&chco=ffffff&chd=t:'
        .join(',', @users)
        .'&chxl='
        .join('|', '0:', @dates);

    my $viral_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_viral
        .'&chds=0,'.$max_viral.',0,'.$max_viral.',0,'.$max_viral
        .'&chdl=Viral%20Coefficient|Growth%20Rate|Churn%20Rate&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3|3&chxtc=1,-750&chs=750x200&cht=ls&chco=00ff00,ffb400,b400ff&chd=t:'
        .join('|',
            join(',', @vc),
            join(',', @gr),
            join(',', @cr),
        )
        .'&chxl='
        .join('|', '0:', @dates);

    my $change_chart = 'http://chart.apis.google.com/chart?chxr=1,0,'.$max_change
        .'&chds=0,'.$max_change.',0,'.$max_change.',0,'.$max_change.',0,'.$max_change
        .'&chdl=Invites|Accepts|Creates|Deletes&chf=bg,s,014986&chxs=0,ffffff|1,ffffff&chls=3|3|3|3&chxtc=1,-750&chs=750x200&cht=ls&chco=ff0000,00ff00,0000ff,ff00ff&chd=t:'
        .join('|',
            join(',', @invites),
            join(',', @accepts),
            join(',', @creates),
            join(',', @deletes),
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
        
        <h2>Change</h2>
        <img src="'.$change_chart.'" alt="change chart">
        
        <h2>Total Users</h2>
        <img src="'.$users_chart.'" alt="users chart">
        
        </div>
    ';
    
    return $self->wrap($out);
}

sub get_viral {
    return Lacuna->db->resultset('Lacuna::DB::Result::ViralLog');
}


sub www_default {
    my ($self, $request) = @_;
    return $self->wrap('<h1>Lacuna Expanse Admin Console</h1>
            Server Version: '.Lacuna->version.'
        <ul>
        <li><a href="/">Play Game</a></li>
        <li><a href="/api/">API</a></li>
        <li><a href="http://www.lacunaexpanse.com/">Lacuna Web Site</a></li>
        </ul>
        

        <fieldset><legend>Server Utilities</legend>
        <ul>
            <li><a href="/admin/server/wide/recalc">Force Server Wide Recalc Of Planets</a></li>
        </ul>
        </fieldset>
        ');
}

sub www_server_wide_recalc {
    my ($self, $request) = @_;
    Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({empire_id => {'>', 0}})->update({needs_recalc=>1});
    return $self->wrap('Done!');
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
    <li><a href="/admin/view/logs">Logs</a></li>
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

