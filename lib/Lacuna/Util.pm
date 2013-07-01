package Lacuna::Util;

use List::MoreUtils qw(any);
use DateTime;
use DateTime::Format::Duration;
use DateTime::Format::Strptime;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(randint format_date random_element commify consolidate_items);


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
    return int($low + int( rand( $high - $low + 1 ) ));
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

1;
