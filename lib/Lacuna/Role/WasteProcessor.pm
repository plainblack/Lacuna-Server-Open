package Lacuna::Role::WasteProcessor;

use Moose::Role;


sub ore_production_hour {
    my ($self) = @_;
    my $base = $self->ore_production * $self->production_hour * ($self->body->total_ore_concentration / 10000);
    return 0 if $base == 0;
    return sprintf('%.0f', $base * $self->manufacturing_production_bonus);
}

sub energy_production_hour {
    my ($self) = @_;
    my $base = $self->energy_production * $self->production_hour;
    return 0 if $base == 0;
    return sprintf('%.0f', $base * $self->manufacturing_production_bonus);
}

sub water_production_hour {
    my ($self) = @_;
    my $base = $self->water_production * $self->production_hour;
    return 0 if $base == 0;
    return sprintf('%.0f', $base * $self->manufacturing_production_bonus);
}

1;
