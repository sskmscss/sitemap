use lib 'C:/strawberry/perl/lib';
use lib 'lib';

use File::Find::Object::Rule;
use XML::Writer;
use XML::LibXML;
use URI::Encode qw( uri_encode );

use CurlOperation;
use Config;

my (@targets, @files, @url_list, $ignore_regex, $curl, $response);

$curl = CurlOperation->new();
@targets = ($curl->{conf}->{'SITEMAP.SOURCE_PATH'});

@files = File::Find::Object::Rule->file()
                              ->name( 'routes.ts' )
                              ->in( @targets );

$ignore_regex = join "|", @{$curl->{conf}->{'SITEMAP.IGNORE_LIST'}};

push @url_list, $curl->{conf}->{'SITEMAP.STANDALONE_LINKS'};

foreach my $file (@files) {
    open($IN,  "< $file") or die "cant open $dir/$file for reading"; {
        local $/ = undef;
        my $value = <$IN>;
        $value =~ m#ROUTES\:\s+Ng2StateDeclaration\[\]\s*=\s*\[(.*)\]#gs;
        my $route = $1;

        if ($file =~ m#xm\\*\/*routes\.ts#) {
            while ($route =~ m#name\:\s+\'([^\']+)\'#gs) {
                my $name = $1;

                if ($name !~ m/$ignore_regex/) {
                    if ($name =~ m#\.\*\*#) {
                        if ($route =~ m#url\:\s+\'([^\']+)\'#gs) {
                            push @url_list, "${1}" if $1;
                        }
                    } elsif ($name !~ m#\.#) {
                        if ($route =~ m#url\:\s+\'([^\']+)\'#gs) {
                            push @url_list, "${1}" if $1;
                            $parent_name = $name;
                            $parent_url = $1;
                        }
                    } elsif ($name =~ m#${parent_name}\.#) {
                        if ($route =~ m#url\:\s+\'([^\']*)\'#gs) {
                            push @url_list, "${parent_url}${1}" if $1;
                        }
                    }
                }
            }
        }

        if ($route =~ m#parent\:.*?name\:[^\,]+\,\s+url\:\s+\'([^\']+)\'(.*)#gs) {
            $url = $1;
            $urls = $2;
            push @url_list, "$url" if $url && $url !~ m/$ignore_regex/;;
            while ($urls =~ m#url\:\s+\'([^\']+)\'#gs) {
                push @url_list, "${url}${1}" if $1 && $url !~ m/$ignore_regex/;
            }
        } elsif ($route !~ m/$ignore_regex/) {
            while ($urls =~ m#url\:\s+\'([^\']+)\'#gs) {
                push @url_list, "${url}${1}" if $1 && $url !~ m/$ignore_regex/;;
            }
        }
    }
    close($IN);
}

foreach my $source (@{$curl->{conf}->{'SITEMAP.COLLECT_PCAT_DETAILS'}}) {
    my $source_info = $source eq 'accessory' ? 'accessories' : $source;
    push @url_list, $curl->map_pcat_url($source, $curl->{curl}->get_pcat_details($curl->{conf}->{'SITEMAP.API_CATALOG'}, $source_info));
}

my @catalog_list = $curl->catalog_list($curl->{curl}->get_categories_and_details($curl->{conf}->{'SITEMAP.API_CATEGORIES'}));

push @url_list, $curl->map_catalog(@catalog_list);

foreach my $catalog_slug (@catalog_list) {
    push @url_list, $curl->map_article($curl->{curl}->get_categories_and_details($curl->{conf}->{'SITEMAP.API_CATEGORIES'}, $catalog_slug));
}

%url_list = map { uri_encode($_) => 1 } grep { $_ !~ /\/\:/ } @url_list;

my $writer = XML::Writer->new(OUTPUT => 'self', DATA_MODE => 1, DATA_INDENT => 2);
$writer->xmlDecl('UTF-8');
$writer->startTag(
    'urlset',
    'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
    'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
    'xmlns:image' => 'http://www.google.com/schemas/sitemap-image/1.1'
);

foreach my $key (sort keys %url_list) {
    $writer->startTag('url');
    $writer->startTag('loc');
    $writer->characters($curl->{conf}->{'SITE_URL'} . $key);
    $writer->endTag('loc');
    $writer->startTag('changefreq');
    $writer->characters('weekly');
    $writer->endTag('changefreq');
    $writer->endTag('url'); 
}
$writer->endTag('urlset');
 
my $xml = $writer->end();
$doc = XML::LibXML->load_xml(string => $xml);

# save
open my $out, '>', 'sitemap.xml';
binmode $out; # as above
$doc->toFH($out);
