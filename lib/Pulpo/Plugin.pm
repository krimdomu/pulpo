#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Pulpo::Plugin;

use strict;
use warnings;

use vars qw($ATTACH);

sub attach_to {
   my ($class, $stage, $code) = @_;
   if( ! exists $ATTACH->{$stage}) {
      $ATTACH->{$stage} = [];
   }

   push @{$ATTACH->{$stage}}, $code;
}

sub get_code_for {
   my ($class, $stage) = @_;
   return $ATTACH->{$stage} if exists $ATTACH->{$stage};
   return [];
}

1;
