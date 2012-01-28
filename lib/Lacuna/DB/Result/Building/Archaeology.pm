package Lacuna::DB::Result::Building::Archaeology;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';
use Lacuna::Constants qw(ORE_TYPES);
use Clone qw(clone);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Construction));
};

use constant max_instances_per_planet => 1;
use constant controller_class => 'Lacuna::RPC::Building::Archaeology';

use constant university_prereq => 11;

use constant image => 'archaeology';

use constant name => 'Archaeology Ministry';

use constant food_to_build => 210;

use constant energy_to_build => 240;

use constant ore_to_build => 210;

use constant water_to_build => 190;

use constant waste_to_build => 250;

use constant time_to_build => 500;

use constant food_consumption => 20;

use constant energy_consumption => 5;

use constant ore_consumption => 5;

use constant water_consumption => 30;

use constant waste_production => 20;

sub chance_of_glyph {
    my $self = shift;
    return $self->level;
}

sub is_glyph_found {
    my $self = shift;
    return rand(100) <= $self->chance_of_glyph;
}

sub get_ores_available_for_processing {
    my ($self) = @_;
    my $body = $self->body;
    my %available;
    foreach my $type (ORE_TYPES) {
        my $stored = $body->type_stored($type);
        if ($stored >= 10_000) {
            $available{ $type } = $stored;
        }
    }
    return \%available;
}

sub can_search_for_glyph {
    my ($self, $ore) = @_;
    unless ($self->level > 0) {
        confess [1010, 'The Archaeology Ministry is not finished building yet.'];
    }
    unless ($ore ~~ [ ORE_TYPES ]) {
        confess [1005, $ore.' is not a valid type of ore.'];
    }
    if ($self->is_working) {
        confess [1010, 'The Archaeology Ministry is already searching for a glyph.'];
    }
    unless ($self->body->type_stored($ore) >= 10_000) {
        confess [1011, 'Not enough '.$ore.' in storage. You need 10,000.'];
    }
    return 1;
}

sub search_for_glyph {
    my ($self, $ore) = @_;
    $self->can_search_for_glyph($ore);
    my $body = $self->body;
    $body->spend_ore_type($ore, 10_000);
    $body->add_waste(5000);
    $body->update;
    $self->start_work({
        ore_type    => $ore,
    }, 60*60*6)->update;
}

before finish_work => sub {
    my $self = shift;
    if ($self->is_glyph_found) {
        my $ore = $self->work->{ore_type};
        my $body = $self->body;
        $body->add_glyph($ore);
        my $empire = $body->empire;
        $empire->send_predefined_message(
            tags        => ['Alert'],
            filename    => 'glyph_discovered.txt',
            params      => [$body->id, $body->name, $ore],
            attachments => {
                image => {
                    title   => $ore,
                    url     => 'https://d16cbq0l6kkf21.cloudfront.net/assets/glyphs/'.$ore.'.png',
                }
            }
        );
        $empire->add_medal($ore.'_glyph');
        $body->add_news(70, sprintf('%s has uncovered a rare and ancient %s glyph on %s.',$empire->name, $ore, $body->name));
    }
};

sub make_plan {
    my ($self, $ids) = @_;
    unless (ref $ids eq 'ARRAY' && scalar(@{$ids}) < 5) {
        confess [1009, 'It is not possible to combine more than 4 glyphs.'];
    }

    my @glyph_names;
    my $glyphs_rs = $self->body->glyphs;
    foreach my $id (@{$ids}) {
        my $glyph = $glyphs_rs->find($id);
        confess [1002, 'You tried to combine a glyph you do not have.'] unless defined $glyph;
        push @glyph_names,$glyph->type;
    }

    my $plan_class = Lacuna::DB::Result::Plans->check_glyph_recipe(\@glyph_names);
    if (not $plan_class) {
        confess [1002, 'The glyphs specified do not fit together in that manner.'];
    }
    $glyphs_rs->search({ id => { in => $ids}})->delete;
    return $self->body->add_plan($plan_class, 1);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
