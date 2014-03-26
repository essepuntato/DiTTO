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
    xmlns:rdfs="&rdfs;"
    xmlns:owl="&owl;"
    xmlns:rdf="&rdf;"
    xmlns:f="http://www.essepuntato.it/xslt/function/"
    exclude-result-prefixes="xs f"
    version="2.0">
    
    <xsl:import href="functions.xsl"/>
    
    <xsl:template name="class">
        <xsl:param name="iri" as="xs:anyURI" />
        <xsl:param name="label" as="xs:string?" />
        <rdf:Description rdf:about="{$iri}">
            <rdf:type rdf:resource="&owl;Class" />
            <xsl:if test="$label">
                <rdfs:label><xsl:value-of select="$label" /></rdfs:label>
            </xsl:if>
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="compose-classes-as-union">
        <xsl:param name="classes" as="xs:anyURI*" />
        <xsl:choose>
            <xsl:when test="count($classes) = 1">
                <xsl:attribute name="rdf:resource" select="$classes[1]" />
            </xsl:when>
            <xsl:when test="count($classes) > 1">
                <owl:Class>
                    <owl:unionOf>
                        <xsl:call-template name="create-list">
                            <xsl:with-param name="uris" select="$classes" as="xs:anyURI*" />
                        </xsl:call-template>
                    </owl:unionOf>
                </owl:Class>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="create-list">
        <xsl:param name="uris" as="xs:anyURI*" />
        <xsl:choose>
            <xsl:when test="empty($uris)">
                <xsl:attribute name="rdf:resource" select="'&rdf;nil'" />
            </xsl:when>
            <xsl:otherwise>
                <rdf:Description>
                    <rdf:first rdf:resource="{$uris[1]}" />
                    <rdf:rest>
                        <xsl:call-template name="create-list">
                            <xsl:with-param name="uris" select="subsequence($uris,2)" as="xs:anyURI*" />
                        </xsl:call-template>
                    </rdf:rest>
                </rdf:Description>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="data-property">
        <xsl:param name="iri" as="xs:anyURI" />
        <xsl:param name="label" as="xs:string?" />
        <xsl:param name="domain" as="xs:anyURI*" />
        <xsl:param name="range" as="xs:anyURI*" />
        <xsl:param name="functional" as="xs:boolean?" />
        <rdf:Description rdf:about="{$iri}">
            <rdf:type rdf:resource="&owl;DatatypeProperty" />
            <xsl:if test="$label">
                <rdfs:label><xsl:value-of select="$label" /></rdfs:label>
            </xsl:if>
            <xsl:if test="exists($domain)">
                <rdfs:domain>
                    <xsl:call-template name="compose-classes-as-union">
                        <xsl:with-param name="classes" select="$domain" as="xs:anyURI*" />
                    </xsl:call-template>
                </rdfs:domain>
            </xsl:if>
            <xsl:if test="exists($range)">
                <rdfs:range>
                    <xsl:call-template name="compose-classes-as-union">
                        <xsl:with-param name="classes" select="$range" as="xs:anyURI*" />
                    </xsl:call-template>
                </rdfs:range>
            </xsl:if>
            <xsl:if test="$functional">
                <rdf:type rdf:resource="&owl;FunctionalProperty" />
            </xsl:if>
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="exactly-subclass">
        <xsl:param name="iri" as="xs:anyURI" />
        <xsl:param name="classes" as="xs:anyURI*" />
        <xsl:param name="property" as="xs:anyURI" />
        <xsl:param name="cardinality" as="xs:integer" />
        <xsl:param name="inverse" select="false()" as="xs:boolean" />
        <rdf:Description rdf:about="{$iri}">
            <rdfs:subClassOf>
                <xsl:call-template name="restriction">
                    <xsl:with-param name="inverse" select="$inverse" />
                    <xsl:with-param name="type" select="'exactly'" />
                    <xsl:with-param name="classes" select="$classes" />
                    <xsl:with-param name="property" select="$property" />
                    <xsl:with-param name="cardinality" select="$cardinality" />
                </xsl:call-template>
            </rdfs:subClassOf>
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="key">
        <xsl:param name="iri" as="xs:anyURI" />
        <xsl:param name="key-set" as="xs:anyURI+" />
        <rdf:Description rdf:about="{$iri}">
            <owl:hasKey rdf:parseType="Collection">
                <xsl:for-each select="$key-set">
                    <rdf:Description rdf:about="{.}" />
                </xsl:for-each>
            </owl:hasKey>
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="inverse-of">
        <xsl:param name="iri-property-1" as="xs:anyURI" />
        <xsl:param name="iri-property-2" as="xs:anyURI" />
        
        <rdf:Description rdf:about="{$iri-property-1}">
            <owl:inverseOf rdf:resource="{$iri-property-2}" />
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="max-subclass">
        <xsl:param name="iri" as="xs:anyURI" />
        <xsl:param name="classes" as="xs:anyURI*" />
        <xsl:param name="property" as="xs:anyURI" />
        <xsl:param name="cardinality" as="xs:integer" />
        <xsl:param name="inverse" select="false()" as="xs:boolean" />
        <rdf:Description rdf:about="{$iri}">
            <rdfs:subClassOf>
                <xsl:call-template name="restriction">
                    <xsl:with-param name="inverse" select="$inverse" />
                    <xsl:with-param name="type" select="'max'" />
                    <xsl:with-param name="classes" select="$classes" />
                    <xsl:with-param name="property" select="$property" />
                    <xsl:with-param name="cardinality" select="$cardinality" />
                </xsl:call-template>
            </rdfs:subClassOf>
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="restriction">
        <xsl:param name="type" as="xs:string" /> <!-- one of 'some', 'max', 'exactly' -->
        <xsl:param name="classes" as="xs:anyURI*" />
        <xsl:param name="property" as="xs:anyURI" />
        <xsl:param name="inverse" as="xs:boolean?" />
        <xsl:param name="cardinality" as="xs:integer?" />
        <owl:Restriction>
            <owl:onProperty>
                <xsl:choose>
                    <xsl:when test="$inverse">
                        <rdf:Description>
                            <owl:inverseOf rdf:resource="{$property}" />
                        </rdf:Description>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="rdf:resource" select="$property" />
                    </xsl:otherwise>
                </xsl:choose>
            </owl:onProperty>
            <xsl:choose>
                <xsl:when test="$type = 'some'">
                    <owl:someValuesFrom>
                        <xsl:call-template name="compose-classes-as-union">
                            <xsl:with-param name="classes" select="$classes" as="xs:anyURI*" />
                        </xsl:call-template>
                    </owl:someValuesFrom>
                </xsl:when>
                <xsl:when test="$type = 'only'">
                    <owl:allValuesFrom>
                        <xsl:call-template name="compose-classes-as-union">
                            <xsl:with-param name="classes" select="$classes" as="xs:anyURI*" />
                        </xsl:call-template>
                    </owl:allValuesFrom>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="$classes">
                        <owl:onClass>
                            <xsl:call-template name="compose-classes-as-union">
                                <xsl:with-param name="classes" select="$classes" as="xs:anyURI*" />
                            </xsl:call-template>
                        </owl:onClass>
                    </xsl:if>
                    <xsl:variable name="qualified" select="if ($classes) then 'qualifiedC' else 'c'" />
                    <xsl:choose>
                        <xsl:when test="$type = 'max'">
                            <xsl:element name="owl:max{f:capitaliseFirst($qualified)}ardinality">
                                <xsl:attribute name="rdf:datatype" select="'&xsd;nonNegativeInteger'" />
                                <xsl:value-of select="$cardinality" />
                            </xsl:element>
                        </xsl:when>
                        <xsl:when test="$type = 'exactly'">
                            <xsl:element name="owl:{$qualified}ardinality">
                                <xsl:attribute name="rdf:datatype" select="'&xsd;nonNegativeInteger'" />
                                <xsl:value-of select="$cardinality" />
                            </xsl:element>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
                <!-- [TODO] Handle other restrictions: 'value', 'one of', 'min' -->
            </xsl:choose>
        </owl:Restriction>
    </xsl:template>
    
    <xsl:template name="object-property">
        <xsl:param name="iri" as="xs:anyURI" />
        <xsl:param name="label" as="xs:string?" />
        <xsl:param name="domain" as="xs:anyURI*" />
        <xsl:param name="range" as="xs:anyURI*" />
        <xsl:param name="functional" as="xs:boolean?" />
        <xsl:param name="inverse-functional" as="xs:boolean?" />
        <xsl:param name="symmetric" as="xs:boolean?" />
        <xsl:param name="asymmetric" as="xs:boolean?" />
        <xsl:param name="reflexive" as="xs:boolean?" />
        <xsl:param name="irreflexive" as="xs:boolean?" />
        <xsl:param name="transitive" as="xs:boolean?" />
        <rdf:Description rdf:about="{$iri}">
            <rdf:type rdf:resource="&owl;ObjectProperty" />
            <xsl:if test="$label">
                <rdfs:label><xsl:value-of select="$label" /></rdfs:label>
            </xsl:if>
            <xsl:if test="exists($domain)">
                <rdfs:domain>
                    <xsl:call-template name="compose-classes-as-union">
                        <xsl:with-param name="classes" select="$domain" as="xs:anyURI*" />
                    </xsl:call-template>
                </rdfs:domain>
            </xsl:if>
            <xsl:if test="exists($range)">
                <rdfs:range>
                    <xsl:call-template name="compose-classes-as-union">
                        <xsl:with-param name="classes" select="$range" as="xs:anyURI*" />
                    </xsl:call-template>
                </rdfs:range>
            </xsl:if>
            <xsl:if test="$functional">
                <rdf:type rdf:resource="&owl;FunctionalProperty" />
            </xsl:if>
            <xsl:if test="$inverse-functional">
                <rdf:type rdf:resource="&owl;InverseFunctionalProperty" />
            </xsl:if>
            <xsl:if test="$symmetric">
                <rdf:type rdf:resource="&owl;SymmetricProperty" />
            </xsl:if>
            <xsl:if test="$asymmetric">
                <rdf:type rdf:resource="&owl;AsymmetricProperty" />
            </xsl:if>
            <xsl:if test="$transitive">
                <rdf:type rdf:resource="&owl;TransitiveProperty" />
            </xsl:if>
            <xsl:if test="$irreflexive">
                <rdf:type rdf:resource="&owl;IrreflexiveProperty" />
            </xsl:if>
            <xsl:if test="$reflexive">
                <rdf:type rdf:resource="&owl;ReflexiveProperty" />
            </xsl:if>
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="only-subclass">
        <xsl:param name="iri" as="xs:anyURI" />
        <xsl:param name="classes" as="xs:anyURI+" />
        <xsl:param name="property" as="xs:anyURI" />
        <xsl:param name="inverse" select="false()" as="xs:boolean" />
        <rdf:Description rdf:about="{$iri}">
            <rdfs:subClassOf>
                <xsl:call-template name="restriction">
                    <xsl:with-param name="inverse" select="$inverse" />
                    <xsl:with-param name="type" select="'only'" />
                    <xsl:with-param name="classes" select="$classes" />
                    <xsl:with-param name="property" select="$property" />
                </xsl:call-template>
            </rdfs:subClassOf>
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="some-subclass">
        <xsl:param name="iri" as="xs:anyURI" />
        <xsl:param name="classes" as="xs:anyURI+" />
        <xsl:param name="property" as="xs:anyURI" />
        <xsl:param name="inverse" select="false()" as="xs:boolean" />
        <rdf:Description rdf:about="{$iri}">
            <rdfs:subClassOf>
                <xsl:call-template name="restriction">
                    <xsl:with-param name="inverse" select="$inverse" />
                    <xsl:with-param name="type" select="'some'" />
                    <xsl:with-param name="classes" select="$classes" />
                    <xsl:with-param name="property" select="$property" />
                </xsl:call-template>
            </rdfs:subClassOf>
        </rdf:Description>
    </xsl:template>
    
    <xsl:template name="subclass-of">
        <xsl:param name="subclass" as="xs:anyURI" />
        <xsl:param name="class" as="xs:anyURI" />
        
        <rdf:Description rdf:about="{$subclass}">
            <rdfs:subClassOf rdf:resource="{$class}" />
        </rdf:Description>
    </xsl:template>
</xsl:stylesheet>