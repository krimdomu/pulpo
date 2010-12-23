package Pulpo::Server;

use strict;
use warnings;

use Data::Dumper;

use Net::Server::PreFork;
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use IO::Socket qw(:crlf);
use HTTP::Parser::XS qw(parse_http_request);

use constant READ_LEN     => 64 * 1024;
use constant READ_TIMEOUT => 3;

use base qw(Net::Server::PreFork);

sub run {
   my $self = shift;

   $self->SUPER::run(
      port => '8080',
      host => '',
      proto => 'tcp',
      serialize => 'flock',
      min_servers => 20,
      min_spare_servers => 10,
      max_spare_servers => 20,
      max_servers => 50,
      listen => 1024,
      no_client_stdout => 1
   );
}

sub process_request {
   my $self = shift;
   my $c = $self->{'server'}->{'client'};

   setsockopt($c, IPPROTO_TCP, TCP_NODELAY, 1) or die($!);

   my %env;
   my $ret = parse_http_request($self->_fetch_header, \%env);
   if($ret == -1) {
      print STDERR "Request broken...\n";
      return;
   }

   syswrite $c, qq~HTTP/1.0 200 OK$CRLF${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello$CRLF${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello${CRLF}hello~;

}

sub _fetch_header {
   my $self = shift;

   my $in = '';
   eval {
      local $SIG{'ALRM'} = sub { die("Request time out\n"); };
      local $/ = $CRLF;
      alarm( READ_TIMEOUT );
      my $cl = $self->{'server'}->{'client'};
      while(my $line = <$cl>) {
         $in .= $line;
         last if $in =~ m/$CRLF$CRLF/s;
      }
   };

   return $in;
}

1;
