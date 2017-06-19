<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:jc="http://james.blushingbunny.net/ns.html"
xmlns="http://www.tei-c.org/ns/1.0"
      xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output method="text"/>
  <!-- files and recurse parameters defaulting to '*.xml' and 'no' respectively -->
  <xsl:param name="files" select="'*.xml'"/>
  <xsl:param name="recurse" select="'yes'"/>
  
  <!-- The main template, everything happens here. -->
  <xsl:template name="main">
    <!-- create path from params -->
    <xsl:variable name="path">
      <xsl:value-of
        select="concat('./?select=', $files,';on-error=warning;recurse=',$recurse)"/>
    </xsl:variable>
    <!-- the main collection of all the documents we are dealing with -->
    <xsl:variable name="doc" select="collection($path)"/>
    <xsl:variable name="msDesc" select="$doc//msDesc"/>
<xsl:for-each select="$msDesc">
  <xsl:text>"</xsl:text><xsl:value-of select="jc:csvEscapeDoubleQuotes(msIdentifier/idno)"/><xsl:text>", "</xsl:text><xsl:value-of select="jc:csvEscapeDoubleQuotes(@xml:id)"/><xsl:text>"
</xsl:text>
</xsl:for-each>
</xsl:template>


  <!-- CSV doesn't like spare double quotes lying around. So you escape them by putting two double quotes instead --> 
  <xsl:function name="jc:csvEscapeDoubleQuotes" as="xs:string">
    <xsl:param name="string"/>
    <xsl:value-of select="replace($string, '&quot;', '&quot;&quot;')"/>
  </xsl:function>
    
</xsl:stylesheet>