use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
my $schema = $t->app->schema;

my $start = DateTime->today->subtract( hours => 12 );

# create 30 days worth of data
for my $count ( 0 .. 29 ) {
  my $trans_day = $start->clone->subtract( days => $count );

  create_random_transaction( 'test1@example.com', $trans_day );
  if ( $count % 2 ) {
    create_random_transaction( 'test2@example.com', $trans_day );
  }
  if ( $count % 3 ) {
    create_random_transaction( 'test3@example.com', $trans_day );
  }
  if ( $count % 4 ) {
    create_random_transaction( 'test4@example.com', $trans_day );
  }
}

my $session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

$t->post_ok('/api/outgoing-transactions' => json => {
    session_key => $session_key,
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/success', Mojo::JSON->true)
  ->json_has('/transactions')
  ->json_has('/transactions/1/seller')
  ->json_has('/transactions/1/value')
  ->json_has('/transactions/1/purchase_time');

my $test_purchase_time = "2017-08-14T11:29:07.965+01:00";

$t->post_ok('/api/recurring-transactions' => json => {
  session_key      => $session_key,
  id               => 1,
  apply_time       => $test_purchase_time,
  essential        => "false",
  value            => 5,
  recurring_period => 'daily',
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->true,
    message => 'Recurring Transaction Updated Successfully',
  });

is $schema->resultset('TransactionRecurring')->count, 87;

$t->post_ok('/api/recurring-transactions/delete' => json => {
  session_key      => $session_key,
  id               => 1,
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is({
    success => Mojo::JSON->true,
    message => 'Recurring Transaction Deleted Successfully',
  });

is $schema->resultset('TransactionRecurring')->count, 86;


sub create_random_transaction {
  my $buyer = shift;
  my $time = shift;

  my $buyer_result = $schema->resultset('User')->find({ email => $buyer })->entity;
  my $seller_result = $schema->resultset('Organisation')->find({ name => 'Test Org' })->entity;
  $schema->resultset('Transaction')->create({
    buyer => $buyer_result,
    seller => $seller_result,
    value => 10,
    proof_image => 'a',
    purchase_time => $time,
  });
  $schema->resultset('TransactionRecurring')->create({
    buyer => $buyer_result,
    seller => $seller_result,
    value => 10,
    start_time => $time,
    essential => 1,
    recurring_period => 'weekly',
  });
}

done_testing;
