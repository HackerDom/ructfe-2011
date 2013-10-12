#!/usr/bin/perl -lw
# TODO: Global timeout => CORRUPT
use strict;
#use diagnostics;
use IO::Socket;
require LWP::UserAgent;
use IO::Zlib;

sub RESULT_OK      {101}
sub RESULT_NOFLAG  {102}
sub RESULT_CORRUPT {103}
sub RESULT_DOWN    {104}                               
sub RESULT_ERROR   {110}

my $JURY_ADDRESS = '10.23.201.17';
my $SECRET_KEY = 'aSGRTUdsgdfj55457uyjdSFBDYtdssdwe5yIDFGsdbsd;;sgasde##@!FOA';

$SIG{PIPE} = sub {warn "SIG_PIPE\n"; };

## TESITNG ##
if ($ARGV[0] eq 'forecast')
{
  print "Forecast";
  my @data = (1, 2, 3)x1000;
  @data = @{forecast(\@data)};
  $, = ' ';
  print @data;
  exit;
}                                                                          
##

###############################################################

my @agents = (
  "Ubuntu APT-HTTP/1.3 (0.7.23.1ubuntu2)",
  "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.215 Safari/535.1",
  "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/534.16 (KHTML, like Gecko) Chrome/10.0.648.205 Safari/534.16",
  "curl/7.19.5 (i586-pc-mingw32msvc) libcurl/7.19.5 OpenSSL/0.9.8l zlib/1.2.3",
  "Emacs-W3/4.0pre.46 URL/p4.0pre.46 (i686-pc-linux; X11)",
  "Mozilla/5.0 (X11; U; Linux i686; en-us) AppleWebKit/531.2+ (KHTML, like Gecko) Safari/531.2+ Epiphany/2.29.5",
  "Mozilla/5.0 (X11; U; Linux armv61; en-US; rv:1.9.1b2pre) Gecko/20081015 Fennec/1.0a1",
  "Mozilla/5.0 (Windows NT 7.0; Win64; x64; rv:3.0b2pre) Gecko/20110203 Firefox/4.0b12pre",
  "Mozilla/5.0 (X11; Linux i686; rv:6.0.2) Gecko/20100101 Firefox/6.0.2",
  "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:5.0) Gecko/20100101 Firefox/5.0",
  "Mozilla/5.0 (Linux; U; Android 1.1; en-gb; dream) AppleWebKit/525.10+ (KHTML, like Gecko) Version/3.0.4 Mobile Safari/523.12.2",
  "Mozilla/4.5 RPT-HTTPClient/0.3-2",
  "Mozilla/5.0 (compatible; Konqueror/4.0; Linux) KHTML/4.0.5 (like Gecko)",
  "Links (2.1pre31; Linux 2.6.21-omap1 armv6l; x)",
  "Lynx/2.8.5dev.16 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.6b",
  "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.1.9) Gecko/20100508 SeaMonkey/2.0.4",
  "Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)",
  "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)",
  "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; WOW64; Trident/5.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; .NET4.0E; InfoPath.3; Creative AutoUpdate v1.40.02)",
  "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; GTB6.4; .NET CLR 1.1.4322; FDM; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)",
  "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98; Rogers Hi·Speed Internet; (R1 1.3))",
  "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.12) Gecko/20080219 Firefox/2.0.0.12 Navigator/9.0.0.6",
  "Opera/9.80 (J2ME/MIDP; Opera Mini/4.2.13221/25.623; U; en) Presto/2.5.25 Version/10.54",
  "Opera/9.80 (J2ME/MIDP; Opera Mini/5.1.21214/19.916; U; en) Presto/2.5.25",
  "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; en-us) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27",
  "Wget/1.8.1"
);



my $ua = LWP::UserAgent->new;
$ua->agent($agents[int rand @agents]);
$ua->timeout(15);

my %MODES = (check => \&check, get => \&get, put => \&put);

my $mode = shift or do
{
	warn "Arguments error: no 'mode'\n";
	exit RESULT_ERROR;
};

my $ip = shift or do
{
	warn "Arguments error: no 'ip'\n";
	exit RESULT_ERROR;
};

exists $MODES{$mode} or do
{
	warn "Arguments error: unknown 'mode'\n";
	exit RESULT_ERROR;
};

$MODES{$mode}->(@ARGV);
exit RESULT_ERROR;

#############################################################################

sub teamNumber
{
  my @ip = split '\.', $ip;
  # TODO!!!
  return int($ip[2]);
}

sub createLastFile
{
  my $team = shift;
  my $filename = "last$team.txt";
  open F, ">$filename";
  print F "100 20 5 60";
  close F;
}

sub createTime
{
  my $team = shift;
  open F, ">time$team.txt";
  print F time() - 2300;
  close F;
}

sub getLast
{
  my $team = shift;
  my $filename = "last$team.txt";
  createLastFile $team unless -f $filename;
  open F, $filename;
  local $/ = ' ';
  my @last = <F>;
  close F;
  return @last;
}

sub saveLast
{
  my ($team, $last) = @_;
  open F, ">last$team.txt";
  local $, = ' ';
  print F @$last;
  close F;
}

