#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Pulpo::Plugin::Request::Simple;

use strict;
use warnings;

use base qw(Pulpo::Plugin);

__PACKAGE__->attach_to('request', sub {
   __PACKAGE__->do_request(@_);
});

sub do_request {
   my ($client, $env) = @_;

   return Pulpo::HTTP::Response->new(content => 'Hello world!', status => 200, message => 'OK');
}

1;
