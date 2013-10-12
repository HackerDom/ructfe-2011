#!/usr/bin/perl -lw
use strict;
use MIME::Base64;
use Digest::MD5 qw(md5_hex);
use Math::GMPz qw(:mpz);
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Bignum;
require LWP::UserAgent;

### Needed module: libcrypt-ssleay-perl

$|=1;

#####################  Config  #################################

my $TCP_PORT      = 443;
my $LWP_TIME      = 5;	# Timeout (sec) for each HTTP request
my $SCRIPT_DO     = '/cgi-bin/cms-do';
my $DB_DIR        = './cms.checker.db/';
my $MAX_OUR_USERS = 15;		# Макс. кол-во наших пользователей на сервисе.

##################  End of config  #############################

sub RESULT_OK      {exit 101}
sub RESULT_NOFLAG  {print pop().$/; exit 102}
sub RESULT_CORRUPT {print pop().$/; exit 103}
sub RESULT_DOWN    {print pop().$/; exit 104}
sub RESULT_ERROR   {warn  pop().$/; exit 110}

my @USERAGENTS = (
	'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.874.106 Safari/535.2',
	'Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3',
	'Mozilla/5.0 (X11; Linux x86_64; rv:2.0b4) Gecko/20100818 Firefox/4.0b4',
	'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:2.0b7) Gecko/20101111 Firefox/4.0b7',
	'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)',
	'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
	'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0)',
	'Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)'
);

my %CHECK_MD5 = (
	'/cms/js/register.js' => 'c6fb4d5f62901b91f28646f742b3990c',
	'/cms/js/onload.js'   => 'dac6597d828bd6976219bc23fdbf652a',
	'/cms/js/send.js'     => 'aa658706d3cb685e74f7df032e47426a',
	'/cms/js/sha256.js'   => 'ba8cc9d888736406a588dedce43f37d1',
	'/cms/js/view.js'     => '4b2f3fe8df85e008244124448133d67d',
);

my %CHECK_SUBSTR = (
	'/cgi-bin/cms'        => '<img src="/cms/safe.jpg">',
	'/cgi-bin/cms?t=reg'  => '<form id="regform" action=',
	'/cgi-bin/cms-do'     => 'Error - No action specified',
);

