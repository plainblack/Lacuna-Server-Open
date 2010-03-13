use lib '../lib';
use Test::More tests => 8;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;

$result = $tester->post('inbox','send_message', [$session_id, $tester->empire_name.', Some Guy', 'my subject', 'my body']);
is($result->{result}{message}{sent}[0], $tester->empire_name, 'send message works');
is($result->{result}{message}{unknown}[0], 'Some Guy', 'detecting unknown recipients works');

sleep 2;

$result = $tester->post('inbox','view_inbox', [$session_id]);
is($result->{result}{messages}[1]{subject}, 'my subject', 'view inbox works');
is($result->{result}{status}{empire}{has_new_messages}, 2, 'new message count works');
my $message_id = $result->{result}{messages}[1]{id};

$result = $tester->post('inbox', 'read_message', [$session_id, $message_id]);
is($result->{result}{message}{body}, 'my body', 'can view a message');

$result = $tester->post('inbox','view_sent', [$session_id]);
is($result->{result}{messages}[0]{subject}, 'my subject', 'view sent works');

$result = $tester->post('inbox', 'archive_messages', [$session_id, [$message_id]]);
is($result->{result}{success}, 1, 'archiving works');

sleep 1;

$result = $tester->post('inbox','view_archived', [$session_id]);
is($result->{result}{messages}[0]{subject}, 'my subject', 'view archived works');


END {
    $tester->cleanup;
}
