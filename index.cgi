#!/usr/bin/perl
print <<"HEAD";
Content-type: text/html

HEAD

print <<"EOF";
<html><head>
<title>Nico Channel Manager</title>
<link rel="stylesheet" type="text/css" href="default.css" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, user-scalable=yes,initial-scale=1.0" />
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
      print "<a href='movie.cgi?c=$chid&v=$watchid'>$title</a>";
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


sub GetChannelThumbIframe{
  my $chid=$_[0];
  return "<iframe class='channel_thumb' src='http://ch.nicovideo.jp/$chid/thumb_channel' scrolling='no'></iframe>";
}

sub GetChannels{
  my @result;
  open(FILE,"< chlist.txt");
  while(my $urlch =<FILE>){
    if($urlch=~ m!^https?://ch.nicovideo.jp/.+!){
      push @result,$urlch;
    }
  }
  return @result;
}

sub GetChannelName{
  my $arg=$_[0];
  if($arg=~ m!^https?://ch.nicovideo.jp/channel/([^/]+)!){
    return $1;
  }
  if($arg=~ m!^https?://ch.nicovideo.jp/([^/]+)!){
    return $1;
  }
  return "";
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
