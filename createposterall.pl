#!/usr/bin/perl

use DBI;
use DateTime;
use Config::Simple;
use IO::Handle;

STDOUT->autoflush(1);

my $todayDate = DateTime->now(time_zone=>'local');
my $yesterdayDate = DateTime->now(time_zone=>'local')->subtract( days => 1 );
my $sixtyDate = DateTime->now(time_zone=>'local')->subtract( days => 60 );
my $sevenDate = DateTime->now(time_zone=>'local')->subtract( days => 7 );
my $todayDateString = $todayDate->ymd;
my $yesterdayDateString = $yesterdayDate->ymd;
my $sixtyDateString = $sixtyDate->ymd;
my $sevenDateString = $sevenDate->ymd;

my $runTimeString = $todayDate->hms;

my $currentHour = $todayDate->hour;

$sixtySQL = "post_time >= '$sixtyDateString 00:00:00'";
$sevenSQL = "post_time >= '$sevenDateString 00:00:00'";

if ($currentHour > 0) { 
	$lastHour = $currentHour - 1;
	$dateStringSQL = "post_time >= '$todayDateString $lastHour:00:00' AND post_time <= '$todayDateString $lastHour:59:59'";
	$hourTextString = "$lastHour:00 and $currentHour:00";
} else {
	$dateStringSQL = "post_time >= '$yesterdayDateString 23:00:00' AND post_time <= '$yesterdayDateString 23:59:59'";
	$hourTextString = "23:00 and 00:00";
	}
	
	

$depthFactor = 500;
$singleDepthFactor = 75;


my $angerdepth = 6;

my @authorarray;

readDBconfig();

my $dbh = DBI->connect("DBI:Pg:dbname=$dbName;host=$dbHost", "$dbUser", "$dbPassword", {'RaiseError' => 1});



$alltimeCount = $dbh->selectrow_array("SELECT COUNT(*) FROM $dbTable", undef, @params);
$alltimeDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable", undef, @params);

$hourCount = $dbh->selectrow_array("SELECT COUNT(*) FROM $dbTable WHERE $dateStringSQL", undef, @params);
$hourDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE $dateStringSQL", undef, @params);
$dayDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00'", undef, @params);
$dayCount = $dbh->selectrow_array("SELECT COUNT(*) FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00'", undef, @params);


$userCount = $dbh->selectrow_array("SELECT COUNT(DISTINCT author) from usertotals", undef, @params);


my $usersQuery = $dbh->prepare("SELECT DISTINCT author FROM $dbUsersTable ORDER BY author");
$usersQuery->execute();

while (my $resultHash = $usersQuery->fetchrow_hashref()) {

	push (@authorarray, $resultHash->{'author'});

}

my $buyoutTotal;

print "Processing authors: ";

