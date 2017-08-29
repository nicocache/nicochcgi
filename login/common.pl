#!/usr/bin/perl
use strict;
use Digest::SHA qw(sha256_hex);
use File::Basename 'basename', 'dirname';
use File::Spec;
use String::Random;

require DBD::SQLite;
require DBI;

sub GetSessionData{
  my ($dbh,$key)=@_;
  my $sth=$dbh->prepare("select * from session where key = '".escape_sql($key)."' join account on session.id = account.id");
  $sth->execute;
  return $sth->fetchrow_hashref();
}

sub UpdateAuthority{
  my ($dbh,$id,$authority)=@_;
  $authority=~ s/(\d+)/$1/;
  if($authority eq ""){$authority=0;}
  $id=~ s/(\d+)/$1/;
  if($id eq ""){$id="";}
  $dbh->do("update account set authority=".$authority." where id=".$id);
}

sub CreateAccountIfValid{
  my ($dbh,$user,$password)=@_;
  if((my $err = CheckUsernameValidity($dbh,$user)) ne "ok"){
    return ("error","username",$err);
  }
  if((my $err = CheckPasswordValidity($password)) ne "ok"){
    return ("error","password",$err);
  }
  my $salt=GetSalt();
  $dbh->do("insert into account(id,login,password,salt,authority) select case when max(id) is null then 1 else max(id) +1 end,'".$user."','"
    .GetHash($password,$salt)."','".$salt."',0 from account;");
  return ("ok");
}

sub GetDatabaseHandle{
  my %conf=GetConf(File::Spec->catfile(dirname(__FILE__),"login.conf"));
  my $dbh = DBI->connect("dbi:SQLite:dbname=".$conf{"sqlitedb"});
  $dbh->{sqlite_unicode} = 1;
  $dbh->do("create table if not exists account(id,login,password,salt,authority);");
  $dbh->do("create table if not exists session(key,id,date);");
  $dbh->do("create table if not exists redirect(id,url);");
  return $dbh;
}

sub CheckUsernameValidity{
  my ($dbh,$user)=@_;
  if($user eq ""){return "empty";}
  if(GetAccount($dbh,$user)){return "registered";}
  return "ok";
}

sub CheckPasswordValidity{
  my ($password)=@_;
  if(length($password)<=7){return "too_short";}
  if($password=~ /^[0-9]+$/){return "number_only";}
  return "ok";
}

sub PushSession{
  my ($dbh,$id,$key)=@_;
  $dbh->do("insert into session(key,id,date) values('".$key."','".$id."',".time.");");
}

sub VerifyAccount{
  my ($dbh,$user,$password)=@_;
  if(my $hash=GetAccount($dbh,$user)){
    if($hash->{'password'} eq GetHash($password,$hash->{'salt'})){
      return $hash;
    }else{
      return "";
    }
  }
  return "";
}

sub GetRedirectId{
  my ($dbh,$url)=@_;
  my $sth=$dbh->prepare("select * from redirect where url = '".escape_sql($url)."'");
  $sth->execute;
  if($sth->fetchrow_hashref()){
    return $sth->{"id"};
  }else{
    my $sth2=$dbh->prepare("select max(id) from redirect");
    $sth2->execute;
    my $id=0;
    if($sth->fetchrow_hashref()){
      $id=$sth2->{"max(id)"}+1;
    }
    $dbh->do("insert into redirect(id,url) values(".$id.",'".$url."');");
    return GetRedirectId();
  }
}

sub GetRedirectUrl{
  my ($dbh,$id)=@_;
  $id=~ s/(\d+)/$1/;
  if($id eq ""){$id=0;}
  my $sth=$dbh->prepare("select * from redirect where id = ".$id."");
  $sth->execute;
  if(my $hash= $sth->fetchrow_hashref()){
    return $hash->{"url"};
  }
  return "";
}

sub GetAccount{
  my ($dbh,$user)=@_;
  my $sth=$dbh->prepare("select * from account where login = '".escape_sql($user)."'");
  $sth->execute;
  return $sth->fetchrow_hashref();
}

sub GetSessionKey{
  my ($dbh)=@_;
  my $session=GetSessionKeyBasic();
  while(GetSession($dbh,$session)){
    $session=GetSessionKeyBasic();
  }
  return $session;
}

sub GetSession{
  my ($dbh,$key)=@_;
  my $sth=$dbh->prepare("select * from session where key = '".escape_sql($key)."'");
  $sth->execute;
  return $sth->fetchrow_hashref();
}

sub GetSessionKeyBasic{
  my $sr = String::Random->new();
  return Digest::SHA->sha256_hex($sr->randregex('[a-zA-Z0-9]{40}'));
}

sub GetSalt{
  my $sr = String::Random->new();
  return $sr->randregex('[a-zA-Z0-9]{40}');
}

sub GetHash{
  my ($password,$salt)=@_;
  my $saltedpw=length($salt).":".$salt.":".$password;
  return Digest::SHA->sha256_hex($saltedpw);
}

sub GetConf{
  my $file=$_[0];
  open(CONF,"< $file");
  my %result;
  while(my $line=<CONF>){
    if($line =~ m/^\#/){ next;}
    if($line =~ m/^(\w+)\=(.+)$/){
      $result{$1}=$2;
      next;
    }
  }
  return %result;
}

sub escape_sql{
  my $str=$_[0];
  if(defined($str)){
    $str=~ s/\\/\\\\\\\\/go;
    $str=~ s/'/''/go;
    $str=~ s/%/\\\\%/go;
    $str=~ s/_/\\\\_/go;
  }
  return $str;
}

1;
