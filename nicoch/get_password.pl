#!/usr/bin/perl
use strict;

use File::Spec;
use File::Basename 'basename', 'dirname';
use warnings;
use Term::ReadKey;
use String::Random;

require File::Spec->catfile(dirname(__FILE__),"common.pl");

main();
sub main{
  print "Input Password:";
  ReadMode "noecho";
  my $line = ReadLine 0;
  chomp($line);
  ReadMode "restore";
  
  my $sr = String::Random->new();
  my $salt = $sr->randregex('[a-zA-Z0-9]{70}');
  my $count = 50000;
  
  print "\n\n以下をnicoch.confにコピーしてください(既にあれば上書き)。\n\n";
  
  print "#________ここから________\n";
  print "password_salt=".$salt."\n";
  
  print "password=";
  print GetHashed($line,$salt,$count);
  print "\n";
  
  print "password_stretching=".$count."\n";
  
  print "password_algorithm=SHA256\n";
  print "#________ここまで________\n";
}