my @NAMES = qw(
	Aaron Adam Alan Albert Alex Alexander Alexandra Alfred Alice Alicia Alison 
	Allan Allen Allison Alvin Amanda Amy Andrea Andrew Angela Anita Ann Anna 
	Anne Annette Annie Anthony April Arlene Arnold Arthur Ashley Audrey Barbara 
	Barry Becky Ben Benjamin Bernard Bernice Beth Betsy Betty Beverly Bill 
	Billie Billy Bob Bobby Bonnie Brad Bradley Brandon Brenda Brent Brett Brian 
	Brooke Bruce Bryan Calvin Cameron Carl Carla Carlos Carmen Carol Carole 
	Caroline Carolyn Carrie Catherine Cathy Cecil Chad Charlene Charles Charlie 
	Charlotte Cheryl Chris Christian Christina Christine Christopher Christy 
	Cindy Claire Clara Clarence Claude Claudia Clifford Clyde Colleen Connie 
	Constance Courtney Craig Crystal Curtis Cynthia Dale Dan Dana Daniel Danielle 
	Danny Darlene David Dawn Dean Debbie Deborah Debra Denise Dennis Derek 
	Diana Diane Dianne Dolores Don Donald Donna Doris Dorothy Douglas Dwight 
	Earl Eddie Edgar Edith Edna Edward Edwin Eileen Elaine Eleanor Elisabeth 
	Elizabeth Ellen Elsie Emily Emma Eric Erica Erik Erika Erin Ernest Esther 
	Ethel Eugene Eva Evan Evelyn Faye Florence Floyd Frances Francis Frank 
	Franklin Fred Frederick Gail Gary Gayle Gene Geoffrey George Gerald Geraldine 
	Gilbert Gina Gladys Glen Glenda Glenn Gloria Gordon Grace Greg Gregory 
	Gretchen Guy Gwendolyn Hannah Harold Harriet Harry Harvey Hazel Heather 
	Heidi Helen Henry Herbert Herman Hilda Holly Howard Hugh Ian Irene Jack 
	Jackie Jacob Jacqueline James Jamie Jan Jane Janet Janice Jason Jay Jean 
	Jeanette Jeanne Jeff Jeffrey Jennifer Jenny Jeremy Jerome Jerry Jesse Jessica 
	Jessie Jill Jim Jimmy Joan Joann Joanna Joanne Joe Joel John Johnny Jon 
	Jonathan Jordan Jose Joseph Josephine Joshua Joy Joyce Juan Juanita Judith 
	Judy Julia Julian Julie June Justin Kara Karen Karl Kate Katharine Katherine 
	Kathleen Kathryn Kathy Katie Kay Keith Kelly Ken Kenneth Kent Kerry Kevin 
	Kim Kimberly Kristen Kristin Kristina Kristine Kurt Kyle Larry Laura Lauren 
	Laurence Laurie Lawrence Leah Lee Leigh Leo Leon Leonard Leroy LeRoy Leroy 
	LeRoy Leroy LeRoy Leroy LeRoy Leroy LeRoy Leroy Leslie Lester Lewis Lillian 
	Linda Lindsay Lisa Lloyd Lois Lori Lorraine Louis Louise Lucille Lucy Luis 
	Lynda Lynn Lynne Malcolm Marc Marcia Marcus Margaret Marguerite Maria Marian 
	Marianne Marie Marilyn Marion Marjorie Mark Marlene Marsha Marshall Martha 
	Martin Marvin Mary Matthew Maureen Maurice Max Maxine Megan Melanie Melinda 
	Melissa Melvin Meredith Michael Michele Michelle Mike Mildred Milton Miriam 
	Mitchell Molly Monica Nancy Natalie Nathan Neal Neil Nelson Nicholas Nicole 
	Nina Norma Norman Oscar Paige Pam Pamela Pat Patricia Patrick Patsy Paul 
	Paula Pauline Peggy Penny Peter Philip Phillip Phyllis Priscilla Rachel 
	Ralph Randall Randy Ray Raymond Rebecca Regina Renee Rhonda Richard Rick 
	Ricky Rita Robert Roberta Robin Robyn Rodney Roger Ron Ronald Ronnie Rose 
	Rosemary Ross Roy Ruby Russell Ruth Ryan Sally Sam Samantha Samuel Sandra 
	Sandy Sara Sarah Scott Sean Seth Shannon Sharon Shawn Sheila Shelley Sherri 
	Sherry Sheryl Shirley Sidney Stacey Stacy Stanley Stephanie Stephen Steve 
	Steven Stuart Sue Susan Suzanne Sylvia Tamara Tammy Tara Ted Teresa Terri 
	Terry Thelma Theodore Theresa Thomas Tiffany Tim Timothy Tina Todd Tom 
	Tommy Toni Tony Tonya Tracey Tracy Troy Valerie Vanessa Vernon Veronica 
	Vicki Vickie Victor Victoria Vincent Virginia Vivian Wade Wallace Walter 
);

