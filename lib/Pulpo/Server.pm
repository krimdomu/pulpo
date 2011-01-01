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
use constant WRITE_LEN    => 64 * 1024;

use base qw(Net::Server::PreFork);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   my $p = { @_ };

   bless($self, $proto);

   $self->{'on_request'} = $p->{'on_request'};
   $self->{'on_header'}  = $p->{'on_header'};

   return $self;
}

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

   my %env = (
      REMOTE_ADDR => $self->{'server'}->{'peeraddr'},
      REMOTE_HOST => $self->{'server'}->{'peerhost'} || $self->{'server'}->{'peeraddr'},
      SERVER_NAME => $self->{'server'}->{'sockaddr'},
      SERVER_PORT => $self->{'server'}->{'sockport'},
      SCRIPT_NAME => ''
   );

   my $ret = parse_http_request($self->_fetch_header, \%env);
  
   if($ret == -1) {
      print STDERR "Request broken...\n";
      return;
   }

   if(defined $self->{'on_header'}) {
      my $hdr_call = $self->{'on_header'};
      &$hdr_call(\%env, $c);
   }

   my $call = $self->{'on_request'};
   $ret  = &$call(\%env, $c);

   if(exists $self->{'on_response'}) {
      my $r_call = $self->{'on_response'};
      $ret = &$r_call(\%env, $c, $ret);
   }

   my $len = length($ret);
   for(my $i = 0; $i < $len; $i) {
      syswrite $c, substr($ret, $i, WRITE_LEN);
      $i+=WRITE_LEN;
   }
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
