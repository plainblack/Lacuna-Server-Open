package Lacuna::Web::Pay;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw(Lacuna::Web);
use Digest::MD5 qw(md5_hex);
use Digest::HMAC_SHA1;
use XML::Hash::LX;
use Tie::IxHash;
use LWP::UserAgent;

sub pay_by_credit_card {
    my ($self, $params) = @_;
    confess [1009, 'Card number is required.'] unless $params->{card_number};
    confess [1009, 'Expiration month is required and must be 2 digits.'] unless ($params->{expiration_month} && length($params->{expiration_month}) == 2);
    confess [1009, 'Expiration year is required and must be 4 digits.'] unless ($params->{expiration_year} && length($params->{expiration_year}) == 4);
    confess [1009, 'CVV2 is required and must be 3 or 4 digits.'] unless ($params->{cvv2} && length($params->{cvv2}) >= 3 && length($params->{cvv2}) <= 4);
    my $config = Lacuna->config->get('itransact');
    my @name = split /\s+/, $params->{billingaddress}{name};
    my %payload;
    tie %payload, 'Tie::IxHash';
    %payload = (
        GatewayInterface    => {
            APICredentials  => {
                Username            => $config->{APIUsername},
                TargetGateway       => $config->{Gateway},
            },
            AuthTransaction => {
                CustomerData    => {
                    Email           => $params->{user}->{email},
                    BillingAddress  => {
                        Address1        => $params->{billingaddress}{address1},
                        Address2        => $params->{billingaddress}{address2},
                        FirstName       => shift @name,
                        LastName        => join ' ', @name,
                        City            => $params->{billingaddress}{city},
                        State           => $params->{billingaddress}{state},
                        Zip             => $params->{billingaddress}{postal_code},
                        Country         => $params->{billingaddress}{country},
                        Phone           => $params->{billingaddress}{phone_number},
                    },
                    CustId          => $params->{user}{username},
                },
                Total               => $params->{total},
                Description         => 'Essentia Order #'.$params->{order_number},
                AccountInfo         => {
                    CardAccount => {
                        AccountNumber   => $params->{card_number},
                        ExpirationMonth => $params->{expiration_month},
                        ExpirationYear  => $params->{expiration_year},
                        CVVNumber       => $params->{cvv2},
                    },
                },
                TransactionControl  => {
                    SendCustomerEmail   => $config->{SendCustomerEmail},
                    SendMerchantEmail   => $config->{SendMerchantEmail},
                    TestMode            => $config->{TestMode},
                },
            },
        },
    );
    my $xml = hash2xml \%payload;
    my $hmac = Digest::HMAC_SHA1->new($config->{APIKey});
    $hmac->add($xml);
    $payload{GatewayInterface}{APICredentials}{PayloadSignature} = $hmac->b64digest . '=';
    $xml = hash2xml \%payload;
    my $response = LWP::UserAgent->new->post(
        'https://secure.itransact.com/cgi-bin/rc/xmltrans2.cgi',
        Content_Type    => 'text/xml',
        Content         => $xml,
        Accept          => 'text/xml',
    );
    $self->payment_method('Credit Card');
    if ($response->is_success) {
        my $result = xml2hash $response->decoded_content;
        $result = $result->{GatewayInterface}{TransactionResponse}{TransactionResult};
        if($result->{Status} eq 'ok') {
            # show success message
            # add essentia
        }
        else {
            confess [1009, 'Card was rejected: '.$result->{XID}];
        }
    }
    else {
        confess [1009, 'Could not connect to the credit card processor.'];
    }
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
    my $script = "
     try {
      window.opener.YAHOO.lacuna.Essentia.paymentFinished();
      window.setTimeout( function () { window.close() }, 5000);
      } catch (e) {}
    ";
    return $self->wrap('Thank you! The essentia will be added to your account momentarily.<script type="text/javascript">'.$script.'</script>');
}

sub www_jambool_error {
    my ($self, $request) = @_;
    return $self->format_error('Shucks! Something went wrong and we could not process your payment. Please try again in a few minutes.');
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
    )->update;
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
    my $session = $self->get_session($request->param('session_id'));
    unless (defined $session) {
        confess [ 401, 'You must be logged in to purchase essentia.'];
    }
    if ($session->is_sitter) {
        confess [ 401, 'Sitters cannot purchase essentia.'];
    }
    my $empire = $session->empire;
    unless (defined $empire) {
        confess [401, 'Empire not found.'];
    }
    return $self->wrap('<div style="margin: 0 auto;width: 425;"><iframe frameborder="0" scrolling="no" width="425" height="365" src="'.$self->jambool_buy_url($empire->id).'"></iframe></div>');
}

sub wrap {
    my ($self, $content) = @_;
    return $self->wrapper($content, { title => 'Purchase Essentia', logo => 1 });
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

