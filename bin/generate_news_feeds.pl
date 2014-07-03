use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna;
use XML::FeedPP;
use DateTime;
use Net::Amazon::S3;
use Encode;

my $config = Lacuna->config;
my $db = Lacuna->db;
my $s3 = Net::Amazon::S3->new(
    aws_access_key_id     => $config->get('access_key'), 
    aws_secret_access_key => $config->get('secret_key'),
    retry                 => 1,
    );
my $bucket = $s3->bucket($config->get('feeds/bucket'));
my $news_domain = $db->resultset('Lacuna::DB::Result::News');
foreach my $x (int($config->get('map_size/x')->[0]/250) .. int($config->get('map_size/x')->[1]/250)) {
    foreach my $y (int($config->get('map_size/y')->[0]/250) .. int($config->get('map_size/y')->[1]/250)) {
        my $zone = $x.'|'.$y;
        say $zone;
        my $feed = XML::FeedPP::RSS->new;
        $feed->title('Network 19 Zone '.$zone.' News');
        $feed->description('Network 19 is the trusted name in news for the Lacuna Expanse.');
        $feed->link('http://www.lacunaexpanse.com/');
        my $rs = $news_domain->search(
            {
                zone        => $zone,
            },
            {
                rows        => 100,
                order_by    => { -desc => 'date_posted' },
            }
        );
        while (my $story = $rs->next) {
	    say $story->headline;
            my $item = $feed->add_item;
            $item->title(encode("UTF-8",$story->headline));
            $item->pubDate($story->date_posted);
        }
        say "Uploading...";
        $bucket->add_key(
            Lacuna::DB::Result::News->feed_filename($zone),
            $feed->to_string,
            {
                'Content-Type'  => 'application/rss+xml',
                 acl_short       => 'public-read',
            }
        );
    }
}

say "Finished!";


