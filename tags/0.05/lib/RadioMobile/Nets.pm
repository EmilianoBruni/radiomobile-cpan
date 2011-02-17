package RadioMobile::Nets;

use strict;
use warnings;

use Class::Container;
use base qw(Class::Container Array::AsObject);

use File::Binary;

use RadioMobile::Net;

our $VERSION    = '0.01';

sub parse {
	my $s	= shift;
	my $f	= $s->container->bfile;
	my $len	= $s->container->header->networkCount;
	foreach (1..$len) {
		my $net = $s->length >= $_ ? $s->at($_-1) : new RadioMobile::Net;
		$net->parse($f);
		$s->push($net) unless ($s->at($_-1));
	}
}

sub dump {
	my $s	= shift;
	my $ret	= "NETS => [\n";
	foreach ($s->list) {
		$ret .= "\t" . $_->dump;
	}
	$ret .= "]\n";
	return $ret;
}

sub reset {
	my $s	= shift;
	my $len = shift || $s->container->header->networkCount;
	$s->clear();
	foreach (1..$len) {
		my $net = new RadioMobile::Net;
		$net->reset($_);
		$s->push($net);
	}
}


1;

__END__
