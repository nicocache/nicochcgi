#!/usr/bin/perl
use File::Spec;
use File::Basename 'basename', 'dirname';

require File::Spec->catfile(dirname(__FILE__),"common.pl");

print <<"HEAD";
Content-Type: application/json;charset=utf-8;

HEAD

print "{\n";
print "  \"recorded_channels\":\n  [\n";

my %conf=GetConf("nicoch.conf");
my @dirs=glob $conf{"dlhome"}."/*";

my $cnt1=0;
foreach my $dir (@dirs){
  if(-d $dir){
    if($cnt1>0){print ",\n";}
    $cnt1++;
    print "    {\n";
    my ($chid)= $dir =~ m!/([^/]+/?$)!;
#next line is for compatibility...
    print "      \"channel_id\":\"$chid\",\n";
    print "      \"channnel_id\":\"$chid\",\n";
    print "      \"videos\":[\n";

    my @files=glob $dir."/*";
    my $cnt2=0;
    foreach my $file (@files){
      next if ! -e $file;
      my ($watchid,$title) = $file =~ m!/([^\./]+)\.(.+)\.[^\.]+$!;
      next if $watchid == "tmp";
      if($cnt2>0){print ",\n";}
      $cnt2++;
     
      print "        {\n          \"id\":\"$watchid\",\n";
      print "          \"title\":\"".EscapeJson($title)."\",\n";
      print "          \"movie_url\":\"movie.cgi?c=$chid&v=$watchid\",\n";
      print "          \"thumbnail_url\":\"thumb.cgi?c=$chid&v=$watchid\",\n";
      print "          \"player_url\":\"play.html\#$watchid:$chid\",\n";
      print "          \"comment_url\":\"commentproxy.cgi?id=$watchid\"\n";
      print "        }";
    }
    print "\n      ]";
    print "\n    }";
  }
}
print "\n  ],";

print "\n  \"recording_channels\":[\n";
my @chlist=GetChannels();

$cnt1=0;
foreach my $ch (@chlist){
  if($cnt1>0){print ",\n";}
  $cnt1++;
  my ($chid)= $ch =~ m!\/([^\/]+)\/?$!;
  print "    {\"channel_url\":\"$ch\",\"channel_id\":\"$chid\"}";
  $ch=~ s/[\r\n]//g;
}
print "\n  ]\n}";

sub EscapeJson{
my $text=$_[0];
$text=~ s/([\\\"])/\\$1/g;
return $text;
}
