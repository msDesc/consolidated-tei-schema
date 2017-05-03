<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
     xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:jc="http://james.blushingbunny.net/ns.html" exclude-result-prefixes="tei jc" version="2.0">

<!-- 
  Created by James Cummings james@blushingbunny.net 
  2017-04 to 2017-05 or so
  for up-conversion of existing TEI Catalogue
  -->


<!-- Set up the collection of files to be converted -->
  <!-- files and recurse parameters defaulting to '*.xml' and 'no' respectively -->
  <xsl:param name="files" select="'*.xml'"/>
  <xsl:param name="recurse" select="'yes'"/>
  <!-- path hard-coded to location on my desktop -->
  <xsl:variable name="path">
    <xsl:value-of
      select="concat('file:///home/jamesc/Dropbox/stuff/Desktop/Work/projects/Bodleian-TEI-Catalogue-Consolidation/working/tolkien-xml/working/?select=', $files,';on-error=warning;recurse=',$recurse)"/>
  </xsl:variable>
  
  <!-- the main collection of all the documents we are dealing with -->
  <xsl:variable name="doc" select="collection($path)"/>
  

  <!-- In case there are existing schema associations, let's get rid of those -->
<xsl:template match="processing-instruction()"/>

<!-- Named template which we call that starts off the whole thing-->
<xsl:template name="main">
  <!-- For each item in the collection -->
  <xsl:for-each select="$doc">
    <xsl:sort select="tokenize(base-uri(), '/')[last()-1]"/>
    <xsl:sort select="tokenize(base-uri(), '/')[last()]"/>
    <xsl:variable name="baseURI"><xsl:value-of select="base-uri()"/></xsl:variable>
    <xsl:variable name="filename"><xsl:value-of select="tokenize(base-uri(), '/')[last()]"/></xsl:variable>
    <xsl:variable name="folder"><xsl:value-of select="tokenize(base-uri(), '/')[last()-1]"/></xsl:variable>
    <xsl:variable name="fileNum"><xsl:value-of select="position()"/></xsl:variable>
    <xsl:variable name="msID"><xsl:value-of select="jc:normalizeID(.//msDesc[1]/msIdentifier/idno)"/></xsl:variable>
    
    <!-- This is just a debugging message so I see the filnames whiz by on the screen -->
   <xsl:message>
      Base URI: <xsl:value-of select="$baseURI"/>
      Folder: <xsl:value-of select="$folder"/>
      Old Filename: <xsl:value-of select="$filename"/>
      New ID: <xsl:value-of select="$msID"/>
    </xsl:message>
    
    <!-- Create the output file name -->
<xsl:variable name="outputFilename"  
      select="concat('file:/home/jamesc/Dropbox/stuff/Desktop/Work/projects/Bodleian-TEI-Catalogue-Consolidation/working/tolkien-xml/new/', 
      $folder, '/', $msID, '.xml')"/> 
    <!-- create output file -->
<xsl:result-document href="{$outputFilename}" method="xml" indent="yes">
  <!-- add relative schema associations -->
<xsl:text>&#xA;</xsl:text><xsl:processing-instruction name="xml-model">href="../bodley-msDesc.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
<xsl:text>&#xA;</xsl:text><xsl:processing-instruction name="xml-model">href="../bodley-msDesc.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"</xsl:processing-instruction>
<xsl:text>&#xA;</xsl:text>
  <!-- TEI/@xml:id contains the manuscript_12345 used on the website -->
  <TEI xml:id="{concat('manuscript_', $fileNum)}">
  <xsl:apply-templates/>
  </TEI>
</xsl:result-document>
  </xsl:for-each>
