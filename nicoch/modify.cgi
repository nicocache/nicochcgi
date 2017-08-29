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
if($arg1=~ m!^http://ch.nicovideo.jp/!){
$arg1=~ s/[\n\r]//g;
open FILE, ">>", "chlist.txt" or die "error";
print FILE $arg1."\n";
print "Added $arg1 to list";
}
}elsif($op eq "del"){
open FILEIN, "<", "chlist.txt" or die "error";
open FILEBUP, ">", "chlist.bup" or die "error";
open FILEOUT, ">", "chlist.tmp" or die "error";
while(my $t=<FILEIN>){
print FILEBUP $t;
my $o=$t;
$t=~ s/[\r\n]//g;
if($t eq $arg1){
print "Deleted $arg1.<br />\n";
print FILEOUT "\#".$o;
}else{
print FILEOUT $o;
}
}
open FILETMP, "<", "chlist.tmp" or die "error";
open FILEOUT, ">", "chlist.txt" or die "error";
while(my $t=<FILETMP>){
print FILEOUT $t;
}
}
print "</p></body>";
}else{
print "Please use post method.</p></body>\n";
}
