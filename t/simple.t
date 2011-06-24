use strict;
use warnings;
use Test::More;

BEGIN { use_ok('WebService::SlimTimer'); }

my $st = WebService::SlimTimer->new();
isa_ok($st, 'WebService::SlimTimer');

can_ok($st, qw(login));

done_testing();