</xsl:template>
    
    <!-- By default we just copy the input to the output -->
    <xsl:template match="@*|node()" priority="-1">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()|comment()"/>
        </xsl:copy>
    </xsl:template>
  
    <!-- Make TEI element vanish since adding it above -->
    <xsl:template match="TEI"><xsl:apply-templates/></xsl:template>
  
   <!-- Add ID to msDesc -->
   <xsl:template match="msDesc">
     <xsl:if test="count(//msDesc) gt 1">Error: more than one msDesc in this file!</xsl:if>
     <msDesc xml:id="{jc:normalizeID(msIdentifier/idno)}"><xsl:apply-templates select="@*[name() ne 'xml:id']|node()"/></msDesc>
   </xsl:template>
  
  
<!-- Schema normalisation -->    
    <!-- bibl/@type -->
   <xsl:template match="bibl/@type">
     <xsl:variable name="type">
       <xsl:choose>
         <!--<xsl:when test=".='commentedOn'">commentary</xsl:when>-->
         <xsl:when test=".='digitised-version' or .='related-items' or .='realted-volumes' or .='related-volumes' or .='referred'">related</xsl:when>
         <xsl:when test=".='extracts'">extract</xsl:when>
         <xsl:when test=".='ms'">MS</xsl:when>
         <xsl:when test=".='textual-relations'">text-relations</xsl:when>
         <xsl:when test=".='translated'">translation</xsl:when>
         <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
       </xsl:choose>
     </xsl:variable>
     <xsl:if test="normalize-space($type) != ''"><xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute></xsl:if>
   </xsl:template>
  
  
  <!-- decoNote/@type -->
  <xsl:template match="decoNote/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test=".='frieze' ">border</xsl:when>
        <xsl:when test=".='decoration' or .='paratext' or .='printmark' or .='secondary' or .='unspecified'">other</xsl:when>
        <xsl:when test=".='diagrams'">diagram</xsl:when>
        <xsl:when test=".='ms'">MS</xsl:when>
        <xsl:when test=".='borderInitials'">initial_border</xsl:when>
         <xsl:when test=".='intials'">initial</xsl:when>
        <xsl:when test=".='marginalSketches'">marginal</xsl:when>
        <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="normalize-space($type) != ''"><xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute></xsl:if>
  </xsl:template>
  
  <!-- dimensions/@type -->
  <xsl:template match="dimensions/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="normalize-space(.)='number of folia'">folia</xsl:when>
        <xsl:when test=".='ruledColumn' or .='ruling'">ruled</xsl:when>
        <xsl:when test=".='leaves'">leaf</xsl:when>
        <xsl:when test=".='ms'">MS</xsl:when>
        <xsl:when test=".='unknown'">other</xsl:when>
        <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="normalize-space($type) != ''"><xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute></xsl:if>     
  </xsl:template>
  
  <!-- name/@type -->
   <xsl:template match="name/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="normalize-space(.)=''"/>
        <xsl:when test=".='artist'">person</xsl:when>
        <xsl:when test=".='church' or .='corporate'">org</xsl:when>
        <xsl:when test=".='ms'">MS</xsl:when>
        <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
     <xsl:if test="normalize-space($type) != ''"><xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute></xsl:if>     
  </xsl:template>
  
  <!-- title/@type -->
   <xsl:template match="title/@type">
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="normalize-space(.)=''"/>
        <xsl:when test=".='alternative' or .='parallel'">alt</xsl:when>
        <xsl:when test=".='general' or .='uniform'">main</xsl:when>
        <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
     <xsl:if test="normalize-space($type) != ''"><xsl:attribute name="type"><xsl:value-of select="$type"/></xsl:attribute></xsl:if>     
  </xsl:template>
  
   
   
  <!-- up-conversions -->
  
  <!-- Make name/@type='person' into <persName> in the end easier just to do it for all of them and make nested persName vanish -->
   <xsl:template match="name[@type='person']|name[@type='artist']">
     <persName><xsl:apply-templates select="@*[not(name()='type')]|node()" /></persName><!--
     <xsl:choose>
       <xsl:when test="not(persName)"><persName><xsl:apply-templates select="@*[name() ne 'type']|node()" /></persName></xsl:when>
       <xsl:when test="persName and count(*)=1"><persName><xsl:apply-templates select="@*|node()"/></persName></xsl:when>
       <xsl:otherwise><persName><xsl:apply-templates select="@*[name() ne 'type']|node()" /></persName></xsl:otherwise>
     </xsl:choose>-->
     </xsl:template>
  <xsl:template match="name[@type='person' or @type='artist']/persName"><xsl:apply-templates/></xsl:template>
  
  <!-- Same with corporate to orgName  and church-->
  <xsl:template match="name[@type='corporate']|name[@type='church']">
    <orgName><xsl:apply-templates select="@*[not(name()='type')]|node()"/></orgName>
  </xsl:template>
  <xsl:template match="name[@type='corporate' or @type='church']/persName"><xsl:apply-templates/></xsl:template>

 <xsl:template match="author/persName"><xsl:apply-templates/></xsl:template>
  
  <!-- Why does author sometimes have title in it? Let's move it to after -->
 <xsl:template match="author[title]">
   <xsl:copy>
     <xsl:apply-templates select="@*|node()[not(name()='title')]"/>
   </xsl:copy>
   <xsl:copy-of select="title"/>
 </xsl:template> 
  <!-- make it vanish -->
  <xsl:template match="author/title"/>
    
  <xsl:template match="origin//date">
    <origDate><xsl:apply-templates select="@*|node()"/></origDate>
  </xsl:template>
  
  
  <!-- 
