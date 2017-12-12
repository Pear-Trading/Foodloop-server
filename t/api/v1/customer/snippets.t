use Mojo::Base -strict;

use FindBin qw/ $Bin /;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new(
  etc_dir => "$Bin/../../../etc",
);
$framework->install_fixtures('users');

my $t = $framework->framework;
my $schema = $t->app->schema;

$t->app->schema->resultset('Leaderboard')->create_new( 'monthly_total', DateTime->now->truncate(to => 'month' )->subtract( months => 1) );

my $start = DateTime->today->subtract( hours => 12 );

# create 30 days worth of data
for my $count ( 0 .. 60 ) {
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

$t->post_ok('/api/v1/customer/snippets' => json => {
    session_key => $session_key,
  })
  ->status_is(200)->or($framework->dump_error)
  ->json_is('/snippets', {
      user_sum => 610,
      user_position => 1,
  });

$framework->logout( $session_key );

$session_key = $framework->login({
  email => 'test1@example.com',
  password => 'abc123',
});

sub create_random_transaction {
  my $buyer = shift;
  my $time = shift;

  my $buyer_result = $schema->resultset('User')->find({ email => $buyer })->entity;
  my $seller_result = $schema->resultset('Organisation')->find({ name => 'Test Org' })->entity;
  $schema->resultset('Transaction')->create({
    buyer => $buyer_result,
    seller => $seller_result,
    value => 10 * 100000,
    proof_image => 'a',
    purchase_time => $time,
  });
}

done_testing;
