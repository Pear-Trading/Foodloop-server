# LocalSpend - Server

This repository contains the server for the LocalSpend system.

## Current Status

*Master:* [![Build Status](https://travis-ci.org/Pear-Trading/Foodloop-Server.svg?branch=master)](https://travis-ci.org/Pear-Trading/Foodloop-Server)

*Development:* [![Build Status](https://travis-ci.org/Pear-Trading/Foodloop-Server.svg?branch=development)](https://travis-ci.org/Pear-Trading/Foodloop-Server)

# Test Environment

## Running Tests

To run the main test framework, first install all the dependencies, then run 
the tests:

- `cpanm --installdeps .`
- `prove -lr`

To run the main framework against a PostgreSQL backend, assuming you have 
`postgres` installed, you will need some extra dependencies first:

- `cpanm --installdeps . --with-feature postgres`
- `PEAR_TEST_PG=1 prove -lr`

## Setting Up Minion

To set up Minion support, you will need to create a database and user for
it to connect to.
In production his should be a PostgreSQL database, however SQLite can be used 
in testing.

To use the SQLite version:

1. Install the SQLite dependencies:
    - `cpanm --installdeps --with-feature sqlite .`
2. Ensure that the following is in your configuration file:
    - ```
      minion => {
        SQLite => 'sqlite:minion.db',
      },
      ```

This will then use an SQLite DB for the Minion backend, using `minion.db` as
the database file.

To start the minion itself, run this command:
- `./script/pear-local_loop minion worker`

## Importing Ward Data

To import ward data:

1. Download CSV(s) from [here](https://www.doogal.co.uk/PostcodeDownloads.php)
1. Run the following command:
    - ```shell script
      ./script/pear-local_loop minion job \
        --enqueue 'csv_postcode_import'  \
        --args '[ "⟨ path to CSV ⟩ ]'
      ```

## Setting Up Entity Postcodes

1. Import Code-Point Open:
    - included in `etc/`
    - `./script/pear-local_loop codepoint_open --outcodes LA1`
1. Assign postcodes:
    - ```shell script
      ./script/pear-local_loop minion job \
        --enqueue entity_postcode_lookup
      ```

## Example PostgreSQL setup

```
# Example commands - probably not the best ones
# TODO come back and improve these with proper ownership and DDL rights
sudo -u postgres createuser minion
sudo -u postgres createdb localloop_minion
sudo -u postgres psql
psql=# alter user minion with encrypted password 'abc123';
psql=# grant all privileges on database localloop_minion to minion;
```

# Development Environment

There are a couple of setup steps to getting a development environment ready.

## First Time Setup

1. Decide if you're using SQLite or PostgreSQL locally.
    - Development supports both, however production uses PostgreSQL. 
    - For this example we will use SQLite.
    - As the default config. is set up for this, no configuration changes are
needed initially.
1. Install dependencies:
    - `cpanm --installdeps . --with-feature=sqlite --with-feature=codepoint-open`
1. Install the database:
    - `./script/deploy_db install -c 'dbi:SQLite:dbname=foodloop.db'`
1. Set up the development users:
    - `./script/pear-local_loop dev_data --force`
    - ***DO NOT RUN ON PROD.***
1. Start the minion:
    - `./script/pear-local_loop minion worker`
1. Import ward data (see [instructions](#importing-ward-data) above)
1. Set up postcodes (see [intructions](#setting-up-entity-postcodes) above)
1. Start the application:
    - `morbo script/pear-local_loop -l http://*:3000`
    - You can modify the host and port as needed.

## Database Scripts

To upgrade the database after making changes to commit:

```
./script/deploy_db write_ddl -c 'dbi:SQLite:dbname=foodloop.db'
./script/deploy_db upgrade -c 'dbi:SQLite:dbname=foodloop.db'
```

To redo leaderboards:

```
./script/pear-local_loop recalc_leaderboards
```
