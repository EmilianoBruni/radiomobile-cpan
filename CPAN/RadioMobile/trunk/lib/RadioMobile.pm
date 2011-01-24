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
	use RadioMobile::UnitIconParser;
	use RadioMobile::UnitsSystemParser;
	use RadioMobile::UnitsHeightParser;
	use RadioMobile::Systems;
	use RadioMobile::SystemCableLossParser;
	use RadioMobile::Nets;
	use RadioMobile::NetsUnits;
	use RadioMobile::Cov;
	use RadioMobile::Config;

	__PACKAGE__->valid_params(
								file 	=> { type => SCALAR, optional => 1 },
								debug 	=> { type => SCALAR, optional => 1, default => 0 },
								header	=> { isa  => 'RadioMobile::Header'},
								units	=> { isa  => 'RadioMobile::Units'},
								systems	=> { isa  => 'RadioMobile::Systems'},
								nets	=> { isa  => 'RadioMobile::Nets'},
								netsunits	=> { isa  => 'RadioMobile::NetsUnits'},
								config	=> { isa  => 'RadioMobile::Config'},

	);

	__PACKAGE__->contained_objects(
		'header'	=> 'RadioMobile::Header',
		'units'		=> 'RadioMobile::Units',
		'systems'	=> 'RadioMobile::Systems',
		'nets'		=> 'RadioMobile::Nets',
		'netsunits'	=> 'RadioMobile::NetsUnits',
		'config'	=> 'RadioMobile::Config',
	);

	use Class::MethodMaker [ scalar => [qw/file debug header units 
		bfile systems nets netsunits config/] ];

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

		# open binary .net file
		$s->{bfile} = new File::Binary($s->file);

		# read header
		$s->header->parse;
		print $s->header->dump if $s->debug;

		# read units
		$s->units->parse;
		print $s->units->dump if $s->debug;

		# read systems
		$s->systems->parse;
		print $s->systems->dump if $s->debug;

		# initialize nets (I need them in net_role structure)
		$s->nets->reset;
		#print $s->nets->dump if $s->debug;


		# read net_role
		$s->netsunits->parse;
		print "isIn: \n", $s->netsunits->dump('isIn') if $s->debug;
		print "role: \n", $s->netsunits->dump('role') if $s->debug;

		# read system for units in nets
		my $ns = new RadioMobile::UnitsSystemParser(
											bfile 		=> $s->bfile,
											header		=> $s->header,
											netsunits 	=> $s->netsunits
										);
		$ns->parse;
		print "system: \n", $s->netsunits->dump('system') if $s->debug;

		# read nets
		$s->nets->parse;
		print $s->nets->dump if $s->debug;

		# read and unpack coverage
		my $cov = new RadioMobile::Cov;
		$cov->parse($s->bfile);

		# lettura del percorso al file map
		$s->config->parse_mapfilepath;
		print "Map file path: " . $s->config->mapfilepath . "\n" if $s->debug;

		# lettura dei percorsi delle picture da caricare
		$s->config->pictures->parse;
		print "PICTURES: " . $s->config->pictures->dump . "\n" if $s->debug;

		# read net_h 
		my $hp = new RadioMobile::UnitsHeightParser(
											bfile 		=> $s->bfile,
											header		=> $s->header,
											netsunits 	=> $s->netsunits
										);
		$hp->parse;
		print "height: \n", $s->netsunits->dump('height') if $s->debug;

		# unit icon
		my $up = new RadioMobile::UnitIconParser(parent => $s);
		$up->parse;
		print "UNITS with ICONS: \n", $s->units->dump if $s->debug;

		# system cable loss
		my $cp = new RadioMobile::SystemCableLossParser(parent => $s);
		$cp->parse;
		print "SYSTEMS with CABLE LOSS: \n", $s->systems->dump if $s->debug;

# parse Style Networks properties
$s->config->parse_stylenetworks;
print "Style Network Properties: " . $s->config->stylenetworksproperties->dump if $s->debug;


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
my $skip2   = 'x[' . ($s->header->networkCount-1)*2 .  ']';
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
