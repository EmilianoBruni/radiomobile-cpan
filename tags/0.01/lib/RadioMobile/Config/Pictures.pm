package RadioMobile::Config::Pictures;

use strict;
use warnings;

use Class::Container;
use base qw(Class::Container Array::AsObject);

sub parse {
	my $s	 	= shift;
	$s->clear;
	my $f	  	= $s->container->container->bfile;
    # il numero di picture
    my $l = unpack("s",$f->get_bytes(2));
    while ($l > 0) {
        $s->push(unpack("a$l",$f->get_bytes($l)));
        # process pic_file: TO DO!!!???
        $l = unpack("s",$f->get_bytes(2));
    }
}

sub dump {
	my $s	= shift;
	my $ret	= "[\n";
	foreach ($s->list) {
		$ret .= "\t" . $_;
	}
	$ret .= "]\n";
	return $ret;
}

1;

__END__
