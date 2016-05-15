#!/usr/bin/env bash
# Adapted from https://github.com/dockyard/reefpoints/blob/master/source/posts/2013-03-29-running-postgresql-9-2-on-travis-ci.md
set -x -e

sudo service postgresql stop
sudo cp /etc/postgresql/9.1/main/pg_hba.conf ./

if [ ! -d "/etc/postgresql/${PG_VERSION}/main" ];
then
    # Control will enter here if $DIRECTORY doesn't exist.
    sudo apt-get remove postgresql libpq-dev libpq5 postgresql-client-common postgresql-common -qq --purge
    source /etc/lsb-release
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $DISTRIB_CODENAME-pgdg main ${PG_VERSION}" > pgdg.list
    sudo mv pgdg.list /etc/apt/sources.list.d/
    wget --quiet -O - https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
    sudo apt-get update
    sudo apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install postgresql-${PG_VERSION} postgresql-contrib-${PG_VERSION} -qq
fi

if [ ${PG_VERSION} = '8.4' ]
then
  sudo sed -i -e 's/port = 5433/port = 5432/g' /etc/postgresql/8.4/main/postgresql.conf
fi

sudo cp ./pg_hba.conf /etc/postgresql/${PG_VERSION}/main

if [ ${REPLICATION} = 'Y' ]
then
    if (( $(echo "${PG_VERSION} >= 9.1" | bc -l)))
    then
        sudo sed -i -e 's/#max_wal_senders = 0/max_wal_senders = 4/g' /etc/postgresql/${PG_VERSION}/main/postgresql.conf
        sudo sed -i -e 's/#wal_keep_segments = 0/wal_keep_segments = 4/g' /etc/postgresql/${PG_VERSION}/main/postgresql.conf
        sudo sed -i -e 's/^#local\s\+replication\s\+postgres\s\+peer/local replication all peer/g' /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
        sudo sed -i -e 's/^#host\s\+replication\s\+postgres\s\+\(.*\)\s\+md5/host replication all \1 md5/g' /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
        if (( $(echo "${PG_VERSION} >= 9.4" | bc -l)))
        then
            sudo sed -i -e 's/#wal_level = minimal/wal_level = logical/g' /etc/postgresql/${PG_VERSION}/main/postgresql.conf
            sudo sed -i -e 's/#max_replication_slots = 0/max_replication_slots = 4/g' /etc/postgresql/${PG_VERSION}/main/postgresql.conf
        fi
    fi
fi

sudo sed -i -e 's/#max_prepared_transactions = 0/max_prepared_transactions = 64/g' /etc/postgresql/${PG_VERSION}/main/postgresql.conf

sudo service postgresql restart ${PG_VERSION}

sudo tail /var/log/postgresql/postgresql-${PG_VERSION}-main.log