foreach (@authorarray) {

	$generateAuthor = $_;

	$writePath = "./website/$generateAuthor.html";
	
	open FILE, ">$writePath"; 
	
	print "[$generateAuthor] ";
	
	my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable WHERE author = '$generateAuthor' ORDER BY RANDOM() LIMIT 1");
	$randomQuery->execute();

	$resultHash = $randomQuery->fetchrow_hashref();

	$hourQuote = "\"" . $resultHash->{'title'} . "\"";
	
	#$buyoutQuery = $dbh->prepare("SELECT * FROM $dbTable WHERE reply_to_author = '$generateAuthor' AND author <> '$generateAuthor' AND title like 'shitbot buyout \%' AND $sixtySQL");
	#$buyoutQuery->execute();
	
	
	
# 	$buyoutTotal = 0;
# 	
# 	my $donorHash = {};
# 	
# 	while (my $buyoutHash = $buyoutQuery->fetchrow_hashref()) {
# 	
# 		$buyoutDonor = $buyoutHash->{'author'};
# 		$buyoutString = $buyoutHash->{'title'};
# 		
# 		@splitBuyout = split(/ /, $buyoutString);
# 		$buyoutVal = $splitBuyout[2];
# 		
# 		if($buyoutVal =~/([0-9.]+)/) 
# 		{ 
# 			
# 			$buyoutTotal = $buyoutTotal + $1;
# 			
# 			$oldTotal = $donorHash{$buyoutDonor};
# 			
# 			$donorHash{$buyoutDonor} = $oldTotal + $1;
# 			#print "$buyoutDonor $1 balls! \n";
# 		} 
# 	
# 	}
# 	
# 	$buyoutAnon = $dbh->selectrow_array("SELECT sum(amount) from buyouts WHERE target='$generateAuthor' AND $sevenSQL", undef, @params);
# 	
# 	
# 	
# 	$buyoutTotal = $buyoutTotal + $buyoutAnon;
	
	#print "$generateAuthor anon: $buyoutAnon total: $buyoutTotal\n";
	
	printHeader();

	# rank section
	#SELECT rank from (SELECT author, sum(totalvorp) as tvorp, rank() OVER (order by sum(totalvorp) DESC) from usertotals group by author ) as poop WHERE author='$generateAuthor'
	#SELECT rank from (SELECT author, sum(posts) as pst, rank() OVER (order by sum(posts) DESC) from usertotals group by author ) as poop WHERE author='$generateAuthor'
	#SELECT rank from (SELECT author, sum(aggressionvorp) as avorp, rank() OVER (order by sum(aggressionvorp)) from usertotals group by author ) as poop WHERE author='$generateAuthor'
	
	$rankVORP = $dbh->selectrow_array("SELECT rank from (SELECT author, sum(totalvorp) as tvorp, rank() OVER (order by sum(totalvorp) DESC) from usertotals group by author ) as poop WHERE author='$generateAuthor'", undef, @params);
	$rankPost = $dbh->selectrow_array("SELECT rank from (SELECT author, sum(posts) as pst, rank() OVER (order by sum(posts) DESC) from usertotals group by author ) as poop WHERE author='$generateAuthor'", undef, @params);
	$rankAggression = $dbh->selectrow_array("SELECT rank from (SELECT author, sum(aggressionvorp) / sum(posts) as avorp, rank() OVER (order by sum(aggressionvorp) / sum(posts)) from usertotals group by author having sum(posts) > 1000) as poop WHERE author='$generateAuthor'", undef, @params);
	$rankEff = $dbh->selectrow_array("SELECT rank from (SELECT author, sum(totalvorp) / SUM(posts), rank() OVER (order by sum(totalvorp) / SUM(posts) DESC) from usertotals group by author HAVING SUM(posts) > 250) as ss WHERE author='$generateAuthor'", undef, @params);
	$allTimePosts = $dbh->selectrow_array("SELECT sum(posts) from usertotals WHERE author='$generateAuthor'", undef, @params);
	$allTimeVORP = $dbh->selectrow_array("SELECT sum(totalvorp) from usertotals WHERE author='$generateAuthor'", undef, @params);
	$allTimeAgg = $dbh->selectrow_array("SELECT sum(aggressionvorp) from usertotals WHERE author='$generateAuthor'", undef, @params);
	
	$allTimeVORP = sprintf("%.2f", $allTimeVORP);
	$allTimeAgg = sprintf("%.2f", $allTimeAgg);


	$lastdate = $dbh->selectrow_array("SELECT user_day FROM usertotals WHERE author = '$generateAuthor' and posts > 0 ORDER BY user_day DESC LIMIT 1", undef, @params);

	# update lastpost table
	
	$checkexists = $dbh->selectrow_array("SELECT post_total FROM lastpost WHERE author = '$generateAuthor'", undef, @params);

	if ($checkexists) {
	
		my $lastpostupdate = $dbh->prepare("UPDATE lastpost SET last_date = '$lastdate', post_total = $allTimePosts WHERE author = '$generateAuthor'");
		$lastpostupdate->execute();
	}
	else {
	
		my $lastpostinsert = $dbh->prepare("INSERT INTO lastpost (author, last_date, post_total) VALUES ('$generateAuthor', '$lastdate', $allTimePosts)");
		$lastpostinsert->execute();
	}


	# end update lastpost table

	
	print FILE "<section id=\"rank\">\n";
	print FILE "        <div class=\"container\">\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h3>$hourQuote</h3>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE " <h1>$generateAuthor</h1>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
	print FILE "</div>\n";

    print FILE "            <div class=\"row text-center\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "                 <div id=\"postvsvorp\"></div>\n";
	print FILE "               </div>\n";
	#print FILE "                <div class=\"col-md-6 text-center\">\n";
	#print FILE "                 <div id=\"postvsvorp2\"></div>\n";
	#print FILE "               </div>\n";
	print FILE "           </div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
	print FILE "</div>\n";

	print FILE " <div class=\"row text-center\">\n";
	print FILE "                <div class=\"col-md-4\">\n";
	print FILE "                    <span class=\"fa-stack fa-4x\">\n";
	print FILE "                        <i class=\"fa fa-circle fa-stack-2x text-primary\"></i>\n";
	print FILE "                        <i class=\"fa fa-stack-1x fa-inverse\">$rankVORP</i>\n";
	print FILE "                    </span>\n";
	print FILE "<h4 class=\"service-heading\">$rankVORP in total VORP.</h4>\n";

	print FILE "<p class=\"text-muted\">Contributions by $generateAuthor have accounted for a total VORP of $allTimeVORP which is good for $rankVORP out of $userCount users who have authored at least one post.</p>\n";
	print FILE "</div>\n";

	print FILE " <div class=\"col-md-4\">\n";
	print FILE "                    <span class=\"fa-stack fa-4x\">\n";
	print FILE "                        <i class=\"fa fa-circle fa-stack-2x text-primary\"></i>\n";
	print FILE "                        <i class=\"fa fa-stack-1x fa-inverse\">$rankPost</i>\n";                       
	print FILE "                    </span>\n";
	print FILE "<h4 class=\"service-heading\">$rankPost in total posts.</h4>\n";

	print FILE "<p class=\"text-muted\">Since the dawn of Our Shitlord through yesterday, $generateAuthor has made $allTimePosts total posts on the ish. Almost all of them probably sucked.</p>\n";

	print FILE "</div>\n";

	if ($rankEff) {
		print FILE " <div class=\"col-md-4\">\n";
		print FILE "                    <span class=\"fa-stack fa-4x\">\n";
		print FILE "                        <i class=\"fa fa-circle fa-stack-2x text-primary\" $iconStyle></i>\n";
		print FILE "                        <i class=\"fa fa-stack-1x fa-inverse\">$rankEff</i>\n";                       
		print FILE "                    </span>\n";
		print FILE "<h4 class=\"service-heading\">$rankEff in efficiency.</h4>\n";
		print FILE "<p class=\"text-muted\">Finally, $generateAuthor ranks number $rankEff in overall efficiency of their posting habits among those with 250 posts or more. This is a value of the average conversation generated by each post.</p>";
		} else {
		
		print FILE " <div class=\"col-md-4\">\n";
		print FILE "                    <span class=\"fa-stack fa-4x\">\n";
		print FILE "                        <i class=\"fa fa-circle fa-stack-2x text-primary\" $iconStyle></i>\n";
		print FILE "                        <i class=\"fa fa-stack-1x fa-inverse\">NA</i>\n";                       
		print FILE "                    </span>\n";
		print FILE "<h4 class=\"service-heading\">N/A in efficiency.</h4>\n";
		print FILE "<p class=\"text-muted\">It looks like $generateAuthor hasn't hit the 250 post threshold yet, so the efficiency rating is pretty much meaningless and isn't shown. He or she should totally post more, unless they suck cocks at posting that is.</p>";		
		
	}

	print FILE "</div>\n";
	print FILE "            </div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h3> </h3>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h3> </h3>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";
	
	print FILE "        </div>\n";
	print FILE "</section>\n";
	
	
	
	# end rank section
	
	my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable WHERE author = '$generateAuthor' ORDER BY RANDOM() LIMIT 1");
	$randomQuery->execute();

	$resultHash = $randomQuery->fetchrow_hashref();

	$hourQuote = "\"" . $resultHash->{'title'} . "\"";
	
	print FILE "<section id=\"graphs\">\n";
	print FILE "        <div class=\"container\">\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
	print FILE "<div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h2></h2>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h3></h3>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";

	print FILE "            <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "                 <h2>Shitposting in Dots and Lines</h2>\n";
	print FILE "<h3>$hourQuote</h3>\n";
	print FILE "<h2> </h2>\n";

	print FILE " <div class=\"panel panel-default\">\n";
	print FILE "   <div class=\"panel-body\">\n";
	print FILE "<h4>$generateAuthor\'s Posts by Day</h4>\n";
	print FILE "</div>\n";
	print FILE "            </div>\n";		
	
	
	print FILE "                 <div id=\"allday\" style=\"height: 500px;\"></div>\n";
	print FILE "               </div>\n";
	print FILE "           </div>\n";
	
	print FILE "            <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	
	print FILE "<h2> </h2>\n";
	print FILE "<h2> &nbsp</h2>\n";
	
	print FILE " <div class=\"panel panel-default\">\n";
	print FILE "   <div class=\"panel-body\">\n";
	print FILE "<h4>Activity by Hour and Day for $generateAuthor</h4>\n";
	print FILE "</div>\n";
	
	print FILE "            </div>\n";	
	print FILE "                 <div id=\"weeklyheatmap\" style=\"height: 500px;\"></div>\n";
	print FILE "               </div>\n";
	print FILE "           </div>\n";
	
	
	print FILE "            <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	
	print FILE "<h2> </h2>\n";
	print FILE "<h2> &nbsp</h2>\n";
	
	print FILE " <div class=\"panel panel-default\">\n";
	print FILE "   <div class=\"panel-body\">\n";
	print FILE "<h4>Aggression Rate for $generateAuthor vs All Posters</h4>\n";
	print FILE "</div>\n";
	
	print FILE "            </div>\n";	
	print FILE "                 <div id=\"postvsagg\" style=\"height: 500px;\"></div>\n";
	print FILE "               </div>\n";
	print FILE "           </div>\n";
	
	

	print FILE "        </div>\n";
	print FILE "    </section>\n";
	
	
	#begin printing summary section
	
	
	my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable WHERE author = '$generateAuthor' ORDER BY RANDOM() LIMIT 1");
	$randomQuery->execute();

	$resultHash = $randomQuery->fetchrow_hashref();

	$hourQuote = "\"" . $resultHash->{'title'} . "\"";

	print FILE "<section id=\"30days\">\n";
	print FILE "        <div class=\"container\">\n";
	
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
	print FILE "<div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h2></h2>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h3></h3>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";
	

	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "                    <h2>A Month in the Life of $generateAuthor</h2>\n";
	print FILE "<h3>$hourQuote</h3>\n";
	print FILE "<h2> &nbsp</h2>\n";
	
	print FILE "<table class=\" table table-striped table-hover\">\n";
	
	print FILE "  <thead>";
	print FILE "   <tr class=\"text-left\">";
	print FILE "      <th>Date</th>";
	print FILE "      <th>Posts</th>";
	print FILE "      <th>Times Replied To</th>";
	print FILE "      <th>Subthread Replies</th>";
	print FILE "      <th>Threads Started</th>";
	print FILE "      <th>Posting VORP</th>";
	print FILE "      <th>Starting VORP</th>";
	print FILE "      <th>Aggression VORP</th>";
	print FILE "      <th>Total VORP</th>";
	print FILE "      <th>Efficiency</th>";
	print FILE "    </tr>";
	print FILE "  </thead>";
	print FILE "  <tbody>";	
	
	
	$leaderboardAllTimeSQL = "SELECT * FROM $dbUsersTable WHERE author = '$generateAuthor' ORDER BY user_day DESC LIMIT 30";
	$leaderboardAllTimeQuery = $dbh->prepare($leaderboardAllTimeSQL);
	$leaderboardAllTimeQuery->execute();

	$rankcounter = 1;

	while (my $leaderboardAllTimeHash = $leaderboardAllTimeQuery->fetchrow_hashref()) {
		
		
		if ($leaderboardAllTimeHash->{'posts'} > 9) {
			$eff = sprintf("%.5f", $leaderboardAllTimeHash->{'totalvorp'} / $leaderboardAllTimeHash->{'posts'});
			} else {
				$eff = "N/A";
				}
			
		
		print FILE "                    <tr class=\"text-left\">\n";
		print FILE "                          <td>$leaderboardAllTimeHash->{'user_day'}</td><td>$leaderboardAllTimeHash->{'posts'}</td><td>$leaderboardAllTimeHash->{'replied_to'}</td><td>$leaderboardAllTimeHash->{'replied_to_subthread'}</td><td>$leaderboardAllTimeHash->{'threads_started'}</td><td>$leaderboardAllTimeHash->{'postvorp'}</td><td>$leaderboardAllTimeHash->{'startvorp'}</td><td>$leaderboardAllTimeHash->{'aggressionvorp'}</td><td>$leaderboardAllTimeHash->{'totalvorp'}</td><td>$eff</td>\n";
		print FILE "                    </tr>\n";
		
		$rankcounter++;
	}

	print FILE "</tbody>\n";
	print FILE "</table>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";


	print FILE "            </div>\n";
	print FILE "        </div>\n";
	print FILE "</section>\n";
		




	#start of love and hate
	
	my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable WHERE author = '$generateAuthor' ORDER BY RANDOM() LIMIT 1");
	$randomQuery->execute();

	$resultHash = $randomQuery->fetchrow_hashref();

	$hourQuote = "\"" . $resultHash->{'title'} . "\"";

	print FILE "<section id=\"lovehate\">\n";
	print FILE "        <div class=\"container\">\n";

	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
	print FILE "<div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h2></h2>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";
	print FILE "          <div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<h3></h3>\n";
	print FILE "</div>\n";
	print FILE "</div>\n";

	print FILE "			<div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";

	print FILE "                    <h2>Lovers and Haters</h2>\n";
	print FILE "<h3>$hourQuote</h3>\n";
	print FILE "<p><h2>&nbsp</h2>\n";
	print FILE "                </div>\n";
	print FILE "            </div>\n";
	
	

	print FILE "            <div class=\"row\">\n";
	print FILE "                <div class=\"col-md-6 text-center\">\n";
	
	print FILE " <div class=\"panel panel-default\">\n";
	print FILE "   <div class=\"panel-body\">\n";
	print FILE "<h4>Who $generateAuthor Replies To</h4>\n";
	print FILE "</div>\n";
	print FILE "            </div>\n";


	print FILE "<table class=\" table table-striped table-hover\">\n";
	print FILE "  <thead>";
	print FILE "   <tr class=\"text-left\">";
	print FILE "      <th>Rank</th>";
	print FILE "      <th>Poster</th>";
	print FILE "      <th>Replies</th>";
	print FILE "    </tr>";
	print FILE "  </thead>";
	print FILE "  <tbody>";

	
	
	$leaderboardAllTimeSQL = "SELECT reply_to_author, sum(post_depth) / count(*) as angry, Count(*) as replies FROM ishdata WHERE author = '$generateAuthor' AND root_post_id not in (select post_id from gamethreads) GROUP BY reply_to_author HAVING reply_to_author <> '' ORDER BY Count(*) DESC LIMIT 20";
	$leaderboardAllTimeQuery = $dbh->prepare($leaderboardAllTimeSQL);
	$leaderboardAllTimeQuery->execute();

	$rankcounter = 1;

	while (my $leaderboardAllTimeHash = $leaderboardAllTimeQuery->fetchrow_hashref()) {
	
	
		$rowHighlight = 'text-left';
			
			if ($leaderboardAllTimeHash->{'angry'} > 5) {
				$rowHighlight = "text-left warning";
			}
	
			if ($leaderboardAllTimeHash->{'angry'} > 7) {
				$rowHighlight = "text-left danger";
			}
		

		
		print FILE "                    <tr class=\"$rowHighlight\">\n";
		print FILE "                          <td>$rankcounter</td><td><a href=\"./$leaderboardAllTimeHash->{'reply_to_author'}.html\">$leaderboardAllTimeHash->{'reply_to_author'}</a></td><td>$leaderboardAllTimeHash->{'replies'}</td>\n";
		print FILE "                    </tr>\n";
		
		$rankcounter++;
	}

	print FILE "</tbody>";
	print FILE "</table>\n";

	print FILE "</div>\n";
	print FILE "<div class=\"col-md-6 text-center\">\n";

	print FILE " <div class=\"panel panel-default\">\n";
	print FILE "   <div class=\"panel-body\">\n";
	print FILE "<h4>Who  Replies To $generateAuthor</h4>\n";
	print FILE "</div>\n";
	print FILE "            </div>\n";

	print FILE "<table class=\" table table-striped table-hover\">\n";
	print FILE "  <thead>";
	print FILE "   <tr class=\"text-left\">";
	print FILE "      <th>Rank</th>";
	print FILE "      <th>Poster</th>";
	print FILE "      <th>Replies</th>";
	print FILE "    </tr>";
	print FILE "  </thead>";
	print FILE "  <tbody>";
	$leaderboardAllTimeSQL = "SELECT  author, sum(post_depth) / count(*) as angry, Count(*) as replies FROM ishdata WHERE reply_to_author = '$generateAuthor' AND root_post_id not in (select post_id from gamethreads) GROUP BY author ORDER BY Count(*) DESC LIMIT 20";
	$leaderboardAllTimeQuery = $dbh->prepare($leaderboardAllTimeSQL);
	$leaderboardAllTimeQuery->execute();

	$rankcounter = 1;

	while (my $leaderboardAllTimeHash = $leaderboardAllTimeQuery->fetchrow_hashref()) {
	
		$rowHighlight = 'text-left';
			
			if ($leaderboardAllTimeHash->{'angry'} > 5) {
				$rowHighlight = "text-left warning";
			}
	
			if ($leaderboardAllTimeHash->{'angry'} > 7) {
				$rowHighlight = "text-left danger";
			}
		
		print FILE "                    <tr class=\"$rowHighlight\">\n";
		print FILE "                          <td>$rankcounter</td><td><a href=\"./$leaderboardAllTimeHash->{'author'}.html\">$leaderboardAllTimeHash->{'author'}</a></td><td>$leaderboardAllTimeHash->{'replies'}</td>\n";
		print FILE "                    </tr>\n";
		
		$rankcounter++;
	}

	print FILE "</tbody>";
	print FILE "</table>\n";

	
	print FILE "</div>\n";
	print FILE "            </div>\n";
	
	print FILE "			<div class=\"row\">\n";
	print FILE "                <div class=\"col-lg-12 text-center\">\n";
	print FILE "<p><h2>&nbsp</h2>\n";
	print FILE " <div class=\"panel panel-default\">\n";
	print FILE "   <div class=\"panel-body\">\n";
	print FILE "<h4>Spiderweb of Replies From vs. Replies To</h4>\n";
	print FILE "</div>\n";
	print FILE "            </div>\n";
	print FILE "                 <div id=\"spider\" style=\"height: 800px;\"></div>\n";
	print FILE "                 </div>\n";
	print FILE "            </div>\n";
				
				
	print FILE "        </div>\n";
	print FILE "</section>\n";



	#end leaderboard section

	#start parting words section


	my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable WHERE author = '$generateAuthor' ORDER BY RANDOM() LIMIT 1");
	$randomQuery->execute();

	$resultHash = $randomQuery->fetchrow_hashref();

	$hourQuote = "\"" . $resultHash->{'title'} . "\"";
	
	
		print FILE "<section id=\"partingwords\">\n";
		print FILE "        <div class=\"container\">\n";

		print FILE "          <div class=\"row\">\n";
		print FILE "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
		print FILE "<div>\n";
		print FILE "</div>\n";
		print FILE "          <div class=\"row\">\n";
		print FILE "                <div class=\"col-lg-12 text-center\">\n";
		print FILE "<h2></h2>\n";
		print FILE "</div>\n";
		print FILE "</div>\n";
		print FILE "          <div class=\"row\">\n";
		print FILE "                <div class=\"col-lg-12 text-center\">\n";
		print FILE "<h3></h3>\n";
		print FILE "</div>\n";
		print FILE "</div>\n";

		print FILE "			<div class=\"row\">\n";
		print FILE "                <div class=\"col-lg-12 text-center\">\n";

		print FILE "                    <h2>Famous Words</h2>\n";
		print FILE "<h3>$hourQuote</h3>\n";
		print FILE "<p><h2>&nbsp</h2>\n";
		print FILE "                </div>\n";
		print FILE "            </div>\n";
	
	
		print FILE "			<div class=\"row\">\n";
		print FILE "                <div class=\"col-lg-12 text-center\">\n";
		
		#print FILE "<p><h2>&nbsp</h2>\n";
		print FILE " <div class=\"panel panel-default\">\n";
		print FILE "   <div class=\"panel-body\">\n";
		print FILE "<h4>The Last 30 Comments Posted by $generateAuthor</h4>\n";
		print FILE "</div>\n";
		print FILE "            </div>\n";

	
		print FILE "<table class=\" table table-striped table-hover\">\n";
	print FILE "  <thead>";
	print FILE "   <tr class=\"text-left\">";
	print FILE "      <th>Comment</th>";
	print FILE "      <th>Date Posted</th>";
	print FILE "      <th>Reply To</th>";
	print FILE "      <th>Parent Thread</th>";
	print FILE "    </tr>";
	print FILE "  </thead>";
	print FILE "  <tbody>";
	
		$archiveQuerySQL = "SELECT * FROM ishdata WHERE author = '$generateAuthor' ORDER BY post_time DESC LIMIT 30";
		$archiveQuery = $dbh->prepare($archiveQuerySQL);
		$archiveQuery->execute();

		while (my $archiveHash = $archiveQuery->fetchrow_hashref()) {
	
			$rowHighlight = 'text-left';
			
			if ($archiveHash->{'post_depth'} > 5) {
				$rowHighlight = "text-left warning";
			}
	
			if ($archiveHash->{'post_depth'} > 9) {
				$rowHighlight = "text-left danger";
			}
	
			print FILE "<tr class=\"$rowHighlight\">\n";
			
			print FILE "<td>$archiveHash->{'title'}</td>\n";
	
			@longDate = split(/ /, $archiveHash->{'post_time'});
			$shortDate = $longDate[0];	

			
			if ($archiveHash->{'post_depth'}) {
				print FILE "<td>$shortDate</td>\n";
				print FILE "<td><a href=\"./$archiveHash->{'reply_to_author'}.html\">$archiveHash->{'reply_to_author'}</a></td>\n";
				
				$miaLastParent = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE post_id = $archiveHash->{'root_post_id'}", undef, @params);
				
				print FILE "<td>$miaLastParent</td>\n";
				
			} 
			else {
				print FILE "<td>$shortDate</td>\n";
				print FILE "<td>Original Poster</td>\n";
				print FILE "<td>Original Post</td>\n";
			}
			
			print FILE "</tr>\n";
	}

	print FILE "</tbody>";
	print FILE "</table>\n";
	
	print FILE "                </div>\n";
	print FILE "            </div>\n";
	
	
	$testDeepPosts = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE author = '$generateAuthor' AND post_depth > 11 ORDER BY post_time DESC LIMIT 1", undef, @params);
	
	if ($testDeepPosts) {
	
		print FILE "			<div class=\"row\">\n";
		print FILE "                <div class=\"col-lg-12 text-center\">\n";
		
		print FILE "<p><h3>&nbsp</h3>\n";
		print FILE " <div class=\"panel panel-default\">\n";
		print FILE "   <div class=\"panel-body\">\n";
		print FILE "<h4>$generateAuthor\'s Deep Posts</h4>\n";
		print FILE "</div>\n";
		print FILE "            </div>\n";

	
		print FILE "<table class=\" table table-striped table-hover\">\n";
		print FILE "  <thead>";
		print FILE "   <tr class=\"text-left\">";
		print FILE "      <th>Comment</th>";
		print FILE "      <th>Depth</th>";
		print FILE "      <th>Date Posted</th>";
		print FILE "      <th>Reply To</th>";
		print FILE "      <th>Parent Thread</th>";
		print FILE "    </tr>";
		print FILE "  </thead>";
		print FILE "  <tbody>";
	
	
		$archiveQuerySQL = "SELECT * FROM ishdata WHERE author = '$generateAuthor' AND post_depth > 11 ORDER BY post_time DESC LIMIT 15";
		$archiveQuery = $dbh->prepare($archiveQuerySQL);
		$archiveQuery->execute();

			while (my $archiveHash = $archiveQuery->fetchrow_hashref()) {
			
					$rowHighlight = 'text-left';
			
					if ($archiveHash->{'post_depth'} > 15) {
							$rowHighlight = "text-left warning";
					}
	
					if ($archiveHash->{'post_depth'} > 19) {
						$rowHighlight = "text-left danger";
					}
	
					print FILE "<tr class=\"$rowHighlight\">\n";
			
					print FILE "<td>$archiveHash->{'title'}</td>\n";
					print FILE "<td>$archiveHash->{'post_depth'}</td>\n";
	
					@longDate = split(/ /, $archiveHash->{'post_time'});
					$shortDate = $longDate[0];	

			
					
					print FILE "<td>$shortDate</td>\n";
					print FILE "<td><a href=\"./$archiveHash->{'reply_to_author'}.html\">$archiveHash->{'reply_to_author'}</a></td>\n";
				
					$miaLastParent = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE post_id = $archiveHash->{'root_post_id'}", undef, @params);
				
					print FILE "<td>$miaLastParent</td>\n";
				
					 
					
			
					print FILE "</tr>\n";
			
			}
	
		print FILE "  </tbody>";
		print FILE "  </table>";
	}
	
	
	
	print FILE "        </div>\n";
	print FILE "</section>\n";

	
	#end parting words section

	#start archive section



	

	
	#end archive section


	undef %donorHash;

	printFooter();

	#add graph data to bottom of document, this is after close

	morrisGraphs();


}
	

