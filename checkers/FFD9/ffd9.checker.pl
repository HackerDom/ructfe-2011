#!/usr/bin/perl -lw

use 5.10.0;
use strict;
use Mojo::UserAgent;
use Mojo::URL;
use Barcode::Code128;
use File::Temp 'tempfile';
use Digest::MD5 'md5_hex';
use File::Slurp;
use Data::Dumper;

my ($SERVICE_OK, $FLAG_GET_ERROR, $SERVICE_CORRUPT,
	$SERVICE_FAIL, $INTERNAL_ERROR) = (101, 102, 103, 104, 110);
my %MODES = (check => \&check, get => \&get, put => \&put);

my ($mode, $ip) = splice @ARGV, 0, 2;

unless (defined $mode and defined $ip) {
	warn "Invalid input data. Empty mode or ip address.";
	exit $INTERNAL_ERROR;
}

unless ($mode ~~ %MODES and $ip =~ /(\d{1,3}\.){3}\d{1,3}/) {
	warn "Invalid input data. Corrupt mode or ip address.";
	exit $INTERNAL_ERROR;
}

my $url = Mojo::URL->new();
$url->scheme('http');
$url->host($ip);
$url->port(80);

my $check_error = sub {
	my $res = shift;
	if ($res->error) {
		warn $res->error;
		print $res->error;
		exit $SERVICE_FAIL;
	}
};

my $login = sub {
	my ($ua, $un, $up) = @_;
	$url->path('/login');
	my $res = $ua->post_form($url, {user_name => $un, user_pass => $up})->res;
	$check_error->($res);
	my $js = $res->json;
	unless (defined $js and $js->{ok} != 0) {
		print 'Login fail';
		exit $SERVICE_CORRUPT;
	}
	warn 'Login successful';
	return $js->{url};
};

my $register = sub {
	my ($ua, $un, $up) = @_;
	$url->path('/registration');
	warn "Try register user '$un' with password '$up'";
	my $res = $ua->post_form($url, {user_name => $un, user_pass => $up})->res;
	$check_error->($res);
	my $js = $res->json;
	unless (defined $js and $js->{ok} != 0) {
		print 'Registration fail';
		warn 'Registration fail';
		exit $SERVICE_CORRUPT;
	}
	warn 'Registration successful';
};

my $generate_barcode = sub {
	my ($string, $border) = @_;
	$border //= 5;
	my $barcode = Barcode::Code128->new();
	my $data = $barcode->png($string, {
			show_text => 0,
			border => $border,
			scale => 6,
			padding => 30
	});
	my ($fh, $filename) = tempfile('tmpflagXXXXXXXXXX', DIR => '.', SUFFIX => '.png', UNLINK => 1);
	binmode $fh;
	print $fh $data;
	close $fh;
	my $fdata = read_file($filename);
	my $md5 = md5_hex $fdata;
	return ($md5, $filename);
};

$MODES{$mode}->(@ARGV);
exit $SERVICE_OK;

sub check {
	warn "check $ip";
	my $ua = Mojo::UserAgent->new();
	$url->path('/');
	my $res = $ua->get($url)->res;
	$check_error->($res);
	my $title = $res->dom->find('html div#intro p')->first;
	unless (defined $title and $title->text =~ /ffd9 web site/i) {
		print 'Main page corrupt';
		exit $SERVICE_CORRUPT;
	}
	my ($un, $up) = (rname(), rname());
	$register->($ua, $un, $up);
	$login->($ua, $un, $up);

	my $barcode_data = rname();

	$url->path('/user/add/album');
	my $album = rname();
	warn "Album name: $album";
	$res = $ua->post_form($url, {album_private => 1, album_name => $album})->res;
	$check_error->($res);
	my $js = $res->json;
	unless (defined $js and $js->{ok} != 0) {
		print 'Album added fail';
		print $js->{message} if $js;
		exit $SERVICE_CORRUPT;
	}
	warn 'Album added successful';
	warn $js->{url};
	$js->{url} =~ /([0-9a-f]{24})/;
	my $aid = $1;
	warn $aid;
	my ($flag_md5_1, $filename_1) = $generate_barcode->($barcode_data);
	my ($flag_md5_2, $filename_2) = $generate_barcode->($barcode_data, 60);
	$url->path('/user/add/photo');
	$res = $ua->post_form($url, {
					input_file_1 => {file => $filename_1},
					input_file_2 => {file => $filename_2},
					aid => $aid
				})->res;
	$check_error->($res);
	if ($res->code == 200) {
		warn $res->dom->find('p.error')->first->text;
		exit $SERVICE_CORRUPT;
	}
	warn 'photos upload successful';
	$url->path('/user/album/' . $aid);
	$res = $ua->get($url)->res;
	$check_error->($res);
	my @photos = ();
	for my $p ($res->dom->find('div#photos img')->each) {
		push @photos, $p->{src};
	}
	$url->path('/find');
	$res = $ua->post_form($url, {magick_input => '-60', searh_image => {file => $filename_1}})->res;
	$check_error->($res);
	my $result = $res->dom->find('div#find_result img');
	warn $result->size;
	my @search_photos = ();
	for my $i ($result->each) {
		push @search_photos, $i->{src};
	}
	my $ok = 0;
	for my $p (@photos) {
		$ok += $p ~~ @search_photos;
	}
	warn $ok;
	if ($ok != 1) {
		print 'search not working properly';
		exit $SERVICE_CORRUPT;
	}
	warn 'search work properly';
	$url->path('/user/del/album/' . $aid);
	$res = $ua->get($url)->res;
	$check_error->($res);
	$js = $res->json;
	warn $js->{message};
	exit $SERVICE_OK;
}

