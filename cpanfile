requires "Dancer2" => "0.300004";
requires 'Moo';
requires 'Types::Standard';
requires 'URL::Encode';
requires 'Digest::SHA';
requires 'MIME::Base64';
requires 'DateTime';
requires 'DateTime::Format::ISO8601';
requires 'URI';

requires 'Data::Printer';

recommends "YAML"             => "0";
recommends "URL::Encode::XS"  => "0";
recommends "CGI::Deurl::XS"   => "0";
recommends "HTTP::Parser::XS" => "0";

on "test" => sub {
    requires "Test::More"            => "0";
    requires "HTTP::Request::Common" => "0";
};