my @LAST_NAMES = qw(
	Abbott Abrams Adams Adcock Adkins Adler Albright Aldridge Alexander Alford 
	Allen Allison Allred Alston Anderson Andrews Anthony Archer Armstrong Arnold 
	Arthur Ashley Atkins Atkinson Austin Avery Aycock Ayers Bailey Baird Baker 
	Baldwin Ball Ballard Banks Barbee Barber Barbour Barefoot Barker Barnes 
	Barnett Barr Barrett Barry Bartlett Barton Bass Batchelor Bates Bauer Baxter 
	Beach Bean Beard Beasley Beatty Beck Becker Bell Bender Bennett Benson 
	Benton Berg Berger Berman Bernstein Berry Best Bishop Black Blackburn Blackwell 
	Blair Blake Blalock Blanchard Bland Blanton Block Bloom Blum Bolton Bond 
	Boone Booth Boswell Bowden Bowen Bowers Bowles Bowling Bowman Boyd Boyer 
	Boyette Boykin Boyle Bradford Bradley Bradshaw Brady Branch Brandon Brandt 
	Brantley Braswell Braun Bray Brennan Brewer Bridges Briggs Britt Brock 
	Brooks Brown Browning Bruce Bryan Bryant Buchanan Buck Buckley Bullard 
	Bullock Bunn Burch Burgess Burke Burnett Burnette Burns Burton Bush Butler 
	Byers Bynum Byrd Byrne Cain Caldwell Callahan Cameron Camp Campbell Cannon 
	Capps Carey Carlson Carlton Carpenter Carr Carroll Carson Carter Carver 
	Case Casey Cash Cassidy Cates Chambers Chan Chandler Chang Chapman Chappell 
	Chase Cheek Chen Cheng Cherry Cho Choi Christensen Christian Chu Chung 
	Church Clapp Clark Clarke Clayton Clements Cline Coates Cobb Coble Cochran 
	Cohen Cole Coleman Coley Collier Collins Combs Conner Connolly Connor Conrad 
	Conway Cook Cooke Cooper Copeland Corbett Covington Cowan Cox Crabtree 
	Craft Craig Crane Craven Crawford Creech Crews Cross Crowder Crowell Cummings 
	Cunningham Currie Currin Curry Curtis Dale Dalton Daly Daniel Daniels Davenport 
	Davidson Davies Davis Dawson Day Deal Dean Decker Dennis Denton Desai Diaz 
	Dickens Dickerson Dickinson Dickson Dillon Dixon Dodson Dolan Donnelly 
	Donovan Dorsey Dougherty Douglas Doyle Drake Dudley Duffy Duke Duncan Dunlap 
	Dunn Durham Dyer Eason Eaton Edwards Ellington Elliott Ellis Elmore English 
	Ennis Epstein Erickson Evans Everett Faircloth Farmer Farrell Faulkner 
	Feldman Ferguson Fernandez Ferrell Field Fields Finch Fink Finley Fischer 
	Fisher Fitzgerald Fitzpatrick Fleming Fletcher Flowers Floyd Flynn Foley 
	Forbes Ford Forrest Foster Fowler Fox Francis Frank Franklin Frazier Frederick 
	Freedman Freeman French Friedman Frost Frye Fuller Gallagher Galloway Garcia 
	Gardner Garner Garrett Garrison Gates Gay Gentry George Gibbons Gibbs Gibson 
	Gilbert Giles Gill Gillespie Gilliam Glass Glenn Glover Godfrey Godwin 
	Gold Goldberg Golden Goldman Goldstein Gonzalez Goodman Goodwin Gordon 
	Gorman Gould Grady Graham Grant Graves Gray Green Greenberg Greene Greer 
	Gregory Griffin Griffith Grimes Gross Grossman Gunter Gupta Guthrie Haas 
	Hahn Hale Hall Hamilton Hammond Hampton Hamrick Han Hancock Hanna Hansen 
	Hanson Hardin Harding Hardison Hardy Harmon Harper Harrell Harrington Harris 
	Harrison Hart Hartman Harvey Hatcher Hauser Hawkins Hawley Hayes Haynes 
	Heath Hedrick Heller Helms Henderson Hendricks Hendrix Henry Hensley Henson 
	Herbert Herman Hernandez Herndon Herring Hess Hester Hewitt Hicks Higgins 
	High Hill Hines Hinson Hinton Hirsch Ho Hobbs Hodge Hodges Hoffman Hogan 
	Holden Holder Holland Holloway Holmes Holt Honeycutt Hong Hood Hoover Hopkins 
	Horn Horne Horner Horowitz Horton House Houston Howard Howe Howell Hoyle 
	Hsu Hu Huang Hubbard Hudson Huff Huffman Hughes Hull Humphrey Hunt Hunter 
	Hurley Hurst Hutchinson Hwang Ingram Ivey Jackson Jacobs Jacobson Jain 
	James Jenkins Jennings Jensen Jernigan Jiang Johnson Johnston Jones Jordan 
	Joseph Joyce Joyner Justice Kahn Kane Kang Kaplan Katz Kaufman Kay Kearney 
	Keith Keller Kelley Kelly Kemp Kendall Kennedy Kenney Kent Kern Kerr Kessler 
	Khan Kidd Kim King Kinney Kirby Kirk Kirkland Klein Knight Knowles Knox 
	Koch Kramer Kuhn Kumar Lam Lamb Lambert Lamm Lancaster Lane Lang Langley 
	Langston Lanier Larson Lassiter Law Lawrence Lawson Leach Lee Lehman Leonard 
	Lester Levin Levine Levy Lewis Li Lim Lin Lindsay Lindsey Link Little Liu 
	Livingston Lloyd Locklear Logan Long Lopez Love Lowe Lowry Lu Lucas Lutz 
	Lynch Lynn Lyon Lyons MacDonald Mack Malone Mangum Mann Manning Marcus 
	Marks Marsh Marshall Martin Martinez Mason Massey Mathews Matthews Maxwell 
	May Mayer Maynard Mayo McAllister McBride McCall McCarthy McClure McConnell 
	McCormick McCoy McCullough McDaniel McDonald McDowell McFarland McGee McGuire 
	McIntosh McIntyre McKay McKee McKenna McKenzie McKinney McKnight McLamb 
	McLaughlin McLean McLeod McMahon McMillan McNamara McNeill McPherson Meadows 
	Medlin Melton Melvin Mercer Merrill Merritt Meyer Meyers Michael Middleton 
	Miles Miller Mills Mitchell Monroe Montgomery Moody Moon Moore Moran Morgan 
	Morris Morrison Morrow Morse Morton Moser Moss Mueller Mullen Mullins Murphy 
	Murray Myers Nance Nash Neal Nelson Newell Newman Newton Nguyen Nichols 
	Nicholson Nixon Noble Nolan Norman Norris Norton O'Brien O'Connell O'Connor 
	O'Donnell O'Neal O'Neill Oakley Odom Oh Oliver Olsen Olson Orr Osborne 
	Owen Owens Pace Padgett Page Palmer Pappas Park Parker Parks Parrish Parrott 
	Parsons Pate Patel Patrick Patterson Patton Paul Payne Peacock Pearce Pearson 
	Peck Peele Pennington Perez Perkins Perry Peters Petersen Peterson Petty 
	Phelps Phillips Pickett Pierce Pittman Pitts Poe Pollard Pollock Poole 
	Pope Porter Potter Powell Powers Pratt Preston Price Pridgen Prince Pritchard 
	Proctor Pruitt Puckett Pugh Quinn Ramsey Randall Rankin Rao Ray Raynor 
	Reddy Reed Reese Reeves Reid Reilly Reynolds Rhodes Rice Rich Richards 
	Richardson Richmond Riddle Riggs Riley Ritchie Rivera Roach Robbins Roberson 
	Roberts Robertson Robinson Rodgers Rodriguez Rogers Rollins Rose Rosen 
	Rosenberg Rosenthal Ross Roth Rouse Rowe Rowland Roy Rubin Russell Ryan 
	Sanchez Sanders Sanford Saunders Savage Sawyer Scarborough Schaefer Schmidt 
	Schneider Schroeder Schultz Schwartz Schwarz Scott Sellers Shaffer Shah 
	Shannon Shapiro Sharma Sharp Sharpe Shaw Shea Shelton Shepherd Sherman 
	Sherrill Shields Shore Short Siegel Sigmon Silver Silverman Simmons Simon 
	Simpson Sims Sinclair Singer Singh Singleton Skinner Sloan Small Smith 
	Snow Snyder Solomon Song Sparks Spears Spence Spencer Spivey Stafford Stallings 
	Stanley Stanton Stark Starr Steele Stein Stephens Stephenson Stern Stevens 
	Stevenson Stewart Stokes Stone Stout Strauss Strickland Stroud Stuart Sullivan 
	Summers Sumner Sun Sutherland Sutton Swain Swanson Sweeney Sykes Talley 
	Tan Tanner Tate Taylor Teague Terrell Terry Thomas Thompson Thomson Thornton 
	Tilley Todd Townsend Tucker Turner Tuttle Tyler Tyson Underwood Upchurch 
	Vaughan Vaughn Vick Vincent Vogel Wade Wagner Walker Wall Wallace Waller 
	Walsh Walter Walters Walton Wang Ward Warner Warren Washington Waters Watkins 
	Watson Watts Weaver Webb Weber Webster Weeks Weiner Weinstein Weiss Welch 
	Wells Welsh Werner West Wheeler Whitaker White Whitehead Whitfield Whitley 
	Wiggins Wilcox Wilder Wiley Wilkerson Wilkins Wilkinson Willard Williams 
	Williamson Williford Willis Wilson Winstead Winters Wise Wolf Wolfe Womble 
	Wong Wood Woodard Woodruff Woods Woodward Wooten Wrenn Wright Wu Wyatt 
);

