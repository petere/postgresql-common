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
POD1PROGS = pg_conftool.1 \
	    pg_createcluster.1 \
	    pg_ctlcluster.1 \
	    pg_dropcluster.1 \
	    pg_lsclusters.1 \
	    pg_upgradecluster.1 \
	    pg_wrapper.1
POD1PROGS_POD = pg_buildext.1 \
		pg_virtualenv.1
POD8PROGS = pg_updatedicts.8

all: man

man: $(POD1PROGS) $(POD1PROGS_POD) $(POD8PROGS)

%.1: %.pod
	$(POD2MAN) --quotes=none --section 1 $< $@

%.1: %
	$(POD2MAN) --quotes=none --section 1 $< $@

%.8: %
	$(POD2MAN) --quotes=none --section 8 $< $@

clean:
	rm -f *.1 *.8


common_programs = pg_wrapper pg_conftool pg_createcluster pg_ctlcluster pg_dropcluster pg_lsclusters pg_updatedicts pg_upgradecluster

wrapped_programs = clusterdb createdb createlang createuser dropdb droplang dropuser pg_dump pg_dumpall pg_basebackup pg_isready pg_restore pg_receivexlog psql reindexdb vacuumdb vacuumlo pgbench


installdirs:
	$(INSTALL) -d $(DESTDIR)$(bindir) $(DESTDIR)$(pkgdatadir) $(DESTDIR)$(pkgsysconfdir) $(addprefix $(DESTDIR)$(mandir)/,man1 man5 man7 man8)

install: all installdirs
	$(INSTALL_DATA) PgCommon.pm $(DESTDIR)$(pkgdatadir)
	$(INSTALL_SCRIPT) $(common_programs) $(DESTDIR)$(bindir)
	$(INSTALL_DATA) $(POD1PROGS) $(DESTDIR)$(mandir)/man1
	$(INSTALL_DATA) $(POD8PROGS) $(DESTDIR)$(mandir)/man8
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
