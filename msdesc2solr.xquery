module namespace bod="http://www.bodleian.ox.ac.uk/bdlss";
import module namespace functx = "http://www.functx.com" at "functx.xquery";
import module namespace lang = "http://www.bodleian.ox.ac.uk/bdlss/lang" at "languages.xquery";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";

(:~
 : --------------------------------
 : Function Library for TEI catalogues
 : --------------------------------

 : This library is for useful generic functions (date handling, language code lookups, etc)
 : and functions specific to building the Solr files for specific indexes, but likely to be 
 : shared across multiple TEI catalogues  
 :
:)


declare variable $bod:disablelogging as xs:boolean external := false();

declare variable $bod:nonwordregex as xs:string external := concat('["', "\s'\-\[\]\(\)\{\}]");
declare variable $bod:wordregex as xs:string external := concat('[^"', "\s'\-\[\]\(\)\{\}]");
declare variable $bod:yearregex as xs:string external := "\-?\d\d\d\d";


(:~
 : --------------------------------
 : Generic helper functions
 : --------------------------------
:)


declare function bod:logging($level, $msg, $values)
{
    if (not($bod:disablelogging)) then
        (: Trick XQuery into doing trace() to output message to STDERR but not insert it into the XML :)
        substring(trace('', concat(upper-case($level), '	', $msg, '	', string-join($values, '	'), '	')), 0, 0)
    else ()
};


declare function bod:ordinal($num as xs:integer) as xs:string
{
    (: TODO: Reimplement this using modulo to do 22nd, 31st, 101st, 211th, etc :)
    switch($num)
        case 1 return "st"
        case 2 return "nd"
        case 3 return "rd"
        case 21 return "st"
        case 22 return "nd"
        case 23 return "rd"
        default return "th"
};


