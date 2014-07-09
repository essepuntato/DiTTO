<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet SYSTEM "entities.dtd">
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:g="http://graphml.graphdrawing.org/xmlns"
    xmlns:y="http://www.yworks.com/xml/graphml"
    xmlns:utls="http://www.essepuntato.it/graffoo/utils"
    xmlns:rtf="http://www.essepuntato.it/graffoo/resultTreeFragment/">

    <xsl:import href="config.xsl"/>
    <xsl:import href="utils.xsl"/>


    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                Import GraphML elements
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    <!-- 
        Import all Graffoo widgets, generating specific XML elements with specific attributes:
        
            ontology: id, name, main-ontology
            prefix: prefix, uri, ontology-id
            
            datarange: id, name, ontology-id, appearance
            datarange-restriction: id, name, ontology-id
            class: id, name, ontology-id, appearance
            class-restriction: id, name, ontology-id
            individual: id, name, ontology-id, appearance
            literal: id, name, ontology-id
            
            data-property: id, name, source-id, target-id, ontology-id
            object-property: id, name, source-id, target-id, ontology-id
            annotation-property: id, name, source-id, target-id, ontology-id
            
            data-property-facility: id, name, ontology-id
            object-property-facility: id, name, ontology-id
            annotation-property-facility: id, name, ontology-id
            
            axiom: id, name, source-id, target-id, ontology-id [, owl-axiom, domain-type, range-type] 
            
            additional-axiom: name, target-id, ontology-id [, auto-generated]
            rule: name, ontology-id
    	
        All IDs references are lists of white space separated IDs 
    --> 
    
    
    <!-- RTF of all ontology's widgets -->
    <xsl:variable name="ontologies-from-graphml" as="node()">
        <xsl:element name="ontologies" namespace="{$rtf-namespace}">
        
        <xsl:for-each select="$root//g:node[utls:is-an-ontology(.)]">
            
            <xsl:variable name="ontology" as="node()" select="current()"/>
            <xsl:variable name="id" as="xs:string" select="@id"/>
            <xsl:variable name="name" as="xs:string" select="utls:get-node-name($ontology)"/>
            
            <xsl:element name="ontology" namespace="{$rtf-namespace}">
                <xsl:attribute name="id" select="$id"/>
                <xsl:attribute name="name" select="$name"/>
            </xsl:element>
            
            
            <!-- rdfs:label and rdfs:comment annotations from eventual widget's
                user defined description -->
            
            <xsl:variable name="description" as="xs:string?" 
                select="utls:get-entity-description($ontology)"/>
            
            <xsl:if test="exists($description)">
                
                <xsl:variable name="rdfs-label" as="xs:string?" select="utls:transform-to-literal-string(
                    utls:get-entity-rdfs-label($description))"/>
                
                <xsl:if test="exists($rdfs-label)">
                    
                    <xsl:variable name="rdfs-comment" as="xs:string?" select="utls:transform-to-literal-string(
                        utls:get-entity-rdfs-comment($description))"/>
                    
                    <xsl:element name="additional-axiom" namespace="{$rtf-namespace}">
                        <xsl:attribute name="name" select="concat('Annotations: rdfs:label ', $rdfs-label,
                            if (exists($rdfs-comment)) then concat(', rdfs:comment ', $rdfs-comment) else ())"/>
                        <xsl:attribute name="target-id" select="$id"/>
                        <xsl:attribute name="auto-generated"/>
                        <xsl:if test="$debug">
                            <xsl:attribute name="target-name" select="$name"/>
                        </xsl:if>
                    </xsl:element>
                </xsl:if>
            </xsl:if>
            
        </xsl:for-each>


        <!-- if there's some entity node that not belongs to any ontology,
            create an ontology element with default id and default name (config.xsl) -->
        <xsl:if test="exists($root/g:graphml/g:graph/g:node[utls:is-a-class(.) or 
            utls:is-a-class-restriction(.) or utls:is-a-datarange(.) or 
            utls:is-a-datarange-restriction(.) or utls:is-an-individual(.)])">
            <xsl:element name="ontology" namespace="{$rtf-namespace}">
                <xsl:attribute name="id" select="$default-ontology-id"/>
                <xsl:attribute name="name" select="$default-ontology-iri"/>
            </xsl:element>
        </xsl:if>
            
        </xsl:element>
    </xsl:variable>
    
    
    
    <!-- RTF of all prefixes imported from prefix boxes -->
    <xsl:variable name="prefixes-from-graphml" as="node()">
        <xsl:element name="prefixes" namespace="{$rtf-namespace}">
        
        <xsl:for-each select="$root//g:node[utls:is-a-prefixes-box(.)]">
            
            <!-- get the ontology that holds current prefixes box -->
            <xsl:variable name="ontology-id" as="xs:string" 
                select="utls:ontology-membership(current())"/>
            
            <!-- get all prefixes and respective IRIs delared in current prefixes box -->
            <xsl:variable name="prefixes" as="xs:string*" 
                select="utls:get-prefixes-from-prefixes-box(current())"/>
            <xsl:variable name="uris" as="xs:string*" 
                select="utls:get-uris-from-prefixes-box(current())"/>
            
            <!-- create a prefix node for each declared prefix -->
            <xsl:for-each select="$prefixes">
                
                <xsl:element name="prefix" namespace="{$rtf-namespace}">
                    <xsl:attribute name="prefix" select="current()"/>
                    <xsl:attribute name="uri" select="$uris[index-of($prefixes, current())]"/>
                    <xsl:attribute name="ontology-id" select="$ontology-id"/>
                    <xsl:if test="$debug">
                        <xsl:attribute name="ontology-name" 
                            select="utls:get-ontology-name-by-id($ontology-id)"/>
                    </xsl:if>
                </xsl:element>
                
            </xsl:for-each>
        </xsl:for-each>
        
        </xsl:element>
    </xsl:variable>
    
    
    
    <!-- RTF of all axioms (edges in Graffoo) --> 
    <xsl:variable name="axioms-from-graphml" as="node()">
        <xsl:element name="axioms" namespace="{$rtf-namespace}">
            
        <xsl:for-each select="$root//g:edge[utls:is-an-axiom(.)]">
            
            <xsl:variable name="edge" as="node()" select="current()"/>
            <xsl:variable name="source-id" as="xs:string" select="utls:get-edge-source-id($edge)"/>
            <xsl:variable name="target-id" as="xs:string" select="utls:get-edge-target-id($edge)"/>
            <xsl:variable name="ontology-id" as="xs:string" select="utls:ontology-membership($edge)"/>
            
            <!-- extract each effective label of edge and generate an univocal id for it -->
            <xsl:variable name="labels" as="node()" select="utls:generate-labels-and-ids-by-edge($edge)"/>
            
            <!-- for each effective edge's label create a node named with the entity's type
                and an eventual additional axiom to maintain rdfs:label and rdfs:comment annotations -->
            <xsl:for-each select="$labels/rtf:label">
                <xsl:variable name="axiom" as="node()" select="utls:search-for-manchester-axiom(@name)"/>
                
                <xsl:element name="axiom" namespace="{$rtf-namespace}">
                    <xsl:attribute name="id" select="@id"/>
                    <xsl:attribute name="name" select="$axiom/@name"/>
                    <xsl:attribute name="source-id" select="$source-id"/>
                    <xsl:attribute name="target-id" select="$target-id"/>
                    <xsl:attribute name="ontology-id" select="$ontology-id"/>
                    
                    <xsl:if test="$debug">
                        <xsl:attribute name="source-name" select="utls:get-node-name-by-id($source-id)"/>
                        <xsl:attribute name="target-name" select="utls:get-node-name-by-id($target-id)"/>
                        <xsl:attribute name="ontology-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                    </xsl:if>
                    
                    <xsl:copy-of select="$axiom/@owl-axiom, $axiom/@domain-type, $axiom/@range-type"/>
                </xsl:element>
                
            </xsl:for-each>
        </xsl:for-each>
            
        </xsl:element>
    </xsl:variable>
    
    
    
    <!-- RTF of all additional axiom widgets -->
    <xsl:variable name="additional-axioms-from-graphml" as="node()">
        <xsl:element name="additional-axioms" namespace="{$rtf-namespace}">
            
        <xsl:for-each select="$root//g:node[utls:is-an-additional-axiom(.)]">
            
            <xsl:variable name="axiom" as="node()" select="current()"/>
            <xsl:variable name="target-ids" as="xs:string+" select="utls:axiom-refers-to($axiom)"/>
            
            <xsl:choose>
                
                <!-- the axiom refers to node entity (one or more) -->
                <xsl:when test="exists($root//g:node[utls:contains-id(@id, $target-ids)])">
                    
                    <xsl:variable name="target-nodes" as="node()+" select="$root//g:node[utls:contains-id(@id, $target-ids)]"/>
                    
                    <!-- for each node referred by the axiom generate an additional axiom node 
                        that refers to it -->
                    <xsl:for-each select="$target-nodes">
                        <xsl:variable name="target-node" as="node()" select="current()"/>
                        
                        <!-- the ontology that holds current node -->
                        <xsl:variable name="ontology-id" as="xs:string" select="utls:ontology-membership($target-node)"/>
                        
                        <xsl:element name="additional-axiom" namespace="{$rtf-namespace}">
                            <xsl:attribute name="name" select="utls:get-uncommented-manchester-node-name($axiom)"/>
                            <xsl:attribute name="target-id" select="@id"/> 
                            <xsl:attribute name="ontology-id" select="$ontology-id"/>
                            
                            <xsl:if test="$debug">
                                <xsl:attribute name="target-name" select="utls:get-node-name($target-node)"/>
                                <xsl:attribute name="ontology-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                            </xsl:if>
                            
                        </xsl:element>
                    </xsl:for-each>
                </xsl:when>
                
                <!-- the axiom refers to ONE property declaration/facility -->
                <xsl:otherwise>
                    
                    <!-- the ontology that holds current edge -->
                    <xsl:variable name="ontology-id" as="xs:string" 
                        select="utls:ontology-membership(utls:get-edge-by-edgelabel-id($target-ids))"/>
                    
                    <!-- extract each effective property's label and generate an univocal id for it -->
                    <xsl:variable name="labels" as="node()" select="
                        utls:generate-labels-and-ids-by-edgelabel(utls:get-edgelabel-by-id($target-ids))"/>
                    
                    <!-- for each effective label (there's or there will be a dedicated property node) 
                        generate an additional axiom node that refers to it -->
                    <xsl:for-each select="$labels//rtf:label">
                        
                        <xsl:element name="additional-axiom" namespace="{$rtf-namespace}">
                            <xsl:attribute name="name" select="utls:get-node-name($axiom)"/>
                            <xsl:attribute name="target-id" select="@id"/>
                            <xsl:attribute name="ontology-id" select="$ontology-id"/>
                            
                            <xsl:if test="$debug">
                                <xsl:attribute name="target-name" select="@name"/>
                                <xsl:attribute name="ontology-name" 
                                    select="utls:get-ontology-name-by-id($ontology-id)"/>
                            </xsl:if>
                        </xsl:element>
                        
                    </xsl:for-each>
                </xsl:otherwise>
                
            </xsl:choose>
        </xsl:for-each>
            
        </xsl:element>
    </xsl:variable>
    
    
    
    <!-- RTF of all entity node widgets: datarange (simple or restriction), class (simple or restriction),
        individual and literal -->
    <xsl:variable name="entity-nodes-from-graphml" as="node()">
        <xsl:element name="entity-nodes" namespace="{$rtf-namespace}">
        
        <xsl:for-each select="$root//g:node[utls:is-a-datarange(.) or utls:is-a-datarange-restriction(.)
            or utls:is-a-class(.) or utls:is-a-class-restriction(.) or utls:is-an-individual(.) or
            utls:is-a-literal(.)]">
            
            <xsl:variable name="node" as="node()" select="current()"/>
            
            <!-- get current entity's type -->
            <xsl:variable name="type" as="xs:string" select="
                if (utls:is-a-datarange($node)) then '&datarange;' else (
                if (utls:is-a-datarange-restriction($node)) then '&datarange-restriction;' else (
                if (utls:is-a-class($node)) then '&class;' else (
                if (utls:is-a-class-restriction($node)) then '&class-restriction;' else (
                if (utls:is-an-individual($node)) then '&individual;' else '&literal;'))))"/>
            
            <xsl:variable name="id" as="xs:string" select="@id"/>
            <xsl:variable name="name" as="xs:string" select="if ($type = ('&datarange-restriction;',
                '&class-restriction;')) then utls:get-uncommented-manchester-node-name($node)
                else utls:get-node-name($node)"/>
            <xsl:variable name="ontology-id" as="xs:string" select="utls:ontology-membership($node)"/>
            
            <!-- create a node named with the entity's type -->
            <xsl:element name="{$type}" namespace="{$rtf-namespace}">
                <xsl:attribute name="id" select="$id"/>
                <xsl:attribute name="name" select="$name"/>
                <xsl:attribute name="ontology-id" select="$ontology-id"/>
                <xsl:if test="$debug">
                    <xsl:attribute name="ontology-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                </xsl:if>
            </xsl:element>
            
            
            <!-- maintain appearance info? (only for classes, dataranges and individuals
                because these info will be simply store as annotations) -->
            <xsl:if test="$maintain-appearance and (utls:is-a-class($node) or 
                utls:is-a-class-restriction($node) or utls:is-a-datarange($node) or 
                utls:is-a-datarange-restriction($node) or utls:is-an-individual($node))">
                
                <xsl:element name="&additional-axiom;" namespace="{$rtf-namespace}">
                    <xsl:attribute name="name" select="concat('Annotations: ', $has-appearance-property, ' ',
                        utls:transform-to-literal-string(utls:get-node-appearance($node)))"/>
                    <xsl:attribute name="target-id" select="$id"/>
                    <xsl:attribute name="auto-generated"/>
                    <xsl:if test="$debug">
                        <xsl:attribute name="target-name" select="$name"/>
                    </xsl:if>
                </xsl:element>
            </xsl:if>
            
            
            <!-- rdfs:label and rdfs:comment annotations from eventual widget's
                user defined description -->
            
            <xsl:variable name="description" as="xs:string?" 
                select="utls:get-entity-description($node)"/>
            
            <xsl:if test="exists($description)">
                
                <xsl:variable name="rdfs-label" as="xs:string?" select="utls:transform-to-literal-string(
                    utls:get-entity-rdfs-label($description))"/>
                
                <xsl:if test="exists($rdfs-label)">
                    
                    <xsl:variable name="rdfs-comment" as="xs:string?" select="utls:transform-to-literal-string(
                        utls:get-entity-rdfs-comment($description))"/>
                    
                    <xsl:element name="&additional-axiom;" namespace="{$rtf-namespace}">
                        <xsl:attribute name="name" select="concat('Annotations: rdfs:label ',$rdfs-label,
                            if (exists($rdfs-comment)) then concat(', rdfs:comment ',$rdfs-comment) else ())"/>
                        <xsl:attribute name="target-id" select="$id"/>
                        <xsl:attribute name="ontology-id" select="$ontology-id"/>
                        <xsl:if test="$debug">
                            <xsl:attribute name="target-name" select="$name"/>
                            <xsl:attribute name="ontology-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                        </xsl:if>
                    </xsl:element>
                </xsl:if>
            </xsl:if>
            
            
            <!-- rdfs:isDefinedBy annotation if not already defined -->
            
            <xsl:variable name="rdfs-is-defined-by" as="xs:string" select="utls:get-imported-ontology-iri(
                $ontologies-from-graphml/rtf:*[utls:contains-id(@id, $ontology-id)]/@name)"/>
            
            <xsl:element name="additional-axiom" namespace="{$rtf-namespace}">
                <xsl:attribute name="name" select="concat('Annotations: rdfs:isDefinedBy ', $rdfs-is-defined-by)"/>
                <xsl:attribute name="target-id" select="$id"/>
                <xsl:attribute name="ontology-id" select="$ontology-id"/>
                <xsl:attribute name="auto-generated"/>
                <xsl:if test="$debug">
                    <xsl:attribute name="target-name" select="$name"/>
                    <xsl:attribute name="ontology-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                </xsl:if>
            </xsl:element>
        
        </xsl:for-each>
            
        </xsl:element>
    </xsl:variable>
    


    <!-- RTf of all property declarations and facilities -->
    <xsl:variable name="properties-from-graphml" as="node()">
        <xsl:element name="properties" namespace="{$rtf-namespace}">
        
        <xsl:for-each select="$root//g:edge[utls:is-a-dataproperty(.) or
            utls:is-a-dataproperty-facility(.) or utls:is-an-objectproperty(.) or
            utls:is-an-objectproperty-facility(.) or utls:is-an-annotationproperty(.) or
            utls:is-an-annotationproperty-facility(.)]">
            
            <xsl:variable name="edge" as="node()" select="current()"/>
            <xsl:variable name="source-id" as="xs:string" select="utls:get-edge-source-id($edge)"/>
            <xsl:variable name="target-id" as="xs:string" select="utls:get-edge-target-id($edge)"/>
            <xsl:variable name="ontology-id" as="xs:string" select="utls:ontology-membership($edge)"/>
            
            <!-- extract each effective label of edge and generate an univocal id for it -->
            <xsl:variable name="labels" as="node()" select="utls:generate-labels-and-ids-by-edge($edge)"/>
            
            <!-- get current edge's type -->
            <xsl:variable name="type" as="xs:string" select="
                if (utls:is-a-dataproperty($edge)) then '&data-property;' else (
                if (utls:is-a-dataproperty-facility($edge)) then '&data-property-facility;' else (
                if (utls:is-an-objectproperty($edge)) then '&object-property;' else (
                if (utls:is-an-objectproperty-facility($edge)) then '&object-property-facility;' else (
                if (utls:is-an-annotationproperty($edge)) then '&annotation-property;' 
                else '&annotation-property-facility;'))))"/>
            
            <!-- for each effective edge's label create a node named with the entity's type
                and an eventual additional axiom to maintain rdfs:label and rdfs:comment annotations -->
            <xsl:for-each select="$labels/rtf:label">
                
                <xsl:variable name="id" as="xs:string" select="@id"/>
                <xsl:variable name="name" as="xs:string" select="@name"/>
                
                <xsl:element name="{$type}" namespace="{$rtf-namespace}">
                    <xsl:attribute name="id" select="$id"/>
                    <xsl:attribute name="name" select="$name"/>
                    
                    <!-- property facilities haven't domain and range -->
                    <xsl:if test="not($type = ('&data-property-facility;', '&object-property-facility;', 
                        '&annotation-property-facility;'))">
                        
                        <xsl:attribute name="source-id" select="$source-id"/>
                        <xsl:attribute name="target-id" select="$target-id"/>
                    </xsl:if>
                    
                    <xsl:attribute name="ontology-id" select="$ontology-id"/>
                    
                    <xsl:if test="$debug">
                        <xsl:attribute name="source-name" 
                            select="utls:get-node-name-by-id($source-id)"/>
                        <xsl:attribute name="target-name" 
                            select="utls:get-node-name-by-id($target-id)"/>
                        <xsl:attribute name="ontology-name" 
                            select="utls:get-ontology-name-by-id($ontology-id)"/>
                    </xsl:if>
                    
                </xsl:element>
                
                
                <!-- rdfs:label and rdfs:comment annotations from eventual 
                     user defined description -->
                
                <xsl:variable name="description" as="xs:string?" 
                    select="utls:get-entity-description($edge)"/>
                
                <xsl:if test="exists($description)">
                    
                    <xsl:variable name="rdfs-label" as="xs:string?" select="utls:transform-to-literal-string(
                        utls:get-entity-rdfs-label($description))"/>
                    
                    <xsl:if test="exists($rdfs-label)">
                        
                        <xsl:variable name="rdfs-comment" as="xs:string?" select="utls:transform-to-literal-string(
                            utls:get-entity-rdfs-comment($description))"/>
                        
                        <xsl:element name="&additional-axiom;" namespace="{$rtf-namespace}">
                            <xsl:attribute name="name" select="concat('Annotations: rdfs:label ',$rdfs-label,
                                if (exists($rdfs-comment)) then concat(', rdfs:comment ',$rdfs-comment) else ())"/>
                            <xsl:attribute name="target-id" select="$id"/>
                            <xsl:attribute name="ontology-id" select="$ontology-id"/>
                            <xsl:attribute name="auto-generated"/>
                            <xsl:if test="$debug">
                                <xsl:attribute name="target-name" select="$name"/>
                                <xsl:attribute name="ontology-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                            </xsl:if>
                        </xsl:element>
                    </xsl:if>
                </xsl:if>
                
                
                <!-- rdfs:isDefinedBy annotation if not already defined -->
                
                <xsl:variable name="rdfs-is-defined-by" as="xs:string" select="utls:get-imported-ontology-iri(
                    $ontologies-from-graphml/*[utls:contains-id(@id,$ontology-id)]/@name)"/>
                
                <xsl:element name="&additional-axiom;" namespace="{$rtf-namespace}">
                    <xsl:attribute name="name" select="concat('Annotations: rdfs:isDefinedBy ',$rdfs-is-defined-by)"/>
                    <xsl:attribute name="target-id" select="$id"/>
                    <xsl:attribute name="auto-generated"/>
                    <xsl:if test="$debug">
                        <xsl:attribute name="target-name" select="$name"/>
                    </xsl:if>
                </xsl:element>
            
            </xsl:for-each>
        </xsl:for-each>
            
            
        <!-- maintain appearance info? (only for classes, dataranges and individuals
            because these info will be simply store as annotations) -->
        <xsl:if test="$maintain-appearance">
            
            <!-- declare an annotation property "graffoo:hasAppearance" in each ontologies
                 to maintain appearance info of simple nodes -->
            <xsl:element name="&annotation-property;" namespace="{$rtf-namespace}">
                <xsl:attribute name="name" select="$has-appearance-property"/>
                <xsl:attribute name="ontology-id" select="
                    string-join($ontologies-from-graphml/rtf:&ontology;/@id, ' ')"/>
            </xsl:element>
        </xsl:if>

        </xsl:element>
    </xsl:variable>



    <!-- RTF of all external rule widgets -->
    <xsl:variable name="rules-from-graphml" as="node()">
        <xsl:element name="rules" namespace="{$rtf-namespace}">
        
        <xsl:for-each select="$root//g:node[utls:is-an-external-rule(.)]">
            
            <xsl:variable name="rule" as="node()" select="current()"/>
            <xsl:variable name="rule-value" as="xs:string" select="utls:get-node-name(g:graph/g:node)"/>
            <xsl:variable name="language" as="xs:string" select="lower-case(utls:get-node-name($rule))"/>
            <xsl:variable name="ontology-id" as="xs:string" select="utls:ontology-membership($rule)"/>
            
            <!-- choice according to the language -->
            <xsl:choose>
                
                <!-- SWRL rule -->
                <xsl:when test="$language eq '&swrl-language;'">
                    
                    <xsl:element name="&rule;" namespace="{$rtf-namespace}">
                        <xsl:attribute name="name" select="utls:swrl-to-manchester($rule-value)"/>
                        <xsl:attribute name="ontology-id" select="$ontology-id"/>
                        <xsl:if test="$debug">
                            <xsl:attribute name="ontology-name" 
                                select="utls:get-ontology-name-by-id($ontology-id)"/>
                        </xsl:if>
                    </xsl:element>
                    
                </xsl:when>
                
                <!-- rule expressed in other language (for example SPARQL) -->
                <xsl:otherwise>

                    <!-- define the IRI "graffoo:has<Lang>Rule" (the base IRI is defined in config.xml) -->
                    <xsl:variable name="predicate" as="xs:string" select="utls:get-has-lang-rule-iri($language)"/>
                    
                    <!-- declare an annotation property to maintain the rule (the node will be replicated
                        if there're more external rule with same language != SWRL) -->
                    <xsl:element name="&annotation-property;" namespace="{$rtf-namespace}">
                        <xsl:attribute name="name" select="$predicate"/>
                        <xsl:attribute name="ontology-id" select="$ontology-id"/>
                        <xsl:if test="$debug">
                            <xsl:attribute name="ontology-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                        </xsl:if>
                    </xsl:element>
                    
                    <!-- the rule is imported as an additional axiom referred to current ontology -->
                    <xsl:element name="&additional-axiom;" namespace="{$rtf-namespace}">
                        <xsl:attribute name="name" select="concat('Annotations: ', $predicate, ' ',
                            utls:transform-to-literal-string($rule-value))"/>
                        <xsl:attribute name="target-id" select="$ontology-id"/>
                        <xsl:attribute name="ontology-id" select="$ontology-id"/>
                        <xsl:if test="$debug">
                            <xsl:attribute name="target-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                            <xsl:attribute name="ontology-name" select="utls:get-ontology-name-by-id($ontology-id)"/>
                        </xsl:if>
                    </xsl:element>
                    
                </xsl:otherwise>
                
            </xsl:choose>
        </xsl:for-each>
            
        </xsl:element>
    </xsl:variable>

    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    Punning based on axioms
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    
    <!-- perform the entities's punning based on axioms that relate them --> 
    <xsl:template name="punning">
        <xsl:param name="rtf" as="node()"/>
            
        <xsl:for-each select="$rtf/rtf:&axiom;">
            <xsl:variable name="axiom" as="node()" select="current()"/>
            
            <xsl:variable name="source-entity" as="node()" select="$rtf/rtf:*[utls:contains-id(@id,$axiom/@source-id)]"/>
            <xsl:variable name="source-type" as="xs:string" select="local-name($source-entity)"/>
            
            <xsl:variable name="target-entity" as="node()" select="$rtf/rtf:*[utls:contains-id(@id,$axiom/@target-id)]"/>
            <xsl:variable name="target-type" as="xs:string" select="local-name($target-entity)"/>
            
            
            <!-- new type of axiom's source/target node -->
            <xsl:variable name="new-types" as="xs:string+">
                
                <!-- analyze both source and target entity -->
                <xsl:for-each select="$source-entity,$target-entity">
                    
                    <xsl:variable name="current-entity" as="node()" select="current()"/>
                    <xsl:variable name="other-entity" as="node()" select="if (current() is $source-entity)
                        then $target-entity else $source-entity"/>
                    
                    <xsl:variable name="current-type" as="xs:string" select="local-name($current-entity)"/>
                    <xsl:variable name="other-type" as="xs:string" select="local-name($other-entity)"/>
                    
                    <xsl:variable name="current-accepted-types" as="xs:string?" select="if (current() is $source-entity)
                        then $axiom/@domain-type else $axiom/@range-type"/>
                    <xsl:variable name="other-accepted-types" as="xs:string?" select="if (current() is $source-entity)
                        then $axiom/@range-type else $axiom/@domain-type"/>
                    
                    
                    <!-- new type for current entity -->
                    <xsl:variable name="new-current-type" as="xs:string">
                        
                        <xsl:choose>
                            
                            <!-- the axiom isn't an OWL axiom: the source entity is necessarily an individual,
                                the target entity is an individual if the axiom's predicate uses an object property, 
                                else (data or annotation property) is necessarily a literal -->
                            <xsl:when test="empty($axiom/@owl-axiom)">
                                <xsl:sequence select="if ($current-entity is $source-entity) then 'individual' else
                                    if ($rtf/(rtf:&object-property; | rtf:&object-property-facility;)
                                    [@name eq $axiom/@name]) then '&individual;' else '&literal;'"/>
                            </xsl:when>
                            
                            <!-- the axiom is an OWL axiom and the current node isn't of the required type -->
                            <xsl:when test="exists($axiom/@owl-axiom) and not(contains($current-accepted-types, $current-type))">
                                
                                <xsl:variable name="current-entity-instances-in-graph" as="node()*" 
                                    select="$rtf/rtf:*[@name eq $current-entity/@name]
                                    (: not source/target entity :)[not(utls:contains-id(@id, ($source-entity/@id, $target-entity/@id)))]"/>
                                <xsl:variable name="current-entity-instances-types" as="xs:string*" 
                                    select="for $instance in $current-entity-instances-in-graph return local-name($instance)"/>
                                
                                <xsl:variable name="other-entity-instances-in-graph" as="node()*" 
                                    select="$rtf/rtf:*[@name eq $other-entity/@name]
                                    (: not source/target entity :)[not(utls:contains-id(@id, ($source-entity/@id,$target-entity/@id)))]"/>
                                <xsl:variable name="other-entity-instances-types" as="xs:string*" 
                                    select="for $instance in $other-entity-instances-in-graph return local-name($instance)"/>
                                
                                <!-- 1) the axiom requires source and target entity of same type and the other end-point's type
                                    is one of accepted types. The current node's type is the same of the other end-point -->
                                <xsl:variable name="other-end-point-type-if-util" as="xs:string?" select="
                                    if ($axiom/@domain-type eq $axiom/@range-type and contains($other-accepted-types,$other-type)) then
                                    utls:get-best-entity-type else ()"/>
                                
                                <!-- 2) current entity's type can be found by its other instances in graph -->
                                <xsl:variable name="current-entity-instances-types-if-util" as="xs:string*" 
                                    select="for $type in $current-entity-instances-types return 
                                    if (contains($current-accepted-types, $type)) then 
                                    utls:get-entity-real-type($current-entity/@name, $type) else ()"/>
                                
                                <!-- 3) if the axiom requires source and target entities of same type, the current entity's type
                                     can be found by other entity's instances in graph -->
                                <xsl:variable name="other-entity-instances-types-if-util" as="xs:string*" 
                                    select="if ($axiom/@domain-type eq $axiom/@range-type) then 
                                    (for $type in $other-entity-instances-types return 
                                    if (contains($current-accepted-types, $type)) then 
                                    utls:get-entity-real-type($current-entity/@name, $type) else ()) else ()"/>
                                
                                <!-- 4) if the axiom requires source and target entities not necessarly of same type, the current
                                     entity's type can be found by both the axiom's value and the eventual other entity's instances,
                                     for example for rdfs:domain and rdfs:range axioms -->
                                <xsl:variable name="inferred-type" as="xs:string?">
                                    <xsl:choose>
                                        <xsl:when test="$axiom/@name eq '&domain-axiom;'">
                                            <xsl:sequence select="
                                                if ($current-entity is $target-entity) then 
                                                    (if (some $type in $other-entity-instances-types satisfies 
                                                        $type = ('&object-property;','&object-property-facility;')) 
                                                        then utls:get-entity-real-type($current-entity/@name, '&class;')
                                                     else ())
                                                else ()"/>
                                        </xsl:when>
                                        <xsl:when test="$axiom/@name eq '&range-axiom;'">
                                            <xsl:sequence select="
                                                if ($current-entity is $source-entity) then 
                                                    (if (some $type in $other-entity-instances-types satisfies 
                                                        $type = ('&class;','&class-restriction;')) 
                                                        then utls:get-entity-real-type($current-entity/@name, '&object-property;')
                                                    else ())
                                                else (
                                                    if (some $type in $other-entity-instances-types satisfies 
                                                        $type = ('&object-property;', '&object-property-facility;')) 
                                                        then utls:get-entity-real-type($current-entity/@name, '&class;')
                                                    else if (some $type in $other-entity-instances-types satisfies 
                                                        $type = ('&data-property;', '&data-property-facility;'))
                                                        then utls:get-entity-real-type($current-entity/@name, '&datarange;')
                                                    else ()
                                                )"/>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:variable>

                                <!-- 5) else the current entity's type is the default type accepted by the axiom -->
                                <xsl:variable name="axiom-default-accepted-type" as="xs:string" 
                                    select="utls:get-entity-real-type($current-entity/@name, tokenize($current-accepted-types,' ')[1])"/>                
                                        
                                <!-- the current entity's type is the first between the previous found types -->
                                <xsl:sequence select="($inferred-type, $other-end-point-type-if-util, $current-entity-instances-types-if-util,
                                    $other-entity-instances-types-if-util, $axiom-default-accepted-type)[1]"/>
                                
                            </xsl:when>
                            
                            <!-- the current entity's type is accepted by the axiom: no punning -->
                            <xsl:otherwise>
                                <xsl:sequence select="$current-type"/>
                            </xsl:otherwise>
                            
                        </xsl:choose>
                        
                    </xsl:variable>
                    
                    <xsl:sequence select="$new-current-type"/>
                </xsl:for-each>
                
            </xsl:variable>
                
                
            <xsl:variable name="new-source-type" as="xs:string" select="$new-types[1]"/>
            <xsl:variable name="new-target-type" as="xs:string" select="$new-types[2]"/>
                
                
            <!-- analyze both source and target entity -->
            <xsl:for-each select="$source-entity, $target-entity">

                <xsl:variable name="current-entity" as="node()" select="current()"/>
                <xsl:variable name="current-type" as="xs:string" select="local-name($current-entity)"/>
                <xsl:variable name="new-current-type" as="xs:string" select="
                    if ($current-entity is $source-entity) then $new-source-type else $new-target-type"/>
                
                <!-- if the new type is different from the actual, create a new entity of that type
                     duplicating eventual additional axioms -->
                <xsl:if test="$new-current-type ne $current-type">
                    
                    <xsl:element name="{$new-current-type}" namespace="{$rtf-namespace}">
                        <xsl:attribute name="id" select="utls:generate-punned-entity-id($current-entity, $axiom)"/>
                        <xsl:copy-of select="$current-entity/attribute::*[local-name(.) ne 'id']"/>
                    </xsl:element>
                    
                    <xsl:for-each select="$rtf/rtf:&additional-axiom;[utls:contains-id($current-entity/@id, @target-id)]">
                        <xsl:element name="&additional-axiom;" namespace="{$rtf-namespace}">
                            <xsl:copy-of select="current()/attribute::*[local-name(.) ne 'target-id']"/>
                            <xsl:attribute name="target-id" 
                                select="utls:generate-punned-entity-id($current-entity, $axiom)"/>
                        </xsl:element>
                    </xsl:for-each>
                </xsl:if>
                
            </xsl:for-each>
            
            
            <!-- copy or update the axiom to refer to new nodes -->
            <xsl:element name="&axiom;" namespace="{$rtf-namespace}">
                <xsl:copy-of select="$axiom/attribute::*[not(local-name(.) = ('source-id','target-id'))]"/>
                <xsl:attribute name="source-id" select="if ($source-type eq $new-source-type) then $axiom/@source-id
                    else utls:generate-punned-entity-id($source-entity, $axiom)"/>
                <xsl:attribute name="target-id" select="if ($target-type eq $new-target-type) then $axiom/@target-id
                    else utls:generate-punned-entity-id($target-entity, $axiom)"/>
            </xsl:element>
            
        </xsl:for-each>
            
    </xsl:template>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                Import entities from ontologies
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    
    <!-- import entities that belong to imported ontologies -->
    <xsl:template name="import-entities">
        <xsl:param name="rtf" as="node()"/>
            
        <!-- analyze each entities -->
        <xsl:for-each select="$rtf/rtf:*[contains('&entities;', local-name(.))]">
            <xsl:variable name="entity" as="node()" select="current()"/>
            
            <!-- ontologies that hold a link to current entity, excluded the entity's ontology -->
            <xsl:variable name="ontologies-that-link-current-entity" as="xs:string*" select="$rtf/rtf:*
                [contains('&edges;',local-name(.))][not(utls:contains-id(@ontology-id, $entity/@ontology-id))]
                [utls:contains-id($entity/@id, (@source-id,@target-id))]/@ontology-id"/>
            
            <!-- ontologies that import current entity (directly or indirectly) -->
            <xsl:variable name="ontologies-that-import-current-entity" as="xs:string*" select="$rtf/rtf:&ontology;
                [utls:is-ontology-reachable(@id, $entity/@ontology-id)]/@id"/>
            
            <!-- update current entity's ontology-id attr -->
            <xsl:element name="{local-name(current())}" namespace="{$rtf-namespace}">
                <xsl:copy-of select="attribute::*[local-name(.) ne 'ontology-id']"/>
                <xsl:attribute name="ontology-id" select="
                    (: the entity belong to those ontologies that hold a link to it :)
                    utls:add-ids(@ontology-id, $ontologies-that-link-current-entity)
                    
                    (: the entity belong to those ontologies that import it :)
                    (:utls:add-ids(@ontology-id, $ontologies-that-import-current-entity):)
                    "/>
            </xsl:element>
            
            <!-- update eventual additional axioms referred to current entity -->
            <xsl:for-each select="$rtf/rtf:&additional-axiom;[utls:contains-id($entity/@id, @target-id)]">
                <xsl:element name="&additional-axiom;" namespace="{$rtf-namespace}">
                    <xsl:copy-of select="attribute::*[local-name(.) ne 'ontology-id']"/>
                    <xsl:attribute name="ontology-id" select="
                        (: the axiom belong to those ontologies that hold a link to current entity :)
                        $ontologies-that-link-current-entity 
                        
                        (: the axiom belong to those ontologies that import current entity :)
                        (:$ontologies-that-import-current-entity:)
                        "/>
                </xsl:element>    
            </xsl:for-each>
            
        </xsl:for-each>
            
    </xsl:template>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            Analyze Manchester strings and SWRL rules
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    
    <!-- detect entities not already declared as widgets by the user from Manchester strings and SWRL rules -->
    <xsl:template name="analyze-manchester-strings-and-swrl-rules">
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="entities-not-recognized" as="xs:integer" select="0"/>
        <xsl:param name="is-last-scan" as="xs:boolean" select="false()"/>
        <xsl:param name="scan-num" as="xs:integer" select="1"/>
        
        <!-- get new entities from Manchester strings and SWRL rules -->
        <xsl:variable name="new-entities" as="node()*">
            
            <!-- Manchester strings analysis -->
            <xsl:for-each select="$rtf/(rtf:&class-restriction; | rtf:&datarange-restriction; |
                rtf:&additional-axiom;[not(@auto-generated)])">
                <xsl:copy-of select="utls:get-entities-from-manchester-string(@name, 
                    if (local-name(current()) eq '&class-restriction;') then '&description;' else
                    if (local-name(current()) eq '&datarange-restriction;') then '&datarange;' else
                    local-name($rtf/rtf:*[utls:contains-id(@id, current()/@target-id)][1]), $rtf, @ontology-id, $is-last-scan)"/>
            </xsl:for-each>
            
            <!-- SWRL rules analysis -->
            <xsl:for-each select="$rtf/rtf:&rule;">
                <xsl:copy-of select="utls:get-entities-from-swrl-rule(@name, $rtf, @ontology-id, $is-last-scan)"/>
            </xsl:for-each>
                
        </xsl:variable>
        
        <!-- counts how many entities have not been recognized -->
        <xsl:variable name="updated-entities-not-recognized" as="xs:integer" 
            select="count($new-entities[local-name(.) eq 'not-recognized'])"/>
        
        
        <xsl:choose>
            
            <!-- this scan has recognized new entitites -->
            <xsl:when test="$entities-not-recognized ne $updated-entities-not-recognized and $scan-num lt $scan-limit">
                
                <!-- merge new recognized entities with rtf -->
                <xsl:variable name="updated-rtf" as="node()">
                    <xsl:element name="updated-rtf" namespace="{$rtf-namespace}">
                        <xsl:copy-of select="$rtf/rtf:*"/>
                        
                        <xsl:for-each-group select="$new-entities[local-name(.) ne 'not-recognized']" group-by="@name">
                            <xsl:variable name="entity" as="node()" select="current-group()[1]"/>
                            <xsl:if test="empty($rtf/rtf:*[local-name(.) eq local-name($entity)][@name eq $entity/@name])">
                                <xsl:copy-of select="$entity"/>
                            </xsl:if>
                        </xsl:for-each-group>
                    </xsl:element>
                </xsl:variable>
                
                <!-- re-scan (not definitive scan) with updated rtf -->
                <xsl:call-template name="analyze-manchester-strings-and-swrl-rules">
                    <xsl:with-param name="rtf" select="$updated-rtf"/>
                    <xsl:with-param name="entities-not-recognized" select="$updated-entities-not-recognized"/>
                    <xsl:with-param name="scan-num" select="$scan-num + 1"/>
                </xsl:call-template>
            </xsl:when>
            
            
            <!-- there's no difference from previous scan but there's still some entity not recognized -->
            <xsl:when test="$updated-entities-not-recognized ne 0 and $scan-num lt $scan-limit">
                
                <!-- definitive scan -->
                <xsl:call-template name="analyze-manchester-strings-and-swrl-rules">
                    <xsl:with-param name="rtf" select="$rtf"/>
                    <xsl:with-param name="entities-not-recognized" select="$updated-entities-not-recognized"/>
                    <xsl:with-param name="is-last-scan" select="true()"/>
                    <xsl:with-param name="scan-num" select="$scan-num + 1"/>
                </xsl:call-template>
            </xsl:when>
            
            
            <!-- all entities have been recognized -->
            <xsl:otherwise>
                
                <!-- merge new recognized entities with rtf -->
                <xsl:variable name="updated-rtf" as="node()">
                    <xsl:element name="updated-rtf" namespace="{$rtf-namespace}">
                        <xsl:copy-of select="$rtf/rtf:*"/>
                        
                        <xsl:for-each-group select="$new-entities[local-name(.) ne 'not-recognized']" group-by="@name">
                            <xsl:for-each-group select="current-group()" group-by="local-name(.)">
                                <xsl:variable name="entity" as="node()" select="current-group()[1]"/>
                                <xsl:if test="empty($rtf/rtf:*[local-name(.) eq local-name($entity)][@name eq $entity/@name])">
                                    <xsl:copy-of select="$entity"/>
                                </xsl:if>
                            </xsl:for-each-group>
                        </xsl:for-each-group>
                    </xsl:element>
                </xsl:variable>
                
                <!-- for each Manchester strings, check if 'min', 'max' and 'exactly' property restriction
                    have a primary (see http://www.w3.org/TR/owl2-manchester-syntax/), optional in Manchester
                    syntax specification but required by Manchester validators -->
                <xsl:for-each select="$updated-rtf/(rtf:additional-axiom | rtf:class-restriction)">
                    <xsl:element name="{local-name(current())}" namespace="{$rtf-namespace}">
                        <xsl:copy-of select="@*[local-name(.) ne 'name']"/>
                        <xsl:attribute name="name" select="
                            utls:check-primary-in-property-restriction(@name, $updated-rtf)"/>
                    </xsl:element>
                </xsl:for-each>
                
                <!-- copy all the other elements -->
                <xsl:copy-of select="$updated-rtf/rtf:*[not(local-name(.) = ('&additional-axiom;', '&class-restriction;'))]"/>
            </xsl:otherwise>
            
        </xsl:choose>
        
    </xsl:template>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    Remove duplicates
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    
    <!-- collapse each duplicates in a single entity -->
    <xsl:template name="remove-duplicates">
        <xsl:param name="rtf" as="node()"/>
        
        <!-- analyze each ontology -->
        <xsl:for-each select="$rtf/rtf:&ontology;">
            <xsl:variable name="current-ontology" as="node()" select="current()"/>
            
            <!-- get all duplicated nodes (classes, dataranges, individuals) -->
            <xsl:for-each-group select="$rtf/rtf:*[contains('&nodes;', local-name(.))]
                [utls:contains-id(@ontology-id, $current-ontology/@id)]" group-by="@name">
                
                <!-- create an entity that represents all duplicates -->
                <xsl:element name="{local-name(current())}" namespace="{$rtf-namespace}">
                    <xsl:attribute name="id" select="string-join(for $duplicate in current-group()
                        return $duplicate/@id, ' ')"/>
                    <xsl:copy-of select="@*[local-name(.) ne 'id']"/>
                </xsl:element>
            </xsl:for-each-group>
            
        </xsl:for-each>
        
        <!-- copy all not node entities -->
        <xsl:copy-of select="$rtf/rtf:*[not(contains('&nodes;', local-name(.)))]"/>
        
    </xsl:template>
    
    
    
    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    Translate to Manchester
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    
    <!-- sort and translate in Manchester OWL syntax -->
    <xsl:template name="translate-to-manchester">
        <xsl:param name="rtf" as="node()"/>
        
        <!-- analyze each ontologies -->
        <xsl:for-each select="$rtf/rtf:&ontology;">
            
            <xsl:variable name="current-ontology" as="node()" select="current()"/>
            <xsl:variable name="current-ontology-id" as="xs:string" select="$current-ontology/@id"/>
            
            <xsl:element name="ontology" namespace="{$rtf-namespace}">
                
                <!-- current ontology is the main ontology if it is not imported by any other ontologies -->
                <xsl:variable name="is-the-main-ontology" as="xs:boolean" 
                    select="not(exists($rtf/rtf:&axiom;[@name eq '&import-axiom;']
                    [utls:contains-id(@target-id, $current-ontology-id)]))"/>
                
                <!-- for each ontology create an ontology node that contains the Manchester statements
                    that define it -->
                <xsl:copy-of select="attribute::*"/>
                <xsl:if test="$is-the-main-ontology">
                    <xsl:attribute name="main-ontology"/>
                </xsl:if>
                
                <xsl:text>&newline;</xsl:text>


                <!-- prefixes declaration -->
                
                <!-- simple entities to verify the use of empty prefix -->
                <xsl:variable name="simple-entities" as="xs:string*" select="$rtf/rtf:*[contains('&nodes-for-empty-prefix;', local-name(.))]
                    [utls:contains-id(@ontology-id, $current-ontology-id)]/@name"/>
                
                <!-- if there're entities that use the empty prefix -->
                <!-- esistono entità (semplici) che utilizzano il prefisso vuoto -->
                <xsl:if test="some $entity in $simple-entities satisfies utls:contains-prefixes($entity,'')">
                    
                    <!-- eventual user defined empty prefix --> 
                    <xsl:variable name="user-defined-empty-prefix" as="node()?" select="$rtf/rtf:&prefix;
                        [utls:contains-id(@ontology-id,$current-ontology-id)][@prefix eq '']"/>
                    
                    <!-- if there's an user defined empty prefix deflare it, else declare a default empty prefix 
                        (config.xsl) -->
                    <xsl:call-template name="translate-element">
                        <xsl:with-param name="element" select="if (exists($user-defined-empty-prefix)) then 
                            $user-defined-empty-prefix else $default-empty-prefix"/>
                    </xsl:call-template>
                    
                </xsl:if>
                
                <!-- nodes to verify the use of not empty prefixes -->
                <xsl:variable name="nodes-for-not-empty-prefix" as="xs:string*" select="
                    $rtf/rtf:*[not(local-name(.) = ('&ontology;','&prefix;'))][utls:contains-id(@ontology-id, $current-ontology-id)]/@name, 
                    $rtf/rtf:&additional-axiom;[@target-id = $rtf/rtf:*[utls:contains-id(@id, $current-ontology-id)]]/@name"/>

                <!-- user defined not empty prefixes and default owl prefixes (really used) -->
                <xsl:for-each-group select="($owl2-default-prefixes, $rtf/rtf:&prefix;)
                    [some $entity in $nodes-for-not-empty-prefix satisfies utls:contains-prefixes($entity, @prefix)]" 
                    group-by="@prefix">
                    
                    <xsl:sort select="@prefix"/>
                    <xsl:call-template name="translate-element">
                        <xsl:with-param name="element" select="current()"/>
                    </xsl:call-template>

                </xsl:for-each-group>
                
                
                <!-- ontology declaration, imports and annotations -->
                <xsl:call-template name="translate-element">
                    <xsl:with-param name="rtf" select="$rtf"/>
                    <xsl:with-param name="element" select="$current-ontology"/>
                </xsl:call-template>
                
                
                <!-- it's possible to use hierarchic or basic sorting method -->
                <xsl:variable name="hierarchic-tree" as="node()">
                    <xsl:element name="hierarchic-tree" namespace="{$rtf-namespace}">
                        
                        <xsl:if test="$use-hierarchical-visit">
                            
                            <!-- declare entities derived from owl:Thing class -->
                            <xsl:call-template name="hierarchic-visit">
                                <xsl:with-param name="rtf" select="$rtf"/>
                                <xsl:with-param name="current-ontology" select="$current-ontology-id"/>
                                <xsl:with-param name="classes-to-visit" select="$owl-thing"/>
                                <xsl:with-param name="classes-already-visited" select="()"/>
                            </xsl:call-template>
                            
                            <!-- split classes in different hierarchies -->
                            <xsl:variable name="class-hierarchies" as="node()"
                                select="utls:split-root-classes-in-different-hierarchies($rtf, $current-ontology-id)"/>
                            
                            <!-- declare entities derived from hierarchies's roots --> 
                            <xsl:for-each select="$class-hierarchies/rtf:hierarchy">
                                <xsl:sort select="@name"/>
                                <xsl:call-template name="hierarchic-visit">
                                    <xsl:with-param name="rtf" select="$rtf"/>
                                    <xsl:with-param name="current-ontology" select="$current-ontology-id"/>
                                    <xsl:with-param name="classes-to-visit" select="rtf:&class;"/>
                                    <xsl:with-param name="classes-already-visited" select="()"/>
                                </xsl:call-template>
                            </xsl:for-each>
                            
                        </xsl:if>
                    </xsl:element>
                </xsl:variable>
                
                
                <!-- translate eventual nodes in hierarchic-tree -->
                <xsl:for-each select="$hierarchic-tree/rtf:*">
                    <xsl:call-template name="translate-element">
                        <xsl:with-param name="rtf" select="$rtf"/>
                        <xsl:with-param name="element" select="current()"/>
                    </xsl:call-template>                        
                </xsl:for-each>
                        

                <!-- classes -->
                <xsl:for-each select="if (not($use-hierarchical-visit)) then $owl-thing else (), 
                    $rtf/rtf:&class;[utls:contains-id(@ontology-id,$current-ontology-id)]
                    [not(utls:contains-id(@id, $hierarchic-tree/rtf:*/@id))]">
                    
                    <xsl:sort select="@name"/>
                    <xsl:if test="current()/@name ne '&owl-thing;' or exists(current()/@auto-generated)">
                        <xsl:call-template name="translate-element">
                            <xsl:with-param name="rtf" select="$rtf"/>
                            <xsl:with-param name="element" select="current()"/>
                        </xsl:call-template>
                    </xsl:if>
                    
                </xsl:for-each>
                <!-- class restrictions, if subject of axioms -->
