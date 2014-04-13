#!/usr/bin/perl
#
#      ioup.pl - upload files to pub.iotek.org
#
#
#      Copyright (c) 2014, IOTek <patrick (at) iotek (dot) org>
#
#
#      Permission to use, copy, modify, and/or distribute this software for any
#      purpose with or without fee is hereby granted, provided that the above
#      copyright notice and this permission notice appear in all copies.
#
#      THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#      WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#      MERCHANTABILITY AND FITNESS IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#      ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#      WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#      ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#      OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
#
use strict;
use warnings;
use Net::Curl::Form qw(:constants);
use Net::Curl::Easy qw(:constants);

#Replace this with your own token
my $TOKEN       = "YOUR TOKEN GOES HERE";

my $VERSION     = 0.5;

#Nice Colours
my $HEADER      = "\033[95m";
my $OKBLUE      = "\033[94m";
my $OKGREEN     = "\033[92m";
my $WARNING     = "\033[93m";
my $FAIL        = "\033[91m";
my $ENDC        = "\033[0m";
my $INFO        = $HEADER . "[". $OKBLUE ."*" . $HEADER ."] ". $ENDC;
my $ARROW       = " ". $OKGREEN . ">> ". $ENDC;
my $PLUS        = $HEADER ."[" . $OKGREEN ."+" . $HEADER ."] ". $ENDC;
my $MINUS       = $HEADER ."[". $FAIL ."-". $HEADER ."] ". $ENDC;

#the curl handle
my $easy  =  Net::Curl::Easy->new({ body => '' });

sub help() {
	print $INFO."Usage: $0 [options] [file]\n";
	print "    
  -h          --help                  Display this usage information.
  -l          --list                  List current files associated with token.
  -lf         --fulllist              Same as -l but with full links
  [files ..]                          Upload the file listed to the server.
  -r [token ..]  --remove [tokens ..] Remove a file or many files (in form of p/Bl3hMo0 or file name)
  -v          --version               Display version.\n"; 
}

sub version() {
	print $INFO.$0."-".$VERSION."\n";
}

sub create_usual_form() {
	my $form = Net::Curl::Form->new();
	$form->add(
		CURLFORM_COPYNAME() => "token",
		CURLFORM_COPYCONTENTS() => $TOKEN
	);
	$form->add(
		CURLFORM_COPYNAME() => "is_ioup",
		CURLFORM_COPYCONTENTS() => "1"
	);
	$form->add( 
		CURLFORM_COPYNAME() => "submit",
		CURLFORM_COPYCONTENTS() => "sent"
	);
	return $form;
}

sub check_list() {
	$easy  =  Net::Curl::Easy->new({ body => '' });
	$easy->setopt( CURLOPT_URL, "http://pub.iotek.org/p/list.php" );
#	$easy->setopt( Net::Curl::Easy::CURLOPT_VERBOSE(), 1 );
	$easy->setopt( Net::Curl::Easy::CURLOPT_FILE(),\$easy->{body} );

	$easy->setopt( CURLOPT_HTTPPOST() => create_usual_form() );
	$easy->perform();
	return $easy->{body};
}

sub check_list_with_links() {
	$easy  =  Net::Curl::Easy->new({ body => '' });
	$easy->setopt( CURLOPT_URL, "http://pub.iotek.org/p/list.php" );
	$easy->setopt( Net::Curl::Easy::CURLOPT_FILE(),\$easy->{body} );

	$easy->setopt( CURLOPT_HTTPPOST() => create_usual_form() );
	$easy->perform();
	my @results = split /\n/, $easy->{body};
	my $result  = "";
	for (@results) {
		$result .= "http://pub.iotek.org/".$_."\n";
	}
	return $result;
}

sub get_remove_code($) {
	my $to_remove = $_[0];
	my $list = check_list();
	my @splits = split /\n/, (split /$to_remove/,$list) [0];
	$list = $splits[$#splits];
	$list =~ s/\t//;
	chomp $list;
	#make the body empty again;
	$easy->{body} = "";
	return $list;
}

sub remove_file($) {
	my $to_remove = $_[0];
	if (not substr($to_remove, 0, 2) eq "p/") {
		$to_remove = get_remove_code($to_remove);
	}
	$easy  =  Net::Curl::Easy->new({ body => '' });
	my $form = create_usual_form();
	$easy->setopt( CURLOPT_URL, "http://pub.iotek.org/remove.php" );

	$form->add(
		CURLFORM_COPYNAME() => $to_remove,
		CURLFORM_COPYCONTENTS() => "1"
	);
	$easy->setopt( CURLOPT_HTTPPOST() => $form );
	$easy->perform();
	print $PLUS."Removed file $_[0]\n";
}

sub upload_file($) {
	$easy  =  Net::Curl::Easy->new({ body => '' });
	$easy->setopt( CURLOPT_URL, "http://pub.iotek.org/post.php");
	my $form = create_usual_form();
	(my $file) = @_;
	if (-r $file && not -d $file) { #continue only if file is readable
		my $extension = "";
		if ($file =~/\./) {
			$extension = reverse( (split /\./,reverse $file)[0]);
		}
		$form->add(
			CURLFORM_COPYNAME() => "xt",
			CURLFORM_COPYCONTENTS() => $extension
		);
		$form->add(
			CURLFORM_COPYNAME() => "pdata",
			CURLFORM_FILE() => $file
		);

		$easy->setopt( CURLOPT_HTTPPOST() => $form );
		$easy->perform();
		print "\n".$PLUS."Uploaded file $file\n";
	}
	elsif (-d $file){
		#maybe upload all dir?
		print $MINUS."$file is a directory\n";
	}
	else {
		print $MINUS."Cannot access file $file\n";
	}
}

if ( $#ARGV < 0 ) {
	help;
}
else {
	if ( $ARGV[0] eq '-h' || $ARGV[0] eq '--help') {
		help;
	}
	elsif ( $ARGV[0] eq '-l' || $ARGV[0] eq '--list') {
		print check_list;
	}
	elsif ( $ARGV[0] eq '-lf' || $ARGV[0] eq '--fulllist') {
		print check_list_with_links;
	}
	elsif ( $ARGV[0] eq '-v' || $ARGV[0] eq '--version') {
		version;
	}
	elsif ( $ARGV[0] eq '-r' || $ARGV[0] eq '--remove') {
		shift @ARGV;
		if ($#ARGV<0) {
			print $MINUS."You must specify a file or a code to remove\n";
		}
		else {
			for (@ARGV) {
				remove_file($_);
			}
		}
	}
	else {
		for (@ARGV) {
			upload_file($_);
		}
	}
}

