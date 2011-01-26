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