<!--                <xsl:for-each select="$rtf/rtf:class-restriction[utls:contains-id(@ontology-id,$current-ontology-id)]
                    [utls:contains-id(@id, $rtf/rtf:axiom/@source-id)]">
                    
                    <xsl:sort select="@name"/>
                    <xsl:call-template name=""></xsl:call-template>
                </xsl:for-each>-->
                
                
                <!-- dataranges -->
                <!-- no default dataranges (dataranges that use rdf, rdfs, xsd and owl prefixes) -->
                <xsl:for-each select="$rtf/rtf:&datarange;[utls:contains-id(@ontology-id,$current-ontology-id)]
                    [not(utls:contains-prefixes(@name, $owl2-default-prefixes/@prefix))]">
                    
                    <xsl:sort select="@name"/>
                    <xsl:call-template name="translate-element">
                        <xsl:with-param name="rtf" select="$rtf"/>
                        <xsl:with-param name="element" select="current()"/>
                    </xsl:call-template>
                    
                </xsl:for-each>
                
                
                <!-- object/data/annotation properties -->
                <xsl:for-each select="'&object-property;', '&data-property;', '&annotation-property;'">
                    <xsl:variable name="property-type" as="xs:string" select="current()"/>
                    
                    <!-- xml nodes names in rtf, corresponding to current property type --> 
                    <xsl:variable name="property-node-names" as="xs:string+" select="
                        $property-type, if ($property-type eq '&object-property;')
                        then '&object-property-facility;' else if ($property-type eq '&data-property;')
                        then '&data-property-facility;' else '&annotation-property-facility;'"/>
                    
                    <xsl:for-each select="$rtf/rtf:*[local-name(.) = $property-node-names]
                        [utls:contains-id(@ontology-id,$current-ontology-id)][not(utls:contains-id(@id, $hierarchic-tree/rtf:*/@id))]">
                        <xsl:sort select="@name"/>
                        
                        <xsl:call-template name="translate-element">
                            <xsl:with-param name="rtf" select="$rtf"/>
                            <xsl:with-param name="element" select="current()"/>
                        </xsl:call-template>
                        
                    </xsl:for-each>
                </xsl:for-each>
                

                <!-- individuals -->
                <xsl:for-each select="$rtf/rtf:&individual;[utls:contains-id(@ontology-id, $current-ontology-id)]
                    [not(utls:contains-id(@id, $hierarchic-tree/rtf:*/@id))]">
                    <xsl:sort select="@name"/>
                    
                    <xsl:call-template name="translate-element">
                        <xsl:with-param name="rtf" select="$rtf"/>
                        <xsl:with-param name="element" select="current()"/>
                    </xsl:call-template>
                    
                </xsl:for-each>
                        
                
                <!-- ontology's rules -->
                <xsl:for-each select="$rtf/rtf:&rule;[utls:contains-id(@ontology-id, $current-ontology-id)]">
                    <xsl:call-template name="translate-element">
                        <xsl:with-param name="element" select="current()"/>
                    </xsl:call-template>
                </xsl:for-each>
                
                
                <xsl:text>&newline;</xsl:text>
            </xsl:element>
        </xsl:for-each>
        
    </xsl:template>
    
    
    <!-- declare entities in rtf param hierarchically sorted -->
    <xsl:template name="hierarchic-visit">
        <xsl:param name="rtf" as="node()"/>
        <xsl:param name="current-ontology" as="xs:string"/>
        <xsl:param name="classes-to-visit" as="node()*"/>
        <xsl:param name="classes-already-visited" as="node()*"/>

        <!-- continue only if there're new classes not already visited -->
        <xsl:if test="exists($classes-to-visit)">

            <!-- divide current class and remander classes -->
            <xsl:variable name="class" as="node()" select="$classes-to-visit[1]"/>
            <xsl:variable name="remainder-classes" as="node()*" select="remove($classes-to-visit, 1)"/>
            
            <!-- immediate subclasses of current class -->
            <xsl:variable name="next-sub-classes" as="node()*">

                <xsl:variable name="all-sub-classes" as="node()*" select="$rtf/rtf:&class;[utls:contains-id(@ontology-id,$current-ontology)]
                    [utls:contains-id(@id, $rtf/rtf:&axiom;[@name eq '&subclassof-axiom;'][utls:contains-id($class/@id, @target-id)]/@source-id)]"/>

                <!-- return only subclasses not already visited or that are expectant -->
                <xsl:sequence select="for $sub-class in $all-sub-classes return if (some $taboo in 
                    ($classes-already-visited, $classes-to-visit) satisfies $taboo is $sub-class) then () else $sub-class"/>
            </xsl:variable>

            
            <!-- print current class (not owl:Thing classes defined by the user) -->
            <xsl:if test="$class/@name ne '&owl-thing;' or exists($class/@auto-generated)">
                <xsl:copy-of select="$class"/>
            </xsl:if>
            
            <!-- print object/data/annotation properties that have current class as domain -->
            <!-- property facilities are not analyzed because they have no domain -->
            <xsl:for-each select="'&object-property;','&data-property;','&annotation-property;'">
                <xsl:for-each select="$rtf/rtf:*[local-name(.) = current()]
                    [utls:contains-id(@ontology-id,$current-ontology)][utls:contains-id($class/@id, @source-id)]">
                    
                    <xsl:sort select="@name"/>
                    <xsl:copy-of select="current()"/>
                    
                </xsl:for-each>
            </xsl:for-each>
            
            <!-- print individuals that hold to current class -->
            <xsl:variable name="types-axioms" as="node()*" select="$rtf/rtf:&axiom;[@name eq '&types-axiom;']
                [utls:contains-id($class/@id, @target-id)][utls:contains-id(@ontology-id, $current-ontology)]"/>
            <xsl:for-each select="$rtf/rtf:&individual;[utls:contains-id(@ontology-id, $current-ontology)]
                [some $axiom in $types-axioms satisfies utls:contains-id(@id, $axiom/@source-id)]">
                
                <xsl:sort select="@name"/>
                <xsl:copy-of select="current()"/>
                
            </xsl:for-each>
            
            
            <!-- recursive visit -->
            <xsl:call-template name="hierarchic-visit">
                <xsl:with-param name="rtf" select="$rtf"/>
                <xsl:with-param name="current-ontology" select="$current-ontology"/>
                
                <xsl:with-param name="classes-to-visit" select="
                    (: depth-first visit: first subclasses of current class, then remainder classes :)
                        if ($use-depth-first-visit) then ($next-sub-classes, $remainder-classes) 
                    (: breadth-first visit: first remainder classes, then subclasses of current class :)
                        else $remainder-classes, $next-sub-classes"/>
                
                <xsl:with-param name="classes-already-visited" select="
                    $classes-already-visited, $class (: add current class to already visited classes :) "/>
            </xsl:call-template>
        
        </xsl:if>
            
    </xsl:template>
    
    
    
    <!-- translate $element to Manchester syntax according to its type -->
    <xsl:template name="translate-element">
        <xsl:param name="rtf" as="node()?"/>
        <xsl:param name="element" as="node()"/>
        
        <xsl:variable name="element-type" as="xs:string" select="local-name($element)"/>
        <xsl:choose>
            
            
            <!-- prefix -->
            <xsl:when test="$element-type eq '&prefix;'">
                <xsl:value-of select="concat('Prefix: ', $element/@prefix, ': ', utls:bracket-iri($element/@uri), $newline)" />
            </xsl:when>
            
            
            <!-- ontology -->
            <xsl:when test="$element-type eq '&ontology;'">
                
                <xsl:value-of select="concat('Ontology: ', $element/@name, $newline)"/>
                
                <!-- axioms referred to ontology (necessarily 'Import') -->
                <xsl:for-each select="$rtf/rtf:&axiom;[utls:contains-id($element/@id, @source-id)]">
                    <xsl:value-of select="concat(@name, ': ', utls:get-imported-ontology-iri(
                        $rtf/rtf:*[utls:contains-id(@id, current()/@target-id)]/@name), $newline)"/>
                </xsl:for-each>
                
            </xsl:when>
            
            
            <!-- class -->
            <xsl:when test="$element-type eq '&class;'">
                
                <xsl:value-of select="concat('Class: ', $element/@name, $newline)"/>
                
                <!-- axioms -->
                <xsl:for-each-group select="$rtf/rtf:&axiom;[utls:contains-id($element/@id, @source-id)]" group-by="@name">
                    <xsl:value-of select="concat($tab, @name, ': ',
                        string-join($rtf/rtf:*[utls:contains-id(@id, current-group()/@target-id)]/@name, ', '), $newline)"/>
                </xsl:for-each-group>
                
            </xsl:when>
            
            
            <!-- datarange -->
            <xsl:when test="$element-type eq '&datarange;'">
                
                <xsl:value-of select="concat('Datatype: ', $element/@name, $newline)"/>
                
                <!-- axioms -->
                <xsl:for-each-group select="$rtf/rtf:&axiom;[utls:contains-id($element/@id, @source-id)]" group-by="@name">
                    <xsl:value-of select="concat($tab, @name, ': ',
                        string-join($rtf/rtf:*[utls:contains-id(@id, current-group()/@target-id)]/@name, ', '), $newline)"/>
                </xsl:for-each-group>
                
            </xsl:when>
            
            
            <!-- property -->
            <xsl:when test="contains('&edges;', $element-type)">
                
                <xsl:variable name="property-type" as="xs:string" select="local-name($element)"/>
                
                <!-- keyword manchester che dichiara la property del tipo corrente -->
                <xsl:variable name="manchester-term" as="xs:string" select="if ($property-type = 
                    ('&object-property;', '&object-property-facility;')) then 'ObjectProperty' 
                    else if ($property-type = ('&data-property;', '&data-property-facility;')) 
                    then 'DataProperty' else 'AnnotationProperty'"/>
                
                <xsl:value-of select="concat($manchester-term, ': ', $element/@name, $newline)"/>
                
                <!-- axioms -->
                <xsl:for-each-group select="$rtf/rtf:&axiom;[utls:contains-id($element/@id, @source-id)]" group-by="@name">
                    <xsl:value-of select="concat($tab, @name, ': ',
                        string-join($rtf/rtf:*[utls:contains-id(@id, current-group()/@target-id)]/@name, ', '), $newline)"/>
                </xsl:for-each-group>
                    
                <!-- properties and facilities obtained by punning are not equipped with domain and range -->
                <xsl:if test="$element/@source-id">
                    <xsl:value-of select="concat($tab, 'Domain: ', string-join($rtf/rtf:*[utls:contains-id(@id, current()/@source-id)]/@name, ', '), $newline)"/>
                </xsl:if>
                <xsl:if test="$element/@target-id">
                    <xsl:value-of select="concat($tab, 'Range: ', string-join($rtf/rtf:*[utls:contains-id(@id, current()/@target-id)]/@name, ', '), $newline)"/>
                </xsl:if>
                
            </xsl:when>
            
            
            <!-- individual -->
            <xsl:when test="$element-type eq '&individual;'">
                
                <xsl:value-of select="concat('Individual: ', $element/@name, $newline)"/>
                
                <!-- owl axioms -->
                <xsl:for-each-group select="$rtf/rtf:&axiom;[utls:contains-id($element/@id, @source-id)][exists(@owl-axiom)]" group-by="@name">
                    <xsl:value-of select="concat($tab, @name, ': ', 
                        string-join($rtf/rtf:*[utls:contains-id(@id, current-group()/@target-id)]/@name, ', '), $newline)"/>
                </xsl:for-each-group>
                
                <!-- not owl axioms ('Facts') -->
                <xsl:for-each-group select="$rtf/rtf:&axiom;[utls:contains-id($element/@id, @source-id)][empty(@owl-axiom)]" group-by="@name">
                    <xsl:value-of select="concat($tab, 'Facts: ', @name, ': ', 
                        string-join($rtf/rtf:*[utls:contains-id(@id, current-group()/@target-id)]/@name, ', '), $newline)"/>
                </xsl:for-each-group>
                
            </xsl:when>
            
            
            <!-- rule -->
            <xsl:when test="$element-type eq '&rule;'">
                <xsl:value-of select="concat('Rule: ', $newline, $tab, @name, $newline)"/>
            </xsl:when>
            
            
        </xsl:choose>
        
        <!-- additional axiom -->
        <xsl:for-each-group select="$rtf/rtf:&additional-axiom;[utls:contains-id($element/@id, @target-id)]" group-by="@name">
            <xsl:value-of select="concat(if ($element-type ne 'ontology') then $tab else (), @name, $newline)"/>
        </xsl:for-each-group>
        
    </xsl:template>
    
 
</xsl:stylesheet>