my @MAIL_DOMAINS = qw( gmail.com hotmail.com mail.ru yahoo.com aol.com msn.com );

################################################################

-d $DB_DIR or RESULT_ERROR "Fatal error: DB_DIR doesn't exist: $DB_DIR";

my $ua = LWP::UserAgent->new;
$ua->agent($USERAGENTS[int rand 0+@USERAGENTS]);
$ua->timeout($LWP_TIME);

my %MODES = (check => \&check, get => \&get, put => \&put);

my $mode = shift     or RESULT_ERROR "Arguments error: no 'mode'";
my $ip   = shift     or RESULT_ERROR "Arguments error: no 'ip'";
exists $MODES{$mode} or RESULT_ERROR "Arguments error: unknown 'mode'";

my $BASE_URL = sprintf("https://%s:%d", $ip, $TCP_PORT);

$MODES{$mode}->(@ARGV);
RESULT_ERROR "Check subroutine didn't return anything";

##############################################################################

sub CheckMd5 
{
	my $url = shift;
	my $md5 = $CHECK_MD5{$url};
	my $r = $ua->get("https://$ip:$TCP_PORT" . $url);
	return $r->is_success && ($md5 eq md5_hex $r->decoded_content);
}

sub CheckSubstr 
{
	my $url = shift;
	my $substr = $CHECK_SUBSTR{$url};
	my $r = $ua->get("https://$ip:$TCP_PORT" . $url);
	return $r->is_success && ($r->decoded_content =~ /$substr/);
}

