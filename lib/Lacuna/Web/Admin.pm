package Lacuna::Web::Admin;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use feature "switch";
use Module::Find;
use UUID::Tiny ':std';
use Lacuna::Util qw(format_date commify kmbtq);
use List::Util qw(sum);
use Data::Dumper;
use LWP::UserAgent;

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
    my $codes = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->search(undef, {order_by => { -desc => 'date_created' }, rows => 25, page => $page_number });
    my $code = $request->param('code') || '';
    if ($code) {
        $codes = $codes->search({code => { like => $code.'%' }});
    }
    my $used = $request->param('used');
    if ( defined $used && length $used ) {
        $codes = $codes->search({used => $used});
    }
    my $toggle_used = $used ? '0' : 1;
    my $out = '<h1>Search Essentia Codes</h1>';
    $out .= '<form method="post" action="/admin/search/essentia/codes"><input name="code" value="'.$code.'"><input type="submit" value="search"></form>';
    $out .= sprintf('<table style="width: 100%%;"><tr><th>Id</th><th>Code</th><th>Amount</th><th>Description</th><th>Date Created</th><th><a href="/admin/search/essentia/codes?code=%s;used=%d" title="Toggle">Used</a></th></tr>', $code, $toggle_used );
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
    my %page_query = (
        code => $code,
        used => $used,
    );
    $out .= $self->format_complex_paginator('search/essentia/codes', \%page_query, $page_number);
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
        my $empire_link = '';
        if ( my $from_empire_id = $transaction->from_id ) {
            $empire_link = sprintf '<a href="/admin/view_empire?id=%d">%d</a>', $from_empire_id, $from_empire_id;
        }
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
                        $transaction->date_stamp, $transaction->amount, $transaction->description,
                        $empire_link, $transaction->from_name, $transaction->transaction_id);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_view_login_log {
    my ($self, $request) = @_;
    my ( $search_field, $search_value );
    for my $field (qw( empire_id ip_address api_key )) {
        if ( my $value = $request->param($field) ) {
            $search_field = $field;
            $search_value = $value;
            last;
        }
    }
    my $page_number = $request->param('page_number') || 1;
    my $logins = Lacuna->db->resultset('Lacuna::DB::Result::Log::Login')->search(
        { $search_field => $search_value },
        { order_by => { -desc => 'date_stamp' },
          rows     => 25,
          page     => $page_number,
        });
    my $out = '<h1>Login Log</h1>';
    if ( $search_field eq 'empire_id' ) {
        $out .= sprintf('<a href="/admin/view/empire?id=%s">Back To Empire</a>', $search_value);
    }
    $out .= '<table style="width: 100%;"><tr><th>ID</th><th>Empire Name</th><th>Log-in Date</th><th>Log-out Date</th><th>Extended</th><th>IP Address</th><th>Sitter</th><th>API Key</th></tr>';
    while (my $login = $logins->next) {
        my $sitter = $login->is_sitter ? 'Sitter' : '';
        $out .= sprintf('<tr><td><a href="/admin/view/empire?id=%d">%d</a></td>',
                        $login->empire_id, $login->empire_id);
        $out .= sprintf('<td>%s</td><td>%s</td><td>%s</td><td>%s</td>',
                        $login->empire_name, $login->date_stamp, $login->log_out_date, $login->extended );
        $out .= sprintf('<td><a href="/admin/view/login/log?ip_address=%s" title="Search for all users logging in with this IP address">%s</a></td>',
                        $login->ip_address, $login->ip_address );
        $out .= sprintf('<td>%s</td>', $sitter);
        $out .= sprintf('<td><a href="/admin/view/login/log?api_key=%s" title="Search for all users logging in with this API key">%s</a></td></tr>',
                        $login->api_key, $login->api_key );
    }
    $out .= '</table>';
    $out .= $self->format_paginator('view/login/log', $search_field, $search_value, $page_number);
    return $self->wrap($out);
}

