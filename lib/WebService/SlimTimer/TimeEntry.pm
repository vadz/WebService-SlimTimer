# PODNAME: WebService::SlimTimer::TimeEntry
#
# ABSTRACT: Represents a time entry record in SlimTimer.

use MooseX::Declare;

class WebService::SlimTimer::TimeEntry
{

=head1 SYNOPSIS

The objects of this class repesent a single entry spent on some SlimTimer
task.

=cut

use strict;
use warnings;

use MooseX::Types::Moose qw(Bool Int Maybe Str);
use WebService::SlimTimer::Types qw(TimeStamp);

method BUILDARGS(ClassName $class: HashRef $desc)
{
    # We use a different (shorter) name for one of the attributes compared to
    # the YAML format, translate it on the fly.
    $desc->{'duration'} = delete $desc->{'duration_in_seconds'};
    return $desc;
}

has id         => ( is => 'ro', isa => Int, required => 1 );
has start_time => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has end_time   => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has created_at => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has updated_at => ( is => 'ro', isa => TimeStamp, required => 1, coerce => 1 );
has duration   => ( is => 'ro', isa => Int, required => 1 );
has comments   => ( is => 'ro', isa => Maybe[Str] );
has in_progress => ( is => 'ro', isa => Bool, required => 1 );

# TODO: Add tags.

}
