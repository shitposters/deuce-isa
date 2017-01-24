#!/usr/bin/perl

use LWP::UserAgent;
use HTTP::Request::Common qw(GET);
use HTTP::Cookies;
use HTML::Strip;
use DBI;
use DateTime;
use Config::Simple;


my $todayDate = DateTime->now(time_zone=>'local');
my $yesterdayDate = DateTime->now(time_zone=>'local')->subtract( days => 1 );
my $todayDateString = $todayDate->ymd;
my $yesterdayDateString = $yesterdayDate->ymd;

my $runTimeString = $todayDate->hms;

readDBconfig();

#find newest post value so only the ones larger than that will be inserted

#print "Connecting to database.\n";

my $dbh = DBI->connect("DBI:Pg:dbname=$dbName;host=$dbHost", "$dbUser", "$dbPassword", {'RaiseError' => 1});
my $lastQuery = $dbh->prepare("SELECT * FROM $dbTable ORDER BY post_id DESC LIMIT 1");
$lastQuery->execute();
my $resultHash = $lastQuery->fetchrow_hashref();
my $lastwritten = $resultHash->{'post_id'};

print "$todayDateString $runTimeString: Last post in database is $lastwritten. Retrieving newer.\n";

#$lastwritten = 1423800437; 

my $ua = LWP::UserAgent->new;


    # Define user agent type
    $ua->agent('Mozilla/8.0');

    # Cookies
    $ua->cookie_jar(
        HTTP::Cookies->new(
            file => 'mycookies.txt',
            autosave => 1
        )
);

 # Request object
my $req = GET 'http://members.boardhost.com/onedeuce/';

# Make the request
my $res = $ua->request($req);	

 if ($res->is_success) {
 
$contentstring = $res->content;
@parsedfile = split/\n/, $contentstring;
#print $contentstring;
        #print $res->content;
    } else {
        print $res->status_line . "\n";
    }



$counter = 0;
$inthread = 0;
$msgdepth = 0;

foreach my $line (@parsedfile) {

#	if ($line =~ /onClick=\"expcl\(\'/) {
	if ($line =~ /collapsed\.gif/ || $line =~ /expanded\.gif/) {
	
		$username = $line=~ /<b>\s*(.*?)\s*</;
		$threadstarter = $1;
		
		$threadid = $line=~ /name="t_\s*(.*?)\s*"/;
		$currentparent = $1;
		
		$posttimestamp = $line=~ /<i>\s*(.*?)\s*</;
		$posttime = $1;
		
		#harvest and convert time to database timestamp
		
		@timearray = split(/,/, $posttime);
		$posttime = $timearray[1];
		$posttime =~ s/^\s+//;
		
		if ($timearray[0] eq "Today") {
			$posttime = $todayDateString . " " . $posttime;
		}
		
		if ($timearray[0] eq "Yesterday") {
			$posttime = $yesterdayDateString . " " . $posttime;
		}
		
		
		$clean_text = $line=~ /,false,true\)">\s*(.*?)\s*<\/a>/;
		$clean_text = $1;
		$clean_text=~ s/\'/\'\'/g;
		
		$inthread = 1;
		$msgdepth = 0;
		
		@parentarray = ();
		@authorarray = ();
		
		push @parentarray, $currentparent;
		push @authorarray, $threadstarter;
		
		if ($currentparent > $lastwritten) {
			
			# insert record into database
			$threadstarter=~ s/\'//g;
			my $insertString = "INSERT INTO $dbTable (post_id, post_time, root_post_id, reply_to_id, post_depth, author, reply_to_author, title) VALUES ($currentparent, '$posttime', 0, 0, $msgdepth, '$threadstarter', NULL, '$clean_text')";
			
			#print $insertString . "\n";
			
			my $dbInsert = $dbh->prepare("$insertString");
			
			local $dbh->{RaiseError} = 0;
			
			$dbInsert->execute();
			$counter++;
			
			
		}
		
	}	
	
	if ($line =~ /^<li>/) {
	
		$msgusername = $line=~ /<b>\s*(.*?)\s*</;
		$msguser = $1;
		
		$msgid = $line=~ /href="msg\/\s*(.*?)\s*.html"/;
		$currentmsg = $1;
		
		$msgtimestamp = $line=~ /<i>\s*(.*?)\s*</;
		$msgtime = $1;
		
		@msgtimearray = split(/,/, $msgtime);
		$msgtime = $msgtimearray[1];
		$msgtime =~ s/^\s+//;
		
		if ($msgtimearray[0] eq "Today") {
			$msgtime = $todayDateString . " " . $msgtime;
		}
		
		if ($msgtimearray[0] eq "Yesterday") {
			$msgtime = $yesterdayDateString . " " . $msgtime;
		}
		
		$clean_text = $line=~ /.html">\s*(.*?)\s*<\/a>/;
		$clean_text = $1;
		$clean_text=~ s/\'/\'\'/g;
		
		$authorarray[$msgdepth] = $msguser;
		$previousauthor = $authorarray[$msgdepth - 1];
		
		
		$parentarray[$msgdepth] = $currentmsg;
		$previousid = $parentarray[$msgdepth - 1];
		
		if ($currentmsg > $lastwritten) {
		
			$msguser=~ s/\'//g;
			$previousauthor=~ s/\'//g;
		
			my $insertString = "INSERT INTO $dbTable (post_id, post_time, root_post_id, reply_to_id, post_depth, author, reply_to_author, title) VALUES ($currentmsg, '$msgtime', $currentparent, $previousid, $msgdepth, '$msguser', '$previousauthor', '$clean_text')";
			
			#print $insertString . "\n";
			
			my $dbInsert = $dbh->prepare("$insertString");
			
			local $dbh->{RaiseError} = 0;
			
			$dbInsert->execute();
			#print "$currentparent $msgdepth $msguser $currentmsg $msgtime $clean_text TO $previousparent IN $previousid\n";
			$counter++;
		}
	}		

	if ($line =~ /<ul/) {
		$msgdepth++;
	}

	if ($line =~ /^<\/ul>/) {
		$msgdepth--;
	}

	

}

print "$todayDateString $runTimeString: Completed. $counter inserts performed in database.\n";

sub readDBconfig {

	$dbConfig = new Config::Simple();
	$dbConfig->read('database.conf');

	$dbHost = $dbConfig->param("dbhost");
	$dbName = $dbConfig->param("dbname");
	$dbTable = $dbConfig->param("dbtable");
	$dbUser = $dbConfig->param("dbuser");
	$dbPassword = $dbConfig->param("dbpasswd");

}