sub get {
	my ($id, $flag) = @_;
	# check input
	warn "get $ip";

	my $ua = Mojo::UserAgent->new();

	my @id = split ':', $id;
	my ($un, $up) = splice @id, 0, 2;
	my $home_url = $login->($ua, $un, $up);

	# album list
	$url->path($home_url);
	my $res = $ua->get($url)->res;
	$check_error->($res);
	my @albums;
	for my $album ($res->dom->find('ul#album_list li a')->each) {
		warn $album->text;
		push @albums, $album->text;
	}

	unless (@id) {
		unless ($flag ~~ @albums) {
			warn 'flag not exist';
			exit $FLAG_GET_ERROR;
		}
	} elsif (@id == 2) {
		my ($aid, $md5) = @id;
		$url->path('/user/album/' . $aid);
		$res = $ua->get($url)->res;
		$check_error->($res);
		my $imgs = $res->dom->find('div#photos img');
		if ($imgs->size > 1) {
			warn 'too large image in private album';
			print 'too large image in private album';
			exit $SERVICE_CORRUPT;
		}
		my $photo_url = $imgs->first->{src};
		warn $photo_url;
		$url->path($photo_url);
		$res = $ua->get($url)->res;
		$check_error->($res);
		my $photo_md5 = md5_hex $res->body;
		warn $photo_md5;
		unless ($photo_md5 eq $md5) {
			warn 'flag not exist';
			exit $FLAG_GET_ERROR;
		}
	} else {
		warn 'bad id input';
		exit $INTERNAL_ERROR;
	}
	exit $SERVICE_OK;
}

sub put {
	my ($id, $flag) = @_;
	# check input ...
	warn "put $ip $id $flag";
	my $ua = Mojo::UserAgent->new();

	my ($un, $up) = (rname(), rname());
	$register->($ua, $un, $up);
	$login->($ua, $un, $up);

	# album
	$url->path('/user/add/album');
	my $type = int rand 3;
	my $album;
	if ($type) {
		warn 'flag -- name of album';
		$album = $flag;
	} else {
		warn 'flag -- data in barcode image';
		$album = rname();
	}
	warn "Album name: $album";
	my $res = $ua->post_form($url, {album_private => 1, album_name => $album})->res;
	$check_error->($res);
	my $js = $res->json;
	unless (defined $js and $js->{ok} != 0) {
		print 'Album added fail';
		print $js->{message} if $js;
		exit $SERVICE_CORRUPT;
	}
	warn 'Album added successful';
	warn $js->{url};
	$js->{url} =~ /([0-9a-f]{24})/;
	my $aid = $1;
	if ($type) {
		# return new flag id
		# username:password
		print "$un:$up";
		exit $SERVICE_OK;
	} else {
		my ($flag_md5, $filename) = $generate_barcode->($flag);
		# post image
		$url->path('/user/add/photo');
		$res = $ua->post_form($url, {input_file_1 => {file => $filename}, aid => $aid})->res;
		$check_error->($res);
		if ($res->code == 200) {
			warn $res->dom->find('p.error')->first->text;
			exit $SERVICE_CORRUPT;
		}
		if ($res->code == 302) {
			warn 'image upload success: ' . $res->headers->location;
			# username:password:aid:md5
			print "$un:$up:$aid:$flag_md5";
			exit $SERVICE_OK;
		}
	}
}

sub rname {
	my $count = shift || 12;
	my $name = '';

	$name .= chr 97 + int rand 26  for (1 .. $count);
	return $name;
}
