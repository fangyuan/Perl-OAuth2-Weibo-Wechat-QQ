package WWW::Tecent::Weixin;

use utf8;
use Moose;
use MooseX::Singleton;
use DateTime;
use Mojo::UserAgent;
use URI;

our $VERSION = '0.01';

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
            redirect_uri => $config->{redirect_uri},
        );
    }
    else {
        return $class->$orig(@_);
    }
};

sub authorize_url {
    my $self           = shift;
    my $params         = shift || {};
    my $params_request = {
        appid         => $self->appkey,
        redirect_uri  => $self->redirect_uri,
        response_type => 'code',
        scope         => $params->{scope} || 'snsapi_login',
        state         => $params->{state} || $self->rand_state,
    };
    my $url = 'https://open.weixin.qq.com/connect/qrconnect';
    my $uri = URI->new($url);
    $uri->query_form($params_request);
    return $uri->as_string . '#wechat_redirect'
}

sub get_access_token {
    my $self           = shift;
    my $authorize_code = shift;
    my $is_wap         = shift;
    return unless $authorize_code;

    my $params = {
        appid      => $self->appkey,
        secret     => $self->appsecret,
        code       => $authorize_code,
        grant_type => 'authorization_code',
    };
    my $now = DateTime->now( time_zone => 'Asia/Shanghai' );
    my $url = 'https://api.weixin.qq.com/sns/oauth2/access_token';
    my $res = $self->ua->post( $url => form => $params )->res->json;
    return unless $res and $res->{access_token};
    $res->{expired_at} = $now->clone->add( seconds => $res->{expires_in} );
    return $res;
}

sub get_user_info {
    my $self   = shift;
    my $params = shift;
    my $url    = sprintf( 'https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s', $params->{access_token}, $params->{openid} );
    my $res    = $self->ua->get($url)->res->json;
    return $res;
}

sub rand_state {
    my $self  = shift;
    my @chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );
    my $len   = scalar @chars;
    return join( '', map { $chars[int( rand($len) )] } 1 .. 6 );
}

1;
