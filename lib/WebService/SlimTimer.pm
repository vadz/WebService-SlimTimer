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

has user_id => ( is => 'ro', isa => 'Int', writer => '_set_user_id' );
has access_token => ( is => 'ro', isa => 'Str', writer => '_set_access_token' );

sub _use_yaml_for_request
{
    my $req = shift;
    $req->content_type('application/x-yaml');
    $req->header(Accept => 'application/x-yaml');
    return $req;
}

=method login

Logs in to SlimTimer using the provided login and password.

This method must be called before doing anything else with this object.

=cut

method login(Str $login, Str $password, Str $api_key)
{
    my $req = HTTP::Request->new(POST => 'http://slimtimer.com/users/token');
    _use_yaml_for_request($req);

    my $login_params = { user => { email => $login, password => $password },
                         api_key => $api_key };
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

1;
