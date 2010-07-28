use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Getopt::Long;

my $config = Lacuna->config;
my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached')); 

my $name;
GetOptions(
	'name=s' => \$name,
);	



my $empire = $db
	->resultset('Lacuna::DB::Result::Empire')
	->search({name => $name}, {rows=>1})
	->single;

$empire->send_message(
	from		=> $empire,
	body		=> 'This is a test message that contains all the components possible in a message.',
	subject		=> 'Test Message',
	tags		=> ['Alert'],
	attachments => {
        table => [
				['Header 1', 'Header 2'],
				['Row 1 Field 1', 'Row 1 Field 2'],
				['Row 2 Field 1', 'Row 2 Field 2'],
				],
        image => {
				url => 'http://bloximages.chicago2.vip.townnews.com/host.madison.com/content/tncms/assets/editorial/8/ec/604/8ec6048a-998e-11de-b821-001cc4c002e0.preview-300.jpg',
				title => 'JT Rocks',
				link => 'http://host.madison.com/wsj/business/article_bd9f8c96-998d-11de-87d3-001cc4c002e0.html',
				},
        link => {
				url => 'http://www.plainblack.com/',
				label => 'Plain Black',
				},
        map => {
				surface => 'surface-e',
				buildings => [
						{
							x => 0,
							y => 0,
							image => 'command4',
						},
						{
							x => -4,
							y => 2,
							image => 'apples9',
						},
					]
				}
    }
);


