<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  xmlns:jc="http://james.blushingbunny.net/ns.html" exclude-result-prefixes="tei jc" version="2.0">

  <!-- 
  Created by James Cummings james@blushingbunny.net 
  2017-05
  for output of Bodley TEI msDescs
  -->

  <!-- Set up the collection of files to be converted -->
  <!-- files and recurse parameters defaulting to '*.xml' and 'no' respectively -->
  <xsl:param name="files" select="'*.xml'"/>
  <xsl:param name="recurse" select="'yes'"/>
  <!-- path hard-coded to location on my desktop -->
  <xsl:variable name="path">
    <xsl:value-of
      select="concat('file:///home/jamesc/Dropbox/stuff/Desktop/Work/projects/Bodleian-TEI-Catalogue-Consolidation/working/tolkien-xml/new/?select=', $files,';on-error=warning;recurse=',$recurse)"
    />
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
      <xsl:variable name="baseURI">
        <xsl:value-of select="base-uri()"/>
      </xsl:variable>
      <xsl:variable name="filename">
        <xsl:value-of select="tokenize(base-uri(), '/')[last()]"/>
      </xsl:variable>
      <xsl:variable name="folder">
        <xsl:value-of select="tokenize(base-uri(), '/')[last()-1]"/>
      </xsl:variable>
      <xsl:variable name="msID">
        <xsl:value-of select="//msDesc/@xml:id"/>
      </xsl:variable>

      <!-- This is just a debugging message so I see the filnames whiz by on the screen -->
      <xsl:message> Base URI: <xsl:value-of select="$baseURI"/> 
        Folder: <xsl:value-of select="$folder"/> 
        Old Filename:<xsl:value-of select="$filename"/> 
        New ID: <xsl:value-of select="$msID"/>
      </xsl:message>

      <!-- Create the output file name -->
      <xsl:variable name="outputFilename"
        select="concat('file:/home/jamesc/Dropbox/stuff/Desktop/Work/projects/Bodleian-TEI-Catalogue-Consolidation/working/tolkien-xml/html/', 
      $folder, '/', $msID, '.html')"/>
      <!-- create output file -->
      <xsl:result-document href="{$outputFilename}" method="xml" indent="yes">
        <html>
          <head>
            <title>
              <xsl:value-of select="//msDesc/msIdentifier/idno[@type='shelfmark']"/>
            </title>
          </head>
          <body>
            <div class="content" id="{//msDesc/@xml:id}">
              <div class="titleStmt" id="titleStmt">
                <h1 class="mainTitle"><xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/title[1]"/></h1>
                <h2 class="collectionTitle"><xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/title[@type='collection']"/></h2>
              </div>
              
              <xsl:apply-templates select="//msDesc"/>
              
              <div class="publicationStmt" id="publicationStmt">
                <h3 class="publicationStmtHeading">Publication Statement</h3>
                <p class="publisher">Published by <xsl:value-of select="/TEI/teiHeader/fileDesc/publicationStmt/publisher"/> <xsl:apply-templates select="/TEI/teiHeader/fileDesc/publicationStmt/address"/> </p>
                <p class="distributor">Contact: <a class="distributorEmail" href="{normalize-space(/TEI/teiHeader/fileDesc/publicationStmt/distributor/email)}"><xsl:value-of select="normalize-space(/TEI/teiHeader/fileDesc/publicationStmt/distributor/email)"/></a></p>
                <p class="availability">License: <xsl:apply-templates select="/TEI/teiHeader/fileDesc/publicationStmt/licence"/></p>
              </div>
              
              <div class="respStmt" id="respStmt">
                <h3>Description Edition and Responsibilities</h3>
                <xsl:apply-templates select="/TEI/teiHeader/fileDesc/editionStmt/edition"/>
                <xsl:apply-templates select="/TEI/teiHeader/fileDesc/titleStmt/respStmt"/>
                <xsl:apply-templates select="/TEI/teiHeader/fileDesc/editionStmt/respStmt"/>
                <xsl:apply-templates select="/TEI/teiHeader/revisionDesc"/>
               </div>
              
              
              
             </div>
          </body>
        </html>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>


