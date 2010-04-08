use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use XML::FeedPP;
use DateTime;
use SOAP::Amazon::S3;

my $config = Lacuna->config;
my $age = DateTime->now->subtract(hours=>24);
my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached')); 
my $s3 = SOAP::Amazon::S3->new($config->get('access_key'), $config->get('secret_key'), { RaiseError => 1 });
my $bucket = $s3->bucket($config->get('feeds/bucket'));
my $news_domain = $db->domain('news');
foreach my $x (int($config->get('map_size/x')->[0]/10) .. int($config->get('map_size/x')->[1]/10)) {
    foreach my $y (int($config->get('map_size/y')->[0]/10) .. int($config->get('map_size/y')->[1]/10)) {
        foreach my $z (int($config->get('map_size/z')->[0]/10) .. int($config->get('map_size/z')->[1]/10)) {
            my $zone = $x.'|'.$y.'|'.$z;
            say $zone;
            my $feed = XML::FeedPP::RSS->new;
            $feed->title('Network 19 Zone '.$zone.' News');
            $feed->description('Network 19 is the trusted name in news for the Lacuna Expanse.');
            $feed->link('http://www.lacunaexpanse.com/');
            my $rs = $news_domain->search(
                where   => {
                    zone        => $zone,
                    date_posted => [ '>=', $age ],
                },
                limit       => 100,
                order_by    => ['date_posted'],
            );
            while (my $story = $rs->next) {
                my $item = $feed->add_item;
                $item->title($story->headline);
                $item->pubDate($story->date_posted);
            }
            my $object = $bucket->putobject(Lacuna::DB::News->feed_filename($zone), $feed->to_string, { 'Content-Type' => 'application/rss+xml' });
            $object->acl('public');
        }
    }
}




