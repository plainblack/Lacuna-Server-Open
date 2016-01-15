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
);

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
