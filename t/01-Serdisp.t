# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Serdisp.t'

use strict;
use warnings;

use Test::More tests => 4;

use_ok('Serdisp');
use_ok('GD');

my $d = Serdisp->new('USB:7c0/1501', 'ctinclud');
$d->init();
ok($d->width() eq '128');
ok($d->height() eq '64');

$d->clear();

my $image = GD::Image->new(128,64);
my $black = $image->colorAllocate(0,0,0);
my $white = $image->colorAllocate(255,255,255);

$image->transparent($black);
$image->arc(10,10,10,10,0,270, $white);
$d->copyGD($image);

sleep(5);

undef $d;


