#!/usr/bin/perl

use DBI;
use DateTime;
use Config::Simple;

my $todayDate = DateTime->now(time_zone=>'local');
my $yesterdayDate = DateTime->now(time_zone=>'local')->subtract( days => 1 );
my $todayDateString = $todayDate->ymd;
my $yesterdayDateString = $yesterdayDate->ymd;

my $runTimeString = $todayDate->hms;

$dateStringSQL = "AND post_time >= '$yesterdayDateString 00:00:00' AND post_time <= '$yesterdayDateString 23:59:59'";


my $angerdepth = 6;

my @authorarray;

readDBconfig();

my $dbh = DBI->connect("DBI:Pg:dbname=$dbName;host=$dbHost", "$dbUser", "$dbPassword", {'RaiseError' => 1});
my $usersQuery = $dbh->prepare("SELECT DISTINCT author FROM $dbTable ORDER BY author");
$usersQuery->execute();

while (my $resultHash = $usersQuery->fetchrow_hashref()) {

	push (@authorarray, $resultHash->{'author'});

}

foreach (@authorarray) {


	$author = $_;
	#$author=~ s/\'//g;

	$count = $dbh->selectrow_array("SELECT count(*) FROM $dbTable WHERE author = '$author' $dateStringSQL", undef, @params);
	
	$depthtotal = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE author = '$author' $dateStringSQL", undef, @params);
	#$depthavg = sprintf("%.3f", $depthavg);
	
	$repliescount = $dbh->selectrow_array("SELECT count(*) FROM $dbTable WHERE reply_to_author = '$author' $dateStringSQL", undef, @params);
	
	$deeprepliescount = $dbh->selectrow_array("SELECT count(*) FROM $dbTable WHERE reply_to_author = '$author' AND post_depth > 1 $dateStringSQL", undef, @params);
	
	$threadstartcount = $dbh->selectrow_array("SELECT count(*) FROM $dbTable WHERE root_post_id = 0 AND author = '$author' $dateStringSQL", undef, @params);
	
	$angerpostscount = $dbh->selectrow_array("SELECT count(*) FROM $dbTable WHERE author = '$author' AND post_depth > $angerdepth $dateStringSQL", undef, @params);
	
	$angerrepliescount = $dbh->selectrow_array("SELECT count(*) FROM $dbTable WHERE reply_to_author = '$author' AND post_depth > $angerdepth $dateStringSQL", undef, @params);
	
	$threadStartedTotalReplies = 0;
	$threadNoReplies = 0;
	
	
	
		$threadsQuery = $dbh->prepare("SELECT * FROM $dbTable WHERE root_post_id = 0 AND author = '$author'");
		$threadsQuery->execute();
		
		
		while (my $threadsHash = $threadsQuery->fetchrow_hashref()) {

			$threadStartedID = $threadsHash->{'post_id'};
			$threadStartedRepliesCount = $dbh->selectrow_array("SELECT count(*) FROM $dbTable WHERE author <> '$author' AND root_post_id = $threadStartedID $dateStringSQL", undef, @params);
			
			$threadStartedTotalReplies = $threadStartedTotalReplies + $threadStartedRepliesCount;
			

		}				
	
	
	if (!$depthtotal) { $depthtotal = 0; }
	
	if ($count) { 
		$depthavg = sprintf("%.3f", $depthtotal / $count);
	} else {
		$depthavg = 0;
	}
		
		
	$insertSQL = "INSERT INTO $dbWriteTable (user_day, author, posts, replied_to, replied_to_subthread, replied_to_anger, total_depth, posts_anger, threads_started, threads_started_replies_total, depthavg) VALUES ('$yesterdayDateString', '$author', $count, $repliescount, $deeprepliescount, $angerrepliescount, $depthtotal, $angerpostscount, $threadstartcount, $threadStartedTotalReplies, $depthavg)";
	
	$insertQuery = $dbh->prepare("$insertSQL");
	$insertQuery->execute();
	
	
	#print "$insertSQL\n";
	#print "$author 1:$count 2:$repliescount 3:$deeprepliescount 4:$angerrepliescount 5:$depthtotal 6:$angerpostscount 7:$threadstartcount 8:$threadStartedTotalReplies 9: $depthavg\n";
	
	

}

sub readDBconfig {

	$dbConfig = new Config::Simple();
	$dbConfig->read('database.conf');

	$dbHost = $dbConfig->param("dbhost");
	$dbName = $dbConfig->param("dbname");
	$dbTable = $dbConfig->param("dbtable");
	$dbUser = $dbConfig->param("dbuser");
	$dbPassword = $dbConfig->param("dbpasswd");
	$dbWriteTable = $dbConfig->param("dbusertable");

}
