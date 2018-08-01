package WWW::Sina::Weibo::OAuth;

use utf8;
use Moose::Role;
use DateTime;

sub authorize_url {
    my $self   = shift;
    my $params = {
        client_id     => $self->appkey,
        response_type => 'code',
        redirect_uri  => $self->redirect_uri,
    };
    my $url = sprintf( 'https://api.weibo.com/oauth2/authorize?%s', join( '&', map { sprintf( '%s=%s', $_, $params->{$_} ) } keys %$params ) );
    return $url;
}

sub get_access_token {
    my $self           = shift;
    my $authorize_code = shift;
    return unless $authorize_code;

    my $params = {
        client_id     => $self->appkey,
        client_secret => $self->appsecret,
        grant_type    => 'authorization_code',
        code          => $authorize_code,
        redirect_uri  => $self->redirect_uri,
    };
    my $now = DateTime->now( time_zone => 'Asia/Shanghai' );
    my $res = $self->ua->post( 'https://api.weibo.com/oauth2/access_token' => form => $params )->res->json;
    return unless $res and $res->{expires_in};

    $res->{expired_at} = $now->clone->add( seconds => $res->{expires_in} );
    $res->{refresh_at} = $now->clone->add( seconds => $res->{remind_in} );
    return $res;
}

1;
