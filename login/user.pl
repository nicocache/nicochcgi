#!/usr/bin/perl
use strict;
use File::Basename 'basename', 'dirname';
use File::Spec;

require File::Spec->catfile(dirname(__FILE__),"common.pl");

my $dbh=GetDatabaseHandle();

if($ARGV[0] eq "-a"){
  my $user=$ARGV[1];
  my $password=$ARGV[2];
  my @result= CreateAccountIfValid($dbh,$user,$password);
  print join(" , ",@result)."\n";
}elsif($ARGV[0] eq "-s"){
  my $login=$ARGV[1];
  my $password=$ARGV[2];
  if(my $account=VerifyAccount($dbh,$login,$password)){
    my $key= GetSessionKey($dbh);
    PushSession($dbh,$account->{"id"},$key);
    print $key."\n";
  }else{
    print "wrong ID or password.\n";
  }
}elsif($ARGV[0] eq "-p"){
  my $login=$ARGV[1];
  my $password=$ARGV[2];
  my $authority=$ARGV[3];
  if(my $account=VerifyAccount($dbh,$login,$password)){
    UpdateAuthority($dbh,$account->{"id"},$authority);
    print "Updated Previlage";
  }else{
    print "wrong ID or password";
  }
}else{
}

