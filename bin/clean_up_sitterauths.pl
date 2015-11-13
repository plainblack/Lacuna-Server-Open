use 5.10.0;
use strict;
use warnings;
use lib '/data/Lacuna-Server/lib';
use Getopt::Long;

use L;

GetOptions(
    'quiet!'        => \$quiet,
);

out("Started.");

my $rs = LD->resultset("SitterAuths");

# we do not warn about expired auths since we've already warned them for the
# previous AUTH_WARNING_DAYS days.
out("Checking for messages to send.");

my $soon = DateTime->now()->add(days => $rs->AUTH_WARNING_DAYS);
my $dtf = Lacuna->db->storage->datetime_parser;

my $warnings = $rs->search(
                           {
                               expiry => {
                                   '<' => $dtf->format_datetime($soon),
                                   '>' => $dtf->format_datetime(DateTime->now),
                               },
                           },
                           {
                               join => ['sitter', 'baby'],
                               '+select' => [ 'sitter.name', 'baby.name' ],
                               '+as'     => [ 'sitter_name', 'baby_name' ],
                           },
                          );

my %expiring_sitters;
my %expiring_babies;
my $now = DateTime->now;
while (my $auth = $warnings->next)
{
    my $baby_name   = $auth->get_column('baby_name');
    my $sitter_name = $auth->get_column('sitter_name');
    my %delta       = $auth->expiry->subtract_datetime($now)->deltas();
    $delta{hours}   = int($delta{minutes}/60);#/);
    $delta{minutes} %= 60;
    my $expiry      = sprintf "%d days, %02d:%02d:%02d", @delta{qw(days hours minutes seconds)};

    $expiring_sitters{$baby_name}  {$sitter_name} = $expiry;
    $expiring_babies {$sitter_name}{$baby_name}   = $expiry;
}

for my $baby_name (sort keys %expiring_sitters)
{
    out("Warning baby ", $baby_name);

    my @table = (
                 [ 'Empire', 'Expiring in' ],
                 map {
                     [
                       $_ => $expiring_sitters{$baby_name}{$_}
                     ]
                 } sort keys %{$expiring_sitters{$baby_name}}
                );

    LD->empire({name => $baby_name})->send_predefined_message(
        tags        => ['Alert'],
        params      => [ @table > 2 ? "Treaties" : "Treaty", 
                         @table > 2 ? "multiple" : "a",
                         $baby_name ],
        filename    => 'expiring_sitters.txt',
        attachments => {
            table => \@table,
        },
    );
}

for my $sitter_name (keys %expiring_babies)
{
    out("Warning sitter ", $sitter_name);

    my @table = (
                 [ 'Empire', 'Expiring in' ],
                 map {
                     [
                      $_ => $expiring_babies{$sitter_name}{$_}
                     ]
                 } sort keys %{$expiring_babies{$sitter_name}}
                );

    LD->empire({name => $sitter_name})->send_predefined_message(
        tags        => ['Alert'],
        filename    => 'expiring_babies.txt',
        params      => [ @table > 2 ? "Treaties" : "Treaty", 
                         @table > 2 ? "multiple" : "a",
                         $sitter_name ],
        attachments => {
            table => \@table,
        },
    );
}



out("Done.");
