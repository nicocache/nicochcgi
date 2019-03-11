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
#use Unicode::Escape qw(escape unescape);
use JSON;

use File::Path;

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
        
        #my $ext = $info->{video}->{movieType};
        my $info = GetInfo($client->user_agent,$video_id,$chid);
        sleep(1);

        my $title;
        my $getthumbinfo_res;
        if(defined($info)){
          $title = $info->{video}->{title};
        }else{
          $getthumbinfo_res = $client->user_agent->get("http://ext.nicovideo.jp/api/getthumbinfo/$video_id");
          $title = XMLin($getthumbinfo_res->content)->{thumb}{title};
          $ext = XMLin($getthumbinfo_res->content)->{thumb}{movie_type};
          
          my @testfile2=glob("\"".File::Spec->catfile($chdir , "$video_id.*.$ext")."\"" );
          next if @testfile2+0 >0;
        }

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

        print "Download $file\n";
        open my $fh, '>', $filetmp or die $!;
        eval {
          my ($dl_size, $dl_downloaded, $is_hls) = DownloadVideo($info,$video_id,$chid,$client,0,$fh,$chdir);
          if($is_hls){
            unlink $filetmp;
            return;
          }
          
          if($dl_downloaded!=$dl_size && $dl_size != -1){
            my $dl_size_org=$dl_size;
            my $i=0;
            my $max_retry_count=5;
            while($i<$max_retry_count && $dl_downloaded!=$dl_size_org){
              $i++;
              print $dl_downloaded."B / ".$dl_size_org."B downloaded. Continue.\n";
              sleep 30;
              
              $info = GetInfo($client->user_agent,$video_id,$chid);
              sleep(1);
              
              my ($dl_size_left, $dl_downloaded_current) = DownloadVideo($info,$video_id,$chid,$client,$dl_downloaded,$fh);
              if ($dl_size_left+$dl_downloaded!=$dl_size){die "Content-Length missmatch: ".($dl_size_left+$dl_downloaded)." : ".($dl_size);}
              $dl_downloaded += $dl_downloaded_current;
            }
          
            if($dl_downloaded!=$dl_size_org){
              unlink $filetmp;
              die "Only ".$dl_downloaded."B / ".$dl_size_org."B downloaded.";
            }
          }
          if($dl_downloaded == 0){
            die "Downloaded file empty.";
          }
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

sub DownloadVideo{
  my ($info,$video_id,$chid,$client,$range_from,$fh,$working_dir)=@_;
  
  if(! defined($info)){
    $info = GetInfo($client->user_agent,$video_id,$chid);
    sleep(1);
  }

  my $vurl;
  my $session_uri;
  my $json_dsr;
  my $is_hls=0;
  if(defined($info) && defined($info->{video}->{dmcInfo}->{quality}->{videos}) && defined($info->{video}->{dmcInfo}->{session_api}->{videos})){
    $vurl = $info->{video}->{smileInfo}->{url};
    if ($vurl=~ /low$/){die "low quality";}
    if (@{$info->{video}->{dmcInfo}->{quality}->{videos}}+0 != @{$info->{video}->{dmcInfo}->{session_api}->{videos}}+0){die "low quality";}
    ($json_dsr,$session_uri) = GetHtml5VideoJson($info, $client->user_agent);
    if(defined($json_dsr) && defined($json_dsr->{data}->{session}->{content_uri})){
      print "Access via api.dmc.nico\n";
      if(defined($info->{video}->{dmcInfo}->{encryption})){
        $is_hls=1;
        print "Using HLS encrypted connection.\n";
      }
      $vurl = $json_dsr->{data}->{session}->{content_uri};
    }
  }else{
    $vurl= $client->prepare_download($video_id);
  }
  if ($vurl=~ /low$/){die "low quality";}

  my $ping_content;
  if(defined($json_dsr)){
    $ping_content=encode_json({session => $json_dsr->{data}->{session}});
  }
  if($is_hls==0){
    return DownloadFile($vurl,$client->user_agent,$fh,$range_from,$session_uri,$json_dsr->{data}->{session}->{id},$ping_content);
  }else{
    die "HLS encryption not supported.";

    my $dir_tmp = File::Spec->catfile($working_dir , $video_id.".hls_tmp/");
    my $ua=$client->user_agent;
    
    $ua->default_header( "Origin" => "https://www.nicovideo.jp" );
    $ua->default_header( "Referer" => "https://www.nicovideo.jp/watch/$video_id" );
    
    {
      #以下を参考に。
      #https://github.com/tor4kichi/Hohoema/issues/778
      #なくても動いていたと思うが…。
      my $ping_uri="https://nvapi.nicovideo.jp/v1/2ab0cbaa/watch?t=".uri_escape($info->{video}->{dmcInfo}->{tracking_id});
      my $request_option=HTTP::Request->new( "OPTIONS" , $ping_uri );
      $ua->request($request_option);
      $ua->get($ping_uri);
      
      print $ping_uri."\n";
    }
    
    if(-d $dir_tmp){
      rmtree $dir_tmp;
    }
    mkdir $dir_tmp;
    
    my $m3u8_master_res = $ua->get($json_dsr->{data}->{session}->{content_uri});

    {
      open my $fh_m3u8, '>', File::Spec->catfile($dir_tmp,GetFileName($json_dsr->{data}->{session}->{content_uri})) or die $!;
      print {$fh_m3u8} $m3u8_master_res->content;
    }
    
    
    my $m3u8_playlist;
    {
      foreach my $line (split(/\n/,$m3u8_master_res->content)){
        if($line=~ /^\#/){next;}
        $m3u8_playlist = $line;
      }
      if(! defined($m3u8_playlist)){die "No playlist provided.";}
      my $m3u8_master_dir=$json_dsr->{data}->{session}->{content_uri};
      $m3u8_master_dir=~ s/\/[^\/]+?$/\//;
      $m3u8_playlist = $m3u8_master_dir.$m3u8_playlist;
    }
    
    sleep(1);
    my $m3u8_playlist_res = $ua->get($m3u8_playlist);
    {
      open my $fh_m3u8, '>', File::Spec->catfile($dir_tmp,GetFileName($m3u8_playlist).".org") or die $!;
      print {$fh_m3u8} $m3u8_playlist_res->content;
    }
    {
      open my $fh_m3u8, '>', File::Spec->catfile($dir_tmp,GetFileName($m3u8_playlist)) or die $!;
      my $content = $m3u8_playlist_res->content;
      $content=~ s/([\n\r][^\#\n\r][^\?\n\r]*)\?[^\?\n\r]+([\n\r])/$1$2/g;
      $content=~ s/([\n\r]\#EXT-X-KEY:.+URI=)"[^"]+"/$1"hls"/;
      print {$fh_m3u8} $content;
    }
    
    my $m3u8_playlist_dir = $m3u8_playlist;
    $m3u8_playlist_dir =~ s/\/[^\/]+?$/\//;
    
    foreach my $line (split(/\n/,$m3u8_playlist_res->content)){
      chomp($line);
      if($line=~ /^\#EXT-X-KEY:.+URI="([^"]+)"/){
        my $hls_key_url = $1;
        my $hls_key_res = $ua->get($hls_key_url);
        open my $fh_hls_key, '>', File::Spec->catfile($dir_tmp,"hls") or die $!;
        print {$fh_hls_key} $hls_key_res->content;
        
        #open my $fh_hls_key_info, '>', File::Spec->catfile($dir_tmp,"hls_info") or die $!;
        #print {$fh_hls_key_info} "$hls_key_url\nhls\n";
        
        open my $fh_hls_key_json, '>', File::Spec->catfile($dir_tmp,"hls_info.json") or die $!;
        print {$fh_hls_key_json} encode_json($info->{video}->{dmcInfo}->{encryption});
        
        next;
      }
      if($line eq ""){next;}
      if($line=~ /^\#/){next;}
      {
        my $ts_res = $ua->get($m3u8_playlist_dir.$line);
        sleep(1);
        
        open my $fh_ts, '>', File::Spec->catfile($dir_tmp,GetFileName($line)) or die $!;
        print {$fh_ts} $ts_res->content;
        next;
      }
    }

    return (0,0,1);
  }
}

sub GetFileName{
  my ($file)=@_;
  $file =~ s/\?[^\?]+$//;
  $file =~ s/^.+\///;
  return $file;
}

sub DownloadFile{
  my ($vurl,$ua,$fh,$range_from,$session_uri,$session_id,$ping_content)=@_;
  my $dl_error="";
  my $dl_size=-1;
  my $dl_downloaded=0;
  my $last_ping=time;
  
  my $downloder = sub {
    my ($data, $res, $proto) = @_;
    $dl_size=0+$res->headers->header('Content-Length') if defined $res->headers->header('Content-Length');
    die $dl_error="failed" if !$res->is_success;
    die $dl_error="aborted" if defined $res->headers->header('Client-Aborted');
    die $dl_error="died: ".$res->headers->header("X-Died") if defined $res->header("X-Died");
    $dl_downloaded+=length $data;
    print {$fh} $data;

    if(defined($session_uri) && time-$last_ping>40){
      my $ping_uri=$session_uri."/".$session_id."?_format=json&_method=PUT";
      
      my $request_option=HTTP::Request->new( "OPTIONS" , $ping_uri );
      $request_option->content($ping_content);
      $ua->request($request_option);
      
      $ua->post($ping_uri, Content => $ping_content);
      
      $last_ping = time;
    }
    };

  {
    my $request=HTTP::Request->new( GET => $vurl );
    $request->header(Range=>"bytes=".($range_from)."-");
    my $res2=$ua->request( $request, $downloder);
    die "Failed: ".$res2->status_line if $res2->is_error;
  }
  
  if($dl_error ne ""){die $dl_error;}

  return ($dl_size,$dl_downloaded);
}

sub GetInfo{
  my $info;
  my ($ua,$video_id,$chid)=@_;
  eval{
    my $info_res = $ua->get("https://www.nicovideo.jp/watch/".$video_id);
    my $info_json = scraper {
      process 'div#js-initial-watch-data', 'json' => '@data-api-data';
    }->scrape($info_res->content)->{json};
    if(! defined($info_json) || ! defined($info_res->content) || $info_json eq "" ){return;}
    #$info_json = unescape($info_json);
    $info = decode_json( $info_json );
  };
  if($@ || ! defined($info)){
    warn "GetInfo failed. Channel:$chid Id:$video_id\n";
    warn "ERROR: $@\n" if($@);
    return;
  }
  return $info;
}

sub GetHtml5VideoJson{
  my ($info,$ua) = @_;
  if(!defined($info->{video}->{dmcInfo}->{session_api})){return;}
  my $url=$info->{video}->{dmcInfo}->{session_api}->{urls}[0]->{url};
  my $dsr = GetDmcSessionRequest($info);
  my $res = $ua->post($url."?_format=json", Content => $dsr);
  my $json = decode_json($res->content);
  return ($json,$url);
}

sub EscapeJson{
  my ($data) = @_;
  if(! defined($data)){return "";}
  $data =~ s/\\/\\\\/g;
  $data =~ s/\"/\\\"/g;
  $data =~ s/\n/\\n/g;
  $data =~ s/\r/\\r/g;
  $data =~ s/\t/\\t/g;
  return $data;
}

sub GetDmcSessionRequest{
  my ($info) = @_;
  
  my $protocol_parameters;
  
  if(! defined($info->{video}->{dmcInfo}->{encryption})){
    $protocol_parameters=<<"EOF";
            "http_output_download_parameters": {
              "use_well_known_port": "@{[$info->{video}->{dmcInfo}->{session_api}->{urls}[0]->{is_well_known_port}==1?"yes":"no"]}",
              "use_ssl": "@{[$info->{video}->{dmcInfo}->{session_api}->{urls}[0]->{is_ssl}==1?"yes":"no"]}",
              "transfer_preset": ""
            }
EOF
  }else{
    my $json_in=encode_json($info->{video}->{dmcInfo}->{encryption});
    $protocol_parameters=<<"EOF";
            "hls_parameters": {
              "use_well_known_port": "@{[$info->{video}->{dmcInfo}->{session_api}->{urls}[0]->{is_well_known_port}==1?"yes":"no"]}",
              "use_ssl": "@{[$info->{video}->{dmcInfo}->{session_api}->{urls}[0]->{is_ssl}==1?"yes":"no"]}",
              "transfer_preset": "",
              "segment_duration": 5000,
              "encryption": ${json_in}
            }
EOF
  }
  
  return <<"EOF";
{
  "session": {
    "recipe_id": "@{[ EscapeJson($info->{video}->{dmcInfo}->{session_api}->{recipe_id}) ]}",
    "content_id": "@{[ EscapeJson($info->{video}->{dmcInfo}->{session_api}->{content_id}) ]}",
    "content_type": "movie",
    "content_src_id_sets": [
      {
        "content_src_ids": [
          {
            "src_id_to_mux": {
              "video_src_ids": [
                "@{[ 
join('", "',@{$info->{video}->{dmcInfo}->{session_api}->{videos}})
]}"
              ],
              "audio_src_ids": [
                "@{[
join('", "',@{$info->{video}->{dmcInfo}->{session_api}->{audios}})
]}"
              ]
            }
          }
        ]
      }
    ],
    "timing_constraint": "unlimited",
    "keep_method": {
      "heartbeat": {
        "lifetime": 120000
      }
    },
    "protocol": {
      "name": "http",
      "parameters": {
        "http_parameters": {
          "parameters": {
${protocol_parameters}
          }
        }
      }
    },
    "content_uri": "",
    "session_operation_auth": {
      "session_operation_auth_by_signature": {
        "token": "@{[ EscapeJson($info->{video}->{dmcInfo}->{session_api}->{token}) ]}",
        "signature": "@{[ EscapeJson($info->{video}->{dmcInfo}->{session_api}->{signature}) ]}"
      }
    },
    "content_auth": {
      "auth_type": "ht2",
      "content_key_timeout" : @{[ EscapeJson($info->{video}->{dmcInfo}->{session_api}->{content_key_timeout}) ]},
      "service_id": "nicovideo",
      "service_user_id": "@{[ EscapeJson($info->{video}->{dmcInfo}->{session_api}->{service_user_id}) ]}"
    },
    "client_info": {
      "player_id": "@{[ EscapeJson($info->{video}->{dmcInfo}->{session_api}->{player_id}) ]}"
    },
    "priority": @{[ EscapeJson($info->{video}->{dmcInfo}->{session_api}->{priority}) ]}
  }
}
EOF
}
