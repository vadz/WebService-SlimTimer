# PODNAME: WebService::SlimTimer::TimeEntry
#
# ABSTRACT: Represents a time entry record in SlimTimer.

use MooseX::Declare;

class WebService::SlimTimer::TimeEntry
{

=head1 SYNOPSIS

The objects of this class repesent a single entry spent on some SlimTimer
task. Just as L<WebService::SlimTimer::Task> objects, they are never created
directly but are returned by L<WebService::SlimTimer> methods such as
C<list_entries()> or C<get_entry()>.

    my @entries = $st->list_entries(start => ..., end => ...);
    my $total = 0;
    for my $e (@entries) {
        $total += $e->duration;
    }

    print "Total time spent during the given interval $total seconds.\n";

=attr id

The unique numeric id of the entry.

=attr task_id

The numeric id of the associated task.

=attr task_name

The name of the associated task, provided as a convenience to avoid the need
for calling L<WebService::SlimTimer/get_task> just to retrieve it.

=attr start_time

The time when the entry started.

=attr end_time

The time when the entry ended.

=attr duration

Duration of the entry in seconds.

=attr created_at

The time when the entry itself was created.

=attr updated_at

The time when the entry was last modified.

=head1 SEE ALSO

L<WebService::SlimTimer>

=cut

use strict;
use warnings;

use MooseX::Types::Moose qw(Bool Int Maybe Str);
use WebService::SlimTimer::Types qw(TimeStamp);

method BUILDARGS(ClassName $class: HashRef $desc)
{
    # We use a different (shorter) name for one of the attributes compared to
    # the YAML format, translate it on the fly.
    $desc->{duration} = delete $desc->{duration_in_seconds};

    # We also want to extract the associated task id and name from the nested
    # task hash if present (otherwise task_id must be specified explicitly).
    if ( exists $desc->{'task'} ) {
        $desc->{task_id} = $desc->{task}->{id};
        $desc->{task_name} = $desc->{task}->{name};
    }

    return $desc;
}

has id         => ( is => 'ro', isa => Int, required => 1 );
has task_id    => ( is => 'ro', isa => Int, required => 1 );
has task_name  => ( is => 'ro', isa => Str );
has start_time => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has end_time   => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has created_at => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has updated_at => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has duration   => ( is => 'ro', isa => Int, required => 1 );
has comments   => ( is => 'ro', isa => Maybe[Str] );
has in_progress => ( is => 'ro', isa => Bool, required => 1 );

# TODO: Add tags.

}
