package WWW::Firebase::API;

use Moose;
use JSON;
use JSON::WebToken;
use DateTime;
use Data::Dumper;

has 'secret' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

sub GET {
}

sub PUT {
}

sub POST {
}

sub PATCH {
}

sub DELETE {
}



1;


