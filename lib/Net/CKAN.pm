package Net::CKAN;
use Moose;
use LWP::UserAgent;
use URI::Escape;
use JSON qw/decode_json encode_json/;
use Carp qw/croak/;
use namespace::clean -except => 'meta';

has 'server'     => (is => 'ro', isa => 'Str',            required   => 1);
has 'api_key'    => (is => 'ro', isa => 'Str',            required   => 1);
has 'api_base'   => (is => 'ro', isa => 'Str',            lazy_build => 1);
has 'user_agent' => (is => 'ro', isa => 'LWP::UserAgent', lazy_build => 1);

sub get_packages {
    my $self = shift;
    return $self->_get_json('/package');
}

sub get_package {
    my $self = shift;
    my $name = shift;
    return $self->_get_json("/package/$name");
}

sub update_package {
    my $self = shift;
    my $name = shift;
    my $package = shift;

    return $self->_post_content("/package/$name", $package);
}

sub create_package {
    my $self = shift;
    my $package = shift;

    return $self->_post_content('/package', $package);
}

sub _post_content {
    my $self = shift;
    my $url  = shift;
    my $data = shift;
    my $ua   = $self->user_agent;
    $url = $self->api_base . $url;

    my $json = JSON->new->utf8(1)->pretty(1)->encode($data);
    my $resp = $ua->post($url, Content => {$json => 1});
    croak "Could not fetch $url: ", $resp->status_line, $resp->content, "\n"
        if $resp->code != 200;
}

sub _get_json {
    my $self         = shift;
    my $relative_url = shift;

    my $url  = $self->api_base . $relative_url;
    my $ua   = $self->user_agent;
    my $resp = $ua->get($url);
    croak "Could not fetch $url: ", $resp->status_line, "\n" if $resp->code != 200;
    return decode_json($resp->content);
}

sub _build_api_base { shift->server . '/api/rest' }

sub _build_user_agent {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->default_header(Authorization => $self->api_key);
    return $ua;
}




__PACKAGE__->meta->make_immutable;
1;
