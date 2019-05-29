# Astro::Montenbruck


Library of astronomical calculations, based on
_"Astronomy On The Personal Computer"_ by _O.Montenbruck_ and _T.Phleger_,
_Fourth Edition, Springer-Verlag, 2000_.

As the book authors state, they have tried to obtain an accuracy that is
approximately the same as that found in astronomical yearbooks.

```
"The errors in the fundamental routines for determining the coordinates
of the Sun, the Moon, and the planets amount to about 1″-3″."

-- Introduction to the 4-th edition, p.2.
```

There are many astronomical libraries available in the public domain. While
giving accurate results, they often suffer from lack of convenient API,
documentation and maintainability. Most of the source code is written in C, C++
or Java, and not dynamic languages. So, it is not easy for a layman to customize
them for her custom application, be it an online lunar calendar, or tool for
amateur sky observations. This library is an attempt to find a middle-ground
between precision on the one hand and compact, well organized code on the other.


## Contents

- [Astro::Montenbruck::MathUtils](lib/Astro/Montenbruck/MathUtils.pm) — Core mathematical routines.
- [Astro::Montenbruck::Time](lib/Astro/Montenbruck/Time.pm) — Time-related routines.
- [Astro::Montenbruck::Ephemeris](lib/Astro/Montenbruck/Ephemeris.pm) — Positions of celestial bodies.
- [Astro::Montenbruck::CoCo](lib/Astro/Montenbruck/CoCo.pm) —  Coordinates conversions.
- [Astro::Montenbruck::Nutation](lib/Astro/Montenbruck/Nutation.pm) —  Nutation and obliquity of ecliptic.

## Requirements

* *Perl* >= 5.22

Tested on Linux 64-bit and macOS 10.14. There should be no problems at other platforms.

Perl dependencies are minimal, most of the external modules are part of the standard
distribution. [DateTime](https://metacpan.org/pod/DateTime) is not really required.
It is used only in example scripts and tests, not the library itself.


## Installation

To install this module, run the following commands:

```
$ perl Build.PL
$ ./Build
$ ./Build test
$ ./Build install
```

## Documentation

After installing, you can find documentation for this module with the
perldoc command from the parent directory of the library:

```
$ perldoc Astro::Montenbruck
$ perldoc Astro::Montenbruck::Ephemeris

```

You may also generate local HTML documentation with

```
$ perl script/createdocs.pl
```

Documentation files will be installed to **docs/** directory.

## Usage

**script/** directory contains examples of the library usage. They will be
extended over time.

To display current planetary positions, type:

```
$ perl script/ephemeris.pl
```

For list of available options. type:

```
$ perl script/ephemeris.pl -h
```


## License And Copyright

Copyright (C) 2010-2019 Sergey Krushinsky

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (1.0). You may obtain a
copy of the full license at:

https://dev.perl.org/licenses/artistic.html

Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution. Such use shall not be
construed as a distribution of this Package.

The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
