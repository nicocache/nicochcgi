#!/usr/bin/perl
use File::Spec;
use File::Basename 'basename', 'dirname';

require File::Spec->catfile(dirname(__FILE__),"common.pl");

print <<"HEAD";
Content-type: text/html

HEAD

print <<"EOF";
<html><head>
<title>ニコニコチャンネルレコーダー</title>
<link rel="stylesheet" type="text/css" href="default.css" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, user-scalable=yes,initial-scale=1.0" />
<!-- icon info -->
<link rel="shortcut icon" type="image/vnd.microsoft.icon" href="favicons/favicon.ico">
<link rel="icon" type="image/vnd.microsoft.icon" href="favicons/favicon.ico">
<link rel="apple-touch-icon" sizes="57x57" href="favicons/apple-touch-icon-57x57.png">
<link rel="apple-touch-icon" sizes="60x60" href="favicons/apple-touch-icon-60x60.png">
<link rel="apple-touch-icon" sizes="72x72" href="favicons/apple-touch-icon-72x72.png">
<link rel="apple-touch-icon" sizes="76x76" href="favicons/apple-touch-icon-76x76.png">
<link rel="apple-touch-icon" sizes="114x114" href="favicons/apple-touch-icon-114x114.png">
<link rel="apple-touch-icon" sizes="120x120" href="favicons/apple-touch-icon-120x120.png">
<link rel="apple-touch-icon" sizes="144x144" href="favicons/apple-touch-icon-144x144.png">
<link rel="apple-touch-icon" sizes="152x152" href="favicons/apple-touch-icon-152x152.png">
<link rel="apple-touch-icon" sizes="180x180" href="favicons/apple-touch-icon-180x180.png">
<link rel="icon" type="image/png" sizes="192x192" href="favicons/android-chrome-192x192.png">
<link rel="icon" type="image/png" sizes="48x48" href="favicons/favicon-48x48.png">
<link rel="icon" type="image/png" sizes="96x96" href="favicons/favicon-96x96.png">
<link rel="icon" type="image/png" sizes="96x96" href="favicons/favicon-160x160.png">
<link rel="icon" type="image/png" sizes="96x96" href="favicons/favicon-196x196.png">
<link rel="icon" type="image/png" sizes="16x16" href="favicons/favicon-16x16.png">
<link rel="icon" type="image/png" sizes="32x32" href="favicons/favicon-32x32.png">
<link rel="manifest" href="favicons/manifest.json">
<meta name="msapplication-TileColor" content="#ffffff">
<meta name="msapplication-TileImage" content="favicons/mstile-144x144.png">
<!-- end of icon info -->
</head>
<body>
EOF

my %conf=GetConf("nicoch.conf");
my @dirs=glob $conf{"dlhome"}."/*";

print "<h1>録画済み動画</h1>\n";

print "<div class='channel_group'>";
foreach my $dir (@dirs){
  if(-d $dir){
    my ($chid)= $dir =~ m!/([^/]+/?$)!;
    print "<div class='channel_box'>\n";
    print GetChannelThumbIframe($chid);
    #print "<br />";
    print "<div class='video_group'>\n";
    my @files=glob $dir."/*";
    foreach my $file (@files){
      next if ! -e $file;
      my ($watchid,$title) = $file =~ m!/([^\./]+)\.(.+)\.[^\.]+$!;
      next if $watchid == "tmp";
      print "<a href='play.html\#$watchid\:$chid'>$title</a>";
      print "(<a href='http://www.nicovideo.jp/watch/$watchid'>org</a>)<br />\n";
    }
    print "</div>\n";
    print "</div>\n";
  }
}
print "</div>";

print "<h1>録画予約</h1>\n";
print <<"FORM";
<div class="form_add">
<form action="modify.cgi" method="post">
<input type="input" name="a1" value="http://ch.nicovideo.jp/..." />
<input type="hidden" name="op" value="add" />
<input type="submit" value="追加" />
</form>
<a href="http://ch.nicovideo.jp">ニコニコチャンネル</a>
<a href="editor.cgi">一括編集</a>
</div>
FORM

print "<h1>録画予約中のチャンネル</h1>";

my @chlist=GetChannels();

print "<div class='channel_group'>";
foreach my $ch (@chlist){
  print "<div class='channel_box'>\n";
  my $chid=GetChannelName($ch);
  print GetChannelThumbIframe($chid);

$ch=~ s/[\r\n]//g;
  print <<"FORM";
<form action="modify.cgi" method="post">
<input type="hidden" name="a1" value="$ch" />
<input type="hidden" name="op" value="del" />
<input class="delete" type="submit" value="削除" />
</form>
FORM
  
  print "</div>\n";
}
print "</div>";
print "</body></html>";

