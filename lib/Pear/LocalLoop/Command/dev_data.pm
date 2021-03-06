package Pear::LocalLoop::Command::dev_data;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

has description => 'Input Dev Data';

has usage => sub { shift->extract_usage };

sub run {
  my ( $self, @args ) = @_;

  getopt \@args,
    'f|force' => \my $force;

  unless ( defined $force ) {
    say "Will not do anything without force option";
    return;
  }

  if ( ( defined( $ENV{MOJO_MODE} ) && $ENV{MOJO_MODE} eq 'production' ) || $self->app->mode eq 'production' ) {
    say "Will not run dev data fixtures in production!";
    return;
  }

  my $schema = $self->app->schema;

  $schema->resultset('User')->create({
    email => 'test@example.com',
    password => 'abc123',
    entity => {
      type => 'customer',
      customer => {
        full_name => 'Test User',
        display_name => 'Test User',
        year_of_birth => 2006,
        postcode => 'LA1 1AA',
      }
    },
    is_admin => 1,
  });

  $schema->resultset('User')->create({
    email => 'test2@example.com',
    password => 'abc123',
    entity => {
      type => 'customer',
      customer => {
        full_name => 'Test User 2',
        display_name => 'Test User 2',
        year_of_birth => 2006,
        postcode => 'LA1 1AA',
      },
    },
  });

  $schema->resultset('User')->create({
    email => 'test3@example.com',
    password => 'abc123',
    entity => {
      type => 'customer',
      customer => {
        full_name => 'Test User 3',
        display_name => 'Test User 3',
        year_of_birth => 2006,
        postcode => 'LA1 1AA',
      },
    },
  });

  $schema->resultset('User')->create({
    email       => 'testorg@example.com',
    password    => 'abc123',
    entity => {
      type => 'organisation',
      organisation => {
        name        => 'Test Org',
        street_name => 'Test Street',
        town        => 'Lancaster',
        postcode    => 'LA1 1AA',
      },
    },
  });
}

=head1 SYNOPSIS

  Usage: APPLICATION dev_data [OPTIONS]

  Options:

    -f, --force   Actually insert the data

=cut

1;
