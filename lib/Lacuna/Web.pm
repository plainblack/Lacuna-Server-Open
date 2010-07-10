package Lacuna::Web;

use Moose;
extends qw(Plack::Component);
use Plack::Request;

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
    if (ref $out ne 'ARRAY') {
        $out = [$self->wrapper('Error', $method_name.' did not return a properly structured response.'), {status => 500}];   
    }

    # process response
    my $response = $request->new_response;
    if ($out->[1]{status} eq 302) {
        $response->redirect($out->[0]);
    }
    else {
    	$response->status($out->[1]{status} || 200);
        $response->content_type($out->[1]{content_type} || 'text/html');
        $response->body($out->[0]);
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
    my ($self, $title, $content) = @_;
    if (open my $file, "<", '/data/Lacuna-Server/var/wrapper.html') {
        my $html;
        {
            local $/;
            $html = <$file>;
        }
        close $file;
        return sprintf $html, $title, $content;    
    }
    return 'Could not open wrapper template.';    
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