<xsl:template match="titleStmt/title">
<li class="title"><span class="label">Title: </span> <xsl:apply-templates/> <xsl:if test="@type">(<xsl:value-of select="@type"/>)</xsl:if></li>  
</xsl:template>
  
  
  <xsl:template match="editionStmt/edition">
    <li class="title"><span class="label">Edition: </span> <xsl:apply-templates/> <xsl:if test="@type">(<xsl:value-of select="@type"/>)</xsl:if></li>  
  </xsl:template>
  

<xsl:template match="respStmt">
  <li class="respStmt"><span class="label">Responsibility Statement: </span> <xsl:apply-templates select="resp"/> (<xsl:value-of select="persName"/>)</li>
</xsl:template>
  
  <xsl:template match="revisionDesc//change">
    <li class="respStmt"><span class="label">Change: </span> <xsl:if test="@when"><span class="date"><xsl:value-of select="@when"/> -- </span></xsl:if>
    <xsl:apply-templates/>
    </li>
  </xsl:template>
  
<xsl:template match="ref"><a href="{@target}"><xsl:apply-templates/></a></xsl:template>
  
 <xsl:template match="address"><xsl:for-each select="*">
   <xsl:value-of select="."/><xsl:if test="not(last())"><xsl:text>, </xsl:text></xsl:if>
 </xsl:for-each>
 </xsl:template>
  
  
  
  
  
  
<xsl:template match="msDesc">
  <div id="{@xml:id}"><xsl:if test="@xml:lang"><xsl:attribute name="lang"><xsl:value-of select="@xml:lang"/></xsl:attribute></xsl:if>
    <h2 class="msDesc-heading2"><xsl:value-of select="msIdentifier/idno[@type='shelfmark']"/></h2>
    <xsl:apply-templates/>
  </div>
