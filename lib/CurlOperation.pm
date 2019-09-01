package CurlOperation;

use JSON;
use POSIX;
use Config::Simple;

use curl_interface;

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

    #Curl interface
    $self->{curl} = curl_interface->new();
    $self->{conf} = new Config::Simple('api.ini')->vars();

    return $self;
}

sub map_pcat_url {
    my ($self, $source, $resp) = @_;
    my $response = JSON->new->utf8->decode($resp);
    my %source_map = map { $i++ % 2 ? $_ : lc } split(/\|\|/, $self->{conf}->{'SITEMAP.SOURCE_MAP'});
    my $source_map = $source_map{$source} ? $source_map{$source} : $source;

    my @list;

    push @list, $self->map_page_size($source, ceil($response->{totalNumberOfRecords} / $self->{conf}->{'SITEMAP.PAGE_SIZE'}));

    for (my $i = 0; $i < scalar @{$response->{products}}; $i++) {
        my $slug = $response->{products}->[$i]->{slug};
        
        if ($source eq 'device') {
            push @list, '/shop/' . $source_map . '/' . $slug . '/specs';
        }

        my $colors = $response->{products}->[$i]->{colors};
        for (my $j = 0; $j < scalar @{$colors}; $j++) {
            push @list, '/shop/' . $source_map . '/' . $slug . '?colorName=' . $colors->[$j]->{name};
        }
    }

    return @list;
}

sub map_page_size {
    my ($self, $source, $total_page) = @_;
    my @list;

    $source =  'accessories' if ($source eq 'accessory');
    
    for (my $i = 1; $i <= $total_page; $i++) {
        push @list, '/shop?category=' . $source . '&page=' . $i; 
    }
    return @list;
}

sub catalog_list {
    my ($self, $resp) = @_;
    my $response = JSON->new->utf8->decode($resp);
    my @list;

    for (my $i = 0; $i < scalar @{$response}; $i++) {
        push @list, $response->[$i]->{slug};
    }

    return @list;
}

sub map_catalog {
    my ($self, @catalog_list) = @_;
    my @list;

    for my $catalog (@catalog_list) {
        push @list, '/support/category/' . $catalog;
    }

    return @list;
}

sub map_article {
    my ($self, $resp) = @_;
    my $response = JSON->new->utf8->decode($resp);
    my @list;

    if ($response) {
        for (my $i = 0; $i < scalar @{$response->{subCategories}}; $i++) {
            my $articles = $response->{subCategories}->[$i]->{articles};

            for (my $j = 0; $j < scalar @{$articles}; $j++) {
                push @list, '/support/article/' . $articles->[$j]->{urlAlias};
            }
        }
    }

    return @list;
}

1;
