#!/usr/bin/perl
use File::Spec;
use strict;
use Digest::MD5 qw/md5_hex/;
use File::MimeInfo qw(globs);
use File::Basename 'basename', 'dirname';

require File::Spec->catfile(dirname(__FILE__),"common.pl");

my %form=GetForm();

my %conf=GetConf("nicoch.conf");
my @dirs=glob $conf{"dlhome"}."/*";

foreach my $dir (@dirs){
  if(-d $dir){
    if(basename($dir) ne $form{"c"}){
      next;
    }
    my @files=glob $dir."\/*";
    foreach my $file (@files){
      next if ! -e $file;
      my ($watchid,$title,$ext) = $file =~ m!/([^\./]+)\.(.+)\.([^\.]+)$!;
      next if $watchid == "tmp";

      if($watchid ne $form{"v"}){
        next;
      }
      TransferFile($file);
      exit;
    }
  }
}

print "Status: 404 Not Found\n\n";
