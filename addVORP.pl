#!/usr/bin/perl

use DBI;
use DateTime;
use Config::Simple;

$daysAgoToRun = shift;

if (!$daysAgoToRun) {
	$daysAgoToRun = 1;
}

my $todayDate = DateTime->now(time_zone=>'local');
$yesterdayDate = DateTime->now(time_zone=>'local')->subtract( days => $daysAgoToRun );
#my $yesterdayDate = DateTime->now(time_zone=>'local')->subtract( days => 1 );
my $todayDateString = $todayDate->ymd;
my $yesterdayDateString = $yesterdayDate->ymd;

my $runTimeString = $todayDate->hms;

print "[ADDVORP] Started at $runTimeString running for $yesterdayDateString, $daysAgoToRun days ago].\n";

$dateStringSQL = "AND post_time >= '$yesterdayDateString 00:00:00' AND post_time <= '$yesterdayDateString 23:59:59'";
$dateStringSQLSole = "post_time >= '$yesterdayDateString 00:00:00' AND post_time <= '$yesterdayDateString 23:59:59'";



my $angerdepth = 6;

my $thresholdThread = 11;

my @authorarray;

readDBconfig();

print "[ADDVORP] Executing distinct name query.\n";

my $dbh = DBI->connect("DBI:Pg:dbname=$dbName;host=$dbHost", "$dbUser", "$dbPassword", {'RaiseError' => 1});
my $usersQuery = $dbh->prepare("SELECT DISTINCT author FROM $dbTable ORDER BY author");
$usersQuery->execute();

print "[ADDVORP] Completed query.\n";

while (my $resultHash = $usersQuery->fetchrow_hashref()) {

	push (@authorarray, $resultHash->{'author'});
	#print "$resultHash->{'author'}";

}

#$dayTotalCount = $dbh->selectrow_array("SELECT count(*) FROM $dbTable WHERE $dateStringSQLSole", undef, @params);
$alldepthtotal = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE $dateStringSQLSole", undef, @params);

$dayTotalCount = 2200; 


foreach (@authorarray) {

	#print "$_";
	$author = $_;
	
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
			$threadStartedRepliesDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE author <> '$author' AND root_post_id = $threadStartedID $dateStringSQL", undef, @params);
			
						
			if ($threadStartedRepliesCount > 150) {
			
				#check for gamethread characteristics
				if (($threadStartedRepliesDepth / $threadStartedRepliesCount) < 3.5) {
					#probably a gamethread or other low content long thread
					$gamethread = 1;
				}
			}
			
			if ($threadStartedRepliesCount > 45) { $threadStartedRepliesCount = 45; }
			
			if (!$gamethread) {
				$threadStartedTotalReplies = $threadStartedTotalReplies + $threadStartedRepliesCount;
			} else {
				$threadStartedTotalReplies = $threadStartedTotalReplies + 15;
			}

			$gamethread = 0;
			
		}			
	
	
	if (!$depthtotal) { $depthtotal = 0; }
	
	if ($count) { 
		$depthavg = sprintf("%.3f", $depthtotal / $count);
	} else {
		$depthavg = 0;
	}
		
		
	#$insertSQL = "INSERT INTO $dbWriteTable (user_day, author, posts, replied_to, replied_to_subthread, replied_to_anger, total_depth, posts_anger, threads_started, threads_started_replies_total, depthavg) VALUES ('$yesterdayDateString', '$author', $count, $repliescount, $deeprepliescount, $angerrepliescount, $depthtotal, $angerpostscount, $threadstartcount, $threadStartedTotalReplies, $depthavg)";
	
	#$insertQuery = $dbh->prepare("$insertSQL");
	#$insertQuery->execute();
	
	
	#print "$insertSQL\n";
	#print "$author 1:$count 2:$repliescount 3:$deeprepliescount 4:$angerrepliescount 5:$depthtotal 6:$angerpostscount 7:$threadstartcount 8:$threadStartedTotalReplies 9: $depthavg\n";
	
	$postingComponent = sprintf("%.4f", 0.5 * ($count / $dayTotalCount) + 3 * ($deeprepliescount / $dayTotalCount));
	
	if (!$threadstartcount) { 
		$replyPerThread = $threadStartedTotalReplies / 1;
		} else {
			$replyPerThread = $threadStartedTotalReplies / $threadstartcount;
		}
	
	$pctRepliesGenerated = $threadStartedTotalReplies / $dayTotalCount;
	
	
	
	
	$postPar = $thresholdThread / $dayTotalCount;
	$minPar = $postPar * $threadstartcount;
	
	$startComponent = sprintf("%.4f", 0.9 * ($pctRepliesGenerated - $minPar));
	
	
	#$allaveragedepth = $alldepthtotal / $dayTotalCount;
	$allaveragedepth = 3.1;
	
	if ($allaveragedepth > $depthavg) {
			$allaveragedepth = $depthavg;
		}
	
	$depthdiff = sprintf("%.4f", $allaveragedepth - $depthavg);
	
	if ($count) {
		$angerquotient = $angerpostscount / $count;
	} else {
		$angerquotient = 0;
	}
	
	$angerComponent = sprintf("%.4f", 1.25 * (($count / $dayTotalCount) * ($depthdiff * $angerquotient)));
	
	
	$totalVORP = sprintf("%.4f", $postingComponent + $startComponent + $angerComponent);
	
	#if (!$threadstartcount) { $threadstartcount = 1; }
	#
	#$postsPerStartedThread = ($threadStartedTotalReplies / $threadstartcount);
	#
	#
	
	$checkSQL = $dbh->selectrow_array("SELECT author FROM $dbWriteTable WHERE author = '$author' AND user_day = '$yesterdayDateString'", undef, @params);
	
	#$writeCount = 0;
	
	if ($checkSQL) { 
	
		#print "NO RECORD "; 
		$writeQuery = $dbh->prepare("UPDATE $dbWriteTable SET postvorp = $postingComponent, startvorp = $startComponent, aggressionvorp = $angerComponent, totalvorp = $totalVORP WHERE author = '$author' AND user_day = '$yesterdayDateString'");
		$writeQuery->execute();
		#print "UPDATE usertotals SET postvorp = $postingComponent, startvorp = $startComponent, aggressionvorp = $angerComponent, totalvorp = $totalVORP WHERE author = '$author' AND user_day = '$yesterdayDateString'";
		#print "UPDATED $yesterdayDateString $author $postingComponent $startComponent $angerComponent [$totalVORP]\n";
		
		$writeCount++;
                #print "$writeCount.";
		
	}
	

}


print "[ADDVORP FINISHED] $writeCount records written\n";

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


