package Lacuna::Util;

use List::MoreUtils qw(any);
use DateTime::Format::Duration;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(cname in randint to_seconds);

sub cname {
    my $name = shift;
    my $cname = lc($name);
    $cname =~ s{\s+}{_}xmsg;
    return $cname;
}

sub to_seconds {
    my $duration = shift;
    return DateTime::Format::Duration->new(pattern=>'%s')->format_duration($duration);
}

sub randint {
	my ($low, $high) = @_;
	$low = 0 unless defined $low;
	$high = 1 unless defined $high;
	($low, $high) = ($high,$low) if $low > $high;
	return $low + int( rand( $high - $low + 1 ) );
}

1;
