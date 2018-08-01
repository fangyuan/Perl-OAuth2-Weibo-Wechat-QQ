package WWW::Tecent::QQ;

use utf8;
use Moose;
use MooseX::Singleton;
use DateTime;
use Mojo::UserAgent;
use JSON::XS;

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
        response_type => 'code',
        client_id     => $self->appkey,
        redirect_uri  => $self->redirect_uri,
        state         => $params->{state} || $self->rand_state,
    };
    map { $params->{$_} = $params->{$_}; } grep { defined $params->{$_} } qw/scope display g_ut/;
    my $authorize_url = 'https://graph.qq.com/oauth2.0/authorize';
    $authorize_url = 'https://graph.z.qq.com/moc2/authorize' if $params->{display} and $params->{display} eq 'mobile';

    my $url = sprintf( '%s?%s', $authorize_url, join( '&', map { sprintf( '%s=%s', $_, $params_request->{$_} ) } keys %$params_request ) );
    return $url;
}

sub get_access_token {
    my $self           = shift;
    my $authorize_code = shift;
    my $is_wap         = shift;
    return unless $authorize_code;

    my $params = {
        grant_type    => 'authorization_code',
        client_id     => $self->appkey,
        client_secret => $self->appsecret,
        code          => $authorize_code,
        redirect_uri  => $self->redirect_uri,
    };
    my $now = DateTime->now( time_zone => 'Asia/Shanghai' );
    my $url = $is_wap ? 'https://graph.z.qq.com/moc2/token' : 'https://graph.qq.com/oauth2.0/token';
    my $content = $self->ua->post( $url => form => $params )->res->body;
    my $res = $self->__response_content_to_hash($content);
    return unless $res and $res->{access_token};
    $res->{expired_at} = $now->clone->add( seconds => $res->{expires_in} );
    return $res;
}

sub get_user_openid {
    my $self         = shift;
    my $access_token = shift;
    my $is_wap       = shift;

    return unless $access_token;

    my $params = { access_token => $access_token };
    my $url = $is_wap ? 'https://graph.z.qq.com/moc2/me' : 'https://graph.qq.com/oauth2.0/me';
    my $content = $self->ua->get( $url => form => $params )->res->body;
    my $res = $self->__response_content_to_hash($content);
    return $res->{openid} if $res;
}

sub get_user_info {
    my $self = shift;
    my $args = shift || {};
    return unless $args->{access_token} and $args->{openid};
    my $params = {
        access_token       => $args->{access_token},
        oauth_consumer_key => $self->appkey,
        openid             => $args->{openid},
        format             => 'json',
    };
    my $url = 'https://graph.qq.com/user/get_user_info';
    my $content = $self->ua->get( $url => form => $params )->res->body;
    my $res = $self->__response_content_to_hash($content);
    return $res if $res and $res->{ret} eq '0';
}

sub __response_content_to_hash {
    my $self    = shift;
    my $content = shift;
    if ( $content =~ /^callback/ ) {    #jsonp format
        $content =~ s/^callback\(//;
        $content =~ s/\);$//;
        return JSON::XS::decode_json($content);
    }
    if ($content =~ /^\{/) { # json format
        return JSON::XS::decode_json($content);
    }

    #uri params format
    my %data = ( map { split /=/ } split /&/, $content );
    return \%data;
}

sub rand_state {
    my $self  = shift;
    my @chars = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );
    my $len   = scalar @chars;
    return join( '', map { $chars[int( rand($len) )] } 1 .. 6 );
}

1;
