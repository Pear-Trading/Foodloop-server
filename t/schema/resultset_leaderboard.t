use Mojo::Base -strict;

use Test::More;
use Mojo::JSON;
use Test::Pear::LocalLoop;
use DateTime;

my $framework = Test::Pear::LocalLoop->new;
my $t = $framework->framework;
my $schema = $t->app->schema;
my $dtf = $schema->storage->datetime_parser;

my $user1 = {
  token        => 'a',
  full_name    => 'Test User1',
  display_name => 'Test User1',
  email        => 'test1@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $user2 = {
  token        => 'b',
  full_name    => 'Test User2',
  display_name => 'Test User2',
  email        => 'test2@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $user3 = {
  token        => 'c',
  full_name    => 'Test User3',
  display_name => 'Test User3',
  email        => 'test3@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $user4 = {
  token        => 'd',
  full_name    => 'Test User4',
  display_name => 'Test User4',
  email        => 'test4@example.com',
  postcode     => 'LA1 1AA',
  password     => 'abc123',
  year_of_birth => 2006,
};

my $org = {
  token       => 'e',
  email       => 'test5@example.com',
  name        => 'Test Org',
  street_name => 'Test Street',
  town        => 'Lancaster',
  postcode    => 'LA1 1AA',
  password    => 'abc123',
};

$schema->resultset('AccountToken')->create({ name => $_->{token} })
  for ( $user1, $user2, $user3, $user4, $org );

$framework->register_customer($_)
  for ( $user1, $user2, $user3, $user4 );

$framework->register_organisation($org);

my $org_result = $schema->resultset('Organisation')->find({ name => $org->{name} });

my $tweak = 0;

my $now = DateTime->today();

for my $user ( $user1, $user2, $user3, $user4 ) {
  $tweak ++;
  my $user_result = $schema->resultset('User')->find({ email => $user->{email} });
  for ( 1 .. 10 ) {
    $user_result->create_related( 'transactions', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
    });
  }

  for ( 11 .. 20 ) {
    $user_result->create_related( 'transactions', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      submitted_at => $dtf->format_datetime($now->clone->subtract( days => 5 )),
    });
  }

  for ( 21 .. 30 ) {
    $user_result->create_related( 'transactions', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      submitted_at => $dtf->format_datetime($now->clone->subtract( days => 25 )),
    });
  }

  for ( 31 .. 40 ) {
    $user_result->create_related( 'transactions', {
      seller_id => $org_result->id,
      value => $_ + $tweak,
      proof_image => 'a',
      submitted_at => $dtf->format_datetime($now->clone->subtract( days => 50 )),
    });
  }

  is $user_result->transactions->count, 40, 'correct count for user' . $tweak;
}

sub test_leaderboard {
  my ( $title, $name, $date, $expected ) = @_;

  subtest $title => sub {
    my $leaderboard_rs = $schema->resultset('Leaderboard');

    $leaderboard_rs->create_new( $name, $date );
    
    my $today_board = $leaderboard_rs->get_latest( $name );

    is $today_board->values->count, 4, 'correct value count';

    my $today_values = $today_board->values->search(
      {},
      {
        order_by => { -desc => 'value' },
        columns => [ qw/ user_id value position / ],
      },
    );
    $today_values->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

    is_deeply [ $today_values->all ], $expected, 'array as expected';
  };
}

test_leaderboard(
  'Daily Total',
  'daily_total',
  $now,
  [
    { user_id => 4, value => 95, position => 1 },
    { user_id => 3, value => 85, position => 2 },
    { user_id => 2, value => 75, position => 3 },
    { user_id => 1, value => 65, position => 4 },
  ]
);

test_leaderboard(
  'Daily Count',
  'daily_count',
  $now,
  [
    { user_id => 1, value => 10, position => 1 },
    { user_id => 2, value => 10, position => 2 },
    { user_id => 3, value => 10, position => 3 },
    { user_id => 4, value => 10, position => 4 },
  ]
);

test_leaderboard(
  'Weekly Total',
  'weekly_total',
  $now->clone->subtract( days => 7 ),
  [
    { user_id => 4, value => 195, position => 1 },
    { user_id => 3, value => 185, position => 2 },
    { user_id => 2, value => 175, position => 3 },
    { user_id => 1, value => 165, position => 4 },
  ]
);

test_leaderboard(
  'Weekly Count',
  'weekly_count',
  $now->clone->subtract( days => 7 ),
  [
    { user_id => 1, value => 10, position => 1 },
    { user_id => 2, value => 10, position => 2 },
    { user_id => 3, value => 10, position => 3 },
    { user_id => 4, value => 10, position => 4 },
  ]
);

test_leaderboard(
  'Monthly Total',
  'monthly_total',
  $now->clone->subtract( months => 1 ),
  [
    { user_id => 4, value => 490, position => 1 },
    { user_id => 3, value => 470, position => 2 },
    { user_id => 2, value => 450, position => 3 },
    { user_id => 1, value => 430, position => 4 },
  ]
);

test_leaderboard(
  'Monthly Count',
  'monthly_count',
  $now->clone->subtract( months => 1 ),
  [
    { user_id => 1, value => 20, position => 1 },
    { user_id => 2, value => 20, position => 2 },
    { user_id => 3, value => 20, position => 3 },
    { user_id => 4, value => 20, position => 4 },
  ]
);

test_leaderboard(
  'All Time Total',
  'all_time_total',
  $now,
  [
    { user_id => 4, value => 980, position => 1 },
    { user_id => 3, value => 940, position => 2 },
    { user_id => 2, value => 900, position => 3 },
    { user_id => 1, value => 860, position => 4 },
  ]
);

test_leaderboard(
  'All Time Count',
  'all_time_count',
  $now,
  [
    { user_id => 1, value => 40, position => 1 },
    { user_id => 2, value => 40, position => 2 },
    { user_id => 3, value => 40, position => 3 },
    { user_id => 4, value => 40, position => 4 },
  ]
);

subtest 'get_latest' => sub {
  my $leaderboard_rs = $schema->resultset('Leaderboard');
  $leaderboard_rs->create_new( 'daily_total', $now->clone->subtract(days => 5));
  $leaderboard_rs->create_new( 'daily_total', $now->clone->subtract(days => 25));
  $leaderboard_rs->create_new( 'daily_total', $now->clone->subtract(days => 50));

  my $today_board = $leaderboard_rs->get_latest( 'daily_total' );

  is $today_board->values->count, 4, 'correct value count';

  my $today_values = $today_board->values->search(
    {},
    {
      order_by => { -desc => 'value' },
      columns => [ qw/ user_id value position / ],
    },
  );
  $today_values->result_class( 'DBIx::Class::ResultClass::HashRefInflator' );

  my $expected = [
    { user_id => 4, value => 95, position => 1 },
    { user_id => 3, value => 85, position => 2 },
    { user_id => 2, value => 75, position => 3 },
    { user_id => 1, value => 65, position => 4 },
  ];

  is_deeply [ $today_values->all ], $expected, 'array as expected';

  is $leaderboard_rs->find_by_type( 'daily_total' )->sets->count, 4, 'correct leaderboard count';
};

done_testing;