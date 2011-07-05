# PODNAME: WebService::SlimTimer::Task
#
# ABSTRACT: Represents a single SlimTimer task.

use MooseX::Declare;

class WebService::SlimTimer::Task
{

=head1 SYNOPSIS

The objects of this class repesent a SlimTimer task. These objects are not
created directly but rather retrieved from L<WebService::SlimTimer> using its
C<list_tasks()> method.

=head1 SEE ALSO

L<WebService::SlimTimer>

=cut

use strict;
use warnings;

use MooseX::Types::Moose qw(Int Num Str);
use WebService::SlimTimer::Types qw(TimeStamp OptionalTimeStamp);

has id => ( is => 'ro', isa => Int, required => 1 );
has name => ( is => 'ro', isa => Str, required => 1 );
has created_at => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has updated_at => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has hours => ( is => 'ro', isa => Num, required => 1 );
has completed_on => ( is => 'ro', isa => OptionalTimeStamp, coerce => 1 );

# TODO: Add more fields:
#   - role: comma-separated list of (owner, coworker, reporter)
#   - tags: comma-separated list of arbitrary words
#   - owners: list of persons (name + user_id + email)
#   - reports: list of persons
#   - coworkers: list of persons

}