sub getTime
{
  my $team = shift;
  createTime $team unless -f "time$team.txt";
  open F, "time$team.txt";
  my $time = <F>;
  close F;
  chomp($time);
  return $time;
}

sub saveTime
{
  my ($team, $time) = @_;
  open F, ">time$team.txt";
  print F $time;
  close F;
}

sub generate
{
  my ($OUT, $DATA, $count, $author, $comment, $timeStart) = @_;
  local ($\, $,) = ("\n", ' ');
  print $OUT "T P Wind Humidity $author $comment";
  my $time = 0;
  my @last = getLast(teamNumber());
  for (0..$count - 1)
  {
    my @new = map {$_ + rand() * .02 - .01} @last;
    print $OUT $time, @new;
    print $DATA $timeStart + $time, $new[0];
    @last = @new;
    $time++;
  }       
  return \@last;
}

sub sendData
{
  my ($ip, $team, $time, $secret) = @_;
  my $socket = IO::Socket::INET->new(PeerAddr => $ip,
                                     PeerPort => 3300,
                                     Proto    => "tcp",
                                     Type     => SOCK_STREAM,
                                     TimeOut  => 15)
  or do
  {
    warn "Couldn't connect to 3300\n";
    print "Couldn't connect to 3300";
    exit RESULT_DOWN;
  };
  print $socket "add";
  print $socket "$time"; 
  print $socket "$secret"; 
  my $size = -s "tmp$team.txt.gz";
  my $packSize = pack 'L', $size;

  warn "Size " .$size."\n";

  binmode $socket;
  {
    local $\;
    print $socket $packSize;
    warn "Sent size\n";
    open F, "tmp$team.txt.gz";
    binmode F;
    local $/;
    my $data = <F>;
    warn "Sending...\n";
    print $socket $data or do
    {
        warn "Error\n";
    };
    warn "Sent data\n";
  }
  close F;

  print $socket "quit";

  my $ans;
  warn "Reading\n";
  for (0..4)
  {
    $ans = <$socket>;
    warn $ans;
  }
  if ($ans =~ /Invalid/)
  {
    warn "Invalid secret\n";
    exit RESULT_CORRUPT;
  }

  shutdown $socket, 2;
  close $socket;

}

sub getSecret($)
{
  my $team = shift;
  my $socket = IO::Socket::INET->new(PeerAddr => $JURY_ADDRESS,
                                     PeerPort => 4444,
                                     Proto    => "tcp",
                                     Type     => SOCK_STREAM,
                                     TimeOut  => 15) or do
  {
    print "Jury Server is unavailable";
    exit RESULT_DOWN;
  };

  local $\ = $/;
  print $socket $SECRET_KEY;
  print $socket "pass $team";
  my $pass = <$socket>;
  $pass =~ s/(^\s+)|(\s+$)//g;
  $socket->close();
  return $pass;
}

sub getStatus($)
{
  my $team = shift;
  my $socket = IO::Socket::INET->new(PeerAddr => $JURY_ADDRESS,
                                     PeerPort => 4444,
                                     Proto    => "tcp",
                                     Type     => SOCK_STREAM,
                                     TimeOut  => 15)
  or do
  {
    print STDOUT "Can't connect to 4444";
    exit RESULT_DOWN;
  };

  local $\ = $/;
  print $socket $SECRET_KEY;
  print $socket "status $team";
  my $status = <$socket>;
  $status =~ s/(^\s+)|(\s+$)//g;
  $socket->close();
  return $status;
}  

