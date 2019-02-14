#!/usr/bin/perl
use CGI;

print <<"HEAD";
Content-type: text/html

HEAD

print <<"EOF";
<html><head>
<title>Modification</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, user-scalable=yes,initial-scale=1.0" />
<meta http-equiv="refresh" content="5; URL=." />
</head>
<body>
<p>
EOF

my $referer = $ENV{'HTTP_REFERER'};
my $srvAddr = $ENV{'SERVER_ADDR'};
if(!$referer || ! $referer=~ m/^https?:\/$srvAddr\//) {
 print "Referer error:".$referer;
 die;
}

if($ENV{'REQUEST_METHOD'} eq "POST"){
 my $q=new CGI;
 my $op=$q->param('op');
 my $arg1=$q->param('a1');
 
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
   print $t."<br/>\n";
   if($t eq $arg1){
   $AlreadyRegisterd=1;
   last;
   }
  }
  if($AlreadyRegisterd==0){
   seek(FILE,2,0);
   print FILE $arg1."\n";
   print "Added $arg1 to list";
   }else{
   print "Url already registerd.";
   }
  close(FILE);
  }
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
    print "Deleted $arg1.<br />\n";
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
  }elsif($op eq "edit"){
  print "Total rewrite.<br />";
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
 print "</p></body>";
 }else{
 print "Please use post method.</p></body>\n";
}
