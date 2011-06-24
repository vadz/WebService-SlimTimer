use strict;
use warnings;

use Test::More;
use Test::Exception;

sub env_var { $ENV{'SLIMTIMER_' . shift} }

for ( qw( LOGIN PASSWORD API_KEY USER_ID ) ) {
    if ( !defined(env_var($_)) ) {
        plan skip_all => 'Please define environment variable "SLIMTIMER_' . $_
                       . '" required to run this test.';
    }
}

use WebService::SlimTimer;

my $st = WebService::SlimTimer->new(env_var('API_KEY'));

throws_ok { $st->login('foo', 'bar') } qr/Failed to login/,
        'Login with dummy values failed.';

ok $st->login(env_var('LOGIN'), env_var('PASSWORD')), 'Can login.';
is $st->user_id(), env_var('USER_ID'), 'Got back expected user id.';

done_testing();

