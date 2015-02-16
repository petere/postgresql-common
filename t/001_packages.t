# Check that the necessary packages are installed

use strict;

use lib 't';
use TestLib;
use POSIX qw/setlocale LC_ALL LC_MESSAGES/;

use Test::More tests => $PgCommon::rpm ? (8*@MAJORS) : (3 + 1*@MAJORS);

note "PostgreSQL versions installed: @MAJORS\n";

if ($PgCommon::rpm) {
    foreach my $v (@MAJORS) {
        my $vv = $v;
        $vv =~ s/\.//;

        ok ((rpm_installed "postgresql$vv"),          "postgresql$vv installed");
        ok ((rpm_installed "postgresql$vv-libs"),     "postgresql$vv-libs installed");
        ok ((rpm_installed "postgresql$vv-server"),   "postgresql$vv-server installed");
        ok ((rpm_installed "postgresql$vv-contrib"),  "postgresql$vv-contrib installed");
        ok ((rpm_installed "postgresql$vv-plperl"),   "postgresql$vv-plperl installed");
        ok ((rpm_installed "postgresql$vv-plpython"), "postgresql$vv-plpython installed");
        ok ((rpm_installed "postgresql$vv-pltcl"),    "postgresql$vv-pltcl installed");
        ok ((rpm_installed "postgresql$vv-devel"),    "postgresql$vv-devel installed");
    }
    exit;
}

foreach my $v (@MAJORS) {
    ok ((deb_installed "postgresql-$v"), "postgresql-$v installed");
}

# check installed locales to fail tests early if they are missing
ok ((setlocale(LC_MESSAGES, '') =~ /utf8|UTF-8/), 'system has a default UTF-8 locale');
ok (setlocale (LC_ALL, "ru_RU.KOI8-R"), 'locale ru_RU exists');
ok (setlocale (LC_ALL, "ru_RU.UTF-8"), 'locale ru_RU.UTF-8 exists');

# vim: filetype=perl
