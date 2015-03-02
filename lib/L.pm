package L;

# Intended to be used from the command line to save a bunch of typing.

# This derives off Lacuna, thus can be used like Lacuna:
# perl -ML -E 'say L->cache->get(...)'

use parent 'Lacuna';
use LD;
use LR;

use L;

1;