sub morrisGraphs {
	
		#mixed ytd anger and volume
	
$graphPostsQuery = $dbh->prepare("SELECT user_day, SUM(posts) AS pst, SUM(total_depth) as deep FROM $dbUsersTable WHERE author = '$generateAuthor' GROUP BY user_day ORDER BY user_day");
$graphPostsQuery->execute();

$arrayCounter = 0;
	
my @graphDates;
my @graphAnger;
my @graphPosts;
	
while (my $datePostsHash = $graphPostsQuery->fetchrow_hashref()) {

		$ishDate = $datePostsHash->{'user_day'};
		$ishPosts = $datePostsHash->{'pst'};
		$ishDepth = $datePostsHash->{'deep'};
		
		if ($ishPosts) {
			$ishAnger = sprintf("%.2f", ($ishDepth / $ishPosts));
		} else {
			$ishAnger = 0;
		}
	
		push @graphDates, $ishDate;
		push @graphAnger, $ishAnger;
		push @graphPosts, $ishPosts;
		

		$arrayCounter++;
}	
	
print FILE "<script type=\"text/javascript\">\n";
print FILE "\$(function () {\n";
print FILE "    \$('#allday').highcharts({\n";
print FILE "        title: {\n";
print FILE "            text: 'All Time Number of Posts By Day for $generateAuthor',\n";
print FILE "            x: -20 //center\n";
print FILE "        },\n";
print FILE "        xAxis: {\n";
print FILE "            type: 'datetime'\n";
print FILE "        },\n";
print FILE "        yAxis: {\n";
print FILE "            title: {\n";
print FILE "                text: 'Number of Posts Per Day'\n";
print FILE "            },\n";
print FILE "            plotLines: [{\n";
print FILE "                value: 0,\n";
print FILE "                width: 1,\n";
print FILE "                color: '#808080'\n";
print FILE "            }]\n";
print FILE "        },\n";
print FILE "        tooltip: {\n";
print FILE "            valueSuffix: ' posts'\n";
print FILE "        },\n";
print FILE "        legend: {\n";
print FILE "            layout: 'vertical',\n";
print FILE "            align: 'right',\n";
print FILE "            verticalAlign: 'middle',\n";
print FILE "            borderWidth: 0\n";
print FILE "       },\n";
print FILE "        series: [\n";
print FILE "        {\n";
print FILE "            name: 'Posts',\n";
print FILE "            data: [";

for (my $i=0; $i < $arrayCounter; $i++) {
	
		@dateArray = split('-', $graphDates[$i]);
		$dayMinus = $dateArray[1] - 1;
	
	
		print FILE "[Date.UTC($dateArray[0], $dayMinus, $dateArray[2]), @graphPosts[$i]], ";
	
	}
	
print FILE "]\n";

print FILE "        }]\n";
print FILE "    });\n";
print FILE "});\n";
print FILE "</script>\n";
	
    #heatmap
	
print FILE "<script type=\"text/javascript\">\n";

print FILE "\$(function () {\n";

print FILE "    \$('#weeklyheatmap').highcharts({\n";

print FILE "        chart: {\n";
print FILE "            type: 'heatmap',\n";
print FILE "            marginTop: 40,\n";
print FILE "            marginBottom: 80,\n";
print FILE " backgroundColor: 'rgba(0, 0, 0, 0)'\n";
print FILE "        },\n";


print FILE "        title: {\n";
print FILE "            text: 'Posts Per Hour for $generateAuthor\'\n";
print FILE "        },\n";

print FILE "        xAxis: {\n";
print FILE "            categories: ['00:00', '01:00', '02:00', '03:00', '04:00', '05:00', '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00']\n";
print FILE "        },\n";

print FILE "        yAxis: {\n";
print FILE "            categories: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],\n";
print FILE "            title: null\n";
print FILE "        },\n";

print FILE "        colorAxis: {\n";
print FILE "            min: 0,\n";
print FILE "            minColor: '#FFFFFF',\n";
print FILE "            maxColor: Highcharts.getOptions().colors[0]\n";
print FILE "        },\n";

print FILE "        legend: {\n";
print FILE "            align: 'right',\n";
print FILE "            layout: 'vertical',\n";
print FILE "            margin: 0,\n";
print FILE "            verticalAlign: 'top',\n";
print FILE "            y: 25,\n";
print FILE "            symbolHeight: 280\n";
print FILE "        },\n";

print FILE "        tooltip: {\n";
print FILE "            formatter: function () {\n";
print FILE "               return '<b>' + this.series.xAxis.categories[this.point.x] + '</b> had <br><b>' +\n";
print FILE "                    this.point.value + '</b> on <br><b>' + this.series.yAxis.categories[this.point.y] + '</b>';\n";
print FILE "            }\n";
print FILE "        },\n";
	
	
	print FILE "series: [{\n";
    print FILE  "name: 'Posts Per Hour by Day',\n";
	print FILE  "borderWidth: 1,\n"; 
	#print FILE  "color: '#E87722',\n"; 
    print FILE  "data: [\n";
	
	
	$hourLoop = 24;
	
	for (my $i=0; $i < $hourLoop; $i++) {
	
		#SELECT COUNT(*) from (SELECT EXTRACT(HOUR FROM post_time) as hour from ishdata WHERE author = '$generateAuthor') subquery WHERE hour = $i
		
		$dayLoop = 7;
		for (my $d=0; $d < $dayLoop; $d++) {
				$hourPosts = $dbh->selectrow_array("SELECT COUNT(*) from (SELECT EXTRACT(HOUR FROM post_time) as hour, EXTRACT(DOW FROM post_time) as dayofweek from ishdata WHERE author = '$generateAuthor') subquery WHERE hour = $i AND dayofweek = $d", undef, @params);
				print FILE  "[$i, $d, $hourPosts], ";
			}
		}	
	
	print FILE "],\n";
	
	#print FILE "datalabels:  {\n";
	#print FILE " enabled: true,\n";
    #print FILE "            color: '#000000',\n";
    #print FILE "            }\n";
	#
	#print FILE " }]\n   });\n });\n";
	
	print FILE "            dataLabels: {\n";
	print FILE "                enabled: true,\n";
	print FILE "                color: '#000000'\n";
	print FILE "            }\n";
	print FILE "        }]\n";
	print FILE "    });\n";
	print FILE "});\n";
	
	
	print FILE "</script>\n";
	
	
	# spider
	
print FILE "	<script type=\"text/javascript\">\n";
print FILE "\$(function () {\n";
print FILE "   \$('#spider').highcharts({\n";
print FILE "            chart: {\n";
print FILE "            polar: true,\n";
print FILE "           type: 'line',\n";
print FILE "			backgroundColor:'rgba(255, 255, 255, 0)'\n";
print FILE "        },\n";

print FILE "        title: {\n";
print FILE "            text: '',\n";
print FILE "        },\n";

print FILE "     pane: {\n";
print FILE "            size: '80%'\n";
print FILE "       },\n";

print FILE "        yAxis: {\n";
print FILE "            gridLineInterpolation: 'polygon',\n";
print FILE "            lineWidth: 0,\n";
print FILE "            min: 0\n";
print FILE "        },\n";

print FILE "        tooltip: {\n";
print FILE "            shared: true,\n";
print FILE "            pointFormat: '<span style=\"color:{series.color}\">{series.name}: <b>{point.y:,.0f}</b><br/>'\n";
print FILE "        },\n";

print FILE "        legend: {\n";
           
print FILE "					enabled: false\n";
print FILE "				},\n";
	
	$spiderSQL = "SELECT * FROM (SELECT reply_to_author, Count(*) as replies FROM ishdata WHERE author = '$generateAuthor' AND reply_to_id not in (select post_id from gamethreads) GROUP BY reply_to_author HAVING reply_to_author <> '' ORDER BY Count(*) DESC LIMIT 30) sub ORDER BY reply_to_author";
	$spiderQuery = $dbh->prepare($spiderSQL);
	$spiderQuery->execute();

	my @spiderNames = ();
	my @spiderReplyOut = ();
	my @spiderReplyIn = ();
	$spiderIndex = 0;
	
	while (my $spiderHash = $spiderQuery->fetchrow_hashref()) {
		
		push @spiderNames, $spiderHash->{'reply_to_author'};
		push @spiderReplyOut, $spiderHash->{'replies'};
		
		$incomingReplies = $dbh->selectrow_array("SELECT Count(*) FROM ishdata WHERE reply_to_author = '$generateAuthor' AND author = '$spiderHash->{'reply_to_author'}' AND reply_to_id not in (SELECT post_id from gamethreads)", undef, @params);
		
		push @spiderReplyIn, $incomingReplies;
		
		$spiderIndex++;
	}
	
	
	print FILE "xAxis: {\n";
	print FILE " categories: [";
	foreach (@spiderNames) { print FILE "'$_',"; }
	print FILE "],\n";
	print FILE "tickmarkPlacement: 'on',\n";
	print FILE "lineWidth: 0\n";
	print FILE " },\n";
	
	print FILE "series: [{\n";
	print FILE " name: 'Reply To',\n";
	print FILE " data: [";
	foreach (@spiderReplyOut) { print FILE "$_,"; }
	print FILE "],\n";
	print FILE " pointPlacement: 'on'\n";
	print FILE " }, {\n";
	print FILE " name: 'Reply From',\n";
	print FILE " data: [";
	foreach (@spiderReplyIn) { print FILE "$_,"; }
	print FILE "],\n";
	print FILE " pointPlacement: 'on'\n";
	
	print FILE " }]\n   });\n });\n";
	print FILE "</script>\n";
	
	
# posts/VORP graph

print FILE "	<script type=\"text/javascript\">\n";
print FILE "\$(function () {\n";
print FILE "    \$('#postvsvorp').highcharts({\n";
print FILE "        chart: {\n";
print FILE "            type: 'scatter',\n";
print FILE "            zoomType: 'xy',\n";
print FILE "			backgroundColor:'rgba(255, 255, 255, 0)'\n";
print FILE "        },\n";
print FILE "        title: {\n";
print FILE "            text: '$generateAuthor Posts and VORP vs. All Posters'\n";
print FILE "        },\n";
       
print FILE "        xAxis: {\n";
print FILE "            title: {\n";
print FILE "                enabled: false,\n";
print FILE "                text: ''\n";
print FILE "            }\n";
print FILE "        },\n";
print FILE "        yAxis: {\n";
print FILE "            title: {\n";
print FILE "                text: ''\n";
print FILE "            }\n";
print FILE "        },\n";
print FILE "        legend: {\n";
print FILE "            layout: 'vertical',\n";
print FILE "            align: 'left',\n";
print FILE "            verticalAlign: 'top',\n";
print FILE "            x: 100,\n";
print FILE "            y: 70,\n";
print FILE "            floating: true,\n";
print FILE "            backgroundColor: (Highcharts.theme && Highcharts.theme.legendBackgroundColor) || '#FFFFFF',\n";
print FILE "            borderWidth: 1\n";
print FILE "        },\n";
print FILE "        plotOptions: {\n";
print FILE "            scatter: {\n";
print FILE "                marker: {\n";
print FILE "                    radius: 5,\n";
print FILE "                    states: {\n";
print FILE "                        hover: {\n";
print FILE "                            enabled: true,\n";
print FILE "                            lineColor: 'rgb(100,100,100)'\n";
print FILE "                        }\n";
print FILE "                    }\n";
print FILE "                },\n";
print FILE "                states: {\n";
print FILE "                    hover: {\n";
print FILE "                        marker: {\n";
print FILE "                            enabled: false\n";
print FILE "                        }\n";
print FILE "                    }\n";
print FILE "                },\n";
print FILE "                tooltip: {\n";
print FILE "                    headerFormat: '<b>{series.name}</b><br>',\n";
print FILE "                    pointFormat: '{point.x} posts, {point.y} VORP'\n";
print FILE "                }\n";
print FILE "            }\n";
print FILE "        },\n";
print FILE "        series: [{\n";
print FILE "            name: 'Others',\n";
print FILE "            color: 'rgba(119, 152, 191, .5)',\n";
print FILE "            data: [\n";

$scatterSQL = "SELECT author, sum(posts) as postcount, sum(totalvorp) as vorp from usertotals where author != '$generateAuthor' group by author having sum(posts) > 1000";
$scatterQuery = $dbh->prepare($scatterSQL);
$scatterQuery->execute();

	
	while (my $scatterHash = $scatterQuery->fetchrow_hashref()) {
	
		print FILE "[$scatterHash->{'postcount'}, $scatterHash->{'vorp'}],";
	
	}

print FILE "                ]\n";

print FILE "        }, {\n";
print FILE "            name: '$generateAuthor',\n";
print FILE "            color: 'rgba(223, 83, 83, 1)',\n";
print FILE "            data: [\n";

$scatterSQL = "SELECT author, sum(posts) as postcount, sum(totalvorp) as vorp from usertotals where author = '$generateAuthor' group by author";
$scatterQuery = $dbh->prepare($scatterSQL);
$scatterQuery->execute();

while (my $scatterHash = $scatterQuery->fetchrow_hashref()) {
	
		print FILE "[$scatterHash->{'postcount'}, $scatterHash->{'vorp'}],";
	
	}

print FILE "               ]\n";
print FILE "        }]\n";
print FILE "    });\n";
print FILE "});\n";
print FILE "</script>\n";


# posts/ agg graph

print FILE "	<script type=\"text/javascript\">\n";
print FILE "\$(function () {\n";
print FILE "    \$('#postvsagg').highcharts({\n";
print FILE "        chart: {\n";
print FILE "            type: 'scatter',\n";
print FILE "            zoomType: 'xy',\n";
print FILE "			backgroundColor:'rgba(255, 255, 255, 0)'\n";
print FILE "        },\n";
print FILE "        title: {\n";
print FILE "            text: '$generateAuthor Posts and Aggression vs. All Posters'\n";
print FILE "        },\n";
       
print FILE "        xAxis: {\n";
print FILE "            title: {\n";
print FILE "                enabled: false,\n";
print FILE "                text: ''\n";
print FILE "            }\n";
print FILE "        },\n";
print FILE "        yAxis: {\n";
print FILE "            title: {\n";
print FILE "                text: ''\n";
print FILE "            }\n";
print FILE "        },\n";
print FILE "        legend: {\n";
print FILE "            layout: 'vertical',\n";
print FILE "            align: 'left',\n";
print FILE "            verticalAlign: 'top',\n";
print FILE "            x: 100,\n";
print FILE "            y: 70,\n";
print FILE "            floating: true,\n";
print FILE "            backgroundColor: (Highcharts.theme && Highcharts.theme.legendBackgroundColor) || '#FFFFFF',\n";
print FILE "            borderWidth: 1\n";
print FILE "        },\n";
print FILE "        plotOptions: {\n";
print FILE "            scatter: {\n";
print FILE "                marker: {\n";
print FILE "                    radius: 5,\n";
print FILE "                    states: {\n";
print FILE "                        hover: {\n";
print FILE "                            enabled: true,\n";
print FILE "                            lineColor: 'rgb(100,100,100)'\n";
print FILE "                        }\n";
print FILE "                    }\n";
print FILE "                },\n";
print FILE "                states: {\n";
print FILE "                    hover: {\n";
print FILE "                        marker: {\n";
print FILE "                            enabled: false\n";
print FILE "                        }\n";
print FILE "                    }\n";
print FILE "                },\n";
print FILE "                tooltip: {\n";
print FILE "                    headerFormat: '<b>{series.name}</b><br>',\n";
print FILE "                    pointFormat: '{point.x} posts, {point.y} aggression'\n";
print FILE "                }\n";
print FILE "            }\n";
print FILE "        },\n";
print FILE "        series: [{\n";
print FILE "            name: 'Others',\n";
print FILE "            color: 'rgba(119, 152, 191, .5)',\n";
print FILE "            data: [\n";

$scatterSQL = "SELECT author, sum(posts) as postcount, sum(aggressionvorp) as vorp from usertotals where author != '$generateAuthor' group by author having sum(posts) > 1000";
$scatterQuery = $dbh->prepare($scatterSQL);
$scatterQuery->execute();

	
	while (my $scatterHash = $scatterQuery->fetchrow_hashref()) {
	
		$aggRate = -10000 * ($scatterHash->{'vorp'} / $scatterHash->{'postcount'});
		
		$aggRate = sprintf("%.2f", $aggRate);
	
		
		print FILE "[$scatterHash->{'postcount'}, $aggRate],";
	
	}

print FILE "                ]\n";

print FILE "        }, {\n";
print FILE "            name: '$generateAuthor',\n";
print FILE "            color: 'rgba(223, 83, 83, 1)',\n";
print FILE "            data: [\n";

$scatterSQL = "SELECT author, sum(posts) as postcount, sum(aggressionvorp) as vorp from usertotals where author = '$generateAuthor' group by author";
$scatterQuery = $dbh->prepare($scatterSQL);
$scatterQuery->execute();

while (my $scatterHash = $scatterQuery->fetchrow_hashref()) {
	
		$aggRate = -10000 * ($scatterHash->{'vorp'} / $scatterHash->{'postcount'});
		
		$aggRate = sprintf("%.2f", $aggRate);
		
		print FILE "[$scatterHash->{'postcount'}, $aggRate],";
	
	}

print FILE "               ]\n";
print FILE "        }]\n";
print FILE "    });\n";
print FILE "});\n";
print FILE "</script>\n";
	
}	


