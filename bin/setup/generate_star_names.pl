use strict;
use 5.010;
use String::Random;
use List::MoreUtils qw(uniq part);
use List::Util qw(shuffle);

srand(314159);

say "Loading real...";
my @real;
open my $file, "<", "../../var/real_starnames.txt";
while (my $name = <$file>) {
    chomp $name;
    push @real, $name;
}
close $file;

say "Loading us...";
my @us = qw(Lacuna Dillon Knope Vrbsky Smith Runde Rozeske Parker Icydee Norway Vasari Rhutenia Lemming Icd);

say "Generating new...";
my $rs = String::Random->new;
$rs->{e} = [qw(a e i o u ea ee oa oo io ia ae ou ie oe ai ui eu ow)];
$rs->{E} = [qw(A E I O U Ea Ee Oa Oo Io Ia Ae Ou)];
$rs->{f} = [qw(b d f g k l m n p r s t v w x y z bb be ce ch ck dd de ff fe ge gh gg je jj ke kk le lk ll lm lp lt ls lz me mm mn mp nch nd ne ng nk nn nt pe ph pp rb rd re rf rg rk rl rm rn rp rr rs rsh rt rth rv rz se sh ss st sy tch te th tt ve zy zz)];
$rs->{b} = [qw(b c d f g h j k l m n p qu r s t v w x y z ch sh dr fl fr bl sl st gr gw th xy tr tw tch sch shr sn pl pr sph spl ph str ly gl gh ll nd rv gg mb ck hl ckl pp ss mp nt nd rn ng tt ss dd cc ndl zz rn)];
$rs->{B} = [qw(B C D F G H J K L M N P Qu R S T V W X Y Z Ch Sh Dr Fl Fr Bl Sl St Gr Gw Th Xy Tr Tw Sch Shr Sn Pl Pr Sph Spl Ph Str Ly Gl Gh Ll Rh Kl Cl Vl Kn)];
$rs->{' '} = [' '];

my @generated;
for my $i (1..80_000) {
    push @generated, $rs->randpattern('Ebe');
    push @generated, $rs->randpattern('Bef');
    push @generated, $rs->randpattern('Bebe');
    push @generated, $rs->randpattern('Ebef');
    push @generated, $rs->randpattern('Efbe');
    push @generated, $rs->randpattern('Ebebe');
    push @generated, $rs->randpattern('Bebef');
    push @generated, $rs->randpattern('Befbe');
    push @generated, $rs->randpattern('Efbef');
    push @generated, $rs->randpattern('Ebebef');
    push @generated, $rs->randpattern('Bebebe');
    push @generated, $rs->randpattern('Ef Bef');
    push @generated, $rs->randpattern('Be Ebe');
    push @generated, $rs->randpattern('Ef Bebe');
    push @generated, $rs->randpattern('Be Ebef');
    push @generated, $rs->randpattern('Eb Ebef');
    push @generated, $rs->randpattern('Be Bebe');
    push @generated, $rs->randpattern('Ef Ebef Ef');
    push @generated, $rs->randpattern('Ef Bebe Ef');
    push @generated, $rs->randpattern('Ef Bebe Be');
    push @generated, $rs->randpattern('Ef Ebef Be');
    push @generated, $rs->randpattern('Be Bebe Be');
    push @generated, $rs->randpattern('Be Ebef Be');
    push @generated, $rs->randpattern('Be Bebe Ef');
    push @generated, $rs->randpattern('Be Ebef Ef');
}

my @all = (@us, shuffle(@real), @generated);
say "Making unique from ".scalar(@all)."...";
my @unique = uniq( @all );

say "Eliminating bad from ".scalar(@unique)."...";
my @naughty = qw(Fuck Shit Ass Cunt Nigger Dick Pussy Cock Snot Puke Damn Bitch Whore Slut);
my @part = part {  foreach my $bad (@naughty) { return 1 if ($_ =~ /$bad/); } return 0; } @unique;
my @good = @{$part[0]};
my @bad = @{$part[1]};

say "Writing list of ".scalar(@good)." names...";
open my $file, ">", "../../var/starnames.txt";
print {$file} join("\n", @good);
close $file;

say "Found ".scalar(@bad)." bad...";
