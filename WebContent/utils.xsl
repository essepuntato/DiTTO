<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet SYSTEM "entities.dtd">
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:g="http://graphml.graphdrawing.org/xmlns"
    xmlns:y="http://www.yworks.com/xml/graphml"
    xmlns:utls="http://www.essepuntato.it/graffoo/utils"
    xmlns:rtf="http://www.essepuntato.it/graffoo/resultTreeFragment/"
    xmlns:cnfg="http://www.essepuntato.it/graffoo/configuration/">
 
    <xsl:import href="config.xsl"/>
    

    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                General purpose utils
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    
    <!-- chars to format the output -->
    <xsl:variable name="newline" as="xs:string"><xsl:text>&newline;</xsl:text></xsl:variable>
    <xsl:variable name="tab" as="xs:string"><xsl:text>&tab;</xsl:text></xsl:variable>
    
    <!-- owl:Thing superclass automatically generated -->
    <xsl:variable name="owl-thing" as="node()">
        <xsl:element name="&class;" namespace="{$rtf-namespace}">
            <xsl:attribute name="name">&owl-thing;</xsl:attribute>
            <xsl:attribute name="auto-generated"/>
        </xsl:element>
    </xsl:variable>
    
    
    <!-- document element of initial graphml file (to access xml nodes from functions) -->
    <xsl:variable name="root" as="node()" select="/"/>
    
    <!-- the name of the graphml file under translation -->
    <xsl:variable name="current-graphml-filename" as="xs:string" 
        select="tokenize(document-uri($root),'/')[last()]"/>
    
    <!-- annotation property <graffoo:hasAppearance> -->
    <xsl:variable name="has-appearance-property" as="xs:string"
        select="utls:bracket-iri(concat($graffoo-prefix/@uri, 'hasAppearance'))"/>

    <!--
        INPUT
            uri: an URI
        OUTPUT
            a string obtained from uri and usable like filename
            Example: <http://www.example.com/my_ontology.owl> becomes http-www-example-com-my-ontology-owl 
    -->
    <!--<xsl:function name="utls:uri-to-filename" as="xs:string">
        <xsl:param name="uri" as="xs:string"/>
        <xsl:sequence select="replace(replace($uri,'(^&lt;)|(&gt;$)',''),'[^a-zA-Z0-9]+','-')"/>
    </xsl:function>-->


    <!--
        INPUT
            str: a string
        OUTPUT
            str enclosed in double quote and with internal double quote chars escaped.
            Examples: <possible "string"> input string becomes <"possible \"string\"">
    -->
    <xsl:function name="utls:transform-to-literal-string" as="xs:string?">
        <xsl:param name="str" as="xs:string?"/>
        <xsl:sequence select="if (exists($str)) then 
            concat('&quot;',replace($str,'&quot;','\\&quot;'),'&quot;') else ()"/>
    </xsl:function>
    
    
    <!--
        INPUT
            string: a string
        OUTPUT
            the string with regex private chars escaped with "\" character
        NOTE
            function from http://www.xsltfunctions.com/
    -->
    <xsl:function name="utls:escape-for-regex" as="xs:string?">
        <xsl:param name="string" as="xs:string?"/>
        <xsl:sequence select="replace($string, '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))', '\\$1')"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            str: a string of white space separated ids
            ids: a sequence of IDs
        OUTPUT
            check if str contains any of ids
    -->
    <xsl:function name="utls:contains-id" as="xs:boolean">
        <xsl:param name="str" as="xs:string?"/>
        <xsl:param name="ids" as="xs:string*"/>
        
        <xsl:sequence select="some $id in $ids satisfies matches($str,concat('(^|\s)',$id,'(\s|$)'))"/>
    </xsl:function>
    
    <!--
        INPUT
            str: a string of white space separated ids
            ids: a sequence of IDs
        OUTPUT
            insert each ID of ids in str (only if absent)
    -->
    <xsl:function name="utls:add-ids" as="xs:string">
        <xsl:param name="str" as="xs:string"/>
        <xsl:param name="ids" as="xs:string*"/>
        
        <xsl:variable name="not-contained-ids" as="xs:string*" select="for $id in $ids
            return if (utls:contains-id($str,$id)) then () else $id"/>
        
        <xsl:sequence select="string-join(($str,$not-contained-ids),' ')"/>
    </xsl:function>
    
    <!--
        INPUT
            str: a string of white space separated ids
            ids: a sequence of IDs
        OUTPUT
            remove ids from str if present
    -->
    <xsl:function name="utls:remove-ids" as="xs:string">
        <xsl:param name="str" as="xs:string"/>
        <xsl:param name="ids" as="xs:string*"/>
        
        <xsl:variable name="ids" as="xs:string*" select="tokenize($str,' ')"/>
        <xsl:variable name="filtered-ids" as="xs:string*" select="for $item in $ids
            return if (not($item = $ids)) then $item else ()"/>
        <xsl:sequence select="string-join($filtered-ids,' ')"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            str: a Manchester string
            prefixes: a list of prefixes
        OUTPUT
            check if str uses one or more prefix in prefixes
    -->
    <xsl:function name="utls:contains-prefixes" as="xs:boolean">
        <xsl:param name="str" as="xs:string"/>
        <xsl:param name="prefixes" as="xs:string+"/>
        <xsl:sequence select="some $prefix in $prefixes satisfies if ($prefix eq '') then 
            not(contains($str,':')) else matches($str,concat('[^a-zA-Z0-9]*', $prefix, ':'))"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            entity: a node representing an entity
            axiom: a node representing an axiom
        OUTPUT
            the univocal ID of entity after the punning caused by axiom
    -->
    <xsl:function name="utls:generate-punned-entity-id" as="xs:string">
        <xsl:param name="entity" as="node()"/>
        <xsl:param name="axiom" as="node()"/>
        
        <xsl:sequence select="concat($entity/@id,'-punning-',$axiom/@id)"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            entity-name: the name of an'entity
            type: the generic type of the entity (for example "class" for both simple classes and 
                class restrictions)
        OUTPUT
            the entity's real type (for example "class" or "class-restriction")
    -->
    <xsl:function name="utls:get-entity-real-type" as="xs:string">
        <xsl:param name="entity-name" as="xs:string"/>
        <xsl:param name="type" as="xs:string"/>
        
        <xsl:sequence select="
            if ($type = ('&class;','&class-restriction;')) then 
            (if (contains($entity-name,' ')) then '&class-restriction;' else '&class;') 
            else if ($type = ('&datarange;','&datarange-restriction;')) then 
            (if (contains($entity-name,' ')) then '&datarange-restriction;' else '&datarange;') 
            else $type"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            str: the name of an axiom
        OUTPUT
            search str between synonyms of OWL 2 axioms (config.xml) and return a XML node that defines:
            1) the axiom (if there's a matching the corresponding Manchester axiom, else str)
            2) a boolean indicating if the axiom is an OWL axiom
            3) if the axiom is an OWL axiom, the domain and range types for that axiom (to punning)
    -->
    <xsl:function name="utls:search-for-manchester-axiom" as="node()">
        <xsl:param name="str" as="xs:string"/>
        
        <!-- search the corresponding OWL2 axiom's node in config.xml (case-insensitive) --> 
        <xsl:variable name="owl2-axiom" as="node()?" select="$owl2-axioms/cnfg:axiom
            [lower-case($str) = (lower-case(@name),cnfg:synonym)]"/>
        
        <!-- result node -->
        <xsl:variable name="result" as="node()">
            <xsl:element name="axiom" namespace="{$rtf-namespace}">
                <xsl:choose>
                    
                    <!-- an OWL2 axiom has been found in config.xml -->
                    <xsl:when test="exists($owl2-axiom)">
                        <xsl:attribute name="name" select="$owl2-axiom/@manchester"/>
                        <xsl:attribute name="owl-axiom"/>
                        <xsl:attribute name="domain-type" select="$owl2-axiom/@domain"/>
                        <xsl:attribute name="range-type" select="$owl2-axiom/@range"/>
                    </xsl:when>
                    
                    <!-- ther's no OWL2 axiom corresponding to $str -->
                    <xsl:otherwise>
                        <xsl:attribute name="name" select="$str"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:variable>
        
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    
    <!--
        INPUT
            str: the name of an imported ontology in the form "IRI version-IRI"
        OUPTUT
            the IRI to use in the Import clause (which value will be returned is determined 
            by "use-imported-ontology-version-iri in config.xsl)
    -->
    <xsl:function name="utls:get-imported-ontology-iri" as="xs:string">
        <xsl:param name="str" as="xs:string?"/>
        <xsl:sequence select="if ($use-imported-ontology-version-iri) then
            utls:get-ontology-version-iri($str) else utls:get-ontology-general-iri($str)"/>
    </xsl:function>
    
    <!--
        INPUT
            str: str: the name of an imported ontology in the form "IRI version-IRI"
        OUTPUT
            the first IRI
    -->
    <xsl:function name="utls:get-ontology-general-iri" as="xs:string">
        <xsl:param name="str" as="xs:string?"/>
        
        <xsl:choose>
            
            <xsl:when test="empty($str)">
                <xsl:sequence select="$default-ontology-iri"/>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:sequence select="tokenize(normalize-space($str),'\s')[1]"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    <!--
        INPUT
            str: str: the name of an imported ontology in the form "IRI version-IRI"
        OUTPUT
            the version-IRI if it exists, else the first IRI (general IRI)
    -->
    <xsl:function name="utls:get-ontology-version-iri" as="xs:string">
        <xsl:param name="str" as="xs:string"/>
        
        <xsl:variable name="iris" as="xs:string+" select="tokenize(normalize-space($str),'\s')"/>
        <xsl:sequence select="if (exists($iris[2])) then $iris[2] else $iris[1]"/>
    </xsl:function>
    
    
    <!--
        INPUT
            iri: an IRI
        OUTPUT
            iri enclosed in angular brackets
    -->
    <xsl:function name="utls:bracket-iri" as="xs:string">
        <xsl:param name="iri" as="xs:string"/>
        <xsl:sequence select="concat('&lt;',$iri,'&gt;')"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            rule: a SWRL (Semantic Web Rule Language) rule
        OUTPUT
            the rule adapted to Manchester syntax (each ?x param is translate to ?<urn:swrl#x>
            like in Protégé)
    -->
    <xsl:function name="utls:swrl-to-manchester" as="xs:string">
        <xsl:param name="rule" as="xs:string"/>
        <xsl:sequence select="replace($rule, '\? ([^ \s \) ,]+)', '?&lt;urn:swrl#$1&gt;', 'x')"/>
    </xsl:function>
    
    
    <!--
        INPUT
            language: the name of a rule language (example: sparql)
        OUTPUT
            the IRI that defines "has<Lang>Rule" annotation property for that language
    -->
    <xsl:function name="utls:get-has-lang-rule-iri" as="xs:string">
        <xsl:param name="language" as="xs:string"/>
        
        <xsl:variable name="lowercase-language" as="xs:string" select="lower-case($language)"/>
        
        <!-- capitalize the language's first letter -->
        <xsl:variable name="language-capitalize" as="xs:string" select="concat(
            upper-case(substring($lowercase-language,1,1)),substring($lowercase-language,2))"/>
        
        <!-- local name "has<Lang>Rule" -->
        <xsl:variable name="local-name" as="xs:string"
            select="concat('has',$language-capitalize,'Rule')"/>
        
        <xsl:variable name="iri" as="xs:string" 
            select="concat($graffoo-prefix/@uri,$local-name)"/>
        
        <xsl:sequence select="utls:bracket-iri($iri)"/>
    </xsl:function>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                Analyze Manchester strings
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    <!-- in 5th partial transformation occurs the recognition of entities from Manchester
        strings. By this way the user can omit the explicit declaration with Graffoo widgets 
        of all the entities used in restrictions and additional axioms -->
    <!-- See http://www.w3.org/TR/owl2-manchester-syntax/ -->
    
    
    <!-- Manchester characters and keywords -->
    <xsl:variable name="manchester-separator" as="xs:string+" select="
        '(', ')', '[', ']', '{', '}', ',', '^^'"/>
    <xsl:variable name="manchester-boolean-operators" as="xs:string+" select="
        'not', 'and', 'or'"/>
    <xsl:variable name="manchester-restriction-keywords" as="xs:string+" select="
        'that', 'some', 'only', 'value', 'Self', 'min', 'max', 'exactly'"/>
    <xsl:variable name="manchester-object-property-keywords" as="xs:string+" select="
        'inverse', 'o'"/>
    <xsl:variable name="manchester-datarange-facets" as="xs:string+" select="
        'length', 'minLength', 'maxLength', 'pattern', 'langRange', '&lt;', '&lt;=', '&gt;', '&gt;='"/>
    <xsl:variable name="manchester-characteristics" as="xs:string+" select="
        'Functional', 'InverseFunctional', 'Reflexive', 'Irreflexive', 'Symmetric', 'Asymmetric', 'Transitive'"/>
    
    <xsl:variable name="manchester-keywords" as="xs:string+" select="
        $manchester-separator, $manchester-boolean-operators, $manchester-restriction-keywords, 
        $manchester-object-property-keywords, $manchester-datarange-facets, $manchester-characteristics"/>
    <xsl:variable name="manchester-statement" as="xs:string" select="':$'"/>
    
    
    <!-- possible contexts used during the recognition of entities -->
    <xsl:variable name="final-contexts" as="xs:string+" select="
        'datarange', 'class', 'object-property', 'data-property', 'annotation-property', 'individual'"/>
    <xsl:variable name="non-final-contexts" as="xs:string+" select="
        'description', 'property', 'enumeration', 'facts', 'symbolic-context'"/>
        
    
    <!--
        INPUT
            manchester-string: a Manchester string
            context: a string representing current context
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
                (if true entities not recognized become object properties)
        OUTPUT
            xml nodes representing the entities recognized from Manchester string
    -->
    <xsl:function name="utls:get-entities-from-manchester-string" as="node()*">
        <xsl:param name="manchester-string" as="xs:string"/>
        <xsl:param name="context" as="xs:string"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <!-- replace string literals with empty strings -->
        <xsl:variable name="manchester-without-complex-strings" as="xs:string" 
            select="replace($manchester-string, '&quot; ([^&quot;] | \\ &quot;)* [^\\] &quot;', '&quot;&quot;', 'x')"/>
        
        <!-- decompose the Manchester string into tokens -->
        <xsl:variable name="tokens" as="xs:string*" select="
            tokenize(normalize-space(replace(replace($manchester-without-complex-strings, 
            (: &lt; and &gt; in datatype restriction :) '([ \[ , ]) \s? ( &lt;= | &gt;= | [ &lt; &gt; ] )', ' $1 $2 ', 'x'),
            (: any other separator :) '([ \( \) \[ \] \{ \} , ] | \^\^ )', ' $1 ', 'x')), ' ')"/>
        
        <!-- analyze the tokens -->
        <xsl:sequence select="utls:scan-manchester-tokens($context, (), $tokens[1], $tokens[position() gt 1], 
            $rtf, $ontology-id, $is-last-scan)"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            context: the current context
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
        OUTPUT
            xml nodes representing the entities recognized from Manchester string
    -->
    <xsl:function name="utls:scan-manchester-tokens" as="node()*">
        <xsl:param name="context" as="xs:string*"/>
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:if test="exists($token)">
            
            <!-- update context according to the current context and token -->
            <xsl:variable name="updated-context" as="xs:string*" select="utls:update-context($context, $token)"/>

            <!-- determine the type of the current token -->
            <xsl:variable name="token-type" as="xs:string">
                <xsl:choose>
                    
                    <!-- not entity (Manchester keyword, literal or separator) -->
                    <xsl:when test="utls:is-not-an-entity-token($token)">
                        <xsl:sequence select="'not-entity'"/>
                    </xsl:when>
                    
                    <!-- datarange -->
                    <xsl:when test="utls:is-a-datarange-token($updated-context, $previous-tokens, 
                        $token, $next-tokens, $rtf, $ontology-id, $is-last-scan)">
                        <xsl:sequence select="'datarange'"/>
                    </xsl:when>
                    
                    <!-- individual -->
                    <xsl:when test="utls:is-an-individual-token($updated-context, $previous-tokens, 
                        $token, $next-tokens, $rtf, $ontology-id, $is-last-scan)">
                        <xsl:sequence select="'individual'"/>
                    </xsl:when>
                    
                    <!-- class -->
                    <xsl:when test="utls:is-a-class-token($updated-context, $previous-tokens, 
                        $token, $next-tokens, $rtf, $ontology-id, $is-last-scan)">
                        <xsl:sequence select="'class'"/>
                    </xsl:when>
                    
                    <!-- object property -->
                    <xsl:when test="utls:is-an-object-property-token($updated-context, $previous-tokens, 
                        $token, $next-tokens, $rtf, $ontology-id, $is-last-scan)">
                        <xsl:sequence select="'object-property'"/>
                    </xsl:when>
                    
                    <!-- data property -->
                    <xsl:when test="utls:is-a-data-property-token($updated-context, $previous-tokens, 
                        $token, $next-tokens, $rtf, $ontology-id, $is-last-scan)">
                        <xsl:sequence select="'data-property'"/>
                    </xsl:when>
                    
                    <!-- annotation property -->
                    <xsl:when test="utls:is-an-annotation-property-token($updated-context, $previous-tokens, 
                        $token, $next-tokens, $rtf, $ontology-id, $is-last-scan)">
                        <xsl:sequence select="'annotation-property'"/>
                    </xsl:when>
                    
                    <!-- entity not recognized -->
                    <xsl:otherwise>
                        <xsl:sequence select="'not-recognized'"/>
                    </xsl:otherwise>
                    
                </xsl:choose>
            </xsl:variable>
            
            
            <!-- if current token is or can be an entity, create a corresponding XML node -->
            <xsl:if test="$token-type ne 'not-entity'">
                <xsl:element name="{$token-type}" namespace="{$rtf-namespace}">
                    <xsl:attribute name="name" select="$token"/>
                    <xsl:attribute name="ontology-id" select="$ontology-id"/>
                </xsl:element>
            </xsl:if>
            
            <!-- recursive call on the next token -->
            <xsl:sequence select="utls:scan-manchester-tokens($updated-context, ($previous-tokens, $token), $next-tokens[1], 
                $next-tokens[position() gt 1], $rtf, $ontology-id, $is-last-scan)"/>
        </xsl:if>
    </xsl:function>



    <!--
        INPUT
            token: a token of a Manchester string
        OUTPUT
            check if token is a Manchester keyword or a literal, i.e. if it is not an entity
    -->
    <xsl:function name="utls:is-not-an-entity-token" as="xs:boolean">
        <xsl:param name="token" as="xs:string?"/>
        <xsl:sequence select="($token = $manchester-keywords) or 
            matches($token, $manchester-statement) or utls:is-a-literal-token($token)"/>
    </xsl:function>
    
    <!--
        INPUT
            token: a token of a Manchester string
        OUTPUT
            check if token is a literal string
    -->
    <xsl:function name="utls:is-a-literal-token" as="xs:boolean">
        <xsl:param name="token" as="xs:string?"/>
        <xsl:sequence select="
            (: string literal or typed literal :) matches($token, '^ &quot; .* &quot; ( \^\^.+ | @.+ )? $', 'x') or
            (: number literal :) matches($token, '^ (\+|\-)? [0-9\.]+ ( (e|E)(\+|\-)?[0-9\.]+ )? (f|F)? $', 'x') or
            (: boolean literal :) $token = ('true', 'false')"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            context: a stack of contexts
            token: a token of a Manchester string
        OUTPUT
            update the context according to last context and the token
    -->
    <xsl:function name="utls:update-context" as="xs:string*">
        <xsl:param name="context" as="xs:string*"/>
        <xsl:param name="token" as="xs:string"/>
        
        <!-- if the current token is a Manchester statement and there are more than one
            context (first context is always the main context), close last context -->
        <xsl:variable name="closed-context" as="xs:string*" select="if (count($context) gt 1 and 
            matches($token, $manchester-statement)) then $context[position() lt last()] else $context"/>
        
        <xsl:choose>
            
            <!-- main Manchester statements: reset old context -->
            
            <xsl:when test="$token eq 'Datatype:'">
                <xsl:sequence select="'datarange'"/>
            </xsl:when>
            <xsl:when test="$token = ('Class:', 'EquivalentClasses:', 'DisjointClasses:')">
                <xsl:sequence select="'class'"/>
            </xsl:when>
            <xsl:when test="$token eq 'ObjectProperty:'">
                <xsl:sequence select="'object-property'"/>
            </xsl:when>
            <xsl:when test="$token eq 'DataProperty:'">
                <xsl:sequence select="'data-property'"/>
            </xsl:when>
            <xsl:when test="$token eq 'AnnotationProperty:'">
                <xsl:sequence select="'annotation-property'"/>
            </xsl:when>
            <xsl:when test="$token = ('Individual:', 'SameIndividual:', 'DifferentIndividuals:')">
                <xsl:sequence select="'individual'"/>
            </xsl:when>
            <xsl:when test="$token = ('EquivalentProperties:', 'DisjointProperties:')">
                <xsl:sequence select="'homogeneous-property'"/>
            </xsl:when>
            
            
            <!-- secondary Manchester statements: conserve old context -->
            
            <!-- annotation property -->
            <xsl:when test="$token eq 'Annotations:'">
                <xsl:sequence select="$closed-context, 'annotation-property'"/>
            </xsl:when>
            
            <!-- datarange -->
            <xsl:when test="$closed-context[last()] eq 'datarange' and $token eq 'EquivalentTo:'">
                <xsl:sequence select="$closed-context, 'datarange'"/>
            </xsl:when>
            
            <!-- class -->
            <xsl:when test="$closed-context[last()] eq 'class' and 
                $token = ('SubClassOf:', 'EquivalentTo:', 'DisjointWith:', 'DisjointUnionOf:')">
                <xsl:sequence select="$closed-context, 'description'"/>
            </xsl:when>
            <xsl:when test="$token eq 'HasKey:'">
                <xsl:sequence select="$closed-context, 'property'"/>
            </xsl:when>
            
            <!-- object property -->
            <xsl:when test="$closed-context[last()] eq 'object-property' and 
                $token = ('SubPropertyOf:', 'EquivalentTo:', 'DisjointWith:', 'InverseOf:', 'SubPropertyChain:')">
                <xsl:sequence select="$closed-context, 'object-property'"/>
            </xsl:when>
            <xsl:when test="$closed-context[last()] eq 'object-property' and 
                $token = ('Domain:', 'Range:')">
                <xsl:sequence select="$closed-context, 'description'"/>
            </xsl:when>
            
            <!-- data property -->
            <xsl:when test="$closed-context[last()] eq 'data-property' and 
                $token = ('SubPropertyOf:', 'EquivalentTo:', 'DisjointWith:')">
                <xsl:sequence select="$closed-context, 'data-property'"/>
            </xsl:when>
            <xsl:when test="$closed-context[last()] eq 'data-property' and 
                $token eq 'Domain:'">
                <xsl:sequence select="$closed-context, 'description'"/>
            </xsl:when>
            <xsl:when test="$closed-context[last()] eq 'data-property' and 
                $token eq 'Range:'">
                <xsl:sequence select="$closed-context, 'datarange'"/>
            </xsl:when>
            
            <!-- annotation property -->
            <xsl:when test="$closed-context[last()] eq 'annotation-property' and 
                $token eq 'SubPropertyOf:'">
                <xsl:sequence select="$closed-context, 'annotation-property'"/>
            </xsl:when>
            
            <!-- individual -->
            <xsl:when test="$token eq 'Types:'">
                <xsl:sequence select="$closed-context, 'description'"/>
            </xsl:when>
            <xsl:when test="$token eq 'Facts:'">
                <xsl:sequence select="$closed-context, 'facts'"/>
            </xsl:when>
            <xsl:when test="$token = ('SameAs:', 'DifferentFrom:')">
                <xsl:sequence select="$closed-context, 'individual'"/>
            </xsl:when>
            
            
            <!-- brace: individual or literal enumeration -->
            <xsl:when test="$token = ('{', '}')">
                <xsl:sequence select="if ($token eq '{') then ($closed-context, 'enumeration') else 
                    $closed-context[position() lt last()]"/>
            </xsl:when>
            
            
            <!-- other Manchester statements like 'Characteristics:': symbolic context -->
            <xsl:when test="matches($token, $manchester-statement)">
                <xsl:sequence select="$closed-context, 'symbolic-context'"/>
            </xsl:when>

            
            <!-- anything else: context not modified -->
            <xsl:otherwise>
                <xsl:sequence select="$context"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    
    <!-- default OWL dataranges -->
    <xsl:variable name="default-dataranges" as="xs:string+" select="
        'integer', 'decimal', 'float', 'string', $owl2-default-datatypes"/>
    
    <!--
        INPUT
            context: the current context
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
        OUTPUT
            check if token represents a datarange
    -->
    <xsl:function name="utls:is-a-datarange-token" as="xs:boolean">
        <xsl:param name="context" as="xs:string*"/>
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:sequence select="
            (: default datarange :) ($token = $default-dataranges) or
            
            (: context requires a datarange :) ($context[last()] eq 'datarange') or
            
            (: this token identify an existing datarange in this ontology :) 
            ($context[last()] eq 'description' and exists($rtf/rtf:datarange
                [@name eq $token][utls:contains-id(@ontology-id, $ontology-id)]))"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            context: the current context
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
        OUTPUT
            check if token represents a class
    -->
    <xsl:function name="utls:is-a-class-token" as="xs:boolean">
        <xsl:param name="context" as="xs:string*"/>
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:sequence select="
            (: context requires a class :) ($context[last()] eq 'class') or
            
            (: 'that' requires a class :) ($next-tokens[1] eq 'that') or
            
            (: this token identify an existing class in this ontology and context is ok :) 
            (exists($rtf/rtf:class[@name eq $token][utls:contains-id(@ontology-id, $ontology-id)])
                and $context[last()] eq 'description') or
                
            (: context is 'description', token isn't a property and is last scan :) 
            ($context[last()] eq 'description' and $is-last-scan and
                not($next-tokens[1] = $manchester-restriction-keywords[. ne 'that']))
            "/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            context: the current context
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
        OUTPUT
            check if token represents an object property
    -->
    <xsl:function name="utls:is-an-object-property-token" as="xs:boolean">
        <xsl:param name="context" as="xs:string*"/>
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:sequence select="
            (: context requires an object property :) ($context[last()] eq 'object-property') or
            
            (: inverse requires object property :) $previous-tokens[last()] eq 'inverse' or
            
            (: 'description' context :) ($context[last()] eq 'description' and (
            $next-tokens[1] eq 'Self' or ($next-tokens[1] eq 'value' and not(utls:is-a-literal-token($next-tokens[2]))) or
            ($next-tokens[1] = ('some', 'only', 'min', 'max', 'exactly') and utls:is-a-primary-token-set(
                $next-tokens[1], $next-tokens[2], $next-tokens[position() gt 2], $rtf, $ontology-id, $is-last-scan)))) or
            
            (: context is 'facts' and next token is neither empty nor ',' nor a Manchester statement nor a literal :)
            ($context[last()] eq 'facts' and not(empty($next-tokens[1]) or matches($next-tokens[1], 
                concat(',', '|', $manchester-statement)) or utls:is-a-literal-token($next-tokens[1]))) or
            
            (: context is 'homogeneous-property' and current token is surrounded by some object property and no data-property :)
            ($context[last()] eq 'homogeneous-property' and 
                utls:is-surrounded-by-typed-properties('object-property', $previous-tokens, $next-tokens, $rtf, $ontology-id) (:and
                not(utls:is-surrounded-by-typed-properties('data-property', $previous-tokens, $next-tokens, $rtf, $ontology-id)):)) or
            
            (: context is 'description', 'property' or 'homogeneous-property' and 
                current token identify an existing object property in this ontology :) 
            ($context[last()] = ('description', 'property', 'homogeneous-property') and exists(
                $rtf/(rtf:object-property | rtf:object-property-facility)
                [@name eq $token][utls:contains-id(@ontology-id, $ontology-id)])) or
                
            (: is last scan, context is 'description', 'property' or 'homogeneous-property' and 
                there's no homonymous data property in this ontology :) 
            ($is-last-scan and $context[last()] = ('description', 'property', 'homogeneous-property') and 
                empty($rtf/(rtf:data-property | rtf:data-property-facility)
                [@name eq $token][utls:contains-id(@ontology-id, $ontology-id)]))
            "/>
    </xsl:function>
    
    
    <!--
        INPUT
            context: the current context
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
        OUTPUT
            check if token represents a data property
    -->
    <xsl:function name="utls:is-a-data-property-token" as="xs:boolean">
        <xsl:param name="context" as="xs:string*"/>
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:sequence select="
            (: context requires a data property :) ($context[last()] eq 'data-property') or
            
            (: 'description' context :) ($context[last()] eq 'description' and (
            ($next-tokens[1] eq 'value' and utls:is-a-literal-token($next-tokens[2])) or
            ($next-tokens[1] = ('some', 'only', 'min', 'max', 'exactly') and utls:is-a-data-primary-token-set(
            $next-tokens[1], $next-tokens[2], $next-tokens[position() gt 2], $rtf, $ontology-id, $is-last-scan, 0)))) or
            
            (: context is 'facts' and next token is a literal :)
            ($context[last()] eq 'facts' and utls:is-a-literal-token($next-tokens[1])) or
            
            (: context is 'homogeneous-property' and current token is surrounded by some data property and no object property :)
            ($context[last()] eq 'homogeneous-property' and 
                utls:is-surrounded-by-typed-properties('data-property', $previous-tokens, $next-tokens, $rtf, $ontology-id) (:and
                not(utls:is-surrounded-by-typed-properties('object-property', $previous-tokens, $next-tokens, $rtf, $ontology-id)):)) or
            
            (: context is 'description', 'property' or 'homogeneous-property' and 
                current token identify an existing data property in this ontology :) 
            ($context[last()] = ('description', 'property', 'homogeneous-property') and exists(
                $rtf/(rtf:data-property | rtf:data-property-facility)[@name eq $token]
                [utls:contains-id(@ontology-id, $ontology-id)]))
            "/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            context: the current context
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
        OUTPUT
            check if token represents an annotation property
    -->
    <xsl:function name="utls:is-an-annotation-property-token" as="xs:boolean">
        <xsl:param name="context" as="xs:string*"/>
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:sequence select="
            (: current context is 'annotation-property' (and current token is not a literal) :)
            $context[last()] eq 'annotation-property'
            
            (: current token identify an existing annotation property in this ontology :) 
            (:exists($rtf/(rtf:annotation-property | rtf:annotation-property-facility)
                [@name eq $token][utls:contains-id(@ontology-id, $ontology-id)]):)
            "/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            context: the current context
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
        OUTPUT
            check if token represents an individual
    -->
    <xsl:function name="utls:is-an-individual-token" as="xs:boolean">
        <xsl:param name="context" as="xs:string*"/>
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:sequence select="
            (: context requires an individual :) $context[last()] eq 'individual' or
            
            (: previous token is 'value' (and current token is not a literal) :) 
            $previous-tokens[last()] eq 'value' or
            
            (: context is 'enumeration' (and current token isn't a literal) :)
            $context[last()] eq 'enumeration' or
            
            (: context is 'facts', next token is empty or ',' or another Manchester statement 
                and current token isn't a literal :)
            ($context[last()] eq 'facts' and (empty($next-tokens[1]) or matches($next-tokens[1], 
                concat(',', '|', $manchester-statement))) and not(utls:is-a-literal-token($token)))
            "/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
        OUTPUT
            check if token is in a primary 
            (http://www.w3.org/TR/owl2-manchester-syntax/#Descriptions)
    -->
    <xsl:function name="utls:is-a-primary-token-set" as="xs:boolean?">
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:variable name="is-a-data-primary-token-set" as="xs:boolean?" select="
            utls:is-a-data-primary-token-set($previous-tokens, $token, $next-tokens, 
            $rtf, $ontology-id, $is-last-scan, 0)"/>
        
        <xsl:choose>
            <xsl:when test="empty($is-a-data-primary-token-set) and not($is-last-scan)">
                <xsl:sequence select="()"/>
            </xsl:when>
            
            <xsl:when test="(empty($is-a-data-primary-token-set) and $is-last-scan) or
                not($is-a-data-primary-token-set)">
                <xsl:sequence select="true()"/>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    
    <!--
        INPUT
            previous-tokens: tokens already visited
            token: current token
            next-tokens: tokens not already visited
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
            num-open-bracket: number of open brackets encountered during the recursive analysis
        OUTPUT
            check if token is in a data primary 
            (http://www.w3.org/TR/owl2-manchester-syntax/#Descriptions)
    -->
    <xsl:function name="utls:is-a-data-primary-token-set" as="xs:boolean?">
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        <xsl:param name="num-open-bracket" as="xs:integer"/>
        
        <xsl:variable name="updated-num-open-bracket" as="xs:integer" select="$num-open-bracket +
            (if ($token eq '(') then 1 else if ($token eq ')') then -1 else 0)"/>
        
        <xsl:choose>
            <xsl:when test="empty($token) or $token eq ',' or matches($token, $manchester-statement) or
                ($token = ('and', 'or') and $updated-num-open-bracket le 0)">
                <xsl:sequence select="()"/>
            </xsl:when>
            
            <xsl:when test="$token = ($manchester-restriction-keywords, $manchester-object-property-keywords) or
                ($token eq '{' and not(utls:is-a-literal-token($next-tokens[1]))) or 
                $rtf/(rtf:class | rtf:individual)[utls:contains-id(@ontology-id, $ontology-id)][@name eq $token]">
                <xsl:sequence select="false()"/>
            </xsl:when>
            
            <xsl:when test="$token = ($manchester-datarange-facets, $default-dataranges) or
                (utls:is-a-literal-token($token) and not($previous-tokens[last()] = ('min', 'max', 'exactly'))) or
                $rtf/rtf:datarange[utls:contains-id(@ontology-id, $ontology-id)][@name eq $token]">
                <xsl:sequence select="true()"/>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:sequence select="utls:is-a-data-primary-token-set(($previous-tokens, $token), $next-tokens[1], 
                    $next-tokens[position() gt 1], $rtf, $ontology-id, $is-last-scan, $updated-num-open-bracket)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <!--
        INPUT
            property-type: the type of expected properties ('object-property' or 'data-property')
            previous-tokens: tokens on the left of current token
            next-tokens: tokens on the right of current token
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
        OUTPUT
            check if there's some property of property-type in previous or next tokens
    -->
    <xsl:function name="utls:is-surrounded-by-typed-properties" as="xs:boolean">
        <xsl:param name="property-type" as="xs:string"/>
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        
        <!-- check if there's a typed property both backward in previous tokens and forward in next tokens -->
        <xsl:sequence select="utls:is-followed-by-typed-properties($property-type, 
            $previous-tokens, 'backward', $rtf, $ontology-id) or utls:is-followed-by-typed-properties(
            $property-type, $next-tokens, 'forward', $rtf, $ontology-id)"/>
    </xsl:function>
    
    
    <!--
        INPUT
            property-type: the type of expected properties ('object-property' or 'data-property')
            tokens: tokens to analyze
            direction: direction to analyze tokens ('forward' or 'backward')
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
        OUTPUT
            check if there's some property of property-type tokens
    -->
    <xsl:function name="utls:is-followed-by-typed-properties" as="xs:boolean">
        <xsl:param name="property-type" as="xs:string"/>
        <xsl:param name="tokens" as="xs:string*"/>
        <xsl:param name="direction" as="xs:string"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        
        <!-- get next token -->
        <xsl:variable name="token" as="xs:string?" select="$tokens
            [if ($direction eq 'forward') then 1 else last()]"/>
        
        <xsl:choose>
            
            <!-- current token is empty or there are no more properties -->
            <xsl:when test="empty($token) or matches($token, $manchester-statement)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            
            <!-- there's an homonymous property of this type in current ontology -->
            <xsl:when test="$token ne ',' and $rtf/rtf:*[local-name() = (if ($property-type eq 'object-property') then 
                ('object-property', 'object-property-facility') else ('data-property', 'data-property-facility'))]
                [utls:contains-id(@ontology-id, $ontology-id)][@name eq $token]">
                <xsl:sequence select="true()"/>
            </xsl:when>
            
            <!-- else recursive call -->
            <xsl:otherwise>
                <xsl:sequence select="utls:is-followed-by-typed-properties($property-type, 
                    if ($direction eq 'forward') then $tokens[position() gt 1] else $tokens[position() lt last()], 
                    $direction, $rtf, $ontology-id)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    


    <!--
        INPUT
            manchester-string: a Manchester string
            rtf: the RTF representing the current partial transformation
        OUTPUT
            insert in 'min', 'max' and 'exactly' property restriction in manchester-string the 
            primary 'owl:Thing' and 'rdfs:Literal' if absent (the Manchester syntax doesn't require
            they're present, Protégé does)
    -->
    <xsl:function name="utls:check-primary-in-property-restriction" as="xs:string">
        <xsl:param name="manchester-string" as="xs:string"/>
        <xsl:param name="rtf" as="node()"/>
        
        <xsl:sequence select="utls:check-primary-in-property-restriction-aux(
            utls:check-primary-in-property-restriction-aux($manchester-string, 
            $rtf/(rtf:&object-property; | rtf:&object-property-facility;)/@name, 'object-property'), 
            $rtf/(rtf:&data-property; | rtf:&data-property-facility;)/@name, 'data-property')"/>
    </xsl:function>
    
    <xsl:function name="utls:check-primary-in-property-restriction-aux" as="xs:string">
        <xsl:param name="manchester-string" as="xs:string"/>
        <xsl:param name="properties" as="xs:string*"/>
        <xsl:param name="property-type" as="xs:string"/>

        <xsl:variable name="property" as="xs:string?" select="utls:escape-for-regex($properties[1])"/>
        
        <xsl:choose>
            <xsl:when test="empty($property) or $property eq ''">
                <xsl:sequence select="$manchester-string"/>
            </xsl:when>

            <xsl:otherwise>
                <xsl:sequence select="utls:check-primary-in-property-restriction-aux(
                    replace($manchester-string, concat('(', $property, '\s (min | max | exactly) \s [0-9]+) 
                        (\s? ([^:]+: \s | and | or | , | \) | $))'), concat('$1 ', if ($property-type eq 'object-property') 
                        then 'owl:Thing' else 'rdfs:Literal', '$3'),'x'),
                    $properties[position() gt 1], $property-type)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    Analyze SWRL rules
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->

    <!-- in 5th partial transformation, after the recognition of entities from Manchester
        strings, occurs the recognition of entities from SWRL rules. By this way the user
        can omit the explicit declaration with Graffoo widgets of all the entities used
        in restrictions and rules -->
    
    
    <!--
        INPUT
            swrl-rule: a string representing a SWRL rule
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
                (if true entities not recognized become object properties)
        OUTPUT
            xml nodes representing the entities recognized from SWRL rule
    -->
    <xsl:function name="utls:get-entities-from-swrl-rule" as="node()*">
        <xsl:param name="swrl-rule" as="xs:string"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <!-- replace string literals with empty strings -->
        <xsl:variable name="rule-without-complex-strings" as="xs:string" select="replace($swrl-rule, 
            '&quot; ([^&quot;] | \\ &quot;)* [^\\] &quot; (\^\^ [^ , \)]+)?', '&quot;&quot;', 'x')"/>
        
        <!-- decompose the rule into tokens -->
        <xsl:variable name="tokens" as="xs:string*" select="tokenize(normalize-space(replace(
            replace($rule-without-complex-strings, ', | \^ | \-&gt;', ' ', 'x'), '([ \( \) ])', ' $1 ', 'x')), ' ')"/>
        
        <xsl:sequence select="utls:scan-swrl-tokens((), $tokens[1], $tokens[position() gt 1], 
            $rtf, $ontology-id, $is-last-scan)"/>
    </xsl:function>
    
    
    <!-- regex matching a SWRL variable -->
    <xsl:variable name="swrl-variable" as="xs:string" select="'^\?'"/>
    
    
    <!--
        INPUT
            previous-tokens: tokens already analized
            token: current token
            next-tokens: tokens not already analized
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
            is-last-scan: a boolean indicating if this is the last scan
                (if true entities not recognized become object properties)
        OUTPUT
            analyzes recursively the SWRL tokens returning new XML nodes for each
            token recognized as entity
    -->        
    <xsl:function name="utls:scan-swrl-tokens" as="node()*">
        <xsl:param name="previous-tokens" as="xs:string*"/>
        <xsl:param name="token" as="xs:string?"/>
        <xsl:param name="next-tokens" as="xs:string*"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        <xsl:param name="is-last-scan" as="xs:boolean"/>
        
        <xsl:if test="exists($token)">
            
            <xsl:variable name="token-type" as="xs:string">
                <xsl:choose>
                    
                    <!-- literal, SWRL variable or bracket -->
                    <xsl:when test="utls:is-a-literal-token($token) or matches($token, $swrl-variable) or $token = ('(', ')')">
                        <xsl:sequence select="'not-entity'"/>
                    </xsl:when>
                    
                    
                    <!-- class -->
                    <xsl:when test="$next-tokens[1] eq '(' and $next-tokens[3] eq ')'">
                        <xsl:sequence select="'class'"/>
                    </xsl:when>
                    
                    
                    <!-- object property -->
                    <xsl:when test="
                        (: token must be a property (it has 2 params) :) 
                        $next-tokens[1] eq '(' and $next-tokens[4] eq ')' and (
                        
                        (: second param is an individual :) 
                        not(utls:is-a-literal-token($next-tokens[3]) or matches($next-tokens[3], $swrl-variable) or 
                            $next-tokens[3] = ('(', ')')) or
                        
                        (: second param is a variable used as an individual or by an object property :)
                        (matches($next-tokens[3], $swrl-variable) and utls:is-an-individual-swrl-variable($next-tokens[3], 
                            string-join(($previous-tokens, $token, $next-tokens), ' '), $rtf, $ontology-id)) or 
                        
                        (: there's an homonymous object property in current ontology :)
                        $rtf/(rtf:&object-property; | rtf:&object-property-facility;)
                            [utls:contains-id(@ontology-id, $ontology-id)][@name eq $token] or
                        
                        (: is last scan and there's not an homonymous data property in current ontology :)
                        ($is-last-scan and empty($rtf/(rtf:&data-property; | rtf:&data-property-facility;)
                            [utls:contains-id(@ontology-id, $ontology-id)][@name eq $token]))
                        )">
                        <xsl:sequence select="'object-property'"/>
                    </xsl:when>
                    
                    
                    <!-- data property -->
                    <xsl:when test="
                        (: token must be property (it has 2 params) :) 
                        $next-tokens[1] eq '(' and $next-tokens[4] eq ')' and (
                        
                        (: second param is a literal :) utls:is-a-literal-token($next-tokens[3]) or
                        
                        (: second param is a variable used by a data property :)
                        (matches($next-tokens[3], $swrl-variable) and utls:is-used-by-a-data-property($next-tokens[3], 
                            string-join(($previous-tokens, $token, $next-tokens), ' '), $rtf, $ontology-id)) or
                        
                        (: there's an homonymous data property in current ontology :)
                        $rtf/(rtf:&data-property; | rtf:&data-property-facility;)
                            [utls:contains-id(@ontology-id, $ontology-id)][@name eq $token]
                        )">
                        <xsl:sequence select="'data-property'"/>
                    </xsl:when>
                    
                    
                    <!-- individual -->
                    <xsl:when test="($previous-tokens[last()] eq '(' and $next-tokens[2] eq ')') or 
                        ($previous-tokens[last() -1] eq '(' and $next-tokens[1] eq ')')">
                        <xsl:sequence select="'individual'"/>
                    </xsl:when>
                    
                    
                    <!-- not recognized -->
                    <xsl:otherwise>
                        <xsl:sequence select="'not-recognized'"/>
                    </xsl:otherwise>
                    
                </xsl:choose>
            </xsl:variable>
            
            <!-- if current token is or can be an entity, create a corresponding XML node -->
            <xsl:if test="$token-type ne 'not-entity'">
                <xsl:element name="{$token-type}" namespace="{$rtf-namespace}">
                    <xsl:attribute name="name" select="$token"/>
                    <xsl:attribute name="ontology-id" select="$ontology-id"/>
                </xsl:element>
            </xsl:if>
            
            <!-- recursive call on the next token -->
            <xsl:sequence select="utls:scan-swrl-tokens(($previous-tokens, $token), $next-tokens[1], 
                $next-tokens[position() gt 1], $rtf, $ontology-id, $is-last-scan)"/>
            
        </xsl:if>
    </xsl:function>
    
    
    <!--
        INPUT
            token: a SWRL token
            swrl-rule: the SWRL rule
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
        OUTPUT
            check if the token is used in SWRL rule as an individual 
    -->
    <xsl:function name="utls:is-an-individual-swrl-variable" as="xs:boolean">
        <xsl:param name="token" as="xs:string"/>
        <xsl:param name="swrl-rule" as="xs:string"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        
        <xsl:variable name="escaped-token" as="xs:string" select="utls:escape-for-regex($token)"/>
        <xsl:sequence select="
            (: used as individual :) matches($swrl-rule, concat('[^\(\)\s]+ \( ', $escaped-token, ' ')) or
            (: used by an object property :) (some $object-property in 
                $rtf/(rtf:&object-property; | rtf:&object-property-facility;)[utls:contains-id(@ontology-id, $ontology-id)] 
                satisfies matches($swrl-rule, concat('(^| )', $object-property/@name, ' \( [^ ]+ ', $escaped-token, ' \)')))"/>
    </xsl:function>
    
    
    <!--
        INPUT
            token: a SWRL token
            swrl-rule: the SWRL rule
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
        OUTPUT
            check if the token is used in SWRL rule as 2nd param of a data property
            (it's not an individual)
    -->
    <xsl:function name="utls:is-used-by-a-data-property" as="xs:boolean">
        <xsl:param name="token" as="xs:string"/>
        <xsl:param name="swrl-rule" as="xs:string"/>
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        
        <xsl:variable name="escaped-token" as="xs:string" select="utls:escape-for-regex($token)"/>
        <xsl:sequence select="some $data-property in 
            $rtf/(rtf:&data-property; | rtf:&data-property-facility;)[utls:contains-id(@ontology-id, $ontology-id)] 
            satisfies matches($swrl-rule, concat('(^| )', $data-property/@name, ' \( [^ ]+ ', $escaped-token, ' \)'))"/>
    </xsl:function>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    Class hierarchies
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    

    <!--
        INPUT
            rtf: the RTF representing the current partial transformation
            ontology-id: the current ontology ID
        OUTPUT
            an XML node representing the different hiearchies of classes in ontology
            identified by ontology-id
    -->
    <xsl:function name="utls:split-root-classes-in-different-hierarchies" as="node()">
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="ontology-id" as="xs:string"/>
        
        <xsl:variable name="sub-class-axioms" as="node()*" 
            select="$rtf/rtf:&axiom;[@name eq '&subclassof-axiom;']"/>
        
        <xsl:variable name="root-classes" as="node()*" 
            select="$rtf/rtf:&class;[utls:contains-id(@ontology-id, $ontology-id)][@id (: auto generated classes excluded :)]
            [not(utls:contains-id(@id, $rtf/rtf:&axiom;[@name eq '&subclassof-axiom;']/@source-id))]"/>
        
        <xsl:variable name="disjoint-root-classes" as="node()*" 
            select="utls:disjoin-classes($sub-class-axioms, $root-classes, ())"/>
        
        <xsl:element name="class-hierarchies" namespace="{$rtf-namespace}">
            
            <!-- for each hierarchy represented by one root class, create a "hierarchy" element
                that contains all root classes that belong to it -->
            <xsl:for-each select="$disjoint-root-classes">
                <xsl:variable name="current-hierarchy" as="node()" select="current()"/>
                <xsl:element name="hierarchy" namespace="{$rtf-namespace}">
                    <xsl:attribute name="name" select="$current-hierarchy/@name"/>
                    
                    <!-- sort and insert all root classes that belong to current hiearchy -->
                    <xsl:for-each select="$root-classes">
                        <xsl:sort select="@name"/>
                        <xsl:variable name="current-class" as="node()" select="current()"/>
                        <xsl:if test="utls:are-in-same-hierarchy($sub-class-axioms, $current-class/@id, $current-hierarchy/@id)">
                            <xsl:copy-of select="$current-class"/>    
                        </xsl:if>
                    </xsl:for-each>
                    
                </xsl:element>

            </xsl:for-each>
        </xsl:element>
    </xsl:function>
    
    
    <!--
        INPUT
            sub-class-axioms: a list of subclassof axiom nodes
            classes: classes to analyze
            disjoint-classes: accumulator that memorize classes that belong to different hierarchies
        OUTPUT
            a list of disjoint classes
    -->
    <xsl:function name="utls:disjoin-classes" as="node()*">
        <xsl:param name="sub-class-axioms" as="node()*"/>
        <xsl:param name="classes" as="node()*"/>            <!-- classi da analizzare -->
        <xsl:param name="disjoint-classes" as="node()*"/>   <!-- accumulatore delle classi appartenenti a diverse gerarchie -->
        
        <xsl:sequence select="
            (: if there's no classes to analyze return disjoint-classes :)
            if (empty($classes)) then $disjoint-classes
            (: else recursive call on remainder classes  :)
            else utls:disjoin-classes($sub-class-axioms, remove($classes, 1),
                (: current class is memorized if it doesn't belong to any visited class' hiearchy :)
                if (some $class in $disjoint-classes satisfies utls:are-in-same-hierarchy($sub-class-axioms, $classes[1]/@id, $class/@id))
                    then $disjoint-classes else ($disjoint-classes, $classes[1]))
        "/>
    </xsl:function>
    
    
    <!--
        INPUT
            sub-class-axioms: a list of subclassof axiom nodes
            class1, class2: two classes in same ontology
        OUTPUT
            check if class1 and class2 are in same hiearchy
    -->
    <xsl:function name="utls:are-in-same-hierarchy" as="xs:boolean">
        <xsl:param name="sub-class-axioms" as="node()*"/>
        <xsl:param name="class1" as="xs:string"/>
        <xsl:param name="class2" as="xs:string"/>
        
        <xsl:sequence select="utls:is-class-reachable($sub-class-axioms, $class1, $class2, ())"/>
    </xsl:function>
    
    
    <!--
        INPUT
            sub-class-axioms: a list of subclassof axiom nodes
            source-classes: list of classes
            target-class: a class
            already-visited: accumulator of classes already visited
        OUTPUT
            check if target class is reachable from some source-classes
    -->
    <xsl:function name="utls:is-class-reachable" as="xs:boolean">
        <xsl:param name="sub-class-axioms" as="node()*"/>
        <xsl:param name="source-classes" as="xs:string*"/>
        <xsl:param name="target-class" as="xs:string"/>
        <xsl:param name="already-visited" as="xs:string*"></xsl:param>
        
        <xsl:choose>
            
            <xsl:when test="empty($source-classes)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            
            <xsl:when test="$source-classes = $target-class">
                <xsl:sequence select="true()"/>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:variable name="adiacent-classes-not-already-visited" as="xs:string*" select="
                    $sub-class-axioms[(@source-id, @target-id) = $source-classes]/(@target-id|@source-id)[not(. = $already-visited)]"/>
                
                <!-- recursive call -->
                <xsl:sequence select="utls:is-class-reachable($sub-class-axioms, $adiacent-classes-not-already-visited, 
                    $target-class, ($source-classes, $adiacent-classes-not-already-visited))"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    Manage graphml widgets
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    
    <!-- keys to identify the content-node of node/edge elements in graphml file -->
    <xsl:variable name="node-content" as="xs:string" 
        select="$root/g:graphml/g:key[@yfiles.type eq 'nodegraphics']/@id"/>
    <xsl:variable name="edge-content" as="xs:string" 
        select="$root/g:graphml/g:key[@yfiles.type eq 'edgegraphics']/@id"/>
    
    <!-- keys to identify the description-node of node/edge elements in graphml file -->
    <xsl:variable name="node-description" as="xs:string" 
        select="$root/g:graphml/g:key[@attr.name eq 'description'][@for eq 'node']/@id"/>
    <xsl:variable name="edge-description" as="xs:string" 
        select="$root/g:graphml/g:key[@attr.name eq 'description'][@for eq 'edge']/@id"/>
    
    
    <!-- 
        INPUT
            node: a g:node in GraphML graph
        OUTPUT
            check if node is a prefixes box Graffoo widget
    -->
    <xsl:function name="utls:is-a-prefixes-box" as="xs:boolean"> 
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:graph][g:data[@key eq $node-content]//y:GroupNode
            [y:State/@closed eq 'false'][contains(y:NodeLabel,'Prefixes')]]) then true() else false()"/>
    </xsl:function>
    
    <!--
        INPUT
            node: a g:node representing a prefixes box Graffoo widget
        OUTPUT
            return all the prefixes (without ":") from prefixes box
    -->
    <xsl:function name="utls:get-prefixes-from-prefixes-box" as="xs:string*">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="for $prefix in tokenize(normalize-space(
            $node/g:graph/g:node//y:NodeLabel[@fontStyle = 'bold']),'\s')
            return replace($prefix,':','')"/>
    </xsl:function>
    
    <!--
        INPUT
            node: a g:node representing a prefixes box Graffoo widget
        OUTPUT
            return all the URIs from prefixes box
    -->
    <xsl:function name="utls:get-uris-from-prefixes-box" as="xs:string*">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="tokenize(normalize-space(
            $node/g:graph/g:node//y:NodeLabel[@fontStyle = 'plain']),'\s')"/>
    </xsl:function>
    
    
    
    <!-- 
        INPUT
            node: a g:node in GraphML graph
        OUTPUT
            check if node is an ontology Graffoo widget
    -->    
    <xsl:function name="utls:is-an-ontology" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:graph]
            [g:data[@key eq $node-content]//y:BorderStyle/@type = 'dotted']) 
            then true() else false()"/>
    </xsl:function>
    
    <!-- 
        INPUT
            id: the ID of an ontology Graffoo widget
        OUTPUT
            return the ontology name from its ID (if id is the default id, return the default name)
    -->    
    <xsl:function name="utls:get-ontology-name-by-id" as="xs:string">
        <xsl:param name="id" as="xs:string"/>
        <xsl:sequence select="if ($id eq $default-ontology-id) then 
            $default-ontology-iri else utls:get-node-name($root//g:node[utls:contains-id(@id, $id)])"/>
    </xsl:function>
    
    <!-- 
        INPUT
            element: a node, edge or ontology in GraphML graph
        OUTPUT
            the id of which ontology that holds element (if element doesn't belong to any ontology, return
            the default ontology id)
    -->
    <xsl:function name="utls:ontology-membership" as="xs:string">
        <xsl:param name="element" as="node()"/>
        
        <xsl:choose>
            
            <!-- element is an'edge -->
            <xsl:when test="$element[self::g:edge]">
                
                <xsl:variable name="source-node" as="node()" 
                    select="$root//g:node[utls:contains-id(@id, utls:get-edge-source-id($element))]"/>
                <xsl:variable name="source-ontology" as="xs:string" 
                    select="utls:ontology-membership($source-node)"/>
                
                <xsl:variable name="target-node" as="node()" 
                    select="$root//g:node[utls:contains-id(@id, utls:get-edge-target-id($element))]"/>
                <xsl:variable name="target-ontology" as="xs:string" 
                    select="utls:ontology-membership($target-node)"/>
                
                <xsl:sequence select="if ($source-ontology eq $target-ontology) then $source-ontology
                    else (if (utls:is-ontology-reachable($target-ontology,$source-ontology)) then
                    $target-ontology else $source-ontology)"/>
                
            </xsl:when>
            
            <!-- element is a node or an'ontology -->
            <xsl:when test="$element[self::g:node]">
                <xsl:variable name="ontology-node" as="node()?" 
                    select="if (utls:is-an-ontology($element)) then $element
                    else $element/parent::g:graph/parent::g:node"/>
                <xsl:sequence select="if (exists($ontology-node)) then $ontology-node/@id 
                    else $default-ontology-id"/>
            </xsl:when>
            
            <!-- the element is neither a node nor an edge: error -->
            <xsl:otherwise>
                <xsl:sequence select="error(QName($error-namespace,
                    'utls:ontology-membership'),'$element param must be either a node or an edge')"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    <!-- RTF defining all the import axioms in GraphML graph, used in utls:is-ontology-reachable -->
    <xsl:variable name="import-axioms-rtf" as="node()">
        <xsl:element name="axioms" namespace="{$rtf-namespace}">
            
            <!-- analyze each edge in graffoo diagram -->
            <xsl:for-each select="$root//g:edge[utls:is-an-axiom(.)]">
                
                <!-- find edge's source/target node and the ontology that holds the edge -->
                <xsl:variable name="source-id" as="xs:string" 
                    select="utls:get-edge-source-id(current())"/>
                <xsl:variable name="target-id" as="xs:string" 
                    select="utls:get-edge-target-id(current())"/>
                
                <!-- extract each effective label of edge and generate an univocal id for it -->
                <xsl:variable name="labels" as="node()" 
                    select="utls:generate-labels-and-ids-by-edge(current())"/>
                
                <!-- for each effective edge's label create a node named with the entity's type
                and an eventual additional axiom to maintain rdfs:label and rdfs:comment annotations -->
                <xsl:for-each select="$labels/rtf:label">
                    <xsl:variable name="axiom" as="node()"
                        select="utls:search-for-manchester-axiom(@name)"/>
                    
                    <xsl:if test="$axiom/@name eq 'Import'">
                        <xsl:element name="&axiom;" namespace="{$rtf-namespace}">
                            
                            <!-- label's univocal id -->
                            <xsl:attribute name="id" select="@id"/>
                            <!-- label's value -->
                            <xsl:attribute name="name" select="$axiom/@name"/>
                            
                            <!-- source node's id -->
                            <xsl:attribute name="source-id" select="$source-id"/>
                            <!-- target node's id -->
                            <xsl:attribute name="target-id" select="$target-id"/>
                            
                        </xsl:element>
                    </xsl:if>
                    
                </xsl:for-each>
            </xsl:for-each>
            
        </xsl:element>
    </xsl:variable>
    
    <!-- 
        INPUT
            source-ontology, destination-ontology: two ontology in GraphML graph
        OUTPUT
            check if destination-ontology is reachable from source-ontology through Import axioms
    -->
    <xsl:function name="utls:is-ontology-reachable" as="xs:boolean">
        <xsl:param name="source-ontology" as="xs:string"/>
        <xsl:param name="destination-ontology" as="xs:string"/>
        
        <xsl:variable name="reached-ontologies" as="xs:string*" select="$import-axioms-rtf/rtf:&axiom;
            [@name eq '&import-axiom;'][@source-id eq $source-ontology]/@target-id"/>
        
        <xsl:sequence select="($destination-ontology = $reached-ontologies) or 
            (some $ontology in $reached-ontologies satisfies 
            utls:is-ontology-reachable($ontology,$destination-ontology))"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            node: a g:node of GraphML graph
        OUTPUT
            check if node represent an external rule Graffoo widget
    -->
    <xsl:function name="utls:is-an-external-rule" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:graph]
            [g:data[@key eq $node-content]//y:BorderStyle/@type = 'dashed']) 
            then true() else false()"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            node: a g:node of GraphML graph
        OUTPUT
            check if node represent a simple datarange Graffoo widget
    -->
    <xsl:function name="utls:is-a-datarange" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:data[@key eq $node-content]/y:ShapeNode
            [y:Shape/@type eq 'parallelogram'][y:BorderStyle/@type eq 'line']])
            then true() else false()"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            node: a g:node of GraphML graph
        OUTPUT
            check if node represent a datarange restriction Graffoo widget
    -->
    <xsl:function name="utls:is-a-datarange-restriction" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:data[@key eq $node-content]/y:ShapeNode
            [y:Shape/@type eq 'parallelogram'][y:BorderStyle/@type eq 'dotted']])
            then true() else false()"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            node: a g:node of GraphML graph
        OUTPUT
            check if node represent a simple class Graffoo widget
    -->
    <xsl:function name="utls:is-a-class" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:data[@key eq $node-content]/y:ShapeNode
            [y:Shape/@type eq 'roundrectangle'][y:BorderStyle/@type eq 'line']])
            then true() else false()"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            node: a g:node of GraphML graph
        OUTPUT
            check if node represent a restriction class Graffoo widget
    -->
    <xsl:function name="utls:is-a-class-restriction" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:data[@key eq $node-content]/y:ShapeNode
            [y:Shape/@type eq 'roundrectangle'][y:BorderStyle/@type eq 'dotted']])
            then true() else false()"/>
    </xsl:function>
      
    
    
    <!--
        INPUT
            node: a g:node of GraphML graph
        OUTPUT
            check if node represent an instance Graffoo widget
    -->
    <xsl:function name="utls:is-an-individual" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:data[@key eq $node-content]
            /y:ShapeNode/y:Shape/@type eq 'ellipse']) then true() else false()"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            node: a g:node of GraphML graph
        OUTPUT
            check if node represent a literal Graffoo widget
            (literal nodes used in prefixes box are excluded)
    -->
    <xsl:function name="utls:is-a-literal" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if ($node[g:data[@key eq $node-content]
            /y:ShapeNode/y:BorderStyle/@hasColor eq 'false']
            [not($node/parent::g:graph/parent::g:node[utls:is-a-prefixes-box(.) or 
            utls:is-an-external-rule(.)])]) then true() else false()"/>
    </xsl:function>


    
    <!--
        INPUT
            node: a g:node of GraphML graph
        OUTPUT
            check if node represent an additional axiom Graffoo widget
    -->
    <xsl:function name="utls:is-an-additional-axiom" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="if (
            $node/g:data[@key eq $node-content]/y:UMLNoteNode) 
            then true() else false()"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            edge: a g:edge of GraphML graph
        OUTPUT
            check if edge represent a data property Graffoo widget
    -->
    <xsl:function name="utls:is-a-dataproperty" as="xs:boolean">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge[g:data[@key eq $edge-content]/y:*
            [y:LineStyle/@type eq 'line'][y:Arrows[every $end-point-style in 
            ('transparent_circle','white_delta') satisfies $end-point-style = (@source,@target)]]]) 
            then true() else false()"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge of GraphML graph
        OUTPUT
            check if edge represent a data property facility Graffoo widget
    -->
    <xsl:function name="utls:is-a-dataproperty-facility" as="xs:boolean">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge[g:data[@key eq $edge-content]/y:*
            [y:LineStyle/@type eq 'dotted'][y:Arrows[every $end-point-style in 
            ('transparent_circle','white_delta') satisfies $end-point-style = (@source,@target)]]]) 
            then true() else false()"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing a data property Graffoo widget
        OUTPUT
            the id of the edge's source element
    -->
    <xsl:function name="utls:get-dataproperty-source-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge/g:data[@key eq $edge-content]//y:Arrows/@source 
            eq 'transparent_circle') then $edge/@source else $edge/@target"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing a data property Graffoo widget
        OUTPUT
            the id of the edge's target element
    -->
    <xsl:function name="utls:get-dataproperty-target-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge/g:data[@key eq $edge-content]//y:Arrows/@target
            eq 'white_delta') then $edge/@target else $edge/@source"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            edge: a g:edge of GraphML graph
        OUTPUT
            check if edge represent an object property Graffoo widget
    -->
    <xsl:function name="utls:is-an-objectproperty" as="xs:boolean">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge[g:data[@key eq $edge-content]/y:*
            [y:LineStyle/@type eq 'line'][y:Arrows[every $end-point-style in 
            ('circle','delta') satisfies $end-point-style = (@source,@target)]]]) 
            then true() else false()"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge of GraphML graph
        OUTPUT
            check if edge represent an object property facility Graffoo widget
    -->
    <xsl:function name="utls:is-an-objectproperty-facility" as="xs:boolean">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge[g:data[@key eq $edge-content]/y:*
            [y:LineStyle/@type eq 'dotted'][y:Arrows[every $end-point-style in 
            ('circle','delta') satisfies $end-point-style = (@source,@target)]]]) 
            then true() else false()"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing an object property Graffoo widget
        OUTPUT
            the id of the edge's source element
    -->
    <xsl:function name="utls:get-objectproperty-source-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge/g:data[@key eq $edge-content]//y:Arrows/@source 
            eq 'circle') then $edge/@source else $edge/@target"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing an object property Graffoo widget
        OUTPUT
            the id of the edge's target element
    -->
    <xsl:function name="utls:get-objectproperty-target-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge/g:data[@key eq $edge-content]//y:Arrows/@target
            eq 'delta') then $edge/@target else $edge/@source"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            edge: a g:edge of GraphML graph
        OUTPUT
            check if edge represent an annotation property Graffoo widget
    -->
    <xsl:function name="utls:is-an-annotationproperty" as="xs:boolean">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge[g:data[@key eq $edge-content]/y:*
            [y:LineStyle/@type eq 'line'][y:Arrows[every $end-point-style in 
            ('skewed_dash','plain') satisfies $end-point-style = (@source,@target)]]]) 
            then true() else false()"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge of GraphML graph
        OUTPUT
            check if edge represent an annotation property facility Graffoo widget
    -->
    <xsl:function name="utls:is-an-annotationproperty-facility" as="xs:boolean">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge[g:data[@key eq $edge-content]/y:*
            [y:LineStyle/@type eq 'dotted'][y:Arrows[every $end-point-style in 
            ('skewed_dash','plain') satisfies $end-point-style = (@source,@target)]]]) 
            then true() else false()"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing an annotation property Graffoo widget
        OUTPUT
            the id of the edge's source element
    -->
    <xsl:function name="utls:get-annotationproperty-source-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge/g:data[@key eq $edge-content]//y:Arrows/@source 
            eq 'skewed_dash') then $edge/@source else $edge/@target"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing an annotation property Graffoo widget
        OUTPUT
            the id of the edge's target element
    -->
    <xsl:function name="utls:get-annotationproperty-target-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge/g:data[@key eq $edge-content]//y:Arrows/@target
            eq 'plain') then $edge/@target else $edge/@source"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            edge: a g:edge of GraphML graph
        OUTPUT
            check if edge represent an axiom Graffoo widget
    -->
    <xsl:function name="utls:is-an-axiom" as="xs:boolean">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge[g:data[@key eq $edge-content]/y:*
            [y:LineStyle/@type eq 'line'][y:Arrows[every $end-point-style in 
            ('none','standard') satisfies $end-point-style = (@source,@target)]]]) 
            then true() else false()"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing an axiom Graffoo widget
        OUTPUT
            the id of the edge's source element
    -->
    <xsl:function name="utls:get-axiom-source-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge/g:data[@key eq $edge-content]//y:Arrows/@source 
            eq 'none') then $edge/@source else $edge/@target"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing an axiom Graffoo widget
        OUTPUT
            the id of the edge's target element
    -->
    <xsl:function name="utls:get-axiom-target-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="if ($edge/g:data[@key eq $edge-content]//y:Arrows/@target
            eq 'standard') then $edge/@target else $edge/@source"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            edge: a g:edge of GraphML graph
        OUTPUT
            check if edge represent a property Graffoo widget
    -->
    <xsl:function name="utls:is-a-property" as="xs:boolean">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="utls:is-a-dataproperty($edge) or utls:is-a-dataproperty-facility($edge)
            or utls:is-an-objectproperty($edge) or utls:is-an-objectproperty-facility($edge)
            or utls:is-an-annotationproperty($edge) or utls:is-an-annotationproperty-facility($edge)"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing an edge Graffoo widget
        OUTPUT
            the id of the edge's source element
    -->
    <xsl:function name="utls:get-edge-source-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="
            if (utls:is-a-dataproperty($edge) or utls:is-a-dataproperty-facility($edge))
            then utls:get-dataproperty-source-id($edge) else
            if (utls:is-an-objectproperty($edge) or utls:is-an-objectproperty-facility($edge))
            then utls:get-objectproperty-source-id($edge) else 
            if (utls:is-an-annotationproperty($edge) or utls:is-an-annotationproperty-facility($edge))
            then utls:get-annotationproperty-source-id($edge) else
            if (utls:is-an-axiom($edge)) then utls:get-axiom-source-id($edge) else $edge/@source"/>
    </xsl:function>
    
    <!--
        INPUT
            edge: a g:edge representing an edge Graffoo widget
        OUTPUT
            the id of the edge's source element
    -->
    <xsl:function name="utls:get-edge-target-id" as="xs:string">
        <xsl:param name="edge" as="node()"/>
        <xsl:sequence select="
            if (utls:is-a-dataproperty($edge) or utls:is-a-dataproperty-facility($edge))
            then utls:get-dataproperty-target-id($edge) else
            if (utls:is-an-objectproperty($edge) or utls:is-an-objectproperty-facility($edge))
            then utls:get-objectproperty-target-id($edge) else 
            if (utls:is-an-annotationproperty($edge) or utls:is-an-annotationproperty-facility($edge))
            then utls:get-annotationproperty-target-id($edge) else
            if (utls:is-an-axiom($edge)) then utls:get-axiom-target-id($edge) else $edge/@target"/>
    </xsl:function>
    
    
    
    <!--
        INPUT
            nodes: a list of g:node of GraphML graph
        OUTPUT
            the values of nodes
    -->
    <xsl:function name="utls:get-node-name" as="xs:string*">
        <xsl:param name="nodes" as="node()*"/>
        <xsl:sequence select="for $node in $nodes return
            normalize-space($node/g:data[@key eq $node-content]//y:NodeLabel
            [if (parent::y:*/y:State) then parent::y:*/y:State/@closed eq 'false' else 'true'])"/>
    </xsl:function>
    
    <!--
        INPUT
            ids: the IDs of a list of g:node of GraphML graph
        OUTPUT
            the values of nodes identified by one of ids
    -->
    <xsl:function name="utls:get-node-name-by-id" as="xs:string*">
        <xsl:param name="ids" as="xs:string*"/>
        <xsl:sequence select="utls:get-node-name($root//g:node[utls:contains-id(@id, $ids)])"/>
    </xsl:function>
    
    <!--
        INPUT
            nodes: a list of g:node of GraphML graph
        OUTPUT
            the Manchester strings representing the label of each nodes, 
            without eventual comments
    -->
    <xsl:function name="utls:get-uncommented-manchester-node-name" as="xs:string*">
        <xsl:param name="nodes" as="node()*"/>
        
        <xsl:variable name="node-strings" as="xs:string*" select="
            for $node in $nodes return $node/g:data[@key eq $node-content]//y:NodeLabel
            [if (parent::y:*/y:State) then parent::y:*/y:State/@closed eq 'false' else 'true']"/>
        <xsl:variable name="uncommented-strings" as="xs:string*" select="for $str in $node-strings 
            return replace($str, '# .*? ( \r\n? | \n\r? )', '', 'x')"/>
        <xsl:sequence select="for $str in $uncommented-strings return normalize-space($str)"/>
    </xsl:function>
    
    
    
    <!-- 
        INPUT
            node: a node representing a class, datarange or individual of GraphML graph
        OUTPUT
            a string defining a presentational description of the node.
            Example: "x=622.5 y=589.0 height=44.0 width=71.5 fill-color=#FFFF00"
    -->
    <xsl:function name="utls:get-node-appearance" as="xs:string*">
        <xsl:param name="node" as="node()"/>
        
        <xsl:variable name="node-geometry" as="node()" select="$node/g:data[@key eq $node-content]/*/y:Geometry"/>
        <xsl:variable name="node-fill" as="node()" select="$node/g:data[@key eq $node-content]/*/y:Fill"/>
        
        <xsl:sequence select="concat('x=', $node-geometry/@x, ' ', 'y=', $node-geometry/@y, ' ', 
            'width=', $node-geometry/@width, ' ', 'height=', $node-geometry/@height, ' ', 'fill-color=', $node-fill/@color)"/>
    </xsl:function>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    RDFS labels and comments
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    <!--  in yEd (Properties -> Data -> Description) it's possible to associate to each node/edge a description
        used in the final ontology as value of rdfs:label and rdfs:comment predicate (the first not empty string
        is the label, 
        utilizzata nell'ontologia finale come valore delle annotation property rdfs:label e rdfs:comment
        dell'entità (la prima stringa non vuota costituisce la label, everything that follows 
        constitutes the comment) -->
    <!-- note: only ontologies, dataranges, classes, restrictions (subject of assertions), individuals 
        and properties will be equipped with rdfs:label and rdfs:comment annotations in final ontology -->
    
    
    <!--
        INPUT
            entity: the entity node of GraphML graph
        OUTPUT
            the user defined description of that entity
    -->
    <!-- restituisce la description dell'entità -->
    <xsl:function name="utls:get-entity-description" as="xs:string?">
        <xsl:param name="entity" as="node()"/>
        <xsl:sequence select="$entity/g:data[@key = ($node-description,$edge-description)]"/>
    </xsl:function>
    
    
    <!-- 
        INPUT
            description: the user defined description of an entity
        OUTPUT
            the eventual rdfs:label from description
    -->
    <xsl:function name="utls:get-entity-rdfs-label" as="xs:string?">
        <xsl:param name="description" as="xs:string?"/>
        
        <xsl:choose>
            
            <xsl:when test="empty($description)">
                <xsl:sequence select="()"/>
            </xsl:when>
            
            <xsl:otherwise>
                <!-- return the first not empty line if exists, else the empty sequence -->
                <xsl:sequence select="if (matches($description,'[^\s]')) then 
                    normalize-space((for $line in tokenize($description,'\n') return 
                    (if (matches($line,'[^\s]')) then $line else ()))[1]) else ()"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    <!-- 
        INPUT
            description: the user defined description of an entity
        OUTPUT
            the eventual rdfs:comment from description
    -->
    <xsl:function name="utls:get-entity-rdfs-comment" as="xs:string?">
        <xsl:param name="description" as="xs:string?"/>
        
        <xsl:choose>
            
            <xsl:when test="empty($description)">
                <xsl:sequence select="()"/>
            </xsl:when>
            
            <xsl:otherwise>
                <!-- return not empty lines following the first not empty line if they exist,
                    else the empty sequence -->
                <xsl:sequence select="if (matches($description,'[^\s]')) then 
                    normalize-space(string-join(remove(for $line in tokenize($description,'\n')
                    return (if (matches($line,'[^\s]')) then $line else ()), 1),' ')) else ()"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    Edge labels and ids
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    <!-- an edge labeled defines in its interior one or more nodes EdgeLabel,
        each of which defines in its interior one or more labels separated by newline -->
    <!-- each EdgeLabel node is identified by a string obtained by the concatenation of
        * id of edge that holds it ("id" attribute of g:edge node)
        * EdgeLabel position in respect with eventual EdgeLabel brothers -->
    <!-- each label is identified by a string obtained by the concatenation of
        * id of EdgeLabel that holds id
        * label position in respect with the other labels in that EdgeLabel -->
    
    
    <!-- 
        INTPUT
            edgelabel-content: a string representing the content of an EdgeLabel
        OUTPUT
            the not empty labels in edgelabel-content
    -->
    <xsl:function name="utls:tokenize-edgelabel" as="xs:string*">
        <xsl:param name="edgelabel-content" as="xs:string"/>
        
        <!-- all labels, even those that may be empty -->
        <xsl:variable name="labels" as="xs:string*" select="for $label in tokenize($edgelabel-content,'\n') 
            return normalize-space($label)"/>
        
        <!-- return only not empty labels -->
        <xsl:sequence select="for $label in $labels return if (matches($label,'^\s*$')) then () else $label"/>
    </xsl:function>
    
    
    <!-- 
        INPUT
            edge: an edge of GraphML graph
        OUTPUT
            a tree that defines an ID for each label in edge
    -->
    <xsl:function name="utls:generate-labels-and-ids-by-edge" as="node()">
        <xsl:param name="edge" as="node()"/>
        
        <xsl:variable name="result" as="node()">
            <xsl:element name="labels" namespace="{$rtf-namespace}">
                
                <!-- each edge can define multiple EdgeLabel node -->
                <xsl:for-each select="$edge/g:data[@key eq $edge-content]//y:EdgeLabel">
                    
                    <!-- current EdgeLabel index (position in respect to brothers) -->
                    <xsl:variable name="edgelabel-index" as="xs:integer" select="position()"/>
                    
                    <!-- labels defined for the current EdgeLabel -->
                    <xsl:variable name="labels" as="xs:string*" 
                        select="utls:tokenize-edgelabel(current())"/>
                    
                    <!-- for each label create a node "label" with attribute "name" (the label)
                    and "id" (the ID associated with that label) -->
                    <xsl:for-each select="(1 to count($labels))">
                        <xsl:element name="label" namespace="{$rtf-namespace}">
                            <xsl:attribute name="name" select="$labels[current()]"/>
                            <xsl:attribute name="id" select="concat($edge/@id, $edgelabel-id-first-prefix, 
                                $edgelabel-index, $edgelabel-id-second-prefix, current())"/>
                        </xsl:element> 
                    </xsl:for-each>
                </xsl:for-each>
                
            </xsl:element>
        </xsl:variable>
        
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    
    <!--
        INPUT
            edgelabel: an EdgeLabel of GraphML graph
        OUTPUT
            a tree that defines an ID for each label in edgelabel
    -->
    <xsl:function name="utls:generate-labels-and-ids-by-edgelabel" as="node()">
        <xsl:param name="edgelabel" as="node()"/>
        
        <xsl:variable name="result" as="node()">
            <xsl:element name="labels" namespace="{$rtf-namespace}">
                
                <xsl:variable name="edgelabel-id" as="xs:string"
                    select="utls:generate-edgelabel-id($edgelabel)"/>
                
                <!-- labels defined for the current EdgeLabel -->
                <xsl:variable name="labels" as="xs:string*"
                    select="utls:tokenize-edgelabel($edgelabel)"/>
                
                <!-- for each label create a node "label" with attribute "name" (the label)
                    and "id" (the ID associated with that label) -->
                <xsl:for-each select="(1 to count($labels))">
                    <xsl:element name="label" namespace="{$rtf-namespace}">
                        <xsl:attribute name="name" select="$labels[current()]"/>
                        <xsl:attribute name="id" 
                            select="concat($edgelabel-id, $edgelabel-id-second-prefix, current())"/>
                    </xsl:element> 
                </xsl:for-each>
                
            </xsl:element>
        </xsl:variable>
        
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    
    <!--
        INPUT
            edgelabel: an EdgeLabel of GraphML graph
        OUTPUT
            an univocal ID for edgelabel
    -->
    <xsl:function name="utls:generate-edgelabel-id" as="xs:string">
        <xsl:param name="edgelabel" as="node()"/>
        
        <xsl:variable name="edgelabel-index" as="xs:integer" 
            select="count($edgelabel/preceding-sibling::y:EdgeLabel) + 1"/>
        <xsl:sequence select="concat($edgelabel/ancestor::g:edge/@id, 
            $edgelabel-id-first-prefix, $edgelabel-index)"/>
    </xsl:function>
    
    
    <!--
        INPUT
            id: an EdgeLabel id
        OUTPUT
            the EdgeLabel of Graphml graph
    -->
    <xsl:function name="utls:get-edgelabel-by-id" as="node()">
        <xsl:param name="id" as="xs:string"/>
        
        <xsl:variable name="edge-id" as="xs:string" select="substring-before($id, $edgelabel-id-first-prefix)"/>
        <xsl:variable name="edge" as="node()" select="$root//g:edge[utls:contains-id(@id, $edge-id)]"/>
        <xsl:variable name="edgelabel-index" select="substring-after($id, $edgelabel-id-first-prefix)"/>
        <xsl:sequence select="$edge//y:EdgeLabel[position() eq xs:integer($edgelabel-index)]"/>
    </xsl:function>
    
    
    <!--
        INPUT
            id: an EdgeLabel ID
        OUTPUT
            the edge that holds the EdgeLabel identified by id
    -->
    <xsl:function name="utls:get-edge-by-edgelabel-id" as="node()">
        <xsl:param name="id" as="xs:string"/>
        <xsl:sequence select="$root//g:edge[utls:contains-id(@id, substring-before($id, $edgelabel-id-first-prefix))]"/>
    </xsl:function>



    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                Targets of additional axioms
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    <!--
        An additional axiom could refer to MORE Graffoo nodes (g:nodes element)
        through the special Graffoo edge widget, or to the SINGLE Graffoo edge label
        (y:EdgeLabel element) that is the closest to the additional axiom's box.
        Each y:EdgeLabel could generate more edge elements in intermediate results,
        one edge for each line in the label.
    -->
    
    
    <!--
        INPUT
            Axiom: an additional axiom g:node element in graphml diagram
        OUTPUT 
            The IDs of elements (g:nodes or y:EdgeLabel's labels) referred by the axiom
    -->
    <xsl:function name="utls:axiom-refers-to" as="xs:string+">
        <xsl:param name="axiom" as="node()"/>
        
        <!-- eventual axiom's links -->
        <xsl:variable name="link-edges" as="node()*" 
            select="$root//g:edge[utls:contains-id($axiom/@id, (@source,@target))]"/>
        
        <xsl:choose>
            
            <!-- if links exist, then the axiom refers to Graffoo nodes -->
            <xsl:when test="exists($link-edges)">
                <xsl:sequence select="$root//g:node
                    [(utls:contains-id(@id, $link-edges/(@source|@target))) and (not(utls:contains-id(@id, $axiom/@id)))]/@id"/>
            </xsl:when>
            
            <!-- else the axiom refers to a property declation/facility y:EdgeLabel 
                (we don't consider axioms as possible targets) -->
            <xsl:otherwise>
                
                <!-- create a result tree fragment that define for each property declaration/facility
                    y:EdgeLabel elements in the diagram, the distance of its box from additional axiom's box -->
                <xsl:variable name="distances" as="node()">
                    <xsl:element name="distances" namespace="{$rtf-namespace}">
                        
                        <xsl:for-each select="$root//g:edge[utls:is-a-property(.)]//y:EdgeLabel">
                            <xsl:element name="distance" namespace="{$rtf-namespace}">
                                <xsl:attribute name="id" 
                                    select="utls:generate-edgelabel-id(current())"/>
                                <xsl:attribute name="distance" 
                                    select="utls:edgelabel-to-axiom-distance(current(),$axiom)"/>
                            </xsl:element>
                        </xsl:for-each>
                        
                    </xsl:element>
                </xsl:variable>
                
                <!-- return the y:EdgeLabel's ID with the shorter distance -->
                <xsl:variable name="min-distance" as="xs:double" select="
                    min( for $distance in $distances//rtf:distance/@distance return xs:double($distance) )"/>
                <xsl:sequence select="$distances//rtf:distance[xs:double(@distance) eq $min-distance]/@id"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <!--
        INPUT
            edgelabel: an y:EdgeLabel element of Graffoo diagram
            axiom: an additional axiom g:node element
        OUTPUT
            the least distance between edgelabel's box and axiom's box
    -->
    <xsl:function name="utls:edgelabel-to-axiom-distance" as="xs:double">
        <xsl:param name="edgelabel" as="node()"/>
        <xsl:param name="axiom" as="node()"/>
        
        <!-- get the box of both params -->
        <xsl:variable name="edgelabel-box" as="node()" select="utls:get-edgelabel-box($edgelabel)"/>
        <xsl:variable name="axiom-box" as="node()" select="$axiom/g:data[@key eq $node-content]//y:Geometry"/>

        <!-- check if two box is aligned horizontally/vertically -->
        <xsl:variable name="is-boxes-aligned-horizontally" as="xs:boolean"
            select="utls:is-boxes-aligned-horizontally($edgelabel-box,$axiom-box)"/>
        <xsl:variable name="is-boxes-aligned-vertically" as="xs:boolean"
            select="utls:is-boxes-aligned-vertically($edgelabel-box,$axiom-box)"/>
        
        <!-- get the margins of edgelabel's box -->
        <xsl:variable name="edgelabel-left-margin" as="xs:double" select="$edgelabel-box/@x"/>
        <xsl:variable name="edgelabel-right-margin" as="xs:double" 
            select="xs:double($edgelabel-box/@x) + xs:double($edgelabel-box/@width)"/>
        <xsl:variable name="edgelabel-top-margin" as="xs:double" select="$edgelabel-box/@y"/>
        <xsl:variable name="edgelabel-bottom-margin" as="xs:double" 
            select="xs:double($edgelabel-box/@y) + xs:double($edgelabel-box/@height)"/>
        
        <!-- get the margins of axiom's box -->
        <xsl:variable name="axiom-left-margin" as="xs:double" select="$axiom-box/@x"/>
        <xsl:variable name="axiom-right-margin" as="xs:double" 
            select="xs:double($axiom-box/@x) + xs:double($axiom-box/@width)"/>
        <xsl:variable name="axiom-top-margin" as="xs:double" select="$axiom-box/@y"/>
        <xsl:variable name="axiom-bottom-margin" as="xs:double" 
            select="xs:double($axiom-box/@y) + xs:double($axiom-box/@height)"/>
        
        <!-- choose based on the alignment of the boxes -->
        <xsl:choose>
            
            <!-- not vertical but horizontal alignment: 
                distance calculated between horizontal sides of the two boxes -->
            <xsl:when test="$is-boxes-aligned-horizontally and not($is-boxes-aligned-vertically)">
                <xsl:sequence select="min( 
                    for $edgelabel-margin in ($edgelabel-top-margin, $edgelabel-bottom-margin), 
                        $axiom-margin in ($axiom-top-margin, $axiom-bottom-margin) 
                    return abs($edgelabel-margin - $axiom-margin) )"/>
            </xsl:when>
            
            <!-- not horizontal but vertical alignment: 
                distance calculated between vertical sides of the two boxes -->
            <xsl:when test="$is-boxes-aligned-vertically and not($is-boxes-aligned-horizontally)">
                <xsl:sequence select="min(
                    for $edgelabel-margin in ($edgelabel-left-margin, $edgelabel-right-margin),
                        $axiom-margin in ($axiom-left-margin, $axiom-right-margin) 
                    return abs($edgelabel-margin - $axiom-margin) )"/>
            </xsl:when>
            
            <!-- neither vertical nor horizontal alignment: 
                distance calculated with respect to the vertices of the two boxes -->
            <xsl:when test="not($is-boxes-aligned-horizontally or $is-boxes-aligned-vertically)">
                
                <!-- get vertices of the two boxes -->
                <xsl:variable name="edgelabel-vertices" as="node()+" select="(
                    utls:new-point($edgelabel-left-margin, $edgelabel-top-margin),
                    utls:new-point($edgelabel-right-margin, $edgelabel-top-margin),
                    utls:new-point($edgelabel-right-margin, $edgelabel-bottom-margin),
                    utls:new-point($edgelabel-left-margin, $edgelabel-bottom-margin) )"/>
                <xsl:variable name="axiom-vertices" as="node()+" select="(
                    utls:new-point($axiom-left-margin, $axiom-top-margin),
                    utls:new-point($axiom-right-margin, $axiom-top-margin),
                    utls:new-point($axiom-right-margin, $axiom-bottom-margin),
                    utls:new-point($axiom-left-margin, $axiom-bottom-margin) )"/>
                
                <xsl:sequence select="min(
                    for $edgelabel-vertex in $edgelabel-vertices, 
                        $axiom-vertex in $axiom-vertices 
                    return utls:point-to-point-distance($edgelabel-vertex, $axiom-vertex))"/>
            </xsl:when>
            
            <!-- both vertical and horizontal alignment (boxes partially overlapping):
                distance calculated with respect to both sides and vertices of the two boxes -->
            <xsl:otherwise>
                <xsl:sequence select="min(
                    for $edgelabel-margin in 
                            ($edgelabel-left-margin, $edgelabel-top-margin, $edgelabel-right-margin, $edgelabel-bottom-margin),
                        $axiom-margin in 
                            ($axiom-left-margin, $axiom-top-margin, $axiom-right-margin, $axiom-bottom-margin) 
                    return abs($edgelabel-margin -$axiom-margin) )"/>
            </xsl:otherwise>
        </xsl:choose>
       
    </xsl:function>
    
    
    <!--
        INPUT
            box1, box2: two box nodes
        OUTPUT
            a boolean indicating if two boxes are VERTICALLY aligned
            (i.e. if exists an horizontal line that intersect both them)
    -->
    <xsl:function name="utls:is-boxes-aligned-vertically" as="xs:boolean">
        <xsl:param name="box1" as="node()"/>
        <xsl:param name="box2" as="node()"/>
        
        <!-- get box1's top and bottom margins --> 
        <xsl:variable name="box1-top-margin" as="xs:double" select="$box1/@y"/>
        <xsl:variable name="box1-bottom-margin" as="xs:double" 
            select="xs:double($box1/@y) + xs:double($box1/@height)"/>
        
        <!-- get box2's top and bottom margins -->
        <xsl:variable name="box2-top-margin" as="xs:double" select="$box2/@y"/>
        <xsl:variable name="box2-bottom-margin" as="xs:double" 
            select="xs:double($box2/@y) + xs:double($box2/@height) "/>
        
        <xsl:sequence select="
            (some $y in ($box1-top-margin, $box1-bottom-margin) 
                satisfies ($y ge $box2-top-margin and $y le $box2-bottom-margin)) or
            (some $y in ($box2-top-margin, $box2-bottom-margin) 
                satisfies ($y ge $box1-top-margin and $y le $box1-bottom-margin))"/>
    </xsl:function>
    
    
    <!--
        INPUT
            box1, box2: two box nodes
        OUTPUT
            a boolean indicating if two boxes are HORIZONTALLY aligned 
            (i.e. if exists a vertical line that intersect both them)
    -->
    <xsl:function name="utls:is-boxes-aligned-horizontally" as="xs:boolean">
        <xsl:param name="box1" as="node()"/>
        <xsl:param name="box2" as="node()"/>
        
        <!-- get box1's left and right margins --> 
        <xsl:variable name="box1-left-margin" as="xs:double" select="$box1/@x"/>
        <xsl:variable name="box1-right-margin" as="xs:double" 
            select="xs:double($box1/@x) + xs:double($box1/@width)"/>
        
        <!-- get box2's left and right margins --> 
        <xsl:variable name="box2-left-margin" as="xs:double" select="$box2/@x"/>
        <xsl:variable name="box2-right-margin" as="xs:double" 
            select="xs:double($box2/@x) + xs:double($box2/@width)"/>

        <xsl:sequence select="
            (some $x in ($box1-left-margin,$box1-right-margin) 
                satisfies ($x ge $box2-left-margin and $x le $box2-right-margin)) or
            (some $x in ($box2-left-margin,$box2-right-margin) 
                satisfies ($x ge $box1-left-margin and $x le $box1-right-margin))"/>
    </xsl:function>
    
    
    <!--
        INPUT
            edgelabel: an y:EdgeLabel node of graphml diagram
        OUTPUT
            one xml node that represents the y:EdgeLabel box (with absolute position)
    -->
    <xsl:function name="utls:get-edgelabel-box" as="node()">
        <xsl:param name="edgelabel" as="node()"/>
        
        <!-- calculate the absolute position of y:EdgeLabel -->
        <xsl:variable name="edgelabel-position" as="node()" 
            select="utls:get-edgelabel-position($edgelabel)"/>
        
        <!-- create an xml node representing the y:EdgeLabel box -->
        <xsl:element name="box" namespace="{$rtf-namespace}">
            <xsl:attribute name="x" select="$edgelabel-position/@x"/>
            <xsl:attribute name="y" select="$edgelabel-position/@y"/>
            <xsl:attribute name="width" select="$edgelabel/@width"/>
            <xsl:attribute name="height" select="$edgelabel/@height"/>
        </xsl:element>
    </xsl:function>
    
    
    <!--
        INPUT
            edgelabel: an y:EdgeLabel node of graphml diagram
        OUTPUT
            one node representing the absolute position of edgelabel
        NOTES
            in graphml diagram the y:EdgeLabel position is not absolute, but relative 
            to the edge's source point on the border of source node. This point is calculated
            as intersection point of two line defined by
            1) the edge's source point within the source node (relative to the 
                source node's center point) and the next point of edge's path
            2) one of 4 sides of source node
    -->
    <xsl:function name="utls:get-edgelabel-position" as="node()">
        <xsl:param name="edgelabel" as="node()"/>

        <!-- get the g:edge element that holds the edgelabel and its y:Path node -->
        <xsl:variable name="edge" as="node()" select="$edgelabel/ancestor::g:edge"/>
        <xsl:variable name="edge-path" as="node()" 
            select="$edge/g:data[@key eq $edge-content]//y:Path"/>
        
        <!-- get the source node and its y:Geometry node -->
        <xsl:variable name="source-node" as="node()" select="$root//g:node[utls:contains-id(@id, $edge/@source)]"/>
        <xsl:variable name="source-node-geometry" as="node()" 
            select="$source-node/g:data[@key eq $node-content]//y:Geometry"/>
        
        <!-- abolute position of edge's source point within the edge's source node
            (relative to the source node's center point) -->
        <xsl:variable name="start-point" as="node()"> 
            <xsl:variable name="source-node-center" as="node()" select="utls:new-point(
                (xs:double($source-node-geometry/@x) + (xs:double($source-node-geometry/@width) div 2)),
                (xs:double($source-node-geometry/@y) + (xs:double($source-node-geometry/@height) div 2)))"/>
            <xsl:sequence select="utls:new-point(
                ($source-node-center/@x + $edge-path/@sx), ($source-node-center/@y + $edge-path/@sy))"/>
        </xsl:variable>
        
        <!-- absolute position of second point in the edge's path -->
        <xsl:variable name="end-point" as="node()">
            <xsl:choose>
                
                <!-- there're some intermediate points between edge's start and end points:
                    the second point in the edge's path is the first of these -->
                <xsl:when test="$edge-path/y:Point">
                    <xsl:variable name="path-point" as="node()" select="$edge-path/y:Point[1]"/>
                    <xsl:sequence select="utls:new-point($path-point/@x,$path-point/@y)"/>
                </xsl:when>
                
                <!-- there're not intermediate points:
                    the second point in the edge's path is the target point within the target node
                    and its position is relative to the target node's center point -->
                <xsl:otherwise>
                    <xsl:variable name="target-node-geometry" as="node()" select="
                        $root//g:node[utls:contains-id(@id, $edge/@target)]/g:data[@key eq $node-content]//y:Geometry"/>
                    <xsl:variable name="target-node-center" as="node()" select="utls:new-point(
                        ($target-node-geometry/@x + ($target-node-geometry/@width div 2)),
                        ($target-node-geometry/@y + ($target-node-geometry/@height div 2)))"/>
                    <xsl:sequence select="utls:new-point(
                        $target-node-center/@x + $edge-path/@tx, $target-node-center/@y + $edge-path/@ty)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- calculate the intersection point(s) on the source node's border -->
        <xsl:variable name="intersection-point" as="node()*"
            select="utls:box-and-segment-intersection($source-node, $start-point, 
                $end-point, $segment-intersection-tollerance)"/>

        <!-- chose based on the number of intersection points calculated -->
        <xsl:choose>
            
            <!-- one intersection point:
                use it to create the function's result -->
            <xsl:when test="count($intersection-point) eq 1">
                <xsl:sequence select="utls:new-point(
                    (xs:double($intersection-point/@x) + xs:double($edgelabel/@x)),
                    (xs:double($intersection-point/@y) + xs:double($edgelabel/@y)))"/>
            </xsl:when>
            
            <!-- more than one intersectino points:
                use the closest point to the second point in the edge's path -->
            <xsl:when test="count($intersection-point) gt 1">
                <xsl:variable name="distances" as="xs:double+" 
                    select="for $point in $intersection-point return
                        utls:point-to-point-distance($point, $end-point)"/>
                <xsl:variable name="which-point" as="node()" 
                    select="$intersection-point[index-of($distances, min($distances))[1]]"/>
                <xsl:sequence select="utls:new-point(
                    (xs:double($which-point/@x) + xs:double($edgelabel/@x)),
                    (xs:double($which-point/@y) + xs:double($edgelabel/@y)))"/>
            </xsl:when>
            
            <!-- no intersection point: error -->
            <xsl:otherwise>
                <xsl:sequence select="error(QName($error-namespace, 'utls:get-edgelabel-position'),
                    concat('no intersection point found for property label &quot;', $edgelabel, '&quot;'))"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    <!--
        INPUT
            node: a g:node element in graphml diagram
            point1, point2: two absolute positions in diagram that describe one straight line
            tollerance: number of tollerance pts used to calculate the intersection point
                between two segments (an instersection point is valid if it belongs to 
                both segments with max error of $tollerance pts)
        OUTPUT
            the intersection points between node's box border and the segment between point1 and point2
            (point calculated with the tollerance specified), 
            else an empty sequence if no intersection points are found
        NOTES
            as default, the intersection point's calculation is incremental, 
            i.e. the tollerance is increased until at least one result is found (config.xml)
    -->    
    <xsl:function name="utls:box-and-segment-intersection" as="node()*">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="point1" as="node()"/>
        <xsl:param name="point2" as="node()"/>
        <xsl:param name="tollerance" as="xs:double"/>
        
        <!-- get the vertices of node's box -->
        <xsl:variable name="box-vertices" as="node()+" 
            select="utls:get-node-vertices($node)"/>
        
        <!-- calculate the intersection points -->
        <xsl:variable name="intersection-points" as="node()*" select="
            for $n in (1 to count($box-vertices)) 
                return utls:segment-intersection(($point1, $point2), ($box-vertices[$n], 
                    $box-vertices[if ($n eq count($box-vertices)) then 1 else ($n + 1)]), $tollerance)"/>
        
        <!-- choose based on the fact that the calculation is incremental or not -->
        <xsl:choose>
            
            <!-- the calculation is incremental:
                the function calls itself recursively with tollerance increased 
                until at least one intersection point is found -->
            <xsl:when test="$segment-intersection-incremental">
                <xsl:sequence select="
                    if (empty($intersection-points)) then
                        utls:box-and-segment-intersection($node, $point1, $point2, $tollerance +1)
                    else $intersection-points"/>
            </xsl:when>
            
            <!-- no incremental search:
                return current result, even if empty -->
            <xsl:otherwise>
                <xsl:sequence select="$intersection-points"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    <!--
        INPUT
            node: a g:node of graphml diagram
        OUTPUT
            the four vertices of node's box
        NOTES
            we assume that node is a simple entity, i.e. one of class, class rectriction or
            datarange restriction (its shape is a rectangle or parallelogram).
            function called by utls:box-and-segment-intersection
    -->
    <xsl:function name="utls:get-node-vertices" as="node()+">
        <xsl:param name="node" as="node()"/>
        
        <!-- get y:Geometry and y:Shape's type of node -->
        <xsl:variable name="geometry" as="node()" 
            select="$node/g:data[@key eq $node-content]//y:Geometry" />
        <xsl:variable name="shape" as="node()" 
            select="$node/g:data[@key eq $node-content]//y:Shape/@type"/>
        <xsl:choose>
            
            <!-- node's shape is a rectangle (if roundrectangle we ignore
                the curvature at the vertices of the box) -->
            <xsl:when test="$shape = ('rectangle','roundrectangle')">
                <xsl:sequence select="(
                    utls:new-point($geometry/@x, $geometry/@y),
                    utls:new-point(xs:double($geometry/@x) + xs:double($geometry/@width), $geometry/@y),
                    utls:new-point($geometry/@x + xs:double($geometry/@width), 
                        xs:double($geometry/@y) + xs:double($geometry/@height)),
                    utls:new-point($geometry/@x, xs:double($geometry/@y) + xs:double($geometry/@height))
                    )"/>
            </xsl:when>
            
            <!-- node's shape is a parallelogram.
                In yEd the top-left vertex is shifted to the right of 10% of box's width,
                relatively to the position of the box (similarly, the bottom-right vertex 
                 is shitfted to the left) -->
            <xsl:when test="$shape eq 'parallelogram'">
                <xsl:variable name="shift" as="xs:double" select="xs:double($geometry/@width) div 10"/>
                <xsl:sequence select="(
                    utls:new-point(xs:double($geometry/@x) + $shift, $geometry/@y),
                    utls:new-point(xs:double($geometry/@x) + xs:double($geometry/@width), $geometry/@y),
                    utls:new-point(xs:double($geometry/@x) + xs:double($geometry/@width) -$shift, 
                        xs:double($geometry/@y) + xs:double($geometry/@height)),
                    utls:new-point($geometry/@x, xs:double($geometry/@y) + xs:double($geometry/@height))
                    )"/>
            </xsl:when>
            
            <!-- if node's shape is neither a rectangle nor a parallelogram, error -->
            <xsl:otherwise>
                <xsl:sequence select="error(QName($error-namespace,'utls:get-node-vertices'),
                    'unknown shape')"/>            
            </xsl:otherwise>
        </xsl:choose>        
    </xsl:function>
    
    
    <!--
        INPUT
            pair1, pair2: two cuples of points ((x1,y1),(x2,y2)) e ((x3,y3),(x4,y4)), each defines
                one segment
            tollerance: number of tollerance pts used to calculate the intersection point
                between two segments (an instersection point is valid if it belongs to 
                both segments with max error of $tollerance pts)
        OUTPUT
            the intersection point of two segments, calculated with tollerance specified, 
            or the empty sequence if no intersection points is found
        NOTES
            function called by utls:box-and-segment-intersection
    -->
    <xsl:function name="utls:segment-intersection" as="node()?">
        <xsl:param name="pair1" as="node()+"/>
        <xsl:param name="pair2" as="node()+"/>
        <xsl:param name="tollerance" as="xs:double"/>
        
        <!-- calculate (eventual) intersection point of two straight line 
            defined by the two segment -->
        <xsl:variable name="intersection" as="node()?"
            select="utls:straight-intersection-by-points($pair1,$pair2)"/>
        
        <xsl:choose>
            
            <!-- if the two straight lines intersect, 
                check if the intersection point belongs to both segments -->
            <xsl:when test="exists($intersection)">
                <xsl:variable name="x" as="xs:double" select="$intersection/@x"/>
                <xsl:variable name="y" as="xs:double" select="$intersection/@y"/>
                
                <xsl:variable name="is-in-first-segment" as="xs:boolean" select="
                    (($x +$tollerance) ge min((xs:double($pair1[1]/@x),xs:double($pair1[2]/@x))) and
                    ($x -$tollerance) le max((xs:double($pair1[1]/@x),xs:double($pair1[2]/@x)))) or
                    (($y +$tollerance) ge min((xs:double($pair1[1]/@y),xs:double($pair1[2]/@y))) and
                    ($y -$tollerance) le max((xs:double($pair1[1]/@y),xs:double($pair1[2]/@y))))"/>
                
                <xsl:variable name="is-in-second-segment" as="xs:boolean" select="
                    (($x +$tollerance) ge min((xs:double($pair2[1]/@x),xs:double($pair2[2]/@x))) and
                    ($x -$tollerance) le max((xs:double($pair2[1]/@x),xs:double($pair2[2]/@x)))) or
                    (($y +$tollerance) ge min((xs:double($pair2[1]/@y),xs:double($pair2[2]/@y))) and
                    ($y -$tollerance) le max((xs:double($pair2[1]/@y),xs:double($pair2[2]/@y))))"/>
                
                <xsl:sequence select="if ($is-in-first-segment and $is-in-second-segment)
                    then $intersection else ()"/>
            </xsl:when>
            
            <!-- there's no intersection point, return empty sequence -->
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <!--
        INPUT
            pair1, pair2: two cuples of points ((x1,y1),(x2,y2)) e ((x3,y3),(x4,y4)), each defines
                one straight line
        OUTPUT
            the intersection point of two straight lines, or an emtpy sequence if no intersection
            point is found (the two straights are parallel)
    -->
    <xsl:function name="utls:straight-intersection-by-points" as="node()?">
        <xsl:param name="pair1" as="node()+"/>
        <xsl:param name="pair2" as="node()+"/>
        
        <xsl:variable name="straight1" as="node()?" select="utls:new-straight($pair1[1],$pair1[2])"/>
        <xsl:variable name="straight2" as="node()?" select="utls:new-straight($pair2[1],$pair2[2])"/>
        <xsl:sequence select="if (exists($straight1) and exists($straight2)) then
            utls:straight-intersection($straight1,$straight2) else ()"/>
    </xsl:function>
    
    
    <!--
        INPUT
            straight1, straight: two straight lines, each defined by an xml node (see utls:new-point)
        OUTPUT
            the intersection point of two straight lines, or an emtpy sequence if no intersection
            point is found (the two straights are parallel)
    -->
    <xsl:function name="utls:straight-intersection" as="node()?">
        <xsl:param name="straight1" as="node()"/>
        <xsl:param name="straight2" as="node()"/>
        
        <xsl:choose>
            
            <!-- the two straight lines are neither vertical nor parallel -->
            <xsl:when test="
                (every $straight in ($straight1,$straight2) satisfies 
                    ($straight/@type eq '&generic-straight;')) and 
                (xs:double($straight1/@m) ne xs:double($straight2/@m))">
                
                <!-- the intersection point's x value is x=(q1-q2)/(m2-m1) -->
                <xsl:variable name="x" as="xs:double" select="
                    (xs:double($straight1/@q) - xs:double($straight2/@q))
                    div (xs:double($straight2/@m) - xs:double($straight1/@m))"/>
                
                <!-- the intersection point's y value is y=(m1q2-m2q1)/(m1-m2) but we
                    simply obtained it replacing the found x value in the equation 
                    of one of the straight lines -->
                <xsl:variable name="y" as="xs:double" select="
                    (xs:double($straight1/@m) * $x) + xs:double($straight1/@q)"/>
                
                <xsl:sequence select="utls:new-point($x,$y)"/>
            </xsl:when>
            
            <!-- only one straight line is vertical -->            
            <xsl:when test="
                (some $straight in ($straight1,$straight2) satisfies 
                    ($straight/@type eq '&generic-straight;')) and  
                (some $straight in ($straight1,$straight2) satisfies 
                    ($straight/@type eq '&vertical-straight;'))">
                
                <xsl:variable name="vertical-straight" as="node()" select="
                    if ($straight1/@type eq '&vertical-straight;') then $straight1 else $straight2"/>
                <xsl:variable name="other-straight" as="node()" select="
                    if ($vertical-straight is $straight1) then $straight2 else $straight1"/>
                
                <xsl:variable name="x" as="xs:double" select="$vertical-straight/@x"/>
                <xsl:variable name="y" as="xs:double" 
                    select="(xs:double($other-straight/@m) * $x) + xs:double($other-straight/@q)"/>
                
                <xsl:sequence select="utls:new-point($x,$y)"/>
            </xsl:when>
            
            <!-- if two straight lines are paralled: 
                error (no intersection point bwtween two parallel line) -->
            <xsl:otherwise>
                <xsl:sequence select="()"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    
    <!--
        INPUT
            point1, point2: two points (x1,y1),(x2,y2) of Cartesian plane
        OUTPUT
            an xml node representing the straight line y=mx+q defined by the two points
    -->
    <xsl:function name="utls:new-straight" as="node()">
        <xsl:param name="point1" as="node()"/>
        <xsl:param name="point2" as="node()"/>
        
        <!-- choose based on the straight's slope -->
        <xsl:choose>

            <!-- not vertical straight line -->
            <xsl:when test="xs:double($point1/@x) ne xs:double($point2/@x)">
                <xsl:element name="straight" namespace="{$rtf-namespace}">
                    <xsl:attribute name="type">&generic-straight;</xsl:attribute>
                    
                    <!-- straight's slope: m=(y1-y2)/(x1-x2) -->
                    <xsl:attribute name="m" select="(xs:double($point1/@y) -xs:double($point2/@y)) 
                        div (xs:double($point1/@x) -xs:double($point2/@x))"/>
                    
                    <!-- ordinate at the origin: q=(x1y2-x2y1)/(x1-x2) -->
                    <xsl:attribute name="q" select="((xs:double($point1/@x) * xs:double($point2/@y)) 
                        -(xs:double($point2/@x) * xs:double($point1/@y))) 
                        div (xs:double($point1/@x) -xs:double($point2/@x))"/>
                </xsl:element>
            </xsl:when>
            
            <!-- vertical straight line -->
            <xsl:when test="(xs:double($point1/@x) eq xs:double($point2/@x)) 
                    and (xs:double($point1/@y) ne xs:double($point2/@y))">
                <xsl:element name="straight" namespace="{$rtf-namespace}">
                    <xsl:attribute name="type">&vertical-straight;</xsl:attribute>
                    <xsl:attribute name="x" select="$point1/@x"/>
                </xsl:element>
            </xsl:when>
            
            <!-- the two points have same coordinates, i.e. they are the same point:
                error (it is not possible to determine the equation of the straight line) -->
            <xsl:otherwise>
                <xsl:sequence select="error(QName($error-namespace,'utls:new-straight'),
                    'through a single point pass an infinite number of straight lines')"/>
            </xsl:otherwise>
            
        </xsl:choose>
    </xsl:function>
    
    
    <!-- 
        INPUT
            x, y: two coordinates on Cartesian plane
        OUTPUT
            an xml node representing the point (x,y)
    -->
    <xsl:function name="utls:new-point" as="node()">
        <xsl:param name="x" as="xs:double"/>
        <xsl:param name="y" as="xs:double"/>
        
        <xsl:element name="point" namespace="{$rtf-namespace}">
            <xsl:attribute name="x" select="$x"/>
            <xsl:attribute name="y" select="$y"/>
        </xsl:element>
    </xsl:function>
    
    
    <!-- 
        INPUT
            p1, p2: two points (x1,y2),(x2,y2) of Cartesian plane
        OUTPUT
            the distance between the p1 and p2: sqrt(delta(x)^2 + delta(y)^2)
    -->
    <xsl:function name="utls:point-to-point-distance" as="xs:double" >
        <xsl:param name="p1" as="node()"/>
        <xsl:param name="p2" as="node()"/>
        
        <xsl:variable name="delta-x" as="xs:double" select="xs:double($p1/@x) -xs:double($p2/@x)"/>
        <xsl:variable name="delta-y" as="xs:double" select="xs:double($p1/@y) -xs:double($p2/@y)"/>
        <xsl:sequence select="utls:sqrt(($delta-x * $delta-x) + ($delta-y * $delta-y))"/>
    </xsl:function>
    
    
    <!--
        INPUT
            num: a real number
        OUTPUT
            num's root square, calculated calculated with $sqrt-precision (config.xml).
    -->
    <xsl:function name="utls:sqrt" as="xs:double">
        <xsl:param name="num" as="xs:double"/>
        
        <xsl:choose>
            
            <!-- num is a positive real number -->
            <xsl:when test="$num gt 0">
                <xsl:sequence select="utls:sqrt-aux($num, $num div 2)"/>
            </xsl:when>
            
            <!-- num is zero (trivial case) -->
            <xsl:when test="$num eq 0">
                <xsl:sequence select="0"/>
            </xsl:when>
            
            <!-- num is a negative number: error -->
            <xsl:otherwise>
                <xsl:sequence select="error( QName($error-namespace, 'utls:sqrt'),
                    'impossible to extract the square root of a negative number' )"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <!--
        INPUT
            num: a real number
            approximation: current approximation of num's root square
        OUTPUT
            The num's root square calculated with $sqrt-precision (config.xml)
            through Newton-Raphson method based on successive approximations:
            the n+1 root square approximation of N is: a(n+1) = (a(n) + N/a(n)) / 2
    -->
    <xsl:function name="utls:sqrt-aux" as="xs:double">
        <xsl:param name="num" as="xs:double"/>
        <xsl:param name="approximation" as="xs:double"/>
        
        <!-- calculate the error of current approximation -->
        <xsl:variable name="error" as="xs:double" 
            select="abs($num -($approximation * $approximation))"/>
        
        <!-- choose based on the error value -->
        <xsl:choose>
            
            <!-- error is lower than the required precision:
                return current approximation -->
            <xsl:when test="$error le $sqrt-precision">
                <xsl:sequence select="$approximation"/>
            </xsl:when>
            
            <!-- else: recall yourself with next approximation -->
            <xsl:otherwise>
                <xsl:sequence select="utls:sqrt-aux(
                    $num, (($approximation + ($num div $approximation)) div 2) )"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    
</xsl:stylesheet>
