#!/bin/env perl

use strict;
use Firebase;
use Config::JSON;
use Getopt::Long;
use feature 'say';
use Data::Dumper;

GetOptions( 
    'config=s'  =>, \my $config_file,
);


unless ($config_file) {
    say "Usage: $0 --config=/path/to/config.json";
    exit;
}

say "Reading config.";
my $config = Config::JSON->new($config_file)->get('firebase');

say "Connecting to Firebase.";
my $firebase = Firebase->new(%{$config});

say "Fetching rooms.";
my $rooms = $firebase->get('room-metadata');

say "Fetching users attached to rooms.";
my $room_users = $firebase->get('room-users');

say "Deleting abandoned rooms.";
foreach my $room (keys %{$rooms}) {
    if ($rooms->{$room}{type} eq 'official') {
        say "Skipping ".$rooms->{$room}{name}.", because it's an official room.";
    }
    elsif (exists $room_users->{$room}) {
        say "Skipping ".$rooms->{$room}{name}.", because it has connected users.";
    }
    else {
        say "Deleting ".$rooms->{$room}{name}.".";
        $firebase->delete('room-messages/'.$room);
        $firebase->delete('room-metadata/'.$room);
    }
}


