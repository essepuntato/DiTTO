<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright (c) 2012-2014, Silvio Peroni <essepuntato@gmail.com>

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
<!DOCTYPE xsl:stylesheet [
<!ENTITY owl "http://www.w3.org/2002/07/owl#" >
<!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#" >
<!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
<!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
]>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:y="http://www.yworks.com/xml/graphml"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:f="http://www.essepuntato.it/xslt/function/"
    xmlns:g="http://graphml.graphdrawing.org/xmlns"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    exclude-result-prefixes="xs g f y"
    version="2.0">
    
    <xsl:import href="er-intermediate.xsl"/>
    
    <xsl:output encoding="UTF-8" indent="no" method="xml" />

    <xsl:template name="relationship">
        <xsl:param name="els" as="element()*"/> <!-- g:edge -->
        
        <xsl:for-each select="$els">
            <!-- I conseder labels that are in their last occurrence -->
            <xsl:variable name="labels" select=".//y:EdgeLabel[normalize-space() != ''][every $following-label in following::y:EdgeLabel satisfies f:getLabelOutOfIt(.) != f:getLabelOutOfIt($following-label)]" />
            <xsl:for-each select="$labels">
                <xsl:variable name="label" select="." />
                <xsl:variable name="iri" select="f:getIRI($label)" />
                <xsl:variable name="label-text" select="f:getLabelOutOfIt(.)" />
                
                <xsl:variable name="edges-having-label" select="//g:edge[some $l in .//y:EdgeLabel satisfies f:getLabelOutOfIt($l) = $label-text]" as="element()*" />
                
                <xsl:variable name="isSymmetric" select="exists(//g:edge[count(.//y:EdgeLabel) = 2 and (every $l in .//y:EdgeLabel satisfies f:getLabelOutOfIt($l) = $label-text)])" as="xs:boolean" />
                
                <xsl:variable name="domain-uris" as="xs:anyURI*">
                    <xsl:variable name="iri-involved" as="xs:anyURI*">
                        <xsl:for-each select="$edges-having-label">
                            <xsl:variable name="edge" select="." />
                            <xsl:for-each select="//g:node[f:isEntity(.) and f:isInvolvedInEdge(.,$edge)]">
                                <xsl:if test="(f:getOtherNodeInEdge($edge,.) is .) or normalize-space(f:getPropertyLabelHavingNodeAsDomain(.,$edge)) = $label-text">
                                    <xsl:sequence select="f:getIRI(.)" />
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:sequence select="distinct-values($iri-involved)" />
                </xsl:variable>
                <xsl:variable name="range-uris" as="xs:anyURI*">
                    <xsl:variable name="iri-involved" as="xs:anyURI*">
                        <xsl:for-each select="$edges-having-label">
                            <xsl:variable name="edge" select="." />
                            <xsl:for-each select="//g:node[f:isEntity(.) and f:isInvolvedInEdge(.,$edge)]">
                                <xsl:if test="(f:getOtherNodeInEdge($edge,.) is .) or normalize-space(f:getPropertyLabelHavingNodeAsRange(.,$edge)) = $label-text">
                                    <xsl:sequence select="f:getIRI(.)" />
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:sequence select="distinct-values($iri-involved)" />
                </xsl:variable>
                
                <xsl:call-template name="object-property">
                    <xsl:with-param name="iri" select="$iri" />
                    <xsl:with-param name="label" select="$label-text" />
                    <xsl:with-param name="symmetric" select="$isSymmetric" />
                    <xsl:with-param name="domain" select="$domain-uris" />
                    <xsl:with-param name="range" select="$range-uris" />
                </xsl:call-template>
                
                <!-- List of inverses -->
                <xsl:for-each select="//g:edge[some $l in .//y:EdgeLabel[normalize-space() != ''] satisfies f:getLabelOutOfIt($l) = $label-text]//y:EdgeLabel[normalize-space() != ''][f:getLabelOutOfIt(.) != $label-text]">
                    <xsl:variable name="other-iri" select="f:getIRI(.)" />
                    <xsl:call-template name="inverse-of">
                        <xsl:with-param name="iri-property-1" select="$iri" />
                        <xsl:with-param name="iri-property-2" select="$other-iri" />
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="attribute">
        <xsl:param name="els" as="element()*"/> <!-- g:node -->
        
        <xsl:for-each select="$els">
            <!-- I conseder labels that are in their last occurrence -->
            <xsl:variable name="labels" select=".//y:NodeLabel[f:isAttribute(ancestor::g:node[1]) and (every $following-label in following::y:NodeLabel[f:isAttribute(ancestor::g:node[1])] satisfies f:getLabelOutOfIt(.) != f:getLabelOutOfIt($following-label))]" />
            <xsl:for-each select="$labels">
                <xsl:variable name="label" select="." />
                <xsl:variable name="iri" select="f:getIRI($label)" />
                <xsl:variable name="label-text" select="f:getLabelOutOfIt(.)" />
                
                <xsl:variable name="nodes-having-label" select="//g:node[f:isAttribute(.) and f:getLabelOutOfIt(.//y:NodeLabel) = $label-text]" as="element()*" />
                
                <xsl:variable name="domain-uris" as="xs:anyURI*">
                    <xsl:variable name="iri-involved" as="xs:anyURI*">
                        <xsl:for-each select="$nodes-having-label">
                            <xsl:variable name="node" select="." />
                            <xsl:sequence select="for $domain-id in //g:edge[some $attr in (@source|@target) satisfies $node/@id = $attr]/(@source|@target)[. != $node/@id] return f:getIRI(//g:node[@id = $domain-id])" />
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:sequence select="distinct-values($iri-involved)" />
                </xsl:variable>
                
                <xsl:call-template name="data-property">
                    <xsl:with-param name="iri" select="$iri" />
                    <xsl:with-param name="label" select="$label-text" />
                    <xsl:with-param name="domain" select="$domain-uris" />
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>