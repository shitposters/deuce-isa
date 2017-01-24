#!/usr/bin/perl

use DBI;
use DateTime;
use Config::Simple;

my $firstDate = DateTime->new(
    time_zone => "America/Chicago",
    year => 2015,
    month => 02,
    day => 12,
);

my $todayDate = DateTime->now(time_zone=>'local');
my $yesterdayDate = DateTime->now(time_zone=>'local')->subtract( days => 1 );
my $weekDate = DateTime->now(time_zone=>'local')->subtract( days => 7 );
my $monthDate = DateTime->now(time_zone=>'local')->subtract( days => 31 );
my $todayDateString = $todayDate->ymd;
my $yesterdayDateString = $yesterdayDate->ymd;
my $weekDateString = $weekDate->ymd;
my $monthDateString = $monthDate->ymd;

my $runTimeString = $todayDate->hms;

my $currentDow = $todayDate->day_of_week();

my $currentHour = $todayDate->hour;

my $duration = $todayDate->delta_days($firstDate)->delta_days();
$duration = $duration / 7;

if ($currentDow == 7) {
	$currentDow = 0;
}

if ($currentHour > 0) { 
	$lastHour = $currentHour - 1;
	$dateStringSQL = "post_time >= '$todayDateString $lastHour:00:00' AND post_time <= '$todayDateString $lastHour:59:59'";
	$hourTextString = "$lastHour:00 and $currentHour:00";
	
} else {
	$dateStringSQL = "post_time >= '$yesterdayDateString 23:00:00' AND post_time <= '$yesterdayDateString 23:59:59'";
	$hourTextString = "23:00 and 00:00";
	$lastHour = 23;
	$currentDow = $yesterdayDate->day_of_week();
	if ($currentDow == 7) {
			$currentDow = 0;
		}		
	}
	

#$currentDow--;

$depthFactor = 500;
$singleDepthFactor = 75;


my $angerdepth = 6;

my @authorarray;

readDBconfig();

my $dbh = DBI->connect("DBI:Pg:dbname=$dbName;host=$dbHost", "$dbUser", "$dbPassword", {'RaiseError' => 1});
my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable ORDER BY RANDOM() LIMIT 1");
$randomQuery->execute();

$resultHash = $randomQuery->fetchrow_hashref();

$hourQuote = "\"" . $resultHash->{'title'} . "\"" . "  -- $resultHash->{'author'}";

$alltimeCount = $dbh->selectrow_array("SELECT COUNT(*) FROM $dbTable", undef, @params);
$alltimeDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable", undef, @params);
$hourCount = $dbh->selectrow_array("SELECT COUNT(*) FROM $dbTable WHERE $dateStringSQL", undef, @params);
$hourDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE $dateStringSQL", undef, @params);
$dayDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00'", undef, @params);
$dayCount = $dbh->selectrow_array("SELECT COUNT(*) FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00'", undef, @params);

$hourActiveID = $dbh->selectrow_array("SELECT root_post_id FROM $dbTable WHERE $dateStringSQL AND root_post_id > 0 GROUP BY root_post_id ORDER BY Count(*) DESC LIMIT 1", undef, @params);

if ($hourActiveID) {
	$hourActiveTitle = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE post_id = $hourActiveID", undef, @params);
	$hourActiveAuthor = $dbh->selectrow_array("SELECT author FROM $dbTable WHERE post_id = $hourActiveID", undef, @params);
	} 

$dayActiveID = $dbh->selectrow_array("SELECT root_post_id FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' AND root_post_id > 0 GROUP BY root_post_id ORDER BY Count(*) DESC LIMIT 1", undef, @params);

if ($dayActiveID) {
	$dayActiveTitle = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE post_id = $dayActiveID", undef, @params);
	$dayActiveAuthor = $dbh->selectrow_array("SELECT author FROM $dbTable WHERE post_id = $dayActiveID", undef, @params);
}

$dayActivePoster = $dbh->selectrow_array("SELECT author FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' GROUP BY author ORDER BY Count(*) DESC LIMIT 1", undef, @params);
$dayActivePosterNumber = $dbh->selectrow_array("SELECT COUNT(*) FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' AND author ='$dayActivePoster'", undef, @params);

$dayRandomPoster = $dbh->selectrow_array("SELECT author FROM $dbTable ORDER BY RANDOM() LIMIT 1", undef, @params);

if ($hourCount) { 
		$hourDepthAvg = sprintf("%.2f", $hourDepth / $hourCount);
	} else {
		$hourDepthAvg = 0;
	}
	
if ($dayCount) { 
		$dayDepthAvg = sprintf("%.2f", $dayDepth / $dayCount);
	} else {
		$dayDepthAvg = 0;
	}

$normalHourQty = $dbh->selectrow_array("SELECT COUNT(*) from (SELECT EXTRACT(HOUR FROM post_time) as hour, EXTRACT(DOW FROM post_time) as dayofweek from ishdata) subquery WHERE hour = $lastHour AND dayofweek = $currentDow", undef, @params);
$normalHourAvg = int($normalHourQty / $duration);


$ishMoodDay = "pretty average";
$ishMoodHour = "pretty average";
$ishMoodBlurb = "";
$iconStyle = '';
	
if ($dayDepthAvg < 2.5 ) {
	$ishMoodDay = "relatively good";
	$ishMoodBlurb = "Wade in with confidence.";
	$iconStyle = 'style="color:green;"';
}

if ($dayDepthAvg > 3.5 ) {
	$ishMoodDay = "rather shitty";
	$ishMoodBlurb = "Someone is probably looking to rip your dick off.";
	$iconStyle = 'style="color:red;"';
}

if ($hourDepthAvg < 2.5 ) {
	$ishMoodHour = "relatively good";
}

if ($hourDepthAvg > 3.5 ) {
	$ishMoodHour = "rather shitty";
}

if (!$hourCount) {
	$hourCount = 0;
}

if (!$dayCount) {
	$dayCount = 0;
}

printHeader();



#begin printing summary section

print "<section id=\"services\">\n";
print "        <div class=\"container\">\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h3>$hourQuote</h3>\n";
print "</div>\n";
print "</div>\n";

print " <div class=\"row text-center\">\n";
print "                <div class=\"col-md-4\">\n";
print "                 <div id=\"container-postshour\"></div>\n";
print "<h4>$hourCount posts last hour</h4>\n";

if ($hourCount) {
	print "<p>Between the hours of $hourTextString there were $hourCount posts on the ish. Typically there are $normalHourAvg posts during this hour. The most active thread is <a href=\"http://members.boardhost.com/onedeuce/msg/$hourActiveID.html\" target=\"new\">\"$hourActiveTitle\"</a> by <a href=\"./$hourActiveAuthor.html\">$hourActiveAuthor</a>.</p>\n";
	} else {
		print "<p>Between the hours of $hourTextString there were $hourCount no posts on the ish. Everyone is either dead, asleep, masturbating furiously or just doing other things. Typically there are $normalHourAvg posts during this hour.</p>\n";
	}
print "</div>\n";

print " <div class=\"col-md-4\">\n";
print "                 <div id=\"container-postsday\"></div>\n";
print "<h4>$dayCount posts today</h4>\n";