sub www_view_empire_name_change_log {
    my ($self, $request) = @_;
    my $empire_id = $request->param('empire_id');
    my $history = Lacuna->db->resultset('Lacuna::DB::Result::Log::EmpireNameChange')->search({empire_id => $empire_id},{order_by => { -desc => 'date_stamp' }});
    my $out = '<h1>Empire Name-Change Log</h1>';
    $out .= sprintf('<a href="/admin/view/empire?id=%s">Back To Empire</a>', $empire_id);
    $out .= '<table style="width: 100%;"><tr><th>Date</th><th>New Name</th><th>Old Name</th></tr>';
    while (my $log = $history->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td></tr>',
                        $log->date_stamp, $log->empire_name, $log->old_empire_name);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_search_similar_empire {
    my ($self, $request) = @_;
    my $empire_id   = $request->param('empire_id');
    my $page_number = $request->param('page_number') || 1;
    my $type        = $request->param('type');
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    my @query = (
        id => { '!=' => $empire_id },
    );
    if ( $type eq 'name' ) {
        my @words = $empire->name =~ /(\p{Alpha}+)/g;
        if ( @words ) {
            push @query, -or => [
                map { my %x = ( LIKE => "%$_%" ); name => \%x } @words
            ];
        }
        else {
            my $name = $empire->name;
            push @query, name => { 'LIKE' => "%$name%" };
        }
    }
    elsif ( $type eq 'email_user' ) {
        my ($user) = $empire->email =~ /([^@]+)/;
        if ( !defined $user ) {
            confess [ 400, 'Failed to parse email address' ];
        }
        my @words = $user =~ /(\p{Alpha}+)/g;
        if ( @words ) {
            push @query, -or => [
                map { my %x = ( LIKE => "%$_%\@%" ); email => \%x } @words
            ];
        }
        else {
            my $email = $empire->email;
            push @query, email => { 'LIKE' => "%$email%" };
        }
    }
    elsif ( $type eq 'email_domain' ) {
        my ($domain) = $empire->email =~ /@([^@]+)/;
        if ( !defined $domain ) {
            confess [ 400, 'Failed to parse email address' ];
        }
        push @query, email => { 'LIKE' => "%\@$domain" };
    }
    my $search = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search(
        { -and => \@query },
        { order_by => { -desc => 'id' },
          rows     => 25,
          page     => $page_number,
        });
    my $out = '<h1>Similar Empires</h1>';
    $out .= sprintf('<a href="/admin/view/empire?id=%s">Back To Empire</a>', $empire_id);
    $out .= '<table style="width: 100%;"><tr><th>ID</th><th>Empire Name</th><th>Email</th><th>Created</th><th>Last Login</th></tr>';
    while (my $match = $search->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/empire?id=%d">%d</a></td>',
                        $match->id, $match->id);
        $out .= sprintf('<td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
                        $match->name, $match->email, $match->date_created, $match->last_login );
    }
    $out .= '</table>';
    $out .= $self->format_complex_paginator('search/similar/empire', { empire_id => $empire_id, type => $type }, $page_number);
    return $self->wrap($out);
}

sub www_search_empires {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search(undef, { rows => 25, page => $page_number });
    my $field = $request->param('field') || 'name';
    my $name  = $request->param('name') || '';
    if ($name) {
        my $query = "$name%";
        $query =~ s/\*/%/;
        $empires = $empires->search({$field => { like => $query }});
    }
    my $order = $request->param('order') || 'name';
    my $desc  = $request->param('desc') || 0;
    if ( $order ~~ [qw( id name last_login )] ) {
        my $sort = $desc ? "-desc" : "-asc";
        $empires = $empires->search(undef, { order_by => {$sort => $order} });
    }
    my $out = '<h1>Search Empires</h1>';
    $out .= '<form method="post" action="/admin/search/empires"><input name="name" value="'.$name.'">';
    $out .= '<select name="field">';
    $out .= '<option value="name"'.( $field eq 'name'  ? ' selected="selected"' : '' ).'">Name</option>';
    $out .= '<option value="email"'.( $field eq 'email'  ? ' selected="selected"' : '' ).'">Email</option>';
    $out .= '</select><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr>';
    $out .= sprintf('<th>Id <a href="/admin/search/empires?name=%s;order=id;desc=0" title="Order by Id, Ascending">&dArr;</a> <a href="/admin/search/empires?name=%s;order=id;desc=1" title="Order by Id, Descending">&uArr;</a></th>', $name, $name );
    $out .= sprintf('<th>Name <a href="/admin/search/empires?name=%s;order=name;desc=0" title="Order by Name, Ascending">&dArr;</a> <a href="/admin/search/empires?name=%s;order=name;desc=1" title="Order by Name, Descending">&uArr;</a></th>', $name, $name );
    $out .= '<th>Species</th><th>Home</th>';
    $out .= sprintf('<th>Last Login <a href="/admin/search/empires?name=%s;order=last_login;desc=0" title="Order by Last Login, Ascending">&dArr;</a> <a href="/admin/search/empires?name=%s;order=last_login;desc=1" title="Order by Last Login, Descending">&uArr;</a></th></tr>', $name, $name );
    while (my $empire = $empires->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/empire?id=%s">%s</a></td><td>%s</td><td>%s</td><td><a href="/admin/view/body?id=%s">%s</a></td><td>%s</td></tr>', $empire->id, $empire->id, $empire->name, $empire->species_name, $empire->home_planet_id, $empire->home_planet_id, $empire->last_login);
    }
    $out .= '</table>';
    my %page_query = (
        name  => $name,
        order => $order,
        desc  => $desc,
    );
    $out .= $self->format_complex_paginator('search/empires', \%page_query, $page_number);
    return $self->wrap($out);
}