sub readDBconfig {

	$dbConfig = new Config::Simple();
	$dbConfig->read('database.conf');

	$dbHost = $dbConfig->param("dbhost");
	$dbName = $dbConfig->param("dbname");
	$dbTable = $dbConfig->param("dbtable");
	$dbUser = $dbConfig->param("dbuser");
	$dbPassword = $dbConfig->param("dbpasswd");
	$dbUsersTable = $dbConfig->param("dbusertable");

}


sub printHeader {


print FILE  '

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <title>shitposters.org - charting a small, weird corner of the internet</title>

    <!-- Bootstrap Core CSS -->
    <link href="css/bootstrap.min.css" rel="stylesheet">

    
      <!-- Custom CSS -->
    <link href="css/darkly.css" rel="stylesheet">

    <!-- Custom Fonts -->
    <link href="font-awesome/css/font-awesome.min.css" rel="stylesheet" type="text/css">
    <link href="http://fonts.googleapis.com/css?family=Montserrat:400,700" rel="stylesheet" type="text/css">
    <link href="http://fonts.googleapis.com/css?family=Kaushan+Script" rel="stylesheet" type="text/css">
    <link href="http://fonts.googleapis.com/css?family=Droid+Serif:400,700,400italic,700italic" rel="stylesheet" type="text/css">
    <link href="http://fonts.googleapis.com/css?family=Roboto+Slab:400,100,300,700" rel="stylesheet" type="text/css">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesnt work if you view the page via file:// -->
    <!--[if lt IE 9]>
        <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
        <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
	
	<link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/morris.js/0.5.1/morris.css">
';


print FILE "\n\n<script>\n";
print FILE "  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){\n";
print FILE "  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),\n";
print FILE "  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)\n";
print FILE "  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');\n\n";

print FILE "  ga('create', 'UA-59827132-1', 'auto');\n";
print FILE "  ga('send', 'pageview');\n\n";

print FILE "</script>\n\n";


print FILE '
</head>
<body id="page-top" class="index">

    <!-- Navigation -->
    <nav class="navbar navbar-default navbar-fixed-top">
        <div class="container">
            <!-- Brand and toggle get grouped for better mobile display -->
            <div class="navbar-header page-scroll">
                <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#bs-example-navbar-collapse-1">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>';
				
				
print FILE  "                <a class=\"navbar-brand page-scroll\" href=\"#page-top\">$resultHash->{'author'}</a>";

print FILE '            </div>

            <!-- Collect the nav links, forms, and other content for toggling -->
            <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
                <ul class="nav navbar-nav navbar-right">
                    <li class="hidden">
                        <a href="#page-top"></a>
                    </li>
					<li>
                        <a class="page-scroll" href="#rank">Rankings</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#graphs">Graphs</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#30days">30 Days</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#lovehate">Love/Hate</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#partingwords">Words</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="./index.html">Home</a>
                    </li>
                   
                </ul>
            </div>
            <!-- /.navbar-collapse -->
        </div>
        <!-- /.container-fluid -->
    </nav>

			';
			




}

