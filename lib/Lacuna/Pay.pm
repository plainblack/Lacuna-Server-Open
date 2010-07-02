package Lacuna::Pay;

use Moose;
extends qw(Plack::Component);
use Plack::Request;
use feature "switch";
use Digest::MD5 qw(md5_hex);

sub call {
    my ($self, $env) = @_;
    my $request = Plack::Request->new($env);

    # figure out what is being called
    my $method_name = $request->path_info;
    $method_name =~ s{^/}{};                # remove preceeding slash
    $method_name =~ s{/}{_}g;               # replace slashes with underscores
    $method_name ||= 'default';             # if no method is specified, then display the default
    $method_name = 'www_' . $method_name;   # not all methods are public
    
    # call it
    my $out;
    my $method = $self->can($method_name);
    if ($method) {
        $out = eval{$self->$method($request)};
        if ($@) {
            $out = $self->format_error($request, $@);
        }
    }

    # process response
    my $response = $request->new_response;
    $response->status($out->[1]{status} || 200);
    $response->content_type($out->[1]{content_type} || 'text/html');
    $response->body($out->[0]);
    return $response->finalize;
}

sub calculate_jambool_signature {
    my ($self, $params, $secret) = @_;
    my $message;
    foreach my $key (sort keys %{$params}) {
        $message .= $key.$params->{$key};
    }
    $message .= $secret;
    return md5_hex($message);
}

sub jambool_buy_url {
    my ($self, $user_id) = @_;
    my $config = Lacuna->config->get('jambool');
    my %params = (
        ts          => time(),
        offer_id    => $config->{offer_id},
        user_id     => $user_id,
        action      => 'buy_currency',
    );
    $params{sig} = $self->calculate_jambool_signature(\%params, $config->{secret_key});
    delete $params{offer_id};
    delete $params{user_id};
    my $url = sprintf '%s/socialgold/v1/%s/%s/buy_currency?format=iframe', $config->{api_url}, $config->{offer_id}, $user_id;
    foreach my $key (sort keys %params) {
        $url .= sprintf '&%s=%s', $key, $params{$key};
    }
    return $url;
}

sub www_jambool_success {
    my ($self, $request) = @_;
    return [$self->wrapper('Thank you! The essentia will be added to your account momentarily.')];
}

sub www_jambool_error {
    my ($self, $request) = @_;
    return [$self->wrapper('Shucks! Something went wrong and we could not process your payment. Please try again in a few minutes.')];
}

sub www_jambool_postback {
    my ($self, $request) = @_;

    # validate signature
    my $signature = $self->calculate_jambool_signature({timestamp => $request->param('timestamp')}, Lacuna->config->get('jambool/secret_key'));
    unless ($request->param('signature') eq $signature) {
        return ['Invalid Signature', { status => 400 }];
    }

    # get user account
    my $empire_id = $request->param('user_id');
    unless ($empire_id) {
        return ['Not a valid user_id.', { status => 401 }];
    }
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $empire) {
        return ['Emire not found.', { status => 404 }];
    }
    
    # make sure we haven't already processed this transaction
    my $transaction_id = $request->param('socialgold_transaction_id');
    unless ($empire_id) {
        return ['Not a valid socialgold_transaction_id.', { status => 402 }];
    }
    my $transaction = Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia')->search(
        { transaction_id => $transaction_id },
        { rows => 1 }
    )->single;
    if (defined $transaction) {
        return ['Already processed this transaction.', { status => 200 }];
    }
    
    # add essentia and alert user
    my $amount = $request->param('premium_currency_amount') / 100;
    $empire->add_essentia(
        $amount,
        'Purchased via Social Gold',
        $transaction_id,
    );
    $empire->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'purchase_essentia.txt',
        params      => [$amount, $transaction_id],        
    );
        
    return ['OK'];
}

sub www_jambool_reversal {
    my ($self, $request) = @_;

    # validate signature
    my $signature = $self->calculate_jambool_signature({
            timestamp                   => $request->param('timestamp'),
            amount                      => $request->param('amount'),
            socialgold_transaction_id   => $request->param('socialgold_transaction_id'),
        },
        Lacuna->config->get('jambool/secret_key')
    );
    unless ($request->param('signature') eq $signature) {
        return ['Invalid Signature', { status => 400 }];
    }

    # get user account
    my $empire_id = $request->param('user_id');
    unless ($empire_id) {
        return ['Not a valid user_id.', { status => 401 }];
    }
    my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
    unless (defined $empire) {
        return ['Emire not found.', { status => 404 }];
    }
    
    # make sure we already gave them essentia
    my $transaction_id = $request->param('socialgold_transaction_id');
    unless ($empire_id) {
        return ['Not a valid socialgold_transaction_id.', { status => 402 }];
    }
    my $transaction = Lacuna->db->resultset('Lacuna::DB::Result::Log::Essentia')->search(
        {
            transaction_id  => $transaction_id,
        },
        { rows => 1 }
    )->single;
    unless (defined $transaction) {
        return ['No record of this transaction.', { status => 402 }];
    }
    
    # reverse the transaction
    my $amount = $transaction->amount;
    $empire->add_essentia(
        $amount,
        'Reversed via Social Gold',
        $transaction_id,
    );

        
    return ['OK'];
}

sub www_default {
    my ($self, $request) = @_;
    return ['<iframe frameborder="0" scrolling="no" width="425" height="365" src="'.$self->jambool_buy_url(1).'"></iframe>'];
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
    return [$self->wrapper($out), {status => $error->[1] || 500}];
}

sub wrapper {
    my ($self, $content) = @_;
    my $out = <<STOP;
    <html>
    <head><title>Lacuna Payment Console</title>
    </head>
    <body>
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

