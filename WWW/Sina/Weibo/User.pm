package WWW::Sina::Weibo::User;
use utf8;
use Moose::Role;

sub user_show {
    my $self   = shift;
    my $args   = shift;
    my $params = {
        access_token => $args->{access_token} || $args->{token},
        source => $self->appkey,
    };
    map { $params->{$_} = $args->{$_} } grep { defined $args->{$_} } qw/uid screen_name/;
    return unless $params->{access_token};
    return unless $params->{uid} || $params->{screen_name};

    my $url = 'https://api.weibo.com/2/users/show.json';
    my $res = $self->ua->get( $url => form => $params )->res->json;
    return $res;
}

1;
