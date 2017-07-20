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

require File::Spec->catfile(dirname(__FILE__),"common.pl");

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

my $ua = LWP::UserAgent->new();
foreach my $url (@url) {
    my $video = scraper {
        process '.g-video-title .g-video-link', 'title' => 'TEXT', 'url[]' => '@href';
    }->scrape(URI->new($url));
    my $video2 = scraper {
        process '.thumb_video', 'title' => 'TEXT', 'url[]' => '@href';
    }->scrape(URI->new($url."/video"));

    foreach my $surl (@{$video->{url}},@{$video2->{url}}){
        my ($video_id) = $surl =~ m!/watch/(\w+)!;
        my $res = $ua->get("http://ext.nicovideo.jp/api/getthumbinfo/$video_id");
        my $ext = XMLin($res->content)->{thumb}{movie_type};
        my $title = XMLin($res->content)->{thumb}{title};
        my ($chid) = $url =~ m!/([^/]+?)$!;
        my $chdir=File::Spec->catfile($animedir , $chid );
        if(! -d $chdir){mkdir $chdir;}

        $title=~ s/\\\\:\,\l\*\?\"\<\>\|//g;

        my $fileold = File::Spec->catfile($chdir , "$video_id.$ext");
        my $file = File::Spec->catfile($chdir , "$video_id.$title.$ext");
        my $filetmp = File::Spec->catfile($chdir , "tmp.$ext");
        unlink $filetmp if -e $filetmp;
        next if -e $file;

        if(-e $fileold ) {
            rename $fileold,$file;
            next;
        }

        warn "download $file\n";
        open my $fh, '>', $filetmp or die $!;
        eval {
            $client->download($video_id, sub {
                my ($data, $res, $proto) = @_;
                print {$fh} $data;
	        });
          rename $filetmp,$file;
        };
        if ($@) {
          warn "ERROR: $@\n";
          unlink $filetmp;
          next;
        }
        sleep 5;
    }
}

