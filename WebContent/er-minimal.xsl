<?xml version="1.0" encoding="UTF-8"?>
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
                
                <xsl:call-template name="cardinality">
                    <xsl:with-param name="node" select="$node" />
                    <xsl:with-param name="other-node" select="$other-node" />
                    <xsl:with-param name="value" select="'crows_foot_many_optional'" />
                    <xsl:with-param name="label" select="$current-label" />
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
                    
                    <xsl:call-template name="cardinality">
                        <xsl:with-param name="node" select="$node" />
                        <xsl:with-param name="other-node" select="$other-node" />
                        <xsl:with-param name="value" select="'crows_foot_many_optional'" />
                        <xsl:with-param name="label" select="$inverse-label" />
                    </xsl:call-template>
                </xsl:if>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="f:getIRI" as="xs:anyURI+">
        <xsl:param name="el" as="element()+" /> <!-- They can be a y:NodeLabel of an entity, y:EdgeLabel of a relationship or a y:NodeLabel of an attribute  -->
        <xsl:variable name="result" as="xs:anyURI+">
            <xsl:for-each select="$el">
                <xsl:choose>
                    <xsl:when test="f:isEntity(.)">
                        <xsl:sequence select="f:classLocalURI(./ancestor-or-self::g:node[1]//y:NodeLabel//text())" />
                    </xsl:when>
                    <xsl:when test="f:isRelationship(./ancestor-or-self::g:edge[1])">
                        <xsl:variable name="current-label" select="f:getLabelOutOfIt(.)" />
                        <xsl:variable name="prec" select="preceding::y:EdgeLabel[f:getLabelOutOfIt(.) = $current-label]" as="element()*" />
                        <xsl:variable name="incr" select="if (exists($prec | following::y:EdgeLabel[f:getLabelOutOfIt(.) = $current-label])) then concat('',count($prec)+1) else ''" />
                        <xsl:sequence select="xs:anyURI(concat(f:propertyLocalURI(.//text()),$incr))" />
                    </xsl:when>
                    <xsl:otherwise> <!-- it's an attribute -->
                        <xsl:variable name="current-label" select="f:getLabelOutOfIt(./ancestor-or-self::g:node[1]//y:NodeLabel)" />
                        <xsl:variable name="prec" select="./ancestor-or-self::g:node[1]//y:NodeLabel/preceding::y:NodeLabel[f:isAttribute(ancestor::g:node) and f:getLabelOutOfIt(.) = $current-label]" as="element()*" />
                        <xsl:variable name="incr" select="if (exists($prec | ./ancestor-or-self::g:node[1]//y:NodeLabel/following::y:NodeLabel[f:isAttribute(ancestor::g:node) and f:getLabelOutOfIt(.) = $current-label])) then concat('',count($prec)+1) else ''" />
                        <xsl:sequence select="xs:anyURI(concat(f:propertyLocalURI(./ancestor-or-self::g:node[1]//y:NodeLabel//text()),$incr))" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="$result" />
    </xsl:function>
    
</xsl:stylesheet>