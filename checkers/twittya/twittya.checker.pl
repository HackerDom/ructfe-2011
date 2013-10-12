#!/usr/bin/perl -l

use LWP::UserAgent;
use constant {
  CHECKER_OK => 101,
  CHECKER_NOFLAG => 102,
  CHECKER_MUMBLE => 103,
  CHECKER_DOWN => 104,
  CHECKER_ERROR => 110
};

@agents = (
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

$port = 10050;
($mode, $ip, $id, $flag) = @ARGV;
%handlers = ('check' => \&check, 'put' => \&put, 'get' => \&get);
$ua = LWP::UserAgent->new;
$ua->agent ($agents [int rand @agents]);

$url = "http://$ip:$port";
($state, $state2) = ("user-$ip.s1", "user-$ip.s2");
@abc = ('a'..'z', 'A'..'Z', '0'..'9', split //, "_-,.:;*+=!? ");

$handlers {$mode}->($id, $flag);

sub is_error {
  my $s = shift;
  ($s =~ /errorpage/) &&
  ($s =~ /<div class="error">/) &&
  ($s =~ /<title>Twittya :: error page<\/title>/);
}

sub exists_substr {
  my ($str, $sub) = @_;
  $sub =~ s/(\W)/\\$1/g;
  $str =~ qr/$sub/;
}

sub gen_str {
  my ($l, $L) = @_;
  join '', map { $abc [int rand @abc] } 1 .. ($l + int rand ($L - $l));
}

sub gen_unique_str {
  my ($c, $r) = shift;
  do { $r = &gen_str } while (exists_substr ($c, $r));
  $r;
}

sub do_exit {
  my ($code, $msg, $log) = @_;
  print $msg;
  print STDERR $log;
  exit ($code);
}

# Проверка регистрации пользователя
sub check1 {
  my ($login, $password) = (gen_str (8, 16), gen_str (4, 8));
  $login =~ s/;|=//g;
  $password =~ s/;|=//g;
  my $r = $ua->post ("$url/user.pl?a=2", ['l' => $login, 'p' => $password]);
  do_exit (CHECKER_DOWN, "Could not connect to the service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Could not register in the service", "login:$login\npassword:$password") if is_error ($r->content);

  my $cookie = $r->header ('Set-Cookie');
  $ua->default_header ('Cookie' => $cookie);

  $r = $ua->get ("$url/user.pl?a=7");
  do_exit (CHECKER_DOWN, "Could not connect to the service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Error on registration page", "login:$login\npassword:$password") if is_error ($r->content);

  local $\ = "\n";
  open F, '>', $state;
  print F $login;
  print F $password;
  close F;
}

# Вход пользователя (с проверкой)
sub precheck {
  open F, '<', $state;
  (my $login = <F>) =~ s/\r|\n//g;
  (my $password = <F>) =~ s/\r|\n//g;
  close F;

  my $r = $ua->post ("$url/user.pl?a=1", ['l' => $login, 'p' => $password]);
  do_exit (CHECKER_DOWN, "Could not connect the service") unless $r->is_success;
  if (is_error ($r->content)) {
    unlink $state;
    do_exit (CHECKER_MUMBLE, "Could not get user's page", "login:$login\npassword:$password");
  }
  
  my $cookie = $r->header ('Set-Cookie');
  $ua->default_header ('Cookie' => $cookie);
  ($login, $password, $r);
}

# Проверка добавления тем пользователем
sub check2 {
  return &check1 unless (-e $state);
  my ($l, $p, $r) = &precheck;

  my $topic = gen_unique_str ($r->content, 10, 20);
  $r = $ua->post ("$url/user.pl?a=3", ['t' => $topic]);
  $ua->get ("$url/user.pl?a=7");
  do_exit (CHECKER_DOWN, "Could not connect to the service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Could not add a topic", "login:$l\npassword:$p\ntopic:$topic") if is_error ($r->content);
}

# Проверка добавления новости пользователем
sub check3 {
  return &check1 unless (-e $state);
  my ($login, $password, $r) = &precheck;

  my @topic_ids = (($r->content) =~ /<a href="user\.pl\?t=(\d+)"><div class="topic">/g);
  my $topic_id = $topic_ids [int rand @topic_ids];
  return &check2 unless $topic_id;

  my $news_title = gen_str (10, 20);
  my $news_content = gen_str (48, 64);

  $r = $ua->post ("$url/user.pl?a=4&t=$topic_id", ['to' => $topic_id, 'nt' => $news_title, 'nc' => $news_content]);
  
  $ua->get ("$url/user.pl?a=7");
  do_exit (CHECKER_DOWN, "Could not connect to a service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Could not add news", "login:$login\npassword:$password\ntopic:$topic_id\ntitle:$news_title\ncontent:$news_content") if is_error ($r->content);

  local $\ = "\n";
  open F, '>', $state2;
  print F $login;
  print F $password;
  print F $topic_id;
  print F $news_title;
  close F;
}

# Проверка публикации новости пользователем
sub check4 {
  return &check3 unless (-e $state2);

  open F, '<', $state2;
  (my $login = <F>) =~ s/\r|\n//g;
  (my $password = <F>) =~ s/\r|\n//g;
  (my $topic_id = <F>) =~ s/\r|\n//g;
  (my $news_title = <F>) =~ s/\r|\n//g;
  close F;

  my $r = $ua->post ("$url/user.pl?a=1", ['l' => $login, 'p' => $password]);
  do_exit (CHECKER_DOWN, "Could not connect the service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Could not get user's page", "login:$login\npassword:$password") if is_error ($r->content);
  
  my $cookie = $r->header ('Set-Cookie');
  $ua->default_header ('Cookie' => $cookie);

  my $r = $ua->get ("$url/user.pl?t=$topic_id");
  do_exit (CHECKER_DOWN, "Could not connect to a service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Could not get news", "login:$login\npassword:$password\ntopic:$topic_id\ntitle:$news_title") if is_error ($r->content);

  $news_title =~ s/(\W)/\\$1/g;
  unless ($r->content =~ /<div class="news">.*?$news_title.*?user\.pl\?a=6&i=(\d+)/s) {
    $ua->get ("$url/user.pl?a=7");
    unlink $state2;
    do_exit (CHECKER_MUMBLE, "News not found", "login:$login\npassword:$password\ntopic:$topic_id\ntitle:$news_title");
  }
  my $news_id = $1;

  $r = $ua->get ("$url/user.pl?a=6&i=$news_id");
  $ua->get ("$url/user.pl?a=7");
  do_exit (CHECKER_DOWN, "Could not connect to a service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Could not publish news", "login:$login\npassword:$password\ntopic:$topic_id\ntitle:$news_title\nnews-id:$news_id") if is_error ($r->content);

  $r = $ua->get ("$url/main.pl?t=$topic_id");
  do_exit (CHECKER_DOWN, "Could not connect to a service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Error page") if is_error ($r->content);
  do_exit (CHECKER_MUMBLE, "Could not publish news", "login:$login\npassword:$password\ntopic:$topic_id\ntitle:$news_title\nnews-id:$news_id") unless $r->content =~ /$news_title/;

  unlink $state2;
}

# Проверка наличия страницы "подписка" у пользователя
sub check5 {
  return &check1 unless (-e $state);
  my ($l, $p) = &precheck;

  my $r = $ua->get ("$url/subscribe.pl");
  $ua->get ("$url/user.pl?a=7");
  do_exit (CHECKER_DOWN, "Could not connect to a service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Could not get 'subscriptions' page", "login:$l\npassword:$p") if is_error ($r->content);
}

sub check {
  my $r = $ua->get ("$url/main.pl");
  do_exit (CHECKER_DOWN, "Could not connect to the service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Error page") if is_error ($r->content);

  eval "&check" . (1 + (int rand 100) % 5);

  do_exit (CHECKER_OK);
}

sub put {
  my ($id, $flag) = @_;
  (my $login = $id) =~ s/-//g;
  my $password = gen_str (8, 16);

  $login =~ s/;|=//g;
  $password =~ s/;|=//g;

  my $r = $ua->post ("$url/user.pl?a=2", ['l' => $login, 'p' => $password]);
  do_exit (CHECKER_DOWN, "Could not connect to the service") unless $r->is_success;
  do_exit (CHECKER_MUMBLE, "Could not register in the service", "login:$login\npassword:$password") if is_error ($r->content);

  my $cookie = $r->header ('Set-Cookie');
  $ua->default_header ('Cookie' => $cookie);

  if ((int rand 10) < 7) {
    my $topic = gen_unique_str ($r->content, 10, 20);
    my ($status, $topic_id) = 0;

    if ((int rand 10) < 7) {
      $r = $ua->get ("$url/user.pl");
      if (is_error ($r->content)) {
        $ua->get ("$url/user.pl?a=7");
        do_exit (CHECKER_MUMBLE, "Could not get user's page", "login:$login\npassword:$password");
      }
      unless ($r->is_success) {
        $ua->get ("$url/user.pl?a=7");
        do_exit (CHECKER_DOWN, "Could not connect to the service");
      }
      my @topic_ids = (($r->content) =~ /<a href="user\.pl\?t=(\d+)"><div class="topic">/g);
      $topic_id = $topic_ids [int rand @topic_ids];
      $status = $topic_id ? 1 : 2;
    }
    if ($status == 2 || !$status) {
      $r = $ua->post ("$url/user.pl?a=3", ['t' => $topic]);
      unless ($r->is_success) {
        $ua->get ("$url/user.pl?a=7");
        do_exit (CHECKER_DOWN, "Could not connect to the service");
      }
      if (is_error ($r->content)) {
        $r = $ua->get ("$url/user.pl");
        unless ($r->is_success) {
          $ua->get ("$url/user.pl?a=7");
          do_exit (CHECKER_DOWN, "Could not connect to the service");
        }
      }

      (my $_topic = $topic) =~ s/(\W)/\\$1/g;
      $r->content =~ /<a href="user\.pl\?t=(\d+)"><div class="topic">$_topic<\/div><\/a>/;
      $topic_id = $1;
    }

    my $news_title = gen_str (10, 20);
    my $news_content = gen_str (8, 16) . " $flag " . gen_str (8, 16);

    $r = $ua->post ("$url/user.pl?a=4", ['to' => $topic_id, 'nt' => $news_title, 'nc' => $news_content]);
    $ua->get ("$url/user.pl?a=7");
    do_exit (CHECKER_DOWN, "Could not connect to the service") unless $r->is_success;
    do_exit (CHECKER_MUMBLE, "Could not add news", "login:$login\npassword:$password\ntopic-id:$topic_id\ntitle:$news_title\ncontent:$news_content") if is_error ($r->content);

    print "1-$topic_id-$login/$password";
  }
  else {
    $r = $ua->post ("$url/user.pl?a=5", ['pr' => $flag]);
    unless ($r->is_success) {
      $ua->get ("$url/user.pl?a=7");
      do_exit (CHECKER_DOWN, "Could not connect to the service");
    }
    if (is_error ($r->content)) {
      $ua->get ("$url/user.pl?a=7");
      do_exit (CHECKER_MUMBLE, "Could not change user's profile", "login:$login\npassword:$password\nprofile:$flag");
    }
    if ((int rand 10) < 5) {
      $r = $ua->get ("$url/user.pl?a=7");
      do_exit (CHECKER_DOWN, "Could not connect to the service") unless $r->is_success;
      do_exit (CHECKER_MUMBLE, "Could not logoff", "login:$login\npassword:$password") if is_error ($r->content);
    }

    print "2-$login/$password";
  }
  do_exit (CHECKER_OK);
}

sub get {
  my ($id, $flag) = @_;
  if ($id =~ /^1-/) {
    my ($topic_id, $login, $password) = ($id =~ /^1-(.*)-(.*)\/(.*)$/);
    my $r = $ua->post ("$url/user.pl?a=1", ['l' => $login, 'p' => $password]);
    do_exit (CHECKER_DOWN, "Could not connect the service") unless $r->is_success;
    do_exit (CHECKER_MUMBLE, "Could not get user's page", "login:$login\npassword:$password") if is_error ($r->content);

    my $cookie = $r->header ('Set-Cookie');
    $ua->default_header ('Cookie' => $cookie);

    $r = $ua->post ("$url/user.pl?t=$topic_id");
    unless ($r->is_success) {
      $ua->get ("$url/user.pl?a=7");
      do_exit (CHECKER_DOWN, "Could not connect to the service");
    }
    if (is_error ($r->content)) {
      $ua->get ("$url/user.pl?a=7");
      do_exit (CHECKER_MUMBLE, "Could not get user's page", "login:$login\npassword:$password\ntopic-id$topic_id");
    }

    $ua->get ("$url/user.pl?a=7");
    do_exit (CHECKER_NOFLAG, "No flag", "login:$login\npassword:$password\ntopic-id$topic_id\nflag:$flag") unless exists_substr ($r->content, $flag);
  }
  else {
    my ($login, $password) = ($id =~ /^2-(.*)\/(.*)$/);
    my $r = $ua->post ("$url/user.pl?a=1", ['l' => $login, 'p' => $password]);
    do_exit (CHECKER_DOWN, "Could not connect to the service") unless $r->is_success;
    do_exit (CHECKER_MUMBLE, "Could not get user's page", "login:$login\npassword:$password") if is_error ($r->content);
    do_exit (CHECKER_NOFLAG, "No flag", "login:$login\npassword:$password\ntopic-id$topic_id\nflag:$flag") unless exists_substr ($r->content, $flag);
  }
  do_exit (CHECKER_OK);
}
