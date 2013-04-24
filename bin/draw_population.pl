#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Imager;
use Imager::Fill;
use Getopt::Long qw(GetOptions);
use JSON;
use Text::CSV;

our %opts = (
    img      => "map_population.png",
    input    => "/tmp/map_population.json",
    starfile => "data/stars.csv",  # Will need to pull this from actual location.
    blur      => 0,
    ai        => 0,
    colony    => 0,
    seize     => 0,
    fissure   => 0,
);

my $ok = GetOptions(\%opts,
    'img=s',
    'input=s',
    'ai',
    'blur',
    'colony',
    'seize',
    'fissure',
    'stars',
);

  exit if (not $ok);

  my $json = JSON->new->utf8(1);

  my $bf;
  die "No $opts{input}\n" unless (-e $opts{input});
  open ($bf, "<", "$opts{input}") or die;
  my $lines = join("",<$bf>);
  my $map_data = $json->decode($lines);

  my $stars;
  if ($opts{stars} and -e $opts{starfile}) {
    $stars = get_stars("$opts{starfile}");
  }
  else {
    print "No stars loaded from $opts{starfile}\n";
  }

  my $map_size = {
    min_x => $map_data->{map}->{bounds}->{x}[0],
    max_x => $map_data->{map}->{bounds}->{x}[1],
    min_y => $map_data->{map}->{bounds}->{y}[0],
    max_y => $map_data->{map}->{bounds}->{y}[1],
    border_x => 25,
    border_y => 25,
  };

  $map_size->{size_x} = $map_size->{max_x} - $map_size->{min_x} +
                        2 * $map_size->{border_x};
  $map_size->{size_y} = $map_size->{max_y} - $map_size->{min_y} +
                        2 * $map_size->{border_y};
  
  my $bg_color = Imager::Color->new(100,100,100);
  my $border   = Imager::Color->new(0,0,0);
  my $img = Imager->new(
      xsize => $map_size->{size_x},
      ysize => $map_size->{size_y},
      alpha => 4,
  ) or die Imager->errstr;
  $img->box( xmin   => $map_size->{border_x},
             xmax   => $map_size->{size_x} - $map_size->{border_x},
             ymin   => $map_size->{border_y},
             ymax   => $map_size->{size_y} - $map_size->{border_y},
             color  => $bg_color,
             filled => 1,
           );

  my $matrix = set_matrix($map_data->{colonies}, $map_size);

  print "Drawing map\n";
  for my $key (keys %$matrix) {
    my ($px, $py) = split(/:/,$key,2);
#    printf "%11s,%04d\n",$key, $matrix{$key};
    my $color = set_color($matrix->{$key}, $matrix->{highest}, $key);
    if ($color) {
      $img->setpixel(x => $px,
                     y => $py,
                     color => $color,
                    );
    }
  }
  print "Drawing zone lines\n";
  draw_zone($img, $map_size, $border);
  if ($opts{colony}) {
      print "Drawing Colonies\n";
      draw_colonies($img, $map_data->{colonies}, $map_size);
  }
  if ($opts{seize}) {
      print "Drawing Seized\n";
      my $alliance = config_seize($map_data->{seized});
      draw_seize($img, $map_data->{seized}, $alliance, $map_size);
  }
  if ($opts{stars}) {
      print "Drawing stars\n";
      draw_stars($img, $stars, $map_size);
  }
  if ($opts{fissure}) {
      print "Drawing Fissure\n";
      draw_fissure($img, $map_data->{fissure}, $map_size);
  }

  print "High: $matrix->{highest}\n";
  $img->write(file => "$opts{img}")
    or die q{Cannot save $opts{img}, }, $img->errstr;

exit;

sub set_color {
  my ($val, $range, $key) = @_;

  my $scolor  = undef;
  return $scolor unless $val;
  return $scolor unless $range;

  my $hue = 180 + int($val * 180/$range + 0.5);

#  printf("pix: %11s %04d %03d\n", $key, $val, $hue);
  $scolor = Imager::Color->new(hue=>$hue, v=>0.8, s=>0.8);

  return $scolor;
}

