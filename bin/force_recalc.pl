use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;

Lacuna->db->domain('Lacuna::DB::Result::Body')->search(where=>{empire_id => {'>', 0}})->update({needs_recalc=>1});

