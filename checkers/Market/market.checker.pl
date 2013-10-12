#!/usr/bin/perl

use LWP::UserAgent;
use HTTP::Cookies;
use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);

my $d=0;

my $do=$ARGV[0];
my $ip=$ARGV[1];
my $id=$ARGV[2];
my $flag=$ARGV[3];
my $percent=$ARGV[4];
$percent=$id if $do eq "check"; 

# URL
my $url="http://".$ip.":2121/";


# Create UserAgent
my $ua=LWP::UserAgent->new;

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

$ua->agent($agents [int rand @agents]);

# Create Cookies 
my $cookie_jar = HTTP::Cookies->new;

# Cookies enable
$ua->cookie_jar( $cookie_jar );

# do POST & GET redirectable
# $ua->max_redirect(5);
push @{$ua->requests_redirectable}, 'POST';
push @{$ua->requests_redirectable}, 'GET';

# Set timeout to 10 sec.
$ua->timeout(10);

sub getlogpas
{
    my @a=(substr($id,0,int(length($id)/2)),substr($id,int(length($id)/2)));
    $a[1] .= "r" while (md5($a[1]) =~ /\"/);
    return @a;
}

(my $login, my $pass) = &getlogpas();

my $m = ((ord(substr $login, 0, 1)) % 3);

if($do eq 'check')
{
    my $err = "";
    my $out = "";
    my $fs = 1;
    
    my @pages = ("index.mix", "sell.mix", "buy.mix", "ad.mix", "requests.mix", 
    "purchase.mix", "status.mix", "pull.mix", "check.mix", "req.mix",
    "send.mix", "msg.mix", "reg.mix");
    
    if(open F, "<", $ip.".thfl")
    {
        my $inpu = <F>;
        close F;
        (my $id1, my $flag1) = split ' ', $inpu;
        $id = $id1;
        (my $login, my $pass) = &getlogpas();
        # print $login, "/", $pass, " ", $flag1;
        my $response = $ua->get ($url . "index.mix?alogin=" . $login . "&apass=" . $pass . "&Sign+In%21=Sign+In%21");
        $response = $ua->get ($url . "requests.mix");
        if ($response->is_success)
        {
            $out .= "page requests.mix: Ok!\n";
            my $cont = $response->content;
            for($response->content =~ /<a\s+href="(\S+)">\s*No\s*<\/a>/g)
            {
                $response = $ua->get ($url . $_);
            }
        }
        else
        {
            $out .= "page requests.mix: Down!\n";
            $fs = 0;
        }
    }
    else
    { 
        for(@pages)
        {
            my $response = $ua->get ($url . $_);
            if ($response->is_success) {
                $out .= "page $_: Ok\n";
            }
            else {
                $out .= "page $_: Down!\n";
                $fs = 0
           }
        }
    }

    if($fs == 1)
    {
        print STDOUT $out;
        print STDERR $err;
        exit 101;
    }
    else
    {
        print STDOUT $out;
        print STDERR $err;
        exit 104;
    }
}

elsif($do eq 'put')
{
    my $err = "";
    
    if($m == 0)
    {
        # flag in credit card number
        
        my $response = $ua->get ($url . "reg.mix?login=" . $login . "&pass=" . $pass . "&cpass=" . $pass . "&name=" . $login . "&cc=" . $flag . "&cvc=123&Sign+Up%21=Sign+Up%21");
        if ($response->is_success) 
        {
            $err .= "Success put flag: " . $flag . " in credit card number.\n";
            print STDERR $err;
            exit 101;
        }
        else 
        {
            $err .= "Error put flag: " . $flag . " in credit card number.\n";
            print STDERR $err;
            exit 104;
        }
    }
    elsif($m == 1)
    {
        # flag in buy ad
        
        my $response = $ua->get ($url . "reg.mix?login=" . $login . "&pass=" . $pass . "&cpass=" . $pass . "&name=" . $login . "&cc=12345678901234567890&cvc=123&Sign+Up%21=Sign+Up%21");
        $response = $ua->get ($url . "index.mix?alogin=$login&apass=" . $pass . "&Sign+In%21=Sign+In%21");
        if ($response->is_success) 
        {
            $response = $ua->get ($url . "ad.mix?type=buy&title=Flag%21&publicity=Give+me+please+your+flags%21&content=real..+give+me...&cost=1&Add+Ad=Add+Ad");
            if ($response->is_success)
            {
                $response = $ua->get ($url . "ad.mix?logout=1");
                
                $response = $ua->get ($url . "reg.mix?login=" . $login . "2&pass=" . $pass . "&cpass=" . $pass . "&name=" . $login . "2&cc=09876543210987654321&cvc=123&Sign+Up%21=Sign+Up%21");
                $response = $ua->get ($url . "index.mix?alogin=" . $login . "2&apass=" . $pass . "&Sign+In%21=Sign+In%21");
                $response = $ua->get ($url . "buy.mix");
                if ($response->is_success) 
                {
                    for(split "Posted by $login", $response->content)
                    {
                        if($_ =~ /id=(\w+)/)
                        {
                            $response = $ua->get ($url . "check.mix?idu=69&ida=" . $1 . "&content=" . $flag . "&sell=1");
                            if ($response->is_success)
                            {
                                $err .= "Success put flag: " . $flag . " in buy flag.\n";
                                print STDERR $err;
                                exit 101;
                            }
                            else
                            {
                                $err .= "Error check. id: " . $id . " in buy flag.\n";
                                print STDERR $err;
                                exit 104;
                            }
                        }
                    }
                    $err .= "Error post ad. id: " . $id . " in buy flag.\n";
                    print STDERR $err;
                    exit 104;
                }
                else 
                {
                    $err .= "Error login. id: " . $id . " in buy flag. second.\n";
                    print STDERR $err;
                    exit 104;
                }
            }
            else
            {
                $err .= "Error add ad. id: " . $id . " in buy flag\n";
                print STDERR $err;
                exit 104;
            }
        }
        else 
        {
            $err .= "Error login. id: " . $id . " in buy flag\n";
            print STDERR $err;
            exit 104;
        }
    }
    elsif($m == 2)
    {
        # flag in sell ad
        
        my $response = $ua->get ($url . "reg.mix?login=" . $login . "&pass=" . $pass . "&cpass=" . $pass . "&name=" . $login . "&cc=12345678901234567890&cvc=123&Sign+Up%21=Sign+Up%21");
        $response = $ua->get ($url . "index.mix?alogin=$login&apass=" . $pass . "&Sign+In%21=Sign+In%21");
        if ($response->is_success) 
        {
            $response = $ua->get ($url . "ad.mix?type=sell&title=Flag%21&publicity=This+is+real+flag%21+Buy+Now%21&content=" . $flag . "&cost=39&Add+Ad=Add+Ad");
            if ($response->is_success)
            {
            
                
                $response = $ua->get ($url . "sell.mix");
                if ($response->is_success) 
                {
                    for(split "Posted by $login", $response->content)
                    {
                        if($_ =~ /id=(\w+)/)
                        {
                            $response = $ua->get ($url . "msg.mix?idu=69&ida=" . $1 . "&message=Hi! give me!&Send=Send");
                            if ($response->is_success)
                            {
                                if(open F, ">", $ip.".thfl")
                                {
                                    print F $id." ".$flag;
                                    close F;
                                }
                                
                                $err .= "Success put flag: " . $flag . " in sell flag.\n";
                                print STDERR $err;
                                exit 101;
                            }
                            else
                            {
                                $err .= "Error check. id: " . $id . " in sell flag.\n";
                                print STDERR $err;
                                exit 104;
                            }
                        }
                    }
                    $err .= "Error post ad. id: " . $id . " in sell flag.\n";
                    print STDERR $err;
                    exit 104;
                }
                else 
                {
                    $err .= "Error login. id: " . $id . " in sell flag. second.\n";
                    print STDERR $err;
                    exit 104;
                }
                
            }
            else
            {
                $err .= "Error add ad. id: " . $id . " in sell flag\n";
                print STDERR $err;
                exit 104;
            }
        }
        else 
        {
            $err .= "Error login. id: " . $id . " in sell flag\n";
            print STDERR $err;
            exit 104;
        }
    }
    else
    {
        $err .= "Incorrect type flag! id: " . $id . "\n";
        print STDERR $err;
        exit 110;
    }
}

elsif($do eq 'get')
{
    my $err = "";
    my $out = "";
    
    if($m == 0)
    {
        # flag in credit card number
        
        my $response = $ua->get ($url . "index.mix?alogin=" . $login . "&apass=" . $pass . "&Sign+In%21=Sign+In%21");
        $response = $ua->get ($url . "index.mix");
        if ($response->is_success) 
        {
            if($response->content =~ /$flag/)
            {
                $err .= "Success get flag: " . $flag . " in credit card number.\n";
                print STDOUT $out;
                print STDERR $err;
                exit 101;
            }
            else
            {
                $err .= "Error get flag: " . $flag . " in credit card number.\n";
                print STDOUT $out;
                print STDERR $err;
                exit 102;
            }
        }
        else 
        {
            $err .= "Error login. id: " . $id . "  in credit card number.\n";
            $out .= "Error login.\n";
            print STDOUT $out;
            print STDERR $err;
            exit 104;
        }
    }
    elsif($m == 1)
    {
        # flag in buy ad
        
        my $response = $ua->get ($url . "index.mix?alogin=" . $login . "&apass=" . $pass . "&Sign+In%21=Sign+In%21");
        $response = $ua->get ($url . "pull.mix");
        if ($response->is_success) 
        {
            if($response->content =~ /$flag/)
            {
                $err .= "Success get flag: " . $flag . " in buy flag.\n";
                print STDOUT $out;
                print STDERR $err;
                exit 101;
            }
            else
            {
                $err .= "Error get flag: " . $flag . " in buy flag.\n";
                print STDOUT $out;
                print STDERR $err;
                exit 102;
            }
        }
        else 
        {
            $err .= "Error login. id: " . $id . "  in buy flag.\n";
            $out .= "Error login.\n";
            print STDOUT $out;
            print STDERR $err;
            exit 104;
        }
    }
    elsif($m == 2)
    {
        # flag in sell ad
        
        my $response = $ua->get ($url . "index.mix?alogin=" . $login . "&apass=" . $pass . "&Sign+In%21=Sign+In%21");
        $response = $ua->get ($url . "requests.mix");
        if ($response->is_success) 
        {
            my $cont = $response->content;
            for($response->content =~ /<a\s+href="(\S+)">\s*No\s*<\/a>/g)
            {
                $response = $ua->get ($url . $_);
            }
            
            if($cont =~ /$flag/)
            {
                $err .= "Success get flag: " . $flag . " in sell flag.\n";
                print STDOUT $out;
                print STDERR $err;
                exit 101;
            }
            else
            {
                $err .= "Error get flag: " . $flag . " in sell flag.\n";
                print STDOUT $out;
                print STDERR $err;
                exit 102;
            }
        }
        else 
        {
            $err .= "Error login. id: " . $id . "  in sell flag.\n";
            $out .= "Error login.\n";
            print STDOUT $out;
            print STDERR $err;
            exit 104;
        }
    }
    else
    {
        $err .= "Incorrect type flag! id: " . $id . "\n";
        print STDOUT $out;
        print STDERR $err;
        exit 110;
    }
}
