use File::Spec;
use strict;
use Digest::MD5 qw/md5_hex/;
use File::MimeInfo qw(globs);
use File::Basename 'basename' , 'dirname';

sub GetChannels{
  my @result;
  my $chlist=File::Spec->catfile(dirname(__FILE__),"chlist.txt");
  open(FILE,"<",$chlist);
  while(my $urlch =<FILE>){
    if($urlch=~ m!^(https?://ch.nicovideo.jp/.+)!){
      push @result,$1;
    }
  }
  return @result;
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

sub GetChannelThumbIframe{
  my $chid=$_[0];
  return "<iframe class='channel_thumb' src='http://ch.nicovideo.jp/$chid/thumb_channel' scrolling='no'></iframe>";
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

sub TransferFile{
  my $file=$_[0];
  my ($ext)= $file =~ m!\.([^\.]+)$!;

  my $blocksize=4096;

  my $mimetype=globs($file);
  my $filesize=-s $file;

  open MOVIE, "<" , $file or die;
  binmode MOVIE;

  my $range=$ENV{'HTTP_RANGE'};
print <<"HEAD";
Content-type: $mimetype
Accept-Ranges: bytes
HEAD
print "Etag: \"". md5_hex($ENV{"REQUEST_URI"}) ."$filesize\"\n";

  if($range ne ""){
    my ($start,$end)= $range=~ m/(\d*)\-(\d*)/;
    if ($start eq "" || $start>$filesize){$start=0;}
    if ($end eq "" || $end<=$start){$end=$filesize-1;}
    my $length=$end-$start+1;

print <<"HEAD";
Status: 206 Partial Content
Content-Length: $length
Content-Range: bytes $start-$end/$filesize

HEAD

    binmode STDOUT;
    seek MOVIE, $start,0;
    my $current=$start;

    while (read MOVIE, my $buffer, ($end-$current+1<$blocksize?$end-$current+1:$blocksize)){
      print $buffer;
      $current+=$blocksize;
      if($end<=$current){return;}
    }
  }else{
    print "Content-Length: $filesize\n\n";
    binmode STDOUT;

    while (read MOVIE, my $buffer, $blocksize){
      print $buffer;
    }
  }
}

sub GetForm{
  my @form=split(/&/,$ENV{'QUERY_STRING'});
  my %result;
  foreach my $tmp (@form){
    my ($name,$value)=split(/=/,$tmp);
    $result{$name}=$value;
  }
  return %result;
}

1;
