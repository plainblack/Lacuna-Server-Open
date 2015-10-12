use 5.10.0;
use strict;
use lib '/data/Lacuna-Server/lib';
use Getopt::Long;
use List::Util qw(all);

BEGIN { $Lacuna::Role::Trader::overload_allowed = 1 }

use L;
use Module::Find;
use Lacuna::Constants qw(ORE_TYPES SHIP_TYPES);

use Data::Dump qw(dump);

our $quiet;
GetOptions(
           'quiet|q!'      => \$quiet,
           'sst'           => \my $sst,
           'amount|e=f'    => \my $cost,
           'plan|p=s@'     => \my @plans,
           'glyph|g=s@'    => \my @glyphs,
           'ship|s=s@'     => \my @ships,
           'maxuniversity|u=i' => \my $maxuni,
          );

if (not defined $cost or
    not (@plans or @glyphs or @ships)
   )
{
    say <<'USAGE';

post_lec_trade.pl

    --sst      Use SST (defaults to Trade Min)
    --amount   Cost in Essentia
      -e
    --plan     Plans: <#?><type><plus>+<extra?>
      -p              (default: 1 plan, +0 extra)
    --glyph    Glyphs: <#?><type>
      -g              (default: 1 glyph)
    --ship     Ships: <#?><type>:k=v:k=v:k=v
      -s              (default: 1 ship, all parameters max)
                      Keys: sp (speed), st (stealth), h (hold size)
                            b (berth level), c (combat)
USAGE

    exit 0;
}

out("Started");

my $trade_type = 'Lacuna::DB::Result::Building::' . ( $sst ? 'Transporter' : 'Trade' );
my $trade_ships_required = $sst ? 0 : 1;
my $trade = LD->building({"me.class" => $trade_type, "body.empire_id"=>1},{join => "body"});
my $yard  = LD->building({"me.class" => 'Lacuna::DB::Result::Building::Shipyard', 'me.level'=>30,"body.empire_id"=>1},{join => "body"});
my $body = $trade->body;

# track all ship types and their defaults
my %ship_types = map {
    my $ship = LD->ships->new({type=>$_});
    $_ => {
        speed       => $yard->set_ship_speed($ship),
        stealth     => $yard->set_ship_stealth($ship),
        hold_size   => $yard->set_ship_hold_size($ship),
        berth_level => $ship->base_berth_level,
        combat      => $yard->set_ship_combat($ship),
        name        => $_,
    }
} SHIP_TYPES;
my %ship_fields = qw(
sp speed
st stealth
h hold_size
b berth_level
c combat
);

# figure out what to sell.
my @offer;

@plans = map {
    # magic starter packs.
    if (my ($q,$rest) = /^(\d*)(?:starterpack|sp)(\d.*)/)
    {
        $rest ||= '1+0';
        map "$q$_$rest", qw(
            Permanent_AlgaePond
            Permanent_AmalgusMeadow
            Permanent_BeeldebanNest
            Permanent_CrashedShipSite
            Permanent_DentonBrambles
            Permanent_GeoThermalVent
            Permanent_InterDimensionalRift
            Permanent_KalavianRuins
            Permanent_LapisForest
            Permanent_MalcudField
            Permanent_NaturalSpring
            Permanent_Ravine
            Permanent_Volcano
        );
    }
    elsif (my ($q) = /^(\d*)(?:sspack|ss)/)
    {
        my @r = map {
            my $p = $_;
            map "$p$_", 1..15
        } map "$q$_", qw(
            Module_ArtMuseum
            Module_CulinaryInstitute
            Module_IBS
            Module_OperaHouse
            Module_Parliament
            Module_PoliceStation
            Module_StationCommand
        );
        $q ||= 1;
        $q *= 15;
        push @r, map $q."Module_Warehouse$_", 1..15;
        @r;
    }
    else
    {
        $_
    }
} @plans;

