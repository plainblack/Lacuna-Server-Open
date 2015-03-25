package Lacuna::Util;

use List::MoreUtils qw(any);
use DateTime;
use DateTime::Format::Duration;
use DateTime::Format::Strptime;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(
    randint
    format_date
    random_element
    commify
    consolidate_items
    kmbtq
    real_ip_address
    );


sub format_date {
    my ($date, $format) = @_;
    $date ||= DateTime->now;
    $format ||= '%d %m %Y %H:%M:%S %z';
    return DateTime::Format::Strptime::strftime($format,$date);
}

# Return a random integer between $low and $high inclusive
sub randint {
    my ($low, $high) = @_;
    $low = 0 unless defined $low;
    $high = 1 unless defined $high;
    ($low, $high) = ($high,$low) if $low > $high;
    return $low + int( rand( $high - $low + 1 ) );
}

sub random_element {
    my ($list) = @_;
    return $list->[randint(0, scalar(@{$list} -1 ))];
}

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

sub kmbtq {
    my ($numb) = @_;

    my $neq = $numb < 0 ? -1 : 1;
    $numb =~ tr/0-9//cd;
    $numb *= $neq;

    if ($numb >= 100_000_000_000_000_000 || $numb <= -100_000_000_000_000_000) {
# 101Q
        return int($numb/1_000_000_000_000_000).'Q';
    }
    elsif ($numb >= 1_000_000_000_000_000 || $numb <= -1_000_000_000_000_000) {
# 83.4Q
        return (int($numb/100_000_000_000_000) / 10).'Q';
    }
    elsif ($numb >= 100_000_000_000_000 ||  $numb <= -100_000_000_000_000) {
# 101T
        return int( $numb/1_000_000_000_000).'T';
    }
    elsif ( $numb >= 1_000_000_000_000 ||  $numb <= -1_000_000_000_000) {
# 75.3T
        return (int( $numb/100_000_000_000) / 10).'T';
    }
    elsif ( $numb >= 100_000_000_000 ||  $numb <= -100_000_000_000) {
# 101B
        return int( $numb/1_000_000_000).'B';
    }
    elsif ( $numb >= 1_000_000_000 ||  $numb <= -1_000_000_000) {
# 75.3B
        return (int( $numb/100_000_000) / 10).'B';
    }
    elsif ( $numb >= 100_000_000 ||  $numb <= -100_000_000) {
# 101M
                return int( $numb/1000000).'M';
    }
    elsif ( $numb >= 1_000_000 ||  $numb <= -1_000_000) {
# 75.3M
                return (int( $numb/100_000) / 10).'M';
    }
    elsif ( $numb >= 10_000 ||  $numb <= -10_000) {
# 123k
        return int( $numb/1_000).'k';
    }
    else {
# 8765
        return int( $numb);
    }

  return $numb;
}

sub consolidate_items {
    my ($item_arr) = @_;

    my $item_hash = {};
    for my $item (@{$item_arr}) {
        $item_hash->{$item}++;
    }
    undef $item_arr;
    for my $item (sort keys %{$item_hash}) {
        push @{$item_arr}, sprintf("%5s %s", commify($item_hash->{$item}), $item);
    }
    return $item_arr;
}

sub real_ip_address {
    my ($plack_request) = @_;
    $plack_request->headers->header('X-Real-IP') //
            $plack_request->address;
}

1;