</xsl:template>
  
  <xsl:template match="p"><p><xsl:apply-templates/></p></xsl:template>
  
  <xsl:template match="msDesc/msIdentifier|msDesc/head|msPart/head|msContents|physDesc|additional|msPart|msFrag">
    <div class="{name()}">
    <h3 class="msDesc-heading3"><xsl:choose>
      <xsl:when test="name()='msIdentifier'">Manuscript Identifier</xsl:when>
      <xsl:when test="name()='head'">Summary</xsl:when>
      <xsl:when test="name()='msContents'">Contents</xsl:when>
      <xsl:when test="name()='physDesc'">Physical Description</xsl:when>
      <xsl:when test="name()='additional'">Additional Metadata</xsl:when>
      <xsl:when test="name()='msPart'"><xsl:value-of select=".//idno[1]"/></xsl:when>
      <xsl:when test="name()='msFrag'"><xsl:value-of select=".//idno[1]"/></xsl:when>
    </xsl:choose></h3>
      <xsl:choose>
        <xsl:when test="name()='msIdentifier'"><ul class="msIdentifier"><xsl:apply-templates/></ul></xsl:when>
        <xsl:when test="name()='physDesc'"><ul class="physDesc"><xsl:apply-templates/></ul></xsl:when>
        <xsl:when test="name()='additional'"><ul class="additional"><xsl:apply-templates/></ul></xsl:when>
        <xsl:when test="name()='msPart' or name()='msFrag'"><ul class="{name()}"><xsl:apply-templates/></ul></xsl:when>
        <xsl:when test="name()='head'"><p class="msHead"><span class="label">Summary:</span> <xsl:apply-templates/></p></xsl:when>
        <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
      </xsl:choose>
    </div>
    </xsl:template>
  
  <!-- special case history -->
  <xsl:template match="history">
    <div class="{name()}">
      <h3 class="msDesc-heading3">History</h3>
      <xsl:if test="origin">
        <p class="origin"><span class="label">Origin: </span>
        <xsl:apply-templates select="origin"/>
      </p></xsl:if>
      
      <xsl:if test="provenance or acquisition">
        <p class="origin"><span class="label">Provenance and Acquisition: </span>
          <xsl:apply-templates select="provenance | acquisition"/>
        </p></xsl:if>
    </div>
  </xsl:template>
  
  <xsl:template match="origin/origDate">
    <xsl:if test="not(preceding-sibling::origDate)"><br/></xsl:if>
    <span class="{name()}"><xsl:apply-templates/></span>
  </xsl:template>
  
  <xsl:template match="origin/origPlace">
    <xsl:if test="not(preceding-sibling::origPlace)"><br/></xsl:if>
    <span class="{name()}"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="origin/p">
    <br/>
    <span class="origin-p"><xsl:apply-templates/></span>
  </xsl:template>
  
  <xsl:template match="msIdentifier"><ul class="msIdentifier"><xsl:apply-templates/></ul></xsl:template>
  
  <xsl:template match="msIdentifier/*">
    <li class="{name()}">
      <span class="label">
        <xsl:choose>
          <xsl:when test="name()='country'">Country: </xsl:when>
          <xsl:when test="name()='institution'">Institution: </xsl:when>
          <xsl:when test="name()='msName'">Manuscript Name: </xsl:when>
          <xsl:when test="name()='region'">Region: </xsl:when>
          <xsl:when test="name()='repository'">Repository: </xsl:when>
          <xsl:when test="name()='settlement'">Settlement: </xsl:when>
          <xsl:when test="name()='altIdentifier' or name()='idno'">
            <xsl:choose>
              <xsl:when test="idno/@type='shelfmark' or @type='shelfmark'">ShelfMark: </xsl:when>
              <xsl:when test="idno/@type='SCN' or @type='SCN'">Summary Catalogue no.: </xsl:when>
              <xsl:when test="@type='TM' or idno/@type='TM'">Trismegistos no.: </xsl:when>
              <xsl:when test="@type='PR'">Papyrological Reference: </xsl:when>
              <xsl:when test="@type='diktyon'">Diktyon no.: </xsl:when>
              <xsl:when test="@type='LDAB'">LDAB no.: </xsl:when>
              </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </span>
      <xsl:apply-templates/>
    </li>
    </xsl:template>
  
  <xsl:template match="altIdentifier/idno"><xsl:apply-templates/></xsl:template>
  <xsl:template match="msContents/summary">
    <p class="msSummary"><span class="label">Summary of Contents: </span><xsl:apply-templates/></p>
  </xsl:template>
  <xsl:template match="msContents/textLang">
    <p class="ContentsTextLang">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <xsl:template match="msContents/msItem" priority="10">
   <div class="msItem" id="{@xml:id}">
     <xsl:if test="@n"><span class="label"><xsl:value-of select="@n"/></span></xsl:if>
     <ul>
       <xsl:apply-templates/>
     </ul>
   </div> 
  </xsl:template>
  <xsl:template match="msItem/msItem">
    <li class="nestedmsItem" id="{@xml:id}">
      <xsl:if test="@n"><span class="label"><xsl:value-of select="@n"/></span></xsl:if>
      <ul class="nestedmsItemList">
        <xsl:apply-templates/>
      </ul>
    </li>
    
  </xsl:template>
  
  
  <xsl:template match="msItem/author | msItem/docAuthor"><li class="author"><xsl:apply-templates/><xsl:if test="following-sibling::title[1]"><xsl:text>, </xsl:text></xsl:if></li></xsl:template>
  <xsl:template match="msItem/editor"><li class="editor"><xsl:apply-templates/></li></xsl:template>
  <xsl:template match="msItem/bibl">
    <xsl:choose>
      <xsl:when test="@type='bible' or @type='commentedOn' or @type='commentary' or @type='related'"/>
      <xsl:otherwise>
        <li class="bibl"><xsl:apply-templates/><xsl:if test="following-sibling::title[1]"><xsl:text>, </xsl:text></xsl:if></li>  
      </xsl:otherwise>
     </xsl:choose>
  </xsl:template>
  <xsl:template match="msItem/title"><li class="title">
    <xsl:apply-templates/><xsl:if test="following-sibling::note[1][not(starts-with(., '('))][not(starts-with(., '[A-Z]'))][not(following-sibling::lb[1])]"><xsl:text>, </xsl:text></xsl:if>
  </li>
</xsl:template>
  
 <xsl:template match="msItem/note">
   <li class="{name()}"><span class="label">Note: </span><xsl:apply-templates/></li>
 </xsl:template> 
  
  <xsl:template match="msItem/quote">
    <li class="{name()}">"<xsl:apply-templates/>"</li>
  </xsl:template> 
  
  
  
 
<xsl:template match="msItem/incipit | msItem/explicit">
  <li class="{name()}"><span class="label">(<xsl:value-of select="name()"/>)</span> <xsl:if test="@defective='true'"><span class="defective">||</span></xsl:if><xsl:if test="@type"><span class="type">(<xsl:value-of select="@type"/>)</span></xsl:if><xsl:apply-templates/></li>
