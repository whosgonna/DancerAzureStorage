package Dancer2Uploader;
use Dancer2;
use v5.26;
use Azure::Blob::SAS;
use Data::Printer;

our $VERSION = '0.1';

my $storage_service   = config->{azure}->{service}   // $ENV{STORAGE_SERVICE};
my $storage_container = config->{azure}->{container} // $ENV{STORAGE_CONTAINER};

get '/' => sub {
    template 'index' => { 'title' => 'Dancer2Uploader' };
};

get '/upload' => sub {

    info "storage_service   = '$storage_service'";
    info "storage_container = '$storage_container'";

    template 'upload' => { 
        title     => 'Dancer2Uploader',
        service   => $storage_service,
        container => $storage_container,
    };
};

any ['get', 'post'] => '/signature' => sub {
    my $params = query_parameters;
    
    my $sas_key = config->{azure}->{password} // $ENV{SAS_PASSWORD}

    info "===BLOBURI=== " . query_parameters->get('bloburi');

    my $sas = Azure::Blob::SAS->new(
        sas_key           => $sas_key,
        url               => query_parameters->get('bloburi'),
        signedpermissions => 'w',
        signedResource    => 'b',
    );

    my $signed_url = $sas->signed_url;
    p $signed_url;
    return( $signed_url );
};


any ['get', 'post'] => '/success' => sub {
    my $params = body_parameters;
    p $params;
    return();
};

true;
