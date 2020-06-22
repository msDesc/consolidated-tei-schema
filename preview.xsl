<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei html xs"
    version="2.0">
    
    <!-- This stylesheet will transform a single TEI document which has been written to validate to the msdesc schema
         (https://github.com/msdesc/consolidated-tei-schema) into a HTML page roughly as it would appear on a web site
         like www.fihrist.org.uk or medieval.bodleian.ox.ac.uk. But it will lack customisations added for each catalogue
         and CSS styling like fonts and indenting. Use the preview stylesheet in the processing subfolders of their own 
         GitHub repositories if working on an Oxford-maintained catalogue. -->
    
    <xsl:import href="https://raw.githubusercontent.com/bodleian/consolidated-tei-schema/master/msdesc2html.xsl"/>

    <xsl:template match="/">
        <xsl:variable name="title" as="xs:string" select="(/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:idno)[1]/text()"/>
        <html>
            <head>
                <title>Preview of <xsl:value-of select="$title"/></title>
            </head>
            <body style="padding:2em;">
                <h1>
                    <xsl:value-of select="$title"/>
                </h1>
                <div>
                    <xsl:call-template name="Header"/>
                    <xsl:apply-templates select="//msDesc"/>
                    <xsl:call-template name="AbbreviationsKey"/>
                    <xsl:call-template name="Footer"/>
                </div>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>
