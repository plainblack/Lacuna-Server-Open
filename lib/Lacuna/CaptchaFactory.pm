package Lacuna::CaptchaFactory;

use strict;
use Moose;
use utf8;
no warnings qw(uninitialized);
use UUID::Tiny ':std';
use GD::SecurityImage;

use Lacuna;
use Lacuna::Util qw(random_element);

has 'riddle' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_riddle',
);

has 'font' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_font',
);

has 'style' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_style',
);
has 'bg_color' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_bg_color',
);
has 'fg_color' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_fg_color',
);
has 'guid'      => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_guid',
);
has 'fonts' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_fonts',
);
has 'font_path' => (
    is          => 'rw',
    lazy        => 1,
    builder     => '_build_font_path',
);

my %riddles = (
    "1x1x1=_"     => "1",
    "0x0x0=_"     => "0",
    "0+0+0=_"     => "0",
    "0-0-0=_"     => "0",
    "1/1=_"       => "1",
    "2/1=_"       => "2",
    "2/2=_"       => "1",
    "4/2=_"       => "2",
    "6/2=_"       => "3",
    "6/3=_"       => "2",
    "9/3=_"       => "3",
    "10/2=_"      => "5",
    "10/5=_"      => "2",
    "12/3=_"      => "4",
    "12/4=_"      => "3",
);

for my $a (1..9) {
    for my $b (1..9) {
        $riddles{$a.'+'.$b.'=_'} = $a + $b;
        $riddles{$a.'-'.$b.'=_'} = $a - $b;
        $riddles{$a.'x'.$b.'=_'} = $a * $b;
    }
}
for my $a ('a'..'c') {
   for (1..4) {
       my $string = $a++;
       $string .= $a++;
       my $answer = $a++;
       $answer .= $a++;
       $string .= '_';
       $string .= $a++;
       $string .= $a++;
       $riddles{$string} = $answer;
   }
}    

for my $a ('a'..'c') {
    for (1..4) {
        my $string = $a++;
        $string .= uc($a++);
        my $answer = $a++;
        $answer .= uc($a++);
        $string .= '_';
        $string .= $a++;
        $string .= uc($a++);
        $riddles{$string} = $answer;
    }
}

for my $a ('1'..'2') {
    for (1..2) {
        my $string = $a++;
        $string .= ',';
        $string .= $a++;
        my $answer = $a++;
        $answer .= ',';
        $answer .= $a++;
        $string .= ',_,';
        $string .= $a++;
        $string .= ',';
        $string .= $a++;
        $riddles{$string} = $answer;
    }
}
for my $a ('a'..'i') {
    for (1..2) {
        my $string = $a++;
        $string .= $a++;
        $string .= $a++;
        my $answer = $a++;
        $answer .= $a++;
        $answer .= $a++;
        $string .= '_';
        $string .= $a++;
        $string .= $a++;
        $string .= $a++;
        $riddles{$string} = $answer;
    }
}

# Return a random riddle from the list of riddles
sub _build_riddle {
    my ($self) = @_;

    my $key = random_element(keys %riddles);
    return [ $key => $riddles{$key} ];
}

# The array of fonts from which to choose
sub _build_fonts {
    my ($self) = @_;
    return [ "Ayuthaya", "Chalkduster", "HeadlineA", "Kai" ];
}

# return a random font from the fonts
sub _build_font {
    my ($self) = @_;

    return random_element(@{$self->fonts});
}

# return a random style
sub _build_style {
    my ($self) = @_;

    return random_element(qw(default rect circle ellipse ec blank));
}

# return a random background color
sub _build_bg_color {
    my ($self) = @_;

    return random_element('#666600', '#660066', '#006666');
}

# return a random foreground color
sub _build_fg_color {
    my ($self) = @_;
    
    return random_element('#ddffff', '#ffddff', '#ffffdd');
}

# return a random UUID
sub _build_guid {
    my ($self) = @_;
    return create_uuid_as_string(UUID_V4);
}

# The folder where fonts can be found
sub _build_font_path {
    my ($self) = @_;
    
    return "/Library/Fonts";
}

# Construct the image
sub construct {
    my ($self) = @_;

    my $captchas = Lacuna->db->resultset('Lacuna::DB::Result::Captcha');

    my ($image,$mime,$string) = GD::SecurityImage
        ->new(
            width   => 300,
            height  => 80,
            lines   => 20,
            font    => $self->font_path.'/'.$self->font.'.ttf',
            bgcolor => $self->bg_color,
            ptsize  => 32,
            rndmax  => 3,
            #send_ctobg => 1,
            #thickness => 4,
            #scramble => 1,
            angle => 3,
        )
        ->random($self->riddle->[0])
        ->create( 'ttf', $self->style, $self->fg_color, ($self->bg_color+10) )
        ->particle
        ->info_text(
            x      => 'left',
            y      => 'up',
            gd     => 1,
            strip  => 1,
            color  => '#000000',
            scolor => '#FFFFFF',
            text   => 'Fill in the blank:',
        )
        ->out(
            force   => 'png',
            compress=> 1,
        );
    my $prefix = substr($self->guid, 0,2);
    my $dir = '/data/captcha/'.$prefix;
    unless (-d $dir) {
        mkdir $dir;
    }
    open my $file, '>', $dir.'/'.$self->guid.'.png';
    print {$file} $image;
    close $file;
    $captchas->create({
        guid    => $self->guid,
        riddle  => $self->riddle->[0],
        solution=> $self->riddle->[1],
    });
}
    


no Moose;
__PACKAGE__->meta->make_immutable;