msPart/altIdentifier needs to be changed to msIdentifier
  but also split those existing altIdentifiers with commas 
   -->
  <xsl:template match="altIdentifier">
    <xsl:variable name="current" select="."/>
    <xsl:choose>
      <xsl:when test="parent::msPart and idno[matches(., '.*[a-zA-Z].*')]">
        <msIdentifier>
          <altIdentifier>
            <xsl:apply-templates select="@*|node()"/>
          </altIdentifier>
        </msIdentifier>    
      </xsl:when>
      <xsl:when test="parent::msPart and idno[not(matches(., '.*[a-zA-Z].*'))]">
        <msIdentifier>
          <xsl:choose>
            <xsl:when test="contains(idno, ',')">
              <xsl:for-each select="tokenize(idno, ',')">
                <altIdentifier>
                  <xsl:copy-of select="$current/@*"/>
                  <idno><xsl:copy-of select="$current/idno/@*"/><xsl:value-of select="normalize-space(.)"/></idno>
                </altIdentifier>
              </xsl:for-each>
              </xsl:when>
            <xsl:otherwise>
                <altIdentifier>
                  <xsl:apply-templates select="@*|node()"/>
                </altIdentifier>
            </xsl:otherwise>
          </xsl:choose>
          </msIdentifier>
      </xsl:when>
      <xsl:when test="not(parent::msPart) and idno[not(matches(., '.*[a-zA-Z].*'))] and contains(idno, ',')">
        <xsl:for-each select="tokenize(idno, ',')">
          <altIdentifier>
            <xsl:copy-of select="$current/@*"/>
            <idno><xsl:copy-of select="$current/idno/@*"/><xsl:value-of select="normalize-space(.)"/></idno>
          </altIdentifier>
        </xsl:for-each>
        </xsl:when>
      <xsl:otherwise>
        <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
      </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
  
  <!-- Give new ID to each msPart -->
  <xsl:template match="msPart">
    <xsl:variable name="num"><xsl:number count="msPart" level="any"/></xsl:variable>
    <xsl:variable name="msID"><xsl:value-of select="jc:normalizeID(ancestor::msDesc/msIdentifier/idno)"/></xsl:variable>
<msPart xml:id="{concat($msID, '-', $num)}">
  <xsl:apply-templates select="@*[not(name()='xml:id')]|node()"/>
