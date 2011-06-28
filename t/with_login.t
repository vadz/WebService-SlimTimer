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

my $initial_num_tasks = $st->list_tasks;

my $task1 = $st->create_task('First');
isa_ok $task1, 'WebService::SlimTimer::Task';

my $task2 = $st->create_task('Second');
isa_ok $task2, 'WebService::SlimTimer::Task';

my @tasks = $st->list_tasks;
is scalar @tasks, $initial_num_tasks + 2, 'Two tasks created.';

my @tasks_with_id1 = grep { $_->id == $task1->id } @tasks;
is scalar @tasks_with_id1, 1, 'Found the first task.';
is $tasks_with_id1[0]->name, 'First', 'First task has correct name.';

is $st->get_task($task2->id)->name, 'Second', 'Second task has correct name.';

$st->delete_task($_->id) for @tasks;

is scalar $st->list_tasks, 0, 'No tasks remain.';

done_testing();