if ($dayCount) {
	print "<p>There have been $dayCount posts since midnight on the ish. The most active topic has been <a href=\"http://members.boardhost.com/onedeuce/msg/$dayActiveID.html\" target=\"new\">\"$dayActiveTitle\"<a> by <a href=\"./$dayActiveAuthor.html\">$dayActiveAuthor</a>. The most posts so far today are by <a href=\"./$dayActivePoster.html\">$dayActivePoster</a> with $dayActivePosterNumber.</p>\n";
	} else {
		print "<p>No posts yet today? Well, it's not that far past midnight, but clearly some new, less lazy posters are needed. Someone put out a want ad or something.</p>\n";
	}
	
print "</div>\n";

print " <div class=\"col-md-4\">\n";
print "                 <div id=\"container-postsdepth\"></div>\n";
print "<h4>The mood is $ishMoodDay</h4>\n";
print "<p>Data since midnight shows that the ish is in a $ishMoodDay frame of mind. $ishMoodBlurb If there's anyone to watch out for, it's probably one of these redasses: ";
my $angryQuery = $dbh->prepare("SELECT author FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' GROUP BY author ORDER BY SUM(post_depth) DESC LIMIT 3");
$angryQuery->execute();
$angryAuthor = $angryQuery->fetchrow_hashref();
print "<a href=\"./$angryAuthor->{'author'}.html\">$angryAuthor->{'author'}</a>, ";
$angryAuthor = $angryQuery->fetchrow_hashref();
print "<a href=\"./$angryAuthor->{'author'}.html\">$angryAuthor->{'author'}</a> or ";
$angryAuthor = $angryQuery->fetchrow_hashref();
print "<a href=\"./$angryAuthor->{'author'}.html\">$angryAuthor->{'author'}</a>. ";
print "Good luck.</p>\n";

print "</div>\n";
print "            </div>\n";



print " <div class=\"row text-center\" style=\"margin-top: 100px;\">\n";
print "                <div class=\"col-md-6\">\n";

print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Most Popular Threads Today</h4>\n";
print "</div>\n";
print "            </div>\n";


print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Title</th>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Posts</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $popularQuery = $dbh->prepare("SELECT root_post_id, COUNT(*) as threadposts FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' AND root_post_id > 0 GROUP BY root_post_id ORDER BY Count(*) DESC LIMIT 5");
$popularQuery->execute();

