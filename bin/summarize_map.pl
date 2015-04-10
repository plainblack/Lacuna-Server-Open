# Gathers up all colony seizure info
use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
use JSON;
use utf8;


  $|=1;

  our $quiet;
  our $map_file = "/tmp/map_population.json";

  GetOptions(
    'quiet'     => \$quiet,  
    'map_file'  => \$map_file,
  );

  out('Started');
  my $start = DateTime->now;

  out('Loading DB');
  our $db = Lacuna->db;

  my $map_data = summarize_map();
  output_map($map_data, $map_file );

  my $finish = time;
  out('Finished');
  out((($finish - $start->epoch)/60)." minutes have elapsed");
exit;


###############
## SUBROUTINES
###############
sub summarize_map {

    my %map_data;
    my $star_map_size = Lacuna->config->get('map_size');
    $map_data{map} = {
      bounds => $star_map_size,
    };
#    my $bodies = $db->resultset('Lacuna::DB::Result::Map::Body');
#    out('Getting Occupied Bodies');
#    my $occupied = $bodies->search({empire_id => { '!=' => 'Null' }});
#    $map_data{colonies} = {};
#    while (my $body = $occupied->next) {
#        my $bdata = {
#            id => $body->id,
#            x => $body->x,
#            y => $body->y,
#            pop => $body->population,
#            zone => $body->zone,
#            orbit => $body->orbit,
#            star_id => $body->star_id,
#            empire_id => $body->empire_id,
#        };
#        $map_data{colonies}->{$body->id} = $bdata;
#    }
    out('Getting Seized Stars');
    my $stars  = $db->resultset('Lacuna::DB::Result::Map::Star');
    my $seized_stars = $stars->search({station_id => { '!=' => 'Null' }});
    $map_data{seized} = {};
    while (my $star = $seized_stars->next) {
        my $sdata = {
            id => $star->id,
            x  => $star->x,
            y  => $star->y,
            zone => $star->zone,
            color => $star->color,
            station_id => $star->station_id,
            aid        => $star->station->empire->alliance_id,
        };
        $map_data{seized}->{$star->id} = $sdata;
    }
    out('Getting Fissured planets');
    $map_data{fissure} = {};
    my %has_fissures = map { $_->body_id => 1 } $db->resultset('Building')->search({
        class => 'Lacuna::DB::Result::Building::Permanent::Fissure',
    })->all;
    for my $body_id (sort keys %has_fissures) {
        my $body = $db->resultset('Map::Body')->find($body_id);
        next unless $body;
        my $fdata = {
            id => $body->id,
            x => $body->x,
            y => $body->y,
            pop => $body->population,
            zone => $body->zone,
            orbit => $body->orbit,
            star_id => $body->star_id,
            empire_id => $body->empire_id,
        };
        $map_data{fissure}->{$body->id} = $fdata;
    }

    return \%map_data;
}

sub output_map {
  my ($mapping, $map_file) = @_;
  
  my $map_txt = JSON->new->utf8->encode($mapping);
  open(OUT, ">:utf8:", "$map_file");
  print OUT $map_txt;
  close(OUT);
}

# UTILITIES

sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

