#! perl -w
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Dancer2;

use Example;

dance();
#Example->to_app();
