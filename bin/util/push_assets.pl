use strict;
use File::Find;
use 5.010;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use DateTime;
use File::Slurp;
use Net::Amazon::S3;
use Getopt::Long;
use DateTime::Format::HTTP;

$|=1;

our $quiet;
our $start = '/data/Lacuna-Assets/';
our @pushes;

GetOptions(
    'quiet'         => \$quiet,  
    'start=s'       => \$start,
    'push=s'        => \@pushes,
);


my $config = Lacuna->config;
my $s3 = Net::Amazon::S3->new(
    aws_access_key_id     => $config->get('access_key'), 
    aws_secret_access_key => $config->get('secret_key'),
    retry                 => 1,
    );
my $bucket = $s3->bucket('game.lacunaexpanse.com');

my %types = (
    png   => "image/png",
    jpg   => "image/jpeg",
    gif   => "image/png",
    css   => "text/css",
    json  => "application/json",
    html  => "text/html",
    txt  => "text/plain",
    cur  => "image/x-win-bitmap",
);

if (scalar @pushes) {
    foreach my $push (@pushes) {
        if (-f $push) {
            push_file($push);
        }
        elsif (-d $push) {
            push_dir($push);
        }
        else {
            say "Skipping $push";
        }
    }
    exit;
}

die 'start must end with a slash' unless ($start =~ m/\/$/);
push_dir($start);

sub push_dir {
    my $path = shift;
    find(sub {
        push_file($File::Find::name);
    },
    $path);
}

sub push_file {
    my ($path) = @_;
    $path =~ m/^(.*)\/(.*)$/;
    my $dir = $1;
    my $name = $2;
    $dir =~ m/^$start(.*)$/;
    my $sansstart = $1;
    if (-f $path && $name !~ m/^\./ && $sansstart !~ m/^\./) {
        say $path;
        my $assets = 'assets/'.$sansstart;
        my $s3path = $assets.'/'.$name;
        say $s3path;
        my $type = "text/plain";
        if ($name =~ m/\.(.\w+)$/) {
            $type = $types{$1};
        }
        else {
            warn "MIME type not found for ".$path;
        }
        say $type;
        #my $contents = read_file($File::Find::name, binmode => ':raw');
        $bucket->add_key_filename(
            $s3path,
            $path,
            {
                'Content-Type'  => $type,
                'Expires'       => DateTime::Format::HTTP->format_datetime(DateTime->now->add(years=>5)),
                'Cache-Control' => 'max-age=290304000, public', 
                acl_short       => 'public-read',
            }
        ) or die $s3->err . ": " . $s3->errstr;
    }
    else {
        warn "Skipping ".$path;
    }
}

