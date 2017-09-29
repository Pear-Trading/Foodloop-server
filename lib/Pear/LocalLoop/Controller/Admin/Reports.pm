package Pear::LocalLoop::Controller::Admin::Reports;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw/ encode_json /;

sub transaction_data {
  my $c = shift;

  my $driver = $c->schema->storage->dbh->{Driver}->{Name};
  my $transaction_rs = $c->schema->resultset('ViewQuantisedTransaction' . $driver)->search(
    {},
    {
      columns => [
        'quantised_hours',
        {
          count            => \"COUNT(*)",
          sum_distance     => $c->pg_or_sqlite(
                                '',
                                'SUM("me"."distance")',
                              ),
          average_distance => $c->pg_or_sqlite(
                                '',
                                'AVG("me"."distance")',
                              ),
          sum_value        => $c->pg_or_sqlite(
                                '',
                                'SUM("me"."value")',
                              ),
          average_value    => $c->pg_or_sqlite(
                                '',
                                'AVG("me"."value")',
                              ),
        }
      ],
      group_by => 'quantised_hours',
      order_by => { '-asc' => 'quantised_hours' },
    }
  );

  $transaction_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');

  $c->stash(
    transaction_rs => encode_json( [$transaction_rs->all] ),
  );
}

sub pg_or_sqlite {
  my ( $c, $pg_sql, $sqlite_sql ) = @_;

  my $driver = $c->schema->storage->dbh->{Driver}->{Name};

  if ( $driver eq 'Pg' ) {
    return \$pg_sql;
  } elsif ( $driver eq 'SQLite' ) {
    return \$sqlite_sql;
  } else {
    $c->app->log->warn('Unknown Driver Used');
    return undef;
  }
}

1;
