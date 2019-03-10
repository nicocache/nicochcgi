#!/usr/bin/perl
use Net::Netrc;
use LWP::UserAgent;
use URI::Escape;
use CGI;
use Web::Scraper;
use Unicode::Escape qw(escape unescape);
use JSON;

print <<"HEAD";
Content-type: application/xml
Access-Control-Allow-Origin: *

HEAD

my $mach = Net::Netrc->lookup('nicovideo');
my ($nicologin, $nicopassword, $nicoaccount) = $mach->lpa;

my $login_info = {
    mail_tel => $nicologin,
    password => $nicopassword,
};

my $q=new CGI;
my $movie_id=$q->param('id');

my $ua = LWP::UserAgent->new(cookie_jar => {});
$ua->post("https://secure.nicovideo.jp/secure/login?site=niconico", $login_info);

my $info_res = $ua->get("https://www.nicovideo.jp/watch/".$movie_id);
my $info_json = scraper {
  process 'div#js-initial-watch-data', 'json' => '@data-api-data'
}->scrape($info_res->content)->{json};
$info_json = unescape($info_json);
$info = decode_json( $info_json );

my $ms= $info->{thread}->{serverUrl};
#my $user_id= $info->{video}->{dmcInfo}->{user}->{user_id};
my $user_id= $info->{viewer}->{id};
my $length= $info->{video}->{duration};
my $threads = $info->{commentComposite}->{threads};

#use YAML;
#print Dump $info;

my $min=int($length/60)+1;
my $post_msg="<packet>\n";

foreach my $thread (@$threads){
  if($thread->{isActive} == 1){
    my $thread_id = $thread->{id};
    if($thread->{isThreadkeyRequired} == 1){
      my $thread_key_res=$ua->get("http://flapi.nicovideo.jp/api/getthreadkey?thread=".$thread->{id});

      my $thread_key = ParseUrl($thread_key_res->content,"threadkey");
      my $force_184 = ParseUrl($thread_key_res->content,"force_184");
      
      $post_msg.=<<"PACKET"
 <thread thread="$thread_id" version="20090904" threadkey="$thread_key" force_184="$force_184" user_id="$user_id" />
 <thread_leaves scores="1" thread="$thread_id" threadkey="$thread_key" force_184="$force_184" user_id="$user_id">0-$min:100,1000</thread_leaves>
PACKET
    }else{
      $post_msg.="<thread thread=\"$thread_id\" version=\"20061206\" res_from=\"-1000\" user_id=\"$user_id\" />\n";
    }
  }
}

$post_msg.="</thread>\n";

my $req=HTTP::Request->new(POST => $ms);
$req->content($post_msg);
print $ua->request($req)->content;

sub ParseUrl{
  my $text=$_[0];
  my $key=$_[1];
  my ($res) = $text=~ m/$key\=([^\&]+)/;
  return uri_unescape($res);
}