sub draw_zone {
    my ($img, $map_size, $border) = @_;

    my $xline = 1;
    while (($xline * 250) < $map_size->{max_x}) {
        $img->line(
            x1 => x_coord_to_pixel( $map_size, $xline * 250),
            x2 => x_coord_to_pixel( $map_size, $xline * 250),
            y1 => y_coord_to_pixel( $map_size, $map_size->{min_y} ),
            y2 => y_coord_to_pixel( $map_size, $map_size->{max_y} ),
        );
        $xline++;
    }
    $xline = -1;
    while (($xline * 250) > $map_size->{min_x}) {
        $img->line(
            x1 => x_coord_to_pixel( $map_size, $xline * 250),
            x2 => x_coord_to_pixel( $map_size, $xline * 250),
            y1 => y_coord_to_pixel( $map_size, $map_size->{min_y} ),
            y2 => y_coord_to_pixel( $map_size, $map_size->{max_y} ),
        );
        $xline--;
    }
    my $yline = 1;
    while (($yline * 250) < $map_size->{max_y}) {
        $img->line(
            x1 => x_coord_to_pixel( $map_size, $map_size->{min_x} ),
            x2 => x_coord_to_pixel( $map_size, $map_size->{max_x} ),
            y1 => y_coord_to_pixel( $map_size, $yline * 250),
            y2 => y_coord_to_pixel( $map_size, $yline * 250),
        );
        $yline++;
    }
    $yline = -1;
    while (($yline * 250) > $map_size->{min_y}) {
        $img->line(
            x1 => x_coord_to_pixel( $map_size, $map_size->{min_x} ),
            x2 => x_coord_to_pixel( $map_size, $map_size->{max_x} ),
            y1 => y_coord_to_pixel( $map_size, $yline * 250),
            y2 => y_coord_to_pixel( $map_size, $yline * 250),
        );
        $yline--;
    }
    return;
}

sub config_seize {
    my ($seized) = @_;

    my %alliance;
    for my $sid (keys %$seized) {
        my $star = $seized->{$sid};
        $alliance{$star->{aid}} = 1;
    }
    my $a_cnt = scalar keys %alliance;
    $a_cnt = 1 if ($a_cnt < 1);
    my $step = 0;
    for my $key (sort keys %alliance) {
        my $hue = int($step * 180/$a_cnt);
        $alliance{$key} = Imager::Color->new(hue=>$hue, v=>90, s=>90);
        $step++;
    }
    return \%alliance;
}

sub draw_seize {
    my ($img, $seized, $alliance, $map_size) = @_;

    for my $bid (keys %$seized) {
	my $star = $seized->{$bid};
	my $cx = x_coord_to_pixel( $map_size, $star->{x} );
	my $cy = y_coord_to_pixel( $map_size, $star->{y} );

        $img->circle(
            x      => $cx,
            y      => $cy,
            color  => $alliance->{$star->{aid}},
            r      => 2,
            aa     => 1,
            filled => 0,
        );
        $img->circle(
            x      => $cx,
            y      => $cy,
            color  => Imager::Color->new(hue=>0, v=>0, s=>0),
            r      => 3,
            aa     => 1,
            filled => 0,
        );
    }
    return;
}

sub draw_stars {
    my ($img, $stars, $map_size) = @_;

    my %colors;
    $colors{blue}    = Imager::Color->new(  0,   0, 255);
    $colors{green}   = Imager::Color->new(  0, 255,   0);
    $colors{magenta} = Imager::Color->new(255,   0, 255);
    $colors{red}     = Imager::Color->new(255,   0,   0);
    $colors{white}   = Imager::Color->new(255, 255, 255);
    $colors{yellow}  = Imager::Color->new(255, 255,   0);
    for my $sid (keys %$stars) {
	my $star = $stars->{$sid};
	my $cx = x_coord_to_pixel( $map_size, $star->{x} );
	my $cy = y_coord_to_pixel( $map_size, $star->{y} );

        $img->setpixel(x => $cx,
                       y => $cy,
                       color => $colors{$star->{color}},
                      );
    }
    return;
}

sub draw_fissure {
    my ($img, $fissure, $map_size) = @_;

    for my $bid (keys %$fissure) {
	my $fizz = $fissure->{$bid};
	my $cx = x_coord_to_pixel( $map_size, $fizz->{x} );
	my $cy = y_coord_to_pixel( $map_size, $fizz->{y} );

        my $body_color = Imager::Color->new(hue=>0, v=>0, s=>0);
        $img->circle(
            x      => $cx,
            y      => $cy,
            color  => $body_color,
            r      => 2,
            aa     => 1,
            filled => 1,
        );
    }
    return;
}

sub draw_colonies {
    my ($img, $colonies, $map_size) = @_;

    for my $bid (keys %$colonies) {
	my $colony = $colonies->{$bid};
	my $cx = x_coord_to_pixel( $map_size, $colony->{x} );
	my $cy = y_coord_to_pixel( $map_size, $colony->{y} );

        my $colony_color;
        if ($colony->{empire_id} < 0) {
            return unless ($opts{ai});
            $colony_color = Imager::Color->new(hue=>0, v=>1, s=>1);
        }
        else {
            $colony_color = Imager::Color->new(hue=>125, v=>1, s=>0.6);
        }
        $img->circle(
            x       => $cx,
            y       => $cy,
            color   => $colony_color,
            r       => 2,
            filled  => 1,
            aa      => 1,
        );
    }
    return;
}

