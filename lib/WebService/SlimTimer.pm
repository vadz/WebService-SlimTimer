use strict;
use warnings;

package WebService::SlimTimer;

# ABSTRACT: Provides interface to SlimTimer web service.

=head1 SYNOPSIS

This module provides interface to L<http://www.slimtimer.com/> functionality.

Notice that to use it you must obtain an API key by creating an account at
SlimTimer web site.

=head1 SEE ALSO

L<WebService::SlimTimer::Task>, L<WebService::SlimTimer::TimeEntry>

=head1 BUGS

Currently the C<offset> parameter is not used by C<list_tasks> and
C<list_entries> and C<list_task_entries> methods, so they are limited to 50
tasks for the first one and 5000 entries for the latter two and accessing the
subsequent results is impossible.

Access to the comments and tags of the tasks and time entries objects is not
implemented yet.

=cut

use Moose;
use MooseX::Method::Signatures;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(Int Str);

use LWP::UserAgent;
use YAML::XS;

use debug;

use WebService::SlimTimer::Task;
use WebService::SlimTimer::TimeEntry;
use WebService::SlimTimer::Types qw(TimeStamp OptionalTimeStamp);

has api_key => ( is => 'ro', isa => Str, required => 1 );

has user_id => ( is => 'ro', isa => Int, writer => '_set_user_id' );
has access_token => ( is => 'ro', isa => Str, writer => '_set_access_token',
        predicate => 'is_logged_in'
    );

has _user_agent => ( is => 'ro', builder => '_create_ua', lazy => 1 );

# Return a string representation of a TimeStamp.
method _format_time(TimeStamp $timestamp)
{
    use DateTime::Format::RFC3339;
    return DateTime::Format::RFC3339->format_datetime($timestamp)
}

# Create the LWP object that we use. This is currently trivial but provides a
# central point for customizing its creation later.
method _create_ua()
{
    my $ua = LWP::UserAgent->new;
    return $ua;
}

# A helper method for creating and initializing an HTTP request without
# parameters, e.g. a GET or DELETE.
method _make_request(Str $method, Str $url, HashRef $params?)
{
    my $uri = URI->new($url);
    $uri->query_form(
            api_key => $self->api_key,
            access_token => $self->access_token,
            %$params
          );
    my $req = HTTP::Request->new($method, $uri);

    debug::log("*** About to request " . $req->as_string) if DEBUG;

    $req->header(Accept => 'application/x-yaml');

    return $req;
}

# Another helper for POST and PUT requests.
method _make_post(Str $method, Str $url, HashRef $params)
{
    my $req = HTTP::Request->new($method, $url);

    $params->{'api_key'} = $self->api_key;

    # POST request is used to log in so we can be called before we have the
    # access token and need to check for this explicitly.
    if ( $self->is_logged_in ) {
        $params->{'access_token'} = $self->access_token;
    }

    $req->content(Dump($params));

    debug::log("*** About to post " . $req->as_string) if DEBUG;

    $req->header(Accept => 'application/x-yaml');
    $req->content_type('application/x-yaml');

    return $req;
}

# Provide a simple single-argument ctor instead of default Moose one taking a
# hash with all attributes values.
around BUILDARGS => sub
{
    die "A single API key argument is required" unless @_ == 3;

    my ($orig, $class, $api_key) = @_;

    $class->$orig(api_key => $api_key)
};

=method login

Logs in to SlimTimer using the provided login and password.

This method must be called before doing anything else with this object.

=cut

method login(Str $login, Str $password)
{
    my $req = $self->_make_post(POST => 'http://slimtimer.com/users/token',
            { user => { email => $login, password => $password } }
        );

    my $res = $self->_user_agent->request($req);
    if ( !$res->is_success ) {
        die "Failed to login as \"$login\": " . $res->status_line
    }

    my $retval = Load($res->content);
    if ( exists $retval->{':error:'} ) {
        die "Failed to login as \"$login\": " . $retval->{':error:'}
    }

    $self->_set_user_id($retval->{'user_id'});
    $self->_set_access_token($retval->{'access_token'})
}


# Helper for task-related methods: returns either the root tasks URI or the
# URI for the given task if the task id is specified.
method _get_tasks_uri(Int $task_id?)
{
    my $uri = "http://slimtimer.com/users/$self->{user_id}/tasks";
    if ( defined $task_id ) {
        $uri .= "/$task_id"
    }

    return $uri
}

=method list_tasks

Returns the list of all tasks involving the logged in user, completed or not.

=cut

