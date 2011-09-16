use lib '../lib';
use Test::More tests => 54;

use_ok('Lacuna::Verify');

my $foo = Lacuna::Verify->new(content=>\'foo', throws=>'NO');

isa_ok($foo, 'Lacuna::Verify');

ok($foo->ok(1), 'ok');
is(eval{$foo->ok(0)}, undef, 'ok - fail');
like($@, qr/^NO/, 'ok exception');
ok($foo->not_ok(0), 'not_ok');
is(eval{$foo->not_ok(1)}, undef, 'not_ok - fail');
like($@, qr/^NO/, 'not ok exception');

ok($foo->eq('foo'), 'eq');
is(eval{$foo->eq(0)}, undef, 'eq - fail');
like($@, qr/^NO/, 'ne exception');
ok($foo->ne(0), 'ne');
is(eval{$foo->ne('foo')}, undef, 'ne - fail');
like($@, qr/^NO/, 'ne exception');

ok($foo->length_gt(2), 'length_gt');
is(eval{$foo->length_gt(3)}, undef, 'length_gt - fail');
like($@, qr/^NO/, 'length gt exception');
ok($foo->length_lt(4), 'length_lt');
is(eval{$foo->length_lt(3)}, undef, 'length_lt - fail');
like($@, qr/^NO/, 'length lt exception');

ok($foo->no_restricted_chars, 'no_restricted_chars');
my $at = Lacuna::Verify->new(content=>\'foo@bar', throws=>'NO');
is(eval{$at->no_restricted_chars}, undef, 'no_restricted_chars - @');
like($@, qr/^NO/, 'rc @ exception');
my $gt = Lacuna::Verify->new(content=>\'foo>bar', throws=>'NO');
is(eval{$gt->no_restricted_chars}, undef, 'no_restricted_chars - >');
like($@, qr/^NO/, 'rc >  exception');
my $lt = Lacuna::Verify->new(content=>\'foo<bar', throws=>'NO');
is(eval{$lt->no_restricted_chars}, undef, 'no_restricted_chars - <');
like($@, qr/^NO/, 'rc < exception');
my $amp = Lacuna::Verify->new(content=>\'foo&bar', throws=>'NO');
is(eval{$amp->no_restricted_chars}, undef, 'no_restricted_chars - &');
like($@, qr/^NO/, 'rc & exception');
my $semi = Lacuna::Verify->new(content=>\'foo;bar', throws=>'NO');
is(eval{$semi->no_restricted_chars}, undef, 'no_restricted_chars - ;');
like($@, qr/^NO/, 'rc ; exception');

$gt = Lacuna::Verify->new(content=>\'foo>bar', throws=>'NO');
is(eval{$gt->no_tags}, undef, 'no_tags - >');
like($@, qr/^NO/, 'rc >  exception');
$lt = Lacuna::Verify->new(content=>\'foo<bar', throws=>'NO');
is(eval{$lt->no_tags}, undef, 'no_tags - <');
like($@, qr/^NO/, 'rc < exception');

my $empty = Lacuna::Verify->new(content=>\'', throws=>'NO');
ok($empty->empty, 'empty');
is(eval{$foo->empty}, undef, 'empty - fail');
like($@, qr/^NO/, 'empty exception');
ok($foo->not_empty, 'not_empty');
is(eval{$empty->not_empty}, undef, 'not_empty - fail');
like($@, qr/^NO/, 'not empty exception');
$empty = Lacuna::Verify->new(content=>\" \t", throws=>'NO');
is(eval{$empty->not_empty}, undef, 'not_empty whitespace - fail');
like($@, qr/^NO/, 'not empty whitespace exception');

my $shit = Lacuna::Verify->new(content=>\'shit', throws=>'NO');
ok($foo->no_profanity, 'no_profanity');
is(eval{$shit->no_profanity}, undef, 'no_profanity - fail');
like($@, qr/^NO/, 'np exception');

my $fuck = Lacuna::Verify->new(content=>\'Fuck', throws=>'NO');
is(eval{$fuck->no_profanity}, undef, 'no_profanity - uppercase fuck triggers exception');
like($@, qr/^NO/, 'np exception');

my $double_carriage_returns = Lacuna::Verify->new(content=>\"foo\n\nbar", throws=>'NO');
ok($double_carriage_returns->no_tags, '\n\n no_tags');
ok($double_carriage_returns->no_profanity, '\n\n no_profanity');
ok($double_carriage_returns->not_empty, '\n\n not_empty');

$double_carriage_returns = Lacuna::Verify->new(content=>\"foo\n\n", throws=>'NO');
ok($double_carriage_returns->not_empty, 'after \n\n not_empty');

$double_carriage_returns = Lacuna::Verify->new(content=>\"\n\nfoo", throws=>'NO');
ok($double_carriage_returns->not_empty, 'before \n\n not_empty');

my $email = Lacuna::Verify->new(content => \'jt@lacunaexpanse.com', throws => 'NO');
ok($email->is_email, 'is_email works');

# I can't see where code for this test is implemented.
#my $not_email = Lacuna::Verify->new(content => \'<script jt@lacunaexpanse.com>', throws => 'NO');
#like($@, qr/^NO/, 'is_email finds hacks');

