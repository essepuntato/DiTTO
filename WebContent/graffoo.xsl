<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright (c) 2014, Riccardo Falco <rky.falco@gmail.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
-->
<!DOCTYPE xsl:stylesheet SYSTEM "entities.dtd">
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:utls="http://www.essepuntato.it/graffoo/utils"
    xmlns:rtf="http://www.essepuntato.it/graffoo/resultTreeFragment/">
    
    <xsl:import href="config.xsl"/>
    <xsl:import href="utils.xsl"/>
    <xsl:import href="translation.xsl"/>
    
    
    <!-- to store intermediate translations on files (to debug) -->
    <xsl:output name="xml" method="xml" indent="yes"/>
    <xsl:output name="manchester" method="text"/>
    
    <!-- to manage direct output of one (intermediate) translation result -->
<!--    <xsl:output method="xml" indent="yes"/>-->
    <xsl:output method="text" />
    
    
    <!-- entry point -->
    <xsl:template match="/">
        
        <!-- the entire translation is composed of five partial translations, 
            each of which generates an intermediate result, an RTF (Result Tree Fragment) -->
        
        
        <!-- 1st partial translation -->
        <xsl:variable name="import-graphml-result" as="node()">
            <xsl:element name="import-graphml-result" namespace="{$rtf-namespace}">
                
                <!-- merge RTFs generated during the import of GraphML diagram (translation.xsl) -->
                <xsl:copy-of select="($ontologies-from-graphml | $prefixes-from-graphml |
                    $entity-nodes-from-graphml | $properties-from-graphml | $axioms-from-graphml | 
                    $additional-axioms-from-graphml | $rules-from-graphml)/rtf:*"/>
            </xsl:element>
        </xsl:variable>
        
        
        <!-- 2nd partial translation -->
        <xsl:variable name="punning-result" as="node()">
            <xsl:element name="punning-result" namespace="{$rtf-namespace}">
                
                <!-- punning of entities involved in axioms -->
                <!-- return new entities, duplicated additional axiom and all the axioms (eventually updated) --> 
                <xsl:call-template name="punning">
                    <xsl:with-param name="rtf" select="$import-graphml-result"/>
                </xsl:call-template>     

                <!-- copy of all not-axiom elements -->
                <xsl:copy-of select="$import-graphml-result/rtf:*[not(local-name(.) eq '&axiom;')]"/> 
            </xsl:element>
        </xsl:variable>
        
        
        <!-- 3rd partial translation -->
        <xsl:variable name="ontology-imports-result" as="node()">
            <xsl:element name="ontology-imports-result" namespace="{$rtf-namespace}">
                
                <!-- import the entities defined in imported ontologies -->
                <!-- return all entities, eventually with updated ontology-id attribute -->
                <xsl:call-template name="import-entities">
                    <xsl:with-param name="rtf" select="$punning-result"/>
                </xsl:call-template>
                
                <!-- copy all not-entity elements -->
                <xsl:copy-of select="$punning-result/rtf:*[not(contains('&entities;',local-name(.)))]"/>
            </xsl:element>
        </xsl:variable>
        
        
        <!-- 4th partial translation -->
        <xsl:variable name="analyze-manchester-strings-and-swrl-rules-result" as="node()">
            <xsl:element name="analyze-manchester-strings-and-swrl-rules-result" namespace="{$rtf-namespace}">
                
                <!-- detect from Manchester and SWRL strings the entities not already declared by the user.
                    Moreover include 'owl:Thing' or 'rdfs:Literal' if necessary in 
                    "property min|max|exactly integer" property restriction -->
                <!-- new elements are merged with all others -->
                <xsl:call-template name="analyze-manchester-strings-and-swrl-rules">
                    <xsl:with-param name="rtf" select="$ontology-imports-result"/>
                </xsl:call-template>
                
            </xsl:element>
        </xsl:variable>
        
        
        <!-- 5th partial translation -->
        <xsl:variable name="manchester-result" as="node()">
            <xsl:element name="manchester-result" namespace="{$rtf-namespace}">
                
                <!-- translate to Manchester OWL syntax and sort Manchester statements
                    (default or hierarchical order) -->
                <xsl:call-template name="translate-to-manchester">
                    <xsl:with-param name="rtf" select="$analyze-manchester-strings-and-swrl-rules-result"/>
                </xsl:call-template>
                
            </xsl:element>
        </xsl:variable>
        
        
        <!-- storing of intermediate results to debug -->
        <xsl:if test="$debug">
            
            <xsl:result-document format="xml" 
                href="../output/1-{local-name($import-graphml-result)}.xml">
                <xsl:copy-of select="$import-graphml-result"/>
            </xsl:result-document>
            <xsl:result-document format="xml" 
                href="../output/2-{local-name($punning-result)}.xml">
                <xsl:copy-of select="$punning-result"/>
            </xsl:result-document>
            <xsl:result-document format="xml" 
                href="../output/3-{local-name($ontology-imports-result)}.xml">
                <xsl:copy-of select="$ontology-imports-result"/>
            </xsl:result-document>
            <xsl:result-document format="xml" 
                href="../output/4-{local-name($analyze-manchester-strings-and-swrl-rules-result)}.xml">
                <xsl:copy-of select="$analyze-manchester-strings-and-swrl-rules-result"/>
            </xsl:result-document>
            <xsl:result-document format="xml" 
                href="../output/5-{local-name($manchester-result)}.xml">
                <xsl:copy-of select="$manchester-result"/>
            </xsl:result-document>
            <xsl:result-document format="manchester" 
                href="../output/5-{local-name($manchester-result)}.txt">
                <xsl:copy-of select="$manchester-result"/>
            </xsl:result-document>
            
        </xsl:if>
        
        
        <!-- direct output of one intermediate result (update xsl:output method) -->
