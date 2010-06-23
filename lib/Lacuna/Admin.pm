package Lacuna::Admin;

use Moose;
extends qw(Plack::Component);
use Plack::Request;
use feature "switch";
use Module::Find;

sub call {
    my ($self, $env) = @_;
    my $request = Plack::Request->new($env);
    my $op = $request->param('op');
    my $out;
    if ($op) {
        my $method = $self->can('www_'.$op);
        if ($method) {
            $out = eval{$self->$method($request)};
            if ($@) {
                $out = $self->format_error($request, $@);
            }
        }
    }
    $out ||= $self->www_home($request);
    my $response = $request->new_response;
    $response->status($out->[1]{status} || 200);
    $response->content_type($out->[1]{content_type} || 'text/html');
    if ($response->content_type eq 'text/html') {
        $out->[0] = $self->wrapper($out->[0]);
    }
    $response->body($out->[0]);
    return $response->finalize;
}

sub www_search_empires {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    if ($name) {
        $empires = $empires->search({name => { like => '%'.$name.'%' }});
    }
    my $out = '<h1>Search Empires</h1>';
    $out .= '<form><input type="hidden" name="op" value="search_empires"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>Species</th><th>Home</th><th>Last Login</th></tr>';
    while (my $empire = $empires->next) {
        $out .= sprintf('<tr><td><a href="?op=manage_empire;id=%s">%s</a></td><td>%s</td><td>%s</td><td><a href="?op=manage_body;id=%s">%s</a></td><td>%s</td></tr>', $empire->id, $empire->id, $empire->name, $empire->species_id, $empire->home_planet_id, $empire->home_planet_id, $empire->last_login);
    }
    $out .= '</table>';
    $out .= $self->format_paginator('search_empires', $name, $page_number);
    return [$out];
}

