use strict;
use warnings;

package WebService::SlimTimer;

# ABSTRACT: Provides interface to SlimTimer web service.

=head1 SYNOPSIS

This module provides interface to L<http://www.slimtimer.com/> functionality.

Notice that to use it you must obtain an API key by creating an account at
SlimTimer web site.

=cut

use Moose;
use MooseX::Method::Signatures;

use LWP::UserAgent;
use YAML::XS;

use WebService::SlimTimer::Task;

has api_key => ( is => 'ro', isa => 'Str', required => 1 );

has user_id => ( is => 'ro', isa => 'Int', writer => '_set_user_id' );
has access_token => ( is => 'ro', isa => 'Str', writer => '_set_access_token' );

sub _accept_yaml
{
    my $req = shift;
    $req->header(Accept => 'application/x-yaml');
}

sub _use_yaml_for_post
{
    my $req = shift;
    $req->content_type('application/x-yaml');
    _accept_yaml($req);
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
    my $req = HTTP::Request->new(POST => 'http://slimtimer.com/users/token');
    _use_yaml_for_post($req);

    my $login_params = { user => { email => $login, password => $password },
                         api_key => $self->api_key };
    $req->content(Dump($login_params));

    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
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
    my $uri = URI->new($self->_get_tasks_uri);
    $uri->query_form(
            api_key => $self->api_key,
            access_token => $self->access_token,
          );
    my $req = HTTP::Request->new(GET => $uri);
    _accept_yaml($req);

    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
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
    my $req = HTTP::Request->new(POST => $self->_get_tasks_uri);
    _use_yaml_for_post($req);

    $req->content(Dump({
        access_token => $self->access_token,
        api_key      => $self->api_key,
        task         => { name => $name },
    }));

    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
    if ( !$res->is_success ) {
        die "Failed to create task \"$name\": " . $res->status_line
    }

    return WebService::SlimTimer::Task->new(Load($res->content));
}

=method delete_task

Delete the task with the given id (presumably previously obtained from
L<list_tasks>.

=cut

method delete_task(Int $task_id)
{
    my $uri = URI->new($self->_get_tasks_uri($task_id));
    $uri->query_form(
            api_key => $self->api_key,
            access_token => $self->access_token,
          );
    my $req = HTTP::Request->new(DELETE => $uri);
    _accept_yaml($req);

    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
    if ( !$res->is_success ) {
        die "Failed to delete the task $task_id: " . $res->status_line
    }
}

1;