<!--        <xsl:copy-of select="$import-graphml-result"/>-->
<!--        <xsl:copy-of select="$punning-result"/>-->
<!--        <xsl:copy-of select="$ontology-imports-results"/>-->
<!--        <xsl:copy-of select="$analyze-manchester-strings-result"/>-->
        <xsl:choose>
            
            <!-- print all ontologies in the Graffoo diagram -->
            <xsl:when test="$generate-all-ontologies">
                <xsl:value-of select="$manchester-result"/>        
            </xsl:when>
            
            <!-- print only the single main ontology in the Graffoo diagram -->
            <xsl:otherwise>
                <xsl:value-of select="$manchester-result/rtf:&ontology;[@main-ontology]"/>
            </xsl:otherwise>
        </xsl:choose>
        
        
        <!-- generation of OWL file for the main ontology or for each ontology in Graffoo diagram 
            (the file name is obtained by ontology's IRI) -->
<!--        <xsl:choose>
            <xsl:when test="$generate-all-ontologies">
                
                <xsl:for-each select="$manchester-result/rtf:&ontology;">
                    <xsl:result-document format="manchester" 
                        href="{concat('../output/', $current-graphml-filename,
                        '/', utls:uri-to-filename(utls:get-ontology-version-iri(@name)), '.owl')}">
                        <xsl:value-of select="current()"/>
                    </xsl:result-document>
                </xsl:for-each>
                
            </xsl:when>
            <xsl:otherwise>
                
                <!-/- we assume that there's only one main ontology -/->
                <xsl:variable name="main-ontology" as="node()" 
                    select="$manchester-result/rtf:&ontology;[@main-ontology]"/>
                <xsl:result-document format="manchester" 
                    href="{concat('../output/', $current-graphml-filename,
                    '/', utls:uri-to-filename(utls:get-ontology-version-iri($main-ontology/@name)), '.owl')}">
                    <xsl:value-of select="$main-ontology"/>
                </xsl:result-document>
                
            </xsl:otherwise>
        </xsl:choose>-->
        
    </xsl:template>
    
</xsl:stylesheet>
