package Lacuna::Web;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends qw(Plack::Component);
use Plack::Request;
use Encode;

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
		my $reason = $@;
        if ($reason) {
            my $message = $reason;
            my %options = (
                request     => $request,
                status      => 500,
                debug       => 1,
            );
            if (ref $reason eq 'ARRAY') {
                $message = $reason->[1];
                if ($reason->[0] > 99 && $reason->[0] < 600) {
                    $options{status} = $reason->[0];
                    $options{debug} = 0;
                }
            }
            $out = $self->format_error($message, \%options);
        }
    }
    else {
        $out = $self->format_error( 'Whatever you were looking for is not here.', { status => 404 });
    }
    if (ref $out ne 'ARRAY') {
        $out = $self->format_error( $method_name.' did not return a properly structured response.');
    }

    # process response
    my $response = $request->new_response;
    if (exists $out->[1]{status} && $out->[1]{status} eq 302) {
        $response->redirect($out->[0]);
    }
    else {
    	$response->status($out->[1]{status} || 200);
        $response->content_type($out->[1]{content_type} || 'text/html');
        $response->body(encode_utf8($out->[0]));
    }
    return $response->finalize;
}

sub get_session {
    my ($self, $session_id) = @_;
    if (ref $session_id eq 'Lacuna::DB::Result::Session') {
        return $session_id;
    }
    else {
        my $session = Lacuna::Session->new(id=>$session_id);
        if ($session->empire_id) {
            $session->extend;
            return $session;
        }
        else {
            return undef;
        }
    }
}

sub format_error {
    my ($self, $message, $options) = @_;
    my $out = $message;
    if ($options->{debug}) {
        $out .= ' <hr> ';
        if (ref $options->{request} eq 'Plack::Request') {
            foreach my $key ($options->{request}->parameters->keys) {
                $out .= $key.': '.$options->{request}->param($key).'<br>';
            }
        }
        else {
            $out .= 'No request object!';
        }
    }
    return $self->wrapper($out, { title => 'Error', logo => 1, status => ($options->{status} || 500) });
}

sub wrapper {
    my ($self, $content, $options) = @_;
    if (open my $file, "<", '/data/Lacuna-Server-Open/var/wrapper.html') {
        my $html;
        {
            local $/;
            $html = <$file>;
        }
        close $file;
        if ($options->{logo}) {
            $content = '<div id="logo"><img src="https://s3.amazonaws.com/www.lacunaexpanse.com/logo.png"></div>'.$content;
        }
        return [ sprintf($html, ($options->{title} || 'The Lacuna Expanse'), $options->{head_tags}, $content), { status => $options->{status} } ];    
    }
    return ['Could not open wrapper template.', {status => 500} ];    
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

