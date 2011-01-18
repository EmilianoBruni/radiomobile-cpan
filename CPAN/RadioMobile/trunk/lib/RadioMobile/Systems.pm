package RadioMobile::Systems;

use 5.010000;
use strict;
use warnings;

use base qw/Array::AsObject/;

use File::Binary;

use RadioMobile::System;

sub parse {
	my $s	 	= shift;
	my $f	  	= shift;
	my $len		= shift;

	foreach (1..$len) {
		my $system = new RadioMobile::System;
		$system->parse($f);
		$s->push($system);
	}
}

sub dump {
	my $s	= shift;
	my $ret	= "SYSTEMS => [\n";
	foreach ($s->list) {
		$ret .= "\t" . $_->dump;
	}
	$ret .= "]\n";
	return $ret;
}

1;

__END__
