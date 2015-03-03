#!/bin/env perl

use strict;
use Firebase;
use Config::JSON;
use Getopt::Long;
use feature 'say';
use Data::Dumper;

GetOptions( 
    'config=s'  => \my $config_file,
    'alliance-id=s'=> \my $alliance_id,
    'alliance-name=s'=> \my $alliance_name,
    'empire-id=s' => \my $empire_id,
);


unless ($config_file && $alliance_id && $alliance_name && $empire_id) {
    say "Usage: $0 --config=/path/to/config.json --alliance-id=xxx --alliance-name='Big Cool Guys' --empire-id=yyy";
    exit;
}

say "Reading config.";
my $config = Config::JSON->new($config_file)->get('firebase');

say "Connecting to Firebase.";
my $firebase = Firebase->new(%{$config});

say "Fetching room.";
my $room = $firebase->get('room-metadata/'.$alliance_id);
if (defined $room) {
    say "Authorizing empire.";
    $firebase->patch('room-metadata/'.$alliance_id.'/authorizedUsers', {
        $empire_id => \1
    });
}
else {
    say "Creating room.";
    $firebase->put('room-metadata/'.$alliance_id, {
        id              => $alliance_id,
        name            => $alliance_name,
        type            => 'private',
        createdByUserId => $empire_id,
        '.priority'     => {'.sv' => 'timestamp'},
        authorizedUsers => {$empire_id => \1},
    });
}

say "Adding room to user's list of rooms.";
$firebase->put('users/'.$empire_id.'/rooms/'.$alliance_id, {
    id      => $alliance_id,
    active  => \1, 
    name    => $alliance_name,
});

