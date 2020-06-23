#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use Dancer2Uploader;

Dancer2Uploader->to_app;

=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use Dancer2Uploader;
use Plack::Builder;

builder {
    enable 'Deflater';
    Dancer2Uploader->to_app;
}

=end comment

=cut

=begin comment
# use this block if you want to mount several applications on different path

use Dancer2Uploader;
use Dancer2Uploader_admin;

use Plack::Builder;

builder {
    mount '/'      => Dancer2Uploader->to_app;
    mount '/admin'      => Dancer2Uploader_admin->to_app;
}

=end comment

=cut