sub RandomStr
{
	my $len = shift;
	my $RND = join '', ('a'..'z','A'..'Z','0'..'9');
	my $RLEN = length($RND);
	return join '', map { substr($RND,int rand $RLEN,1) } 1..$len;
}

sub RandomHexStr
{
	my $len = shift;
	my $RND = join '', ('a'..'f','0'..'9');
	my $RLEN = length($RND);
	return join '', map { substr($RND,int rand $RLEN,1) } 1..$len;
}

sub LoadUsers
{
	my %DB=();
	my $dbfname = "$DB_DIR/$ip.dat";
	-f $dbfname or return %DB;
	open F, $dbfname or RESULT_ERROR "LoadUsers: cannot open '$dbfname': $!";
	while (<F>) {
		chomp;
		my ($name,$age,$email,$privkey) = split /;/;
		$DB{$name} = {};
		$DB{$name}->{age}=$age;
		$DB{$name}->{email}=$email;
		$DB{$name}->{privkey}=$privkey;
	}
	close F;
	return %DB;
}

# AddUser - добавить пользователя в файл базы данных.
#

sub AddUser
{
	my ($name,$age,$email,$privkey) = @_;
	my $dbfname = "$DB_DIR/$ip.dat";
	open(F, ">>", $dbfname) or RESULT_ERROR "AddUser: cannot open '$dbfname': $!";
	my $str = "$name;$age;$email;$privkey";
	$str =~ s/[\r\n]+//g;
	syswrite F, "$str\n";
	close F;
}

