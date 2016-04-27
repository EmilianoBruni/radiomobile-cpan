# Introduction #

This document analizes the structure of the configuration file .net saved by Radio Mobile software.

The .net is a binary file. Its macro structure has build by these blocks

  * [Header](#Header.md) informatio
  * [Units](#Units.md) information list
  * [Systems](#Systems.md) information list
  * [NetsUnitsRole](#NetsUnitsRole.md) with Units `<->` Nets association and the role of every unit in every net
  * [UnitsSystem](#UnitsSystem.md) with system of every unit in every net
  * [Nets](#Nets.md) information list
  * [Cov](#Cov.md) with coverage settings
  * [MapFilePath](#MapFilePath.md) with the path to .map file
  * [Pictures](#Pictures.md) list path to load
  * [UnitsHeight](#UnitsHeight.md) setting height of every unit in every net
  * [UnitIcon](#UnitIcon.md) with the icon of every unit
  * [SystemCableLoss](#SystemCableLoss.md) with additional cable loss for every system
  * [StyleNetworksProperties](#StyleNetworksProperties.md) with style networks properties window settings
  * [NetUnknown1](#NetUnknown1.md), a (currently) unknown network property
  * [SystemAntenna](#SystemAntenna.md), the antenna setting for every system
  * [UnitsAzimutDirection](#UnitsAzimutDirection.md), the azimut or unit direction of antenna in every unit in every net
  * [UnitUnknown1](#UnitUnknown1.md), a (currently) unknown unit property
  * [UnitsElevation](#UnitsElevation.md), the elevation angle of antenna in every unit in every net
  * [VersionNumberAgain](#VersionNumberAgain.md) with the version number (again)
  * [TwoByteZeros](#TwoByteZeros.md), a (currently unknown) two bytes zerofilled
  * [LandHeight](#LandHeight.md) with path to landheight file


# Header #

The file begins with a 10 byte structure with header and general information.

| **Field Name** | **Perl Type (pack)** | **VB Type** | **Len** |
|:---------------|:---------------------|:------------|:--------|
| **VERSION**      | `[f]` single-precision float | Single      | 4       |
| **NETWORKS COUNT** | `[s]` signed short   | Integer     | 2       |
| **UNITS COUNT** | `[s]` signed short   | Integer     | 2       |
| **SYSTEMS COUNT** | `[s]` signed short   | Integer     | 2       |

# Units #

Following there are "UNITS COUNT" elements which describe every unit of the simulation.

Every unit is a structure 44 bytes long with these property

| **Field Name** | **Perl Type (pack)** | **VB Type**       | **Len**  |
|:---------------|:---------------------|:------------------|:---------|
| **LON**        | `[f]` single-precision float | Single            | 4        |
| **LAT**        | `[f]` single-precision float | Single            | 4        |
| **H**          | `[f]` single-precision float | Single            | 4        |
| **ENABLED**    | `[s]` signed short           | Integer           | 2        |
| **TRANSPARENT**| `[s]` signed short           | Integer           | 2        |
| **FORECOLOR**  | `[l]` signed long            | Integer           | 4        |
| **BACKCOLOR**  | `[l]` signed long            | Integer           | 4        |
| **NAME**       | `[A]` ASCII string           | String\*20        | 20       |

# Systems #

Following there are "SYSTEMS COUNT" elements which describe every system of the simulation.

Every system is a structure 50 bytes long with these property

| **Field Name** | **Perl Type (pack)** | **VB Type**       | **Len**  |
|:---------------|:---------------------|:------------------|:---------|
| **TX**         | `[f]` single-precision float | Single            | 4        |
| **RX**         | `[f]` single-precision float | Single            | 4        |
| **LOSS**        | `[f]` single-precision float | Single            | 4        |
| **ANT**        | `[f]` single-precision float | Single            | 4        |
| **H**          | `[f]` single-precision float | Single            | 4        |
| **NAME**        | `[A]` ASCII string   | String\*30        | 30       |

# NetsUnitsRole #

Following there are "NETWORKS COUNT" `*` "UNITS COUNT" bytes shows in which network is associated an unit and its role (master/slave/node/terminal).

Given A,B,C... units and 1,2,3 Network so A1 is a byte indicate if unit A is in network 1 and its role.

It's structure is

` A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ... `

and so on.

Every byte has used in this way. Give A1 = aaaabbbb where aaaa is the first four bits and bbbb the others then aaaa is 1000 if the unit A belongs to network 1, 0000 else. bbbb, decoded as an integer 0..127 set the role of this unit in this network.

Examples: \x00 first role, no belong, \x01 second role, no belong, \x80 (128) first role, belong to network, \x81 (129) second role belong

# UnitsSystem #

Following there are "NETWORKS COUNT" `*` "UNITS COUNT" short unsigned integer (2 bytes) identifing the index of system element.

Given A,B,C... units and 1,2,3 Networks, A1 is a short identifying the system of the first unit in the first network between the 0-index elements of the systems list.

It's structure is

` A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ... `

and so on.

# Nets #

Following there are "NETWORKS COUNT" elements which describe every network of the simulation.

Every network is a structure 72 bytes long with these property

| **Field Name** | **Perl Type (pack)** | **VB Type**       | **Len**  |
|:---------------|:---------------------|:------------------|:---------|
| **MINFX**        | `[f]` single-precision float | Single            | 4        |
| **MAXFX**       | `[f]` single-precision float | Single            | 4        |
| **POL**        | `[s]` signed short   | Integer           | 2        |
| **EPS**        | `[f]` single-precision float | Single            | 4        |
| **SGM**        | `[f]` single-precision float | Single            | 4        |
| **ENS**        | `[f]` single-precision float | Single            | 4        |
| **CLIMATE**        | `[s]` signed short   | Integer           | 2        |
| **MDVAR**        | `[s]` signed short   | Integer           | 2        |
| **TIME**        | `[f]` single-precision float | Single            | 4        |
| **LOCATION**        | `[f]` single-precision float | Single            | 4        |
| **SITUATION**        | `[f]` single-precision float | Single            | 4        |
| **HOPS**        | `[s]` signed short   | Integer           | 2        |
| **TOPOLOGY**        | `[s]` signed short   | Integer           | 2        |
| **NAME**        | `[A]` ASCII string   | String\*30        | 30       |

# Cov #

Following there is a 74 byte long structure describe currently cartesian coverage windows setting.

![http://blog.ebruni.it/blog/wp-content/uploads/2011/01/Radio-Mobile-Single-Polar-Radio-Coverage-383x400.png](http://blog.ebruni.it/blog/wp-content/uploads/2011/01/Radio-Mobile-Single-Polar-Radio-Coverage-383x400.png)

Its structure is

| **Field Name** | **Perl Type (pack)** | **VB Type**       | **Len**  |
|:---------------|:---------------------|:------------------|:---------|
| **DMAX**       | `[f]` single-precision float | Single            | 4        |
| **THMIN**      | `[f]` single-precision float | Single            | 4        |
| **THMAX**      | `[f]` single-precision float | Single            | 4        |
| **THINC**      | `[f]` single-precision float | Single            | 4        |
| **ANTAZT**     | `[f]` single-precision float | Single            | 4        |
| **FILE**       | `[A]` ASCII string   | String\*20        | 20       |
| **TRESHOLD**   | `[s]` signed short   | Integer           | 2        |
| **LEVEL**      | `[f]` single-precision float | Single            | 4        |
| **AREA**       | `[S]` unsigned short | Boolean??         | 2        |
| **CAREA**      | `[l]` signed long    | Integer           | 4        |
| **CONTOUR**    | `[S]` unsigned short | Boolean           | 2        |
| **CCONTOUR**   | `[l]` signed long    | Integer           | 4        |
| **VHS**        | `[f]` single-precision float | Single            | 4        |
| **VHT**        | `[f]` single-precision float | Single            | 4        |
| **DMIN**       | `[f]` single-precision float | Single            | 4        |
| **VCOL**       | `[l]` signed long    | Integer           | 4        |

# MapFilePath #

Follow a 2 byte unsigned short integer which denotes the length of the next structure, a string of chars with the path to the .map file.

# Pictures #

Follow a 2 byte unsigned short integer. If this integer is not zero, it denotes the lenght of the next structure, a string of chars with the path to a picture file. Then we continue to read the next 2 byte unsigned short integer and if it's not zero, we read pictures path and we loop this process until we find a lenght of zero.

# UnitsHeight #

Following there are "NETWORKS COUNT" `*` "UNITS COUNT" single-precision float (4 bytes) identifing the height of every antenna unit in every network.

Given A,B,C... units and 1,2,3 Networks, A1 is a float identifing the height of the antenna of the first unit in the first network. If its value is zero, system height has taken.

It's structure is

` A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ... `

and so on.

# UnitIcon #

Following there are "UNITS COUNT" bytes which rappresent the index zero-based of the icon of any units. The value is an unsigned octet value 0..254

# SystemCableLoss #

Following we find "SYSTEMS COUNT" single-precision float (4 bytes) rappresents an additional line loss per meter in every system.

# StyleNetworksProperties #

Following we find a block of elements used for some program settings. It's 7 bytes long but it seems only first 4 bytes are used for Style Networks properties (use two ray LOS, draw green, yello, red and bg line, etc.)

[the window picture here](add.md)

Given b(1) the first bit, b(2..8) the bits from 2 to 8 we find that

  * b(1): Enabled (1) or disabled (0) "Draw a red line..."
  * b(2..8): an unsigned short to draw yellow line if RX >= b(2..8) - 50
  * b(9): Enabled (1) or disabled (0) "Draw a yellow line..."
  * b(10..16): an unsigned short to draw green line if RX >= b(10..16) - 50
  * b(17): Enabled (1) or disabled (0) "Draw a green line..."
  * b(18..23): Not used
  * b(24): Enabled (1) or disabled (0) "Draw lines with dark background"
  * b(25..30: Not used
  * b(31): Enabled (0) or disabled (1) "Use Two Rays..."
  * b(32): Normal (0) or Interference (1) Two Ray Los