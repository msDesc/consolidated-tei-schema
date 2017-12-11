<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                xmlns:jc="http://james.blushingbunny.net/ns.html"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:bdlss="http://www.bodleian.ox.ac.uk/bdlss"
                exclude-result-prefixes="tei jc html xs bdlss" version="2.0">
    <!--
        Created by Dr James Cummings james@blushingbunny.net
        2017-05 for output of Bodley TEI msDescs as HTML to
        be sucked into the frontend platform.
    -->
    
    <xsl:param name="collections-path" as="xs:string" select="''"/>
    <xsl:param name="files" select="'*.xml'"/>
    <xsl:param name="recurse" select="'yes'"/>
    <xsl:param name="verbose" as="xs:boolean" select="false()"/>
    
    <xsl:variable name="website-url" as="xs:string" select="''"/>    <!-- This will be overriden by stylesheets that call this one -->
    <xsl:variable name="output-full-html" as="xs:boolean" select="true()"/>
    
    <xsl:output omit-xml-declaration="yes" method="xhtml" encoding="UTF-8" indent="yes"/>

    <!-- In case there are existing schema associations, let's get rid of those -->
    <xsl:template match="processing-instruction()"/>
    
    <xsl:function name="bdlss:logging">
        <xsl:param name="level" as="xs:string"/>
        <xsl:param name="msg" as="xs:string"/>
        <xsl:param name="context" as="element()"/>
        <xsl:param name="vals"/>
        <xsl:message select="concat(upper-case($level), '    ', $msg, '    ', ($context/ancestor-or-self::*/@xml:id)[position()=last()], '    ', string-join($vals, '    '))"/>        
    </xsl:function>
    
    <!-- Named template that is called from command line to batch convert all manuscript TEI files to HTML -->
    <xsl:template name="batch">
        
        <!-- Set up the collection of files to be converted. The path must be supplied in batch mode, and must be a full
             path because this stylesheet is normally imported by convert2HTML.xsl via a URL. -->
        <xsl:variable name="path">
            <xsl:choose>
                <xsl:when test="starts-with($collections-path, '/')">
                    <!-- UNIX-like systems -->
                    <xsl:value-of select="concat('file://', $collections-path, '/?select=', $files, ';on-error=warning;recurse=', $recurse)"/>
                </xsl:when>
                <xsl:when test="matches($collections-path, '[A-Z]:/')">
                    <!-- Git Bash on Windows -->
                    <xsl:value-of select="concat('file:///', $collections-path, '/?select=', $files, ';on-error=warning;recurse=', $recurse)"/>
                </xsl:when>
                <xsl:when test="matches($collections-path, '[A-Z]:\\')">
                    <!-- Windows -->
                    <xsl:value-of select="concat('file:///', replace($collections-path, '\\', '/'), '/?select=', $files, ';on-error=warning;recurse=', $recurse)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>A full path to the collections folder containing source TEI must be specified when batch converting.</xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- For each item in the collection -->
        <xsl:for-each select="collection($path)">

            <!-- Might as well sort them by current file name -->
            <xsl:sort select="tokenize(base-uri(), '/')[last()-1]"/>
            <xsl:sort select="tokenize(base-uri(), '/')[last()]"/>

            <!-- Get the baseURI -->
            <xsl:variable name="baseURI">
                <xsl:value-of select="base-uri()"/>
            </xsl:variable>

            <!-- Get the file name from that -->
            <xsl:variable name="filename">
                <xsl:value-of select="tokenize($baseURI, '/')[last()]"/>
            </xsl:variable>

            <!-- get the folder from that -->
            <xsl:variable name="folder">
                <xsl:value-of select="tokenize($baseURI, '/')[last()-1]"/>
            </xsl:variable>

            <!-- Get the @xml:id from the first msDesc inside the sourceDesc
              (won't work if msDesc elsewhere but stops problem with nested msDesc)
            -->
            <xsl:variable name="msID">
                <xsl:value-of select="//sourceDesc/msDesc[1]/@xml:id"/>
            </xsl:variable>

            <xsl:if test="$verbose">
                <!-- This is just a debugging message so I see the msIDs whiz by on the screen in case of any errors -->
                <xsl:message>
                    <!--
                        Folder: <xsl:value-of select="$folder"/>
                        Old Filename:<xsl:value-of select="$filename"/>
                    -->
                    <xsl:value-of select="$msID"/>
                </xsl:message>
            </xsl:if>

            <!-- Create the output file name hard coded to my dev machine-->
            <xsl:variable name="outputFilename" select="concat('./html/', $folder, '/', $msID, '.html')"/>

            <!-- create output file -->
            <xsl:result-document href="{$outputFilename}" method="xhtml" encoding="UTF-8" indent="yes">
                <xsl:choose>
                    <xsl:when test="$output-full-html">
                        <html xmlns="http://www.w3.org/1999/xhtml">
                            <head>
                                <title></title>
                            </head>
                            <body>
                                <div class="content tei-body" id="{//TEI/@xml:id}">
                                    <xsl:apply-templates select="//msDesc"/>
                                </div>
                            </body>
                        </html>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Create content div with the id of the manuscript. Wrap it in an extra root div so that
                             we can ignore the namespace attribute that XSLT puts on it automatically. -->
                        <div>
                            <div class="content tei-body" id="{//TEI/@xml:id}">
                                <xsl:apply-templates select="//msDesc"/>
                            </div>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:result-document>
        </xsl:for-each>
    </xsl:template>

    <!-- Templates for titleStmt titles and normal titles, author, editors, and related content -->
    <xsl:template match="titleStmt/title">
        <li class="title">
            <span class="tei-label">Title:</span>
            <xsl:apply-templates/>
            <xsl:if test="@type">(<xsl:value-of select="@type"/>)
            </xsl:if>
        </li>
    </xsl:template>

    <!-- new: default title should be in italic -->
    <xsl:template match="title">
        <span class="{name()} italic">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- <xsl:template match="author|editor">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template> -->

    <xsl:template match="series">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="citedRange">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- transcription related stuff like corr/date/add/dell/note/foreign/sic -->
    <xsl:template match="corr">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="date">
        <span class="{name()}">
            <xsl:if test="@when">
                <xsl:attribute name="title">
                    <xsl:value-of select="@when"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="add|del">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="note">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="foreign">
        <!-- modified to add @rend to the class -->
        <span class="{name()} {@rend}">
            <xsl:if test="@xml:lang">
                <xsl:attribute name="title">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="sic">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="supplied">
        <span class="supplied">[<xsl:apply-templates/>]</span>
    </xsl:template>
    
    <xsl:template match="choice[sic and corr]">
        <span class="sicAndCorr">
            <xsl:apply-templates select="sic"/>
            [
            <span class="italic">sic for</span>
            <xsl:apply-templates select="corr"/>]
        </span>
    </xsl:template>
    
    <xsl:template match="choice[sic and not(corr)]">
        <span class="sicAndNotCorr">
            <xsl:apply-templates select="sic"/>
            [<span class="italic">sic</span>]
        </span>
    </xsl:template>
    
    <xsl:template match="choice[abbr and expan]">
        <span class="expan" title="{abbr}">
            <xsl:apply-templates select="expan"/>
        </span>
    </xsl:template>

    <xsl:template match="abbr">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="unclear">
        <span class="unclear">
            <xsl:apply-templates/>
            <span class="unclearMarker">(?)</span>
        </span>
    </xsl:template>

    <xsl:template match="gap">
        <span class="gap">…</span>
    </xsl:template>
    
    <xsl:template match="gap[@unit='chars' and number(@quantity)]">
        <xsl:variable name="possibleDots">
            .....................................................................................................................
        </xsl:variable>
        <span class="gap">
            <xsl:value-of select="substring(normalize-space($possibleDots), 1, number(@quantity))"/>
        </span>
    </xsl:template>
    
    <xsl:template match="gap[@unit='chars' and number(@extent)]">
        <xsl:variable name="possibleDots">
            .....................................................................................................................
        </xsl:variable>
        <span class="gap">
            <xsl:value-of select="substring(normalize-space($possibleDots), 1, number(@extent))"/>
        </span>
    </xsl:template>
    

    <xsl:template match="expan | ex">
        <!-- was: class = expan, changed 6.11.17 to better match TEI guidelines. ex=parts of words. -->
        <span class="ex">(<xsl:apply-templates/>)
        </span>
    </xsl:template>

    <!-- editions -->
    <xsl:template match="editionStmt/edition">
        <li class="title">
            <span class="tei-label">Edition: </span>
            <xsl:apply-templates/>
            <xsl:if test="@type">(<xsl:value-of select="@type"/>)
            </xsl:if>
        </li>
    </xsl:template>

    <!-- responsibility and revisions -->
    <xsl:template match="respStmt">
        <li class="respStmt">
            <xsl:apply-templates select="resp"/>
            <xsl:if test="persName">(<xsl:value-of select="persName"/>)
            </xsl:if>
        </li>
    </xsl:template>

    <xsl:template match="resp">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="revisionDesc">
        <li class="revisionDesc">
            <ul class="revisionDesc">
                <xsl:apply-templates/>
            </ul>
        </li>
    </xsl:template>

    <xsl:template match="revisionDesc//change">
        <li class="change">
            <span class="tei-label">Change: </span>
            <xsl:if test="@when">
                <span class="date">
                    <xsl:value-of select="@when"/> --
                </span>
            </xsl:if>
            <xsl:apply-templates/>
        </li>
    </xsl:template>

    <!-- Refs, with targets and without -->
    <xsl:template match="ref[@target]" priority="10">
        <a href="{@target}">
            <xsl:apply-templates/>
        </a>
    </xsl:template>

    <xsl:template match="ref" priority="5">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- addresses, dealt with as requested. -->
    <xsl:template match="address">
        <xsl:for-each select="*">
            <xsl:value-of select="."/>
            <xsl:if test="not(last())">
                <xsl:text>, </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- lb to br -->
    <xsl:template match="lb">
        <br/>
    </xsl:template>

    <!-- Main msDesc template and processing starts here -->
    <xsl:template match="msDesc[@xml:id]">
        <div class="msDesc" id="{concat(@xml:id, '-msDesc', count(preceding::msDesc) + 1)}">
            <xsl:if test="@xml:lang">
                <xsl:attribute name="lang">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:attribute>
            </xsl:if>

            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- Just a warning template if an msDesc doesn't have an @xml:id -->
    <xsl:template match="msDesc">
        <xsl:message>No xml:id attribute in <xsl:value-of select="//TEI/@xml:id"/> for <xsl:value-of select="msIdentifier/idno[1]"/></xsl:message>

        <div class="msDesc">
            <xsl:if test="@xml:lang">
                <xsl:attribute name="lang">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:attribute>
            </xsl:if>

            <h2 class="msDesc-heading2">
                <xsl:value-of select="msIdentifier/idno[@type='shelfmark']"/>
            </h2>

            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- skip output of msIdentifier block with subtype for now - AH -->
    <!-- was: <xsl:template match="msIdentifier/altIdentifier/idno/@subtype" /> 23.10 -->
    <xsl:template match="msIdentifier[not(parent::msPart)]/altIdentifier/idno[@subtype]" />
    <xsl:template match="msIdentifier/institution | msIdentifier/region | msIdentifier/country | msIdentifier/settlement | msIdentifier/repository | msIdentifier/idno[@type='shelfmark']" />


    <!-- altidentifier/idno is all we want from this section, and not if subtype="alt" -->
    <!-- altidentifier with subtype alt should not be matched, otherwise we get an empty div which interferes with display [e.g. http://medieval-qa.bodleian.ox.ac.uk/catalog/manuscript_4968] -->
    <xsl:template match="msDesc/msIdentifier/altIdentifier[child::idno[not(@subtype)]]">
        <div class="msIdentifier">
            <xsl:choose>
                <!--<xsl:when test="idno/@type='shelfmark' or @type='shelfmark'">ShelfMark:</xsl:when>-->
                <!-- spaces after ':' added 26.6 -->
                <xsl:when test="idno[not(@subtype)]/@type='SCN'">Summary Catalogue no.: <xsl:apply-templates/></xsl:when>
                <xsl:when test="idno[not(@subtype)]/@type='TM' or idno/@type='TM'">Trismegistos no.: <xsl:apply-templates/></xsl:when>
                <xsl:when test="idno[not(@subtype)]/@type='PR'">Papyrological Reference: <xsl:apply-templates/></xsl:when>
                <xsl:when test="idno[not(@subtype)]/@type='diktyon'">Diktyon no.: <xsl:apply-templates/></xsl:when>
                <xsl:when test="idno[not(@subtype)]/@type='LDAB'">LDAB no.: <xsl:apply-templates/></xsl:when>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- Paragraphs -->
    <xsl:template match="p">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <!-- Default rule for head see msPart head below.-->
    <xsl:template match="head">
        <h4 class="{name()}">
            <xsl:apply-templates/>
        </h4>
    </xsl:template>
    
    <!-- Override to style main and part heads differently -->
    <xsl:template match="msDesc/head|msPart/head">
        <h4 class="msHead">
            <xsl:apply-templates/>
        </h4>
    </xsl:template>
    
    <xsl:template match="msContents">
        <h3>Contents</h3>
        <div class="{name()}">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="physDesc">
        <h3>Physical Description</h3>
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="additional">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="msPart|msFrag">
        <div class="{name()}">
            <h2>
                <xsl:apply-templates select="msIdentifier/altIdentifier"/>
            </h2>
            <xsl:apply-templates select="*[not(self::msIdentifier)]"/>
        </div>
    </xsl:template>
    
    <xsl:template match="msPart/msIdentifier/altIdentifier | msFrag/msIdentifier/altIdentifier">
        <xsl:apply-templates select="idno"/>
        <xsl:apply-templates select="note"/>
    </xsl:template>
    
    <xsl:template match="msPart/msIdentifier/altIdentifier/idno | msFrag/msIdentifier/altIdentifier/idno">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="msPart/msIdentifier/altIdentifier/note | msFrag/msIdentifier/altIdentifier/note">
        <xsl:choose>
            <xsl:when test="matches(text()[1], '^\s*\(')">
                <xsl:text> </xsl:text>
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text> (</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>)</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- special case history -->
    <xsl:template match="history">
        <h3 class="msDesc-heading3">History</h3>
        <!-- if Origin make it a paragraph -->
        <div class="{name()}">
            <xsl:if test="origin">
                <div class="origin">
                    <span class="tei-label">Origin: </span>
                    <xsl:apply-templates select="origin"/>
                </div>
            </xsl:if>
            <xsl:if test="provenance or acquisition">
                <div class="provenance">
                    <h4>Provenance and Acquisition</h4>
                    <xsl:apply-templates select="provenance | acquisition"/>
                </div>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- inside history -->
    
    <xsl:template match="origin">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="origin/origDate">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="origin/origPlace">
        <!-- modified: added logic for separator before or after depending on other elements -->
        <xsl:if test="preceding-sibling::origDate">
            <xsl:text>; </xsl:text>
        </xsl:if>
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
        <xsl:if test="following-sibling::origDate">
            <xsl:text>; </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="origin/p|provenance/p|acquisition/p">
        <!-- modified. want to keep it as a paragraph -->
        <p class="{concat(name(), '-p')}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="provenance|acquisition">
        <!-- modified. p not span -->
        <p class="{name()}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="origPlace">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- quotations - should I be putting in quotation marks? -->
    <xsl:template match="q">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- msIdentifier -->
    <xsl:template match="msIdentifier">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Things in msContents -->
    <xsl:template match="msContents/summary">
        <!-- h instead of p -->
        <h4 class="msSummary">
            <!-- label unnecessary -->
            <!--<span class="tei-label">Summary of Contents:</span>-->
            <xsl:apply-templates/>
        </h4>
    </xsl:template>

    <xsl:template match="msContents/summary/p">
        <span class="summary-p">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="msContents/textLang">
        <p class="ContentsTextLang">
            <!-- this on the other hand does need a label, if it is to appear at all -->
            <span class="tei-label">Language(s): </span>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <!-- msItem -->
    <!-- <xsl:template match="msContents/msItem" priority="10">
         <div class="msItem" id="{@xml:id}">
             <hr />
             <!-\- add -\-><xsl:apply-templates select="locus"/>
             <h4 class="tei-title">
                 <!-\- add -\-><xsl:apply-templates select="author"/>
                 <xsl:choose>
                     <xsl:when test="title">
                         <!-\- modify -\-><xsl:apply-templates select="title[1]"/>
                         <!-\-<xsl:value-of select="normalize-space(title[1])"/>-\->
                     </xsl:when>
                     <xsl:otherwise>
                         <!-\- this creates duplication with later <note>. need to change? -\->
                         [<xsl:value-of select="normalize-space(string-join(note/string(), ' '))"/>]
                     </xsl:otherwise>
                 </xsl:choose>
             </h4>
             <div>
                 <xsl:apply-templates select="* except (locus, author, title[1])"/>
             </div>
         </div>
     </xsl:template>
     -->

    <!-- what happens if we just apply templates? -->
    <xsl:template match="msContents/msItem" priority="10">
        <div class="msItem">
            <xsl:if test="@xml:id">
                <xsl:attribute name="id" select="@xml:id"/>
            </xsl:if>
            <xsl:if test="string-length(@n) gt 0 and count(parent::msContents/msItem[@n]) gt 1 and not(child::*[1][self::locus])">
                <!-- Display optional numbering on msItems, on its own line (except when the first-child is a locus, then it'll be inline) -->
                <div class="item-number">
                    <xsl:value-of select="@n"/>
                    <xsl:text>. </xsl:text>
                </div>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- nested msItem -->
    <!-- check what happens with multiple levels of nesting? -->
    <!-- modified to match main treatment of msItem above-->
    <xsl:template match="msItem/msItem">
        <div class="nestedmsItem">
            <xsl:if test="@xml:id">
                <xsl:attribute name="id" select="@xml:id"/>
            </xsl:if>
            <xsl:if test="string-length(@n) gt 0 and count(parent::msItem/msItem[@n]) gt 1 and not(child::*[1][self::locus])">
                <!-- Display optional numbering on msItems, on its own line (except when the first-child is a locus, then it'll be inline) -->
                <div class="item-number">
                    <xsl:value-of select="@n"/>
                    <xsl:text>. </xsl:text>
                </div>
            </xsl:if>
            <!--<hr />
            <xsl:apply-templates select="locus"></xsl:apply-templates>
            <!-\- changed from h3. this level needs to be smaller than the preceding level -\->
            <h5 class="tei-title">
                <xsl:apply-templates select="author"/>
                <xsl:apply-templates select="title[1]"/>
                <xsl:apply-templates select="note[1][starts-with(., '(') and preceding-sibling::title]"/>
            </h5>
            <div class="msItemList">
                <xsl:apply-templates select="* except (locus, author, title[1], note[1][starts-with(., '(') and preceding-sibling::title])"/>
            </div>-->
            <!-- again let's try just applying templates -->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- things in msItem -->
    <!-- don't do anything with an msItem title -->
    <!-- need to apply templates, sometimes titles contain names for example or formatting  -->
    <!-- standard titles should be in italic -->
    <xsl:template match="msItem/title[not(@rend) and not(@type)]">
        <span class="tei-title italic">
            <xsl:apply-templates/>
        </span>
        <!--<xsl:if test="following-sibling::note[1][not(starts-with(., '('))][not(starts-with(., '[A-Z]'))][not(following-sibling::lb[1])]">-->
            <!--<xsl:text>, </xsl:text>-->
        <!--</xsl:if>-->
    </xsl:template>
    
    <!-- others should be roman -->
    <xsl:template match="msItem/title[@rend or @type]">
        <span class="tei-title">
            <xsl:apply-templates/>
        </span>
        <xsl:if test="following-sibling::*[1][self::note 
                                                    and not(matches(., '^\s*[A-Z(,]')) 
                                                    and not(child::*[1][self::lb and string-length(normalize-space(preceding-sibling::text())) = 0])]
            ">
            <!-- Insert a comma only if the title is immediately followed by a note, which isn't in paratheses, 
                 doesn't start with an uppercase letter or comma, and there is no line-break element. -->
            <!-- TODO: Move this to the template(s) for notes? -->
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

    <!--<xsl:template match="msItem/author | msItem/docAuthor">-->
        <!--<span class="author">-->
            <!--<xsl:apply-templates /><xsl:if test="following-sibling::*[1]/name()='author'"><xsl:text>; </xsl:text></xsl:if><xsl:if test="following-sibling::*[1]/name()='title'"><xsl:text>. </xsl:text></xsl:if>-->
            <!--&lt;!&ndash;<xsl:choose>&ndash;&gt;-->
                <!--<xsl:when test="@key">-->
                    <!--<a href="/catalog/{@key}">-->
                        <!--&lt;!&ndash; modified &ndash;&gt;-->
                        <!--<xsl:apply-templates /><xsl:if test="following-sibling::*[1]/name()='author'"><xsl:text>; </xsl:text></xsl:if><xsl:if test="following-sibling::*[1]/name()='title'"><xsl:text>. </xsl:text></xsl:if>-->
                        <!--&lt;!&ndash;<xsl:value-of select="normalize-space(string-join(text(), ', '))"/>&ndash;&gt;-->
                    <!--</a>-->
                <!--</xsl:when>-->
                <!--<xsl:otherwise>-->
                    <!--&lt;!&ndash; modified &ndash;&gt;-->
                    <!--<xsl:apply-templates /><xsl:if test="following-sibling::*[1]/name()='author'"><xsl:text>; </xsl:text></xsl:if><xsl:if test="following-sibling::*[1]/name()='title'"><xsl:text>. </xsl:text></xsl:if>-->
                    <!--&lt;!&ndash;<xsl:value-of select="normalize-space(string-join(text(), ', '))"/>&ndash;&gt;-->
                <!--</xsl:otherwise>-->
            <!--</xsl:choose>-->
        <!--</span>-->
    <!--</xsl:template>-->
    
    <xsl:template match="msItem/editor">
        <span class="editor">
            <xsl:value-of select="normalize-space(string-join(text(), ' (editor)'))"/>
        </span>
    </xsl:template>
    
    <xsl:template match="msItem//bibl | physDesc//bibl | history//bibl">
        <xsl:if test="not(@type='bible' or @type='commentedOn' or @type='commentary' or @type='related')">
            <span class="bibl">
                <xsl:apply-templates/>
                <xsl:if test="following-sibling::title[1]">
                    <xsl:text>, </xsl:text>
                </xsl:if>
            </span>
        </xsl:if>
    </xsl:template>

    <!-- First note after title, if in brackets should be span not div to follow title.  -->
    <xsl:template match="msItem/note[starts-with(., '(')]"> <!-- TODO: Add another clause so this only triggers for first notes? -->
        <xsl:text> </xsl:text>
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="msItem/note[not(starts-with(., '('))]">
        <p class="{name()}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="msItem/quote">
        <blockquote class="{name()}">
            <xsl:text>"</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>"</xsl:text>
        </blockquote>
    </xsl:template>

    <xsl:template match="msItem/incipit">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:text>Incipit: </xsl:text>
            </span>
            <xsl:if test="@type">
                <span class="type">(<xsl:value-of select="@type"/>)</span>
            </xsl:if>
            <xsl:if test="@defective='true'">
                <span class="defective">||</span>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/explicit">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:text>Explicit: </xsl:text>
            </span>
            <xsl:if test="@type">
                <span class="type">(<xsl:value-of select="@type"/>)</span>
            </xsl:if>
            <xsl:apply-templates/>
            <xsl:if test="@defective='true'">
                <span class="defective">||</span>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="msItem/rubric">
        <div class="{name()}">
            <span class="tei-label">Rubric: </span>
            <!-- can we have this and the following <xsl:if> back? there is a difference inthe records between italic and not italic rubrics etc. -->
            <!--<xsl:if test="not(@rend='roman')">-->
            <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/finalRubric">
        <div class="{name()}">
            <span class="tei-label">Final rubric: </span>
            <!--<xsl:if test="not(@rend='roman')">-->
            <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/colophon">
        <div class="{name()}">
            <span class="tei-label">Colophon: </span>
            <!--<xsl:if test="not(@rend='roman')">-->
            <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/filiation">
        <div class="{name()}">
            <span class="tei-label">Filiation:</span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/textLang">
        <div class="{name()}">
            <span class="tei-label">Language(s): </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="msItem/locus">
        <div class="{name()}">
            <xsl:if test="parent::msItem[@n] and count(parent::msItem/parent::*/msItem[@n]) gt 1 and count(preceding-sibling::*) = 0">
                <!-- Display optional numbering on msItems, inline when the first-child is a locus (all other cases the number appears on its own line) -->
                <span class="item-number">
                    <xsl:value-of select="parent::msItem/@n"/>
                    <xsl:text>. </xsl:text>
                </span>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- fallback for msItem children -->
    <!-- <xsl:template match="msItem/*" priority="-10">
      <span class="{name()}">
        <xsl:apply-templates/>
      </span>
    </xsl:template> -->

    <!-- Things inside physDesc -->
    <xsl:template match="physDesc/p">
        <div class="physDesc-p">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="accMat">
        <div class="{name()}">
            <h4>Accompanying Material</h4>
            <p>
                <xsl:apply-templates/>
            </p>
        </div>
    </xsl:template>

    <xsl:template match="additions">
        <div class="additions">
            <span class="tei-label">Additions: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="bindingDesc">
        <div class="{name()}">
            <h4>Binding</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="binding">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="binding/p|collation/p|foliation/p">
        <p class="{concat(parent::node()/name(), '-p')}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="decoDesc">
        <div class="{name()}">
            <h4>Decoration</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="handDesc">
        <div class="handDesc">
            <h4>Hand(s)</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="decoDesc/*|handDesc/*">
        <p class="{name()}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="decoNote|handNote" priority="20">
        <p class="{name()}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="decoDesc/p|handDesc/p|decoNote/p|handNote/p" priority="10">
        <p class="{concat(parent::node()/name(), '-p')}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="decoNote//list|handNote//list|support//list" priority="10">
        <div class="{concat(parent::node()/name(), '-list')}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="decoNote/list/item|handNote/list/item|support//item" priority="10">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- where all the text inside a decoNote (e.g. not nested children) = ' Decoration' get rid of it -->
    <xsl:template match="decoNote/text()[normalize-space(.) = 'Decoration']"/>
    <xsl:template match="decoNote/list/head|decoNote/list/label|handNote/list/head|handnote/list/label" priority="10">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="musicNotation">
        <div class="musicNotation">
            <span class="tei-label">Musical Notation: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="typeDesc">
        <div class="typeDesc">
            <span class="tei-label">Type(s): </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="sealDesc">
        <span class="tei-label">Seal(s): </span>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="scriptDesc">
        <h4>Script(s)</h4>
        <div class="scriptDesc">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="objectDesc">
        <div class="objectDesc">
            <xsl:if test="@form">
                <div class="form">
                    <span class="tei-label">Form: </span>
                    <xsl:value-of select="@form"/>
                </div>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="layoutDesc">
        <div class="{name()}">
            <h4>Layout</h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="layoutDesc/layout">
            <!-- modified: do not display attribute values -->
            <!--<xsl:if test="@columns">
                <div class="layout-columns">
                    <span class="tei-label">Columns: </span>
                    <xsl:value-of select="@columns"/>
                </div>
            </xsl:if>
            <xsl:if test="@ruledLine">
                <div class="ruledLines">
                    <span class="tei-label">Ruled Lines: </span>
                    <xsl:value-of select="@ruledLines"/>
                </div>
            </xsl:if>
            <xsl:if test="@writtenLines">
                <div class="writtenLines">
                    <span class="tei-label">Written Lines: </span>
                    <xsl:value-of select="@writtenLines"/>
                </div>
            </xsl:if>-->
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="supportDesc">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- misc phrase-level elements used inside physDesc -->
    <xsl:template match="material">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="measure">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="num">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- Seals -->
    <xsl:template match="seal">
        <p class="{name()}">
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="seal/p">
        <span class="seal-p">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!--  collation condition foliation support -->
    <xsl:template match="collation">
        <div class="{name()}">
            <h4>Collation</h4>
            <div class="collation">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="condition">
        <div>
            <h4>Condition</h4>
            <div class="condition">
                <xsl:apply-templates/>
            </div>
        </div>

    </xsl:template>

    <xsl:template match="foliation">
        <div class="{name()}">
            <span class="tei-label">Foliation: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- this is handled with supportDesc@material - AH -->
    <xsl:template match="support">
        <div class="{name()}">
            <span class="tei-label">Support: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <!-- secFol, locus, extent -->
    <xsl:template match="secFol">
        <div class="{ name() }">
            <span class="tei-label italic">Secundo Folio: </span>
            <xsl:apply-templates/>
            <!-- would be useful to insert a space at end ? (due to there often being a following <locus>) -->
        </div>
    </xsl:template>

    <!-- locus outside of msitem should not be a div since it always appears in continuous text  -->
    <xsl:template match="locus">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="extent">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="extent[child::text()[1][matches(., '[a-z]')] or child::*[1][self::measure]]">
        <!-- TODO: Change to either of:
                <xsl:template match="extent[child::text()[1][matches(., '\w')] or child::*[1][self::measure]]">
                <xsl:template match="extent[(not(child::*) and matches(child::*[1]/preceding-sibling::text(), '\w')) or child::*[1][self::measure]]">
        -->
        <!-- Prefix with label if it begins with untagged text, or a measure child element -->
        <div class="{name()}">
            <span class="tei-label">Extent: </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="dimensions">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="extent/dimensions">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:text>Dimensions</xsl:text>
                <xsl:if test="@type">
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="@type"/>
                    <xsl:text>)</xsl:text>
                </xsl:if>
                <xsl:text>: </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="height[parent::dimensions/width]">
        <!-- When height and width are both specified, ensure height is first and units are added. -->
        <span class="height">
            <xsl:value-of select="."/>
        </span>
        <xsl:text>×</xsl:text>
        <span class="width">
            <xsl:value-of select="parent::dimensions/width"/>
        </span>
        <xsl:apply-templates select="(parent::dimensions//@unit)[1]"/>
    </xsl:template>
    
    <xsl:template match="width[parent::dimensions/height]"/>
    
    <xsl:template match="dimensions//@unit">
        <xsl:value-of select="concat(., '.')"/>
    </xsl:template>
    
    <xsl:template match="height|width">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <!-- formula, catchwords, signatures, watermarks  -->
    <xsl:template match="formula">
        <div class="formula">
            <!-- modified: label not wanted -->
            <!-- <span class="tei-label">Formula: </span>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="catchwords | signatures | watermark | listBibl">
        <!-- changed from div to span since the whole text of <collation> is usually written as a continuous paragraph -->
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <!-- TODO: listBibl shouldn't output spans in contexts that will output uls -->
    
    <!-- hi used for ad hoc formatting -->
    <xsl:template match="hi">
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="@rend"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="list/item[not(@facs)] | listBibl/bibl[not(@facs)]">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <!-- TODO: bibl templates should output li instead of div when inside additional to create valid HTML-->

    <xsl:template match="list/item[@facs] | listBibl/bibl[@facs]">
        <div class="{name()}">
            <xsl:variable name="facs-url" select="concat($website-url, '/images/ms/', substring(@facs, 1, 3), '/', @facs)" />
            <a href="{$facs-url}">
                <xsl:apply-templates/>
            </a>
        </div>
    </xsl:template>

    <!--<xsl:template match="note//bibl | p//bibl | title//bibl | physDesc//bibl">-->
        <!--<div class="{name()}">-->
            <!--<xsl:apply-templates/>-->
        <!--</div>-->
    <!--</xsl:template>-->

    <!-- Things inside additional -->
    <xsl:template match="additional/listBibl">
        <h3 class="msDesc-heading3">Bibliography</h3>
        <div class="listBibl">
            <ul class="listBibl">
                <xsl:apply-templates/>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="additional/surrogates">
        <h3 class="msDesc-heading3">Digital Images</h3>
        <div class="surrogates">
            <!--<xsl:choose>
                <xsl:when test="bibl/@facs">
                    <a href="{bibl/@facs}">
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <!-- new 6.11.17 -->
    <xsl:template match="surrogates//bibl/@*"/>

    <xsl:template match="additional/adminInfo">
        <div class="adminInfo">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="adminInfo/*">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="source">
        <h3>Record Sources</h3>
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="source/listBibl" priority="10">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- names and places -->
    <xsl:template match="persName | placeName | orgName | name | country | settlement | district | region | repository | idno">
        <!-- NOTE: This list may differ between TEI catalogues -->
        <span class="{name()}">
            <xsl:choose>
                <xsl:when test="@key">
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="$website-url"/>
                            <xsl:text>/catalog/</xsl:text>
                            <xsl:value-of select="@key"/>
                        </xsl:attribute>
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>

    <xsl:template match="author">
        <span class="{name()}">
            <xsl:choose>
                <xsl:when test="normalize-space(.)=''" />   <!-- TODO: Lookup author name defined earlier in the same TEI document?-->
                <xsl:when test="@key">
                    <a>
                        <xsl:attribute name="href">
                            <xsl:value-of select="$website-url"/>
                            <xsl:text>/catalog/</xsl:text>
                            <xsl:value-of select="@key"/>
                        </xsl:attribute>
                        <xsl:apply-templates/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
        <xsl:if test="following-sibling::*[1]/name()='author'">
            <xsl:text>; </xsl:text>
        </xsl:if>
        <xsl:if test="following-sibling::*[1]/name()='title'">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="heraldry | label | list/head | seg">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="label">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="list">
        <ul class="{name()}">
            <xsl:apply-templates/>
        </ul>
    </xsl:template>

    <!-- catch all fallback: this is there to warn me of elements I don't have templates for and should never fire otherwise-->
    <xsl:template match="*" priority="-100">
        <xsl:if test="$verbose">
            <xsl:message>No template for: <xsl:value-of select="name()"/></xsl:message>
        </xsl:if>
        <span class="{name()}">
            <xsl:apply-templates select="@*|node()"/>
        </span>
    </xsl:template>
    
</xsl:stylesheet>
