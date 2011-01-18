package RadioMobile;

use 5.010000;
use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use File::Binary;

use RadioMobile::Header;
use RadioMobile::Units;
use RadioMobile::Systems;
use RadioMobile::Net;
use RadioMobile::Cov;
use RadioMobile::Config;

__PACKAGE__->valid_params(
							file 	=> { type => SCALAR, optional => 1 },
							debug 	=> { type => SCALAR, optional => 1, default => 0 },
							header	=> { isa  => 'RadioMobile::Header'},
							units	=> { isa  => 'RadioMobile::Units'},
);

__PACKAGE__->contained_objects(
	'header'	=> 'RadioMobile::Header',
	'units'		=> 'RadioMobile::Units',
);

use Class::MethodMaker [ scalar => [qw/file debug header units bfile/] ];

our $VERSION	= 0.1;

sub new {
	my $proto 	= shift;
	my $self	= $proto->SUPER::new(@_);
	return $self;
}


sub parse {
	my $s = shift;
	# NET ROLE STRUCTURE
	my $NetRoleLen		= sub { my $header = shift; 
		return $header->networkCount * $header->unitCount };
	# NET SYSTEM STRUCTURE
	my $UnitSystemLen		= sub { my $header = shift; 
		return $header->systemCount * $header->unitCount };

	$s->{bfile} = new File::Binary($s->file);

	# read header
	$s->header->parse;
	print $s->header->dump if $s->debug;

	# read units
	$s->units->parse;
	print $s->units->dump if $s->debug;

	# read systems
	my $systems	= new RadioMobile::Systems;
	$systems->parse($s->bfile, $s->header->systemCount);
	print $systems->dump if $s->debug;


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
$b = $s->bfile->get_bytes($NetRoleLen->($s->header));
my $skip   = 'x[' . ($s->header->networkCount-1) .  ']';
foreach (0..$s->header->networkCount-1) {
	my $format = 'x[' . $_ . '](C' .  $skip . ')' . ($s->header->unitCount-1) .  'C'; 
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
my $skip2   = 'x[' . ($s->header->networkCount-1)*2 .  ']';
$b = $s->bfile->get_bytes($NetRoleLen->($s->header) * 2);
foreach (0..$s->header->networkCount-1) {
	my $format = 'x[' . $_ * 2  . '](S' .  $skip2 . ')' . ($s->header->unitCount-1) .  's'; 
	push @netSystem, [unpack($format,$b)];
}

#print Data::Dumper::Dumper(\@netSystem);

# read and unpack nets
my @nets;
foreach (1..$s->header->networkCount) {
	my $net = new RadioMobile::Net;
	$net->parse($s->bfile);
	push @nets,$net;
}
#print Data::Dumper::Dumper(\@nets);

# read and unpack coverage
my $cov = new RadioMobile::Cov;
$cov->parse($s->bfile);
#print Data::Dumper::Dumper($cov);

# lettura del percorso al file map
my $l = unpack("s",$s->bfile->get_bytes(2));
my $map_file = '';
if ($l > 0) {
	$map_file = unpack("A$l",$s->bfile->get_bytes($l));
}

# lettura dei percorsi delle picture da caricare
unless(eof($s->bfile->{_fh})) {
	# forse carica le pictures
	$l = unpack("s",$s->bfile->get_bytes(2));
	while ($l > 0) {
		my $pic_file = $s->bfile->get_bytes($l);
		# process pic_file: TO DO!!!???
		$l = unpack("s",$s->bfile->get_bytes(2));
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
my $skip4   = 'x[' . ($s->header->networkCount-1)*4 .  ']';
$b = $s->bfile->get_bytes( 4 * $NetRoleLen->($s->header)) unless(eof($s->bfile->{_fh}));
foreach (0..$s->header->networkCount-1) {
	my $format = 'x[' . $_ * 4  . '](f' .  $skip4 . ')' . ($s->header->unitCount-1) .  's'; 
	push @netHeight, [unpack($format,$b)];
}
#print Data::Dumper::Dumper(\@netHeight);



# UNIT_ICON
# a vector of byte with icon index base-0 of every units
$b = $s->bfile->get_bytes( $s->header->unitCount) unless(eof($s->bfile->{_fh})); 
my @unitIcon = unpack('c' x $s->header->unitCount,$b);
#print Data::Dumper::Dumper(\@unitIcon);


# ADDITIONAL_CABLE_LOSS
# a vector of float with additional cable loss for every system
$b = $s->bfile->get_bytes( 4 * $s->header->systemCount) unless(eof($s->bfile->{_fh}));
my @lineLossPerMeter = unpack("f" . $s->header->systemCount,$b);
#print Data::Dumper::Dumper(\@lineLossPerMeter);

# parse config elements (currently only Style Networks properties)
my $config = new RadioMobile::Config();
$config->parse($s->bfile);
#print Data::Dumper::Dumper($config);


# a short integer set how much structure follows for
# system antenna type (0 == omni.ant)
$b = $s->bfile->get_bytes(2) unless(eof($s->bfile->{_fh}));
my $format = "s";
my $systemAntennaCount = unpack($format,$b);
my @systemsAntenna;
foreach (1..$systemAntennaCount) {
	$b = $s->bfile->get_bytes(2);
	my $antennaLenght = unpack($format,$b);
	unless ($antennaLenght == 0) {
		$b = $s->bfile->get_bytes($antennaLenght);
		push @systemsAntenna,unpack("a" . $antennaLenght,$b)
	} else {
		push @systemsAntenna,'';
	}
}
print Data::Dumper::Dumper(\@systemsAntenna);


# read azimut antenas
# AZIMUT_ANTENNAS shows the azimut of every antenna in every networks
# the azimut is a short unsigned integer identifing it's value power by ten
# If it's value is greater than 10.000, it's not a azimut value but it's the
# direcion by unit which index is the field value - 10000
# Given A,B,C... units and 1,2,3 Network so A1 is a short 
# indicate the azimut value.
# It's structure is 
# A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ...
# The following code traslate this in a AoA with this structure
# [ 
#   [A1 B1 C1 ... ] 
#   [A2 B2 C2 ....] 
#   [A3 B3 C3 ... ]
# ]
# like _NetData.csv
my @antennaAzimut;
$skip2   = 'x[' . ($s->header->networkCount-1)*2 .  ']';
$b = $s->bfile->get_bytes($NetRoleLen->($s->header) * 2);
foreach (0..$s->header->networkCount-1) {
	my $format = 'x[' . $_ * 2  . '](S' .  $skip2 . ')' . ($s->header->unitCount-1) .  'S'; 
	my @net;
	my @azimut = unpack($format,$b);
	foreach my $azimut (@azimut) {
		my $unitDirection = 0;
		if ($azimut > 10000) {
			$unitDirection = $azimut - 10000;
			$azimut = 0;
		} else {
			$azimut /= 10;
		}
		push @net, {azimut => $azimut, direction => $unitDirection}
	}
	push @antennaAzimut, \@net;
}

# a short integer set how much structure follows.
# currently there are unknown elements
$b = $s->bfile->get_bytes(2);
my $format = "s";
my $unknowsCount = unpack($format,$b);
$b = $s->bfile->get_bytes($unknowsCount*2);
my @unknownElements = unpack($format x $unknowsCount,$b);
print Data::Dumper::Dumper(\@unknownElements);

# a short integer set how much network enabled in ElevationAngle
$b = $s->bfile->get_bytes(2);
my $format = "s";
my $antennaNetworkCount = unpack($format,$b);
# a short integer set how much units enabled in ElevationAngle
$b = $s->bfile->get_bytes(2);
my $format = "s";
my $antennaUnitsCount = unpack($format,$b);
my @antennaElevation;
$b = $s->bfile->get_bytes($antennaNetworkCount * 2 * $antennaUnitsCount);
foreach (0..$antennaNetworkCount-1) {
	my $format = 'x[' . $_ * 2  . '](S' .  $skip2 . ')' . ($antennaUnitsCount-1) .
	'S'; 
	my @net;
	my @elevation = unpack($format,$b);
	foreach my $elevation (@elevation) {
		my $unitDirection = 0;
		$elevation /= 10;
		push @net, {azimut => $elevation, direction => $unitDirection}
	}
	push @antennaElevation,\@net;
}
#print Data::Dumper::Dumper(\@antennaElevation);

# got version number again
$b = $s->bfile->get_bytes(2);
my $versionNumberAgain = unpack("s",$b);

die "not find version number where expected" unless ($versionNumberAgain == $s->header->version);

# this is a zero, don't known what it's
$b = $s->bfile->get_bytes(2);
my $unknownZeroNumber = unpack("s",$b);
die "unexpected value of $unknownZeroNumber while waiting 0 " unless ($unknownZeroNumber == 0);

# leght of landheight.dat path
$b = $s->bfile->get_bytes(2);
my $lenghtLandHeight = unpack("s",$b);
$b = $s->bfile->get_bytes($lenghtLandHeight);
my $pathLandHeight = unpack("a$lenghtLandHeight",$b);
print $pathLandHeight, "\n";

$s->bfile->close;
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
