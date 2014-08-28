#!/usr/bin/perl

@cmd_w = `w`;
@cmd_df = `df -h`;
@cmd_mdstat = `cat /proc/mdstat`;

print << "_EOH_";
Content-Type: text/html

<html>
<body>

<b><big>w</big></b><br><br>
_EOH_

foreach $str(@cmd_w){
  print "$str";
  print "<br>\n";
}

print "<br><hr>\n";
print "<b><big>df</big></b><br><br>\n";

foreach $str(@cmd_df){
  print "$str";
  print "<br>\n";
}

print "<br><hr>\n";
print "<b><big>/proc/mdstat</big></b><br><br>\n";

foreach $str(@cmd_mdstat){
  print "$str";
  print "<br>\n";
}

print << "_EOH_";
</body>
</html>
_EOH_

