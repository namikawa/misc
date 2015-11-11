#!/usr/bin/suidperl

undef($ENV{'PATH'});
system('/bin/sync');
system('/sbin/shutdown -h now');

print << '_EOH_';
Content-Type: text/html

<html>
<body>
<p>Shutdown OK</p>
</body>
</html>
_EOH_

