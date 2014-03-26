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
    
    <xsl:import href="entities-rdfxml.xsl"/>
    <xsl:import href="functions.xsl"/>
    
    <xsl:output encoding="UTF-8" indent="no" method="xml" />
    
    <xsl:param name="ontology-uri" select="'http://www.essepuntato.it/example'" />
    <xsl:param name="ontology-prefix" select="'ex'" />
    <xsl:param name="look-across-for-labels" select="true()" as="xs:boolean" />
    <xsl:variable name="base" select="concat($ontology-uri,'/')" />
    
    <xsl:template match="/">
        <rdf:RDF xml:base="{$base}">
            <xsl:namespace name="{$ontology-prefix}" select="$base" />
            
            <owl:Ontology rdf:about="{$ontology-uri}" />
            <xsl:call-template name="entities" />
            <xsl:call-template name="relationships" />
            <xsl:call-template name="attributes" />
        </rdf:RDF>
    </xsl:template>
    
    <xsl:template name="attribute">
        <xsl:param name="els" as="element()*"/> <!-- g:node -->
        
        <xsl:for-each select="$els"> 
            <xsl:call-template name="data-property">
                <xsl:with-param name="iri" select="f:getIRI(.)" />
                <xsl:with-param name="label" select="f:getLabelOutOfIt(.)" />
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="attributes">
        <xsl:call-template name="attribute">
            <xsl:with-param name="els" select="//g:node[f:isAttribute(.)]" as="element()*" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="cardinality">
        <xsl:param name="node" as="element()"/>
        <xsl:param name="other-node" as="element()+"/>
        <xsl:param name="value" as="xs:string"/>
        <xsl:param name="label" as="element()"/>
        <xsl:param name="inverse" select="false()" as="xs:boolean" />
        <xsl:param name="except" select="()" as="xs:string*" />
        
        <xsl:if test="not(some $ex in $except satisfies $ex = $value)">
            <xsl:choose>
                <xsl:when test="$value = 'crows_foot_one_optional'"> <!-- max 1 -->
                    <xsl:call-template name="max-subclass">
                        <xsl:with-param name="iri" select="f:getIRI($node)" />
                        <xsl:with-param name="property" select="f:getIRI($label)" />
                        <xsl:with-param name="cardinality" select="1" />
                        <xsl:with-param name="classes" select="f:getIRI($other-node)" />
                        <xsl:with-param name="inverse" select="$inverse" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$value = 'crows_foot_many_optional'"> <!-- only -->
                    <xsl:call-template name="only-subclass">
                        <xsl:with-param name="iri" select="f:getIRI($node)" />
                        <xsl:with-param name="property" select="f:getIRI($label)" />
                        <xsl:with-param name="classes" select="f:getIRI($other-node)" />
                        <xsl:with-param name="inverse" select="$inverse" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$value = 'crows_foot_one_mandatory'"> <!-- exactly 1 -->
                    <xsl:call-template name="exactly-subclass">
                        <xsl:with-param name="iri" select="f:getIRI($node)" />
                        <xsl:with-param name="property" select="f:getIRI($label)" />
                        <xsl:with-param name="cardinality" select="1" />
                        <xsl:with-param name="classes" select="f:getIRI($other-node)" />
                        <xsl:with-param name="inverse" select="$inverse" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$value = 'crows_foot_many_mandatory'"><!-- some -->
                    <xsl:call-template name="some-subclass">
                        <xsl:with-param name="iri" select="f:getIRI($node)" />
                        <xsl:with-param name="property" select="f:getIRI($label)" />
                        <xsl:with-param name="classes" select="f:getIRI($other-node)" />
                        <xsl:with-param name="inverse" select="$inverse" />
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>WARNING: not handled!</xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="entity">
        <xsl:param name="els" as="element()*"/> <!-- g:node+ -->
        
        <xsl:for-each select="$els">
            <xsl:variable name="node" select="." />
            <xsl:call-template name="class">
                <xsl:with-param name="iri" select="f:getIRI(.)" />
                <xsl:with-param name="label" select="f:getLabelOutOfIt(.)" />
            </xsl:call-template>
            
            <!-- Object property restrictions (no union) -->
            <xsl:call-template name="entity-object-property-restriction-no-union">
                <xsl:with-param name="node" select="$node" />
            </xsl:call-template>
            
            <!-- Object property restrictions (with union) -->
            <xsl:call-template name="entity-object-property-restriction-with-union">
                <xsl:with-param name="node" select="$node" />
            </xsl:call-template>
            
            <!-- Data property restrictions -->
            <xsl:for-each select="//g:node[f:isAttribute(.) and (some $edge in //g:edge satisfies (@id = $edge/@source and $node/@id = $edge/@target) or (@id = $edge/@target and $node/@id = $edge/@source))]">
                <xsl:call-template name="exactly-subclass">
                    <xsl:with-param name="iri" select="f:getIRI($node)" />
                    <xsl:with-param name="property" select="f:getIRI(.)" />
                    <xsl:with-param name="cardinality" select="1" />
                </xsl:call-template>
            </xsl:for-each>
            
            <!-- Generalizations -->
            <xsl:for-each select="//g:edge[f:isGeneralization(.) and f:isInvolvedInEdge($node,.) and f:getPropertyValueAsDomain(.,$node) = 'white_delta']">
                <xsl:variable name="edge" select="." />
                <xsl:call-template name="subclass-of">
                    <xsl:with-param name="subclass" select="f:getIRI($node)" />
                    <xsl:with-param name="class" select="f:getIRI(//g:node[@id = $edge/(@source|@target)[. != $node/@id]])" />
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="entity-object-property-restriction-no-union">
        <xsl:param name="node" as="element()" />
        <!-- Do nothing - To be defined in the importing modules if needed -->
    </xsl:template>
    
    <xsl:template name="entity-object-property-restriction-with-union">
        <xsl:param name="node" as="element()" />
        <!-- Do nothing - To be defined in the importing modules if needed -->
    </xsl:template>
    
    <xsl:template name="entities">
        <xsl:call-template name="entity">
            <xsl:with-param name="els" select="//g:node[f:isEntity(.)]" as="element()*" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="relationship">
        <xsl:param name="els" as="element()*"/> <!-- g:edge -->
        
        <xsl:for-each select="$els">
            <xsl:variable name="labels" select=".//y:EdgeLabel[normalize-space() != '']" />
            <xsl:for-each select="$labels">
                <xsl:call-template name="object-property">
                    <xsl:with-param name="iri" select="f:getIRI(.)" />
                    <xsl:with-param name="label" select="f:getLabelOutOfIt(.)" />
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="relationships">
        <xsl:call-template name="relationship">
            <xsl:with-param name="els" select="//g:edge[f:isRelationship(.)]" as="element()*" />
        </xsl:call-template>
    </xsl:template>
    
    
    <!-- FUNCTIONS -->
    <!-- It takes the centre of the node as coordinate -->
    <xsl:function name="f:getNodeCoordinates" as="xs:double+">
        <xsl:param name="node" as="element()" /> <!-- node -->
        
        <xsl:variable name="el" select="($node/self::y:Geometry|$node//y:Geometry)[1]" as="element()" />
        
        <xsl:variable name="x" select="$el/@x" as="xs:double" />
        <xsl:variable name="y" select="$el/@y" as="xs:double" />
        <xsl:variable name="w" select="$el/@width" as="xs:double" />
        <xsl:variable name="h" select="$el/@height" as="xs:double" />
        <xsl:sequence select="($x + ($w div 2),$y + ($h div 2))" />
    </xsl:function>
    
    <!-- It takes the position of the point in which an edge is connected with a node -->
    <xsl:function name="f:getEdgePointCoordinates" as="xs:double+">
        <xsl:param name="attr" as="attribute()" /> <!-- @source or @target -->
        
        <xsl:variable name="edge" select="$attr/parent::element()" as="element()" /> <!-- edge -->
        <xsl:variable name="node" select="root($attr)//g:node[@id = $attr]" /> <!-- related node -->
        <xsl:variable name="is-node-source" select="local-name($attr) = 'source'" as="xs:boolean" />
        
        <!-- Removed 2013-05-03 
        <xsl:variable name="nodeCoordinates" select="f:getNodeCoordinates($node)" />
        
        <xsl:variable name="dx" select="if (local-name($attr) = 'source') then $edge//y:Path/@sx else $edge//y:Path/@tx" as="xs:double" />
        <xsl:variable name="dy" select="if (local-name($attr) = 'source') then $edge//y:Path/@sy else $edge//y:Path/@ty" as="xs:double" />
        
        <xsl:sequence select="($nodeCoordinates[1] + $dx,$nodeCoordinates[2] + $dy)" />
        and substituted as follows: -->
        <xsl:variable name="rect" select="f:getRectangleCoordinates($node)" as="xs:double+" />
        
        <xsl:variable name="edge-point" as="xs:double+">
            <xsl:variable name="pointsOutsideRectangle" 
                select="$edge//y:Path/y:Point[not(f:isInRectangle((xs:double(@x),xs:double(@y)),$rect))]" 
                as="element()*" />
            
            <xsl:choose>
                <xsl:when test="$pointsOutsideRectangle">
                    <xsl:variable name="pointToConsider" as="element()">
                        <xsl:choose>
                            <xsl:when test="$is-node-source">
                                <xsl:sequence select="$pointsOutsideRectangle[1]" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="$pointsOutsideRectangle[last()]" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:sequence select="($pointToConsider/@x,$pointToConsider/@y)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="other-attr-id" 
                        select="if ($is-node-source) then $edge/@target else $edge/@source"
                        as="xs:string" />
                    <xsl:variable name="other-node" select="root($attr)//g:node[@id = $other-attr-id]" as="element()" />
                    <xsl:sequence select="f:getNodeCoordinates($other-node)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:sequence select="f:getIntesectionPoint($rect,$edge-point)" />
    </xsl:function>
    
    <xsl:function name="f:getRectangleCoordinates" as="xs:double+">
        <xsl:param name="node" as="element()" /> <!-- g:node -->
        <xsl:variable name="geo" select="$node//y:Geometry" as="element()" />
        <xsl:sequence select="(xs:double($geo/@x),xs:double($geo/@y),xs:double($geo/@width),xs:double($geo/@height))" />
    </xsl:function>
    
    <xsl:function name="f:getEdgeLabelCoordinates" as="xs:double+">
        <xsl:param name="label" as="element()" /> <!-- y:EdgeLabel -->
        
        <xsl:variable name="x" select="$label/@x" as="xs:double" />
        <xsl:variable name="y" select="$label/@y" as="xs:double" />
        <xsl:variable name="w" select="$label/@width" as="xs:double" />
        <xsl:variable name="h" select="$label/@height" as="xs:double" />
        
        <xsl:variable name="tmpCoordinates" select="($x + ($w div 2),$y + ($h div 2))" />
        <xsl:variable name="sourceCoordinates" 
            select="f:getEdgePointCoordinates($label/ancestor::g:edge[1]/@source)" as="xs:double+" />
        
        <xsl:sequence select="($sourceCoordinates[1] + $tmpCoordinates[1], $sourceCoordinates[2] + $tmpCoordinates[2])" />
    </xsl:function>
    
    <xsl:function name="f:getIRI" as="xs:anyURI+">
        <xsl:param name="el" as="element()+" /> <!-- It can be a y:NodeLabel of an entity, y:EdgeLabel of a relationship or a y:NodeLabel of an attribute  -->
        <xsl:variable name="result" as="xs:anyURI+">
            <xsl:for-each select="$el">
                <xsl:choose>
                    <xsl:when test="f:isEntity(.)">
                        <xsl:sequence select="f:classLocalURI(./ancestor-or-self::g:node[1]//y:NodeLabel//text())" />
                    </xsl:when>
                    <xsl:when test="f:isRelationship(./ancestor-or-self::g:edge[1])">
                        <xsl:sequence select="f:propertyLocalURI(.//text())" />
                    </xsl:when>
                    <xsl:otherwise> <!-- it's an attribute -->
                        <xsl:sequence select="f:propertyLocalURI(./ancestor-or-self::g:node[1]//y:NodeLabel//text())" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="$result" />
    </xsl:function>
    
    <xsl:function name="f:getLabelOutOfIt">
        <xsl:param name="el" as="element()" />
        <xsl:choose>
            <xsl:when test="f:isRelationship($el/ancestor-or-self::g:edge[1])">
                <xsl:value-of select="f:getLabel($el//text())" />
            </xsl:when>
            <!-- it's an entity or an attribute -->
            <xsl:when test="f:isEntity($el/ancestor-or-self::g:node[1]) or f:isAttribute($el/ancestor-or-self::g:node[1])">
                <xsl:value-of select="f:getLabel($el/ancestor-or-self::g:node[1]//y:NodeLabel//text())" />
            </xsl:when>
            <!-- The previous xsl:when modified the following one
            <xsl:otherwise>
                <xsl:value-of select="f:getLabel($el/ancestor-or-self::g:node[1]//y:NodeLabel//text())" />
            </xsl:otherwise>
            -->
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:getOtherNodeInEdge" as="element()">
        <xsl:param name="edge" as="element()" />
        <xsl:param name="node" as="element()" />
        <xsl:variable name="node-id" select="$node/@id" as="xs:string" />
        
        <xsl:variable name="attr" select="$edge/(@source|@target)[. != $node-id][1]" />
        <xsl:choose>
            <xsl:when test="$attr">
                <xsl:sequence select="root($node)//g:node[@id = $attr]" />
            </xsl:when>
            <xsl:otherwise> <!-- It means that the source and target nodes of this edge is the same node -->
                <xsl:sequence select="$node" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:getPropertyLabelHavingNodeAsDomain" as="element()?">
        <xsl:param name="node" as="element()" />
        <xsl:param name="edge" as="element()" />
        
        <xsl:choose>
            <xsl:when test="$look-across-for-labels">
                <xsl:sequence select="f:__getPropertyLabelHavingNodeAsDomain($node,$edge)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="f:__getPropertyLabelHavingNodeAsRange($node,$edge)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:getPropertyLabelHavingNodeAsRange" as="element()?">
        <xsl:param name="node" as="element()" />
        <xsl:param name="edge" as="element()" />
        
        <xsl:choose>
            <xsl:when test="$look-across-for-labels">
                <xsl:sequence select="f:__getPropertyLabelHavingNodeAsRange($node,$edge)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="f:__getPropertyLabelHavingNodeAsDomain($node,$edge)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:__getPropertyLabelHavingNodeAsDomain" as="element()?">
        <xsl:param name="node" as="element()" />
        <xsl:param name="edge" as="element()" />
        
        <xsl:variable name="result" select="f:__getPropertyLabelDistances($node,$edge)" />
        <xsl:variable name="toReturn" select="if ($result[2] > $result[1]) then $result[4] else $result[3]" as="element()?" />
        <xsl:sequence select="if (normalize-space($toReturn) = '') then () else $toReturn" />
        
        <!-- Before the previous two lines where substituted by the following one 
            <xsl:sequence select="if ($result[2] > $result[1]) then $result[4] else $result[3]" />
        -->
    </xsl:function>
    
    <xsl:function name="f:__getPropertyLabelHavingNodeAsRange" as="element()?">
        <xsl:param name="node" as="element()" />
        <xsl:param name="edge" as="element()" />
        
        <xsl:variable name="result" select="f:__getPropertyLabelDistances($node,$edge)" />
        <xsl:variable name="toReturn" select="if ($result[2] > $result[1]) then $result[3] else $result[4]" as="element()?" />
        <xsl:sequence select="if (normalize-space($toReturn) = '') then () else $toReturn" />
        
        <!-- Before the previous two lines where substituted by the following one 
            <xsl:sequence select="if ($result[2] > $result[1]) then $result[3] else $result[4]" />
        -->
    </xsl:function>
    
    <xsl:function name="f:__getPropertyLabelDistances" as="item()*">
        <xsl:param name="node" as="element()" />
        <xsl:param name="edge" as="element()" />
        
        <xsl:variable name="other-node" select="f:getOtherNodeInEdge($edge,$node)" as="element()" />
        <xsl:variable name="is-node-source" select="$node/@id = $edge/@source" as="xs:boolean" />
        
        <xsl:choose>
            <xsl:when test="count($edge//y:EdgeLabel) = 1"> <!-- There exists one label -->
                <xsl:variable name="edge-label" select="$edge//y:EdgeLabel" />
                
                <!-- Modified 25/04/2013
                <xsl:variable name="nodes-coordinates" select="
                    if ($is-node-source) then (0.0,0.0,f:differenceCoordinates(f:getCoordinates($other-node//y:Geometry),f:getCoordinates($node//y:Geometry))) else (f:differenceCoordinates(f:getCoordinates($node//y:Geometry),f:getCoordinates($other-node//y:Geometry)),0.0,0.0)" />
                <xsl:variable name="edges-coordinates" select="f:getCoordinates($edge-label)" />
                
                <xsl:variable name="node-1-distance-label" select="f:getDistanceExponential(
                    ($nodes-coordinates[1],$nodes-coordinates[2]),
                    ($edges-coordinates[1],$edges-coordinates[2]))" />
                <xsl:variable name="node-2-distance-label" select="f:getDistanceExponential(
                    ($nodes-coordinates[3],$nodes-coordinates[4]),
                    ($edges-coordinates[1],$edges-coordinates[2]))" />
                    
                    <xsl:sequence select="($node-1-distance-label,$node-2-distance-label,$edge-label)" />
                    as follows: -->
                <xsl:variable name="source-coordinates" select="f:getEdgePointCoordinates($edge/@source)" />
                <xsl:variable name="target-coordinates" select="f:getEdgePointCoordinates($edge/@target)" />
                <xsl:variable name="edge-coordinates" select="f:getEdgeLabelCoordinates($edge-label)" />
                
                <xsl:variable name="source-distance-label" select="f:getDistanceExponential(
                    ($source-coordinates[1],$source-coordinates[2]),
                    ($edge-coordinates[1],$edge-coordinates[2]))" />
                <xsl:variable name="target-distance-label" select="f:getDistanceExponential(
                    ($target-coordinates[1],$target-coordinates[2]),
                    ($edge-coordinates[1],$edge-coordinates[2]))" />
                
                <xsl:variable name="node-distance" 
                    select="if ($is-node-source) then $source-distance-label else $target-distance-label" />
                <xsl:variable name="other-node-distance" 
                    select="if ($is-node-source) then $target-distance-label else $source-distance-label" />
                
                <!-- Distance from $node to the label, distance from $other-node to the label, the label -->
                <xsl:sequence select="($node-distance,$other-node-distance,$edge-label)" />
            </xsl:when>
            <xsl:when test="count($edge//y:EdgeLabel) > 1"> <!-- There exist two labels -->
                <xsl:variable name="edge-label1" select="$edge//y:EdgeLabel[1]" />
                <xsl:variable name="edge-label2" select="$edge//y:EdgeLabel[2]" />
                
                <!-- Modified 25/04/2013
                <xsl:variable name="nodes-coordinates" select="f:normaliseCoordinates(
                    f:getCoordinates($node//y:Geometry),f:getCoordinates($other-node//y:Geometry))" />
                <xsl:variable name="edges-coordinates" select="f:normaliseCoordinates(f:getCoordinates($edge-label1),f:getCoordinates($edge-label2))" />
                
                <xsl:variable name="distance-label-1" select="f:getDistanceExponential(
                    ($nodes-coordinates[1],$nodes-coordinates[2]),
                    ($edges-coordinates[1],$edges-coordinates[2]))" />
                <xsl:variable name="distance-label-2" select="f:getDistanceExponential(
                    ($nodes-coordinates[1],$nodes-coordinates[2]),
                    ($edges-coordinates[3],$edges-coordinates[4]))" />
                <xsl:sequence select="$distance-label-1,$distance-label-2,$edge-label1,$edge-label2" />    
                as follows: -->
                <xsl:variable name="node-point-edge-coordinates"
                    select="if ($is-node-source) then f:getEdgePointCoordinates($edge/@source) else f:getEdgePointCoordinates($edge/@target)" />
                <xsl:variable name="label-1-coordinates" select="f:getEdgeLabelCoordinates($edge-label1)" />
                <xsl:variable name="label-2-coordinates" select="f:getEdgeLabelCoordinates($edge-label2)" />
                
                <xsl:variable name="distance-label-1" select="f:getDistanceExponential(
                    ($node-point-edge-coordinates[1],$node-point-edge-coordinates[2]),
                    ($label-1-coordinates[1],$label-1-coordinates[2]))" />
                <xsl:variable name="distance-label-2" select="f:getDistanceExponential(
                    ($node-point-edge-coordinates[1],$node-point-edge-coordinates[2]),
                    ($label-2-coordinates[1],$label-2-coordinates[2]))" />
                
                <!-- Distance from $node to the $label-1, distance from $node to the $label-2, $label-1, $label-2 -->
                <xsl:sequence select="$distance-label-1,$distance-label-2,$edge-label1,$edge-label2" />
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:getPropertyValueAsDomain" as="xs:string">
        <xsl:param name="edge" as="element()"/>
        <xsl:param name="node" as="element()"/>
        
        <xsl:variable name="source-target" select="if ($node/@id = $edge/@source) then 'target' else 'source'" as="xs:string" />
        <xsl:value-of select="normalize-space($edge//y:Arrows/attribute()[local-name() = $source-target])" />
    </xsl:function>
    
    <xsl:function name="f:getPropertyValueAsRange" as="xs:string">
        <xsl:param name="edge" as="element()"/>
        <xsl:param name="node" as="element()"/>
        
        <xsl:variable name="source-target" select="if ($node/@id = $edge/@target) then 'source' else 'target'" as="xs:string" />
        <xsl:value-of select="normalize-space($edge//y:Arrows/attribute()[local-name() = $source-target])" />
    </xsl:function>
    
    <xsl:function name="f:isAttribute" as="xs:boolean">
        <xsl:param name="el" as="element()?" />
        
        <xsl:value-of select="ends-with($el//y:GenericNode/@configuration,'.attribute')"/>
    </xsl:function>
    
    <xsl:function name="f:isInvolvedInEdge" as="xs:boolean">
        <xsl:param name="node" as="element()" />
        <xsl:param name="edge" as="element()" />
        
        <xsl:value-of select="some $attr in $edge/(@source|@target) satisfies $node/@id = $attr" />
    </xsl:function>
    
    <xsl:function name="f:isEntity" as="xs:boolean">
        <xsl:param name="el" as="element()?" />
        
        <xsl:value-of select="ends-with($el//y:GenericNode/@configuration,'.small_entity')" />
    </xsl:function>
    
    <xsl:function name="f:isGeneralization" as="xs:boolean">
        <xsl:param name="el" as="element()?" />
        
        <xsl:value-of select="$el/self::g:edge and (some $attr in $el//y:Arrows/(@source|@target) satisfies $attr = 'white_delta')"/>
    </xsl:function>
    
    <xsl:function name="f:isRelationship" as="xs:boolean">
        <xsl:param name="el" as="element()?" />
        
        <xsl:value-of select="exists($el//y:EdgeLabel[normalize-space() != ''])"/>
    </xsl:function>
    
    <!-- Issues: relationship to the same entity, only one label for a relationship -->
</xsl:stylesheet>