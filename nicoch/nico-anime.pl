#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Spec;
use LWP::UserAgent;
use URI;
use WWW::NicoVideo::Download;
use Web::Scraper;
use XML::Simple;
use Net::Netrc;

use URI::Escape;
use Unicode::Escape qw(escape unescape);
use JSON;

require File::Spec->catfile(dirname(__FILE__),"common.pl");

binmode(STDOUT, ":utf8");

$| = 1;

print "Log\nTime: ".time."\n";

print "Locked...\n";
open(LOCK, File::Spec->catfile(dirname(__FILE__),"lock"));
flock(LOCK, 2);
print "Unlocked!\n";

my $mach = Net::Netrc->lookup('nicovideo');
my ($nicologin, $nicopassword, $nicoaccount) = $mach->lpa;

my $client = WWW::NicoVideo::Download->new(
    email => $nicologin,
    password => $nicopassword,
);

my %conf=GetConf(File::Spec->catfile(dirname(__FILE__),"nicoch.conf"));
my @url = GetChannels();

my $animedir=$conf{"dlhome"};
#my $animedir=dirname(__FILE__)

foreach my $url (@url) {
    my $video;
    my $video2;
    eval{
    $video = scraper {
        process '.g-video-title .g-video-link', 'title' => 'TEXT', 'url[]' => '@href';
    }->scrape(URI->new($url));
    $video2 = scraper {
        process '.thumb_video', 'title' => 'TEXT', 'url[]' => '@href';
    }->scrape(URI->new($url."/video"));
    };
    sleep(1);
    if($@){
      warn "ERROR: $@\n";
      next;
    }

    my ($chid) = $url =~ m!/([^/]+?)/?$!;
    my $chdir=File::Spec->catfile($animedir , $chid );
    if(! -d $chdir){mkdir $chdir;}

    foreach my $surl (@{$video->{url}},@{$video2->{url}}){
        my ($video_id) = $surl =~ m!/watch/(\w+)!;

        my $ext = "mp4";

        my @testfile=glob("\"".File::Spec->catfile($chdir , "$video_id.*.$ext")."\"" );
        next if @testfile+0 >0;
        
        #my $res = $client->user_agent->get("http://ext.nicovideo.jp/api/getthumbinfo/$video_id");
        
        #my $ext = $info->{video}->{movieType};
        my $info = GetInfo($client,$video_id,$chid);
        sleep(1);
        my $title = $info->{video}->{title};

        $title=~ s/[\/\\\:\,\;\*\?\"\<\>\|]//g;

        my $fileold = File::Spec->catfile($chdir , "$video_id.$ext");
        my $file = File::Spec->catfile($chdir , "$video_id.$title.$ext");
        my $filetmp = File::Spec->catfile($chdir , "tmp.$ext");
        unlink $filetmp if -e $filetmp;
        next if -e $file;

        if(-e $fileold ) {
            rename $fileold,$file;
            next;
        }

        print "download $file\n";
        open my $fh, '>', $filetmp or die $!;
        eval {
          #my $vurl= $client->prepare_download($video_id);
          my $vurl= $info->{video}->{smileInfo}->{url};
          my $dl_error="";
          my $dl_size=-1;
          my $dl_downloaded=0;
          if ($vurl=~ /low$/){die "low quality";}

          my $downloder = sub {
              my ($data, $res, $proto) = @_;
              $dl_size=0+$res->headers->header('Content-Length') if defined $res->headers->header('Content-Length');
              die $dl_error="failed" if !$res->is_success;
              die $dl_error="aborted" if defined $res->headers->header('Client-Aborted');
              die $dl_error="died: ".$res->headers->header("X-Died") if defined $res->header("X-Died");
              $dl_downloaded+=length $data;
              print {$fh} $data;
              };

          #$client->download($video_id, $downloder);
          {
            my $request=HTTP::Request->new( GET => $vurl );
            my $res2=$client->user_agent->request( $request, $downloder);
            die "Failed: ".$res2->status_line if $res2->is_error;
          }
          
          if($dl_error ne ""){unlink $filetmp; die $dl_error;}
          if($dl_downloaded!=$dl_size && $dl_size != -1){
            my $dl_size_org=$dl_size;
            my $i=0;
            my $max_retry_count=3;
            while($i<$max_retry_count && $dl_downloaded!=$dl_size_org){
              $i++;
              print $dl_downloaded."B / ".$dl_size_org."B downloaded. Continue.\n";
              sleep 30;
              $info = GetInfo($client,$video_id,$chid);
              sleep(1);
              my $vurl2= $info->{video}->{smileInfo}->{url};
              if ($vurl2=~ /low$/){die "low quality";}
              my $request=HTTP::Request->new( GET => $vurl2 );
              $request->header(Range=>"bytes=".($dl_downloaded)."-");
              my $res2=$client->user_agent->request( $request, $downloder);
              die "Failed: ".$res2->status_line if $res2->is_error;
              if($dl_error ne ""){unlink $filetmp; die $dl_error;}
            }
          
            if($dl_downloaded!=$dl_size_org){
              unlink $filetmp;
              die "Only ".$dl_downloaded."B / ".$dl_size_org."B downloaded.";
            }
          }
          if(-s $filetmp == 0){unlink $filetmp;}
          else{rename $filetmp,$file;}
        };
        sleep 10;
        if ($@) {
          warn "ERROR: $@\n";
          unlink $filetmp;
          next;
        }
    }
}

print "Time: ".time."\nDone\n";

sub GetInfo{
  my $info;
  my ($client,$video_id,$chid)=@_;
  eval{
    my $info_res = $client->user_agent->get("https://www.nicovideo.jp/watch/".$video_id);
    my $info_json = scraper {
      process 'div#js-initial-watch-data', 'json' => '@data-api-data';
    }->scrape($info_res->content)->{json};
    $info_json = unescape($info_json);
    $info = decode_json( $info_json );
  };
  if($@ || ! defined($info)){
    warn "Channel:$chid Id:$video_id\n";
    warn "ERROR: $@\n";
    return;
  }
  return $info;
}
