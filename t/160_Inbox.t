use lib '../lib';
use Test::More tests => 19;
use Test::Deep;
use Data::Dumper;
use 5.010;


use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;

my $result;
my $message_body = 'this is my message body, it just keeps going and going and going';
$result = $tester->post('inbox','send_message', [$session_id, $tester->empire_name.', Some Guy', 'my subject', $message_body]);
is($result->{result}{message}{sent}[0], $tester->empire_name, 'send message works');
is($result->{result}{message}{unknown}[0], 'Some Guy', 'detecting unknown recipients works');

$result = $tester->post('inbox','view_inbox', [$session_id, { tags=>['Tutorial'] }]);
is(scalar(@{$result->{result}{messages}}), 1, 'fetching by tag works');

$result = $tester->post('inbox','view_inbox', [$session_id]);
is($result->{result}{message_count}, 5, 'message_count works');
ok($result->{result}{messages}[0]{subject}, 'view inbox works');

my $archive_id = $result->{result}{messages}[0]{id};
my $trash_id = $result->{result}{messages}[1]{id};

$result = $tester->post('empire','get_status', [$session_id]);
is($result->{result}{empire}{has_new_messages}, 5, 'new message count works');

$result = $tester->post('inbox', 'read_message', [$session_id, $archive_id]);
is($result->{result}{message}{id}, $archive_id, 'can view a message');

$result = $tester->post('inbox','view_sent', [$session_id]);
is(scalar(@{$result->{result}{messages}}), 0, 'should not see messages i sent myself in sent');

$result = $tester->post('inbox', 'archive_messages', [$session_id, [$archive_id]]);
is($result->{result}{success}[0], $archive_id, 'archiving works');

$result = $tester->post('inbox','view_archived', [$session_id]);
is($result->{result}{messages}[0]{id}, $archive_id, 'view archived works');

$result = $tester->post('inbox', 'archive_messages', [$session_id, [$archive_id,'adsfafdsfads']]);
is($result->{result}{failure}[0], $archive_id, 'archived messages cannot be archived again');
is($result->{result}{failure}[1], 'adsfafdsfads', 'unknown messages cannot be archived');

$result = $tester->post('inbox', 'trash_messages', [$session_id, [$trash_id]]);
is($result->{result}{success}[0], $trash_id, 'archiving works');

$result = $tester->post('inbox','view_trashed', [$session_id]);
is($result->{result}{messages}[0]{id}, $trash_id, 'view trashed works');

$result = $tester->post('inbox', 'trash_messages', [$session_id, [$trash_id,'adsfafdsfads']]);
is($result->{result}{failure}[0], $trash_id, 'trashed messages cannot be trashed again');
is($result->{result}{failure}[1], 'adsfafdsfads', 'unknown messages cannot be trashed');

$result = $tester->post('inbox', 'archive_messages', [$session_id, [$trash_id]]);
is($result->{result}{success}[0], $trash_id, 'archiving a trashed message works');

$result = $tester->post('inbox', 'trash_messages', [$session_id, [$archive_id]]);
is($result->{result}{success}[0], $archive_id, 'trashing a archived message works');

$result = $tester->post('inbox','send_message', [$session_id, $tester->empire_name, 'my subject', "foo\n\nbar"]);
is($result->{result}{message}{sent}[0], $tester->empire_name, 'you can send a message with double carriage return');

END {
    TestHelper->clear_all_test_empires;
}
