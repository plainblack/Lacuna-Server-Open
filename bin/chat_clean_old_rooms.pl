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
my %room_clear;
my %room_keep;
foreach my $room (keys %{$rooms}) {
    if ($rooms->{$room}{type} eq 'official') {
        say "Skipping ".$rooms->{$room}{name}.", because it's an official room.";
    }
    elsif (exists $room_users->{$room}) {
        if ($room_keep{"$rooms->{$room}{name}"}) {
            $room_keep{"$rooms->{$room}{name}"} += 1;
        }
        else {
            $room_keep{"$rooms->{$room}{name}"} = 1;
        }
    }
    else {
        if ($room_clear{"$rooms->{$room}{name}"}) {
            $room_clear{"$rooms->{$room}{name}"} += 1;
        }
        else {
            $room_clear{"$rooms->{$room}{name}"} = 1;
        }
        $firebase->delete('room-messages/'.$room);
        $firebase->delete('room-metadata/'.$room);
    }
}
foreach my $key (sort keys %room_clear) {
    say "Deleted ".$key." ".$room_clear{"$key"}.".";
}
foreach my $key (sort keys %room_keep) {
    say "Skipping ".$key." ".$room_keep{"$key"}.".";
}
