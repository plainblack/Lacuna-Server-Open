use 5.010;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna::DB;
use Lacuna;
use DateTime;
use Net::Amazon::S3;
use Text::CSV_XS;
my $out;
my $csv = Text::CSV_XS->new({binary => 1});
$csv->combine(qw(id name x y color zone));
$out .= $csv->string."\n";
#say $csv->string;
my $stars = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star');
while (my $star = $stars->next) {
    if ($csv->combine( $star->id, $star->name, $star->x, $star->y, $star->color, $star->zone )) {
        $out .= $csv->string."\n";
        #say $csv->string;
    }
    else {
        say "ERROR", $csv->error_input;
    }
}

my $config = Lacuna->config;
my $s3 = Net::Amazon::S3->new(
    aws_access_key_id     => $config->get('access_key'), 
    aws_secret_access_key => $config->get('secret_key'),
    retry                 => 1,
    );
my $bucket = $s3->bucket($config->get('feeds/bucket'));
$bucket->add_key(
    'stars.csv',
    $out,
    {
        'Content-Type'  => 'text/csv',
         acl_short       => 'public-read',
    }
);

