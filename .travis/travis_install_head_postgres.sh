#!/usr/bin/env bash
set -x -e

PG_DATADIR="/etc/postgresql/${PG_VERSION}/main"

sudo service postgresql stop
sudo apt-get remove postgresql libpq-dev libpq5 postgresql-client-common postgresql-common -qq --purge

git clone --depth=1 https://github.com/postgres/postgres.git
cd postgres

# Build PostgreSQL from source
sudo ./configure && sudo make && sudo make install
sudo ln -s /usr/local/pgsql/bin/psql /usr/bin/psql
# Build contrib from source
cd contrib
sudo make all && sudo make install

#Post compile actions
LD_LIBRARY_PATH=/usr/local/pgsql/lib
export LD_LIBRARY_PATH
sudo /sbin/ldconfig /usr/local/pgsql/lib

sudo mkdir -p ${PG_DATADIR}
sudo chmod 777 ${PG_DATADIR}
sudo chown -R postgres:postgres ${PG_DATADIR}

sudo su postgres -c "/usr/local/pgsql/bin/pg_ctl -D ${PG_DATADIR} -U postgres initdb"
#Start head postgres
sudo su postgres -c "/usr/local/pgsql/bin/pg_ctl -D ${PG_DATADIR} -w -t 300 -o '-p 5432' -l /tmp/postgres.log start"
sudo tail /tmp/postgres.log