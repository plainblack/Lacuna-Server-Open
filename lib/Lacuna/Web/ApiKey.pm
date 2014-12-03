package Lacuna::Web::ApiKey;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use UUID::Tiny ':std';
use Email::Stuff;

sub www_view_stats {
    my ($self, $request) = @_;
    my $pair = Lacuna->db->resultset('Lacuna::DB::Result::ApiKey')->search({ private_key => $request->param('private_key')})->first;
    unless (defined $pair) {
        confess [404, 'That private key could not be found'];
    }
    my $name = '<span style="font-size: 18pt;">'.$pair->public_key.'</span>';
    $name = ($pair->name) ? $pair->name . ' ('.$name.')' : $name;
    my $row = sub {
        return '<tr><td>'.$_[0].'</td><td>'.$_[1].'</td><td>'.$_[2].'</td></tr>';
    };
    my $dt_parser = Lacuna->db->storage->datetime_parser;
    my $thirty_days_ago = $dt_parser->format_datetime( DateTime->now->subtract(days=>30) );
    my $out = "<h1>Stats for $name</h1><table style=\"width: 100%;\"><tr><th>Statistic</th><th>Past 30 Days</th><th>All Time</th></tr>";
    my $login = Lacuna->db->resultset('Lacuna::DB::Result::Log::Login')->search({api_key => $pair->public_key});
    $out .= $row->('Empires Using',
        $login->search({date_stamp => { '>=' => $thirty_days_ago }},{group_by => ['empire_id']})->count,
        $login->search(undef,{group_by => ['empire_id']})->count
    );
    $out .= $row->('Logins',
        $login->search({date_stamp => { '>=' => $thirty_days_ago }})->count,
        $login->count
    );
    my $essentia = Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia')->search({api_key => $pair->public_key, amount => { '<' => 0 } });
    $out .= $row->('Essentia Spent',
        $essentia->search({date_stamp => { '>=' =>$thirty_days_ago }})->get_column('amount')->sum * -1,
        $essentia->get_column('amount')->sum * -1
    );
    my $lottery = Lacuna->db->resultset('Lacuna::DB::Result::Log::Lottery')->search({api_key => $pair->public_key });
    $out .= $row->('Lottery Votes',
        $lottery->search({date_stamp => { '>=' =>$thirty_days_ago }})->count,
        $lottery->count
    );
    my $rpc = Lacuna->db->resultset('Lacuna::DB::Result::Log::RPC')->search({api_key => $pair->public_key });
    $out .= $row->('RPC Calls',
        $rpc->search({date_stamp => { '>=' =>$thirty_days_ago }})->count,
        $rpc->count
    );
    $out .= '</table>';
    return $self->wrapper($out, { title => 'Your Stats', logo => 1 });    
}

sub www_generate_key {
    my ($self, $request) = @_;
    my $pair = Lacuna->db->resultset('Lacuna::DB::Result::ApiKey')->new({
        public_key  => create_uuid_as_string(UUID_V4),
        private_key => create_uuid_as_string(UUID_V4),
        email       => $request->param('email'),
        name        => $request->param('name'),
        ip_address  => $request->address,
    });
    $pair->insert;
    my $out = q{
        <h1>Your Key</h1>
        <b>Public Key:</b><br>
    }.
        $pair->public_key
    .q{
        <br><br>
        <b>Private Key:</b><br>            
    }.
        $pair->private_key
    .q{
        <br><br>         
    };
    if ($pair->email) {
        Email::Stuff->from('noreply@lacunaexpanse.com')
            ->to($pair->email)
            ->subject('Lacuna API Key')
            ->text_body("Here is the copy of the API Key you requested.\n\nPublic Key: ".$pair->public_key."\n\nPrivate Key: ".$pair->private_key)
            ->send;
    }
    return $self->wrapper($out, { title => 'Your API Key', logo => 1 });    
}

sub www_default {
    my ($self, $request) = @_;
    my $out = q{
      <h1>Lacuna Expanse API Key Console</h1>
      <div>You can either equest a key or view the stats of an existing key.</div>
      <div style="width: 35%; padding-right: 10px; float: left; margin-top: 20px;">
        <form action="/apikey/view/stats">
            <fieldset>
                <legend>View Stats</legend>
                <b>Private Key:</b><br>
                <input type="text" name="private_key"><br><br>
                <input type="submit" value="View Stats">
            </fieldset>
        </form>
      </div>
      <div style="width: 64%; float: right; margin-top: 20px;">
        <form action="/apikey/generate/key">
            <fieldset>
                <legend>Create Key</legend>
                <b>Program / Client Name:</b><br>
                <input type="text" name="name"> (Optional)<br><br>
                <b>Email Address:</b><br>                
                <input type="text" name="email"> (If you want the key emailed to you as well.)<br><br>
                <input type="submit" value="Generate Key">
            </fieldset>
        </form>
      </div>
      <div style="clear: both;">You may want to view the <a href="/api/ApiKeys.html">API Key FAQ</a> if you are unfamiliar with API Keys.</div>
    };
    return $self->wrapper($out, { title => 'Lacuna Expanse API Key Console', logo => 1 });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

