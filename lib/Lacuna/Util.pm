package Lacuna::Util;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(cname);

sub cname {
    my $name = shift;
    my $cname = lc($name);
    $cname =~ s{\s+}{_}xmsg;
    return $cname;
}


1;
