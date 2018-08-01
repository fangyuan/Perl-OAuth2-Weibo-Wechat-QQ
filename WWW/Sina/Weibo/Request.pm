package WWW::Sina::Weibo::Request;

use Moose::Role;
use JSON::XS qw/decode_json/;
use Data::Dumper;

sub url {
    my $self     = shift;
    my $base_url = shift;
    my $params   = shift;
    return $base_url . '?' . join( '&', map { $_ . '=' . $params->{$_}; } keys %$params );
}

sub get {
    my $self     = shift;
    my $url      = shift;
    my $response = $self->ua->get($url);
    if ( $response->is_success ) {
        my $data;
        eval { $data = decode_json( $response->content ); };
        return $data;
    }
    print Dumper($response);
    return;
}

1;
