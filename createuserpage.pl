#!/usr/bin/perl

use DBI;
use DateTime;
use Config::Simple;



my $todayDate = DateTime->now(time_zone=>'local');
my $yesterdayDate = DateTime->now(time_zone=>'local')->subtract( days => 1 );
my $todayDateString = $todayDate->ymd;
my $yesterdayDateString = $yesterdayDate->ymd;

my $runTimeString = $todayDate->hms;

my $currentHour = $todayDate->hour;

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

$dayActiveID = $dbh->selectrow_array("SELECT root_post_id FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' GROUP BY root_post_id ORDER BY Count(*) DESC LIMIT 1", undef, @params);

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


$ishMoodDay = "pretty average";
$ishMoodHour = "pretty average";
$ishMoodBlurb = "Things are pretty typical so far";
	
if ($dayDepthAvg < 2.5 ) {
	$ishMoodDay = "relatively good";
	$ishMoodBlurb = "Wade in with confidence";
}

if ($dayDepthAvg > 3.5 ) {
	$ishMoodDay = "rather shitty";
	$ishMoodBlurb = "Someone is probably looking to rip your dick off";
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


	


#print "$hourQuote\n";
#print "$hourCount posts last hour and is in a $ishMoodHour ($hourDepthAvg) mood.\n";
#print "\"$hourActiveTitle\" by $hourActiveAuthor\n";
#print "There have been $dayCount posts since midnight on the ish. Based on the patterns of posting, the ish appears to be in a $ishMoodDay mood for the day. ";
#print " The most active topic has been \"$dayActiveTitle\" by $dayActiveAuthor. The most posts so far today are by $dayActivePoster ($dayActivePosterNumber).\n";

#end printing summary section


#graph section needs to go here

print "<section id=\"portfolio\" class=\"bg-light-gray\">\n";
print "        <div class=\"container\">\n";
print "            <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "                 <h2 class=\"section-heading\">All-Time Shitposters</h2>\n";
print "                 <h3 class=\"section-subheading text-muted\">All the shitposters that ever were, ranked in order of Value Over Replacement Poster efficiency. Must have 250 posts or more to appear.</h3>\n";
print "					<p class=\"text-muted\"><b>The top shitposters of all time:</b></p>\n";
print "<table class=\" table table-striped table-hover\">\n";
print "<tr>\n";
print "<td><b>Rank</b></td><td><b>Poster</b></td><td><b>Posts</b></td><td><b>Thread Starts</b></td><td><b>Replied To</b></td><td><b>Agg Class</b></td><td><b>Agg Rate</b></td><td><b>VORP</b></td><td><b>Efficiency</b></td>\n";
print "</tr>\n";

$leaderboardAllTimeSQL = "SELECT author, sum(threads_started) as starts, sum(posts) as pst, SUM(replied_to) as replies, SUM(total_depth) / (SUM(posts) + 1)  as depth, SUM(aggressionvorp) / SUM(posts) * -1000000 as agg, SUM(totalvorp) AS vorp, SUM(totalvorp) / SUM(posts) as eff FROM $dbUsersTable GROUP BY author HAVING SUM(posts) > 250 ORDER BY SUM(totalvorp) / SUM(posts) DESC";
$leaderboardAllTimeQuery = $dbh->prepare($leaderboardAllTimeSQL);
$leaderboardAllTimeQuery->execute();

$rankcounter = 1;

while (my $leaderboardAllTimeHash = $leaderboardAllTimeQuery->fetchrow_hashref()) {


	$startVORP = sprintf("%.4f", $leaderboardAllTimeHash->{'startvorp'});
	$eff = sprintf("%.5f", $leaderboardAllTimeHash->{'eff'});
	$tVORP = sprintf("%.5f", $leaderboardAllTimeHash->{'vorp'});
	$aggdisplay = sprintf("%.5f", $leaderboardAllTimeHash->{'agg'});
	
	print "                    <tr>\n";
	print "                          <td>$rankcounter</td><td><a href=\"./$leaderboardAllTimeHash->{'author'}.html\">$leaderboardAllTimeHash->{'author'}</a></td><td>$leaderboardAllTimeHash->{'pst'}</td><td>$leaderboardAllTimeHash->{'starts'}</td><td>$leaderboardAllTimeHash->{'replies'}</td><td>$leaderboardAllTimeHash->{'depth'}</td><td>$aggdisplay</td><td>$tVORP</td><td>$eff</td>\n";
	print "                    </tr>\n";
	
	$rankcounter++;
}

print "</table>\n";
print "               </div>\n";
print "           </div>\n";

print "        </div>\n";
print "    </section>\n";


#end of graph insertion

#start of leaderboard

print "<section id=\"about\">\n";
print "        <div class=\"container\">\n";
print "            <div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
print "                    <h2 class=\"section-heading\">Yesterday's Shitposters</h2>\n";
print "                    <h3 class=\"section-subheading text-muted\">Here's the ranking of what everyone spewed all over the ish yesterday.</h3>\n";



print "					<p class=\"text-muted\"><b>Yesterday's rank of posters, ordered by number of posts:</b></p>\n";

print "<table class=\" table table-striped table-hover\">\n";
print "<tr>\n";
print "<td><b>Rank</b></td><td><b>Poster</b></td><td><b>Posts</b></td><td><b>Thread Starts</b></td><td><b>Replied To</b></td><td><b>Agg Class</b></td><td><b>Agg Rate</b></td><td><b>VORP</b></td><td><b>Efficiency</b></td>\n";
print "</tr>\n";
$leaderboardAllTimeSQL = "SELECT author, sum(threads_started) as starts, sum(posts) as pst, SUM(replied_to) as replies, SUM(total_depth) / (SUM(posts) + 1)  as depth, SUM(startvorp) as startvorp, SUM(aggressionvorp) / SUM(posts) * -1000000 as agg, SUM(totalvorp) AS vorp, SUM(totalvorp) / SUM(posts) as eff FROM $dbUsersTable WHERE user_day = '$yesterdayDateString' GROUP BY author HAVING SUM(posts) > 0 ORDER BY SUM(posts) DESC";
$leaderboardAllTimeQuery = $dbh->prepare($leaderboardAllTimeSQL);
$leaderboardAllTimeQuery->execute();

$rankcounter = 1;

while (my $leaderboardAllTimeHash = $leaderboardAllTimeQuery->fetchrow_hashref()) {
	
	$eff = sprintf("%.5f", $leaderboardAllTimeHash->{'eff'});
	$startVORP = sprintf("%.4f", $leaderboardAllTimeHash->{'startvorp'});
	$aggdisplay = sprintf("%.5f", $leaderboardAllTimeHash->{'agg'});
	print "                    <tr>\n";
	print "                          <td>$rankcounter</td><td><a href=\"./$leaderboardAllTimeHash->{'author'}.html\">$leaderboardAllTimeHash->{'author'}</a></td><td>$leaderboardAllTimeHash->{'pst'}</td><td>$leaderboardAllTimeHash->{'starts'}</td><td>$leaderboardAllTimeHash->{'replies'}</td><td>$leaderboardAllTimeHash->{'depth'}</td><td>$aggdisplay</td><td>$leaderboardAllTimeHash->{'vorp'}</td><td>$eff</td>\n";
	print "                    </tr>\n";
	
	$rankcounter++;
}

print "</table>\n";


print "</div>\n";
print "            </div>\n";
			
print "			<div class=\"row\">\n";
print "                <div class=\"col-lg-12 text-center\">\n";
                
print "					<p class=\"text-muted\">The ishVORP is calculated on a weighted analysis of various characteristics of each post, including aggression factors, response factors and whether or not the person starts shitty threads. It is updated each day after midnight and is aggregate for the data set.</p>\n";
print "                </div>\n";
print "            </div>\n";
            
print "        </div>\n";
print "</section>\n";



#end leaderboard section

#start hall of shit section



#end hall of shit section




printFooter();

#add graph data to bottom of document, this is after close

#morrisGraphs();


sub morrisGraphs {
	
	$findTotalAveragesQuery = $dbh->prepare("SELECT MIN(totalsum) as min, MAX(totalsum) as max, AVG(totalsum) as avg from (select SUM(total_depth) as totalsum from usertotals group by user_day) ss");
	$findTotalAveragesQuery->execute();
	$totalAveragesHash = $findTotalAveragesQuery->fetchrow_hashref();
	
	$averageDepth = $totalAveragesHash->{'avg'};
	
	$alltimeDepthAverage = sprintf("%.2f", $alltimeDepth / $alltimeCount);
	
	
	
	$graphPostsQuery = $dbh->prepare("SELECT user_day, SUM(posts) AS pst, SUM(total_depth) as deep FROM $dbUsersTable GROUP BY user_day ORDER BY user_day");
	$graphPostsQuery->execute();

	print "<script>\n";
	print "Morris.Line({\n";
	print "element: 'monthly-chart',\n";
	print "data: [\n";
	
	
	while (my $datePostsHash = $graphPostsQuery->fetchrow_hashref()) {

		$ishDate = $datePostsHash->{'user_day'};
		$ishPosts = $datePostsHash->{'pst'};
		$ishDepth = $datePostsHash->{'deep'};
		
		if ($ishPosts) {
			$ishAnger = 1000 * sprintf("%.2f", ($ishDepth / $ishPosts) / $alltimeDepthAverage);
		} else {
			$ishAnger = 0;
		}
	
		
		print "{ y: '$ishDate', a: $ishPosts, b: $ishAnger },\n";

	}
	
	
	$dayAnger = 1000 * sprintf("%.2f", ($dayDepthAvg / $alltimeDepthAverage));

	
	print "{ y: '$todayDateString', a: $dayCount, b: $dayAnger },\n";
	
	print "],\n";
	print "xkey: 'y',\n";
	print "ykeys: ['a', 'b'],\n";
	print "labels: ['posts', 'anger index'],\n";
	print "xLabels: 'day',\n";
	print "resize: true,\n";
	print "xLabelAngle: 30\n";
	print "})\;\n";
	print "</script>\n";
	
	
	$randomPostsQuery = $dbh->prepare("SELECT user_day, SUM(posts) AS pst, SUM(total_depth) as deep FROM $dbUsersTable WHERE author = '$dayRandomPoster' GROUP BY user_day ORDER BY user_day");
	$randomPostsQuery->execute();
	
	
	print "<script>\n";
	print "Morris.Line({\n";
	print "element: 'random-chart',\n";
	print "data: [\n";
	
	while (my $randomPostsHash = $randomPostsQuery->fetchrow_hashref()) {

		$ishDate = $randomPostsHash->{'user_day'};
		$ishPosts = $randomPostsHash->{'pst'};
		$ishDepth = $randomPostsHash->{'deep'};
		$ishVORP = $randomPostsHash->{'totalvorp'};
		
		if ($ishPosts) {
			$ishAnger = 100 * sprintf("%.2f", ($ishDepth / $ishPosts) / $alltimeDepthAverage);
		} else {
			$ishAnger = 0;
		}
		
		print "{ y: '$ishDate', a: $ishPosts, b: $ishAnger },\n";

	}
	
	$randomPosterTodayPosts = $dbh->selectrow_array("SELECT COUNT(*) FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' AND author ='$dayRandomPoster'", undef, @params);
	$randomPosterTodayDepth = $dbh->selectrow_array("SELECT SUM(post_depth) FROM $dbTable WHERE post_time >= '$todayDateString 00:00:00' AND author ='$dayRandomPoster'", undef, @params);
	
	if ($randomPosterTodayPosts) {
			$ishAnger = 100 * sprintf("%.2f", ($randomPosterTodayDepth / $randomPosterTodayPosts) / $alltimeDepthAverage);
		} else {
			$ishAnger = 0;
		}
	
	print "{ y: '$todayDateString', a: $randomPosterTodayPosts, b: $ishAnger },\n";
	
	print "],\n";
	print "xkey: 'y',\n";
	print "ykeys: ['a', 'b'],\n";
	print "labels: ['$dayRandomPoster posts', '$dayRandomPoster anger index'],\n";
	print "xLabels: 'day',\n";
	print "resize: true,\n";
	print "xLabelAngle: 30\n";
	print "})\;\n";
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
    <link href="css/user.css" rel="stylesheet">

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
                <a class="navbar-brand page-scroll" href="#page-top">shitposters.org users</a>
            </div>

            <!-- Collect the nav links, forms, and other content for toggling -->
            <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
                <ul class="nav navbar-nav navbar-right">
                    <li class="hidden">
                        <a href="#page-top"></a>
                    </li>                    
                    <li>
                        <a class="page-scroll" href="#portfolio">All-Time Shitposters</a>
                    </li>
                    <li>
                        <a class="page-scroll" href="#about">Yesterday\'s Shit</a>
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

    <!-- Header -->
    <header>
        <div class="container">
            <div class="intro-text">
                <div class="intro-lead-in">We are all sick of your shit and you should be ashamed</div>
                <div class="intro-heading">SHITPOSTERS.ORG</div>
                <a href="#portfolio" class="page-scroll btn btn-xl">MORE</a>
            </div>
        </div>
    </header>
	
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

    <!-- Bootstrap Core JavaScript -->
    <script src="js/bootstrap.min.js"></script>

    <!-- Plugin JavaScript -->
    <script src="http://cdnjs.cloudflare.com/ajax/libs/jquery-easing/1.3/jquery.easing.min.js"></script>
    <script src="js/classie.js"></script>
    <script src="js/cbpAnimatedHeader.js"></script>

    <!-- Contact Form JavaScript -->
    <script src="js/jqBootstrapValidation.js"></script>
    <script src="js/contact_me.js"></script>

    <!-- Custom Theme JavaScript -->
    <script src="js/agency.js"></script>
	
	<script src="//cdnjs.cloudflare.com/ajax/libs/raphael/2.1.0/raphael-min.js"></script>
	<script src="//cdnjs.cloudflare.com/ajax/libs/morris.js/0.5.1/morris.min.js"></script>
	


</body>

</html>

';




}