##############################################################################
#
# Register(...) - зарегистрировать пользователя с указанными данными
# Возвращает: если успешно - пару (pubkey,privkey), если неудачно - (undef,undef)

sub Register
{
	my ($name,$age,$email,$pass,$rand)=@_;
	
	my $data = {
		a     => "register",
		name  => $name, age   => $age,  email => $email,
		pass1 => $pass, pass2 => $pass, rand  => $rand
	};
	my $r = $ua->post( "https://$ip:$TCP_PORT$SCRIPT_DO", $data );

	if ($r->is_success) 
	{
		my $reply = $r->decoded_content;
		chomp $reply;
		if ($reply =~ /^OK - (\S+),(\S+)$/) {
			warn "Register: OK ($name,$age,$email)\n";
			return ($1,$2);
		}
		else {
			warn "Register: Fail. Reply: $reply\n";
			return (undef,undef);
		}
	}
	else {
		warn "Register: Fail. ".$r->status_line."\n";
		return (undef,undef);
	}
}

##############################################################################
#
# SendMessage - отправить пользователю сообщение

sub SendMessage
{
	my ($sender,$recipient,$msg) = @_;

	my $data = {
		a         => 'send',
		sender    => $sender,
		recipient => $recipient,
		msg       => $msg
	};
	my $r = $ua->post( "https://$ip:$TCP_PORT$SCRIPT_DO", $data );

	if (!$r->is_success)  {
		warn "SendMessage: Fail. ".$r->status_line."\n";
		RESULT_CORRUPT "Cannot send message";
	}

	my $reply = $r->decoded_content;
	chomp $reply;
	if ($reply !~ /^OK /) {
		warn "SendMessage: Fail. Reply: $reply\n";
		RESULT_CORRUPT "Cannot send message";
	}

	warn "SendMessage: OK\n";
}

##############################################################################
#
# CreateName - сгенерировать имя новому пользователю (случайно)
#

sub CreateName
{
	$NAMES[int rand @NAMES].' '.$LAST_NAMES[int rand @LAST_NAMES];
}

sub CreateEmail
{
	my $name = shift;
	$name =~ /^(\S+)/;
	my $login = length($1)>0 ? lc($1) : RandomStr(5);
	my $domain = $MAIL_DOMAINS[int rand @MAIL_DOMAINS];
	return $login.'@'.$domain;
}

sub uncut_priv
{
	my $s = shift;
	$s =~ s/(.{64})/$1\n/g;
	return "-----BEGIN RSA PRIVATE KEY-----\n$s\n-----END RSA PRIVATE KEY-----\n";
}

##############################################################################
#
# GetUsersFromService - получить список пользователей с сервиса.

sub GetUsersFromService
{
	my %U = ();
	my $r = $ua->get("$BASE_URL$SCRIPT_DO?a=list");
	if ($r->is_success) {
		my @L = split /[\r\n]+/,$r->decoded_content;
		local $_;
		for (@L) {
			my ($id,$name,$age,$email) = split /;/;
			$U{$name} = {};
			$U{$name}->{id}    = $id;
			$U{$name}->{age}   = $age;
			$U{$name}->{email} = $email;
		}
		warn sprintf "GetUsersFromService: %d users\n", 0+keys%U;
	}
	else {
		warn "GetUsersFromService: Fail. ".$r->status_line."\n";
	}
	return %U;
}

##############################################################################

sub check 
{
	my $response = $ua->get("https://$ip:$TCP_PORT/cms/");
	$response->is_success or RESULT_DOWN $response->status_line;
	CheckMd5 $_    or RESULT_CORRUPT "File corrupted: $_" for sort keys %CHECK_MD5;
	CheckSubstr $_ or RESULT_CORRUPT "Page corrupted: $_" for sort keys %CHECK_SUBSTR;
	RESULT_OK;
}

