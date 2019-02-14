#!/usr/bin/perl
use CGI;

print <<"HEAD";
Content-type: text/html

HEAD

#http://jsfiddle.net/ginpei/kutUL/?utm_source=website&utm_medium=embed&utm_campaign=kutUL
print <<"EOF";
<html><head>
<title>Editor</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="viewport" content="width=device-width, user-scalable=yes,initial-scale=1.0" />
<style type="text/css">
html, body { height:100%; margin:0; }
.fix-height {
  box-sizing: border-box;
  height: 100%;
}
.fix-width {
  box-sizing: border-box;
  width: 100%;
}
.editor {
  box-sizing: border-box;
  height: 100%;
  padding-top: 30px;
}
.menubar {
  height: 30px;
  left: 0;
  position: absolute;
  top: 0;
}
.menubar input {
  height: 30px;
}
.main {
  height: 100%;
}
</style>
</head>
<body>
<div class="editor">
<form action="modify.cgi" method="post">
<div class="menubar">
<input type="submit" value="Save" />
<input type="reset" value="Reset" />
</div>
<div class="main">
<textarea name="a1" class="fix-height fix-width">
EOF

open FILEIN, "<", "chlist.txt" or die "error";
while(<FILEIN>){
print;
}
close(FILEIN);

print <<"EOF";
</textarea>
</div>
<input type="hidden" name="op" value="edit" />
</form></div></body>
</html>
EOF
