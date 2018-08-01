package WWW::Sina::Weibo;

use utf8;
use Moose;
use MooseX::Singleton;
use DateTime;
use Mojo::UserAgent;
use Data::Dumper;

our $VERSION = '0.01';
with 'WWW::Sina::Weibo::OAuth', 'WWW::Sina::Weibo::User';

has appkey       => ( is => 'ro', isa => 'Str',             required => 1 );
has appsecret    => ( is => 'ro', isa => 'Str',             required => 1 );
has redirect_uri => ( is => 'ro', isa => 'Str',             default  => '' );
has ua           => ( is => 'ro', isa => 'Mojo::UserAgent', lazy     => 1, default => sub { Mojo::UserAgent->new } );

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    if ( @_ == 0 ) {
        my $config = {};
        return $class->$orig(
            appkey       => $config->{appkey},
            appsecret    => $config->{appsecret},
            redirect_uri => $config->{auth_redirect_uri},
        );
    }
    else {
        return $class->$orig(@_);
    }
};

1;
