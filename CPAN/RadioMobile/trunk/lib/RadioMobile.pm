package RadioMobile;

use 5.010000;
use strict;
use warnings;

use Class::Struct;
use File::Binary;

use Data::Dumper;

use RadioMobile::Header;
use RadioMobile::Unit;
use RadioMobile::System;
use RadioMobile::Net;
use RadioMobile::Cov;

sub new {
	my $proto = shift;
	my $class = $proto || shift;

	my $self	= bless {},$class;

	return $self;
}

sub file { my $s = shift; if (@_) {$s->{file} = shift}; return $s->{file}; }

sub parse {

	my $s = shift;






# NET ROLE STRUCTURE
my $NetRoleLen		= sub { my $header = shift; 
	return $header->networkCount * $header->unitCount };
# NET SYSTEM STRUCTURE
my $NetSystemLen	= $NetRoleLen;
#my $file 			= 'net1.net';
#my $file 			= 'wdasl.net';

my $f = new File::Binary($s->file);

# read and unpack the header
my $header = RadioMobile::Header->parse($f);
#print Data::Dumper::Dumper($header);
#print $header->version;

# read and unpack units
my @units;
foreach (1..$header->unitCount) {
	my $unit = RadioMobile::Unit->parse($f);
	push @units,$unit;
}
#print Data::Dumper::Dumper(\@units);


# read and unpack systems
my @systems;
foreach (1..$header->systemCount) {
	my $system = RadioMobile::System->parse($f);
	push @systems,$system;
}
#print Data::Dumper::Dumper(\@systems);

# read net_role
# NET_ROLE shows in which network is associated an unit
# and its role (master/slave/node/terminal) 
# it's a vector of byte with size $header->networkCount * $header->unitCount
# Given A,B,C... units and 1,2,3 Network so A1 is a byte
# indicate if unit A is in network 1 and its role
# It's structure is 
# A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ...
# The following code traslate this in a AoA with this structure
# [ 
#   [A1 B1 C1 ... ] 
#   [A2 B2 C2 ....] 
#   [A3 B3 C3 ... ]
# ]
# like _NetData.csv
# Every byte it's so used A1 = aaaabbbb where aaaa is the first four bits
# and bbbb the others. aaaa is 1000 if the unit A
# belongs to network 1, 0000 else. 
# bbbb is an integer 0..127 setting its role index
# Example: (\x00 first role, no belong, \x01 second role, no belong, 
# \x80 (128) first role, belong to network, \x81 (129) first role, belong 

my @data;
$b = $f->get_bytes($NetSystemLen->($header));
my $skip   = 'x[' . ($header->networkCount-1) .  ']';
foreach (0..$header->networkCount-1) {
	#my $lastskip   = $_ == $header->networkCount-1 ? '' : $skip;
	my $format = 'x[' . $_ . '](C' .  $skip . ')' . ($header->unitCount-1) .  'C'; 
	#print $format,"\n";
	push @data, [unpack($format,$b)];
}

# I prefer to split network belonger from network role
my @unitNetwork;
foreach my $item (@data) {
	push @unitNetwork, [map {$_ > 127 ? 1 : 0} @$item] 
}
#print Data::Dumper::Dumper(\@unitNetwork);

my @unitRole;
foreach my $item (@data) {
	push @unitRole, [map {$_ > 127 ? $_-128 : $_ } @$item] 
}
#print Data::Dumper::Dumper(\@unitRole);


# read net system
#$b = $f->get_bytes($NetSystemLen->($header));
foreach (1..$header->networkCount) {
	$b = $f->get_bytes($header->unitCount);
#	print unpack('W' . $header->unitCount,$b),"\n";
}

# read unknown elements [NOT PRESENT IN VERSION 3000]
#$b = $f->get_bytes($NetSystemLen->($header));
foreach (1..$header->networkCount) {
	$b = $f->get_bytes($header->unitCount);
#	print unpack('W' . $header->unitCount,$b),"\n";
}

# read and unpack nets
my @nets;
foreach (1..$header->networkCount) {
	my $net = RadioMobile::Net->parse($f);
	push @nets,$net;
}
#print Data::Dumper::Dumper(\@nets);

# read and unpack coverage
my $cov = RadioMobile::Cov->parse($f);
print Data::Dumper::Dumper($cov);

# lettura del percorso al file map
my $l = unpack("s",$f->get_bytes(2));
my $map_file = '';
if ($l > 0) {
	$map_file = unpack("A$l",$f->get_bytes($l));
}

# lettura dei percorsi delle picture da caricare
unless(eof($f->{_fh})) {
	# forse carica le pictures
	$l = unpack("s",$f->get_bytes(2));
	while ($l > 0) {
		my $pic_file = $f->get_bytes($l);
		# process pic_file: TO DO!!!???
		$l = unpack("s",$f->get_bytes(2));
	}
}

# da qui, mistero.

# carico net_h che una matrice bidimensionale di single con la stessa dimensione di
# NetSystemLen
my $net_h = $f->get_bytes( 4 * $NetSystemLen->($header)) unless(eof($f->{_fh}));
# Carico UnitIcon di dimensione pari alle unit di tipo byte
my $unitIcon = $f->get_bytes( $header->unitCount) unless(eof($f->{_fh})); 
# Carico lineLossPerMeter che sono dei single di systemCount
my $lineLossPerMeter = $f->get_bytes( 4 * $header->systemCount) unless(eof($f->{_fh}));


$f->close;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

RadioMobile - Perl extension for blah blah blah

=head1 SYNOPSIS

  use RadioMobile;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for RadioMobile, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

root, E<lt>root@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
