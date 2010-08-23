use strict;
use File::Find;
use 5.010;

my $pngout = '/usr/bin/pngout';
my $path = $ARGV[0];

find(sub {
   if (-f $File::Find::name && $File::Find::name =~ m/\.png$/) {
        say $File::Find::name;
	system($pngout . ' '. $File::Find::name);
   }
},
$path);

