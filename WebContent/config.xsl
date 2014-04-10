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
    xmlns:g="http://graphml.graphdrawing.org/xmlns"
    xpath-default-namespace="http://www.essepuntato.it/graffoo/configuration/">
    
    
    <!-- load the configuration tree from config.xml -->
    <xsl:variable name="config" as="node()" select="if (doc-available('config.xml')) 
        then document('config.xml') else error(QName('http://www.essepuntato.it/graffoo/errors/', 
        'no-configuration-file'), 'config.xml file not found')"/>
    

    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    PARAMS FROM ENVIRONMENT 
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->


    <!-- it specifices if the translation has to generate all diagram's ontologies 
        or only the main ontology -->
    <xsl:param name="generate-all-ontologies-param" as="xs:boolean" 
        select="$config//graffoo/default-values/generate-all-ontologies"/>
    
    <!-- it specifies which sorting method is to be used to output entities in the final ontology:
        * basic sorting: 
            1) prefixes
            2) ontology (declaration, import, annotations) 
            3) classes
            4) datatypes
            5) properties (object, data and annotation properties)
            6) individuals
            7) rules
        * hierarchical sorting: 
            1) prefixes
            2) ontology (declaration, import, annotations) 
            3) classes sorted hierarchically and on each level 
                * the properties with that class as domain 
                * the individuals of that class
            4) datatypes
            5) properties  (object, data and annotation properties) not declarated yet, 
            6) individuals not declarated yet
            7) rules
        For both sorting method, entities of same type are sorted alphabetically -->
    <xsl:param name="use-hierarchical-visit-param" as="xs:boolean"
        select="$config//graffoo/default-values/use-hierarchical-visit"/>
    
    <!-- the hierachical visit has to be execute in depth-first mode -->
    <xsl:param name="use-depth-first-visit-param" as="xs:boolean"
        select="$config//graffoo/default-values/use-depth-first-visit"/>
        
    <!-- are simple nodes's appearance info to be maintain in final ontologies? -->
    <xsl:param name="maintain-appearance-param" as="xs:boolean"
        select="$config//graffoo/default-values/maintain-appearance"/>
    
    <!-- it specifies which ontology's IRI (general or version IRI) is to be used --> 
    <xsl:param name="use-imported-ontology-version-iri-param" as="xs:boolean"
        select="$config//graffoo/default-values/use-imported-ontology-version-iri"/>
    
    <!-- default ontology IRI for main ontology, 
        used only if not already defined in graffoo diagram -->
    <xsl:param name="default-ontology-iri-param" as="xs:string" 
        select="$config//graffoo/default-values/default-ontology-iri"/>
    
    <!-- default prefix IRI (empty prefix) -->
    <xsl:param name="default-empty-prefix-param" as="xs:string" 
        select="$config//graffoo/default-values/default-empty-prefix/@uri"/>



    <!-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    VARIABLES USED DURING TRANSLATION 
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< -->
    
    
    <!-- from previous param -->
    
    <xsl:variable name="generate-all-ontologies" as="xs:boolean" 
        select="$generate-all-ontologies-param"/>
    
    <xsl:variable name="use-hierarchical-visit" as="xs:boolean"
        select="$use-hierarchical-visit-param"/>
    
    <xsl:variable name="use-depth-first-visit" as="xs:boolean"
        select="$use-depth-first-visit-param"/>
    
    <xsl:variable name="maintain-appearance" as="xs:boolean"
        select="$maintain-appearance-param"/>
    
    <xsl:variable name="use-imported-ontology-version-iri" as="xs:boolean"
        select="$use-imported-ontology-version-iri-param"/>
    
    <xsl:variable name="default-ontology-iri" as="xs:string" 
        select="$default-ontology-iri-param"/>
    
    <xsl:variable name="default-empty-prefix" as="node()">
        <xsl:element name="prefix">
            <xsl:attribute name="prefix" select="''"/>
            <xsl:attribute name="uri" select="$default-empty-prefix-param"/>
        </xsl:element>
    </xsl:variable> 
    
    
    <!-- from configuration file -->
    
    <xsl:variable name="debug" as="xs:boolean" select="$config//graffoo/debug"/>
    
    <xsl:variable name="graffoo-prefix" as="node()" select="$config//graffoo/graffoo-prefix"/>
    
    <xsl:variable name="scan-limit" as="xs:integer" select="$config//graffoo/scan-limit"/>
    
    <xsl:variable name="restriction-label-prefix-left-delimiter" as="xs:string"
        select="$config//graffoo/import-graphml/restriction-label/@prefix-left-delimiter"/>
    <xsl:variable name="restriction-label-prefix-right-delimiter" as="xs:string"
        select="$config//graffoo/import-graphml/restriction-label/@prefix-right-delimiter"/>
    <xsl:variable name="restriction-label-blank-substitute" as="xs:string"
        select="$config//graffoo/import-graphml/restriction-label/@blank-substitute"/>
    <xsl:variable name="restriction-label-numeric-suffix" as="xs:string"
        select="$config//graffoo/import-graphml/restriction-label/@numeric-suffix"/>

    <xsl:variable name="edgelabel-id-first-prefix" as="xs:string"
        select="$config//graffoo/import-graphml/edgelabel-id/@first-prefix"/>
    <xsl:variable name="edgelabel-id-second-prefix" as="xs:string"
        select="$config//graffoo/import-graphml/edgelabel-id/@second-prefix"/>

    <xsl:variable name="segment-intersection-incremental" as="xs:boolean"
        select="$config//graffoo/import-graphml/segment-intersection/incremental"/>
    <xsl:variable name="segment-intersection-tollerance" as="xs:double"
        select="$config//graffoo/import-graphml/segment-intersection/tollerance"/>

    <xsl:variable name="sqrt-precision" as="xs:double" 
        select="$config//graffoo/import-graphml/sqrt-precision"/>

    <xsl:variable name="error-namespace" as="xs:string" 
        select="$config//graffoo/error-namespace"/>
    <xsl:variable name="rtf-namespace" as="xs:string"
        select="$config//graffoo//rtf-namespace"/>
    
    <xsl:variable name="owl2-default-prefixes" as="node()+"
        select="$config//owl2/default-prefixes/prefix"/>
    <xsl:variable name="owl2-axioms" as="node()"
        select="$config//owl2/common-axioms"/>
    <xsl:variable name="owl2-default-datatypes" as="xs:string+"
        select="$config//owl2/default-datatypes/datatype/@name"/>
    
    
    <!-- others -->
    
    <!-- default ontology's id used during importing of graphml diagram  -->
    <xsl:variable name="default-ontology-id" as="xs:string"
        select="/g:graphml/g:graph/@id (: use the id of graph node in graphml file :)"/>


</xsl:stylesheet>