sub www_search_bodies {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    my $pager = 'name';
    if ($name) {
        my $query = "$name%";
        $query =~ s/\*/%/g;
        $bodies = $bodies->search({name => { like => $query }});
    }
    if ($request->param('empire_id')) {
        $pager = 'empire_id';
        $name  = $request->param('empire_id');
        $bodies = $bodies->search({empire_id => $name});
    }
    if ($request->param('zone')) {
        $bodies = $bodies->search({zone => $request->param('zone')});
    }
    if ($request->param('star_id')) {
        $bodies = $bodies->search({star_id => $request->param('star_id')});
    }
    my $out = '<h1>Search Bodies</h1>';
    $out .= '<form method="post" action="/admin/search/bodies"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>O</th><th>Zone</th><th>Star</th><th>Type</th><th>Happiness</th><th>Empire</th></tr>';
    while (my $body = $bodies->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/body?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><a href="/admin/view/empire?id=%s">%s</a></td></tr>',
                        $body->id, $body->id, $body->name, $body->x, $body->y, $body->orbit, $body->zone, $body->star_id, $body->image_name, kmbtq($body->happiness),
                        $body->empire_id || '', $body->empire_id ? sprintf("%s (%s)",$body->empire->name,$body->empire_id) : '' );
    }
    $out .= '</table>';
    $out .= $self->format_paginator('search/bodies', $pager, $name, $page_number);
    return $self->wrap($out);
}

sub www_search_stars {
    my ($self, $request) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $stars = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    if ($name) {
        my $query = "$name%";
        $query =~ s/\*/%/;
        $stars = $stars->search({name => { like => $query }});
    }
    if ($request->param('zone')) {
        $stars = $stars->search({zone => $request->param('zone')});
    }
    my $out = '<h1>Search Stars</h1>';
    $out .= '<form method="post" action="/admin/search/stars"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>X</th><th>Y</th><th>Zone</th><th>Station</th></tr>';
    while (my $star = $stars->next) {
        $out .= sprintf('<tr><td><a href="/admin/view/star?id=%s">%s</a></td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><a href="/admin/view/body?id=%s">%s</a></td></tr>',
                        $star->id, $star->id, $star->name, $star->x, $star->y, $star->zone,
                        $star->station_id || '', $star->station_id || '');
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
        $building->finish_upgrade;
    }
    return $self->wrap(sprintf('All building constuction completed! <a href="/admin/view/body?id=%s">Back To Body</a>', $request->param('body_id')));
}

sub www_send_stellar_flare {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($body_id);
    foreach my $building (@{$body->building_cache}) {
#        next unless ('Infrastructure' ~~ [$building->build_tags]);
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
#        next if ( $building->class eq 'Lacuna::DB::Result::Building::PlanetaryCommand' );
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
    my @all_buildings = @{$body->building_cache};
    $body->delete_buildings(\@all_buildings);
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
    $out .= '<h2>Add Building</h2>';
    $out .= '<p>This costs no resources or plans, and bypasses normal restrictions ';
    $out .= 'such as tech-level, plot-count, etc.<br>';
    $out .= '<b>Level</b> is the final level <b>after</b> the build is complete.</br>';
    $out .= '<b>X</b> and <b>Y</b> are not required.</p>';
    $out .= '<form method="post" action="/admin/add/building"><tr>';
    $out .= '<table><tr><th>Type</th><th>X</th><th>Y</th><th>Level</th><th>Skip build queue</th><th></th></tr>';
    $out .= '<input type="hidden" name="body_id" value="'.$body_id.'">';
    $out .= '<tr><td><select name="class">';
    my %buildings = map { $_->name => $_ } findallmod Lacuna::DB::Result::Building;
    foreach my $name (sort keys %buildings) {
        next if $name eq 'Building';
        $out .= '<option value="'.$buildings{$name}.'">'.$name.'</option>';
    }
    $out .= '</select></td>';
    $out .= '<td><input name="x" value="" size="2"></td>';
    $out .= '<td><input name="y" value="" size="2"></td>';
    $out .= '<td><input name="level" value="1" size="2"></td>';
    $out .= '<td><input name="skip_build_queue" type="checkbox" value="1"></td>';
    $out .= '<td><input type="submit" value="add building"></td>';
    $out .= '</tr></table></form>';
    return $self->wrap($out);
}

sub www_add_building {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    my $class = $request->param('class');
    my $x     = $request->param('x');
    my $y     = $request->param('y');
    my $level = $request->param('level') || 1;
    $level--;
    if ( !length $x || !length $y ) {
        ($x, $y) = $body->find_free_space;
    }

    # check the plot lock
    if ($body->is_plot_locked($x, $y)) {
        confess [1013, "That plot is reserved for another building.", [$x,$y]];
    }
    else {
        $body->lock_plot($x,$y);
    }
    # is the plot empty?
    $body->check_for_available_build_space( $x, $y );

    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => $x,
        y               => $y,
        level           => $level,
        body_id         => $body->id,
        body            => $body,
        class           => $class,
    });
    $body->build_building( $building );
    if ( $request->param('skip_build_queue') ) {
        $building->finish_upgrade;
    }
    return $self->www_view_buildings($request, $body->id);
}

