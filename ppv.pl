#!/usr/bin/perl
=head1 NAME

Pure perl pipe viewer

=head1 VERSION

Version 1

=cut

our $VERSION = '1';

=head1 SYNOPSIS

This is a pure perl pipe viewer to view progress of data being piped through STDIN to STDOUT. It is similar to the 'pv' command line tool.

Why? I needed 'pv' on MacOS and didn't want to bother installing ports.

=head1 USAGE

./ppv.pl <INPUTFILE >OUTPUTFILE

cat BIGFILE | gzip | ./ppv.pl | ssh somehost "gunzip | someothercomand >blargh"


=head1 AUTHOR

Mark Steele, C<< <mark at control-alt-del.org> >>
    
=cut

use IO::Select;
use Time::HiRes qw(time);
use Number::Bytes::Human qw(format_bytes);
use strict;

my $s = IO::Select->new();

$s->add(\*STDIN);

my $count = 0;
my $bytes = 0;
my $time = my $start = time();
my $totalbytes = 0;

while ($s->can_read()) {
  my $ret = sysread(STDIN,my $buf, 32768);  
  if ($ret == 0) {
    total();
  }
  my $now = time();
  $bytes += $ret;
  $totalbytes += $ret;
  if (($now - $time) >= 1) {
    printf STDERR "\rThroughput: %s/sec",format_bytes($bytes/($now-$time));
    $time = $now;
    $bytes = 0;
  }
  my $written = 0;
  while ($written != $ret) {
    $written += syswrite(STDOUT,$buf,$ret-$written,$written);
  }
}

total();

sub total {
    my $now = time();
    printf STDERR "\nBytes: %s (%s/sec) in %.02f seconds\n",format_bytes($totalbytes),format_bytes($totalbytes/($now-$start)),($now-$start);
    exit;
}
