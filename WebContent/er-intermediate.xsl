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
    
    <xsl:import href="er-core.xsl"/>
    
    <xsl:output encoding="UTF-8" indent="no" method="xml" />
    
    <xsl:template name="entity-object-property-restriction-no-union">
        <xsl:param name="node" as="element()" />
        <!-- Object property restrictions (no union) -->
        <xsl:for-each select="//g:edge[f:isRelationship(.) and f:isInvolvedInEdge($node,.)]">
            
            <xsl:variable name="edge" select="." as="element()" />
            <xsl:variable name="other-node" select="f:getOtherNodeInEdge(.,$node)" />
            
            <xsl:variable name="current-label" select="f:getPropertyLabelHavingNodeAsDomain($node,$edge)" as="element()?"/>
            <xsl:if test="$current-label">
                <xsl:call-template name="cardinality">
                    <xsl:with-param name="node" select="$node" />
                    <xsl:with-param name="other-node" select="$other-node" />
                    <xsl:with-param name="value" select="f:getPropertyValueAsDomain($edge,$node)" />
                    <xsl:with-param name="label" select="$current-label" />
                    <xsl:with-param name="except" select="('crows_foot_many_optional')" />
                </xsl:call-template>
            </xsl:if>
            
            <xsl:if test="$node is $other-node"> <!-- To handle entities having relationships starting and ending to them -->
                <xsl:variable name="inverse-label" select="f:getPropertyLabelHavingNodeAsRange($node,$edge)" as="element()?"/>
                <xsl:if test="$inverse-label">
                    <xsl:call-template name="cardinality">
                        <xsl:with-param name="node" select="$node" />
                        <xsl:with-param name="other-node" select="$other-node" />
                        <xsl:with-param name="value" select="f:getPropertyValueAsRange($edge,$node)" />
                        <xsl:with-param name="label" select="$inverse-label" />
                        <xsl:with-param name="except" select="('crows_foot_many_optional')" />
                    </xsl:call-template>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="entity-object-property-restriction-with-union">
        <xsl:param name="node" as="element()" />
        <xsl:variable name="edges" as="element()*" select="//g:edge[
            f:isRelationship(.) and 
            f:isInvolvedInEdge($node,.) and
            f:getPropertyLabelHavingNodeAsDomain($node,.)]" />
        
        <xsl:for-each select="distinct-values(for $edge in $edges return (normalize-space(f:getPropertyLabelHavingNodeAsRange($node,$edge)),normalize-space(f:getPropertyLabelHavingNodeAsDomain($node,$edge))))">
            <xsl:variable name="current-label" select="." />
            
            <!-- 
            <xsl:variable name="current-edges" select="$edges[normalize-space(f:getPropertyLabelHavingNodeAsDomain($node,.)) = $current-label or normalize-space(f:getPropertyLabelHavingNodeAsRange($node,.)) = $current-label]" as="element()*" />
            -->
            <xsl:variable name="current-edges" select="$edges[normalize-space(f:getPropertyLabelHavingNodeAsDomain($node,.)) = $current-label]" as="element()*" />
            
            <xsl:variable name="other-nodes" as="element()*">
                <xsl:for-each select="$current-edges">
                    <xsl:sequence select="f:getOtherNodeInEdge(.,$node)" />
                </xsl:for-each>
            </xsl:variable>
            
            <xsl:variable name="current-edges-filtered" as="element()*">
                <xsl:choose>
                    <xsl:when test="some $n in $other-nodes satisfies $n is $node">
                        <xsl:sequence select="$current-edges" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$edges[normalize-space(f:getPropertyLabelHavingNodeAsDomain($node,.)) = $current-label]" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="edge-having-label-as-domain" select="$current-edges-filtered[normalize-space(f:getPropertyLabelHavingNodeAsDomain($node,.)) = $current-label][1]" />
            
            <xsl:variable name="edge-having-label-as-range" select="if (some $n in $other-nodes satisfies $n is $node) then $current-edges-filtered[normalize-space(f:getPropertyLabelHavingNodeAsRange($node,.)) = $current-label][1] else ()" />
            
            <xsl:variable name="label-element" as="element()?">
                <xsl:choose>
                    <xsl:when test="$edge-having-label-as-domain">
                        <xsl:sequence select="f:getPropertyLabelHavingNodeAsDomain($node,$edge-having-label-as-domain)" />
                    </xsl:when>
                    <xsl:when test="$edge-having-label-as-range">
                        <xsl:sequence select="f:getPropertyLabelHavingNodeAsRange($node,$edge-having-label-as-range)" />
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:if test="$other-nodes and $label-element">
                <xsl:call-template name="cardinality">
                    <xsl:with-param name="node" select="$node" />
                    <xsl:with-param name="other-node" select="$other-nodes" />
                    <xsl:with-param name="value" select="'crows_foot_many_optional'" />
                    <xsl:with-param name="label" select="$label-element" />
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="relationship">
        <xsl:param name="els" as="element()*"/> <!-- g:edge -->
        <xsl:for-each select="$els">
            <xsl:variable name="labels" select=".//y:EdgeLabel[normalize-space() != ''][every $following-label in following::y:EdgeLabel satisfies f:getLabelOutOfIt(.) != f:getLabelOutOfIt($following-label)]" />
            <xsl:for-each select="$labels">
                <xsl:call-template name="object-property">
                    <xsl:with-param name="iri" select="f:getIRI(.)" />
                    <xsl:with-param name="label" select="f:getLabelOutOfIt(.)" />
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="attribute">
        <xsl:param name="els" as="element()*"/> <!-- g:node -->
        
        <xsl:for-each select="$els"> 
            <xsl:variable name="labels" select=".//y:NodeLabel[f:isAttribute(ancestor::g:node[1]) and (every $following-label in following::y:NodeLabel[f:isAttribute(ancestor::g:node[1])] satisfies f:getLabelOutOfIt(.) != f:getLabelOutOfIt($following-label))]" />
            <xsl:for-each select="$labels">
                <xsl:call-template name="data-property">
                    <xsl:with-param name="iri" select="f:getIRI(.)" />
                    <xsl:with-param name="label" select="f:getLabelOutOfIt(.)" />
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>