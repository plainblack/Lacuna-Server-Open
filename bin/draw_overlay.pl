use strict;
use 5.010;
use lib '/data/Lacuna-Server/lib';

use GD;

use Lacuna;
use Math::Round;

my $img_file        = '/data/Lacuna-Server/var/www/public/influencemap/today/';
my $img             = GD::Image->newTrueColor(3000,3000);
my $clr_background  = $img->colorAllocateAlpha(0,0,0,127);
my $clr_grid        = $img->colorAllocateAlpha(75,75,75,0);
my $clr_star        = $img->colorAllocateAlpha(50,50,50,0);

$img->alphaBlending(0);
$img->saveAlpha(1);
$img->filledRectangle(0,0,2999,2999,$clr_background);

# Draw the stars over the influence
my $stars_rs = Lacuna->db->resultset('Map::Star')->search({
});
while (my $star = $stars_rs->next) {
    print($star->id."\tProcessing star ".$star->name."\n");
    draw_star_1($star->x, $star->y, $clr_star);
}

print("Processing Grid\n");
GRID: foreach my $i (0..12) {
    next GRID if $i == 6;
    my $offset = $i * 250;
    $img->filledRectangle($offset,0,$offset+2,2999,$clr_grid);
    $img->filledRectangle(0,$offset,2999,$offset+2,$clr_grid);
}

# output the image
print("Saving image file\n");
my $png_data = $img->png;
open (FILE, ">$img_file"."overlay.png") || die;
binmode(FILE);
print FILE $png_data;
close FILE;

sub draw_star_1 {
    my ($x, $y, $color) = @_;

    foreach my $v (0..3) {
        foreach my $w (0..3) {
            if ($v==1 or $v==2 or $w==1 or $w==2) {
                my $px = $x+1500-1+$v;
                my $py = 3000 - ($y+1500-1+$w);
                $img->setPixel($px,$py,$color);
            }
        }
    }
}
# HSV values in [0..1]
# (Hue, Saturation, Value)
# returns [r, g, b] values from 0 to 255
sub hsv_to_rgb {
    my ($h, $s, $v) = @_;

    my $hi  = int($h*6);
    my $f   = $h * 6 - $hi;
    my $p   = $v * (1 - $s);
    my $q   = $v * (1 - $f * $s);
    my $t   = $v * (1 - (1 - $f) * $s);
    my ($r, $g, $b);
    ($r, $g, $b) = ($v, $t, $p) if $hi == 0;
    ($r, $g, $b) = ($q, $v, $p) if $hi == 1;
    ($r, $g, $b) = ($p, $v, $t) if $hi == 2;
    ($r, $g, $b) = ($p, $q, $v) if $hi == 3;
    ($r, $g, $b) = ($t, $p, $v) if $hi == 4;
    ($r, $g, $b) = ($v, $p, $q) if $hi == 5;
    return(int($r * 256), int($g * 256), int($b * 256));
}
1;