</xsl:template> 
 
 <xsl:template match="msItem/rubric">
   <li class="{name()}"><span class="label">(<xsl:value-of select="name()"/>)</span> <span><xsl:if test="not(@rend='roman')"><xsl:attribute name="class">italic</xsl:attribute></xsl:if><xsl:apply-templates/></span></li>   
 </xsl:template>
 
  <xsl:template match="msItem/finalRubric">
    <li class="{name()}"><span class="label">(final rubric)</span> <span><xsl:if test="not(@rend='roman')"><xsl:attribute name="class">italic</xsl:attribute></xsl:if><xsl:apply-templates/></span></li>   
  </xsl:template>
  
  <xsl:template match="msItem/colophon">
    <li class="{name()}"><span class="label">(colophon)</span> <span><xsl:if test="not(@rend='roman')"><xsl:attribute name="class">italic</xsl:attribute></xsl:if><xsl:apply-templates/></span></li>   
  </xsl:template>
  
  <xsl:template match="msItem/filiation">
    <li class="{name()}"><span class="label">(filiation)</span> <xsl:apply-templates/></li>   
  </xsl:template>
  
  <xsl:template match="msItem/textLang">
    <li class="{name()}"><xsl:apply-templates/></li>
  </xsl:template> 
  
  <xsl:template match="msItem/decoNote | msItem/decoDesc| msItem/filiation">
    <li class="{name()}"><xsl:apply-templates/></li>
  </xsl:template>
  
  <xsl:template match="msItem/locus">
    <li class="{name()}"><xsl:apply-templates/></li>
  </xsl:template>
  
  <!-- fallback for msItem children -->
  <xsl:template match="msItem/*" priority="-10">
    <li class="{name()}"><xsl:apply-templates/></li>
  </xsl:template>
  
  
  <!-- PhysDesc Children
   accMat additions bindingDesc decoDesc handDesc musicNotation objectDesc scriptDesc sealDesc typeDesc
  -->
  <xsl:template match="accMat">
    <li class="accMat"><span class="label">Accompanying Material: </span>
    <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  
  <xsl:template match="additions">
    <li class="accMat"><span class="label">Additions: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  
  <xsl:template match="bindingDesc">
    <li class="bindingDesc"><span class="label">Binding: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  
  <xsl:template match="decoDesc">
    <li class="descoDesc"><span class="label">Decoration: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  
  <xsl:template match="decoDesc/*|handDesc/*">
    <p class="{name()}"><xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <xsl:template match="handDesc">
    <li class="handDesc"><span class="label">Hand(s): </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  <xsl:template match="musicNotation">
    <li class="musicNotation"><span class="label">Musical Notation: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="typeDesc">
    <li class="typeDesc"><span class="label">Type(s): </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="sealDesc">
    <li class="sealDesc"><span class="label">Seal(s): </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="scriptDesc">
    <li class=""><span class="label">Script(s): </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <xsl:template match="objectDesc">
    <li class="objectDesc"><span class="label">Format: </span> <xsl:if test="@form"><span class="form"><xsl:value-of select="@form"/></span></xsl:if>
      <xsl:choose>
      <xsl:when test="p|ab"><xsl:apply-templates/></xsl:when>
        <xsl:otherwise><ul class="objectDesc"><xsl:apply-templates /></ul></xsl:otherwise>
      </xsl:choose>
    </li>
  </xsl:template>
  
  <xsl:template match="layoutDesc">
    <li class="layoutDesc"><span class="label">Layout: </span>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  
  <xsl:template match="layoutDesc/*">
    <p class="{name()}">
      <xsl:if test="@columns"><span class="label">Columns: </span> <span class="columns"><xsl:value-of select="@columns"/></span><br/></xsl:if>
      <xsl:if test="@ruledLine"><span class="label">Ruled Lines: </span> <span class="ruledLines"><xsl:value-of select="@ruledLines"/></span><br/></xsl:if>
      <xsl:if test="@writtenLines"><span class="label">Written Lines: </span> <span class="writtenLines"><xsl:value-of select="@writtenLines"/></span><br/></xsl:if>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  
  
  <xsl:template match="supportDesc">
    <li class="supperDesc"><span class="label">Support: </span>
      <xsl:if test="@material"><span class="label">Material: </span> <span class="material"><xsl:value-of select="@material"/></span><br/></xsl:if>
      <xsl:apply-templates/>
    </li>
  </xsl:template>
  <!--  collation condition foliation support -->
  <xsl:template match="collation">
    <p class="{name()}"><span class="label">Collation: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <xsl:template match="condition">
    <p class="{name()}"><span class="label">Condition: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <xsl:template match="foliation">
    <p class="{name()}"><span class="label">Foliation: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  
  <xsl:template match="support">
    <p class="{name()}"><span class="label">Material Support: </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

