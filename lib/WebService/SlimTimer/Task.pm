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

=cut

use strict;
use warnings;

use DateTime::Format::ISO8601;
use Moose::Util::TypeConstraints;

sub DateTime_from_YAML
{
    # For some reason we have we get spaces in data returned by SlimTimer and
    # we need to get rid of them before using ISO8601 as otherwise it fails.
    tr / //d; DateTime::Format::ISO8601->parse_datetime($_) 
}

class_type 'DateTime';
coerce 'DateTime'
    => from 'Str'
    => via { DateTime_from_YAML($_) };

subtype 'MaybeDateTime', as 'Maybe[DateTime]';
coerce 'MaybeDateTime'
    => from 'Str'
    => via { defined $_ ? DateTime_from_YAML($_) : undef };

has id => ( is => 'ro', isa => 'Int', required => 1 );
has name => ( is => 'ro', isa => 'Str', required => 1 );
has created_at => ( is => 'ro', isa => 'DateTime', required => 1, coerce => 1 );
has updated_at => ( is => 'ro', isa => 'DateTime', required => 1, coerce => 1 );
has hours => ( is => 'ro', isa => 'Num', required => 1 );
has completed_on => ( is => 'ro', isa => 'MaybeDateTime', coerce => 1 );

# TODO: Add more fields:
#   - role: comma-separated list of (owner, coworker, reporter)
#   - tags: comma-separated list of arbitrary words
#   - owners: list of persons (name + user_id + email)
#   - reports: list of persons
#   - coworkers: list of persons

}