my @valid_plans;
for my $p (@plans)
{
    @valid_plans = findallmod 'Lacuna::DB::Result::Building'
        unless @valid_plans;

    my ($quantity,$class,$level,$extra_build_level) =
        $p =~ /^(\d*)\s*([^\d\s]+)(\d+)(?:\+(\d+))?/;
    $quantity ||= 1;
    $extra_build_level ||= 0;

    $class =~ s/_/::/g;
    my @classes = grep /$class/i, @valid_plans;

    die qq[Can't understand plan for "$p"] if @classes == 0;
    die qq["$p" matches more than one class] if @classes > 1;
    $class = $classes[0];

    # make sure we have enough.
    my ($plan) = grep {
            $_->class eq $class
        and $_->level == $level
        and $_->extra_build_level == $extra_build_level
    } @{$body->plan_cache};
    my $needed = $quantity;
    $needed -= $plan->quantity if $plan;
    if ($needed > 0)
    {
        out "Adding $needed $class $level+$extra_build_level plan(s)";
        $body->add_plan($class, $level, $extra_build_level, $needed);
    }

    push @offer, {
        type       => 'plan',
        plan_type  => $class,
        level      => $level,
        extra_build_level => $extra_build_level,
        quantity   => $quantity,
    };
}

for my $g (@glyphs)
{
    my ($quantity, $type) =
        $g =~ /^(\d*)\s*(\S+)/;
    $quantity ||= 1;
    my @choices = grep /$type/i, ORE_TYPES;

    die qq[Can't understand glyph for "$g"] if @choices == 0;
    die qq["$g" matches more than one glyph type] if @choices > 1;
    $type = $choices[0];

    # make sure we have enough.
    my $glyph = $body->glyph->search({type=>$type})->first;
    if ($glyph)
    {
        if ($glyph->quantity < $quantity)
        {
            out("Setting $quantity $type glyphs");
            $glyph->quantity($quantity);
            $glyph->update;
        }
    }
    else
    {
        out("Adding $quantity $type glyphs");
        $body->add_glyph($type, $quantity);
    }

    push @offer, {
        type => 'glyph',
        name => $type,
        quantity => $quantity,
    };
}

for my $s (@ships)
{
    my ($qt,@fields) = split /:/,$s;

    my ($quantity, $type) =
        $qt =~ /^(\d*)\s*(\S+)/;
    $quantity ||= 1;

    my @choices = grep /$type/i, SHIP_TYPES;

    die qq[Can't understand ship for "$qt"] if @choices == 0;
    die qq["$qt" matches more than one ship type] if @choices > 1;

    $type = $choices[0];

    my %params = ( task => 'Docked', %{$ship_types{$type}} );

    for my $f (@fields)
    {
        my ($k,$v) = split /=/, $f, 2;

        die qq[Extra fields should be key=value in ship "$s"]
            unless $k and $v and $v =~ /^\d+$/;

        if ($ship_fields{$k})
        {
            $params{$ship_fields{$k}} = $v;
        }
        else
        {
            die qq[Unknown key "$k" in ship "$s"];
        }
    }

    # are we building the ship we're going to use?
    if (
        $type eq 'galleon' &&
        all { $params{$_} == $ship_types{galleon}{$_} } values %ship_fields
       )
    {
        $trade_ships_required += $quantity;
    }

    # do we already have enough?
    build_enough_ships($body, $quantity, $type, %params);

    push @offer, { type => 'ship', ship_type => $type, quantity => $quantity, %params };
}

my @opts;
unless ($sst)
{
    out("Finding trade ship.") unless $sst;
    build_enough_ships($body, $trade_ships_required, 'galleon', %{$ship_types{galleon}}, name => "LEC Trade Ship", task => 'Docked');
    my $ship = $body->ships->search({type => 'galleon', %{$ship_types{galleon}}, name => "LEC Trade Ship", task => 'Docked'})->first;
    @opts = ({ship_id => $ship->id});
}


out(dump(\@offer));

out("Posting.");
eval {
    $trade->add_to_market(
                          \@offer,
                          $cost,
                          @opts,
                          { max_university => $maxuni },
                         );
    1;
} or die dump($@);


out("Done.");

exit 0;

sub build_enough_ships
{
    my $body = shift;
    my $quantity = shift;

    my $have = $body->ships->search({type => @_})->count;

    while ($have < $quantity)
    {
        # build 'em.
        out "Building a $_[0] ship";
        build_ship($body, @_);

        $have++;
    }

}

sub build_ship
{
    my $body = shift;
    my $type = shift;
    my %params = @_;
    my $ship = LD->resultset('Ships')->new({type => $type, %params});
    $ship->body($body);
    $ship->date_started(DateTime->now);
    $ship->date_available(DateTime->now);
    $ship->insert;

    $ship;
}
