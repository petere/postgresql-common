PACKAGE_NAME = postgresql-common

prefix = /usr/local
bindir = $(prefix)/bin
datarootdir = $(prefix)/share
datadir = $(datarootdir)
pkgdatadir = $(datadir)/$(PACKAGE_NAME)
mandir = $(datarootdir)/man
sysconfdir = $(prefix)/etc
pkgsysconfdir = $(sysconfdir)/$(PACKAGE_NAME)
localstatedir = $(prefix)/var

GSED = gsed

INSTALL = install -c
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_SCRIPT = $(INSTALL) -m 755

POD2MAN=pod2man --center "Debian PostgreSQL infrastructure" -r "Debian"
POD1PROGS=pg_wrapper pg_lsclusters
POD8PROGS=pg_ctlcluster pg_createcluster pg_dropcluster

common_programs = pg_wrapper pg_createcluster pg_ctlcluster pg_dropcluster pg_lsclusters pg_upgradecluster

wrapped_programs = clusterdb createdb createlang createuser dropdb droplang dropuser pg_dump pg_dumpall pg_basebackup pg_isready pg_restore pg_receivexlog psql reindexdb vacuumdb vacuumlo pgbench


all:
	for p in $(POD1PROGS); do $(POD2MAN) --quotes=none --section 1 $$p > $$p.1 || exit 1; done
	for p in $(POD8PROGS); do $(POD2MAN) --quotes=none --section 8 $$p > $$p.8 || exit 1; done

installdirs:
	$(INSTALL) -d $(DESTDIR)$(bindir) $(DESTDIR)$(pkgdatadir) $(DESTDIR)$(pkgsysconfdir) $(addprefix $(DESTDIR)$(mandir)/,man1 man5 man7 man8)

install: all installdirs
	$(INSTALL_DATA) PgCommon.pm $(DESTDIR)$(pkgdatadir)
	$(INSTALL_SCRIPT) $(common_programs) $(DESTDIR)$(bindir)
	$(INSTALL_DATA) $(addsuffix .1,$(POD1PROGS)) $(DESTDIR)$(mandir)/man1
	$(INSTALL_DATA) $(addsuffix .8,$(POD8PROGS)) $(DESTDIR)$(mandir)/man8
	$(INSTALL_DATA) createcluster.conf user_clusters $(DESTDIR)$(pkgsysconfdir)
	$(INSTALL_DATA) postgresqlrc.5 user_clusters.5 $(DESTDIR)$(mandir)/man5
	$(GSED) -i \
	-e 's,/usr/share/postgresql-common,$(pkgdatadir),g' \
	-e 's,/etc/postgresql,$(sysconfdir)/postgresql,' \
	-e 's,/var/lib/postgresql,$(localstatedir)/lib/postgresql,' \
	-e 's,/var/log/postgresql,$(localstatedir)/log/postgresql,' \
	-e 's,/var/run/postgresql,$(localstatedir)/run/postgresql,' \
	-e 's,/bin:/usr/bin,$(bindir):/bin:/usr/bin,' \
	-e '/version/s,/usr/lib/postgresql/,/usr/local/opt/postgresql-,g' \
	$(addprefix $(DESTDIR)$(bindir)/,$(common_programs)) \
	$(DESTDIR)$(pkgsysconfdir)/createcluster.conf \
	$(DESTDIR)$(mandir)/man1/*.1 $(DESTDIR)$(mandir)/man5/*.5 $(DESTDIR)$(mandir)/man8/*.8 \
	$(DESTDIR)$(pkgdatadir)/PgCommon.pm
	for f in $(wrapped_programs); do (cd $(DESTDIR)$(bindir) && ln -f -s pg_wrapper $$f) || exit; done
	cd $(DESTDIR)$(mandir)/man7 && ln -f -s ../man1/pg_wrapper.1 postgresql-common.7
