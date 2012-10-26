package RadioMobile::Units;

use strict;
use warnings;

use Class::Container;
use base qw(Class::Container Array::AsObject);

use File::Binary;

use RadioMobile::Unit;

our $VERSION    = '0.10';

sub parse {
	my $s	 	= shift;
	my $f	  	= $s->container->bfile;
	my $len		= $s->container->header->unitCount;
	foreach (1..$len) {
		my $unit = new RadioMobile::Unit;
		$unit->parse($f);
		$s->add($unit);
	}
}

sub write {
	my $s	 	= shift;
	my $f	  	= $s->container->bfile;
	my $len		= $s->container->header->unitCount;
	foreach (0..$len-1) {
		my $unit = $s->at($_);
		$unit->write($f);
	}
}

sub dump {
	my $s	= shift;
	my $ret	= "UNITS => [\n";
	foreach ($s->list) {
		$ret .= "\t" . $_->dump;
	}
	$ret .= "]\n";
	return $ret;
}

sub add {
	my $s		= shift;
	my $item	= shift;
	$s->push($item);
	$s->container->header->unitCount($s->length);
	$s->at(-1)->idx($s->length-1);
	return $s->at(-1);
}

sub addNew {
	my $s		= shift;
	my $name	= shift;
	my $item = new RadioMobile::Unit;
	$item->name($name);
	return $s->add($item)
}

1;

__END__