</msPart>   
  </xsl:template>
  
  
  <!-- 
  Replace publicationStmt
  -->
  <xsl:template match="publicationStmt">
    <xsl:variable name="folder"><xsl:value-of select="tokenize(base-uri(), '/')[last()-1]"/></xsl:variable>
    <xsl:variable name="msID"><xsl:value-of select="jc:normalizeID(//msDesc[1]/msIdentifier/idno)"/></xsl:variable>
    <publicationStmt>
      <publisher>Special Collections, Bodleian Libraries</publisher>
      <address>
        <orgName type="department">Special Collections</orgName>
        <orgName type="unit">Bodleian Libraries</orgName>
        <orgName type="institution">University of Oxford</orgName>
        <street>Weston Library, Broad Street</street>
        <settlement>Oxford</settlement>
        <postCode>OX1 3BG</postCode>
        <country>United Kingdom</country>
      </address>
      <distributor>
        <email>specialcollections.enquiries@bodleian.ox.ac.uk</email>
      </distributor>
      <availability>
        <licence target="https://creativecommons.org/licenses/by/4.0/">A Creative Commons Attribution licence applies to this file.</licence>
      </availability>
      <idno type="msID"><xsl:value-of select="$msID"/></idno>
      <idno type="collection"><xsl:value-of select="translate($folder, '_', ' ')"/></idno>  
    </publicationStmt>
  </xsl:template>
  
  <!-- Add revisionDesc to the teiHeader -->
  <xsl:template match="teiHeader">
    <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <xsl:choose>
      <xsl:when test="revisionDesc"><xsl:message>WARNING: Already has a revisionDesc element</xsl:message></xsl:when>
      <xsl:otherwise>
        <revisionDesc>
          <change when="{substring(string(current-date()), 0, 11)}">
            <persName>James Cummings</persName>
            Up-converted the markup using 
            <ref target="https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/convertTolkien2Bodley.xsl">https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/convertTolkien2Bodley.xsl</ref>
          </change>
        </revisionDesc>    
      </xsl:otherwise>
    </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <!-- If it has a revisionDesc -->
  <xsl:template match="revisionDesc">
    <xsl:copy>
    <change when="{substring(string(current-date()), 0, 11)}">
      <persName>James Cummings</persName>
      Up-converted the markup using 
      <ref target="https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/convertTolkien2Bodley.xsl">https://github.com/jamescummings/Bodleian-msDesc-ODD/blob/master/convertTolkien2Bodley.xsl</ref>
     </change>
    <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Some have /@type in teiHeader -->
  
  <xsl:template match="teiHeader/@type"/>
  
  <!-- type not allowed on msItem --> 
  <xsl:template match="msItem/@type"/>
  
  <!-- tittle is surely title! -->
  <xsl:template match="tittle"><title><xsl:apply-templates select="@*|node()"/></title></xsl:template>    
  
  <xsl:template match="listBibl[not(*)]"/>
  
  
  
  <!-- function to replace characters in manuscript identifiers -->
  <xsl:function name="jc:normalizeID" >
    <xsl:param name="ID" as="item()"/>
    <xsl:variable name="pass0"><xsl:value-of select="translate(normalize-space($ID), '\/`!£$%^[_]()}{,.', '')"/></xsl:variable>    
    <xsl:variable name="pass1"><xsl:value-of select="replace(normalize-space($pass0), ' - ', '-')"/></xsl:variable>
    <xsl:variable name="pass2"><xsl:value-of select="replace(normalize-space($pass1), '\*', '-star')"/></xsl:variable>
    <xsl:variable name="apos">&apos;</xsl:variable>
    <xsl:variable name="pass3"><xsl:value-of select="replace(normalize-space($pass2), $apos, '')"/></xsl:variable>    
    <xsl:value-of select="translate(normalize-space($pass3), ' ','_')"/></xsl:function>
  
</xsl:stylesheet>