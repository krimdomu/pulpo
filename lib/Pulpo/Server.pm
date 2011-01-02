package Pulpo::Server;

use strict;
use warnings;

use Data::Dumper;

use Net::Server::PreFork;
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use IO::Socket qw(:crlf);
use HTTP::Parser::XS qw(parse_http_request);

use Pulpo::Plugin;
use Pulpo::Exception;
use Pulpo::Exception::NoRequestModule;
use Pulpo::Exception::RequestTimeout;
use Pulpo::HTTP::Response;

use constant READ_LEN     => 64 * 1024;
use constant READ_TIMEOUT => 3;
use constant WRITE_LEN    => 64 * 1024;

use base qw(Net::Server::PreFork);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   $self->{'config'} = { @_ };

   bless($self, $proto);

   $self->{'on_request'} = $self->{'config'}->{'on_request'};

   return $self;
}

sub run {
   my $self = shift;


   $self->SUPER::run(
      port                 => $self->{'config'}->{'port'}               || '8080',
      host                 => $self->{'config'}->{'host'}               || '',
      min_servers          => $self->{'config'}->{'min_servers'}        || 5,
      min_spare_servers    => $self->{'config'}->{'min_spare_servers'}  || 5,
      max_spare_servers    => $self->{'config'}->{'max_spare_servers'}  || 10,
      max_servers          => $self->{'config'}->{'max_servers'}        || 20,
      listen               => $self->{'config'}->{'backlog'}            || 1024,

      no_client_stdout     => 1,
      proto                => 'tcp',
      serialize            => 'flock',
   );

}

sub process_request {
   my $self = shift;
   my $c = $self->{'server'}->{'client'};
   setsockopt($c, IPPROTO_TCP, TCP_NODELAY, 1) or die($!);

   for my $code (@{Pulpo::Plugin->get_code_for('connect')}) {
      my $c_ret = &$code($c);
      if($c_ret == -1) { return; }
   }

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

   for my $code (@{Pulpo::Plugin->get_code_for('header')}) {
      my $c_ret = &$code($c, \%env);
      if($c_ret == -1) { return; }
   }

   REQUEST: {
      my $call = Pulpo::Plugin->get_code_for('request')->[0];
      if(! $call) { die Pulpo::Exception::NoRequestModule->new(msg => 'No request module loaded.'); }
      $ret  = &$call($c, \%env);
      if(ref($ret) ne 'Pulpo::HTTP::Response') {
         print STDERR "Strange error...\n";
         return;
      }
   }

   for my $code (@{Pulpo::Plugin->get_code_for('response')}) {
      $ret = &$code($c, \%env, $ret);
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
      local $SIG{'ALRM'} = sub { die Pulpo::Exception::RequestTimeout->new(msg => 'Request timed out.'); };
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