declare function bod:shortenToNearestWord($stringval as xs:string, $tolength as xs:integer) as xs:string
{
    let $cutoffat as xs:integer := $tolength - 1
    let $nsstringval as xs:string := normalize-space($stringval)
    
    return if (string-length($nsstringval) le $tolength) then
        (: Already short enough, so return unmodified :)
        $nsstringval
    else if (substring($nsstringval, $cutoffat, 1) = (' ', '&#9;', '&#10;')) then
        (: The cut-off is at the location of some whitespace, so won't be cutting off any words :)
        concat(normalize-space(substring($nsstringval, 1, $cutoffat)), '…')
    else if (substring($nsstringval, $tolength, 1) = (' ', '&#9;', '&#10;')) then
        (: The cut-off is at the end of a word, so won't be cutting off any words :)
        concat(substring($nsstringval, 1, $cutoffat), '…')
    else
        (: The cut-off is in the middle of a word, so return everything up to the preceding word :)
        concat(replace(substring($nsstringval, 1, $cutoffat), '\s\S*$', ''), '…')
};


declare function bod:formatCentury($centuryNum as xs:integer) as xs:string
{
    (: Converts century in number form (negative integers for BCE, positive integers for CE) into human-readable form :)
    if ($centuryNum gt 0) then
        concat($centuryNum, bod:ordinal($centuryNum), ' Century')
    else
        concat(abs($centuryNum), bod:ordinal(abs($centuryNum)), ' Century BCE')
};


declare function bod:findCenturies($earliestYear as xs:string*, $latestYear as xs:string*) as xs:string*
{
    (: Converts a year range into a sequence of century names.
       Input parametes are strings containing four-digit years (e.g. "0050", "0500", "1500")
       BCE dates should be prefixed with a minus (e.g. "-0100")
       For single years, pass it as first param and an empty string for the second, or both. :)

    (: Zero below stands for null, as there is no Year 0 :)
    let $ey as xs:double := number(functx:if-empty($earliestYear, 0))
    let $ly as xs:double := number(functx:if-empty($latestYear, 0))
    
    let $earliestIsTurnOfCentury as xs:boolean := ends-with($earliestYear, '00')
    let $latestIsTurnOfCentury as xs:boolean := ends-with($latestYear, '00')
    
    (: Convert years to centuries. Special cases required for turn-of-the-century years, e.g. 1500 AD is treated 
       as 16th century if at the start of a range, or the only known year, but as 15th if at the end of a range; 
       while 200 BC is treated as 3rd century BCE if at the end of a range but as 2nd BCE at the start. :)
    let $earliestCentury as xs:integer := xs:integer(
        if (string($ey) eq 'NaN') then
            (0)
        else if ($ey gt 0 and $earliestIsTurnOfCentury) then 
            ($ey div 100) + 1
        else if ($ey lt 0) then
            floor($ey div 100)
        else 
            ceiling($ey div 100)
        )      
    let $latestCentury as xs:integer := xs:integer(
        if (string($ly) eq 'NaN') then
            (0)
        else if ($ly lt 0 and $latestIsTurnOfCentury) then 
            ($ly div 100) - 1
        else if ($ly lt 0) then
            floor($ly div 100)
        else 
            ceiling($ly div 100)
        )

    return    
        if ($ey gt $ly and $ly ne 0) then
            bod:logging('info', 'Date range not valid', concat($earliestYear, '-', $latestYear))
            
        else if ($earliestCentury ne 0 and $latestCentury ne 0) then
            (: A date range, something like "After 1400 and before 1650", so fill in all the possible centuries between :)
            for $century in (-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21)
                return
                    if ($century ge $earliestCentury and $century le $latestCentury) then
                        bod:formatCentury($century)
                    else
                        ()
         else if ($earliestCentury ne 0 or $latestCentury ne 0) then
            (: Only a single date, either a precise year or an open-ended range like "Before 1500" or "After 1066", so just output the known century :)
            bod:formatCentury(($earliestCentury, $latestCentury)[. ne 0])
         else
            bod:logging('info', 'Unreadable dates', concat($earliestYear, '-', $latestYear))
};

declare function bod:summarizeDates($teinodes as element()*) as xs:string?
{
    let $years := 
        for $date in $teinodes/(@when|@notBefore|@notAfter|@from|@to)/normalize-space()
            return functx:get-matches($date, $bod:yearregex)[1]
    let $earliestYear := min($years)
    let $latestYear := max($years)
    let $centuries := 
        if (string-length($earliestYear) gt 0 and string-length($latestYear) gt 0) then 
            bod:findCenturies($earliestYear, $latestYear)
        else if (string-length($earliestYear) gt 0) then 
            bod:findCenturies($earliestYear, '')
        else if (string-length($latestYear) gt 0) then 
            bod:findCenturies('', $latestYear) 
        else ()
    return
    if (count($centuries) eq 0) then
        ()
    else if (count($centuries) eq 1) then
        $centuries[1]
    else
        concat($centuries[1], ' – ', $centuries[count($centuries)])
};

declare function bod:personRoleLookup($role as xs:string) as xs:string
{
    let $lcrole := lower-case($role)
    return
    if ($lcrole eq 'author') then
        "Author"
    else if ($lcrole eq 'editor') then
        "Editor"
    else if ($lcrole eq 'subject') then
        "Subject of a work"
    else if (string-length($role) eq 3) then
        (: Expecting three-char MARC relator codes. Merge and rename 
           some special cases, but otherwise lookup label. :)
        if ($lcrole = ('fmo', 'sgn', 'dnr')) then
            "Owner, signer, or donor"
        else if ($lcrole = ('dte', 'pat')) then
            "Commissioner, dedicatee, or patron"
        else if ($lcrole eq 'bsl') then
            "Stationer or bookseller"
        else
            let $relator as xs:string := bod:roleLookupMarcCode($lcrole)
            return if ($relator ne '') then $relator else concat('Unknown role code: ', $lcrole)
    else
        (: Anything else, assume it is a label, and display as-is, except capitalized :)
        functx:capitalize-first($role)
};

declare function bod:personRoleLookup2($role as xs:string) as xs:string
{
    (: Same as previous function but without merging and renaming of special cases, which originated with the Medieval catalogue :)
    let $lcrole := lower-case($role)
    return
    if ($lcrole eq 'author') then
        "Author"
    else if ($lcrole eq 'editor') then
        "Editor"
    else if ($lcrole eq 'subject') then
        "Subject of a work"
    else if (string-length($role) eq 3) then
        (: Expecting three-char MARC relator codes. Lookup label. :)
        let $relator as xs:string := bod:roleLookupMarcCode($lcrole)
        return if ($relator ne '') then $relator else concat('Unknown role code: ', $lcrole)
    else
        (: Anything else, assume it is a label, and display as-is, except capitalized :)
        functx:capitalize-first($role)
};

declare function bod:roleLookupMarcCode($rolecode as xs:string) as xs:string
{
    (: This is the MARC Code List for Relators standard, copy taken on 2018-06-22 from http://id.loc.gov/vocabulary/relators.tsv :)
    switch (lower-case($rolecode))
        case 'abr' return "Abridger"
        case 'acp' return "Art copyist"
        case 'act' return "Actor"
        case 'adi' return "Art director"
        case 'adp' return "Adapter"
        case 'aft' return "Author of afterword or colophon"
        case 'anl' return "Analyst"
        case 'anm' return "Animator"
        case 'ann' return "Annotator"
        case 'ant' return "Bibliographic antecedent"
        case 'ape' return "Appellee"
        case 'apl' return "Appellant"
        case 'app' return "Applicant"
        case 'aqt' return "Author in quotations or text abstracts"
        case 'arc' return "Architect"
        case 'ard' return "Artistic director"
        case 'arr' return "Arranger"
        case 'art' return "Artist"
        case 'asg' return "Assignee"
        case 'asn' return "Associated name"
        case 'ato' return "Autographer"
        case 'att' return "Attributed name"
        case 'auc' return "Auctioneer"
        case 'aud' return "Author of dialog"
        case 'aui' return "Author of introduction"
        case 'aus' return "Screenwriter"
        case 'aut' return "Author"
        case 'bdd' return "Binding designer"
        case 'bjd' return "Bookjacket designer"
        case 'bkd' return "Book designer"
        case 'bkp' return "Book producer"
        case 'blw' return "Blurb writer"
        case 'bnd' return "Binder"
        case 'bpd' return "Bookplate designer"
        case 'brd' return "Broadcaster"
        case 'brl' return "Braille embosser"
        case 'bsl' return "Bookseller"
        case 'cas' return "Caster"
        case 'ccp' return "Conceptor"
        case 'chr' return "Choreographer"
        case 'cli' return "Client"
        case 'cll' return "Calligrapher"
        case 'clr' return "Colorist"
        case 'clt' return "Collotyper"
        case 'cmm' return "Commentator"
        case 'cmp' return "Composer"
        case 'cmt' return "Compositor"
        case 'cnd' return "Conductor"
        case 'cng' return "Cinematographer"
        case 'cns' return "Censor"
        case 'coe' return "Contestant-appellee"
        case 'col' return "Collector"
        case 'com' return "Compiler"
        case 'con' return "Conservator"
        case 'cor' return "Collection registrar"
        case 'cos' return "Contestant"
        case 'cot' return "Contestant-appellant"
        case 'cou' return "Court governed"
        case 'cov' return "Cover designer"
        case 'cpc' return "Copyright claimant"
        case 'cpe' return "Complainant-appellee"
        case 'cph' return "Copyright holder"
        case 'cpl' return "Complainant"
        case 'cpt' return "Complainant-appellant"
        case 'cre' return "Creator"
        case 'crp' return "Correspondent"
        case 'crr' return "Corrector"
        case 'crt' return "Court reporter"
        case 'csl' return "Consultant"
        case 'csp' return "Consultant to a project"
        case 'cst' return "Costume designer"
        case 'ctb' return "Contributor"
        case 'cte' return "Contestee-appellee"
        case 'ctg' return "Cartographer"
        case 'ctr' return "Contractor"
        case 'cts' return "Contestee"
        case 'ctt' return "Contestee-appellant"
        case 'cur' return "Curator"
        case 'cwt' return "Commentator for written text"
        case 'dbp' return "Distribution place"
        case 'dfd' return "Defendant"
        case 'dfe' return "Defendant-appellee"
        case 'dft' return "Defendant-appellant"
        case 'dgg' return "Degree granting institution"
        case 'dgs' return "Degree supervisor"
        case 'dis' return "Dissertant"
        case 'dln' return "Delineator"
        case 'dnc' return "Dancer"
        case 'dnr' return "Donor"
        case 'dpc' return "Depicted"
        case 'dpt' return "Depositor"
        case 'drm' return "Draftsman"
        case 'drt' return "Director"
        case 'dsr' return "Designer"
        case 'dst' return "Distributor"
        case 'dtc' return "Data contributor"
        case 'dte' return "Dedicatee"
        case 'dtm' return "Data manager"
        case 'dto' return "Dedicator"
        case 'dub' return "Dubious author"
        case 'edc' return "Editor of compilation"
        case 'edm' return "Editor of moving image work"
        case 'edt' return "Editor"
        case 'egr' return "Engraver"
        case 'elg' return "Electrician"
        case 'elt' return "Electrotyper"
        case 'eng' return "Engineer"
        case 'enj' return "Enacting jurisdiction"
        case 'etr' return "Etcher"
        case 'evp' return "Event place"
        case 'exp' return "Expert"
        case 'fac' return "Facsimilist"
        case 'fds' return "Film distributor"
        case 'fld' return "Field director"
        case 'flm' return "Film editor"
        case 'fmd' return "Film director"
        case 'fmk' return "Filmmaker"
        case 'fmo' return "Former owner"
        case 'fmp' return "Film producer"
        case 'fnd' return "Funder"
        case 'fpy' return "First party"
        case 'frg' return "Forger"
        case 'gis' return "Geographic information specialist"
        case 'his' return "Host institution"
        case 'hnr' return "Honoree"
        case 'hst' return "Host"
        case 'ill' return "Illustrator"
        case 'ilu' return "Illuminator"
        case 'ins' return "Inscriber"
        case 'inv' return "Inventor"
        case 'isb' return "Issuing body"
        case 'itr' return "Instrumentalist"
        case 'ive' return "Interviewee"
        case 'ivr' return "Interviewer"
        case 'jud' return "Judge"
        case 'jug' return "Jurisdiction governed"
        case 'lbr' return "Laboratory"
        case 'lbt' return "Librettist"
        case 'ldr' return "Laboratory director"
        case 'led' return "Lead"
        case 'lee' return "Libelee-appellee"
        case 'lel' return "Libelee"
        case 'len' return "Lender"
        case 'let' return "Libelee-appellant"
        case 'lgd' return "Lighting designer"
        case 'lie' return "Libelant-appellee"
        case 'lil' return "Libelant"
        case 'lit' return "Libelant-appellant"
        case 'lsa' return "Landscape architect"
        case 'lse' return "Licensee"
        case 'lso' return "Licensor"
        case 'ltg' return "Lithographer"
        case 'lyr' return "Lyricist"
        case 'mcp' return "Music copyist"
        case 'mdc' return "Metadata contact"
        case 'med' return "Medium"
        case 'mfp' return "Manufacture place"
        case 'mfr' return "Manufacturer"
        case 'mod' return "Moderator"
        case 'mon' return "Monitor"
        case 'mrb' return "Marbler"
        case 'mrk' return "Markup editor"
        case 'msd' return "Musical director"
        case 'mte' return "Metal-engraver"
        case 'mtk' return "Minute taker"
        case 'mus' return "Musician"
        case 'nrt' return "Narrator"
        case 'opn' return "Opponent"
        case 'org' return "Originator"
        case 'orm' return "Organizer"
        case 'osp' return "Onscreen presenter"
        case 'oth' return "Other"
        case 'own' return "Owner"
        case 'pan' return "Panelist"
        case 'pat' return "Patron"
        case 'pbd' return "Publishing director"
        case 'pbl' return "Publisher"
        case 'pdr' return "Project director"
        case 'pfr' return "Proofreader"
        case 'pht' return "Photographer"
        case 'plt' return "Platemaker"
        case 'pma' return "Permitting agency"
        case 'pmn' return "Production manager"
        case 'pop' return "Printer of plates"
        case 'ppm' return "Papermaker"
        case 'ppt' return "Puppeteer"
        case 'pra' return "Praeses"
        case 'prc' return "Process contact"
        case 'prd' return "Production personnel"
        case 'pre' return "Presenter"
        case 'prf' return "Performer"
        case 'prg' return "Programmer"
        case 'prm' return "Printmaker"
        case 'prn' return "Production company"
        case 'pro' return "Producer"
        case 'prp' return "Production place"
        case 'prs' return "Production designer"
        case 'prt' return "Printer"
        case 'prv' return "Provider"
        case 'pta' return "Patent applicant"
        case 'pte' return "Plaintiff-appellee"
        case 'ptf' return "Plaintiff"
        case 'pth' return "Patent holder"
        case 'ptt' return "Plaintiff-appellant"
        case 'pup' return "Publication place"
        case 'rbr' return "Rubricator"
        case 'rcd' return "Recordist"
        case 'rce' return "Recording engineer"
        case 'rcp' return "Addressee"
        case 'rdd' return "Radio director"
        case 'red' return "Redaktor"
        case 'ren' return "Renderer"
        case 'res' return "Researcher"
        case 'rev' return "Reviewer"
        case 'rpc' return "Radio producer"
        case 'rps' return "Repository"
        case 'rpt' return "Reporter"
        case 'rpy' return "Responsible party"
        case 'rse' return "Respondent-appellee"
        case 'rsg' return "Restager"
        case 'rsp' return "Respondent"
        case 'rsr' return "Restorationist"
        case 'rst' return "Respondent-appellant"
        case 'rth' return "Research team head"
        case 'rtm' return "Research team member"
        case 'sad' return "Scientific advisor"
        case 'sce' return "Scenarist"
        case 'scl' return "Sculptor"
        case 'scr' return "Scribe"
        case 'sds' return "Sound designer"
        case 'sec' return "Secretary"
        case 'sgd' return "Stage director"
        case 'sgn' return "Signer"
        case 'sht' return "Supporting host"
        case 'sll' return "Seller"
        case 'sng' return "Singer"
        case 'spk' return "Speaker"
        case 'spn' return "Sponsor"
        case 'spy' return "Second party"
        case 'srv' return "Surveyor"
        case 'std' return "Set designer"
        case 'stg' return "Setting"
        case 'stl' return "Storyteller"
        case 'stm' return "Stage manager"
        case 'stn' return "Standards body"
        case 'str' return "Stereotyper"
        case 'tcd' return "Technical director"
        case 'tch' return "Teacher"
        case 'ths' return "Thesis advisor"
        case 'tld' return "Television director"
        case 'tlp' return "Television producer"
        case 'trc' return "Transcriber"
        case 'trl' return "Translator"
        case 'tyd' return "Type designer"
        case 'tyg' return "Typographer"
        case 'uvp' return "University place"
        case 'vac' return "Voice actor"
        case 'vdg' return "Videographer"
        case 'wac' return "Writer of added commentary"
        case 'wal' return "Writer of added lyrics"
        case 'wam' return "Writer of accompanying material"
        case 'wat' return "Writer of added text"
        case 'wdc' return "Woodcutter"
        case 'wde' return "Wood engraver"
        case 'win' return "Writer of introduction"
        case 'wit' return "Witness"
        case 'wpr' return "Writer of preface"
        case 'wst' return "Writer of supplementary textual content"
        default return bod:logging('warn', 'Unknown role code', $rolecode)
};


declare function bod:orgRoleLookup($role as xs:string) as xs:string
{
    (: For the moment, using the same roles as persons. But could add organization-specific ones here. :)
    let $normalizedRole := bod:personRoleLookup($role)
    return $normalizedRole
};


declare function bod:physFormLookup($form as xs:string) as xs:string
{
    switch(lower-case($form))
        case 'concertina_book' return 'Concertina book'
        case 'concertina__book' return 'Concertina book'
        case 'rolled_book' return 'Rolled book'
        case 'palm_leaf' return 'Palm leaf'
        case 'modern_notebook' return 'Modern notebook'
        case 'printed_book' return 'Printed book'
        default return functx:capitalize-first($form)
};


declare function bod:isLeadingStopWord($word as xs:string*) as xs:boolean
{
    let $result := switch(lower-case($word))
        case 'the' return true()
        case 'a' return true()
        case 'an' return true()
        case 'le' return true()
        case 'la' return true()
        case 'les' return true()
        case 'l' return true()
        case 'il' return true()
        case 'li' return true()
        case 'der' return true()
        case 'die' return true()
        case 'das' return true()
        case 'al' return true()
        default return false()
    return $result
};


declare function bod:isStopWord($word as xs:string) as xs:boolean
{
    let $result := switch(lower-case($word))
        case 'and' return true()
        case 'of' return true()
        case 'for' return true()
        default return bod:isLeadingStopWord($word)
    return $result
};


declare function bod:stripStopWords($string as xs:string) as xs:string
{
    let $tokens := tokenize($string, "[ ']")
    let $stopwordsfound := distinct-values(for $token in $tokens return if (bod:isStopWord($token)) then $token else ())
    return if (count($stopwordsfound) gt 0) then 
        let $pattern := concat("(", string-join($stopwordsfound, "|"), ")[ ']")
        return replace($string, $pattern, "", "i") 
    else $string    
};

declare function bod:stripLeadingStopWordsOld($string as xs:string) as xs:string
{
    let $tokens := tokenize($string, "[ ']")
    return if (bod:isLeadingStopWord($tokens[1])) then replace($string, "^.+?[ ']", "", "i") else $string
};

declare function bod:stripLeadingStopWords($string as xs:string) as xs:string
{
    let $tokens := tokenize($string, $bod:nonwordregex)[string-length(.) gt 0]
    return if (bod:isLeadingStopWord($tokens[1])) then replace($string, concat('^(', $bod:nonwordregex, '*)', $bod:wordregex, '+', $bod:nonwordregex, '+'), '$1') else $string
};

declare function bod:alphabetizeTitle($string as xs:string) as xs:string
{
    let $firstLetter := functx:capitalize-first(substring(replace(bod:stripLeadingStopWords($string), '[^\p{L}|\p{N}]+', ''), 1, 1))
    return $firstLetter
};


declare function bod:alphabetize($string as xs:string) as xs:string
{
    let $firstLetter := functx:capitalize-first(substring(replace($string, '[^\p{L}|\p{N}]+', ''), 1, 1))
    return $firstLetter
};


declare function bod:pathFromCollections($fullpath as xs:string) as xs:string
{
    let $relativepath as xs:string := substring-after($fullpath, 'collections/')
    return $relativepath
};

declare function bod:italicizeTitles($elem as element()) as xs:string
{
    normalize-space(
        string-join(
            for $x in $elem//(text()|tei:title|tei:ref[@target and matches(@target, '^(#|http)')])
                return
                if ($x/self::tei:title and not($x/ancestor::tei:ref[@target and matches(@target, '^(#|http)')]) and not($x/parent::tei:ref[@target and matches(@target, '^(#|http)')])) then
                    concat('&lt;i&gt;', normalize-space(string-join($x//text())), '&lt;/i&gt;')
                else if ($x/self::tei:ref[@target and matches(@target, '^(#|http)')]) then
                    let $link as xs:string := 
                        concat('&lt;a href="',
                            if (starts-with($x/@target, '#')) then 
                             concat('/catalog/', substring-after($x/@target/string(), '#'), '"&gt;')
                            else
                                concat($x/@target/string(), '" target="_blank"&gt;')
                            , normalize-space(string-join($x//text()))
                            , '&lt;/a&gt;'
                        )
                    return
                    if ($x/tei:title or $x/parent::tei:title) then
                        concat('&lt;i&gt;', $link, '&lt;/i&gt;')
                    else
                        $link
                else if (not($x/ancestor::tei:title) and not($x/ancestor::tei:ref[@target and matches(@target, '^(#|http)')])) then
                    $x
                else
                    ()
        , '')
    )
};

declare function bod:latLongDecimal2DMS($lat as xs:double, $long as xs:double) as xs:string*
{
    for $coord at $pos in ($lat, $long)
        let $direction := if ($pos eq 1) then (if ($coord lt 0) then 'S' else 'N') else (if ($coord lt 0) then 'W' else 'E')
        let $abscoord := abs($coord)
        let $wholedegrees := floor($abscoord)
        let $remainder := $abscoord - $wholedegrees
        let $minutes := $remainder * 60
        let $wholeminutes := floor($minutes)
        let $remainder2 := $minutes - $wholeminutes
        let $wholeseconds := round($remainder2 * 60)
        let $wholeminutes := if ($wholeseconds eq 60) then $wholeminutes + 1 else $wholeminutes
        let $wholeseconds := if ($wholeseconds eq 60) then 0 else $wholeseconds
        let $wholeminutes := if ($wholeminutes eq 60) then 0 else $wholeminutes
        return concat($wholedegrees, '° ', $wholeminutes, "' ", $wholeseconds, '" ', $direction)
};

declare function bod:lookupAuthorityName($name as xs:string) as xs:string
{
    switch(upper-case($name))
        case 'VIAF' return "VIAF: Virtual International Authority File (authority record)"
        case 'LC' return "Library of Congress (authority record)"
        case 'BNF' return "Bibliothèque nationale de France (authority record)"
        case 'SUDOC' return "SUDOC: Système Universitaire de Documentation (authority record)"
        case 'GND' return "GND: Gemeinsame Normdatei (authority record)"
        case 'TGN' return "Getty Thesaurus of Geographic Names® Online (authority record)"
        case 'ISNI' return "ISNI: International Standard Name Identifier (authority record)"
        default return $name
};


declare function bod:shelfmarkVariants($shelfmarks as xs:string*) as xs:string*
{
    let $variants := distinct-values(($shelfmarks, for $shelfmark in $shelfmarks return replace($shelfmark, '\.\s+', ' ')))
    return $variants
};



(:~
 : --------------------------------
 : TEI-to-Solr field mapping functions
 : --------------------------------
:)

declare function bod:one2one_TESTING($teinode as element()*, $solrfield as xs:string)
{
    (: Use this when debugging to find which TEI elements thought to be only exist once per document are actually multiple.
       Hence either many2one or many2many should be used, or the XPath changed to select only one.  :)
    let $value as xs:string := normalize-space(string-join($teinode[1]//text(), ' '))
    return if (count($teinode) lt 2) then
        if (string-length($value) gt 0) then
            <field name="{ $solrfield }">{ $value }</field>
        else
            ()
    else
        bod:logging('error', concat(count($teinode), ' elements found when only one expected for ', $solrfield), bod:pathFromCollections(base-uri($teinode[1])))
};


declare function bod:one2one($teinode as element()?, $solrfield as xs:string)
{
    (: One TEI element maps to a single Solr field :)
    let $value as xs:string := normalize-space(string-join($teinode//text(), ' '))
    return if (string-length($value) gt 0) then
        <field name="{ $solrfield }">{ $value }</field>
    else
        ()
};


declare function bod:one2one($teinode as element()?, $solrfield as xs:string, $ifnone as xs:string)
{
    (: Overload the same function above to handle when nothing is found in the source TEI. Third param should be either a default value to use instead, or 'error' to prevent indexing. :)
    let $result := bod:one2one($teinode, $solrfield)
    return if (count($result) eq 0) then
        if (lower-case($ifnone) eq 'error') then
            bod:logging('error', 'No values for mandatory field', $solrfield)
        else
            <field name="{ $solrfield }">{ $ifnone }</field>
    else
        $result
};


declare function bod:many2one($teinodes as element()*, $solrfield as xs:string)
{
    (: Concatenate a sequence of TEI elements, into a single Solr field :)
    let $values as xs:string* := $teinodes/string-join(.//text(), ' ')
    return if (not(empty($values))) then
        <field name="{ $solrfield }">{ normalize-space(string-join(distinct-values($values), ' ')) }</field>  
    else
        ()
};


declare function bod:many2one($teinodes as element()*, $solrfield as xs:string, $ifnone as xs:string)
{
    (: Overload the same function above to handle when nothing is found in the source TEI. Third param should be either a default value to use instead, or 'error' to prevent indexing. :)
    let $result := bod:many2one($teinodes, $solrfield)
    return if (count($result) eq 0) then
        if (lower-case($ifnone) eq 'error') then
            bod:logging('error', 'No values for mandatory field', $solrfield)
        else
            <field name="{ $solrfield }">{ $ifnone }</field>
    else
        $result
};


declare function bod:many2many($teinodes as element()*, $solrfield as xs:string)
{
    (: Generate multiple Solr fields, one for each distinct value from a sequence of TEI elements :)
    let $values as xs:string* := for $n in $teinodes return normalize-space(string-join($n//text()))
    for $v in distinct-values($values)
        return
            if (string-length($v) > 0) then
                <field name="{ $solrfield }">{ $v }</field>
            else ()
};


declare function bod:many2many($teinodes as element()*, $solrfield as xs:string, $ifnone as xs:string)
{
    (: Overload the same function above to handle when nothing is found in the source TEI. Third param should be either a default value to use instead, or 'error' to prevent indexing. :)
    let $result := bod:many2many($teinodes, $solrfield)
    return if (count($result) eq 0) then
        if (lower-case($ifnone) eq 'error') then
            bod:logging('error', 'No values for mandatory field', $solrfield)
        else
            <field name="{ $solrfield }">{ $ifnone }</field>
    else
        $result
};

declare function bod:string2one($value as xs:string, $solrfield as xs:string)
{
    (: Generate a Solr field from a string :)
    let $result := normalize-space($value)
    return if (string-length($result) gt 0) then
        <field name="{ $solrfield }">{ $result }</field>
    else
        ()
};

declare function bod:strings2many($values as xs:string*, $solrfield as xs:string)
{
    (: Generate multiple Solr fields, one for each distinct value from a sequence of strings :)
    for $v in distinct-values(for $s in $values return normalize-space($s))
        return
            if (string-length($v) > 0) then
                <field name="{ $solrfield }">{ $v }</field>
            else ()
};


declare function bod:oneoranother2one($teinodes as element()*, $solrfield as xs:string)
{
    (: Accepts a sequence of teinodes and uses the first matching one with content to populate a single Solr field :)
    (: TODO: Test this, and maybe use it for ms_institution_s, so that Christ Church College's manuscripts are included in Medieval? :)
    let $result := bod:many2many($teinodes, $solrfield)
    return $result[1]
};


declare function bod:trueIfExists($teinode as element()*, $solrfield as xs:string)
{
    (: Return true/false Solr field depending on presence of a TEI field :)
    let $exists as xs:boolean := exists($teinode)
    return if ($exists = true()) then
        <field name="{ $solrfield }">true</field>
    else
        <field name="{ $solrfield }">false</field>
};


declare function bod:dateEarliest($teinodes as element()*, $solrfield as xs:string)
{
    (: Find the earliest date of all TEI date/origDate fields passed to it :)
    let $dates := $teinodes[string(number(@notBefore)) != 'NaN']/@notBefore
    return if (empty($dates)) then
        ()
    else
        <field name="{ $solrfield }">{ min($dates) }</field>
};


declare function bod:dateLatest($teinodes as element()*, $solrfield as xs:string)
{
    (: Find the latest date of all TEI date/origDate fields passed to it :)
    let $dates := $teinodes[string(number(@notAfter)) != 'NaN']/@notAfter
    return if (empty($dates)) then
        ()
    else
        <field name="{ $solrfield }">{ max($dates) }</field>
};


declare function bod:centuries($teinodes as element()*, $solrfield as xs:string)
{
    (: Convert TEI date files into one Solr field for each century covered by 
       the year or year-range specified in @when/@notAfter/@NotBefore attributes :)
    let $centuries := distinct-values(
        for $date in $teinodes
            return
            if ($date[@when]) then 
                if (matches($date/@when/data(), $bod:yearregex)) then
                    bod:findCenturies(functx:get-matches($date/@when/data(), $bod:yearregex)[1], '')
                else
                    bod:logging('info', 'Unreadable date', $date[@when]/data())
            else if ($date[@notBefore] or $date[@notAfter]) then
                if (matches($date/@notBefore/data(), $bod:yearregex) or matches($date/@notAfter/data(), $bod:yearregex)) then
                    bod:findCenturies(functx:get-matches($date/@notBefore/data(), $bod:yearregex)[1], functx:get-matches($date/@notAfter/data(), $bod:yearregex)[1])
                else
                    bod:logging('info', 'Unreadable dates', concat($date/@notBefore/data(), '-', $date/@notAfter/data()))
            else if ($date[@from] or $date[@to]) then
                if (matches($date/@from/data(), $bod:yearregex) or matches($date/@to/data(), $bod:yearregex)) then
                    bod:findCenturies(functx:get-matches($date/@from/data(), $bod:yearregex)[1], functx:get-matches($date/@to/data(), $bod:yearregex)[1])
                else
                    bod:logging('info', 'Unreadable dates', concat($date/@from/data(), '-', $date/@to/data()))
            else
                ()
        )
    return 
        (
        for $century in $centuries
        order by $century
        return if (string-length($century) gt 0) then <field name="{ $solrfield }">{ $century }</field> else ()
        ,
        if (count($centuries) gt 1) then <field name="{ $solrfield }">Multiple Centuries</field> else ()
        )
};


declare function bod:centuries($teinodes as element()*, $solrfield as xs:string, $ifnone as xs:string)
{
    (: Overload the same function above to handle when nothing is found in the source TEI. Third param should be either a 
       default value to use instead, or 'error' to prevent indexing. :)
    let $result := bod:centuries($teinodes, $solrfield)
    return if (count($result) eq 0) then
        if (lower-case($ifnone) eq 'error') then
            bod:logging('error', 'No values for mandatory field', $solrfield)
        else
            <field name="{ $solrfield }">{ $ifnone }</field>
    else
        $result
};


declare function bod:materials($teinodes as element()*, $solrfield as xs:string)
{
    let $materials := distinct-values($teinodes/string(@material))
    return 
        (
        for $item in $materials
        let $material := (
            switch ($item)
                case "perg" return "Parchment"
                case "chart" return "Paper"
                case "paper" return "Paper"
                case "papyrus" return "Papyrus"
                case "mixed" return "Mixed"
                case "unknown" return "Unknown"
                default return "Other"
                )
        return <field name="{ $solrfield }">{ $material }</field>
        ,
        (: Add "Mixed" for manuscripts containing multiple materials, not just the ones catalogued as "mixed" :)
        if (count($materials[not(. eq 'mixed')]) gt 1) then <field name="{ $solrfield }">Mixed</field> else ()
        )
};


declare function bod:materials($teinodes as element()*, $solrfield as xs:string, $ifnone as xs:string)
{
    (: Overload the same function above to handle when nothing is found in the source TEI. Third param should be either a 
       default value to use instead, or 'error' to prevent indexing. :)
    let $result := bod:materials($teinodes, $solrfield)
    return if (count($result) eq 0) then
        if (lower-case($ifnone) eq 'error') then
            bod:logging('error', 'No values for mandatory field', $solrfield)
        else
            <field name="{ $solrfield }">{ $ifnone }</field>
    else
        $result
};


declare function bod:languages($teinodes as element()*, $solrfield as xs:string)
{
    let $langCodes := distinct-values(for $attr in $teinodes/@* return if (name($attr) = 'mainLang' or name($attr) = 'otherLangs') then tokenize($attr, ' ') else ())
    return
        (
        for $code in $langCodes
        return <field name="{ $solrfield }">{ normalize-space(lang:languageCodeLookup($code)) }</field>
        ,
        if (count($langCodes) gt 1) then <field name="{ $solrfield }">Multiple Languages</field> else ()
        )
};


declare function bod:languages($teinodes as element()*, $solrfield as xs:string, $ifnone as xs:string)
{
    (: Overload the same function above to handle when nothing is found in the source TEI. Third param should be either a 
       default value to use instead, or 'error' to prevent indexing. :)
    let $result := bod:languages($teinodes, $solrfield)
    return if (count($result) eq 0) then
        if (lower-case($ifnone) eq 'error') then
            bod:logging('error', 'No values for mandatory field', $solrfield)
        else
            <field name="{ $solrfield }">{ $ifnone }</field>
    else
        $result
};

declare function bod:languageCodeLookup($lang as xs:string) as xs:string
{
    lang:languageCodeLookup($lang)
};

declare function bod:physForm($teinodes as element()*, $solrfield as xs:string)
{
    for $form in distinct-values($teinodes/@form)
        return <field name="{ $solrfield }">{ bod:physFormLookup($form) }</field>
};


declare function bod:physForm($teinodes as element()*, $solrfield as xs:string, $ifnone as xs:string)
{
    (: Overload the same function above to handle when nothing is found in the source TEI. Third param should be either a default value to use instead, or 'error' to prevent indexing. :)
    let $result := bod:physForm($teinodes, $solrfield)
    return if (count($result) eq 0) then
        if (lower-case($ifnone) eq 'error') then
            bod:logging('error', 'No values for mandatory field', $solrfield)
        else
            <field name="{ $solrfield }">{ $ifnone }</field>
    else
        $result
};

declare function bod:digitized($teinodes as element()*, $solrfield as xs:string)
{
    (: This function returns 1 or 3 Solr fields:
            ms_digitized_s is the 'Digital facsimile online' facet on the web site, including digitized images hosted anywhere
            ms_digbod_sm is the UUID on Digital Bodleian, to be used to create links back to the catalogue from there
            ms_digbod_b is a boolean field which is true if there is at least one Digital Bodleian UUID
    :)
    let $uuids as xs:string* := 
        for $dburl in $teinodes/tei:ref/@target[matches(., '(digital|iiif)\.bodleian\.ox\.ac\.uk')]
            let $matchinguuids := tokenize($dburl, '/')[matches(., '\w{8}\-\w{4}\-4\w{3}\-\w{4}\-\w{12}')][1]
            return
            if (count($matchinguuids) eq 1) then 
                $matchinguuids[1]
            else
                bod:logging('warn', 'Invalid Digital Bodleian URL', $dburl)
    return (
    <field name="ms_digitized_s">
        { 
        if ($teinodes[@type=('digital-fascimile','digital-facsimile') and @subtype='full']) then 'Yes' 
        else if ($teinodes[@type=('digital-fascimile','digital-facsimile') and @subtype='partial']) then 'Selected pages only' 
        else 'No'
        }
    </field>,
    if (count($uuids) gt 0) then
        <field name="ms_digbod_b">true</field>
    else
        ()
    ,
    for $uuid in distinct-values($uuids)
        return
        <field name="ms_digbod_sm">{ $uuid }</field>
    )
};




(:~
 : --------------------------------
 : Manuscript HTML view
 : --------------------------------
:)


declare function bod:displayHTML($htmldoc as document-node(), $solrfield as xs:string)
{
    let $htmlcontent := ($htmldoc//html:div)[1]
    return <field name="{ $solrfield }">{ normalize-space(serialize($htmlcontent)) }</field>
};


declare function bod:indexHTML($htmldoc as document-node(), $solrfield as xs:string)
{
    (: Only index text nodes which aren't between 'ni' processing instructions, which are added by msdesc2html.xsl 
       to prevent indexing of common headings and labels, like "History", that cause every manuscript to match queries
       containing those words. :)
    let $htmlcontent := ($htmldoc//html:div)[1]
    return <field name="{ $solrfield }">{ normalize-space(string-join($htmlcontent//text()[count(preceding::processing-instruction('ni')) mod 2 = 0])) } </field>
};

