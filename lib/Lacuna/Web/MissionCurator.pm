package Lacuna::Web::MissionCurator;

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
use Text::CSV_XS;

sub www_add_essentia {
    my ($self, $request) = @_;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');
    my $empire = $empires->find($request->param('id'));
    unless (defined $empire) {
        confess [404, 'Empire not found.'];
    }
    my $curator = $empires->search({name=>$request->user})->first;
    my $jt = $empires->find(2);
    $empire->add_essentia({
        amount  => 100, 
        reason  => 'Mission Pack Approved By '.$curator->name,
    });
    $empire->update;
    $empire->send_message(
        from    => $curator,
        subject => 'Mission Bounty',
        body    => 'I have approved your mission pack and awarded you 100 essentia.',
        tags    => ['Mission','Correspondence'],
    );
    $jt->send_message(
        from    => $curator,
        subject => 'Mission Bounty',
        body    => 'I have approved a mission pack for '.$empire->name.'.',
        tags    => ['Mission','Correspondence'],
    );
    my $dt_parser = Lacuna->db->storage->datetime_parser;
    my $seven_days_ago = $dt_parser->format_datetime( DateTime->now->subtract(days => 7) );
    my $recent = Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia')->search({
        empire_id => $curator->id, 
        description => 'Mission Curator', 
        date_stamp => { '>' => $seven_days_ago},
    })->count;
    if (not $recent) {
        $curator->add_essentia({
            amount  => 100, 
            reason  => 'Mission Curator',
        });
        $curator->update;
    }
    return $self->www_default($request, 'Essentia Added');
}

sub www_stats {
    my ($self, $request) = @_;
    my $csv = Text::CSV_XS->new({binary => 1});
    my $logs = Lacuna->db->resultset('Lacuna::DB::Result::Log::Mission');
    $csv->combine('filename','number of times offered','number of incompletes','number of completes','completes university level','seconds to complete','number of skips','skips university level');
    my $out = $csv->string."\n";
    while (my $log = $logs->next) {
        $csv->combine(
            $log->filename,
            $log->offers,
            $log->incompletes,
            $log->completes,
            $log->complete_uni_level,
            $log->seconds_to_complete,
            $log->skips,
            $log->skip_uni_level,
        );
        $out .= $csv->string."\n";
    }
    return [$out, { content_type => 'text/csv' }];
}

sub www_payouts {
    my ($self, $request) = @_;
    my $payouts = Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia')->search(
        {description => [{ '=' => 'Mission Curator' }, { like => 'Mission Pack Approved By%'} ] },
        {order_by => { -desc => 'date_stamp' } }
    );
    my $out = '<p><a href="/missioncurator">Back To Empires</a></p><h1>Mission Payout History</h1>';
    $out .= '<table style="width: 80%;"><tr><th>Date</th><th>Paid To</th><th>Description</th></tr>';
    while (my $payout = $payouts->next) {
        $out .= sprintf('<tr><td>%s</td><td>%s</td><td>%s</td></tr>', $payout->date_stamp, $payout->empire_name, $payout->description);
    }
    $out .= '</table>';
    return $self->wrap($out);
}

sub www_default {
    my ($self, $request, $message) = @_;
    my $page_number = $request->param('page_number') || 1;
    my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search(undef, {order_by => ['name'], rows => 25, page => $page_number });
    my $name = $request->param('name') || '';
    if ($name) {
        $empires = $empires->search({name => { like => $name.'%' }});
    }
    my $out = $message.'<h1>Add Mission Essentia</h1>';
    $out .= '<form method="post" action="/missioncurator/default"><input name="name" value="'.$name.'"><input type="submit" value="search"></form>';
    $out .= '<table><tr><th>Add Essentia</th><th>Name</th><th>Email</th></tr>';
    while (my $empire = $empires->next) {
        $out .= sprintf('<tr><td><a href="/missioncurator/add_essentia?id=%s">Add Essentia</a></td><td>%s</td><td>%s</td></tr>', $empire->id, $empire->name, $empire->email);
    }
    $out .= '</table>';
    $out .= $self->format_paginator('default', 'name', $name, $page_number);
    $out .= ' <fieldset><legend>Mission Utilities</legend>
        <ul>
            <li><a href="/missioncurator/payouts">View Mission Payout History</a></li>
            <li><a href="/missioncurator/stats">Download Mission Stats</a></li>
            <li><a href="https://github.com/plainblack/Lacuna-Mission">Mission Repository</a></li>
            <li><a href="http://community.lacunaexpanse.com/forums/missions">Mission Forum</a> [<a href="mailto:missions@lacunaexpanse.com">missions@lacunaexpanse.com</a>]</li>
            <li><a href="http://community.lacunaexpanse.com/forums/mission-curators">Curators Forum</a> [<a href="mailto:missioncurators@lacunaexpanse.com">missioncurators@lacunaexpanse.com</a>]</li>
            <li><a href="http://community.lacunaexpanse.com/wiki/mission-editor">Mission Editor</a></li>
        </ul>
        </fieldset>';
    return $self->wrap($out);
}


sub format_paginator {
    my ($self, $method, $key, $value, $page_number) = @_;
    my $out = '<fieldset><legend>Page: '.$page_number.'</legend>';
    $out .= '<a href="/missioncurator/'.$method.'?'.$key.'='.$value.';page_number='.($page_number - 1).'">&lt; Previous</a> | ';
    $out .= '<a href="/missioncurator/'.$method.'?'.$key.'='.$value.';page_number='.($page_number + 1).'">Next &gt;</a> ';
    $out .= '<form method="post" style="display: inline;" action="/missioncurator/'.$method.'"><input name="page_number" value="'.$page_number.'" style="width: 30px;"><input type="hidden" name="'.$key.'" value="'.$value.'"><input type="submit" value="go"></form>';
    $out .= '</fieldset>';
    return $out;
}


sub wrap {
    my ($self, $content) = @_;
    return $self->wrapper($content,
    { title => 'Mission Curator Panel'}
    );
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