sub printFooter {

print FILE '

    <footer>
        <div class="container">
            <div class="row">
                <div class="col-md-4">
                    <span class="copyright">Copyright &copy; shitposters.org, 2015</span>
                </div>
                <div class="col-md-4">
                    <ul class="list-inline social-buttons">
                        <li><a href="#"><i class="fa fa-twitter"></i></a>
                        </li>
                        <li><a href="#"><i class="fa fa-facebook"></i></a>
                        </li>
                        <li><a href="#"><i class="fa fa-linkedin"></i></a>
                        </li>
                    </ul>
                </div>
                <div class="col-md-4">
                    <ul class="list-inline quicklinks">
                        <li><a href="#">Privacy Policy</a>
                        </li>
                        <li><a href="#">Terms of Use</a>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </footer>

       

    <!-- jQuery -->
	
	<script src="js/jquery.js"></script>

	<script type="text/javascript" src="http://code.highcharts.com/highcharts.js"></script>
	<script type="text/javascript" src="http://www.highcharts.com/highslide/highslide-full.min.js"></script>
	<script type="text/javascript" src="http://www.highcharts.com/highslide/highslide.config.js" charset="utf-8"></script>
	<script type="text/javascript" src="http://code.highcharts.com/modules/heatmap.js"></script>
    <script type="text/javascript" src="http://code.highcharts.com/modules/exporting.js"></script>
	<script src="http://code.highcharts.com/highcharts-more.js"></script>
	<script src="http://code.highcharts.com/modules/solid-gauge.js"></script>
    <script src="http://code.highcharts.com/themes/dark-unica.js"></script>
	<link rel="stylesheet" type="text/css" href="http://www.highcharts.com/highslide/highslide.css" />
	
    <!-- Bootstrap Core JavaScript -->
    <script src="js/bootstrap.min.js"></script>

    <!-- Plugin JavaScript -->
    <script src="http://cdnjs.cloudflare.com/ajax/libs/jquery-easing/1.3/jquery.easing.min.js"></script>
    <script src="js/classie.js"></script>
    <script src="js/cbpAnimatedHeader.js"></script>


    <!-- Custom Theme JavaScript -->
    <script src="js/agency.js"></script>
	
	<script src="//cdnjs.cloudflare.com/ajax/libs/raphael/2.1.0/raphael-min.js"></script>
	

	

</body>

</html>

';

}
