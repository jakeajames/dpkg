#!/usr/bin/perl

use strict;
use warnings;

use POSIX;
use POSIX qw(:errno_h);
use Dpkg;
use Dpkg::Gettext;
use Dpkg::ErrorHandling qw(warning error syserr subprocerr usageerr);

textdomain("dpkg-dev");

my $format ='debian';
my $changelogfile = 'debian/changelog';
my @parserpath = ("/usr/local/lib/dpkg/parsechangelog",
                  "$dpkglibdir/parsechangelog");

my $libdir;	# XXX: Not used!?
my $force;


sub version {
    printf _g("Debian %s version %s.\n"), $progname, $version;

    printf _g("
Copyright (C) 1996 Ian Jackson.
Copyright (C) 2001 Wichert Akkerman");

    printf _g("
This is free software; see the GNU General Public Licence version 2 or
later for copying conditions. There is NO warranty.
");
}

sub usage {
    printf _g(
"Usage: %s [<option> ...]

Options:
  -l<changelogfile>        get per-version info from this file.
  -v<sinceversion>         include all changes later than version.
  -F<changelogformat>      force change log format.
  -L<libdir>               look for change log parsers in <libdir>.
  -h, --help               show this help message.
      --version            show the version.
"), $progname;
}

my @ap = ();
while (@ARGV) {
    last unless $ARGV[0] =~ m/^-/;
    $_= shift(@ARGV);
    if (m/^-L/ && length($_)>2) { $libdir=$'; next; }
    if (m/^-F([0-9a-z]+)$/) { $force=1; $format=$1; next; }
    push(@ap,$_);
    if (m/^-l/ && length($_)>2) { $changelogfile=$'; next; }
    m/^--$/ && last;
    m/^-v/ && next;
    if (m/^-(h|-help)$/) { &usage; exit(0); }
    if (m/^--version$/) { &version; exit(0); }
    &usageerr("unknown option \`$_'");
}

@ARGV && usageerr(_g("%s takes no non-option arguments"), $progname);
$changelogfile= "./$changelogfile" if $changelogfile =~ m/^\s/;

if (not $force and $changelogfile ne "-") {
    open(STDIN,"< $changelogfile") ||
        error(_g("cannot open %s to find format: %s"), $changelogfile, $!);
    open(P,"tail -n 40 |") || die sprintf(_g("cannot fork: %s"), $!)."\n";
    while(<P>) {
        next unless m/\schangelog-format:\s+([0-9a-z]+)\W/;
        $format=$1;
    }
    close(P);
    $? && subprocerr(_g("tail of %s"), $changelogfile);
}

my ($pa, $pf);

for my $pd (@parserpath) {
    $pa= "$pd/$format";
    if (!stat("$pa")) {
        $! == ENOENT || syserr(_g("failed to check for format parser %s"), $pa);
    } elsif (!-x _) {
	warning(_g("format parser %s not executable"), $pa);
    } else {
        $pf= $pa;
	last;
    }
}
        
defined($pf) || error(_g("format %s unknown"), $pa);

if ($changelogfile ne "-") {
    open(STDIN,"< $changelogfile") || die sprintf(_g("cannot open %s: %s"), $changelogfile, $!)."\n";
}
exec($pf,@ap); die sprintf(_g("cannot exec format parser: %s"), $!)."\n";

