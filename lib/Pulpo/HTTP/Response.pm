#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Pulpo::HTTP::Response;

use strict;
use warnings;
use attributes;
use overload '""' => sub { shift->to_string; };
use IO::Socket qw(:crlf);

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   $self->{'status'}  ||= 200;
   $self->{'message'} ||= 'OK';
   $self->{'header'}  ||= [];
   $self->{'content'} ||= '';

   return $self;
}

sub status :lvalue {
   my ($self) = @_;
   $self->{'status'};
}

sub message :lvalue {
   my ($self) = @_;
   $self->{'message'};
}

sub content :lvalue {
   my ($self) = @_;
   $self->{'content'};
}

sub push_header {
   my ($self, $key, $val) = @_;
   push @{$self->{'header'}}, [$key => $val];
}

sub header {
   my ($self, $key, $val) = @_;

   for(my $i = 0; $i < @{$self->{'header'}}; ++$i) {
      if($self->{'header'}->[$i]->[0] eq $key) {
         splice(@{$self->{'header'}}, $i, 1);
      }
   }

   $self->push_header($key, $val);
}

sub get_http_line {
   my ($self) = @_;
   return 'HTTP/1.1 ' . $self->status . ' ' . $self->message . "$CRLF";
}

sub get_headers_as_string {
   my ($self) = @_;
   my $str = '';
   for my $header (@{$self->{'header'}}) {
      $str .= $header->[0] . ': ' . $header->[1] . "$CRLF";
   }

   return $str;
}

sub to_string {
   my ($self) = @_;

   my $str = $self->get_http_line;
   $str .= $self->get_headers_as_string;
   $str .= "$CRLF";

   $str .= $self->content;

   return $str;
}

1;
