#!/bin/sh

cd /home/ubuntu/ishparser
/usr/bin/perl /home/ubuntu/ishparser/leaderboard.pl >> /home/ubuntu/ishparser/ishparser.log 2>&1
/usr/bin/perl /home/ubuntu/ishparser/addVORP.pl 1 >> /home/ubuntu/ishparser/ishparser.log 2>&1
/usr/bin/perl /home/ubuntu/ishparser/createuserpage.pl > /home/ubuntu/ishparser/website/userindex.html
/usr/bin/perl /home/ubuntu/ishparser/createposterall.pl >> /home/ubuntu/ishparser/ishparser.log 2>&1
/home/ubuntu/ishparser/ftpall.sh
