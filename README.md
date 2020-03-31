This repository is primarily the location of the schema used by various manuscript catalogues, including union catalogues of collections at multiple institutions ([Fihrist](https://github.com/fihristorg/fihrist-mss) and [Senmai](https://github.com/bodleian/senmai-mss)) and catalogues of collections held at the University of Oxford (for [Medieval](https://github.com/bodleian/medieval-mss), [Hebrew](https://github.com/bodleian/hebrew-mss), [Genizah](https://github.com/bodleian/genizah-mss), [Georgian](https://github.com/bodleian/georgian-mss), [Armenian](https://github.com/bodleian/armenian-mss), and [Tibetan](https://github.com/bodleian/karchak-mss).)

The schema is a customized version of the TEI (Text Encoding Initiative) P5 standard. The master copy is [msdesc.odd](/msdesc.odd), written in TEI's own [ODD](http://www.tei-c.org/guidelines/customization/getting-started-with-p5-odds/) schema language. That has been converted into schema formats which XML editors and validating parsers can understand. The [msdesc.rng](/msdesc.rng) RELAX NG file is the definitive version, but [alternatives](/alternatives/) are also provided.

The direct URLs for validating (e.g. to paste into an `xml-model` declaration or to point an XML editor like Oxygen XML at) are:

* https://raw.githubusercontent.com/msdesc/consolidated-tei-schema/master/msdesc.rng
* https://raw.githubusercontent.com/msdesc/consolidated-tei-schema/master/alternatives/msdesc.xsd
* https://raw.githubusercontent.com/msdesc/consolidated-tei-schema/master/alternatives/msdesc.dtd

Also provided is documentation, including details of the customization and guidelines for people using it to encode manuscript descriptions. [HTML](https://msdesc.github.io/consolidated-tei-schema/msdesc.html) and [PDF](https://msdesc.github.io/consolidated-tei-schema/msdesc.pdf) versions are available (generated from the ODD file.)

The repository also contains templates that may be used as starting points by cataloguers. [template.xml](/template.xml) is for manuscripts comprising a single codicological unit, and [template-msPart.xml](/template-msPart.xml) is for manuscripts comprising more than one codicological unit.

Finally, this repository is additionally the location for library files used by XSL and XQuery scripts in the catalogue repositories to process the TEI (e.g. converting into HTML, generating indexes for [Blacklight](http://projectblacklight.org/)-based web sites.