method list_tasks
{
    my $req = $self->_make_request(GET => $self->_get_tasks_uri);

    my $res = $self->_user_agent->request($req);
    if ( !$res->is_success ) {
        die "Failed to get the tasks list: " . $res->status_line
    }

    # The expected reply structure is an array of hashes corresponding to each
    # task.
    my $tasks_entries = Load($res->content);

    my @tasks;
    for (@$tasks_entries) {
        push @tasks, WebService::SlimTimer::Task->new(%$_);
    }

    return @tasks;
}

=method create_task

Create a new task with the given name.

=cut

method create_task(Str $name)
{
    my $req = $self->_make_post(POST => $self->_get_tasks_uri,
            { task => { name => $name } }
        );

    my $res = $self->_user_agent->request($req);
    if ( !$res->is_success ) {
        die "Failed to create task \"$name\": " . $res->status_line
    }

    return WebService::SlimTimer::Task->new(Load($res->content));
}

=method delete_task

Delete the task with the given id (presumably previously obtained from
L<list_tasks>).

=cut

method delete_task(Int $task_id)
{
    my $req = $self->_make_request(DELETE => $self->_get_tasks_uri($task_id));

    my $res = $self->_user_agent->request($req);
    if ( !$res->is_success ) {
        die "Failed to delete the task $task_id: " . $res->status_line
    }
}

=method get_task

Find the given task by its id.

=cut

method get_task(Int $task_id)
{
    my $req = $self->_make_request(GET => $self->_get_tasks_uri($task_id));

    my $res = $self->_user_agent->request($req);
    if ( !$res->is_success ) {
        die "Failed to find the task $task_id: " . $res->status_line
    }

    return WebService::SlimTimer::Task->new(Load($res->content));
}

=method complete_task

Mark the task with the given id as being completed.

=cut

method complete_task(Int $task_id, TimeStamp $completed_on)
{
    my $req = $self->_make_post(PUT => $self->_get_tasks_uri($task_id),
            { task => { completed_on => $self->_format_time($completed_on) } }
        );

    my $res = $self->_user_agent->request($req);
    if ( !$res->is_success ) {
        die "Failed to mark the task $task_id as completed: " . $res->status_line
    }
}



# Helper for time-entry-related methods: returns either the root time entries
# URI or the URI for the given entry if the time entry id is specified.
method _get_entries_uri(Int $entry_id?)
{
    my $uri = "http://slimtimer.com/users/$self->{user_id}/time_entries";
    if ( defined $entry_id ) {
        $uri .= "/$entry_id"
    }

    return $uri
}

# Common part of list_entries() and list_task_entries()
method _list_entries(
    Maybe[Int] $taskId,
    OptionalTimeStamp $start,
    OptionalTimeStamp $end)
{
    my $uri = defined $taskId
                ? $self->_get_tasks_uri($taskId) . "/time_entries"
                : $self->_get_entries_uri;

    my %params;
    $params{'range_start'} = $self->_format_time($start) if defined $start;
    $params{'range_end'} = $self->_format_time($end) if defined $end;

    my $req = $self->_make_request(GET => $uri, \%params);

    my $res = $self->_user_agent->request($req);
    if ( !$res->is_success ) {
        die "Failed to get the entries list: " . $res->status_line
    }

    my $entries = Load($res->content);

    my @time_entries;
    for (@$entries) {
        push @time_entries, WebService::SlimTimer::TimeEntry->new($_);
    }

    return @time_entries;
}

=method list_entries

Return all the time entries.

If the optional C<start> and/or C<end> parameters are specified, returns only
the entries that begin after the start date and/or before the end one.

=cut

method list_entries(TimeStamp :$start, TimeStamp :$end)
{
    return $self->_list_entries(undef, $start, $end);
}

=method list_task_entries

Return all the time entries for the given task.

Just as L<list_entries>, this method accepts optional C<start> and C<end>
parameters to restrict the dates of the entries retrieved.

=cut

method list_task_entries(Int $taskId, TimeStamp :$start, TimeStamp :$end)
{
    return $self->_list_entries($taskId, $start, $end);
}

=method get_entry

Find the given time entry by its id.

=cut

method get_entry(Int $entryId)
{
    my $req = $self->_make_request(GET => $self->_get_entries_uri($entryId));

    my $res = $self->_user_agent->request($req);
    if ( !$res->is_success ) {
        die "Failed to get the entry $entryId: " . $res->status_line
    }

    return WebService::SlimTimer::TimeEntry->new(Load($res->content));
}

1;
