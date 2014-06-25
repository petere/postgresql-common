Name:           postgresql-common
Version:        158
Release:        1%{?dist}
BuildArch:      noarch
Summary:        PostgreSQL database-cluster manager
Packager:       Debian PostgreSQL Maintainers <pkg-postgresql-public@lists.alioth.debian.org>

License:        GPLv2+
URL:            https://packages.debian.org/sid/%{name}
Source0:        http://ftp.debian.org/debian/pool/main/p/%{name}/%{name}_%{version}.tar.xz

%description
The postgresql-common package provides a structure under which
multiple versions of PostgreSQL may be installed and/or multiple
clusters maintained at one time.

%package -n postgresql-client-common
Summary: manager for multiple PostgreSQL client versions
%description -n postgresql-client-common
The postgresql-client-common package provides a structure under which
multiple versions of PostgreSQL client programs may be installed at
the same time. It provides a wrapper which selects the right version
for the particular cluster you want to access (with a command line
option, an environment variable, /etc/postgresql-common/user_clusters,
or ~/.postgresqlrc).

%package -n postgresql-server-dev-all
Summary: extension build tool for multiple PostgreSQL versions
%description -n postgresql-server-dev-all
The postgresql-server-dev-all package provides the pg_buildext script for
simplifying packaging of a PostgreSQL extension supporting multiple major
versions of the product.

%prep
# unpack tarball, ignoring the name of the top level directory inside
%setup -c
mv */* .

%build
make

%install
rm -rf %{buildroot}
# install in subpackages using the Debian files
for inst in debian/*.install; do
    pkg=$(basename $inst .install)
    echo "### Reading $pkg files list from $inst ###"
    while read file dir; do
        mkdir -p %{buildroot}/$dir
        cp -r $file %{buildroot}/$dir
        echo "/$dir/${file##*/}" >> files-$pkg
    done < $inst
done
# install manpages
for manpages in debian/*.manpages; do
    pkg=$(basename $manpages .manpages)
    echo "### Reading $pkg manpages list from $manpages ###"
    while read file; do
        section="${file##*.}"
        mandir="%{buildroot}%{_mandir}/man$section"
        mkdir -p $mandir
        for f in $file; do # expand wildcards
            cp $f $mandir
            echo "%doc %{_mandir}/man$section/$f.gz" >> files-$pkg
        done
    done < $manpages
done
# install pg_wrapper symlinks by augmenting the existing pgdg.rpm alternatives
while read dest link; do
    name="pgsql-$(basename $link)"
    echo "update-alternatives --install /$link $name /$dest 9999" >> postgresql-client-common.post
    echo "update-alternatives --remove $name /$dest" >> postgresql-client-common.preun
done < debian/postgresql-client-common.links
# activate rpm-specific tweaks
sed -i -e 's/#redhat# //' \
    %{buildroot}/usr/bin/pg_config \
    %{buildroot}/usr/bin/pg_virtualenv \
    %{buildroot}/usr/share/postgresql-common/PgCommon.pm \
    %{buildroot}/usr/share/postgresql-common/init.d-functions
# install init script
mkdir -p %{buildroot}/etc/init.d %{buildroot}/etc/logrotate.d
cp debian/postgresql-common.postgresql.init %{buildroot}/etc/init.d/postgresql
#cp debian/postgresql-common.postinst %{buildroot}/usr/share/postgresql-common
cp rpm/init-functions-compat %{buildroot}/usr/share/postgresql-common
# ssl defaults to 'off' here because we don't have pregenerated snakeoil certs
sed -e 's/__SSL__/off/' createcluster.conf > %{buildroot}/etc/postgresql-common/createcluster.conf
cp debian/logrotate.template %{buildroot}/etc/logrotate.d/postgresql-common

%files -n postgresql-common -f files-postgresql-common
%attr(0755, root, root) %config /etc/init.d/postgresql
#%attr(0755, root, root) /usr/share/postgresql-common/postgresql-common.postinst
/usr/share/postgresql-common/init-functions-compat
%config /etc/postgresql-common/createcluster.conf
%config /etc/logrotate.d/postgresql-common

%files -n postgresql-client-common -f files-postgresql-client-common

%files -n postgresql-server-dev-all -f files-postgresql-server-dev-all

%post
## RedHat's adduser is different, create the user here
#if ! getent passwd postgres > /dev/null; then
#    adduser --system --home /var/lib/postgresql --no-create-home \
#            --shell /bin/bash --comment "PostgreSQL administrator" postgres
#fi
#sh -x /usr/share/postgresql-common/postgresql-common.postinst "configure"
version_lt () {
    newest=$( ( echo "$1"; echo "$2" ) | sort -V | tail -n1)
    [ "$1" != "$newest" ]
}
lrversion=$(rpm --queryformat '%{VERSION}' -q logrotate)
if version_lt $lrversion 3.8; then
    echo "Adjusting /etc/logrotate.d/postgresql-common for logrotate version $lrversion"
    sed -i -e '/ su /d' /etc/logrotate.d/postgresql-common || :
fi

%post -n postgresql-client-common -f postgresql-client-common.post

%preun -n postgresql-client-common -f postgresql-client-common.preun

%changelog
* Thu Jun  5 2014 Christoph Berg <christoph.berg@credativ.de> 158-1
- Initial specfile version
