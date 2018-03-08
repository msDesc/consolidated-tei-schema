<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xpath-default-namespace="http://www.tei-c.org/ns/1.0"
                xmlns:jc="http://james.blushingbunny.net/ns.html"
                xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:bod="http://www.bodleian.ox.ac.uk/bdlss"
                exclude-result-prefixes="tei jc html xs bod" version="2.0">
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

    <!-- Strip out all processing instructions in the source XML -->
    <xsl:template match="processing-instruction()"/>




    <!-- Functions -->
    
    <xsl:function name="bod:logging" as="empty-sequence()">
        <xsl:param name="level" as="xs:string"/>
        <xsl:param name="msg" as="xs:string"/>
        <xsl:param name="context" as="element()"/>
        <xsl:param name="vals"/>
        <xsl:choose>
            <xsl:when test="lower-case($level) eq 'error'">
                <xsl:message terminate="yes" select="concat(upper-case($level), '&#9;', $msg, '&#9;', ($context/ancestor-or-self::*/@xml:id)[position()=last()], '    ', string-join($vals, '    '))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="concat(upper-case($level), '&#9;', $msg, '&#9;', ($context/ancestor-or-self::*/@xml:id)[position()=last()], '    ', string-join($vals, '    '))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="bod:logging" as="empty-sequence()">
        <xsl:param name="level" as="xs:string"/>
        <xsl:param name="msg" as="xs:string"/>
        <xsl:param name="context" as="element()"/>
        <xsl:choose>
            <xsl:when test="lower-case($level) eq 'error'">
                <xsl:message terminate="yes" select="concat(upper-case($level), '&#9;', $msg, '&#9;', ($context/ancestor-or-self::*/@xml:id)[position()=last()], '    ')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message select="concat(upper-case($level), '&#9;', $msg, '&#9;', ($context/ancestor-or-self::*/@xml:id)[position()=last()], '    ')"/>
            </xsl:otherwise>
        </xsl:choose>      
    </xsl:function>
    
    <xsl:function name="bod:languageCodeLookup" as="xs:string">
        <xsl:param name="lang" as="xs:string"/>
        <!-- TODO: Replace this with a lookup to an XML file -->
        <xsl:choose>
            <xsl:when test="$lang eq 'he'">Hebrew</xsl:when>
            <xsl:when test="$lang eq 'yi'">Yiddish</xsl:when>
            <xsl:when test="$lang eq 'arc'">Aramaic</xsl:when>
            <xsl:when test="$lang eq 'ka'">Georgian</xsl:when>
            <xsl:when test="$lang eq 'jrb'">Judeo-Arabic</xsl:when>
            <xsl:when test="$lang eq 'ar'">Arabic</xsl:when>
            <xsl:when test="$lang eq 'lad'">Ladino</xsl:when>
            <xsl:when test="$lang eq 'jpr'">Judeo-Persian</xsl:when>
            <xsl:when test="$lang eq 'jpt'">Judaeo-Portuguese</xsl:when>
            <xsl:when test="$lang eq 'grc'">Greek</xsl:when>
            <xsl:when test="$lang eq 'es'">Spanish</xsl:when>
            <xsl:when test="$lang eq 'la'">Latin</xsl:when>
            <xsl:when test="$lang eq 'lat'">Latin</xsl:when>
            <xsl:when test="$lang eq 'en'">English</xsl:when>
            <xsl:when test="$lang eq 'eng'">English</xsl:when>
            <xsl:when test="$lang eq 'zxx'">No Linguistic Content</xsl:when>
            <xsl:when test="$lang eq 'und'">Undetermined</xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$lang"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="bod:standardText">
        <xsl:param name="textval" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$textval = ('Physical Description', 'Contents', 'History', 'Record Sources', 'Language(s):', 'Support:', 'Origin:', 'Form:')">
                <xsl:processing-instruction name="ni"/>
                <xsl:value-of select="$textval"/>
                <xsl:processing-instruction name="ni"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$textval"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="bod:shortenToNearestWord" as="xs:string">
        <xsl:param name="stringval" as="xs:string"/>
        <xsl:param name="tolength" as="xs:integer"/>
        <xsl:variable name="cutoffat" as="xs:integer" select="$tolength - 1"/>
        <xsl:choose>
            <xsl:when test="string-length($stringval) le $tolength">
                <!-- Already short enough, so return unmodified -->
                <xsl:value-of select="$stringval"/>
            </xsl:when>
            <xsl:when test="substring($stringval, $cutoffat, 1) = (' ', '&#9;', '&#10;')">
                <!-- The cut-off is at the location of some whitespace, so won't be cutting off any words -->
                <xsl:value-of select="concat(normalize-space(substring($stringval, 1, $cutoffat)), '…')"/>
            </xsl:when>
            <xsl:when test="substring($stringval, $tolength, 1) = (' ', '&#9;', '&#10;')">
                <!-- The cut-off is at the end of a word, so won't be cutting off any words -->
                <xsl:value-of select="concat(substring($stringval, 1, $cutoffat), '…')"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- The cut-off is in the middle of a word, so return everything up to the preceding word -->
                <xsl:value-of select="concat(replace(substring($stringval, 1, $cutoffat), '\s\S*$', ''), '…')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>




    <!-- Named template which is called from command line 
         to batch convert all manuscript TEI files to HTML -->
    
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
                    <xsl:copy-of select="bod:logging('error', 'A full path to the collections folder containing source TEI must be specified', .)"/>
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
                <xsl:value-of select="tokenize($baseURI, '/')[last()-1][not(. eq 'collections')]"/>
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

            <xsl:variable name="outputFilename" select="concat('./html/', $folder, '/', $msID, '.html')"/>

            <!-- Build HTML in a variable so it can be post-processed to strip out undesirable HTML code -->
            <xsl:variable name="outputdoc" as="element()">
                <xsl:choose>
                    <xsl:when test="$output-full-html">
                        <html xmlns="http://www.w3.org/1999/xhtml">
                            <head>
                                <title></title>
                            </head>
                            <body>
                                <div class="content tei-body" id="{//TEI/@xml:id}">
                                    <xsl:call-template name="Header"/>
                                    <xsl:apply-templates select="/TEI/teiHeader/fileDesc/sourceDesc/msDesc"/>
                                    <xsl:call-template name="Footer"/>
                                </div>
                            </body>
                        </html>
                    </xsl:when>
                    <xsl:otherwise>
                        <div>
                            <div class="content tei-body" id="{//TEI/@xml:id}">
                                <xsl:call-template name="Header"/>
                                <xsl:apply-templates select="/TEI/teiHeader/fileDesc/sourceDesc/msDesc"/>
                                <xsl:call-template name="Footer"/>
                            </div>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- Create output HTML files -->
            <xsl:result-document href="{$outputFilename}" method="xhtml" encoding="UTF-8" indent="yes">
                
                <!-- Applying templates on the HTML already built, with a mode, to strip out undesirable HTML code -->
                <xsl:apply-templates select="$outputdoc" mode="stripoutempty"/>
                
            </xsl:result-document>
            
        </xsl:for-each>
    </xsl:template>




    <!-- These next templates act on HTML already generated from the source TEI, as a post-processing phase to strip out 
         empty elements. These can confuse web browsers (whose parsers assume that, for example, an empty div element
         was someone's handcoded mistake and ignores the closing div tag) causing display issues especially in IE/Edge -->
    
    <xsl:template match="*" mode="stripoutempty">
        <xsl:if test="child::* or text() or processing-instruction() or local-name() = ('img', 'br', 'hr', 'title')">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates mode="stripoutempty"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>
    <xsl:template match="text()|processing-instruction()|comment()" mode="stripoutempty"><xsl:copy/></xsl:template>



    <!-- These named templates are intentionally left empty. They can be overridden by 
         convert2HTML.xsl stylesheets to add a special footer for each catalogue. The
         hooks which call them are in other templates above and below in this stylesheet.-->
    
    <xsl:template name="Header"></xsl:template>
    <xsl:template name="Footer"></xsl:template>
    <xsl:template name="AdditionalContent"></xsl:template>




    <!-- Actual TEI-to-HTML templates below -->

    <xsl:template match="titleStmt/title">
        <li class="title">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Title:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:apply-templates/>
            <xsl:if test="@type">(<xsl:value-of select="@type"/>)
            </xsl:if>
        </li>
    </xsl:template>

    <xsl:template match="title">
        <span class="{name()} italic">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

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

    <xsl:template match="add">
        <ins class="{@place}">
            <xsl:choose>
                <xsl:when test="@place = 'above'">
                    <xsl:text>^</xsl:text>
                    <xsl:apply-templates/>
                    <xsl:text>^</xsl:text>
                </xsl:when>
                <xsl:when test="@place = 'margin'">
                    <xsl:text>\</xsl:text>
                    <xsl:apply-templates/>
                    <xsl:text>/</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>\</xsl:text>
                    <xsl:apply-templates/>
                    <xsl:text>/</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </ins>
    </xsl:template>
    
    <xsl:template match="del">
        <del>
            <xsl:apply-templates/>
        </del>
    </xsl:template>

    <xsl:template match="note">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="foreign">
        <xsl:text> </xsl:text>
        <span class="{name()} {@rend}">
            <xsl:if test="@xml:lang">
                <xsl:attribute name="title">
                    <xsl:value-of select="bod:languageCodeLookup(@xml:lang)"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </span>
        <xsl:text> </xsl:text>
    </xsl:template>

    <xsl:template match="sic[child::* or text()]">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="sic[not(child::* or text())]">
        <!-- For self-closing sic tags just output a "[sic]" marker -->
        <xsl:text>[</xsl:text>
        <span class="italic">
            <xsl:text>sic</xsl:text>
        </span>
        <xsl:text>]</xsl:text>
    </xsl:template>

    <xsl:template match="supplied">
        <span class="supplied">
            <xsl:text>⟨</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>⟩</xsl:text>
        </span>
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
        <!-- TODO: Split this into two templates for expan used in contexts where it is not inline? -->
        <span class="ex">(<xsl:apply-templates/>)</span>
    </xsl:template>

    <!-- editions -->
    <xsl:template match="editionStmt/edition">
        <li class="title">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Edition:')"/>
                <xsl:text> </xsl:text>
            </span>
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
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Change:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:if test="@when">
                <span class="date">
                    <xsl:value-of select="@when"/> --
                </span>
            </xsl:if>
            <xsl:apply-templates/>
        </li>
    </xsl:template>

    <xsl:template match="ref[@target]" priority="10">
        <xsl:variable name="target" as="xs:string" select="normalize-space(@target)"/>
        <xsl:choose>
            <xsl:when test="starts-with($target, '#')">
                <xsl:choose>
                    <xsl:when test="$target = (//@xml:id)">
                        <!-- Create internal link within the same page -->
                        <a href="{$target}">
                            <xsl:apply-templates/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Don't create links anything that looks like a reference to an old internal ID -->
                        <xsl:apply-templates/>
                        <xsl:copy-of select="bod:logging('warn', 'Skipping ref with invalid target', ., $target)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="string-length($target) le 3">
                <!-- Anything shorter than a few chars is very likely another old ID -->
                <xsl:apply-templates/>
                <xsl:copy-of select="bod:logging('warn', 'Skipping ref with invalid target', ., $target)"/>
            </xsl:when>
            <xsl:when test="starts-with($target, 'www')">
                <!-- Assume if the protocol is missing that it is http (hopefully if it is https the destiantion server will redirect) -->
                <a href="http://{$target}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:when test="starts-with($target, 'http') or starts-with($target, 'mailto') or starts-with($target, 'ftp')">
                <!-- For valid-looking URLs create links to external resources -->
                <a href="{$target}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:when test="contains(base-uri(.), 'hebrew-mss') or contains(base-uri(.), 'genizah-mss')">
                <!-- In Hebrew and Genizah, a lot of these look like classmarks, so convert them into links to search the catalogue -->
                <a href="/?q={translate($target, '_#', '  ')}">
                    <xsl:apply-templates/>
                    <xsl:copy-of select="bod:logging('warn', 'Converting ref with unrecognized target into a search', ., $target)"/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <!-- Probably either an old ID or a book reference -->
                <xsl:apply-templates/>
                <xsl:copy-of select="bod:logging('warn', 'Skipping ref with invalid target', ., $target)"/>
            </xsl:otherwise>
        </xsl:choose>
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
    <xsl:template match="msDesc">
        <xsl:variable name="id">
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="concat(@xml:id, '-msDesc', count(preceding::msDesc) + 1)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('tempid_', generate-id(.))"/>
                    <xsl:copy-of select="bod:logging('error', 'msDesc has no xml:id', .)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <div class="msDesc" id="{$id}">
            <xsl:if test="@xml:lang">
                <xsl:attribute name="lang">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="msIdentifier/collection or msIdentifier/altIdentifier[child::idno[not(@subtype)]]">
                <div class="msIdentifier">
                    <xsl:apply-templates select="msIdentifier"/>
                </div>
            </xsl:if>
            <xsl:apply-templates select="*[not(self::msIdentifier)]"/>
            <xsl:call-template name="AdditionalContent"/>
        </div>
    </xsl:template>

    <!-- Most of the fields in msIdentifier are not wanted for display -->
    <xsl:template match="msDesc/msIdentifier/idno"/>
    <xsl:template match="msIdentifier[not(parent::msPart)]/altIdentifier/idno[@subtype]" />
    <xsl:template match="msIdentifier/institution | msIdentifier/region | msIdentifier/country | msIdentifier/settlement | msIdentifier/repository | msIdentifier/idno[@type='shelfmark']" />
    <xsl:template match="msDesc/msIdentifier/altIdentifier[child::idno[@subtype]]"/>

    <xsl:template match="msIdentifier/collection">
        <p><xsl:apply-templates/></p>
    </xsl:template>

    <xsl:template match="msDesc/msIdentifier/altIdentifier[child::idno[not(@subtype)]]">
        <xsl:choose>
            <xsl:when test="idno[not(@subtype)]/@type='SCN'">
                <p>
                    <xsl:text>Summary Catalogue no.: </xsl:text>
                    <xsl:apply-templates/>
                </p>
            </xsl:when>
            <xsl:when test="idno[not(@subtype)]/@type='TM' or idno/@type='TM'">
                <p>
                    <xsl:text>Trismegistos no.: </xsl:text>
                    <xsl:apply-templates/>
                </p>
            </xsl:when>
            <xsl:when test="idno[not(@subtype)]/@type='PR'">
                <p>
                    <xsl:text>Papyrological Reference: </xsl:text>
                    <xsl:apply-templates/>
                </p>
            </xsl:when>
            <xsl:when test="idno[not(@subtype)]/@type='diktyon'">
                <p>
                    <xsl:text>Diktyon no.: </xsl:text>
                    <xsl:apply-templates/>
                </p>
            </xsl:when>
            <xsl:when test="idno[not(@subtype)]/@type='LDAB'">
                <p>
                    <xsl:text>LDAB no.: </xsl:text>
                    <xsl:apply-templates/>
                </p>
            </xsl:when>
        </xsl:choose>
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
        <h3>
            <xsl:copy-of select="bod:standardText('Contents')"/>
        </h3>
        <div class="{name()}">
            <xsl:apply-templates />
        </div>
    </xsl:template>
    
    <xsl:template match="physDesc">
        <h3>
            <xsl:copy-of select="bod:standardText('Physical Description')"/>
        </h3>
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
        <div class="{name()}" id="{(@xml:id, generate-id())[1]}">
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
        <h3 class="msDesc-heading3">
            <xsl:copy-of select="bod:standardText('History')"/>
        </h3>
        <!-- if Origin make it a paragraph -->
        <div class="{name()}">
            <xsl:if test="origin">
                <div class="origin">
                    <span class="tei-label">
                        <xsl:copy-of select="bod:standardText('Origin:')"/>
                        <xsl:text> </xsl:text>
                    </span>
                    <xsl:apply-templates select="origin"/>
                </div>
            </xsl:if>
            <xsl:if test="provenance or acquisition">
                <div class="provenance">
                    <h4>
                        <xsl:copy-of select="bod:standardText('Provenance and Acquisition')"/>
                    </h4>
                    <xsl:apply-templates select="provenance | acquisition"/>
                </div>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- inside history -->
    
    <xsl:template match="origin">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="origin//origDate">
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
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Language(s):')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:choose>
                <xsl:when test="not(.//text()) and (@mainLang or @otherLangs)">
                    <xsl:for-each select="tokenize(string-join((@mainLang, @otherLangs), ' '), ' ')">
                        <xsl:value-of select="bod:languageCodeLookup(.)"/>
                        <xsl:if test="position() ne last()"><xsl:text>, </xsl:text></xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>

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
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/title[not(@rend) and not(@type)]">
        <span class="tei-title italic">
            <xsl:apply-templates/>
        </span>
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
    
    <xsl:template match="editor">
        <xsl:variable name="rolelabel" select="(@role, 'editor')[1]"/>
        <span class="editor{ if ($rolelabel ne 'editor') then concat(' ', $rolelabel) else ''}">
            <xsl:apply-templates/>
            <xsl:value-of select="concat(' (', $rolelabel, ')')"/>
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
    
    <xsl:template match="quote">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="msItem/incipit">
        <xsl:if test=".//text()">
            <div class="{name()}">
                <span class="tei-label">
                    <xsl:copy-of select="bod:standardText('Incipit:')"/>
                    <xsl:text> </xsl:text>
                </span>
                <xsl:if test="@type">
                    <span class="type">(<xsl:value-of select="@type"/>)</span>
                </xsl:if>
                <xsl:if test="@defective='true'">
                    <span class="defective">||</span>
                </xsl:if>
                <xsl:apply-templates/>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template match="msItem/explicit">
        <xsl:if test=".//text()">
            <div class="{name()}">
                <span class="tei-label">
                    <xsl:copy-of select="bod:standardText('Explicit:')"/>
                    <xsl:text> </xsl:text>
                </span>
                <xsl:if test="@type">
                    <span class="type">(<xsl:value-of select="@type"/>)</span>
                </xsl:if>
                <xsl:apply-templates/>
                <xsl:if test="@defective='true'">
                    <span class="defective">||</span>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>

    <xsl:template match="msItem/rubric">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Rubric:')"/>
                <xsl:text> </xsl:text>
            </span>
            <!-- can we have this and the following <xsl:if> back? there is a difference inthe records between italic and not italic rubrics etc. -->
            <!--<xsl:if test="not(@rend='roman')">-->
            <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/finalRubric">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Final rubric:')"/>
                <xsl:text> </xsl:text>
            </span>
            <!--<xsl:if test="not(@rend='roman')">-->
            <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/colophon">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Colophon:')"/>
                <xsl:text> </xsl:text>
            </span>
            <!--<xsl:if test="not(@rend='roman')">-->
            <!--<xsl:attribute name="class">tei-italic</xsl:attribute>-->
            <!--</xsl:if>-->
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/filiation">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Filiation:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="msItem/textLang">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Language(s):')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:choose>
                <xsl:when test="not(.//text()) and (@mainLang or @otherLangs)">
                    <xsl:for-each select="tokenize(string-join((@mainLang, @otherLangs), ' '), ' ')">
                        <xsl:value-of select="bod:languageCodeLookup(.)"/>
                        <xsl:if test="position() ne last()"><xsl:text>, </xsl:text></xsl:if>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
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

    <xsl:template match="physDesc/p">
        <div class="physDesc-p">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="accMat">
        <div class="{name()}">
            <h4>
                <xsl:copy-of select="bod:standardText('Accompanying Material')"/>
            </h4>
            <p>
                <xsl:apply-templates/>
            </p>
        </div>
    </xsl:template>

    <xsl:template match="additions">
        <div class="additions">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Additions:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="bindingDesc">
        <div class="{name()}">
            <h4>
                <xsl:copy-of select="bod:standardText('Binding')"/>
            </h4>
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
            <h4>
                <xsl:copy-of select="bod:standardText('Decoration')"/>
            </h4>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="handDesc">
        <div class="handDesc">
            <h4>
                <xsl:copy-of select="bod:standardText('Hand(s)')"/>
            </h4>
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
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Musical Notation:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="typeDesc">
        <div class="typeDesc">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Type(s):')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="sealDesc">
        <span class="tei-label">
            <xsl:copy-of select="bod:standardText('Seal(s):')"/>
            <xsl:text> </xsl:text>
        </span>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="scriptDesc">
        <h4>
            <xsl:copy-of select="bod:standardText('Script(s)')"/>
        </h4>
        <div class="scriptDesc">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="objectDesc">
        <div class="objectDesc">
            <xsl:if test="@form">
                <div class="form">
                    <span class="tei-label">
                        <xsl:copy-of select="bod:standardText('Form:')"/>
                        <xsl:text> </xsl:text>
                    </span>
                    <xsl:value-of select="@form"/>
                </div>
            </xsl:if>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="layoutDesc">
        <div class="{name()}">
            <h4>
                <xsl:copy-of select="bod:standardText('Layout')"/>
            </h4>
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
            <h4>
                <xsl:copy-of select="bod:standardText('Collation')"/>
            </h4>
            <div class="collation">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="condition">
        <div>
            <h4>
                <xsl:copy-of select="bod:standardText('Condition')"/>
            </h4>
            <div class="condition">
                <xsl:apply-templates/>
            </div>
        </div>

    </xsl:template>

    <xsl:template match="foliation">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Foliation:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- this is handled with supportDesc@material - AH -->
    <xsl:template match="support">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Support:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <!-- secFol, locus, extent -->
    <xsl:template match="secFol">
        <div class="{ name() }">
            <span class="tei-label italic">
                <xsl:copy-of select="bod:standardText('Secundo Folio:')"/>
                <xsl:text> </xsl:text>
            </span>
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
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Extent:')"/>
                <xsl:text> </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="dimensions">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="extent/dimensions">
        <div class="{name()}">
            <span class="tei-label">
                <xsl:copy-of select="bod:standardText('Dimensions:')"/>
                <xsl:text> </xsl:text>
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

    <!-- Things inside additional -->
    <xsl:template match="additional/listBibl">
        <h3 class="msDesc-heading3">
            <xsl:copy-of select="bod:standardText('Bibliography')"/>
        </h3>
        <div class="listBibl">
            <ul class="listBibl">
                <xsl:apply-templates/>
            </ul>
        </div>
    </xsl:template>

    <xsl:template match="additional/surrogates">
        <div class="surrogates">
            <xsl:if test="bibl[@type = ('digital-fascimile','digital-facsimile')]">
                <h3 class="msDesc-heading3">
                    <xsl:copy-of select="bod:standardText('Digital Images')"/>
                </h3>
                <p>
                    <xsl:apply-templates select="bibl[@type = ('digital-fascimile','digital-facsimile')]"/>
                </p>
            </xsl:if>
            <xsl:if test="bibl[idno/@type = 'microfilm']">
                <h3 class="msDesc-heading3">
                    <xsl:copy-of select="bod:standardText('Microfilm')"/>
                </h3>
                <p>
                    <xsl:apply-templates select="bibl[idno/@type = 'microfilm']"/>
                </p>
            </xsl:if>
            <xsl:if test="bibl[not(@type = ('digital-fascimile','digital-facsimile') or idno/@type = 'microfilm')]">
                <h3 class="msDesc-heading3">
                    <xsl:copy-of select="bod:standardText('Surrogates')"/>
                </h3>
                <p>
                    <xsl:apply-templates select="bibl[not(@type = ('digital-fascimile','digital-facsimile') or idno/@type = 'microfilm')]"/>
                </p>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="surrogates//bibl/@*"/>
    
    <xsl:template match="surrogates//bibl/idno[@n]">
        <xsl:value-of select="@n"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="additional/adminInfo">
        <div class="adminInfo">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="adminInfo/*">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="source">
        <h3>
            <xsl:copy-of select="bod:standardText('Record Sources')"/>
        </h3>
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="source/listBibl" priority="10">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- Things that can be displayed as hyperlinks (if they've been given a @key attribute -->
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
    
    <xsl:template match="addName">
        <xsl:apply-templates/>
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
            <xsl:copy-of select="bod:logging('warn', 'No template for this TEI element', ., name())"/>
        </xsl:if>
        <span class="{name()}">
            <xsl:apply-templates select="@*|node()"/>
        </span>
    </xsl:template>
    
</xsl:stylesheet>
