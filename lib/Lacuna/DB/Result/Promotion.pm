package Lacuna::DB::Result::Promotion;

use Moose;
use utf8;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);

__PACKAGE__->load_components('DynamicSubclass');
__PACKAGE__->table('promotion');
__PACKAGE__->add_columns(
    start_date              => { data_type => 'datetime', is_nullable => 0 },
    end_date                => { data_type => 'datetime', is_nullable => 0 },
    type                    => { data_type => 'varchar', size => 30, is_nullable => 0 }, # Look at typecast_map below
    min_purchase            => { data_type => 'int', is_nullable => 1, },
    max_purchase            => { data_type => 'int', is_nullable => 1, },
    payload                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
);

our @types = qw(
    Bonus50
    ECode50
    Valentine50
    );

__PACKAGE__->typecast_map(type => {
    map { $_ => __PACKAGE__ . '::' . $_ } @types
});

use constant category => 'none';

sub ui_details {
    my ($self) = @_;

    my @with;
    push @with, sprintf "minimum purchase of %d", $self->min_purchase if defined $self->min_purchase;
    push @with, sprintf "maximum purchase of %d", $self->max_purchase if defined $self->max_purchase;

    my $description = '';

    if ($self->category eq 'essentia_purchase') {
        if (@with) {
            if (@with == 2 && $self->min_purchase == $self->max_purchase)
            {
                $description = sprintf "With a purchase of %d essentia, ";
            }
            else
            {
                $description = sprintf "With a %s essentia, ", join ' and ', @with if @with;
            }
            $description .= $self->description;
        }
        else
        {
            $description = "With any purchase of essentia, " . $self->description;
        }
    }
    else {
        $description = $self->description;
    }

    return {
        start_date   => format_date($self->start_date),
        end_date     => format_date($self->end_date),
        type         => $self->type,
        description  => ucfirst $description,
        title        => $self->title
    };
}


# checks min/max purchase amounts (if any)
sub purchase_applies
{
    my ($self, $opts) = @_;

    return 0 if defined $self->min_purchase && $opts->{amount} < $self->min_purchase;
    return 0 if defined $self->max_purchase && $opts->{amount} > $self->max_purchase;

    return 1;
}

# opts:
#   amount (essentia)
#   empire (object)
#   cost   (in USD)
#   transaction_id
#   type   (iTransact, Paypal, etc.)

sub essentia_purchased
{
    my ($self, $opts) = @_;

    return; # not all promotions are necessarily E-based?
}

around essentia_purchased => sub {
    my ($orig, $self, $opts) = @_;

    # pre-check this automatically.
    return unless $self->purchase_applies($opts);

    return $self->$orig($opts);
};


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
