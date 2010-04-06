use lib '../lib';
use Test::More tests => 15;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;
my $message_body = 'this is my message body, it just keeps going and going and going';
$result = $tester->post('inbox','send_message', [$session_id, $tester->empire_name.', Some Guy', 'my subject', $message_body]);
is($result->{result}{message}{sent}[0], $tester->empire_name, 'send message works');
is($result->{result}{message}{unknown}[0], 'Some Guy', 'detecting unknown recipients works');

sleep 3;

$result = $tester->post('inbox','view_inbox', [$session_id, { tags=>['Tutorial'] }]);
is(scalar(@{$result->{result}{messages}}), 1, 'fetching back by tag works');

$result = $tester->post('inbox','view_inbox', [$session_id]);
is($result->{result}{message_count}, 5, 'message_count works');
is($result->{result}{messages}[0]{subject}, 'my subject', 'view inbox works');
is($result->{result}{messages}[0]{tags}->[0], 'Correspondence', 'view inbox works');
is($result->{result}{status}{empire}{has_new_messages}, 5, 'new message count works');
is($result->{result}{messages}[0]{body_preview}, 'this is my message body, it ju', 'body preview');
my $message_id = $result->{result}{messages}[0]{id};

$result = $tester->post('inbox', 'read_message', [$session_id, $message_id]);
is($result->{result}{message}{body}, $message_body, 'can view a message');

$result = $tester->post('inbox','view_sent', [$session_id]);
is(scalar(@{$result->{result}{messages}}), 0, 'should not see messages i sent myself in sent');

$result = $tester->post('inbox', 'archive_messages', [$session_id, [$message_id]]);
is($result->{result}{success}[0], $message_id, 'archiving works');

sleep 1;

$result = $tester->post('inbox','view_archived', [$session_id]);
is($result->{result}{messages}[0]{subject}, 'my subject', 'view archived works');

$result = $tester->post('inbox', 'archive_messages', [$session_id, [$message_id,'adsfafdsfads']]);
is($result->{result}{failure}[0], $message_id, 'archived messages cannot be archived again');
is($result->{result}{failure}[1], 'adsfafdsfads', 'unknown messages cannot be archived');

$result = $tester->post('inbox','send_message', [$session_id, $tester->empire_name, 'my subject', "foo\n\nbar"]);
is($result->{result}{message}{sent}[0], $tester->empire_name, 'you can send a message with double carriage return');



END {
    $tester->cleanup;
}
