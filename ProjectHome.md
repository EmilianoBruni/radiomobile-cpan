This module is a Perl interface to .net file of Radio Mobile, a software to predict the performance of a radio system.

Currently this module only parse .net file to extract all information available inside it such as units, radio systems, networks, some configuration of program behaviour, the header with version file, number of units, systems and networks. It also extract the relation between units, systems and networks to show the units associated to a network, their systems and so on.

As soon as possible it will be possible to create a .net from scratch with information available, as an example, from a database.

This module supports only .net file with 4000 as version number (I don't know exactly from which it has been adopted this but I'm sure that all Radio Mobile file starting from version 9.x.x used this).