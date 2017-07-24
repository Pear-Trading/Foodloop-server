package Pear::LocalLoop::Controller::Api::Feedback;
use Mojo::Base 'Mojolicious::Controller';

has error_messages => sub {
  return {
    email => {
      required => { message => 'Email is required', status => 400 },
      in_resultset => { message => 'Change meeee', status => 400 },
    },
    app_name => {
      required => { message => 'App Name is required', status => 400 },
    },
    package_name => {
      required => { message => 'Package Name is required', status => 400 },
    },
    version_code => {
      required => { message => 'Version Code is required', status => 400 },
    },
    version_number => {
      required => { message => 'Version Number is required', status => 400 },
    },
  };
};

sub post_feedback {
  my $c = shift;

  my $validation = $c->validation;
  $validation->input( $c->stash->{api_json} );

  my $user_rs = $c->schema->resultset('User');

  $validation->required('email')->in_reusltset( 'email', $user_rs );
  $validation->required('app_name');
  $validation->required('package_name');
  $validation->required('version_code');
  $validation->required('version_number');

  return $c->api_validation_error if $validation->has_error;

  return $c->render( json => {
    success => Mojo::JSON->true,
    message => 'Thank you for your Feedback!',
  });
}

1;
