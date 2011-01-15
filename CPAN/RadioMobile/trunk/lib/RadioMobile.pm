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

my $f = new File::Binary($s->file);

# read and unpack the header
my $header = RadioMobile::Header->parse($f);
print Data::Dumper::Dumper($header);
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

my @netRole;
$b = $f->get_bytes($NetSystemLen->($header));
my $skip   = 'x[' . ($header->networkCount-1) .  ']';
foreach (0..$header->networkCount-1) {
	my $format = 'x[' . $_ . '](C' .  $skip . ')' . ($header->unitCount-1) .  'C'; 
	push @netRole, [unpack($format,$b)];
}

# I prefer to split network belonger from network role
my @unitNetwork;
foreach my $item (@netRole) {
	push @unitNetwork, [map {$_ > 127 ? 1 : 0} @$item] 
}
#print Data::Dumper::Dumper(\@unitNetwork);

my @unitRole;
foreach my $item (@netRole) {
	push @unitRole, [map {$_ > 127 ? $_-128 : $_ } @$item] 
}
#print Data::Dumper::Dumper(\@unitRole);


# read net system
# NET_SYSTEM shows what's the system of every units in every network
# the system is a short unsigned integer identifing the index of system element
# it's a vector of short with size $header->networkCount * $header->unitCount * 2
# Given A,B,C... units and 1,2,3 Network so A1 is a short 
# indicate the system index of unit A in network 1 
# It's structure is 
# A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ...
# The following code traslate this in a AoA with this structure
# [ 
#   [A1 B1 C1 ... ] 
#   [A2 B2 C2 ....] 
#   [A3 B3 C3 ... ]
# ]
# like _NetData.csv
my @netSystem;
my $skip2   = 'x[' . ($header->networkCount-1)*2 .  ']';
$b = $f->get_bytes($NetSystemLen->($header) * 2);
foreach (0..$header->networkCount-1) {
	my $format = 'x[' . $_ * 2  . '](S' .  $skip2 . ')' . ($header->unitCount-1) .  's'; 
	push @netSystem, [unpack($format,$b)];
}

#print Data::Dumper::Dumper(\@netSystem);

# read and unpack nets
my @nets;
foreach (1..$header->networkCount) {
	my $net = RadioMobile::Net->parse($f);
	push @nets,$net;
}
#print Data::Dumper::Dumper(\@nets);

# read and unpack coverage
my $cov = RadioMobile::Cov->parse($f);
#print Data::Dumper::Dumper($cov);

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


# read net_h 
# NET_HEIGHT shows the height of every units in every network. If height is 0
# then default system height has taken
# it's a vector of  float signed integer
# with size $header->networkCount * $header->unitCount * 4
# Given A,B,C... units and 1,2,3 Network so A1 is a float 
# indicate the height of unit A in network 1 
# It's structure is 
# A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ...
# The following code traslate this in a AoA with this structure
# [ 
#   [A1 B1 C1 ... ] 
#   [A2 B2 C2 ....] 
#   [A3 B3 C3 ... ]
# ]
# like _NetData.csv
my @netHeight;
my $skip4   = 'x[' . ($header->networkCount-1)*4 .  ']';
$b = $f->get_bytes( 4 * $NetSystemLen->($header)) unless(eof($f->{_fh}));
foreach (0..$header->networkCount-1) {
	my $format = 'x[' . $_ * 4  . '](f' .  $skip4 . ')' . ($header->unitCount-1) .  's'; 
	push @netHeight, [unpack($format,$b)];
}
#print Data::Dumper::Dumper(\@netHeight);



# UNIT_ICON
# a vector of byte with icon index base-0 of every units
$b = $f->get_bytes( $header->unitCount) unless(eof($f->{_fh})); 
my @unitIcon = unpack('c' x $header->unitCount,$b);
#print Data::Dumper::Dumper(\@unitIcon);


# ADDITIONAL_CABLE_LOSS
# a vector of float with additional cable loss for every system
$b = $f->get_bytes( 4 * $header->systemCount) unless(eof($f->{_fh}));
my @lineLossPerMeter = unpack("f" . $header->systemCount,$b);
#print Data::Dumper::Dumper(\@lineLossPerMeter);

# a block of configuration elements. It seems it's 23 bytes long
# but only first 4 bytes are used for Style Networks properties 
# (use two ray LOS, draw green, yello, red and bg line, etc.)
# This is its structure in bits
# b(1): Enabled (1) or disabled (0) "Draw a red line..."
# b(2..8): an unsigned short to draw yellow line if RX >= b(2..8) - 50
# b(9): Enabled (1) or disabled (0) "Draw a yellow line..."
# b(10..16): an unsigned short to draw yellow line if RX >= b(10..16) - 50
# b(17): Enabled (1) or disabled (0) "Draw a green line..."
# b(18..23): Not used
# b(24): Enabled (1) or disabled (0) "Draw lines with dark background"
# b(25..30: Not used
# b(31): Enabled (0) or disabled (1) "Use Two Rays..."
# b(32): Normal (0) or Interference (1) Two Ray Los
$b = $f->get_bytes(23) unless(eof($f->{_fh}));
my $format = "H2H2H2H2";
my @data =  unpack($format,$b);

my $res = hex($data[0]) & 0x80;
print "Draw red: " . ($res >> 7), "\n";
print "Yellow >=: " . ((hex($data[0]) & 0x7F) - 50),"\n";
$res = hex($data[1]) & 0x80;
print "Draw Yellow: " . ($res >> 7), "\n";
print "Green >=: " . ((hex($data[1]) & 0x7F) - 50),"\n";
print "Draw green: " . ((hex($data[2]) & 0x80) >> 7), "\n";
print "Draw backg: " . (hex($data[2]) & 0x01), "\n";
print "Two ray enabled: " . !((hex($data[3]) & 0x02) >> 1),"\n";
print "Two ray normal: " . !(hex($data[3]) & 0x01),"\n";
print "Two ray interfer: " . (hex($data[3]) & 0x01),"\n";


# a short integer set how much structure follows for
# system antenna type (0 == omni.ant)
$b = $f->get_bytes(2) unless(eof($f->{_fh}));
$format = "s";
@data = unpack($format,$b);
print Data::Dumper::Dumper(\@data);

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
