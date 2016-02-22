use lib '../lib';

use strict;
use warnings;

use Test::More tests => 7;
use Test::Deep;
use Test::Memory::Cycle;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna;
use TestHelper;


my $now     = DateTime->now;
my $later   = DateTime->now->add( seconds => 3);

my $dur     = $later->subtract_datetime_absolute($now);
my $seconds = $dur->in_units('seconds');

is($seconds, 3, "CPAN modules agree on seconds");

my $db = Lacuna->db;
my $thing = $db->resultset('ApiKey')->create({
    public_key      => 'foo',
    private_key     => 'bar',
    name            => 'iain',
    ip_address      => '10.11.12.13',
    email           => 'iain@docherty.me',
});

my $schedule = $db->resultset('Schedule')->create({
    queue           => 'reboot-build',
    delivery        => $later,
    parent_table    => 'ApiKey',
    parent_id       => $thing->id,
    task            => 'bar',
    args            => {this => 'siht', that => 'taht'},
});

isa_ok($schedule, 'Lacuna::DB::Result::Schedule', 'Correct class');
exit;


# Now test against beanstalk (it must be running)
#
my $queue = Lacuna::Queue->new;

isa_ok($queue, 'Lacuna::Queue', 'Correct queue class');

my $job = $queue->consume('foo');

isa_ok($job, 'Lacuna::Queue::Job', 'Correct job class');

my $payload = $job->payload;
isa_ok($payload, 'Lacuna::DB::Result::ApiKey', 'Got back an ApiKey');
is($payload->public_key,'foo', 'foo found');
is($payload->name,'iain', 'iain found');

$now = DateTime->now;
diag("later = [$later] now = [$now]");

# Delete this job, we no longer need it
$job->delete;


1;

