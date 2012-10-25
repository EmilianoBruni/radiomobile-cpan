package RadioMobile::Systems;

use strict;
use warnings;

use Class::Container;
use base qw(Class::Container Array::AsObject);

use File::Binary;

use RadioMobile::System;

our $VERSION    = '0.10';

sub parse {
	my $s	 	= shift;
	my $f	  	= $s->container->bfile;
	my $len		= $s->container->header->systemCount;
	foreach (0..$len-1) {
		my $system = new RadioMobile::System;
		$system->parse($f);
		$system->idx($_);
		$s->push($system);
	}
}

sub write {
	my $s	 	= shift;
	my $f	  	= $s->container->bfile;
	my $len		= $s->container->header->systemCount;
	foreach (0..$len-1) {
		my $system = $s->at($_);
		$system->write($f);
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