while (my $popularHash = $popularQuery->fetchrow_hashref()) {
	
	$threadID = $popularHash->{'root_post_id'};
	$threadPosts = $popularHash->{'threadposts'};
	$threadTitle = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE post_id = $threadID", undef, @params);
	$threadAuthor = $dbh->selectrow_array("SELECT author FROM $dbTable WHERE post_id = $threadID", undef, @params);
	$threadDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE root_post_id = $threadID", undef, @params);
	
	$threadAverage = $threadDepth / $threadPosts;
	
	$rowHighlight = "";
	
	if ($threadAverage > 4.5) {
		$rowHighlight = "class=\"warning\"";
	}
	
	if ($threadAverage > 6) {
		$rowHighlight = "class=\"danger\"";
	}
	
	print "<tr $rowHighlight>";
	print "<td class=\"text-left\"><a href=\"http://members.boardhost.com/onedeuce/msg/$threadID.html\" target=\"new\">$threadTitle</a></td><td class=\"text-left\"><a href=\"./$threadAuthor.html\">$threadAuthor</a></td><td class=\"text-left\">$threadPosts</td>";
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "</div>\n";

print " <div class=\"row text-center\">\n";
print "                <div class=\"col-md-6\">\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Today's Most Verbose Posters</h4>\n";
print "</div>\n";
print "            </div>\n";

print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Posts</th>";
print "      <th class=\"text-left\">Last Words</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $verboseQuery = $dbh->prepare("SELECT author, COUNT(*) as daycount FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' GROUP BY author ORDER BY Count(*) DESC LIMIT 5");
$verboseQuery->execute();

while (my $verboseHash = $verboseQuery->fetchrow_hashref()) {
	
	$verboseAuthor = $verboseHash->{'author'};
	$verbosePosts = $verboseHash->{'daycount'};
	$verboseLastWords = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE author = '$verboseAuthor' order by post_time DESC LIMIT 1", undef, @params);
	
	$verboseDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE author = '$verboseAuthor' AND post_time >= '$todayDateString 00:00:00'", undef, @params);
	
	$verboseAverage = $verboseDepth / $verbosePosts;
	
	$rowHighlight = "";
	
	if ($verboseAverage > 4.5) {
		$rowHighlight = "class=\"warning\"";
	}
	
	if ($verboseAverage > 6) {
		$rowHighlight = "class=\"danger\"";
	}
	
	print "<tr $rowHighlight>";
	print "<td class=\"text-left\"><a href=\"./$verboseAuthor.html\">$verboseAuthor</a></td><td class=\"text-left\">$verbosePosts</td><td class=\"text-left\">$verboseLastWords</td>";
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "</div>\n";

print "</div>\n";

print " <div class=\"row text-center\" style=\"margin-top: 100px;\">\n";

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "                 <div id=\"pie\"></div>\n";
print "        </div>\n";


print "        </div>\n";
print "</section>\n";
	


#print "$hourQuote\n";
#print "$hourCount posts last hour and is in a $ishMoodHour ($hourDepthAvg) mood.\n";
#print "\"$hourActiveTitle\" by $hourActiveAuthor\n";
#print "There have been $dayCount posts since midnight on the ish. Based on the patterns of posting, the ish appears to be in a $ishMoodDay mood for the day. ";
#print " The most active topic has been \"$dayActiveTitle\" by $dayActiveAuthor. The most posts so far today are by $dayActivePoster ($dayActivePosterNumber).\n";

#end printing summary section


# BEGIN YESTERDAY SECTION

my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable WHERE post_time >= '$yesterdayDateString 00:00:00' AND post_time < '$todayDateString 00:00:00' ORDER BY RANDOM() LIMIT 1");
$randomQuery->execute();

$resultHash = $randomQuery->fetchrow_hashref();

$hourQuote = "\"" . $resultHash->{'title'} . "\"" . "  -- $resultHash->{'author'}";

print "<section id=\"portfolio\">\n";

print "        <div class=\"container\">\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "<div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h2></h2>\n";
print "</div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h3></h3>\n";
print "</div>\n";
print "</div>\n";
print "            <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "                 <h1>Yesterday's News</h1>\n";
print "<h4>$hourQuote</h4>\n";
print "</div>\n";
print "</div>\n";

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "<div>\n";
print "</div>\n";

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h2></h2>\n";
print "</div>\n";
print "</div>\n";

# YESTERDAY TOP TALKERS START

print " <div class=\"row text-center\">\n";
print "                <div class=\"col-md-3\">\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Top Talkers</h4>\n";
print "</div>\n";
print "            </div>\n";

print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Posts</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $verboseQuery = $dbh->prepare("SELECT author, COUNT(*) as daycount FROM $dbTable WHERE post_time >= '$yesterdayDateString 00:00:00' AND post_time < '$todayDateString 00:00:00' GROUP BY author ORDER BY Count(*) DESC LIMIT 10");
$verboseQuery->execute();

while (my $verboseHash = $verboseQuery->fetchrow_hashref()) {
	
	$verboseAuthor = $verboseHash->{'author'};
	$verbosePosts = $verboseHash->{'daycount'};
	
	$verboseDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE author = '$verboseAuthor' AND post_time >= '$todayDateString 00:00:00' AND post_time < '$todayDateString 00:00:00'", undef, @params);
	
	$verboseAverage = $verboseDepth / $verbosePosts;
	
	$rowHighlight = "";
	
	if ($verboseAverage > 4.5) {
		$rowHighlight = "class=\"warning\"";
	}
	
	if ($verboseAverage > 6) {
		$rowHighlight = "class=\"danger\"";
	}
	
	print "<tr $rowHighlight>";
	print "<td class=\"text-left\"><a href=\"./$verboseAuthor.html\">$verboseAuthor</a></td><td class=\"text-left\">$verbosePosts</td>";
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "</div>\n";




# YESTERDAY TOP TALKERS END

# YESTERDAY TOP POSTS START

print "                <div class=\"col-md-6\">\n";

print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Popular Threads Yesterday</h4>\n";
print "</div>\n";
print "            </div>\n";


print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Title</th>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Posts</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $popularQuery = $dbh->prepare("SELECT root_post_id, COUNT(*) as threadposts FROM $dbTable WHERE post_time >= '$yesterdayDateString 00:00:00' AND post_time < '$todayDateString 00:00:00' AND root_post_id > 0 GROUP BY root_post_id ORDER BY Count(*) DESC LIMIT 10");
$popularQuery->execute();

while (my $popularHash = $popularQuery->fetchrow_hashref()) {
	
	$threadID = $popularHash->{'root_post_id'};
	$threadPosts = $popularHash->{'threadposts'};
	$threadTitle = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE post_id = $threadID", undef, @params);
	$threadAuthor = $dbh->selectrow_array("SELECT author FROM $dbTable WHERE post_id = $threadID", undef, @params);
	$threadDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE root_post_id = $threadID", undef, @params);
	
	$threadAverage = $threadDepth / $threadPosts;
	
	$rowHighlight = "";
	
	if ($threadAverage > 4.5) {
		$rowHighlight = "class=\"warning\"";
	}
	
	if ($threadAverage > 6) {
		$rowHighlight = "class=\"danger\"";
	}
	
	print "<tr $rowHighlight>";
	print "<td class=\"text-left\"><a href=\"http://members.boardhost.com/onedeuce/msg/$threadID.html\" target=\"new\">$threadTitle</a></td><td class=\"text-left\"><a href=\"./$threadAuthor.html\">$threadAuthor</a></td><td class=\"text-left\">$threadPosts</td>";
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "</div>\n";

# YESTERDAY'S TOP POSTS END

# YESTERDAY'S ANGRY POSTERS START

print " <div class=\"row text-center\">\n";
print "                <div class=\"col-md-3\">\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Operating Deep</h4>\n";
print "</div>\n";
print "            </div>\n";

print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Depth</th>";
print "      <th class=\"text-left\">Posts</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $angryQuery = $dbh->prepare("SELECT author, posts, depthavg FROM usertotals WHERE user_day = '$yesterdayDateString' AND posts > 5 ORDER BY depthavg DESC LIMIT 10");
$angryQuery->execute();

while (my $angryHash = $angryQuery->fetchrow_hashref()) {
	
	$angryAuthor = $angryHash->{'author'};
	$angryPosts = $angryHash->{'posts'};
	
	$angryDepth = $angryHash->{'depthavg'};
	
	$rowHighlight = "";
	
	if ($depthAverage > 4.5) {
		$rowHighlight = "class=\"warning\"";
	}
	
	if ($depthAverage > 6) {
		$rowHighlight = "class=\"danger\"";
	}
	
	print "<tr $rowHighlight>";
	print "<td class=\"text-left\"><a href=\"./$angryAuthor.html\">$angryAuthor</a></td><td class=\"text-left\">$angryDepth</td><td class=\"text-left\">$angryPosts</td>";
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "</div>\n";

# YESTERDAY'S ANGRY POSTERS END

# WEEKLY HEAT MAP START
print "        </div>\n";

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "                 <div id=\"dailyposts\" style=\"height: 500px;\"></div>\n";
print "</div>\n";
print "</div>\n";

print " <div class=\"row text-center\" style=\"margin-top: 100px;\">\n";
# WEEKLY HEAT MAP END



print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Yesterday's Top 10 Posters by Efficiency</h4>\n";
print "</div>\n";
print "            </div>\n";

print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Rank</th>";
print "      <th class=\"text-left\">Poster</th>";
print "      <th class=\"text-left\">Posts</th>";
print "      <th class=\"text-left\">Thread Starts</th>";
print "      <th class=\"text-left\">Replied To</th>";
print "      <th class=\"text-left\">VORP</th>";
print "      <th class=\"text-left\">Efficiency</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

$leaderboardAllTimeSQL = "SELECT author, SUM(posts) as pst, SUM(replied_to) as replies, SUM(threads_started) as starts, SUM(totalvorp) as vorp, SUM(totalvorp) / SUM(posts) as eff FROM $dbUsersTable WHERE user_day = '$yesterdayDateString' GROUP BY author HAVING SUM(posts) > 10 order by eff DESC LIMIT 10";
$leaderboardAllTimeQuery = $dbh->prepare($leaderboardAllTimeSQL);
$leaderboardAllTimeQuery->execute();



$rankcounter = 1;

while (my $leaderboardAllTimeHash = $leaderboardAllTimeQuery->fetchrow_hashref()) {
	
	$VORP = sprintf("%.4f", $leaderboardAllTimeHash->{'vorp'});
	$eff = sprintf("%.5f", $leaderboardAllTimeHash->{'eff'});
	
	print "                    <tr>\n";
	print "                          <td class=\"text-left\">$rankcounter</td><td class=\"text-left\"><a href=\"./$leaderboardAllTimeHash->{'author'}.html\">$leaderboardAllTimeHash->{'author'}</a></td><td class=\"text-left\">$leaderboardAllTimeHash->{'pst'}</td><td class=\"text-left\">$leaderboardAllTimeHash->{'starts'}</td><td class=\"text-left\">$leaderboardAllTimeHash->{'replies'}</td><td class=\"text-left\">$VORP</td><td class=\"text-left\">$eff</td>\n";
	print "                    </tr>\n";
	
	$rankcounter++;
}



print "  </tbody>";
print "  </table>";

print "\n";
print "</div>\n";
print "            </div>\n";

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "                 <div id=\"weeklyheatmap\" style=\"height: 500px;\"></div>\n";
print "</div>\n";
print "</div>\n";

#GRAPHS START



print "               </div>\n";
print "           </div>\n";

#print "<div class=\"row\">\n";
#print "                <div class=\"col-lg-12 text-center\">\n";
#print "                 <h3 class=\"section-subheading text-muted\">Posts per day and associated anger level of the ish. The anger level is normalized so that 1000 represents the level of anger on an average ish-day.</h3>\n";
#print "                <div id=\"random-chart\" style=\"height: 250px;\"></div>\n";
#print "                 <h3 class=\"section-subheading text-muted\">The posts per day and anger level for a random shitposter, <a href=\"./$dayRandomPoster.html\">$dayRandomPoster</a>. An anger level of 100 is the average for a typical user.</h3>\n";

#print "</div>\n";
#print "            </div>\n";

print "        </div>\n";
print "    </section>\n";


#end of graph insertion


my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable ORDER BY RANDOM() LIMIT 1");
$randomQuery->execute();

$resultHash = $randomQuery->fetchrow_hashref();

$hourQuote = "\"" . $resultHash->{'title'} . "\"" . "  -- $resultHash->{'author'}";

#start of leaderboard

# BEGIN ALL-TIME SECTION



print "<section id=\"about\">\n";
print "        <div class=\"container\">\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "<div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h2></h2>\n";
print "</div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h3></h3>\n";
print "</div>\n";
print "</div>\n";
print "            <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "                 <h1>The Ish is Forever</h1>\n";
print "<h4>$hourQuote</h4>\n";
print "</div>\n";
print "</div>\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "<div>\n";
print "</div>\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>All-Time Top 25 Posters Ranked by Efficiency</h4>\n";
print "</div>\n";
print "            </div>\n";
print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th>Rank</th>";
print "      <th class=\"text-left\">Poster</th>";
print "      <th>Posts</th>";
print "      <th>Thread Starts</th>";
print "      <th>Replied To</th>";
print "      <th>VORP</th>";
print "      <th>Efficiency</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";


#$leaderboardAllTimeSQL = "SELECT author, sum(threads_started) as starts, sum(posts) as pst, SUM(replied_to) as replies, SUM(total_depth) / (SUM(posts) + 1)  as depth, SUM(postvorp) as postvorp, SUM(startvorp) as startvorp, SUM(aggressionvorp) as agg, SUM(totalvorp) AS vorp FROM $dbUsersTable GROUP BY author ORDER BY vorp DESC LIMIT 25";
$leaderboardAllTimeSQL = "SELECT author, SUM(posts) as pst, SUM(replied_to) as replies, SUM(threads_started) as starts, SUM(totalvorp) as vorp, SUM(totalvorp) / SUM(posts) as eff from usertotals GROUP BY author HAVING SUM(posts) > 250 order by eff DESC LIMIT 25";
$leaderboardAllTimeQuery = $dbh->prepare($leaderboardAllTimeSQL);
$leaderboardAllTimeQuery->execute();

$rankcounter = 1;

while (my $leaderboardAllTimeHash = $leaderboardAllTimeQuery->fetchrow_hashref()) {
	
	$VORP = sprintf("%.4f", $leaderboardAllTimeHash->{'vorp'});
	$eff = sprintf("%.5f", $leaderboardAllTimeHash->{'eff'});
	
	print "                    <tr>\n";
	print "                          <td class=\"text-left\">$rankcounter</td><td class=\"text-left\"><a href=\"./$leaderboardAllTimeHash->{'author'}.html\">$leaderboardAllTimeHash->{'author'}</a></td><td class=\"text-left\">$leaderboardAllTimeHash->{'pst'}</td><td class=\"text-left\">$leaderboardAllTimeHash->{'starts'}</td><td class=\"text-left\">$leaderboardAllTimeHash->{'replies'}</td><td class=\"text-left\">$VORP</td><td class=\"text-left\">$eff</td>\n";
	print "                    </tr>\n";
	
	$rankcounter++;
}

print "</tbody>\n";

print "</table>\n";



print "</div>\n";
print "            </div>\n";

# start dropdown for users

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h2> </h2>\n";
print "</div>\n";
print "</div>\n";

print "			<div class=\"row\">\n";

print "<div class=\"form-group\">\n";

print "<label for=\"select\" class=\"col-md-4 control-label text-right\">Details on an isher:</label>\n";
#print "<div class=\"col-md-4 text-right\">\n";
#print "Jump to an isher:\n";
#print "</div>\n";

print "                <div class=\"col-md-4 text-center\">\n";
                
print "<select class=\"form-control\" id=\"select\" onchange=\"location = this.options[this.selectedIndex].value;\">\n";

print "         <option value=\"http://www.shitposters.org/\">Select:</option>\n";

my $usersQuery = $dbh->prepare("SELECT DISTINCT author FROM $dbUsersTable ORDER BY author");
$usersQuery->execute();

while (my $resultHash = $usersQuery->fetchrow_hashref()) {

	$isher = $resultHash->{'author'};
	print "<option value=\"http://www.shitposters.org/$isher.html\">$isher</option>\n";

}
        
print "                </select>\n";
        
print "                </div>\n";

print "<div class=\"col-md-4\">\n";
print "</div>\n";

print "       </div>\n";
print "            </div>\n";


print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h2> </h2>\n";
print "</div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h3></h3>\n";
print "</div>\n";
print "</div>\n";

#end user dropdown

print "			<div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
                
print "                 <div id=\"allday\" style=\"height: 500px;\"></div>\n";
print "                </div>\n";
print "            </div>\n";

# ALL TIME INDIVIDUAL GRAPHS

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "<div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h2> </h2>\n";
print "</div>\n";
print "</div>\n";


# ALL TIME TOP TALKERS START

print " <div class=\"row text-center\">\n";
print "                <div class=\"col-md-4\">\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>All Time Posts</h4>\n";
print "</div>\n";
print "            </div>\n";

print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Posts</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $verboseQuery = $dbh->prepare("SELECT author, COUNT(*) as daycount FROM $dbTable  GROUP BY author ORDER BY Count(*) DESC LIMIT 10");
$verboseQuery->execute();

while (my $verboseHash = $verboseQuery->fetchrow_hashref()) {
	
	$verboseAuthor = $verboseHash->{'author'};
	$verbosePosts = $verboseHash->{'daycount'};
	
	
	print "<tr>";
	print "<td class=\"text-left\"><a href=\"./$verboseAuthor.html\">$verboseAuthor</a></td><td class=\"text-left\">$verbosePosts</td>";
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "</div>\n";




# ALL TIME TOP TALKERS END

# ALL TIME TOP POSTS START

print "                <div class=\"col-md-4\">\n";

print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Top Thread Starters</h4>\n";
print "</div>\n";
print "            </div>\n";


print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Posts</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $verboseQuery = $dbh->prepare("SELECT SUM(threads_started) as pst, author FROM $dbUsersTable GROUP BY author ORDER BY pst DESC LIMIT 10");
$verboseQuery->execute();

while (my $verboseHash = $verboseQuery->fetchrow_hashref()) {
	
	$verboseAuthor = $verboseHash->{'author'};
	$verbosePosts = $verboseHash->{'pst'};
	
	print "<tr $rowHighlight>";
	print "<td class=\"text-left\"><a href=\"./$verboseAuthor.html\">$verboseAuthor</a></td><td class=\"text-left\">$verbosePosts</td>";
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "</div>\n";

# ALL TIME TOP START END


# ALL TIME ANGRY POSTERS START

print " <div class=\"row text-center\">\n";
print "                <div class=\"col-md-4\">\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Rightmost Posters</h4>\n";
print "</div>\n";
print "            </div>\n";

print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Index</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $angryQuery = $dbh->prepare("SELECT author, SUM(aggressionvorp) / SUM(posts) * -10000 as avorp FROM usertotals GROUP BY author HAVING sum(posts) > 1000 ORDER BY avorp DESC LIMIT 10");
$angryQuery->execute();

while (my $angryHash = $angryQuery->fetchrow_hashref()) {
	
	$angryAuthor = $angryHash->{'author'};
	$angryPosts = sprintf("%.3f", $angryHash->{'avorp'});
	
	
	print "<tr $rowHighlight>";
	print "<td class=\"text-left\"><a href=\"./$angryAuthor.html\">$angryAuthor</a></td><td class=\"text-left\">$angryPosts</td>";
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "</div>\n";

# END ALL TIME ANGRY POSTERS END

print "        </div>\n";



# END ALL TIME INDIVIDUAL GRAPHS

print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
          
print "        </div>\n";
print "</section>\n";

# END FOREVER SECTION

my $randomQuery = $dbh->prepare("SELECT * FROM $dbTable ORDER BY RANDOM() LIMIT 1");
$randomQuery->execute();

$resultHash = $randomQuery->fetchrow_hashref();

$hourQuote = "\"" . $resultHash->{'title'} . "\"" . "  -- $resultHash->{'author'}";


#start hall of shit section

print "<section id=\"team\" class=\"bg-light-gray\">\n";
print "        <div class=\"container\">\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "<div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h2></h2>\n";
print "</div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h3></h3>\n";
print "</div>\n";
print "</div>\n";
print "            <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "                 <h1>The Immortal Hall of Shit</h1>\n";
print "<h4>$hourQuote</h4>\n";
print "</div>\n";
print "</div>\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "<div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\" style=\"min-height: 100px;\">\n";
print "<div>\n";
print "</div>\n";
print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h2></h2>\n";
print "</div>\n";
print "</div>\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Current Records and Holders</h4>\n";
print "</div>\n";
print "            </div>\n";
print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Record</th>";
print "      <th class=\"text-left\">Poster</th>";
print "      <th class=\"text-left\">Value</th>";
print "      <th class=\"text-left\">Date</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody class=\"text-left\">";

$recordQuery = $dbh->prepare("SELECT SUM(posts) as pst, user_day FROM $dbUsersTable GROUP BY user_day ORDER BY pst DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

print "<tr><td>Most number of posts on the ish in a day</td><td>N/A</td><td>$recordHash->{'pst'}</td><td>$recordHash->{'user_day'}</td></tr>\n";


$recordQuery = $dbh->prepare("SELECT SUM(posts) as pst, author FROM $dbUsersTable GROUP BY author ORDER BY pst DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

print "<tr><td>Most posts by an isher, all time</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$recordHash->{'pst'}</td><td>N/A</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT * FROM $dbUsersTable ORDER BY posts DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

print "<tr><td>Most posts by an isher in a single day</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$recordHash->{'posts'}</td><td>$recordHash->{'user_day'}</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT SUM(threads_started) as pst, author FROM $dbUsersTable GROUP BY author ORDER BY pst DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

print "<tr><td>Most threads started, all time</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$recordHash->{'pst'}</td><td>N/A</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT * FROM $dbUsersTable ORDER BY threads_started DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

print "<tr><td>Most threads started in a single day</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$recordHash->{'threads_started'}</td><td>$recordHash->{'user_day'}</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT * FROM $dbUsersTable ORDER BY totalvorp DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

print "<tr><td>Highest single-day VORP</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$recordHash->{'totalvorp'}</td><td>$recordHash->{'user_day'}</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT * FROM $dbUsersTable WHERE posts > 25 ORDER BY totalvorp LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

print "<tr><td>Lowest single-day VORP (25 posts minimum)</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$recordHash->{'totalvorp'}</td><td>$recordHash->{'user_day'}</td></tr>\n";

#$recordQuery = $dbh->prepare("SELECT SUM(totalvorp) as tvorp, SUM(posts) as pst, author FROM $dbUsersTable GROUP BY author HAVING SUM(posts) > 100 ORDER BY tvorp LIMIT 1");
#$recordQuery->execute();
#$recordHash = $recordQuery->fetchrow_hashref();

#print "<tr><td>Lowest career VORP (25 posts minimum)</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$recordHash->{'tvorp'}</td><td>N/A</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT * FROM $dbUsersTable WHERE posts > 25 ORDER BY depthavg DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

print "<tr><td>Highest single-day aggression (25 posts minimum)</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$recordHash->{'depthavg'}</td><td>$recordHash->{'user_day'}</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT author, SUM(aggressionvorp) / SUM(posts) * -1000000 as avorp FROM $dbUsersTable GROUP BY author HAVING sum(posts) > 1000 ORDER BY avorp DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

$aggdisplay = sprintf("%.5f", $recordHash->{'avorp'});

print "<tr><td>Highest aggression rate, career to date (1000 posts minimum)</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$aggdisplay</td><td>N/A</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT author, SUM(postvorp) / SUM(posts) * 1000000 as pvorp FROM $dbUsersTable GROUP BY author HAVING sum(posts) > 1000 ORDER BY pvorp DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

$postdisplay = sprintf("%.5f", $recordHash->{'pvorp'});

print "<tr><td>Most efficient poster, career to date (1000 posts minimum)</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$postdisplay</td><td>N/A</td></tr>\n";

$recordQuery = $dbh->prepare("SELECT author, SUM(startvorp) / SUM(posts) * 1000000 as svorp FROM $dbUsersTable GROUP BY author HAVING sum(posts) > 1000 ORDER BY svorp DESC LIMIT 1");
$recordQuery->execute();
$recordHash = $recordQuery->fetchrow_hashref();

$startdisplay = sprintf("%.5f", $recordHash->{'svorp'});

print "<tr><td>Most efficient thread starter, career to date (1000 posts minimum)</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$startdisplay</td><td>N/A</td></tr>\n";


print "</tbody>\n";
print "</table>\n";
print "               </div>\n";
print "           </div>\n";


print "			<div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";  
print "<h2> </h2>\n";         
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Legendary Threads</h4>\n";
print "</div>\n";
print "            </div>\n";
print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Rank</th>";
print "      <th class=\"text-left\">Title</th>";
print "      <th class=\"text-left\">Author</th>";
print "      <th class=\"text-left\">Posts</th>";
print "      <th class=\"text-left\">Date</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody class=\"text-left\">";


$leaderboardAllTimeSQL = "SELECT root_post_id, COUNT(*) as pst from ishdata where root_post_id <> 0 and root_post_id not in (select post_id from gamethreads) GROUP BY root_post_id ORDER BY Count(*) DESC LIMIT 20";
$leaderboardAllTimeQuery = $dbh->prepare($leaderboardAllTimeSQL);
$leaderboardAllTimeQuery->execute();

$rankcounter = 1;

while (my $leaderboardAllTimeHash = $leaderboardAllTimeQuery->fetchrow_hashref()) {

	$recordQuery = $dbh->prepare("SELECT author, title, post_time FROM ishdata WHERE post_id = $leaderboardAllTimeHash->{'root_post_id'} LIMIT 1");
	$recordQuery->execute();
	$recordHash = $recordQuery->fetchrow_hashref();
	
	@longDate = split(/ /, $recordHash->{'post_time'});
	$shortDate = $longDate[0];
	
	print "                    <tr>\n";
	print "                          <td>$rankcounter</td><td>$recordHash->{'title'}</td><td><a href=\"./$recordHash->{'author'}.html\">$recordHash->{'author'}</a></td><td>$leaderboardAllTimeHash->{'pst'}</td><td>$shortDate</td>\n";
	print "                    </tr>\n";
	
	$rankcounter++;
}

print "</tbody>\n";
print "</table>\n";

print "                </div>\n";
print "            </div>\n";



print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print " <div class=\"panel panel-default\">\n";
print "   <div class=\"panel-body\">\n";
print "<h4>Friends Missing in Action</h4>\n";
print "</div>\n";
print "            </div>\n";

print "<table class=\"table table-striped table-hover \">";
print "  <thead>";
print "   <tr>";
print "      <th class=\"text-left\">Friend</th>";
print "      <th class=\"text-left\">Days</th>";
print "      <th class=\"text-left\">Final Words</th>";
print "      <th class=\"text-left\">Said To</th>";
print "    </tr>";
print "  </thead>";
print "  <tbody>";

my $miaQuery = $dbh->prepare("SELECT author, current_date - last_date AS numdays FROM lastpost WHERE last_date < NOW() - INTERVAL '14 days' AND post_total > 150 AND author <> 'tpfkatt' ORDER BY last_date");
$miaQuery->execute();


while (my $miaHash = $miaQuery->fetchrow_hashref()) {
	
	$miaAuthor = $miaHash->{'author'};
	$miaLastWords = $dbh->selectrow_array("SELECT title FROM $dbTable WHERE author = '$miaAuthor' order by post_time DESC LIMIT 1", undef, @params);
	$miaLastReply = $dbh->selectrow_array("SELECT reply_to_author FROM $dbTable WHERE author = '$miaAuthor' order by post_time DESC LIMIT 1", undef, @params);
	
	print "<tr $rowHighlight>";
	
	if ($miaLastReply) {
		print "<td class=\"text-left\"><a href=\"./$miaHash->{'author'}.html\">$miaHash->{'author'}</a></td><td class=\"text-left\">$miaHash->{'numdays'}</td><td class=\"text-left\">$miaLastWords</td><td class=\"text-left\"><a href=\"./$miaLastReply.html\">$miaLastReply</a></td>";
	}
	else {
		print "<td class=\"text-left\"><a href=\"./$miaHash->{'author'}.html\">$miaHash->{'author'}</a></td><td class=\"text-left\">$miaHash->{'numdays'}</td><td class=\"text-left\">$miaLastWords</td><td class=\"text-left\">OP</td>";
	}
	
	print "</tr>\n";
	
}

print "  </tbody>";
print "  </table>";

print "\n";
print "</div>\n";
print "            </div>\n";

            

print "          <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "<h1> </h1>\n";
print "</div>\n";
print "            </div>\n";			

	
print "        </div>\n";
print "</section>\n";


#end hall of shit section




printFooter();

#add graph data to bottom of document, this is after close

morrisGraphs();


sub morrisGraphs {
	
#yesterday hour graph

my @maxArray;
my @minArray;

$yesterdayYear = $yesterdayDate->year();
$yesterdayMonth = $yesterdayDate->month() - 1;
$yesterdayDay =  $yesterdayDate->day();

my $yesterdayDow = $yesterdayDate->day_of_week();

if ($yesterdayDow == 7) { $yesterdayDow = 0; }


for (my $i=0; $i < 24; $i++) {

	$hourMax = $dbh->selectrow_array("SELECT count(*) as maximum from (SELECT EXTRACT(HOUR FROM post_time) as hour, EXTRACT(DOW FROM post_time) as dayofweek, EXTRACT(doy FROM post_time) as daymonth from ishdata WHERE post_time >= '$monthDateString 00:00:00') subquery WHERE hour = $i AND dayofweek = $yesterdayDow GROUP BY daymonth order by maximum DESC LIMIT 1", undef, @params);
	$hourMin = $dbh->selectrow_array("SELECT count(*) as maximum from (SELECT EXTRACT(HOUR FROM post_time) as hour, EXTRACT(DOW FROM post_time) as dayofweek, EXTRACT(doy FROM post_time) as daymonth from ishdata WHERE post_time >= '$monthDateString 00:00:00') subquery WHERE hour = $i AND dayofweek = $yesterdayDow GROUP BY daymonth order by maximum ASC LIMIT 1", undef, @params);
	
	$maxArray[$i] = $hourMax;
	$minArray[$i] = $hourMin;
	
}

print "	<script type=\"text/javascript\">\n";
print "\$(function () {\n";

print "    var ranges = [\n";

for (my $i=0; $i < 24; $i++) {
	print "[Date.UTC($yesterdayYear, $yesterdayMonth, $yesterdayDay, $i, 00), $minArray[$i], $maxArray[$i]],\n";
	#print "['$i:00', $minArray[$i], $maxArray[$i]],\n";
}

print "        ],\n";
print "        averages = [\n";

for (my $i=0; $i < 24; $i++) {
	$yesterdayHour = $dbh->selectrow_array("SELECT count(*) from (SELECT EXTRACT(HOUR FROM post_time) as hour, EXTRACT(DOW FROM post_time) as dayofweek from ishdata WHERE post_time >= '$yesterdayDateString 00:00:00' AND post_time < '$todayDateString 00:00:00') subquery WHERE hour = $i", undef, @params);
	print "            [Date.UTC($yesterdayYear, $yesterdayMonth, $yesterdayDay, $i, 00), $yesterdayHour],\n";
}



print "        ];\n";


print "   \$('#dailyposts').highcharts({\n";

print "        title: {\n";
print "            text: 'Posts Per Hour Yesterday vs. Last 30 Days Min and Max'\n";
print "        },\n";

print "        xAxis: {\n";
print "            type: 'datetime',\n";
print "        },\n";

print "       yAxis: {\n";
print "            title: {\n";
print "                text: null\n";
print "            }\n";
print "        },\n";

print "        tooltip: {\n";
print "            crosshairs: true,\n";
print "            shared: true,\n";
print "            valueSuffix: 'posts'\n";
print "        },\n";

print "        legend: {\n";
print "        },\n";

print "        series: [{\n";
print "            name: 'Yesterday Posts',\n";
print "            data: averages,\n";
print "            zIndex: 1,\n";
print "            marker: {\n";
print "                fillColor: 'white',\n";
print "                lineWidth: 2,\n";
print "                lineColor: Highcharts.getOptions().colors[0]\n";
print "            }\n";
print "        }, {\n";
print "            name: '30 Day Range',\n";
print "            data: ranges,\n";
print "            type: 'arearange',\n";
print "            lineWidth: 0,\n";
print "            linkedTo: ':previous',\n";
print "            color: Highcharts.getOptions().colors[0],\n";
print "            fillOpacity: 0.3,\n";
print "            zIndex: 0\n";
print "        }]\n";
print "    });\n";
print "});\n";
print "</script>\n";

	
	#mixed ytd anger and volume
	
$graphPostsQuery = $dbh->prepare("SELECT user_day, SUM(posts) AS pst, SUM(total_depth) as deep FROM $dbUsersTable GROUP BY user_day ORDER BY user_day");
$graphPostsQuery->execute();

$arrayCounter = 0;
$runningAverage = 21;
$angerAverage = 7;
	
my @graphDates;
my @graphAnger;
my @graphPosts;
	
while (my $datePostsHash = $graphPostsQuery->fetchrow_hashref()) {

		$ishDate = $datePostsHash->{'user_day'};
		$ishPosts = $datePostsHash->{'pst'};
		$ishDepth = $datePostsHash->{'deep'};
		
		if ($ishPosts) {
			$ishAnger = sprintf("%.2f", 500 * ($ishDepth / $ishPosts));
		} else {
			$ishAnger = 0;
		}
	
		push @graphDates, $ishDate;
		push @graphAnger, $ishAnger;
		push @graphPosts, $ishPosts;
		

		$arrayCounter++;
}	
	
print "<script type=\"text/javascript\">\n";
print "\$(function () {\n";
print "    \$('#allday').highcharts({\n";
print "        title: {\n";
print "            text: 'All Time Number of Posts By Day',\n";
print "            x: -20 //center\n";
print "        },\n";
print "        xAxis: {\n";
print "            type: 'datetime'\n";
print "        },\n";
print "        yAxis: {\n";
print "            title: {\n";
print "                text: 'Number of Posts Per Day'\n";
print "            },\n";
print "            plotLines: [{\n";
print "                value: 0,\n";
print "                width: 1,\n";
print "                color: '#808080'\n";
print "            }]\n";
print "        },\n";
print "        tooltip: {\n";
print "            valueSuffix: ''\n";
print "        },\n";
print "        legend: {\n";
print "            layout: 'vertical',\n";
print "            align: 'right',\n";
print "            verticalAlign: 'middle',\n";
print "            borderWidth: 0\n";
print "       },\n";
print "        series: [\n";
print "        {\n";
print "            name: 'Posts',\n";
print "            data: [";

for (my $i=0; $i < $arrayCounter; $i++) {
	
		@dateArray = split('-', $graphDates[$i]);
		$dayMinus = $dateArray[1] - 1;
	
	
		print "[Date.UTC($dateArray[0], $dayMinus, $dateArray[2]), @graphPosts[$i]], ";
	
	}
	
print "]\n";

print "}, {\n";

print "            name: 'Moving Average',\n";
print "            data: [";

my $sum = 0;
for my $p (0..$#graphDates) {
	
		@dateArray = split('-', $graphDates[$p]);
		$dayMinus = $dateArray[1] - 1;
		
		
   		$sum += $graphPosts[$p];
   		$sum -= $graphPosts[$p - $runningAverage] if $p >= $runningAverage;
   		
   		if ($p >= $runningAverage - 1) {
   		
   			$rAvg = int($sum / $runningAverage);
   			print "[Date.UTC($dateArray[0], $dayMinus, $dateArray[2]), $rAvg], ";
   		
   		}
   			
		
	
	}

print "]\n";

print "}, {\n";

print "            name: 'Weekly Depth Index',\n";
print "            data: [";

my $sum = 0;
for my $p (0..$#graphDates) {
	
		@dateArray = split('-', $graphDates[$p]);
		$dayMinus = $dateArray[1] - 1;
		
		
   		$sum += $graphAnger[$p];
   		$sum -= $graphAnger[$p - $angerAverage] if $p >= $angerAverage;
   		
   		if ($p >= $angerAverage - 1) {
   		
   			$aAvg = int($sum / $angerAverage);
   			print "[Date.UTC($dateArray[0], $dayMinus, $dateArray[2]), $aAvg], ";
   		
   		}
   			
		
	
	}

print "]\n";

print "        }]\n";
print "    });\n";
print "});\n";
print "</script>\n";
	
# pie chart	
	
print "	<script type=\"text/javascript\">\n";
print "		\$(function () {\n";

print "    // Build the chart\n";
print "    \$('#pie').highcharts({\n";
print "        chart: {\n";
print "            backgroundColor: 'rgba(255, 255, 255, 0)',\n";
print "            plotBorderWidth: null,\n";
print "            plotShadow: false\n";
print "        },\n";
print "        title: {\n";
print "            text: 'Distribution of Top Volume Posters for the Day'\n";
print "        },\n";
print "        tooltip: {\n";
print "            pointFormat: '{series.name}: <b>{point.y} posts</b>'\n";
print "        },\n";
print "        plotOptions: {\n";
print "            pie: {\n";
print "                allowPointSelect: true,\n";
print "                cursor: 'pointer',\n";
print "                dataLabels: {\n";
print "                    enabled: true,\n";
print "                    format: '<b>{point.name}</b>: {point.percentage:.1f} %',\n";
print "                    style: {\n";
print "                        color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'\n";
print "                    }\n";
print "                }\n";
print "            }\n";
print "        },\n";
	
	$pieTotal = 0;
	
	$piePostsQuery = $dbh->prepare("SELECT author, Count(*) as cnt FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' GROUP BY author ORDER BY Count(*) DESC LIMIT 25");
	$piePostsQuery->execute();
	
	print "series: [{\n";
	print "type: 'pie',\n";
    print "name: 'Poster',\n";
    print "data: [\n";
	
	while (my $piePostsHash = $piePostsQuery->fetchrow_hashref()) {
	
		$pieAuthor = $piePostsHash->{'author'};
		$pieCount = $piePostsHash->{'cnt'};
		
		#$piePct = 100 * sprintf("%.4f", $pieCount / $dayCount);
		
		print "['$pieAuthor', $pieCount],\n";
	
		$pieTotal = $pieTotal + $pieCount;
	
	}
	
	$pieTotal = $dayCount - $pieTotal;
	print "['All Other', $pieTotal]\n";
	
	print "]\n";
	
	
	print "}]\n";
	print "});\n";
	print "});\n";
	print "</script>\n";
	
	
	
# posts per hour gauge
print "<script type=\"text/javascript\">\n";
print '	$(function () {';
print "	\n    var gaugeOptions = {\n";

print "	        chart: {\n";
print "	         type: 'solidgauge',\n";
print " backgroundColor: 'rgba(0, 0, 0, 0)'\n";

print "	        },\n";

print "	        title: null,\n";

print "	        pane: {\n";
print "	            startAngle: -170,\n";
print "	            endAngle: 170,\n";
print "             spacingTop: 0,\n";
print "           spacingLeft: 0,\n";
print "            spacingRight: 0,\n";
print "            spacingBottom: 0,\n";
print "	            background: {\n";
#print "	                backgroundColor: (Highcharts.theme && Highcharts.theme.background2) || '#EEE',\n";
print " backgroundColor: 'rgba(0, 0, 0, 0)',\n";
print "	                innerRadius: '60%',\n";
print "	                outerRadius: '100%',\n";
print "	                shape: 'arc'\n";
print "	            }\n";
print "	        },\n";

print "	        tooltip: {\n";
print "	            enabled: false\n";
print "	        },\n";

print "	        // the value axis\n";
print "	        yAxis: {\n";
print "	            stops: [\n";
print "	                [0.1, '#55BF3B'], // green\n";
print "	                [0.5, '#DDDF0D'], // yellow\n";
print "	                [0.9, '#DF5353'] // red\n";
print "	            ],\n";
print "	            lineWidth: 0,\n";
print "	            minorTickInterval: null,\n";
print "	            tickPixelInterval: 400,\n";
print "	            tickWidth: 0,\n";
print "	            title: {\n";
print "	                y: -70\n";
print "	            },\n";
print "	            labels: {\n";
print "	                y: 16\n";
print "	            }\n";
print "	        },\n";

print "	        plotOptions: {\n";
print "	            solidgauge: {\n";
print "	                dataLabels: {\n";
print "	                    y: 5,\n";
print "	                    borderWidth: 0,\n";
print "	                    useHTML: true\n";
print "	                }\n";
print "	            }\n";
print "	        }\n";
print "	    };\n";
print "	    // The posts gauge\n";
print "	    \$('#container-postshour').highcharts(Highcharts.merge(gaugeOptions, {\n";
print "	        yAxis: {\n";
print "                  showFirstLabel:false,\n";
print "                  	showLastLabel:false,\n";
print "                      labels: {step:2},\n";
print "	            min: 0,\n";
print "	            max: 200,\n";
print "	            title: {\n";
print "	                text: 'Posts Last Hour'\n";
print "	            }\n";
print "	        },\n";

print "	        credits: {\n";
print "	            enabled: false\n";
print "	        },\n";

print "	        series: [{\n";
print "	            name: 'Posts',\n";

print "	            data: [$hourCount],\n";

print "	            dataLabels: {\n";
print "	                format: '<div style=\"text-align:center\"><span style=\"font-size:25px;color:' +\n";
print "	                    ((Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black') + '\">{y}</span><br/>' +\n";
print "	                       '<span style=\"font-size:12px;color:silver\">posts</span></div>'\n";
print "	            },\n";
print "	            tooltip: {\n";
print "	                valueSuffix: ' posts'\n";
print "	            }\n";
print "	        }]\n";

print "	    }));\n";

print "	    // The posts today gauge\n";
print "	    \$('#container-postsday').highcharts(Highcharts.merge(gaugeOptions, {\n";
print "	        yAxis: {\n";
print "                  showFirstLabel:false,\n";
print "                  	showLastLabel:false,\n";
print "                      labels: {step:2},\n";
print "	            min: 0,\n";
print "	            max: 2500,\n";
print "	            title: {\n";
print "	                text: 'Posts Today'\n";
print "	            }\n";
print "	        },\n";

print "	        credits: {\n";
print "	            enabled: false\n";
print "	        },\n";

print "	        series: [{\n";
print "	            name: 'Posts',\n";

print "	            data: [$dayCount],\n";

print "	            dataLabels: {\n";
print "	                format: '<div style=\"text-align:center\"><span style=\"font-size:25px;color:' +\n";
print "	                    ((Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black') + '\">{y}</span><br/>' +\n";
print "	                       '<span style=\"font-size:12px;color:silver\">posts</span></div>'\n";
print "	            },\n";
print "	            tooltip: {\n";
print "	                valueSuffix: ' posts'\n";
print "	            }\n";
print "	        }]\n";

print "	    }));\n";


print "	    // The depth gauge\n";
print "	    \$('#container-postsdepth').highcharts(Highcharts.merge(gaugeOptions, {\n";
print "	        yAxis: {\n";
print "                  showFirstLabel:false,\n";
print "                  	showLastLabel:false,\n";
print "                      labels: {step:2},\n";
print "	            min: 0,\n";
print "	            max: 5.5,\n";
print "	            title: {\n";
print "	                text: 'Depth'\n";
print "	            }\n";
print "	        },\n";

print "	        credits: {\n";
print "	            enabled: false\n";
print "	        },\n";

print "	        series: [{\n";
print "	            name: 'Depth',\n";

print "	            data: [$dayDepthAvg],\n";

print "	            dataLabels: {\n";
print "	                format: '<div style=\"text-align:center\"><span style=\"font-size:25px;color:' +\n";
print "	                    ((Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black') + '\">{y}</span><br/>' +\n";
print "	                       '<span style=\"font-size:12px;color:silver\">Depth</span></div>'\n";
print "	            },\n";
print "	            tooltip: {\n";
print "	                valueSuffix: ' depth'\n";
print "	            }\n";
print "	        }]\n";

print "	    }));\n";
       
print "	});\n";
print "</script>\n";

# WEEKLY HEAT MAP

print "<script type=\"text/javascript\">\n";

print "\$(function () {\n";

print "    \$('#weeklyheatmap').highcharts({\n";

print "        chart: {\n";
print "            type: 'heatmap',\n";
print "            marginTop: 40,\n";
print "            marginBottom: 80,\n";
print " backgroundColor: 'rgba(0, 0, 0, 0)'\n";
print "        },\n";


print "        title: {\n";
print "            text: 'Posts Per Hour $weekDateString through $yesterdayDateString'\n";
print "        },\n";

print "        xAxis: {\n";
print "            categories: ['00:00', '01:00', '02:00', '03:00', '04:00', '05:00', '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00']\n";
print "        },\n";

print "        yAxis: {\n";
print "            categories: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],\n";
print "            title: null\n";
print "        },\n";

print "        colorAxis: {\n";
print "            min: 0,\n";
print "            minColor: '#FFFFFF',\n";
print "            maxColor: Highcharts.getOptions().colors[0]\n";
print "        },\n";

print "        legend: {\n";
print "            align: 'right',\n";
print "            layout: 'vertical',\n";
print "            margin: 0,\n";
print "            verticalAlign: 'top',\n";
print "            y: 25,\n";
print "            symbolHeight: 280\n";
print "        },\n";

print "        tooltip: {\n";
print "            formatter: function () {\n";
print "               return '<b>' + this.series.xAxis.categories[this.point.x] + '</b> had <br><b>' +\n";
print "                    this.point.value + '</b> on <br><b>' + this.series.yAxis.categories[this.point.y] + '</b>';\n";
print "            }\n";
print "        },\n";

print "        series: [{\n";
print "            name: 'Posts Per Hour and Day',\n";
print "            borderWidth: 1,\n";
print "            data: [";

$hourLoop = 24;
	
	for (my $i=0; $i < $hourLoop; $i++) {
	
	
		$dayLoop = 7;
		for (my $d=0; $d < $dayLoop; $d++) {
				$hourPosts = $dbh->selectrow_array("SELECT COUNT(*) from (SELECT EXTRACT(HOUR FROM post_time) as hour, EXTRACT(DOW FROM post_time) as dayofweek from ishdata WHERE post_time >= '$weekDateString 00:00:00' AND post_time <= '$yesterdayDateString 23:59:59') subquery WHERE hour = $i AND dayofweek = $d", undef, @params);
				print "[$i, $d, $hourPosts], ";
			}
		}	

print "],\n";
print "            dataLabels: {\n";
print "                enabled: true,\n";
print "                color: '#000000'\n";
print "            }\n";
print "        }]\n";

print "    });\n";
print "});\n";

print "</script>\n";

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


print '

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
	
print "\n\n<script>\n";
print "  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){\n";
print "  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),\n";
print "  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)\n";
print "  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');\n\n";

print "  ga('create', 'UA-59827132-1', 'auto');\n";
print "  ga('send', 'pageview');\n\n";

print "</script>\n\n";
	
print '

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
                </button>
                <a class="navbar-brand page-scroll" href="#page-top">shitposters.org</a>
            </div>

            <!-- Collect the nav links, forms, and other content for toggling -->
            <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
                <ul class="nav navbar-nav navbar-right">
                    <li class="hidden">
                        <a href="#page-top"></a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#services">Now</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#portfolio">Yesterday</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#about">Forever</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#team">Hall of Shit</a>
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

print '

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
	<script src="http://code.highcharts.com/highcharts-more.js"></script>
	<script type="text/javascript" src="http://www.highcharts.com/highslide/highslide-full.min.js"></script>
	<script type="text/javascript" src="http://www.highcharts.com/highslide/highslide.config.js" charset="utf-8"></script>
	<script type="text/javascript" src="http://code.highcharts.com/modules/heatmap.js"></script>
    <script type="text/javascript" src="http://code.highcharts.com/modules/exporting.js"></script>
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
