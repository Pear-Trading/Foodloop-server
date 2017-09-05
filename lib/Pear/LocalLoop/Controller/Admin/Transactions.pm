package Pear::LocalLoop::Controller::Admin::Transactions;
use Mojo::Base 'Mojolicious::Controller';

has result_set => sub {
  my $c = shift;
  return $c->schema->resultset('Transaction');
};

sub index {
  my $c = shift;

  my $transactions = $c->result_set->search(
    undef, {
      page => $c->param('page') || 1,
      rows => 10,
      order_by => { -desc => 'submitted_at' },
    },
  );
  $c->stash(
    transactions => $transactions,
  );
}

sub read {
  my $c = shift;

  my $id = $c->param('id');

  if ( my $transaction = $c->result_set->find($id) ) {
    $c->stash( transaction => $transaction );
  } else {
    $c->flash( error => 'No transaction found' );
    $c->redirect_to( '/admin/transactions' );
  }
}

sub image {
  my $c = shift;

  my $id = $c->param('id');

  my $transaction = $c->result_set->find($id);

  if ( $transaction->proof_image ) {
    $c->reply->asset($c->get_file_from_uuid($transaction->proof_image));
  }
}

1;
