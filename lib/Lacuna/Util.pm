package Lacuna::Util;

use List::MoreUtils qw(any);
use DateTime;
use DateTime::Format::Duration;
use DateTime::Format::Strptime;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(randint to_seconds format_date random_string);

sub to_seconds {
    my $duration = shift;
    return DateTime::Format::Duration->new(pattern=>'%s')->format_duration($duration);
}

sub format_date {
    my ($date, $format) = @_;
    $date ||= DateTime->now;
    $format ||= '%d %m %Y %H:%M:%S %z';
    return DateTime::Format::Strptime::strftime($format,$date);
}

sub randint {
	my ($low, $high) = @_;
	$low = 0 unless defined $low;
	$high = 1 unless defined $high;
	($low, $high) = ($high,$low) if $low > $high;
	return $low + int( rand( $high - $low + 1 ) );
}

sub random_string {
    my ($list) = @_;
    return $list->[randint(0, scalar(@{$list} -1 ))];
}

1;
