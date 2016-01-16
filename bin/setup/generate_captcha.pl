use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use GD::SecurityImage;
use UUID::Tiny ':std';
use File::Path qw(remove_tree make_path);

my $db = Lacuna->db;
my $config = Lacuna->config;
my $captchas = $db->resultset('Lacuna::DB::Result::Captcha');

say "Generating Riddles";

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

#for my $a ('a'..'c') {
#    for (1..8) {
#        my $string = $a++;
#        my $answer = $a++;
#        $string .= '_';
#        $string .= $a++;
#        $riddles{$string} = $answer;
#    }
#}
#
#for my $a ('1'..'3') {
#    for (1..3) {
#        my $string = $a++;
#        my $answer = $a++;
#        $string .= ',_,';
#        $string .= $a++;
#        $riddles{$string} = $answer;
#    }
#}

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

say "Riddle Count: ".scalar(keys %riddles);

say "Cleaning up old captchas...";
$captchas->delete;
remove_tree('/data/captcha', { keep_root => 1 });
make_path('/data/captcha');

say "Generating Captchas...";
my $counter = 0;
foreach my $riddle (keys %riddles) {
    foreach my $font (@{ $config->get('captcha/fonts') || [ "Ayuthaya", "Chalkduster", "HeadlineA", "Kai" ] }) {
        foreach my $style (qw(default rect circle ellipse ec blank)) {
            foreach my $bg_color (qw(#666600 #660066 #006666)) {
                foreach my $fg_color (qw(#ddffff #ffddff #ffffdd)) {
                    my ($image,$mime,$string) = GD::SecurityImage
                        ->new(
                            width   => 300,
                            height  => 80,
                            lines   => 20,
                            font    => ($config->get('captcha/fontpath')||"/Library/Fonts").'/'.$font.'.ttf',
                            bgcolor => $bg_color,
                            ptsize  => 32,
                            rndmax  => 3,
                            #send_ctobg => 1,
                            #thickness => 4,
                            #scramble => 1,
                            angle => 3,
                        )
                        ->random($riddle)
                        ->create( 'ttf', $style, $fg_color, ($bg_color+10) )
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
                    my $guid = create_uuid_as_string(UUID_V4);
                    my $prefix = substr($guid, 0,2);
                    my $dir = '/data/captcha/'.$prefix;
                    unless (-d $dir) {
                        mkdir $dir;
                    }
                    open my $file, '>', $dir.'/'.$guid.'.png';
                    print {$file} $image;
                    close $file;
                    $counter++;
                    $captchas->new({
                        id      => $counter,
                        guid    => $guid,
                        riddle  => $riddle,
                        solution=> $riddles{$riddle},
                    })->insert;
                }
            }
        }
    }
}

say "Generated $counter Captchas";

say "Exporting Captcha SQL...";
say "Please enter your MySQL root password:";
system "mysqldump -uroot -p --no-create-info lacuna captcha > /data/captcha/captcha.sql";
