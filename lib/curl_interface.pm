package curl_interface;
use strict;
use warnings;
use LWP::UserAgent;

## @method public new (%args)
# @brief Constructor for CNMDB/IP Control interface API
# @param args - optional hash (optional object parameters)
# @retval self - reference (created object, undef on failure)
sub new
{
    my $class = shift;
    my %args = @_;
    my $self = {};
    bless($self, $class);

    #user agent
    $self->{ua} = LWP::UserAgent->new();

    return $self;
}

## @method private _set_get_request
# @brief Create GET request object in preparation for cURL call.
sub _set_get_request
{
    my $self = shift;

    $self->{request} = HTTP::Request->new(GET => $self->{ws}{web_service});
    #$self->{request}->header(Authorization => 'Basic ' . encode_base64($self->{credential}));
}

## @method private _set_post_request
# @brief Create POST request object in preparation for cURL call.
sub _set_post_request
{
    my $self = shift;

    $self->{request} = HTTP::Request->new(POST => 'http://' . $self->{domain} . '/netadmin/module/' . $self->{ws}{web_service});
    #$self->{request}->header('content-type' => 'application/json');
    #$self->{request}->header(Authorization => 'Basic ' . encode_base64("rnandh002c:asas"));
}

## @method public get_ws_response ($address, $map_str, @$show_list)
# @brief Retrieve json-formatted information from a designated web service directly.
# @param address - required string (IP address)
# @retval status - integer (1 on success; 0 otherwise)
sub get_ws_response
{
    my $self = shift;
    my $address = shift;
    $self->{no_json_response} = 1;

    # Request
    my $query = $address;
    $self->{request}->content($query);
    $self->{request}->content_type('application/x-www-form-urlencoded');
    # Response
    $self->{response} = $self->{ua}->request($self->{request});
    eval {$self->{response_content} = $self->{response}->content;};
    if ($@)
    {
        return 0;
    }
    else
    {
        $self->{no_json_response} = 0;
    }
    return $self->{response}->is_success;
}

sub get_pcat_details
{
    my ($self, $url, $source) = @_;

    $self->{ws}{web_service} = $url . $source;
    $self->_set_get_request;
    $self->get_ws_response('', '');
    return $self->{response_content};
}

# sub popular_search_queries
# {
#     my $self   = shift;

#     $self->{ws}{web_service} = "https://api.mobile.xfinity.com/support/popular_search_queries";
#     $self->_set_get_request;
#     $self->get_ws_response('', '');
#     return $self->{response_content};
# }

sub get_categories_and_details
{
    my ($self, $url, $source) = @_;

    if ($source) {
        $source = $source . '/details';
    } else {
        $source = '';
    }

    $self->{ws}{web_service} = $url . $source;
    $self->_set_get_request;
    $self->get_ws_response('', '');
    return $self->{response_content};
}

1;
