#!/usr/bin/perl
use CGI;
use File::Spec;
use File::Basename 'basename', 'dirname';

require File::Spec->catfile(dirname(__FILE__),"common.pl");

print <<"HEAD";
Content-type: text/html

HEAD

print <<"EOF";
<html>
 <head>
  <title>Modification</title>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  <meta name="viewport" content="width=device-width, user-scalable=yes,initial-scale=1.0" />
  <!--<meta http-equiv="refresh" content="5; URL=." />-->
  <style type="text/css">
p, form{text-align: center;}
p#message{
  
}
form.auth{
}
a{
 color:black;
 text-decoration:none;
 font-weight:bold;
}
div#content{
 border:solid 1px black;
}
  </style>
 </head>
 <body>
EOF

my @result=Operate();
my $message=$result[1];
my $q=new CGI;
$q->charset('utf-8');
$message=$q->escapeHTML($message);
$message=~ s/\n/<br \/>/g;

print "  <div id='content'>\n";
print "  <p id='message'>\n";
print $message;
print "  </p>\n";
if($result[2] eq "password_wrong" || $result[2] eq "password_required"){
 print "  <form class='auth' action='modify.cgi' method='post' />\n";
 print "   <input type='password' name='password' />\n";
 print "   <input type='hidden' name='op' value='".$q->escapeHTML($q->param('op'))."' />\n";
 print "   <input type='hidden' name='a1' value='".$q->escapeHTML($q->param('a1'))."' />\n";
 print "   <input type='submit' value='実行' />\n";
 print "  </form>\n";
}
print " <p><a href='.'>ページトップ</a></p>\n";
print " <p><a href='".$ENV{'HTTP_REFERER'}."'>前のページ</a></p>\n";
print " </div>\n";
print " </body>\n</html>\n";

sub Operate{
if($ENV{'REQUEST_METHOD'} eq "POST"){
 my $referer = $ENV{'HTTP_REFERER'};
 my $srvAddr = $ENV{'SERVER_ADDR'};
 if(!$referer || ! $referer=~ m/^https?:\/$srvAddr\//) {
  return ("error","リファラが不適切です:".$referer,"referer_error");
  
 }
 
 my %conf=GetConf("nicoch.conf");
 my $q=new CGI;
 my $op=$q->param('op');
 my $arg1=$q->param('a1');
 my $message="";

 if(exists($conf{"password"})){
  if((! exists($conf{"password_salt"})) || (! exists($conf{"password_stretching"}))){
   return ("error","パスワード設定に問題があります。管理者に連絡してください。","password_error_configure");
  }
  if((not defined $q->param('password')) || $q->param('password') eq ""){
   return ("error","パスワードが必要です。","password_required");
  }
  my $hash=GetHashed(scalar($q->param('password')),$conf{"password_salt"},0+$conf{"password_stretching"});
  if($hash ne $conf{"password"}){
   return ("error","パスワードが誤っています。","password_wrong");
  }
 }
 
 if($op eq "add"){
  if($arg1=~ m!^https?://ch.nicovideo.jp/!){
   $arg1=~ s/[\n\r]//g;
   $arg1=~ s/\?[^\?]+$//;
   open FILE, "+>>", "chlist.txt" or die "error";
   flock(FILE, 2);
   my $AlreadyRegisterd=0;
   seek(FILE,0,0);
   while(my $t=<FILE>){
   chomp($t);
   $t=~ s/\?[^\?]+$//;
   $message.= $t."\n";
   if($t eq $arg1){
   $AlreadyRegisterd=1;
   last;
   }
  }
  if($AlreadyRegisterd==0){
   seek(FILE,2,0);
   print FILE $arg1."\n";
   $message.="'$arg1'を追加しました。\n";
   }else{
   $message.="'$arg1'は既に登録されています。";
   }
  close(FILE);
  }
  return ("success",$message,"add");
 }elsif($op eq "del"){
  open FILEIN, "<", "chlist.txt" or die "error";
  open FILEBUP, ">", "chlist.bup" or die "error";
  flock(FILEIN, 1);
  flock(FILEBUP, 2);
  my $result="";
  while(my $t=<FILEIN>){
   print FILEBUP $t;
   my $o=$t;
   chomp $t;
   if($t eq $arg1){
    $message.="'$arg1'を除外しました。\n";
    $result.= "\#".$o;
    }else{
    $result.= $o;
    }
   }
  close(FILEIN);
  close(FILEBUP);
  open FILEORG, ">", "chlist.txt" or die "error";
  flock(FILEORG, 2);
  print FILEORG $result;
  close(FILEORG);
  return ("success",$message,"delete");
  }elsif($op eq "edit"){
  $message.="設定ファイルを書き換えました。\n";
  open FILEORG, "<", "chlist.txt" or die "error";
  open FILEBUP, ">", "chlist.bup" or die "error";
  flock(FILEORG, 1);
  flock(FILEBUP, 2);
  while(my $t=<FILEORG>){
   print FILEBUP $t;
   }
  close(FILEORG);
  close(FILEBUP);
  open FILEORGOUT, ">", "chlist.txt" or die "error";
  flock(FILEORGOUT, 2);
  $arg1=~ s/\r\n/\n/g;
  print FILEORGOUT $arg1;
  }
  close(FILEORGOUT);
  return ("success",$message,"edit");
 }else{
 $message.="'POST'でアクセスしてください。\n";
 return ("error",$message,"error_not_post");
}
}
