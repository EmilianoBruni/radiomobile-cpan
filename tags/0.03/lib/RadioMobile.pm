	package RadioMobile;

	use 5.008000;
	use strict;
	use warnings;

	use Class::Container;
	use Params::Validate qw(:types);
	use base qw(Class::Container);

	use File::Binary;
	use IO::Scalar;

	use RadioMobile::Header;
	use RadioMobile::Units;
	use RadioMobile::UnitIconParser;
	use RadioMobile::UnitUnknown1Parser;
	use RadioMobile::UnitsSystemParser;
	use RadioMobile::UnitsHeightParser;
	use RadioMobile::UnitsAzimutDirectionParser;
	use RadioMobile::UnitsElevationParser;
	use RadioMobile::Systems;
	use RadioMobile::SystemCableLossParser;
	use RadioMobile::SystemAntennaParser;
	use RadioMobile::Nets;
	use RadioMobile::NetUnknown1Parser;
	use RadioMobile::NetsUnits;
	use RadioMobile::Cov;
	use RadioMobile::Config;

	__PACKAGE__->valid_params(
								file	=> { type => SCALAR, optional => 1 },
								filepath=> { type => SCALAR, optional => 1 },
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

	use Class::MethodMaker [ scalar => [qw/filepath debug header units 
		bfile file systems nets netsunits config/] ];

	our $VERSION	= '0.03';

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
		if ($s->file) {
			# first try to see if you give me binary raw data
			my $data	= $s->file;
			my $io		= new IO::Scalar(\$data);
			$s->{bfile}	= new File::Binary($io);
		} elsif ($s->filepath) {
			# then try to see if you give me a file path
			$s->{bfile} = new File::Binary($s->filepath);
		} else {
			die "You must set file or filepath for enable parsing";
		}

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
		print "Style Network Properties: " . 
					$s->config->stylenetworksproperties->dump if $s->debug;

		# parse an unknown structure of 8 * networkCount bytes
		my $un = new RadioMobile::NetUnknown1Parser(parent => $s);
		$un->parse;
		print "Network after unknown1 structure: " .
					$s->nets->dump if $s->debug;

		# parse system antenna
		my $ap = new RadioMobile::SystemAntennaParser(parent => $s);
		$ap->parse;
		print "SYSTEMS with Antenna: \n", $s->systems->dump if $s->debug;


		# read azimut antenas
		my $ad = new RadioMobile::UnitsAzimutDirectionParser(parent => $s);
		$ad->parse;
		print "Azimut: \n", $s->netsunits->dump('azimut') if $s->debug;
		print "Direction: \n", $s->netsunits->dump('direction') if $s->debug;

		# read unknown units property
		my $uu = new RadioMobile::UnitUnknown1Parser(parent => $s);
		$uu->parse;
		print "UNITS after unknown1 structure: " .  $s->units->dump if $s->debug;

		# read elevation antenas
		my $ep = new RadioMobile::UnitsElevationParser(parent => $s);
		$ep->parse;
		print "Elevation: \n", $s->netsunits->dump('elevation') if $s->debug;

		# got version number again
		my $b = $s->bfile->get_bytes(2);
		my $versionNumberAgain = unpack("s",$b);
		die "not find version number where expected" unless ($versionNumberAgain == $s->header->version);

		# this is a zero, don't known what it's
		$b = $s->bfile->get_bytes(2);
		my $unknownZeroNumber = unpack("s",$b);
		die "unexpected value of $unknownZeroNumber while waiting 0 " unless ($unknownZeroNumber == 0);
		# lettura del percorso al file landheight
		$s->config->parse_landheight;
		print "Land Height path: " . $s->config->landheight . "\n" if $s->debug;

		$s->bfile->close;
	}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

RadioMobile - A Perl interface to Radio Mobile .net file

=head1 SYNOPSIS

  use RadioMobile;
  my $rm = new RadioMobile();
  $rm->file('path_to_radiomobile_file.net');
  $rm->parse;

  my $header = $rm->header;
  my $units  = $rm->units;

  foreach my $idxUnit (0..$header->unitCount-1) {
	  my $unit = $units->at($idxUnit);
	  printf("%s at lon %s and lat %s\n", $unit->name, 
	    $unit->lon, $unit->lat);
  }

=head1 DESCRIPTION

This module is a Perl interface to .net file of Radio Mobile, a software
to predict the performance of a radio system.

Currently this module only parse .net file to extract all information
available inside it such as units, radio systems, networks, some
configuration of program behaviour, the header with version file, number
of units, systems and networks. It also extract the relation between
units, systems and networks to show the units associated to a network,
their systems and so on.

As soon as possible it will be possible to create a .net from scratch
with information available, as an example, from a database.

This module supports only .net file with 4000 as version number (I don't
know exactly from which it has been adopted this but I'm sure that all
Radio Mobile file starting from version 9.x.x used this).

=head1 BE CAREFUL

This is a beta test release. Interfaces can change in future. Report me
any bug you will find.

=head1 METHODS

=head2 new()

Call C<new()> to create a new RadioMobile object

  my $rm = new RadioMobile();

You can call C<new()> to force parsing to dump all structures found using
the debug parameter

  my $rm = new RadioMobile(debug => 1);

=head2 file()

Use this method to set a scalar with Radio Mobile .net raw data

  $rm->file('net1.net');

=head2 filepath()

Use this method to set the path, relative or absolute, to a .net file
created by Radio Mobile software.

  open(NET,$filepath);
  binmode(NET);
  my $dotnet = '';
  while (read(NET,my $buff,8*2**10)) { $dotnet .=  $buff }
  close(NET);
  $rm->file($dotnet);

=head2 parse()

Execute this method for parsing the .net file set with C<file()> or 
C<filepath()> method and fullfill C<header()>, C<config()>, C<units()>,
C<systems()>, C<nets()> and C<netsunits()> elements.

=head2 header()

Returns a L<RadioMobile::Header> object with information about .net
version file, number of units, systems and networks

=head2 config()

Returns a L<RadioMobile::Config> object with Style Network Properties
window setting, list of pictures to be open, the mapfile and landheight
path.

=head2 units()

Returns a L<RadioMobile::Units> object with a list of all units.

=head2 systems()

Returns a L<RadioMobile::Systems> object with a list of all systems.


=head2 nets()

Returns a L<RadioMobile::Nets> object with a list of all networks.

=head2 netsunits

Returns a L<RadioMobile::NetsUnits> object which is a matrix
C<$header-E<gt>networkCount * $header-E<gt>unitCount> with all relation between
units, networks and systems.

=head1 OBJECT MODEL

In F<docs/> distribution directory you can find a PDF with a summarize 
of RadioMobile object model.

=head1 AUTHOR

Emiliano Bruni, <lt>info@ebruni.it<gt>

=head1 COPYRIGHT AND LICENSE

This module is a copyright by Emiliano Bruni

Radio Mobile software is a copyright by Roger Coude' VE2DBE.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