###############################################################################
#                        get - получение флага из сервиса 

sub get 
{
	@ARGV==2 or RESULT_ERROR "Missing arguments: flagid, flag";
	my ($FLAG_ID, $FLAG)=@ARGV;
	$FLAG_ID =~ s/_/ /g;
	$FLAG_ID =~ /^from\s+(.*?)\s+to\s+(.*)$/ or RESULT_ERROR "flagid has invalid format";

	my ($sender,$recipient)=($1,$2);
	warn "get: from $sender to $recipient\n";

	my %DB_USERS   = LoadUsers();           # Пользователи из локальной базы
	my %REAL_USERS = GetUsersFromService(); # Пользователи из сервиса команды

	exists $REAL_USERS{$recipient} or RESULT_NOFLAG "User not found";
	exists $DB_USERS{$recipient}   or RESULT_ERROR  "User not found in local DB";

	my $id = $REAL_USERS{$recipient}->{id};
	defined $id                    or RESULT_CORRUPT "Bad user id";

	my $privkey = $DB_USERS{$recipient}->{privkey};
	defined $id                    or RESULT_ERROR "No privkey for user $recipient in local DB";
	
	my $r = $ua->get("$BASE_URL$SCRIPT_DO?a=view&user=$id");
	$r->is_success                 or RESULT_CORRUPT $r->status_line;
	
	my $data = $r->decoded_content;
	for (split /[\r\n]/,$data) 
	{
		my @a=split /;/;
		next if $a[0] ne $sender;
		
		my $rsa = Crypt::OpenSSL::RSA->new_private_key(uncut_priv($privkey));
		my $plaintext = $rsa->decrypt(decode_base64($a[2]));	### TODO: If ct is broken ??
		
		RESULT_OK if $plaintext eq $FLAG;	# << If flag found ! >>
	}
	RESULT_NOFLAG "Flag not found";
}

###############################################################################
#                        put - установка флага в сервис

sub put 
{
	@ARGV==2 or RESULT_ERROR "Missing arguments: flagid, flag";
	my ($FLAG_ID, $FLAG)=@ARGV;

	my %DB_USERS = LoadUsers();             # Пользователи из локальной базы
	my %REAL_USERS = GetUsersFromService(); # Пользователи из сервиса команды

	## Определим, сколько пользователей, зарегистрированных на сервисе, "наши".

	my @OUR_USERS = grep { exists $DB_USERS{$_} } keys %REAL_USERS;
	warn sprintf "Our users: %d (max %d)\n", 0+@OUR_USERS, $MAX_OUR_USERS;

	my ($id,$name);
	if (@OUR_USERS < $MAX_OUR_USERS) # Если еще не перебор - регистрируем нового
	{
		warn "Will register new user\n";

		$name  = CreateName();
		my $age   = 18 + int rand 60;
		my $email = CreateEmail($name);
		my $pass  = RandomStr(6+int rand 10);
		my $rand  = RandomHexStr(64);
	
		my ($privkey,$pubkey) = Register($name,$age,$email,$pass,$rand);
		defined $privkey or RESULT_CORRUPT "Cannot register new user";

		AddUser($name,$age,$email,$privkey);
		%REAL_USERS = GetUsersFromService();
		$id = $REAL_USERS{$name}->{id};
		if (!defined $id) {
			warn "AddUser succeeded, but user did not appear\n";
			RESULT_CORRUPT "New user did not appear in users list";
		}
	}
	else
	{
		warn "Will send message to existing user\n";

		$name = $OUR_USERS[int rand @OUR_USERS];
		$id = $REAL_USERS{$name}->{id};
	}
	my $sender = CreateName();
	warn "Sending message from '$sender' to '$name' (id=$id)\n";
	SendMessage($sender, $id, $FLAG);

	my $flagid = "from $sender to $name";
	$flagid =~ s/ /_/g;
	print "$flagid"; # New FlagID (!)
	RESULT_OK;
}

