#!/bin/sh

cd /home/ubuntu/ishparser
/usr/bin/perl /home/ubuntu/ishparser/createpage.pl > /home/ubuntu/ishparser/website/index.html
/home/ubuntu/ishparser/ftpindex.sh