sub www_search_bodies {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    if ($name) {
        $bodies = $bodies->search({name => { like => '%'.$name.'%' }});
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
    $out .= '<form><input type="hidden" name="op" value="search_bodies"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Zone</th><th>Star</th><th>Empire</th></tr>';
    while (my $body = $bodies->next) {
        $out .= sprintf('<tr><td><a href="?op=manage_body;id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><a href="?op=manage_empire;id=%s">%s</a></td></tr>', $body->id, $body->id, $body->name, $body->x, $body->y, $body->zone, $body->star_id, $body->empire_id || '', $body->empire_id || '');
    }
    $out .= '</table>';
    $out .= $self->format_paginator('search_bodies', $name, $page_number);
    return [$out];
}

sub www_search_stars {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $stars = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    if ($name) {
        $stars = $stars->search({name => { like => '%'.$name.'%' }});
    }
    if ($request->param('zone')) {
        $stars = $stars->search({zone => $request->param('zone')});
    }
    my $out = '<h1>Search Stars</h1>';
    $out .= '<form><input type="hidden" name="op" value="search_stars"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Zone</th></tr>';
    while (my $star = $stars->next) {
        $out .= sprintf('<tr><td><a href="?op=manage_star;id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $star->id, $star->id, $star->name, $star->x, $star->y, $star->zone);
    }
    $out .= '</table>';
    $out .= $self->format_paginator('search_stars', $name, $page_number);
    return [$out];
}

sub www_view_buildings {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $buildings = Lacuna->db->resultset('Lacuna::DB::Result::Building')->search({ body_id => $body_id }, {order_by => ['x','y'] });
    my $out = '<h1>View Buildings</h1>';
    $out .= sprintf('<a href="?op=manage_body;id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Level</th></tr>';
    while (my $building = $buildings->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $building->id, $building->name, $building->x, $building->y, $building->level);
    }
    $out .= '</table>';
    return [$out];
}

sub www_view_plans {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $plans = Lacuna->db->resultset('Lacuna::DB::Result::Plans')->search({ body_id => $body_id }, {order_by => ['class'] });
    my $out = '<h1>View Plans</h1>';
    $out .= sprintf('<a href="?op=manage_body;id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>Level</th><th>Extra Build Level</th></tr>';
    while (my $plan = $plans->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>', $plan->id, $plan->class->name, $plan->level, $plan->extra_build_level);
    }
    $out .= '</table>';
    $out .= '<fieldset><legend>Add Plan</legend><form>';
    $out .= '<input type="hidden" name="op" value="add_plan">';
    $out .= '<input type="hidden" name="body_id" value="'.$body_id.'">';
    $out .= '<input name="level" value="1">';
    $out .= '<select name="class">';
    my %buildings = map { $_->name => $_ } findallmod Lacuna::DB::Result::Building;
    foreach my $name (sort keys %buildings) {
        next if $name eq 'Building';
        $out .= '<option value="'.$buildings{$name}.'">'.$name.'</option>';
    }
    $out .= '</select>';
    $out .= '<input name="extra_build_level" value="0">';
    $out .= '<input type="submit" value="add">';
    $out .= '</form></fieldset>';
    return [$out];
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

sub www_recalc_body {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->update({needs_recalc=>1});
    return [ sprintf('Done! <a href="?op=manage_body;id=%s">Back To Body</a>', $request->param('body_id')) ];
}

sub format_paginator {
    my ($self, $method, $name, $page_number) = @_;
    my $out = '<fieldset><legend>Page: '.$page_number.'</legend>';
    $out .= '<a href="?op='.$method.';name='.$name.';page_number='.($page_number - 1).'">&lt; Previous</a> | ';
    $out .= '<a href="?op='.$method.';name='.$name.';page_number='.($page_number + 1).'">Next &gt;</a> ';
    $out .= '<form style="display: inline;"><input name="page_number" value="'.$page_number.'" style="width: 30px;"><input type="hidden" name="op" value="'.$method.'"><input type="hidden" name="name" value="'.$name.'"><input type="submit" value="go"></form>';
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
    $out .= sprintf('<tr><th>Name</th><td>%s</td><td></td></tr>', $empire->name);
    $out .= sprintf('<tr><th>Created</th><td>%s</td><td></td></tr>', $empire->date_created);
    $out .= sprintf('<tr><th>Stage</th><td>%s</td><td></td></tr>', $empire->stage);
    $out .= sprintf('<tr><th>Last Login</th><td>%s</td><td></td></tr>', $empire->last_login);
    $out .= sprintf('<tr><th>Essentia</th><td>%s</td><td><form style="display: inline"><input type="hidden" name="op" value="add_essentia"><input type="hidden" name="id" value="%s"><input name="amount" style="width: 30px;" value="0"><input name="description" value="Administrative Privilege"><input type="submit" value="add essentia"></form></td></tr>', $empire->essentia, $empire->id);
    $out .= sprintf('<tr><th>Species</th><td>%s</td><td></td></tr>', $empire->species_id);
    $out .= sprintf('<tr><th>Home</th><td>%s</td><td><a href="?op=search_bodies;empire_id=%s">View All Colonies</a></td></tr>', $empire->home_planet_id, $empire->id);
    $out .= sprintf('<tr><th>Description</th><td>%s</td><td></td></tr>', $empire->description);
    $out .= sprintf('<tr><th>University Level</th><td>%s</td><td></td></tr>', $empire->university_level);
    $out .= sprintf('<tr><th>Isolationist</th><td>%s</td><td></td></tr>', $empire->is_isolationist);
    $out .= '</table>';
    return [$out];
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
    $out .= sprintf('<tr><th>Zone</th><td>%s</td><td><a href="?op=search_bodies;zone=%s">Bodies In This Zone</a></td></tr>', $body->zone, $body->zone);
    $out .= sprintf('<tr><th>X</th><td>%s</td><td></td></tr>', $body->x);
    $out .= sprintf('<tr><th>Y</th><td>%s</td><td></td></tr>', $body->y);
    $out .= sprintf('<tr><th>Orbit</th><td>%s</td><td></td></tr>', $body->orbit);
    $out .= sprintf('<tr><th>Star</th><td><a href="?op=manage_star;id=%s">%s</a></td><td><a href="?op=search_bodies;star_id=%s">Bodies Orbiting This Star</a></td></tr>', $body->star_id, $body->star_id, $body->star_id);
    $out .= sprintf('<tr><th>Empire</th><td><a href="?op=manage_empire;id=%s">%s</a></td><td></td></tr>', $body->empire_id, $body->empire_id);
    $out .= '</table><ul>';
    $out .= sprintf('<li><a href="?op=view_buildings;body_id=%s">View Buildings</a></li>', $body->id);
    $out .= sprintf('<li><a href="?op=view_plans;body_id=%s">View Plans</a></li>', $body->id);
    $out .= sprintf('<li><a href="?op=recalc_body;body_id=%s">Recalculate Body Stats</a></li>', $body->id);
    $out .= '</ul>';
    return [$out];
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
    $out .= sprintf('<tr><th>Zone</th><td>%s</td><td><a href="?op=search_stars;zone=%s">Stars In This Zone</a></td></tr>', $star->zone, $star->zone);
    $out .= sprintf('<tr><th>X</th><td>%s</td><td></td></tr>', $star->x);
    $out .= sprintf('<tr><th>Y</th><td>%s</td><td></td></tr>', $star->y);
    $out .= '</table><ul>';
    $out .= sprintf('<li><a href="?op=search_bodies;star_id=%s">Bodies Orbiting This Star</a></li>', $star->id);
    $out .= '</ul>';
    return [$out];
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
    <a href="?op=view_logs;file=request">Request</a>
    | <a href="?op=view_logs;file=espionage">Espionage</a>
    | <a href="?op=view_logs;file=summary">Summary</a>
    | <a href="?op=view_logs;file=weekmedals">Weekly Medals</a>
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
    return [$list.'<hr><pre>'.$log.'</pre>'];
}

sub www_home {
    my ($self, $request) = @_;
    return ['<h1>Lacuna Expanse Admin Console</h1>
            Server Version: '.Lacuna->version.'
        <ul>
        <li><a href="/">Play Game</a></li>
        <li><a href="/api/">API</a></li>
        <li><a href="http://www.lacunaexpanse.com/">Lacuna Web Site</a></li>
        </ul>
        
        <fieldset><legend>Server Utilities</legend>
        <ul>
            <li><a href="?op=server_wide_recalc">Force Server Wide Recalc Of Planets</a></li>
        </ul>
        </fieldset>
        '];
}

sub www_server_wide_recalc {
    my ($self, $request) = @_;
    Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search({empire_id => {'>', 0}})->update({needs_recalc=>1});
    return ['Done!'];
}

sub format_error {
    my ($self, $request, $error) = @_;
    unless (ref $error eq 'ARRAY') {
        $error = [$error];
    }
    my $out = '<h1>Error</h1> '. $error->[0] . ' <hr> ';
    if (ref $request eq 'Plack::Request') {
        foreach my $key ($request->parameters->keys) {
            $out .= $key.': '.$request->param($key).'<br>';
        }
    }
    else {
        $out .= 'No request object!';
    }
    return [$out, {status => $error->[1] || 500}];
}

sub wrapper {
    my ($self, $content) = @_;
    my $out = <<STOP;
    <html>
    <head><title>Lacuna Admin Console</title>
    <style type="text/css">
        tr {
            text-align: left;
        }
        fieldset {
            margin-top: 10px;
            border: 1px solid #eeeeee;
        }
        legend {
            font-size: 12px;
            color: #888888;
        }
    </style>
    </head>
    <body>
    <div style="width: 150px;">
    <ul>
    <li><a href="?op=search_empires">Empires</a></li>
    <li><a href="?op=search_bodies">Bodies</a></li>
    <li><a href="?op=search_stars">Stars</a></li>
    <li><a href="?op=view_logs">View Logs</a></li>
    <li><a href="?op=home">Home</a></li>
    </ul>
    </div>
    <div style="border: 1px solid #eeeeee; position: absolute; top: 0; left: 160px; min-width: 600px; margin: 5px;">
    <div style="margin: 15px;">
STOP
    $out .= $content;
    $out .= <<STOP;
    </div></div>
    </body>
    </html>
STOP
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

