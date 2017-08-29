#!/usr/bin/perl
use strict;
use File::Basename 'basename', 'dirname';
use File::Spec;
use CGI;

require File::Spec->catfile(dirname(__FILE__),"common.pl");

my $q = new CGI;

my $dbh=GetDatabaseHandle();

my $login=$q->param('name');
my $password=$q->param('password');

if(my $account=VerifyAccount($dbh,$login,$password)){
  my $redirect=$q->param('redirect');
  $redirect=~ s/(\d+)/$1/;
  my $redirectUrl="";
  if($redirect ne ""){
    $redirectUrl=GetRedirectUrl($dbh,$redirect);
  }elsif($ENV{'HTTP_REFERER'}){
    $redirectUrl=$ENV{'HTTP_REFERER'};
  }
  my $key= GetSessionKey($dbh);
  PushSession($dbh,$account->{"id"},$key);
  my $cookie = $q->cookie(-name    => "login_session",
                         -value   => "$key",
                         -expires => "+1y");

  print $q->header(-charset=>"utf-8", -cookie=>"$cookie");
  if($redirectUrl ne ""){
    print $q->start_html(-title=>"login",-head => $q->meta({-http_equiv => 'refresh', -content => '5; url='.$redirectUrl}));
  }else{
    print $q->start_html(-title=>"login");
  }
  print "<p>Login succeed!</p>";
  print $q->end_html;
}else{
  print $q->header(-charset=>"utf-8");
  print <<"EOF";
<html>
  <head>
    <title>login</title>
    <style>
span.head{
  width:150px;
  display:inline-block;
}
input[type=submit]{
  width:150px;
  height:20px;
}
    </style>
  </head>
  <body>
    <form action="login.cgi" method="post">
      <input type="hidden" name="redirect" value="@{[ $q->param('redirect') ]}"/>
      <p>
        <span class="head">ID</span>
        <input type="text" name="name" size="40"/>
      </p>
      <p>
        <span class="head">password</span>
        <input type="password" name="password" size="40"/>
      </p>
      <p>
        <input type="submit" value="submit">
      </p>
  </body>
</html>
EOF
}