<xsl:template match="secFol">
  <span class="label">Secundo Folio: </span>
  <span class="{name()}"><xsl:apply-templates/></span><br/>
</xsl:template>

  <xsl:template match="extent">
    <span class="label">Extent: </span>
    <span class="{name()}"><xsl:apply-templates/></span><br/>
  </xsl:template>
  
  <xsl:template match="dimensions">
    <span class="label">Dimensions<xsl:if test="@type"> (<xsl:value-of select="@type"/>)</xsl:if>: </span>
    <span class="{name()}">
      <xsl:choose>
        <xsl:when test="height and width">
          <span class="height"><xsl:value-of select="height"/></span><span class="x"> × </span><span class="width"><xsl:value-of select="width"/></span>
          <xsl:choose>
            <xsl:when test="@unit"><span class="unit"><xsl:value-of select="@unit"/>.</span></xsl:when>
            <xsl:when test="height/@unit"><span class="unit"><xsl:value-of select="height/@unit"/>.</span></xsl:when>
            <xsl:when test="width/@unit"><span class="unit"><xsl:value-of select="width/@unit"/>.</span></xsl:when>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
      </span><br/>
  </xsl:template>
  <xsl:template match="formula"><span class="formula"><xsl:apply-templates/></span></xsl:template>
  
  <xsl:template match="catchwords | signatures">
  <span class="{name()}"><xsl:apply-templates/></span>    
  </xsl:template>
  <xsl:template match="watermark">
    <span class="{name()}">
      <span class="label">Watermark: </span>
      <xsl:apply-templates/></span>    
  </xsl:template>
  
  
  
  
  <xsl:template match="hi">
    <span><xsl:attribute name="class">hi <xsl:value-of select="rend"/></xsl:attribute>
    <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  <xsl:template match="supplied">
    <span class="supplied">&lt;<xsl:apply-templates/>&gt;</span>
  </xsl:template>
  
<xsl:template match="choice">
  <xsl:choose>
    <xsl:when test="sic and corr">
      <span class="sicAndCorr"><xsl:apply-templates select="sic"/> [<span class="italic">sic for</span> <xsl:apply-templates select="corr"/>]</span>
    </xsl:when>
    <xsl:when test="sic and not(corr)">
      <span class="sicAndNotCorr"><xsl:apply-templates select="sic"/> [<span class="italic">sic</span>]</span>
    </xsl:when>
  </xsl:choose>
</xsl:template>  
  
  <xsl:template match="unclear">
    <span class="unclear"><xsl:apply-templates/> <span class="unclearMarker"> (?)</span></span>
  </xsl:template>

<xsl:template match="gap">
  <xsl:choose>
    <xsl:when test="not(@*)"><span class="gap">…</span></xsl:when>
    <xsl:when test="@unit='chars' and number(@quantity)">
      <xsl:variable name="possibleDots">.....................................................................................................................</xsl:variable>
      <span class="gap"><xsl:value-of select="substring($possibleDots, 1, number(@quantity))"/></span>
    </xsl:when>
    <xsl:when test="@unit='chars' and number(@extent)">
      <xsl:variable name="possibleDots">.....................................................................................................................</xsl:variable>
      <span class="gap"><xsl:value-of select="substring($possibleDots, 1, number(@extent))"/></span>
    </xsl:when>
    <xsl:otherwise><span class="gap">…</span></xsl:otherwise>
  </xsl:choose>
 </xsl:template>
  
  <xsl:template match="expan | ex"><span class="expan">(<xsl:apply-templates/>)</span></xsl:template>
                  
                  
                  <!-- Additional section, inside a nested UL -->
  
  
</xsl:stylesheet>