sub forecast
{
  local ($,, $\) = (' ', $/);
  my @data = @{shift()};
  my $n = 1000;
  my $len = @data;
  warn "Len = $len\n";
  my @sum = (0) x ($len - $n + 1);
  $sum[0] += $data[$_] for 0..$n-1;
  $sum[$_] = $sum[$_ - 1] - $data[$_ - 1] + $data[$_ + $n - 1] for 1..($len - $n);

  my @delta = ();
  $delta[$_] = ($sum[$_ + 1] - $sum[$_]) / $n for 0..($len - $n - 1);

  my @w = ();
  $w[$_] = (-1) ** ($len - $n - $_ - 1) * 1 / ($len - $n - $_) / log(2) for 0..($len - $n - 1);

  for my $idx ($len..$len + 99)
  {
    my $deltanew = 0;
    for (0..($len - $n - 1))
    {
      $deltanew += $w[$_] * $delta[$_];
    }
    #print $deltanew;
    my $meansnew = $sum[$#sum] / $n + $deltanew;
    #xnew <- meansnew * n - sum(x[(length(x) - n + 2) : length(x)])

    my $sumlast = 0;
    for ($idx - $n + 1..$idx - 1)
    {
      $sumlast += $data[$_];
    }

    my $xnew = $meansnew * $n - $sumlast;
    push @data, $xnew;
    push @sum, $meansnew * $n;
    shift @sum;
    push @delta, $deltanew;
    shift @delta;
  }

  return \@data;
}

sub getData($$$)
{
  my ($team, $startTime, $finishTime) = @_;
  open F, "data/$team.txt" or do
  {
    open F, ">data/$team.txt";
    close F;
    open F, "data/$team.txt";
  };
  my @a = <F>;
  close F;
  my @ans = ();
  foreach (@a)
  {
    my ($time, $value) = split ' ';
    push @ans, $value if $time >= $startTime && $time <= $finishTime;
  }
  return \@ans;
}

#############################################################################

sub check
{
  #exit RESULT_OK;
  warn "debug: check $ip\n";
  my $try = 0;
  my $response;
  while (1)
  {
  	$response = $ua->get("http://$ip:8000/");
	  if (!$response->is_success)
    { 
      if ($try == 2)
      {
  	   	warn "check failed: ", $response->status_line, $/;
  	   	exit RESULT_DOWN;
      }
      ++$try;
  	}
    else
    {
      last;
    }
  }
  my $content = $response->content;
  exit RESULT_CORRUPT unless $content =~ /Time on server/;
  exit RESULT_CORRUPT unless $content =~ /Data for last time/;
  exit RESULT_CORRUPT unless $content =~ /andgein, RuCTFE 2011/;

  $response = $ua->get("http://$ip:8000/table");
	if (!$response->is_success)
  {
    print "Couldn't connect to 8000";
		warn "check failed: ", $response->status_line, $/;
		exit RESULT_DOWN;
	}
  $content = $response->content;
  exit RESULT_CORRUPT unless $content =~ /\<title\>Meteoros\<\/title\>/;
  exit RESULT_CORRUPT unless $content =~ /andgein, RuCTFE 2011/;
  exit RESULT_CORRUPT unless $content =~ /table/;

  my $socket = IO::Socket::INET->new(PeerAddr => $ip,
                                     PeerPort => 3300,
                                     Proto    => "tcp",
                                     Type     => SOCK_STREAM,
                                     TimeOut  => 15)
  or do
  {
    warn "Couldn't connect to 3300\n";
    print "Couldn't connect to 3300";
    exit RESULT_DOWN
  };
  print $socket "quit\n";
  my $ans = <$socket>;
  shutdown $socket, 2;
  close $socket;

  my $team = teamNumber($ip);
  my $status = getStatus($team);
  if ($status eq 'Fail')
  {
    print "http://$ip:8000/forecast<SECRET> works more than timeout or is down. See README in service";
    exit RESULT_DOWN;
  }

#  my ($time, $f) = split ' ', $status;
#  my @data = @{getData($team, $time - 100 - 4 * 60 * 60, $time - 100)};
#  if (@data == 0)
#  {
#    return RESULT_OK;
#  }
#  @data = @{forecast(\@data)};
#  local $\ = $/;
#  warn $data[$#data].' vs '.$f."\n";
#  if (abs($data[$#data] - $f) > 1)
#  {
#    print 'Wrong forecast';
#    exit RESULT_CORRUPT;
#  }

	exit RESULT_OK;
}

sub get
{
  #exit RESULT_OK;
  my ($id, $flag) = @ARGV;
	warn "debug: get $ip $id $flag\n";

	my $socket = IO::Socket::INET->new(PeerAddr => $ip,
                                     PeerPort => 3300,
                                     Proto    => "tcp",
                                     Type     => SOCK_STREAM,
                                     TimeOut  => 15)
  or do
  {
    warn "Couldn't connect to 3300\n";
    print "Couldn't connect to 3300";
    exit RESULT_DOWN
  };

	my $secret = getSecret(teamNumber($id));
	print $socket "view";
	print $socket $secret;
	print $socket $id;
        print $socket "quit";
 	warn "Sent `view` command\n";
	my $ans;
	my $ok = 0;
	for (0..6)
	{
		$ans = <$socket>;
		warn $ans;
		$ok = 1 if $ans =~ /$flag/;
		last if $ans =~ /command\:/ && $_ > 2;
	}
	if ($ok == 0)
	{
		print "Can't retrieve the flag";
		exit RESULT_NOFLAG;
	}

	exit RESULT_OK;
}

sub put
{
  #exit RESULT_OK;
  my ($id, $flag) = @ARGV;
	warn "debug: put $ip $id $flag\n";

  my $team = teamNumber();
  unless (-f "data/$team.txt")
  {
    open FFF, ">data/$team.txt";
    close FFF;
  }

  my $F;
  my $DATA;
  open $F, ">tmp$team.txt";
  open $DATA, ">>data/$team.txt";
  my $time = int(time());
  my $count = $time - getTime($team);
  my $last = generate($F, $DATA, $count, 'andgein', $flag, getTime($team));
  close $F;
  close $DATA;

  open F, "tmp$team.txt";
  my $G = IO::Zlib->new("tmp$team.txt.gz", "wb9");
	{
		local $\;
  	print $G $_ while <F>;
	}
  $G->close();
  close F;

  warn "debug: last at $time: @$last\n";

  my $secret = getSecret($team);
  warn $secret;
  sendData($ip, $team, getTime($team), $secret);

  saveTime($team, $time);
  saveLast($team, $last);

  print $time - 1;
  select undef, undef, undef, 2;
  exit RESULT_OK;
}
