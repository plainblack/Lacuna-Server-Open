use strict;
use warnings;
use 5.010;
use DBI;
use Config::JSON;
use Text::Diff;
my $config = Config::JSON->new('/data/Lacuna-Server-Open/etc/lacuna.conf');
my $dev = DBI->connect($config->get('db-reboot/dsn'), $config->get('db-reboot/username'), $config->get('db-reboot/password'));
my $prod = DBI->connect('DBI:mysql:prod', $config->get('db/username'), $config->get('db/password'));

my @dev_tables = @{$dev->selectcol_arrayref("show tables")};
my @prod_tables = @{$prod->selectcol_arrayref("show tables")};
foreach my $table_name (@dev_tables) {
    say "TABLE: ".$table_name;
    my $dev_table = get_table_definition($dev, $table_name);
    my $prod_table = '';
    if ($table_name ~~ \@prod_tables) {
        $prod_table = get_table_definition($prod, $table_name);
    }
    say diff \$prod_table, \$dev_table;
}

$dev->disconnect;
$prod->disconnect;


sub get_table_definition {
    my ($db, $name) = @_;
    return $db->selectrow_arrayref("show create table $name")->[1];
}