sub set_matrix {
    my ($colonies, $map_size) = @_;

    print "Setting matrix up\n";
    my $high = 0;
    for my $bid (keys %$colonies) {
        my $colony = $colonies->{$bid};
        my $shade = int(sqrt($colony->{pop}/20000)+0.5);
        my $cx = x_coord_to_pixel( $map_size, $colony->{x} );
        my $cy = y_coord_to_pixel( $map_size, $colony->{y} );
        next if ($colony->{empire_id} < 0 and !$opts{ai});
        
#        printf("col: %05d:%05d %04d\n", $cx, $cy, int($colony->{pop}/10000));
        for my $x_cnt (0..($shade*2)) {
            for my $y_cnt (0..($shade*2)) {
                my $px = $cx + $x_cnt - $shade;
                my $py = $cy + $y_cnt - $shade;
                if (inside_border($map_size, $px, $py)) {
                    my $val = int($shade - sqrt(($cx-$px)**2 + ($cy-$py)**2));
                    if ($val > 0) {
                        $val = int($val * sqrt($colony->{pop}/40000)+0.5);
                        my $key = sprintf("%05d:%05d",$px,$py);
                        my $tval;
                        if ($val = $shade) {
                            $tval = $val;
                        }
                        else {
                            $tval = int(sqrt($val)+0.5);
                        }
                        if ($matrix->{$key}) {
                            $tval += $matrix->{$key};
                        }
                        $matrix->{$key} = $tval;
                        $high = $tval if ($tval > $high);
                    }
                }
            }
        }
    }
    $matrix->{highest} = $high;

    return $matrix;
}

sub inside_border {
    my ($map_size, $px, $py) = @_;

    return 0 if ($px < $map_size->{border_x} or $px > $map_size->{size_x} - $map_size->{border_x});
    return 0 if ($py < $map_size->{border_y} or $py > $map_size->{size_y} - $map_size->{border_y});
    return 1;
}

sub x_coord_to_pixel {
    my ( $map_size, $coord ) = @_;
    
    my $min_coord = $map_size->{min_x};
    
    $min_coord = 0 - $min_coord;
    
    return $coord + $min_coord + $map_size->{border_x};
}

sub y_coord_to_pixel {
    my ( $map_size, $coord ) = @_;
    
    # flip y coords
    # Imager 0,0 is top left
    
    my $max_coord = $map_size->{max_y};
    
    $coord = 0 - $coord;
    
    return $coord + $max_coord + $map_size->{border_y};
}

sub get_json {
  my ($file) = @_;

  if (-e $file) {
    my $fh; my $lines;
    open($fh, "$file") || die "Could not open $file\n";
    $lines = join("", <$fh>);
    my $data = $json->decode($lines);
    close($fh);
    return $data;
  }
  else {
    warn "$file not found!\n";
  }
  return 0;
}

sub get_stars {
  my ($sfile) = @_;

  my $fh;
  open ($fh, "<", "$sfile") or die;

  my $fline = <$fh>;
  my %star_hash;
  while(<$fh>) {
    chomp;
    my ($id, $name, $x, $y, $color, $zone) = split(/,/, $_, 6);
    $star_hash{$id} = {
      id    => $id,
      name  => $name,
      x     => $x,
      y     => $y,
      color => $color,
      zone  => $zone,
    }
  }
  return \%star_hash;
}

sub get_offset {
  my $array = [
    [ { x =>  0, y=>  0 },
      { x =>  0, y=>  0 },
      { x =>  0, y=>  0 },
      { x =>  0, y=>  0 },
      { x =>  0, y=>  0 }, ],
    [ { x => -1, y=>  0 },
      { x => -1, y=> -1 },
      { x =>  0, y=> -1 },
      { x =>  1, y=> -1 },
      { x => -1, y=>  1 }, ],
    [ { x => -1, y=>  0 },
      { x =>  1, y=>  0 },
      { x =>  1, y=> -1 },
      { x =>  1, y=> -2 },
      { x =>  0, y=> -1 }, ],
    [ { x =>  0, y=> -1 },
      { x =>  1, y=>  0 },
      { x =>  1, y=>  1 },
      { x =>  1, y=> -1 },
      { x => -1, y=> -1 }, ],
    [ { x =>  1, y=>  0 },
      { x =>  0, y=>  1 },
      { x =>  1, y=>  1 },
      { x =>  2, y=>  1 },
      { x =>  0, y=> -1 }, ],
    [ { x =>  1, y=>  0 },
      { x =>  0, y=>  1 },
      { x => -1, y=>  1 },
      { x =>  1, y=>  1 },
      { x =>  1, y=> -1 }, ],
    [ { x =>  1, y=>  0 },
      { x => -1, y=>  0 },
      { x => -1, y=>  1 },
      { x => -1, y=>  2 },
      { x =>  0, y=>  1 }, ],
    [ { x =>  0, y=>  1 },
      { x => -1, y=> -1 },
      { x => -1, y=>  0 },
      { x => -1, y=>  1 },
      { x =>  1, y=>  1 }, ],
    [ { x =>  0, y=>  1 },
      { x =>  0, y=> -1 },
      { x => -1, y=> -1 },
      { x => -2, y=> -1 },
      { x => -1, y=>  0 }, ],
  ];

  return $array;
}
