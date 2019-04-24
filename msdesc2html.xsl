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
            <xsl:when test="$lang eq 'bo'">Tibetan</xsl:when>
            <xsl:when test="$lang eq 'zxx'">No Linguistic Content</xsl:when>
            <xsl:when test="$lang eq 'und'">Undetermined</xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$lang"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="bod:personRoleLookup" as="xs:string">
        <xsl:param name="role" as="xs:string"/>
        <!-- Lookup the values used in role attributes of people (or organizations) and map 
            those values to labels for display in facets on the web site -->
        <xsl:variable name="rolelabels" as="xs:string*">
            <xsl:for-each select="distinct-values(tokenize(normalize-space($role), ' '))">
                <xsl:choose>
                    <xsl:when test="string-length(.) eq 3">
                        <xsl:value-of select="bod:roleLookupMarcCode(.)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="bod:roleNormalizeLabel(.)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="label">
            <xsl:for-each select="$rolelabels[string-length(.) gt 0]">
                <xsl:value-of select="."/>
                <xsl:choose>
                    <xsl:when test="position() eq last() - 1">
                        <xsl:text> and </xsl:text>
                    </xsl:when>
                    <xsl:when test="position() ne last()">
                        <xsl:text>, </xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string-join($label, '')"/>
    </xsl:function>
    
    <xsl:function name="bod:roleNormalizeLabel" as="xs:string">
        <xsl:param name="rolelabel" as="xs:string"/>
        <xsl:variable name="lcrolelabel" as="xs:string" select="lower-case($rolelabel)"/>
        <xsl:choose>
            <xsl:when test="$lcrolelabel eq 'formerowner'">Former Owner</xsl:when>
            <xsl:otherwise>
                <!-- Anything else, just return with first letter capitalized -->
                <xsl:value-of select="concat(upper-case(substring($rolelabel, 1, 1)), substring($rolelabel, 2))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="bod:roleLookupMarcCode" as="xs:string?">
        <xsl:param name="rolecode" as="xs:string"/>
        <!-- This is the MARC Code List for Relators standard, copy taken 
             on 2018-06-22 from http://id.loc.gov/vocabulary/relators.tsv -->
        <xsl:variable name="rolesmapping" as="element()*">
            <map code="abr">Abridger</map>
            <map code="acp">Art copyist</map>
            <map code="act">Actor</map>
            <map code="adi">Art director</map>
            <map code="adp">Adapter</map>
            <map code="aft">Author of afterword, colophon, etc.</map>
            <map code="anl">Analyst</map>
            <map code="anm">Animator</map>
            <map code="ann">Annotator</map>
            <map code="ant">Bibliographic antecedent</map>
            <map code="ape">Appellee</map>
            <map code="apl">Appellant</map>
            <map code="app">Applicant</map>
            <map code="aqt">Author in quotations or text abstracts</map>
            <map code="arc">Architect</map>
            <map code="ard">Artistic director</map>
            <map code="arr">Arranger</map>
            <map code="art">Artist</map>
            <map code="asg">Assignee</map>
            <map code="asn">Associated name</map>
            <map code="ato">Autographer</map>
            <map code="att">Attributed name</map>
            <map code="auc">Auctioneer</map>
            <map code="aud">Author of dialog</map>
            <map code="aui">Author of introduction, etc.</map>
            <map code="aus">Screenwriter</map>
            <map code="aut">Author</map>
            <map code="bdd">Binding designer</map>
            <map code="bjd">Bookjacket designer</map>
            <map code="bkd">Book designer</map>
            <map code="bkp">Book producer</map>
            <map code="blw">Blurb writer</map>
            <map code="bnd">Binder</map>
            <map code="bpd">Bookplate designer</map>
            <map code="brd">Broadcaster</map>
            <map code="brl">Braille embosser</map>
            <map code="bsl">Bookseller</map>
            <map code="cas">Caster</map>
            <map code="ccp">Conceptor</map>
            <map code="chr">Choreographer</map>
            <map code="cli">Client</map>
            <map code="cll">Calligrapher</map>
            <map code="clr">Colorist</map>
            <map code="clt">Collotyper</map>
            <map code="cmm">Commentator</map>
            <map code="cmp">Composer</map>
            <map code="cmt">Compositor</map>
            <map code="cnd">Conductor</map>
            <map code="cng">Cinematographer</map>
            <map code="cns">Censor</map>
            <map code="coe">Contestant-appellee</map>
            <map code="col">Collector</map>
            <map code="com">Compiler</map>
            <map code="con">Conservator</map>
            <map code="cor">Collection registrar</map>
            <map code="cos">Contestant</map>
            <map code="cot">Contestant-appellant</map>
            <map code="cou">Court governed</map>
            <map code="cov">Cover designer</map>
            <map code="cpc">Copyright claimant</map>
            <map code="cpe">Complainant-appellee</map>
            <map code="cph">Copyright holder</map>
            <map code="cpl">Complainant</map>
            <map code="cpt">Complainant-appellant</map>
            <map code="cre">Creator</map>
            <map code="crp">Correspondent</map>
            <map code="crr">Corrector</map>
            <map code="crt">Court reporter</map>
            <map code="csl">Consultant</map>
            <map code="csp">Consultant to a project</map>
            <map code="cst">Costume designer</map>
            <map code="ctb">Contributor</map>
            <map code="cte">Contestee-appellee</map>
            <map code="ctg">Cartographer</map>
            <map code="ctr">Contractor</map>
            <map code="cts">Contestee</map>
            <map code="ctt">Contestee-appellant</map>
            <map code="cur">Curator</map>
            <map code="cwt">Commentator for written text</map>
            <map code="dbp">Distribution place</map>
            <map code="dfd">Defendant</map>
            <map code="dfe">Defendant-appellee</map>
            <map code="dft">Defendant-appellant</map>
            <map code="dgg">Degree granting institution</map>
            <map code="dgs">Degree supervisor</map>
            <map code="dis">Dissertant</map>
            <map code="dln">Delineator</map>
            <map code="dnc">Dancer</map>
            <map code="dnr">Donor</map>
            <map code="dpc">Depicted</map>
            <map code="dpt">Depositor</map>
            <map code="drm">Draftsman</map>
            <map code="drt">Director</map>
            <map code="dsr">Designer</map>
            <map code="dst">Distributor</map>
            <map code="dtc">Data contributor</map>
            <map code="dte">Dedicatee</map>
            <map code="dtm">Data manager</map>
            <map code="dto">Dedicator</map>
            <map code="dub">Dubious author</map>
            <map code="edc">Editor of compilation</map>
            <map code="edm">Editor of moving image work</map>
            <map code="edt">Editor</map>
            <map code="egr">Engraver</map>
            <map code="elg">Electrician</map>
            <map code="elt">Electrotyper</map>
            <map code="eng">Engineer</map>
            <map code="enj">Enacting jurisdiction</map>
            <map code="etr">Etcher</map>
            <map code="evp">Event place</map>
            <map code="exp">Expert</map>
            <map code="fac">Facsimilist</map>
            <map code="fds">Film distributor</map>
            <map code="fld">Field director</map>
            <map code="flm">Film editor</map>
            <map code="fmd">Film director</map>
            <map code="fmk">Filmmaker</map>
            <map code="fmo">Former owner</map>
            <map code="fmp">Film producer</map>
            <map code="fnd">Funder</map>
            <map code="fpy">First party</map>
            <map code="frg">Forger</map>
            <map code="gis">Geographic information specialist</map>
            <map code="his">Host institution</map>
            <map code="hnr">Honoree</map>
            <map code="hst">Host</map>
            <map code="ill">Illustrator</map>
            <map code="ilu">Illuminator</map>
            <map code="ins">Inscriber</map>
            <map code="inv">Inventor</map>
            <map code="isb">Issuing body</map>
            <map code="itr">Instrumentalist</map>
            <map code="ive">Interviewee</map>
            <map code="ivr">Interviewer</map>
            <map code="jud">Judge</map>
            <map code="jug">Jurisdiction governed</map>
            <map code="lbr">Laboratory</map>
            <map code="lbt">Librettist</map>
            <map code="ldr">Laboratory director</map>
            <map code="led">Lead</map>
            <map code="lee">Libelee-appellee</map>
            <map code="lel">Libelee</map>
            <map code="len">Lender</map>
            <map code="let">Libelee-appellant</map>
            <map code="lgd">Lighting designer</map>
            <map code="lie">Libelant-appellee</map>
            <map code="lil">Libelant</map>
            <map code="lit">Libelant-appellant</map>
            <map code="lsa">Landscape architect</map>
            <map code="lse">Licensee</map>
            <map code="lso">Licensor</map>
            <map code="ltg">Lithographer</map>
            <map code="lyr">Lyricist</map>
            <map code="mcp">Music copyist</map>
            <map code="mdc">Metadata contact</map>
            <map code="med">Medium</map>
            <map code="mfp">Manufacture place</map>
            <map code="mfr">Manufacturer</map>
            <map code="mod">Moderator</map>
            <map code="mon">Monitor</map>
            <map code="mrb">Marbler</map>
            <map code="mrk">Markup editor</map>
            <map code="msd">Musical director</map>
            <map code="mte">Metal-engraver</map>
            <map code="mtk">Minute taker</map>
            <map code="mus">Musician</map>
            <map code="nrt">Narrator</map>
            <map code="opn">Opponent</map>
            <map code="org">Originator</map>
            <map code="orm">Organizer</map>
            <map code="osp">Onscreen presenter</map>
            <map code="oth">Other</map>
            <map code="own">Owner</map>
            <map code="pan">Panelist</map>
            <map code="pat">Patron</map>
            <map code="pbd">Publishing director</map>
            <map code="pbl">Publisher</map>
            <map code="pdr">Project director</map>
            <map code="pfr">Proofreader</map>
            <map code="pht">Photographer</map>
            <map code="plt">Platemaker</map>
            <map code="pma">Permitting agency</map>
            <map code="pmn">Production manager</map>
            <map code="pop">Printer of plates</map>
            <map code="ppm">Papermaker</map>
            <map code="ppt">Puppeteer</map>
            <map code="pra">Praeses</map>
            <map code="prc">Process contact</map>
            <map code="prd">Production personnel</map>
            <map code="pre">Presenter</map>
            <map code="prf">Performer</map>
            <map code="prg">Programmer</map>
            <map code="prm">Printmaker</map>
            <map code="prn">Production company</map>
            <map code="pro">Producer</map>
            <map code="prp">Production place</map>
            <map code="prs">Production designer</map>
            <map code="prt">Printer</map>
            <map code="prv">Provider</map>
            <map code="pta">Patent applicant</map>
            <map code="pte">Plaintiff-appellee</map>
            <map code="ptf">Plaintiff</map>
            <map code="pth">Patent holder</map>
            <map code="ptt">Plaintiff-appellant</map>
            <map code="pup">Publication place</map>
            <map code="rbr">Rubricator</map>
            <map code="rcd">Recordist</map>
            <map code="rce">Recording engineer</map>
            <map code="rcp">Addressee</map>
            <map code="rdd">Radio director</map>
            <map code="red">Redaktor</map>
            <map code="ren">Renderer</map>
            <map code="res">Researcher</map>
            <map code="rev">Reviewer</map>
            <map code="rpc">Radio producer</map>
            <map code="rps">Repository</map>
            <map code="rpt">Reporter</map>
            <map code="rpy">Responsible party</map>
            <map code="rse">Respondent-appellee</map>
            <map code="rsg">Restager</map>
            <map code="rsp">Respondent</map>
            <map code="rsr">Restorationist</map>
            <map code="rst">Respondent-appellant</map>
            <map code="rth">Research team head</map>
            <map code="rtm">Research team member</map>
            <map code="sad">Scientific advisor</map>
            <map code="sce">Scenarist</map>
            <map code="scl">Sculptor</map>
            <map code="scr">Scribe</map>
            <map code="sds">Sound designer</map>
            <map code="sec">Secretary</map>
            <map code="sgd">Stage director</map>
            <map code="sgn">Signer</map>
            <map code="sht">Supporting host</map>
            <map code="sll">Seller</map>
            <map code="sng">Singer</map>
            <map code="spk">Speaker</map>
            <map code="spn">Sponsor</map>
            <map code="spy">Second party</map>
            <map code="srv">Surveyor</map>
            <map code="std">Set designer</map>
            <map code="stg">Setting</map>
            <map code="stl">Storyteller</map>
            <map code="stm">Stage manager</map>
            <map code="stn">Standards body</map>
            <map code="str">Stereotyper</map>
            <map code="tcd">Technical director</map>
            <map code="tch">Teacher</map>
            <map code="ths">Thesis advisor</map>
            <map code="tld">Television director</map>
            <map code="tlp">Television producer</map>
            <map code="trc">Transcriber</map>
            <map code="trl">Translator</map>
            <map code="tyd">Type designer</map>
            <map code="tyg">Typographer</map>
            <map code="uvp">University place</map>
            <map code="vac">Voice actor</map>
            <map code="vdg">Videographer</map>
            <map code="wac">Writer of added commentary</map>
            <map code="wal">Writer of added lyrics</map>
            <map code="wam">Writer of accompanying material</map>
            <map code="wat">Writer of added text</map>
            <map code="wdc">Woodcutter</map>
            <map code="wde">Wood engraver</map>
            <map code="win">Writer of introduction</map>
            <map code="wit">Witness</map>
            <map code="wpr">Writer of preface</map>
            <map code="wst">Writer of supplementary textual content</map>
        </xsl:variable>
        <xsl:variable name="matchinglabel" as="xs:string?" select="$rolesmapping//text()[../@code = lower-case($rolecode)]"/>
        <xsl:if test="exists($matchinglabel)">
            <xsl:value-of select="$matchinglabel"/>
        </xsl:if>        
    </xsl:function>
    
    <xsl:function name="bod:standardText">
        <xsl:param name="textval" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$textval = ('Physical Description', 'Contents', 'History', 'Record Sources', 'Language(s):', 'Support:', 'Origin:', 'Form:', 'Additional Information')">
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

    <xsl:function name="bod:direction" as="attribute()?">
        <xsl:param name="elem" as="element()?"/>
        <!-- This funtion returns a HTML style attribute if the TEI element has a @xml:lang 
             specifying the script, as per BCP 47, is right-to-left (eg. "ar-Arab" or "per-Arab-x-lc"),
             or if over half the characters within match a known right-to-left script, unless it contains
             a foreign TEI element, indicating the contents are split between multiple scripts -->
        <xsl:variable name="langcode" as="xs:string?" select="$elem/@xml:lang"/>
        <xsl:variable name="stringval" as="xs:string" select="normalize-space($elem/string())"/>
        <xsl:if test="not($elem//foreign or matches($langcode, '[^\-]+\-Latn', 'i')) and (
            matches($langcode, '[^\-]+\-(Adlm|Arab|Aran|Armi|Avst|Cprt|Egyd|Egyh|Hatr|Hebr|Hung|Inds|Khar|Lydi|Mand|Mani|Mend|Merc|Mero|Narb|Nbat|Nkoo|Orkh|Palm|Phli|Phlp|Phlv|Phnx|Prti|Rohg|Samr|Sarb|Sogd|Sogo|Syrc|Syre|Syrj|Syrn|Thaa|Wole)', 'i') 
            or string-length(replace($stringval, '[&#x600;-&#x6FF;&#xFE70;-&#xFEFF;&#x10b00;-&#x10b3f;&#x0591;-&#x05f4;&#x0700;-&#x074f;&#x860;-&#x86f;]', '')) lt string-length($stringval) div 2
            )">
            <!-- NOTE: The match against the language code above uses a list of codes for right-to-left 
                 scripts taken from: https://en.wikipedia.org/wiki/ISO_15924#List_of_codes -->
            <!-- NOTE: If all the ranges for Arabic symbols then this would make anything with a number 
                 display as right-to-left. The above should be sufficient to cover most cases. -->
            <!-- TODO: Add more unicode ranges for non-Middle-Eastern R-T-L scripts? -->
            <xsl:attribute name="style" select="'direction:rtl; display:inline-block;'"/>
        </xsl:if>
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
            
            <xsl:choose>
                <xsl:when test="string-length(/TEI/@xml:id/string()) eq 0">
                    
                    <!-- Cannot do anything if there is no @xml:id on the root TEI element -->
                    <xsl:copy-of select="bod:logging('warn', 'Cannot process manuscript without @xml:id for root TEI element', /TEI, base-uri())"/>
                                        
                </xsl:when>
                <xsl:otherwise>

                    <!-- Build HTML in a variable so it can be post-processed to strip out undesirable HTML code -->
                    <xsl:variable name="outputdoc" as="element()">
                        <xsl:choose>
                            <xsl:when test="$output-full-html">
                                <html xmlns="http://www.w3.org/1999/xhtml">
                                    <head>
                                        <title></title>
                                    </head>
                                    <body>
                                        <div class="content tei-body" id="{/TEI/@xml:id}">
                                            <xsl:call-template name="Header"/>
                                            <xsl:apply-templates select="/TEI/teiHeader/fileDesc/sourceDesc/msDesc"/>
                                            <xsl:call-template name="Footer"/>
                                        </div>
                                    </body>
                                </html>
                            </xsl:when>
                            <xsl:otherwise>
                                <div>
                                    <div class="content tei-body" id="{/TEI/@xml:id}">
                                        <xsl:call-template name="Header"/>
                                        <xsl:apply-templates select="/TEI/teiHeader/fileDesc/sourceDesc/msDesc"/>
                                        <xsl:call-template name="Footer"/>
                                    </div>
                                </div>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <!-- Create output HTML files -->
                    <xsl:variable name="subfolders" select="tokenize(substring-after(base-uri(.), $collections-path), '/')[position() ne last()]"/>
                    <xsl:variable name="outputpath" select="concat('./html/', string-join($subfolders, '/'), '/', /TEI/@xml:id/string(), '.html')"/>
                    <xsl:result-document href="{$outputpath}" method="xhtml" encoding="UTF-8" indent="yes">
                        
                        <!-- Applying templates on the HTML already built, with a mode, to strip out undesirable HTML code -->
                        <xsl:apply-templates select="$outputdoc" mode="stripoutempty"/>
                        
                    </xsl:result-document>
                    
                </xsl:otherwise>
            </xsl:choose>

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
         convert2HTML.xsl stylesheets to add a special footer for each TEI catalogue. The
         hooks which call them are in other templates above and below in this stylesheet.-->
    <xsl:template name="Header"></xsl:template>
    <xsl:template name="Footer"></xsl:template>
    <xsl:template name="AdditionalContent"></xsl:template>
    <xsl:template name="MsItemFooter"></xsl:template>



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

    <xsl:template match="adminInfo/note">
        <div class="{name()}" style="margin-top:1rem;">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="foreign">
        <xsl:text> </xsl:text>
        <span class="{name()} {@rend}">
            <xsl:copy-of select="bod:direction(.)"/>
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
            <xsl:when test="starts-with($target, 'http') or starts-with($target, 'mailto') or starts-with($target, 'ftp')">
                <!-- For valid-looking URLs create links to external resources -->
                <a href="{$target}" target="_blank">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:when test="starts-with($target, 'www')">
                <!-- Assume if the protocol is missing that it is http (hopefully the destination server will redirect if https) -->
                <a href="http://{$target}" target="_blank">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:when test="contains(base-uri(.), 'hebrew-mss') or contains(base-uri(.), 'genizah-mss')">
                <!-- In Hebrew and Genizah, anything that isn't a URL appears to be a classmark, sometimes with part numbers appended, 
                     so as a TEMPORARY fix, convert them into links to search the catalogue -->
                <a href="/?q={translate($target, '_#', '  ')}">
                    <xsl:apply-templates/>
                    <xsl:copy-of select="bod:logging('warn', 'Converting ref with unrecognized target into a search', ., $target)"/>
                </a>
            </xsl:when>
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

    <!-- lb to br: overridden in medieval-mss, to output | instead -->
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
        <div class="msDesc" id="{ $id }" lang="{ (@xml:lang, 'en')[1] }">
            
            <!-- Identifiers -->
            <xsl:if test="msIdentifier/collection or msIdentifier/altIdentifier[child::idno[not(@subtype)]]">
                <div class="msIdentifier">
                    <xsl:apply-templates select="msIdentifier"/>
                </div>
            </xsl:if>
            
            <!-- The majority of content - works, parts, physical description, history, etc -->
            <xsl:apply-templates select="*[not(self::msIdentifier or self::additional)]"/>
            
            <!-- Move additional to the end. This will be after any parts, because is 
                 desirable because TEI P5 insists msPart, if present, are the last children
                 of msDesc. This is currently the only except to displaying in document order -->
            <xsl:if test="additional and msPart">
                <h2>
                    <xsl:copy-of select="bod:standardText('Additional Information')"/>
                </h2>
            </xsl:if>
            <xsl:apply-templates select="additional"/>
            
            <!-- This named template may be used in some catalogues -->
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
    
    <xsl:template match="list//head">
        <p>
            <xsl:apply-templates/>
        </p>
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
        <div class="{name()}" id="{(@xml:id, generate-id())[1]}" style="margin-left:2rem;">
            <xsl:choose>
                <xsl:when test="not(preceding-sibling::msPart) and following-sibling::msPart">
                    <xsl:attribute name="style">
                        <xsl:text>padding-left:2rem; margin-top:1rem; border-bottom-color:#C0C0C0; border-top:1px #C0C0C0 solid;</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="following-sibling::msPart or preceding-sibling::msPart">
                    <xsl:attribute name="style">
                        <xsl:text>padding-left:2rem; border-bottom-color:#C0C0C0;</xsl:text>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <h2>
                <xsl:if test="following-sibling::msPart or preceding-sibling::msPart">
                    <xsl:attribute name="style">
                        <xsl:text>position:relative; left:-2rem;</xsl:text>
                    </xsl:attribute>
                </xsl:if>
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
            <xsl:apply-templates select="summary"/>
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
                        <xsl:choose>
                            <xsl:when test="not(acquisition) and ancestor::msPart">
                                <xsl:copy-of select="bod:standardText('Provenance')"/>
                            </xsl:when>
                            <xsl:otherwise>
                        <xsl:copy-of select="bod:standardText('Provenance and Acquisition')"/>
                            </xsl:otherwise>
                        </xsl:choose>
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

    <xsl:template match="q">
        <xsl:text>‘</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>’</xsl:text>
    </xsl:template>

    <!-- msIdentifier -->
    <xsl:template match="msIdentifier">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Things in msContents -->
    <xsl:template match="msContents/summary">
        <!-- h instead of p -->
        <xsl:choose>
            <xsl:when test="not(child::*) and string-length(text()) le 128">
                <h4 class="msSummary">
                    <xsl:apply-templates/>
                </h4>
            </xsl:when>
            <xsl:otherwise>
                <div class="msSummary">
                    <span class="tei-label">
                        <xsl:copy-of select="bod:standardText('Summary of Contents:')"/>
                        <xsl:text> </xsl:text>
                    </span>
                    <xsl:apply-templates/> 
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="msContents/summary/p">
        <span class="summary-p">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="summary">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
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
        <div class="msItem" id="{(@xml:id, generate-id())[1]}">
            <xsl:if test="ancestor::msPart and not(following-sibling::msItem) and not(preceding-sibling::msItem)">
                <xsl:attribute name="style">
                    <xsl:text>border-bottom-color:#FFFFFF; margin-bottom:0px; padding-bottom:0px;</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="string-length(@n) gt 0 and not(@n = 'toc') and count(parent::msContents/msItem[@n]) gt 1 and not(child::*[1][self::locus])">
                <!-- Display optional numbering on msItems, on its own line (except when the first-child is a locus, then it'll be inline) -->
                <div class="item-number">
                    <xsl:value-of select="@n"/>
                    <xsl:text>. </xsl:text>
                </div>
            </xsl:if>
            <xsl:call-template name="SubItems"/>
            <xsl:call-template name="MsItemFooter"/>
        </div>
    </xsl:template>
        
    <xsl:template match="msItem/msItem">
        <div class="nestedmsItem" id="{(@xml:id, generate-id())[1]}">
            <xsl:choose>
                <xsl:when test="not(following-sibling::msItem)">
                    <xsl:attribute name="style">
                        <xsl:text>border-bottom-color:#FFFFFF; margin-bottom:0px;</xsl:text>
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="not(preceding-sibling::msItem)">
                    <xsl:attribute name="style">
                        <xsl:text>margin-top:1rem;</xsl:text>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:if test="string-length(@n) gt 0 and not(@n = 'toc') and count(parent::msItem/msItem[@n]) gt 1 and not(child::*[1][self::locus])">
                <!-- Display optional numbering on msItems, on its own line (except when the first-child is a locus, then it'll be inline) -->
                <div class="item-number">
                    <xsl:value-of select="@n"/>
                    <xsl:text>. </xsl:text>
                </div>
            </xsl:if>
            <xsl:call-template name="SubItems"/>
            <xsl:call-template name="MsItemFooter"/>
        </div>
    </xsl:template>
    
    <xsl:template name="SubItems">
        <!-- This lists sub-items (e.g. individual poems in collection of poetry) after any other fields 
             about parent item (e.g. its language). It is a named template so it can be overriden by each
             catalogue. -->
        <xsl:apply-templates select="*[not(self::msItem)]"/>
        <xsl:apply-templates select="msItem"/>
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
        <span class="tei-editor{ if ($rolelabel ne 'editor') then concat(' tei-', lower-case($rolelabel)) else ''}">
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

    <xsl:template match="quote[parent::*[not(self::p or self::note or self::incipit)]/(p|note|incipit) or parent::msItem]">
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
                <span>
                    <xsl:copy-of select="bod:direction(.)"/>
                    <xsl:if test="@defective='true'">
                        <span class="defective">||</span>
                    </xsl:if>
                    <xsl:apply-templates/>
                </span>
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
                <span>
                    <xsl:copy-of select="bod:direction(.)"/>
                    <xsl:apply-templates/>
                    <xsl:if test="@defective='true'">
                        <span class="defective">||</span>
                    </xsl:if>
                </span>
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
            <span>
                <xsl:copy-of select="bod:direction(.)"/>
                <xsl:apply-templates/>
            </span>
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
            <span>
                <xsl:copy-of select="bod:direction(.)"/>
                <xsl:apply-templates/>
            </span>
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
            <span>
                <xsl:copy-of select="bod:direction(.)"/>
                <xsl:apply-templates/>
            </span>
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
            <xsl:if test="parent::msItem[@n] and not(parent::msItem/@n = 'toc') and count(parent::msItem/parent::*/msItem[@n]) gt 1 and count(preceding-sibling::*) = 0">
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

    <xsl:template match="binding/p|binding/condition|collation/p|foliation/p">
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

    <!-- where all the text inside a decoNote (e.g. not nested children) = ' Decoration' get rid of it -->
    <xsl:template match="decoNote/text()[normalize-space(.) = 'Decoration']"/>

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
                    <xsl:choose>
                        <xsl:when test="lower-case(@form) = ('concertina_book','concertina__book')">
                            <xsl:text>Concertina book</xsl:text>
                        </xsl:when>
                        <xsl:when test="lower-case(@form) = 'rolled_book'">
                            <xsl:text>Rolled book</xsl:text>
                        </xsl:when>
                        <xsl:when test="lower-case(@form) = 'palm_leaf'">
                            <xsl:text>Palm leaf</xsl:text>
                        </xsl:when>
                        <xsl:when test="lower-case(@form) = 'modern_notebook'">
                            <xsl:text>Modern notebook</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="@form"/>
                        </xsl:otherwise>
                    </xsl:choose>
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
        <!-- Overridden when the child of a binding element, where it is treated as a simple paragraph -->
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
                <xsl:copy-of select="bod:standardText('Dimensions')"/>
                <xsl:if test="@type">
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="translate(@type, '_', ' ')"/>
                    <xsl:text>)</xsl:text>
                </xsl:if>
                <xsl:text>: </xsl:text>
            </span>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="dimensions/dim">
        <xsl:apply-templates select="*|text()"/>
    </xsl:template>

    <xsl:template match="height[parent::dimensions/width]">
        <!-- When height and width are both specified, ensure height is first and units are added. -->
        <span class="height">
            <xsl:value-of select="."/>
        </span>
        <xsl:text> × </xsl:text>
        <span class="width">
            <xsl:value-of select="parent::dimensions/width"/>
        </span>
        <!-- Finally add depth, if specified -->
        <xsl:if test="parent::dimensions/depth">
            <xsl:text> × </xsl:text>
            <span class="depth">
                <xsl:value-of select="parent::dimensions/depth"/>
            </span>
        </xsl:if>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="(parent::dimensions//@unit)[1]"/>
    </xsl:template>
    
    <!-- The output of these has been handled by the above template -->
    <xsl:template match="width[parent::dimensions/height]"/>
    <xsl:template match="depth[parent::dimensions/height]"/>
    
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
    
    <!--    <xsl:template match="msItem/listBibl[bibl]"> 
        <span class="{name()}"> 
            <span class="tei-label"> 
                <xsl:copy-of select="bod:standardText('References:')"/> 
                <xsl:text> </xsl:text> 
            </span> 
            <xsl:apply-templates/>
        </span>
    </xsl:template>--> 
    
    <xsl:template match="hi[@rend]">
        <!-- hi is used for ad-hoc formatting. To handle multiple space-separate values in @rend attributes, 
             which need to be transformed into nested HTML tags, a recursively-called name template is required. -->
        <xsl:call-template name="Rend">
            <xsl:with-param name="rends" select="tokenize(@rend, '\s+')[string-length(.) gt 0]"/>
            <xsl:with-param name="contents">
                <xsl:apply-templates/>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="Rend">
        <xsl:param name="rends" as="xs:string*"/>
        <xsl:param name="contents" as="document-node()*"/>
        <xsl:choose>
            <xsl:when test="count($rends) eq 0">
                <xsl:copy-of select="$contents"/>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'bold'">
                <b>
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </b>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'italic'">
                <i>
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </i>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'smallcaps'">
                <span style="font-variant:small-caps;">
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'roman'">
                <span style="font-style:normal ! important;">
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'superscript'">
                <sup>
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </sup>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'subscript'">
                <sub>
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </sub>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'underline'">
                <span style="text-decoration:underline;">
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'overline'">
                <span style="text-decoration:overline;">
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:when test="$rends[1] eq 'strikethrough'">
                <span style="text-decoration:line-through;">
                    <xsl:call-template name="Rend">
                        <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                        <xsl:with-param name="contents" select="$contents"/>
                    </xsl:call-template>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <!-- If a @rend value is not one of the above, ignore it... -->
                <xsl:call-template name="Rend">
                    <xsl:with-param name="rends" select="$rends[position() gt 1]"/>
                    <xsl:with-param name="contents" select="$contents"/>
                </xsl:call-template>
                <!-- ...but also log it... -->
                <xsl:copy-of select="bod:logging('warn', concat('Unrecognized rend attribute value: ', $rends[1]), .)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="hi[not(@rend)]">
        <mark><xsl:apply-templates/></mark>
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
    
    <xsl:template match="item[not(preceding-sibling::label)]"> 
        <li class="mslistitem"> 
            <xsl:apply-templates/> 
        </li> 
    </xsl:template>
    
    <xsl:template match="item[preceding-sibling::label]"><!-- These items are handled in the template for label --></xsl:template>

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
            <xsl:if test=".//bibl[@type = ('digital-fascimile','digital-facsimile')]">
                <h3 class="msDesc-heading3">
                    <xsl:copy-of select="bod:standardText('Digital Images')"/>
                </h3>
                <p>
                    <xsl:for-each select=".//bibl[@type = ('digital-fascimile','digital-facsimile')]">
                        <xsl:apply-templates select="."/>
                        <br/>
                    </xsl:for-each>
                </p>
            </xsl:if>
            <xsl:if test=".//bibl[@type = 'microfilm'] or .//bibl[idno/@type = 'microfilm']">
                <h3 class="msDesc-heading3">
                    <xsl:copy-of select="bod:standardText('Microfilm')"/>
                </h3>
                <p>
                    <xsl:for-each select=".//bibl[@type = 'microfilm' or idno/@type = 'microfilm']">
                        <xsl:apply-templates select="."/>
                        <br/>
                    </xsl:for-each>
                </p>
            </xsl:if>
            <xsl:if test="bibl[not(@type = ('digital-fascimile','digital-facsimile', 'microfilm') or idno/@type = 'microfilm')]">
                <h3 class="msDesc-heading3">
                    <xsl:copy-of select="bod:standardText('Surrogates')"/>
                </h3>
                <p>
                    <xsl:for-each select="bibl[not(@type = ('digital-fascimile','digital-facsimile', 'microfilm') or idno/@type = 'microfilm')]">
                        <xsl:apply-templates select="."/>
                        <br/>
                    </xsl:for-each>
                </p>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="surrogates//bibl">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
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

    <xsl:template match="adminInfo/recordHist">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="adminInfo//source">
        <h3>
            <xsl:copy-of select="bod:standardText('Record Sources')"/>
        </h3>
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="adminInfo/availability">
        <h3>
            <xsl:copy-of select="bod:standardText('Availability')"/>
        </h3>
        <div class="{name()}">
            <xsl:processing-instruction name="ni"/>
            <xsl:apply-templates/>
            <xsl:processing-instruction name="ni"/>
        </div>
    </xsl:template>

    <xsl:template match="source/listBibl" priority="10">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- Things that can be displayed as hyperlinks (if they've been given a @key attribute) -->
    <xsl:template match="persName | placeName | orgName | name | country | settlement | district | region | repository | idno">
        <!-- NOTE: This list may differ between TEI catalogues -->
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="string-join((name(), @role), ' ')"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@key and not(@key='')">
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
    
    <xsl:template match="forename|addName">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="author[child::* or text()]">
        <span class="{name()}">
            <xsl:choose>
                <xsl:when test="normalize-space(.)=''" />
                <xsl:when test="@key and not(@key='')">
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
    
    <xsl:template match="author[not(child::* or text())]"><!-- Do not output anything for self-closing author tags --></xsl:template>

    <xsl:template match="heraldry | seg">
        <span class="{name()}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="label">
        <b>
            <xsl:apply-templates/>
        </b>
    </xsl:template>
    
    <xsl:template match="list">
        <span class="head">
            <xsl:apply-templates select="head"/>
        </span>
        <ul class="{name()}"> 
            <xsl:apply-templates select="(*|text())[not(self::head)]"/>
        </ul>
    </xsl:template>
    
    <xsl:template match="list/list">
        <xsl:apply-templates select="head"/>
        <ul class="{name()}"> 
            <xsl:apply-templates select="(*|text())[not(self::head)]"/>
        </ul>
    </xsl:template>
    
    <xsl:template match="list/label[following-sibling::item]">
        <li>
            <b>
                <xsl:apply-templates/>
            </b>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="following-sibling::item[1]/(*|text())"/>
        </li>
    </xsl:template>

    <xsl:template match="email[matches(normalize-space(string()), '^\S+@\S+\.\S+$')]">
        <a>
            <xsl:attribute name="href">
                <xsl:text>mailto:</xsl:text>
                <xsl:value-of select="normalize-space(string())"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </a>
    </xsl:template>
    
    <xsl:template match="term">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="fw">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="geo"><!-- Do not display geographical coordinates --></xsl:template>
    
    <xsl:template match="custodialHist">
        <h3>
            <xsl:copy-of select="bod:standardText('Custodial History')"/>
        </h3>
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="custEvent">
        <div class="{name()}">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="custEvent/label">
        <h4>
            <xsl:apply-templates/>
        </h4>
    </xsl:template>

    <xsl:template match="@xml:*"></xsl:template>

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
