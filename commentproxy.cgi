#!/usr/bin/perl
#use Net::Netrc;
use LWP::UserAgent;
use URI::Escape;
use CGI;

print <<"HEAD";
Content-type: application/xml

HEAD

#my $mach = Net::Netrc->lookup('nicovideo');
#my ($nicologin, $nicopassword, $nicoaccount) = $mach->lpa;
my ($nicologin, $nicopassword, $nicoaccount) = ("","","");

my $login_info = {
    mail_tel => $nicologin,
    password => $nicopassword,
};

my $q=new CGI;
my $movie_id=$q->param('id');

my $ua = LWP::UserAgent->new(cookie_jar => {});
$ua->post("https://secure.nicovideo.jp/secure/login?site=niconico", $login_info);
my $getflv_res = $ua->get("http://flapi.nicovideo.jp/api/getflv/$movie_id");
my ($thread_id)= ParseUrl($getflv_res->content,"thread_id");
my $ms= ParseUrl( $getflv_res->content,"ms");
my $user_id= ParseUrl( $getflv_res->content,"user_id");
my $length= ParseUrl( $getflv_res->content,"l");

if($movie_id=~ /^\d+$/){
my $thread_key_res=$ua->get("http://flapi.nicovideo.jp/api/getthreadkey?thread=".$thread_id);
my $thread_key= ParseUrl($thread_key_res->content,"threadkey");
my $force_184= ParseUrl($thread_key_res->content,"force_184");

my $min=int($length/60)+1;

my $post_msg=<<"PACKET";
<packet>
 <thread thread="$thread_id" version="20090904" threadkey="$thread_key" force_184="$force_184" user_id="$user_id" />
 <thread_leaves scores="1" thread="$thread_id" threadkey="$thread_key" force_184="$force_184" user_id="$user_id">0-$min:100,1000</thread_leaves>
</packet>
PACKET

my $req=HTTP::Request->new(POST => $ms);
$req->content($post_msg);
print $ua->request($req)->content;
}else{
my $post_msg="<thread thread=\"$thread_id\" version=\"20061206\" res_from=\"-1000\" user_id=\"$user_id\" />";
my $req=HTTP::Request->new(POST => $ms);
$req->content($post_msg);
print $ua->request($req)->content;
}

sub ParseUrl{
my $text=$_[0];
my $key=$_[1];
my ($res) = $text=~ m/$key\=([^\&]+)/;
return uri_unescape($res);
}
