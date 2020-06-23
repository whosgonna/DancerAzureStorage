use strict;
use warnings;
package Azure::Blob::SAS;

## REFERENCE THIS PAGE:
## https://docs.microsoft.com/en-us/rest/api/storageservices/create-service-sas

use Moo;
use Types::Standard qw(Str InstanceOf Enum Int); 
use URL::Encode qw(url_encode url_decode);
use Digest::SHA qw(hmac_sha256_base64);
use MIME::Base64;
use URI;
use DateTime;
use DateTime::Format::ISO8601;
use File::Spec::Functions qw(catpath);

has storageaccount => (
    is       => 'lazy',
    isa      => Str,
    required => 'yes',
);
sub _build_storageaccount {
    my $self  = shift;
    my @hosts = split( /\./, $self->_host );
    return $hosts[0];
}

has sas_key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'url' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has '_uri' => (
    is       => 'lazy',
    isa      => InstanceOf['URI'],
    required => 1
);

sub _build__uri {
    my $self = shift;
    my $uri = URI->new( $self->url );
};

## Will be difficult to enumerate, because the order of the permissions
## makes a difference.  Will look for a regexp test.
has signedpermissions => (
    is       => 'ro',
    required => 1,
    default  => 'r',
);

## Should maybe be datetime?  Needs to be like DateTime's iso8601(), but with 
## a "Z" at the end of it.
has signedstart => (
    is       => 'ro',
    required => 1,
    default  => sub { 
        my $dt      = DateTime->now();
        return $dt->iso8601() . 'Z';
        #my $stamp   = $iso8601 . "Z";
        #return $stamp; 
    },
);

has duration => (
    is       => 'ro',
    isa      => Int,
    default  => 900, # seconds.
);

## Can be based off of start. We will need this value, but it might be more
## useful to assume start is now, and then take a duration as an argument.
has signedexpiry => (
    is       => 'lazy',
    required => '1'
);
sub _build_signedexpiry {
    my $self     = shift;
    my $duration = $self->duration;
    my $start_dt = DateTime::Format::ISO8601
        ->parse_datetime( $self->signedstart );
    my $end_dt   = $start_dt->clone->add( seconds => $duration );
    return $end_dt->iso8601 . 'Z';
}





## Should (almost always) be https.  I think there's a way to specify EITHER,
## but was unable to find the documentation.
has signedProtocol => (
    is       => 'lazy',
    isa      => Enum[qw(http https)],
    required => 1,
);

sub _build_signedProtocol {
    my $self  = shift;
    my $uri   = $self->_uri;
    my $proto = $uri->scheme;
    return $proto;
}


has signedversion => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    default  => '2019-10-10'
);

##  Should enumerate the possible values.
has signedResource => (
    is       => 'ro',
    required => 1,
    isa      => Enum[qw( b bv bs c sr '')],
    default  => 'b'
);

## TODO: Enumerate types (find out what types are possible?)
has service_type => (
    is       => 'lazy',
    required => 1,
);
sub _build_service_type {
    my $self  = shift;
    my @hosts = split( /\./, $self->_host );
    return $hosts[1];
}

has _host => (
    is  => 'lazy',
    isa => Str
);
sub _build__host {
    my $self = shift;
    my $uri  = $self->_uri;
    return $uri->host;
};


my @optional_args = qw(
    signedidentifier
    signedIP
    signedSnapshotTime
    rscc
    rscd
    rsce
    rscl
    rsct
);
has [ @optional_args ]=> (
    is       => 'ro',
    required => 1,
    default  => ''
);


sub canonicalizedresource {
    my $self           = shift;
    my $storageaccount = $self->storageaccount;
    my $service_type   = $self->service_type;
    my $uri            = $self->_uri;
    my $path           = $uri->path;
    
    my $canonicalizedresource = "/$service_type/$storageaccount$path";

    return $canonicalizedresource;
}


sub string_to_sign {
    my $self = shift;
    my @string_to_sign_arr = (
        $self->signedpermissions,
        $self->signedstart,
        $self->signedexpiry,
        $self->canonicalizedresource,
        $self->signedidentifier,
        $self->signedIP,
        $self->signedProtocol,
        $self->signedversion,
        $self->signedResource,
        $self->signedSnapshotTime,
        $self->rscc,
        $self->rscd,
        $self->rsce,
        $self->rscl,
        $self->rsct
    );

    my $string_to_sign = join( "\n", @string_to_sign_arr);
    return $string_to_sign;
}

sub generate_signature {
    my $self = shift;

    my $string_to_sign_unenc = $self->string_to_sign;
    my $string_to_sign_enc   = url_encode $string_to_sign_unenc;
    my $signing_key          = decode_base64( $self->sas_key );

    my $hmac = hmac_sha256_base64( $string_to_sign_unenc, $signing_key );

    my $token = $hmac;
    while ( length( $token) % 4 ) {
        $token .= '=';
    }

    my $token_url = url_encode( $token );
    return $token_url;
}

sub token {
    my $self = shift;
    my $uri  = $self->_uri;
    

    my $query_form = {
        sp  => $self->signedpermissions,
        st  => $self->signedstart,
        se  => $self->signedexpiry,
        spr => $self->signedProtocol,
        sv  => $self->signedversion,
        sr  => $self->signedResource,
        sig => url_decode $self->generate_signature,
    };
    $uri->query_form( $query_form );
    return $uri->query;
}


sub manual_token {
    my $self = shift;

    my $manual_token = 'sp='   . $self->signedpermissions;
    $manual_token   .= '&st='  . $self->signedstart;
    $manual_token   .= '&se='  . $self->signedexpiry;
    $manual_token   .= '&spr=' . $self->signedProtocol;
    $manual_token   .= '&sv='  . $self->signedversion;
    $manual_token   .= '&sr='  . $self->signedResource;
    $manual_token   .= '&sig=' . $self->generate_signature;

    return $manual_token;

}

sub signed_url {
    my $self     = shift;
    my $token    = $self->token;
    return $self->_uri->as_string;

}








1;
