#!/usr/bin/perl

@cmd_w = `w`;
@cmd_df = `df -h`;
@cmd_mdstat = `cat /proc/mdstat`;
@cmd_vmstat = `vmstat 1 1`;
@cmd_dstat = `dstat -cdnlms 1 1`;

print << "_EOH_";
Content-Type: text/html

<html>
<body>

<b><big>w</big></b><br><br>
_EOH_
print "<pre>\n";

foreach $str(@cmd_w){
  print "$str";
}

print "</pre>\n";
print "<br><hr>\n\n";

print "<b><big>df</big></b><br><br>\n";
print "<pre>\n";

foreach $str(@cmd_df){
  print "$str";
}

print "</pre>\n";
print "<br><hr>\n\n";

print "<b><big>/proc/mdstat</big></b><br><br>\n";
print "<pre>\n";

foreach $str(@cmd_mdstat){
  print "$str";
}

print "</pre>\n";
print "<br><hr>\n\n";

print "<b><big>vmstat</big></b><br><br>\n";
print "<pre>\n";

foreach $str(@cmd_vmstat){
  print "$str";
}

print "</pre>\n";
print "<br><hr>\n\n";

print "<b><big>dstat</big></b><br><br>\n";
print "<pre>\n";

foreach $str(@cmd_dstat){
  print "$str";
}

print "</pre>\n";
print << "_EOH_";
</body>
</html>
_EOH_

