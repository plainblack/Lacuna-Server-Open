package Lacuna::Web::Admin;

use Moose;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use feature "switch";
use Module::Find;
use UUID::Tiny;
use Lacuna::Util qw(format_date);


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
        $out .= sprintf('<tr><td><a href="/admin/manage/empire?id=%s">%s</a></td><td>%s</td><td>%s</td><td><a href="/admin/manage/body?id=%s">%s</a></td><td>%s</td></tr>', $empire->id, $empire->id, $empire->name, $empire->species_id, $empire->home_planet_id, $empire->home_planet_id, $empire->last_login);
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
        $out .= sprintf('<tr><td><a href="/admin/manage/body?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><a href="/admin/manage/empire?id=%s">%s</a></td></tr>', $body->id, $body->id, $body->name, $body->x, $body->y, $body->zone, $body->star_id, $body->empire_id || '', $body->empire_id || '');
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
        $out .= sprintf('<tr><td><a href="/admin/manage/star?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $star->id, $star->id, $star->name, $star->x, $star->y, $star->zone);
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
    $body->add_news(99, sprintf('Yesterday there was an outbreak of Derni Pestilence on %s. Today %s has gone dark.', $body->name));
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
    $out .= sprintf('<a href="/admin/manage/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Level</th></tr>';
    while (my $building = $buildings->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $building->id, $building->name, $building->x, $building->y, $building->level);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_view_resources {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    my @types = (FOOD_TYPES, ORE_TYPES, qw(water energy waste));
    my $out = '<h1>View Resources</h1>';
    $out .= sprintf('<a href="/admin/manage/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Type</th><th>Stored</th><th>Add</th></tr>';
    foreach my $resource (@types) {
        my $stored = $resource.'_stored';

        $out .= sprintf('<tr><td>%s</td><td>%s</td><form action="/admin/add/resources"><td><input name="amount"><input type="submit" value="add"><input type="hidden" name="body_id" value="%s"><input type="hidden" name="resource" value="%s"</td></form></tr>', $resource, $body->$stored, $body_id, $resource);
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
    my $add = 'add_'.$request->param('resource');
    $body->$add($request->param('amount'));
    $body->update;
    return $self->www_view_resources($request, $body->id);
}

sub www_view_glyphs {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $glyphs = Lacuna->db->resultset('Lacuna::DB::Result::Glyphs')->search({ body_id => $body_id }, {order_by => ['type'] });
    my $out = '<h1>View Glyphs</h1>';
    $out .= sprintf('<a href="/admin/manage/body?id=%s">Back To Body</a>', $body_id);
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
    $out .= sprintf('<a href="/admin/manage/body?id=%s">Back To Body</a>', $body_id);
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
    return $self->wrap(sprintf('Done! <a href="/admin/manage/body?id=%s">Back To Body</a>', $request->param('body_id')));
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

sub www_manage_empire {
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
    $out .= sprintf('<tr><th>Species</th><td>%s</td><td></td></tr>', $empire->species_id);
    $out .= sprintf('<tr><th>Home</th><td>%s</td><td><a href="/admin/search/bodies?empire_id=%s">View All Colonies</a></td></tr>', $empire->home_planet_id, $empire->id);
    $out .= sprintf('<tr><th>Description</th><td>%s</td><td></td></tr>', $empire->description);
    $out .= sprintf('<tr><th>University Level</th><td>%s</td><td></td></tr>', $empire->university_level);
    $out .= sprintf('<tr><th>Isolationist</th><td>%s</td><td></td></tr>', $empire->is_isolationist);
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_manage_body {
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
    $out .= sprintf('<tr><th>Star</th><td><a href="/admin/manage/star?id=%s">%s</a></td><td><a href="/admin/search/bodies?star_id=%s">Bodies Orbiting This Star</a></td></tr>', $body->star_id, $body->star_id, $body->star_id);
    $out .= sprintf('<tr><th>Empire</th><td><a href="/admin/manage/empire?id=%s">%s</a></td><td></td></tr>', $body->empire_id, $body->empire_id);
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

sub www_manage_star {
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
    return $self->www_manage_empire($request, $id);
}


sub www_view_logs {
    my ($self, $request) = @_;
    my $list = '
    <a href="/admin/view/logs?file=request">Request</a>
    | <a href="/admin/view/logs?file=espionage">Espionage</a>
    | <a href="/admin/view/logs?file=summary">Summary</a>
    | <a href="/admin/view/logs?file=weekmedals">Weekly Medals</a>
    ';
    my $log = 'Choose a log file.';
    given ($request->param('file')) {
        when ('request') {
            $log = `tail -50 /tmp/lacuna.log`;
        }
        when ('espionage') {
            $log = `tail -1000 /tmp/espionage.log`;
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

