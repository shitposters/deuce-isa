#!/bin/sh
HOST='shitposters.org'
USER='transfer@shitposters.org'
PASSWD='xxx'
FILE='*.html'

ftp -n -i $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
passive
lcd /home/ubuntu/ishparser/website/
mput $FILE
quit
END_SCRIPT
exit 0