sub www_set_efficiency {
    my ($self, $request) = @_;
    my $building = Lacuna->db->resultset('Lacuna::DB::Result::Building')->find($request->param('building_id'));
    my $body = Lacuna->db->resultset('Map::Body')->find($building->body_id);
    my $x = $request->param('x');
    my $y = $request->param('y');
    
    # is the building being moved?
    if ( $x != $building->x || $y != $building->y ) {
        # check the plot lock
        if ($body->is_plot_locked($x, $y)) {
            confess [1013, "That plot is reserved for another building.", [$x,$y]];
        }
        else {
            $body->lock_plot($x,$y);
        }
        # is the plot empty?
        $body->check_for_available_build_space( $x, $y );
    }
    
    $building->update({
        efficiency      => $request->param('efficiency'),
        x               => $x,
        y               => $y,
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

sub www_view_ships {
    my ($self, $request, $body_id) = @_;
    $body_id ||= $request->param('body_id');
    my $ships = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $body_id });
    my $out = '<h1>View Ships</h1>';
    $out .= sprintf('<a href="/admin/view/body?id=%s">Back To Body</a>', $body_id);
    $out .= '<table style="width: 100%;"><tr><th>Id</th><th>Name</th><th>Type</th><th>Stealth</th><th>Hold Size</th><th>Speed</th><th>Combat</th><th>Task</th><th>Delete</td></tr>';
    while (my $ship = $ships->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>', $ship->id, $ship->name, $ship->type_formatted, $ship->stealth, $ship->hold_size, $ship->speed, $ship->combat);
        if ($ship->task eq 'Travelling') {
            $out .= sprintf('<td>%s<form method="post" action="/admin/zoom/ship"><input type="hidden" name="ship_id" value="%s"><input type="hidden" name="body_id" value="%s"><input type="submit" value="zoom"></form></td>', $ship->task, $ship->id, $body_id);
        }
        elsif ($ship->task ~~ [qw(Defend Orbiting)]) {
            my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($ship->foreign_body_id);
            $out .= sprintf('<td>%s<br>%s (%d, %d)<form method="post" action="/admin/recall/ship"><input type="hidden" name="ship_id" value="%s"><input type="hidden" name="body_id" value="%s"><input type="submit" value="recall"></form></td>', $ship->task, $target->name, $target->x, $target->y, $ship->id, $body_id);
        }
        elsif ($ship->task ne 'Docked') {
            $out .= sprintf('<td>%s<form method="post" action="/admin/dock/ship"><input type="hidden" name="ship_id" value="%s"><input type="hidden" name="body_id" value="%s"><input type="submit" value="dock" onclick="return confirm(\'Doing this without knowing the implications can cause unintended side effects. Are you sure?\');"></form></td>', $ship->task, $ship->id, $body_id);            
        }
        else {
            $out .= sprintf('<td>%s</td>', $ship->task);            
        }
        $out .= sprintf('<form method="post" action="/admin/delete/ship"><td><input type="hidden" name="ship_id" value="%s"><input type="hidden" name="body_id" value="%s"><input type="submit" value="delete"></td></form></tr>', $ship->id, $body_id);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_zoom_ship {
    my ($self, $request) = @_;
    my $ship_id = $request->param('ship_id');
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
#    my $body = $ship->body;

#    $ship->re_schedule(DateTime->now);
    $ship->date_available(DateTime->now);
    $ship->update;
#    $ship->update({date_available => DateTime->now});
#    $body->tick;
    return $self->www_view_ships($request);
}

sub www_recall_ship {
    my ($self, $request) = @_;
    my $ship_id = $request->param('ship_id');
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    my $target = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($ship->foreign_body_id);

    my $body = $ship->body;
    $ship->send(
        target      => $target,
        direction   => 'in',
    );
    $body->tick;
    return $self->www_view_ships($request);
}

sub www_dock_ship {
    my ($self, $request) = @_;
    my $ship_id = $request->param('ship_id');
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($ship_id);
    $ship->land->update;
    return $self->www_view_ships($request);
}

sub www_delete_ship {
    my ($self, $request) = @_;
    my $ship = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->find($request->param('ship_id'));
    $ship->delete;
    return $self->www_view_ships($request);
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
    $out .= '<td><input name="quantity" value="1" size="2"></td>';
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
    $body->add_glyph($request->param('type'), $request->param('quantity'));
    return $self->www_view_glyphs($request, $body->id);
}

sub www_delete_glyph {
    my ($self, $request) = @_;
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($request->param('body_id'));
    unless (defined $body) {
        confess [404, 'Body not found.'];
    }
    $body->glyph->find($request->param('glyph_id'))->delete;
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
    
    return $self->format_complex_paginator( $method, { $key => $value }, $page_number );
}

sub format_complex_paginator {
    my ($self, $method, $query, $page_number) = @_;
    my $out = '<fieldset><legend>Page: '.$page_number.'</legend>';
    my $query_str = join ';', map { sprintf "%s=%s", $_, $query->{$_} } keys %$query;
    $out .= '<a href="/admin/'.$method.'?'.$query_str.';page_number='.($page_number - 1).'">&lt; Previous</a> | ';
    $out .= '<a href="/admin/'.$method.'?'.$query_str.';page_number='.($page_number + 1).'">Next &gt;</a> ';
    $out .= '<form method="post" style="display: inline;" action="/admin/'.$method.'"><input name="page_number" value="'.$page_number.'" style="width: 30px;">';
    for my $key ( keys %$query ) {
        $out .= sprintf '<input type="hidden" name="%s" value="%s">', $key, $query->{$key};
    }
    $out .= '<input type="submit" value="go"></form>';
    $out .= '</fieldset>';
    return $out;
}

=for later

MUCH later.

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

=cut

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

=for probably never

Admins are added/removed so rarely, it shouldn't be done so trivially

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

=cut

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
    $uri = sprintf $uri, $empire->start_session({ is_admin => $request->user, api_key => 'admin:' . $request->user })->id;
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
    if ( $empire->self_destruct_active ) {
        $out .= sprintf('<tr class="admin_highlight"><th>Self Destruct Active!</th><td>Expires: %s</td><td></td></tr>', $empire->self_destruct_date);
    }
    $out .= sprintf('<tr><th>Id</th><td>%s</td><td></td></tr>', $empire->id);
    $out .= sprintf('<tr><th>RPC Requests</th><td>%s</td><td></td></tr>', $empire->rpc_count);
    $out .= sprintf('<tr><th>Name</th><td>%s</td><td>', $empire->name);
    $out .= sprintf('<a href="/admin/view/empire/name/change/log?empire_id=%s">View History</a>',$empire->id);
    $out .= sprintf(' | <a href="/admin/search/similar/empire?empire_id=%s&type=name">Find Similar Empire Names</a></td></tr>',$empire->id);
    $out .= sprintf('<tr><th>Email</th><td>%s</td><td>', $empire->email);
    if ( $empire->email ) {
        $out .= sprintf('<a href="/admin/search/similar/empire?empire_id=%s&type=email_user">Find Similar Email Usernames</a>',$empire->id);
        $out .= sprintf(' | <a href="/admin/search/similar/empire?empire_id=%s&type=email_domain">Find Same Email Domains</a>',$empire->id);
    }
    $out .= '</td></tr>';
    $out .= sprintf('<tr><th>Created</th><td>%s</td><td></td></tr>', $empire->date_created);
    $out .= sprintf('<tr><th>Stage</th><td>%s</td><td></td></tr>', $empire->stage);
    $out .= sprintf('<tr><th>Last Login</th><td>%s</td><td>', $empire->last_login);
    $out .= sprintf('<a href="/admin/view/login/log?empire_id=%s">View Log</a></td></tr>',$empire->id);
    $out .= sprintf('<tr><th>Essentia</th><td>%.1f</td><td>', $empire->essentia);
    $out .= sprintf('<a href="/admin/view/essentia/log?empire_id=%s">View Log</a></td></tr>',$empire->id);
    $out .= sprintf('<tr><th>Essentia Types</th><td>Free: %.1f; Game: %.1f; Paid: %.1f</td><td></td></tr>', $empire->essentia_free, $empire->essentia_game, $empire->essentia_paid);
    $out .= sprintf('<th>Add Essentia</th><td colspan="2">
<form method="post" style="display: inline" action="/admin/add/essentia">
<input type="hidden" name="id" value="%s">
<input name="amount" style="width: 30px;" value="0">
<input name="description" value="Administrative Privilege">
<input type="submit" value="add essentia"></form></td></tr>', $empire->id);
    $out .= sprintf('<tr><th>Species</th><td>%s</td><td></td></tr>', $empire->species_name);
    $out .= sprintf('<tr><th>Home</th><td><a href="/admin/view/body?id=%s">%s</a> (%s)</td><td></td></tr>', $empire->home_planet_id, $empire->home_planet->name, $empire->home_planet_id);
    $out .= sprintf('<tr><th>Alliance</th><td>');
    if ( my $alliance = $empire->alliance ) {
        $out .= sprintf('<a href="/admin/view/alliance?id=%d">%s</a> (%s)', $alliance->id, $alliance->name, $alliance->id);
    }
    $out .= sprintf('</td></tr>');
    $out .= '<tr><th>Invites Sent To</th><td>';
    my $invites_sent = Lacuna->db->resultset('Lacuna::DB::Result::Invite')->search({inviter_id => $empire->id});
    $out .= join ' ; ',
        map {
            sprintf('<a href="/admin/view/empire?id=%d">%s</a> (%s)', $_->id, $_->name, $_->id )
        }
        map  { $_->invitee }
        grep { $_->invitee_id } 
            $invites_sent->all;
    $out .= '</td></tr>';
    $out .= '<tr><th>Invite Accepted From</th><td>';
    my $invite_accepted = Lacuna->db->resultset('Lacuna::DB::Result::Invite')->search({invitee_id => $empire->id})->first;
    if ( $invite_accepted && $invite_accepted->inviter_id ) {
        my $inviter = $invite_accepted->inviter;
        $out .= sprintf('<a href="/admin/view/empire?id=%d">%s</a> (%s)', $inviter->id, $inviter->name, $inviter->id);
    }
    $out .= '</td></tr>';
    $out .= sprintf('<tr><th>Description</th><td>%s</td><td></td></tr>', $empire->description);
    $out .= sprintf('<tr><th>University Level</th><td>%s</td><td><form method="post" style="display: inline" action="/admin/change/university/level"><input type="hidden" name="id" value="%s"><input name="university_level" style="width: 30px;" value="0"><input type="submit" value="change"></form></td></tr>', $empire->university_level, $empire->id);
    $out .= sprintf('<tr><th>Isolationist</th><td>%s</td><td><a href="/admin/toggle/isolationist?id=%s">Toggle</a></td></tr>', $empire->is_isolationist, $empire->id);
    $out .= sprintf('<tr><th>Admin</th><td>%s</td></tr>', $empire->is_admin);
    $out .= sprintf('<tr><th>Mission Curator</th><td>%s</td><td><a href="/admin/toggle/mission/curator?id=%s">Toggle</a></td></tr>', $empire->is_mission_curator, $empire->id);

    my $notes = Lacuna->db->resultset('Log::EmpireAdminNotes')->find({empire_id => $empire->id},{order_by => { -desc => 'id' }, limit => 1 });
    $out .= sprintf('<tr><th>Admin Notes</th><td colspan="2"><form method="post" style="display: inline" action="/admin/set/admin/notes"><input type="hidden" name="id" value="%s"><textarea name="notes" rows="4" cols="80">%s</textarea><input type="submit"></form></td><td>Last set by: %s<br/>Last set on: %s<br/><a href="/admin/view/admin/note/log?id=%s">View Log</a></td></tr>',
                    $empire->id,
                    $notes ? $notes->notes : '',
                    $notes ? $notes->creator : '<i>not set yet</i>',
                    $notes ? $notes->date_stamp : '<i>not set yet</i>',
                    $empire->id
                   );

    $out .= '</table><ul>';
    $out .= sprintf('<li><a href="/admin/become/empire?empire_id=%s">Become This Empire In-Game</a></li>', $empire->id);
    $out .= sprintf('<li><a href="/admin/search/bodies?empire_id=%s">View All Colonies</a></li>', $empire->id);
    $out .= sprintf('<li><a href="/admin/send/test/message?empire_id=%s">Send Developer Test Email</a></li>', $empire->id);
    #$out .= sprintf('<li><a href="/admin/delete/empire?empire_id=%s" onclick="return confirm(\'Are you sure?\')">Delete Empire</a> (Be Careful)</li>', $empire->id);
    $out .= '</ul>';
    return $self->wrap($out);
}

sub www_set_admin_notes {
    my ($self, $request) = @_;

    my $id = $request->param('id');
    my $empire = Lacuna->db->empire($id);
    my $notes = $request->param('notes');

    my $note = Lacuna->db->resultset('Log::EmpireAdminNotes')->new({
                       empire_id   => $empire->id,
                       empire_name => $empire->name,
                       date_stamp  => DateTime->now,
                       notes       => $notes,
                       creator     => $request->user,
                   })->insert;

    return $self->www_view_empire($request);
}

sub www_view_admin_note_log {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $empire = Lacuna->db->empire($id);

    my $history = Lacuna->db->resultset('Log::EmpireAdminNotes')->search({empire_id => $empire->id},{order_by => { -desc => 'date_stamp' }});
    my $out = sprintf '<h1>"%s" Empire notes log</h1>', $empire->name;
    $out .= sprintf('<a href="/admin/view/empire?id=%s">Back To Empire</a>', $empire->id);
    $out .= '<table style="width:100%;"><tr><th>Date</t><th>Creator</th><th>Notes</th></tr>';
    while (my $log = $history->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td><pre>%s</pre></td></tr>',
                        $log->date_stamp, $log->creator, Plack::Util::encode_html($log->notes));
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_set_alliance_logo {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $alliance = Lacuna->db->resultset('Lacuna::DB::Result::Alliance')->find($id);
    unless (defined $alliance) {
        confess [404, 'Alliance not found.'];
    }
    my $image = $request->param('logo_url');
    unless (defined $image) {
        confess [404, 'Logo URL not supplied' ];
    }
    my $out = '';

    my $full_url = 'https://d16cbq0l6kkf21.cloudfront.net/assets/alliances/' . $image . '.png';
    my $response = LWP::UserAgent->new->head($full_url);
    if ($response->is_success)
    {
        $alliance->image($image);
        $alliance->update;
        $out .= '<h2>Success</h2>';
        $out .= sprintf('<p>Successfully updated %s to use <a href="%s">%s</a></p>',
                        $alliance->name, $full_url, $image);
    }
    else
    {
        $out .= '<h3>Failure</h2>';
        $out .= sprintf('<p>Could not find an image for %s - has it been delivered yet?</p>',
                        $image);
    }
    $out .= sprintf('<p>Back to <a href="/admin/view/alliance?id=%d">%s</a></p>',
                    $alliance->id, $alliance->name);
    return $self->wrap($out);

}

sub www_view_alliance {
    my ($self, $request, $id) = @_;
    $id ||= $request->param('id');
    my $alliance = Lacuna->db->resultset('Lacuna::DB::Result::Alliance')->find($id);
    unless (defined $alliance) {
        confess [404, 'Alliance not found.'];
    }
    my $current_logo_path = $alliance->image;
    my $num = 0;

    if ($current_logo_path)
    {
        ($num) = $current_logo_path =~ /_(\d+)$/;
        $current_logo_path = qq["$current_logo_path"];
    }
    else
    {
        $current_logo_path = "not set";
    }

    my $uri = URI->new(Lacuna->config->get('server_url'));
    my ($domain) = $uri->authority =~ /^([^.]+)\./;
    my $new_logo_path = sprintf("%s/logo_%d_%03d", $domain, $alliance->id, $num + 1);

    my $leader = $alliance->leader;
    my $out = '<h1>Manage Alliance</h1>';
    $out .= '<ul>';
    $out .= sprintf('<li><form method="post" action="/admin/set/alliance/logo?id=%d">Alliance logo image (excluding ".png"): <input name="logo_url" value="%s"> (currently %s)<input type="submit" value="set_logo"></form></li>',
                    $alliance->id,
                    $new_logo_path,
                    $current_logo_path,
                   );
    $out .= '</ul>';
    $out .= '<table style="width: 100%">';
    $out .= '<tr><th>Id</th><th>Name</th><th>Home</th><th>Last Login</th></tr>';
    $out .= sprintf('<tr><td><b><a href="/admin/view/empire?id=%d">%d</a></b></td><td><b>%s</b></td><td><b><a href="/admin/view/body?id=%d">%s</a></b></td><td><b>%s</b></td></tr>',
                    $leader->id, $leader->id, $leader->name, $leader->home_planet_id, $leader->home_planet_id, $leader->last_login);
    for my $member( $alliance->members ) {
        next if $member->id == $leader->id;
        $out .= sprintf('<tr><td><a href="/admin/view/empire?id=%d">%d</a></td><td>%s</td><td><a href="/admin/view/body?id=%d">%s</a></td><td>%s</td></tr>',
                    $member->id, $member->id, $member->name, $member->home_planet_id, $member->home_planet_id, $member->last_login);
    }
    $out .= '</table>';
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
    $out .= sprintf('<tr><th>Star</th><td><a href="/admin/view/star?id=%s">%s</a> (%s)</td><td><a href="/admin/search/bodies?star_id=%s">Bodies Orbiting This Star</a></td></tr>', $body->star_id, $body->star->name, $body->star_id, $body->star_id);
    if ($body->empire) {
        $out .= sprintf('<tr><th>Empire</th><td><a href="/admin/view/empire?id=%s">%s</a> (%s)</td><td></td></tr>', $body->empire_id, $body->empire->name, $body->empire_id);
    }
    else {
        $out .= sprintf('<tr><th>Empire</th><td><i>Unowned</i></td><td></td></tr>');
    }
    $out .= '</table><ul>';
    $out .= sprintf('<li><a href="/admin/view/resources?body_id=%s">View Resources</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/buildings?body_id=%s">View Buildings</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/ships?body_id=%s">View Ships</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/plans?body_id=%s">View Plans</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/view/glyphs?body_id=%s">View Glyphs</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/recalc/body?body_id=%s">Recalculate Body Stats</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/complete/builds?body_id=%s">Complete All Builds</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/send/stellar/flare?body_id=%s" onclick="return confirm(\'Set all buildings on planet (except PCC) to zero efficiency - Are you sure?\')" title="Set all buildings on planet (except PCC) to zero efficiency">Send Stellar Flare</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/send/meteor/shower?body_id=%s" onclick="return confirm(\'Replace all infrastructure buildings on planet (except PCC) with level 1 craters - Are you sure?\')" title="Replace all infrastructure buildings on planet (except PCC) with level 1 craters">Send Meteor Shower</a></li>', $body->id);
    $out .= sprintf('<li><a href="/admin/send/pestilence?body_id=%s" onclick="return confirm(\'Abandon colony and remove all non-permanent buildings - Are you sure?\')" title="Abandon colony and remove all non-permanent buildings">Send Pestilence</a></li>', $body->id);
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
    $out .= sprintf('<tr><th>Y</th><td>%s</td><td></td></tr>', $star->y);#))
    if ($star->station_id) {
        $out .= sprintf('<tr><th>Station</th><td><a href="/admin/view/body?id=%s">%s</a> (%s)</td><td></td></tr>', $star->station_id, $star->station->name, $star->station_id);
    }
    else {
        $out .= sprintf('<tr><th>Station</th><td><i>Unowned</i></td><td></td></tr>');
    }
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
    $empire->add_essentia({
        amount  => $request->param('amount'), 
        reason  => $request->param('description'),
        type    => 'free',
    });
    $empire->update;
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

    my $dt_formatter = Lacuna->db->storage->datetime_parser;
    my (@accepts, @abandons, @creates, @invites, @dates, @deletes, @users, @stay, @vc, @gr, @cr, $previous, $max_viral, $max_change, $max_users, $max_stay);
    my $past30 = Lacuna->db->resultset('Lacuna::DB::Result::Log::Viral')->search({date_stamp => { '>=' => $dt_formatter->format_datetime(DateTime->now->subtract(days => 31))}}, { order_by => 'date_stamp'});
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

    my $dt_formatter = Lacuna->db->storage->datetime_parser;
    my (@dates, $previous, @arpu, $max_purchases, @p30, @p100, @p200, @p600, @p1300, $max_revenue, @revenue, @r30, @r100, @r200, @r600, @r1300);
    my ($max_out, @out_boost, @out_mission, @out_recycle, @out_ship, @out_spy, @out_glyph, @out_party, @out_building, @out_trade, @out_delete, @out_other);        
    my ($max_in, @in_mission, @in_purchase, @in_trade, @in_redemption, @in_vein, @in_vote, @in_tutorial, @in_other);
    my $past30 = Lacuna->db->resultset('Lacuna::DB::Result::Log::Economy')->search({date_stamp => { '>=' => $dt_formatter->format_datetime(DateTime->now->subtract(days => 31))}}, { order_by => 'date_stamp'});
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
                                    #"
sub wrap {
    my ($self, $content) = @_;

    my $uri = URI->new(Lacuna->config->get('server_url'));
    my ($domain) = $uri->authority =~ /^([^.]+)\./;

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
    { title => "Admin Console ($domain)"}
    );
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

