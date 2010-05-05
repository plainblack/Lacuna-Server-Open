use lib '../lib';
use strict;
use Lacuna::DB;

my $db = Lacuna::DB->connect('DBI:mysql:lacuna','root');
$db->create_ddl_dir(['MySQL'],'1.0','/data/Lacuna-Server/var/');
