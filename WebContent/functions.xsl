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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:f="http://www.essepuntato.it/xslt/function/"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <!-- 
        This function checks if the input point (x,y) is defined within a 
        rectangle (top-left point x, top-left point y, width, height) -->
    <xsl:function name="f:isInRectangle" as="xs:boolean">
        <xsl:param name="point" as="xs:double+" /> <!-- (x,y) -->
        <xsl:param name="rect" as="xs:double+" /> <!-- (top-left point x, top-left point y, width, height) -->
        
        <xsl:variable name="x" select="$point[1]" />
        <xsl:variable name="y" select="$point[2]" />
        <xsl:variable name="rect_x_min" select="$rect[1]" />
        <xsl:variable name="rect_y_min" select="$rect[1]" />
        <xsl:variable name="rect_x_max" select="$rect_x_min + $rect[3]" />
        <xsl:variable name="rect_y_max" select="$rect_y_min + $rect[4]" />
        
        <xsl:sequence select="
            $rect_x_min &lt;= $x and $x &lt;= $rect_x_max
            and
            $rect_y_min &lt;= $y and $y &lt;= $rect_y_max" />
    </xsl:function>
    
    <!-- 
        This function takes as input a rectangle (top-left point x, top-left point y, width, height) 
        and an outside point (x,y) and returns the point where the segment generated between the center 
        of the rectangle and the outside point intersects the rectangle itself -->
    <xsl:function name="f:getIntesectionPoint" as="xs:double+">
        <xsl:param name="rect" as="xs:double+" /> <!-- (top-left point x, top-left point y, width, height) -->
        <xsl:param name="out" as="xs:double+" /> <!-- (x,y) -->
        
        <xsl:variable name="in" select="($rect[1] + ($rect[3] div 2.0),$rect[2] + ($rect[4] div 2.0))" as="xs:double+" />
        <xsl:variable name="slope" select="($out[2] - $in[2]) div ($out[1] - $in[1])" as="xs:double" />
        
        <xsl:variable name="edge" as="xs:double+"> <!-- (x1,y1,x2,y2) -->
            <!-- Algorithm found at
            http://stackoverflow.com/questions/1585525/how-to-find-the-intersection-point-between-a-line-and-a-rectangle -->
            <xsl:variable name="hDiv2" select="$rect[4] div 2" as="xs:double" />
            <xsl:variable name="comp" select="$slope * ($rect[3] div 2)" as="xs:double" />
            <xsl:choose>
                <xsl:when test="(-1 * $hDiv2) &lt;= $comp and $comp &lt;= $hDiv2">
                    <xsl:choose>
                        <xsl:when test="$out[1] >= $in[1]">
                            <!-- right -->
                            <xsl:sequence select="($rect[1] + $rect[3],$rect[2],$rect[1] + $rect[3],$rect[2] + $rect[4])" />
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- left -->
                            <xsl:sequence select="($rect[1],$rect[2],$rect[1],$rect[2] + $rect[4])" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="$out[2] &lt;= $in[2]">
                            <!-- top -->
                            <xsl:sequence select="($rect[1],$rect[2],$rect[1] + $rect[3],$rect[2])" />
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- bottom -->
                            <xsl:sequence select="($rect[1],$rect[2] + $rect[4],$rect[1] + $rect[3],$rect[2] + $rect[4])" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Algorithm found at 
        http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect -->
        <xsl:variable name="RS_x" select="$edge[1]" as="xs:double" />
        <xsl:variable name="RS_y" select="$edge[2]" as="xs:double" />
        <xsl:variable name="RT_x" select="$edge[3]" as="xs:double" />
        <xsl:variable name="RT_y" select="$edge[4]" as="xs:double" />
        <xsl:variable name="OS_x" select="$in[1]" as="xs:double" />
        <xsl:variable name="OS_y" select="$in[2]" as="xs:double" />
        <xsl:variable name="OT_x" select="$out[1]" as="xs:double" />
        <xsl:variable name="OT_y" select="$out[2]" as="xs:double" />
        <xsl:variable name="r_x" select="$RT_x - $RS_x" as="xs:double" />
        <xsl:variable name="r_y" select="$RT_y - $RS_y" as="xs:double" />
        <xsl:variable name="o_x" select="$OT_x - $OS_x" as="xs:double" />
        <xsl:variable name="o_y" select="$OT_y - $OS_y" as="xs:double" />
        <xsl:variable name="s" select="
            ((-1 * $r_y) * ($RS_x - $OS_x) + $r_x * ($RS_y - $OS_y)) div ((-1 * $o_x) * $r_y + $r_x * $o_y)" 
            as="xs:double" />
        <xsl:variable name="t" select="
            ($o_x * ($RS_y - $OS_y) - $o_y * ($RS_x - $OS_x)) div ((-1 * $o_x) * $r_y + $r_x * $o_y)" 
            as="xs:double" />
        <xsl:sequence select="($RS_x + ($t * $r_x),$RS_y + ($t * $r_y))" />
    </xsl:function>
    
    <!-- NB: all these functions works independently from the XML graphical format used to store diagrams. This means that they can be used for different kinds of linearisation (e.g. E/R, UML, Graffoo).  -->
    <xsl:function name="f:differenceCoordinates" as="xs:double+">
        <xsl:param name="coord1" as="xs:double+" />
        <xsl:param name="coord2" as="xs:double+" />
        
        <xsl:variable name="x1" select="$coord1[1]" as="xs:double" />
        <xsl:variable name="y1" select="$coord1[2]" as="xs:double" />
        <xsl:variable name="x2" select="$coord2[1]" as="xs:double" />
        <xsl:variable name="y2" select="$coord2[2]" as="xs:double" />
        
        <xsl:sequence select="($x1 - $x2,$y1 - $y2)" />
    </xsl:function>
    
    <xsl:function name="f:getLabel" as="xs:string?">
        <xsl:param name="string" as="xs:string+" />
        
        <xsl:value-of select="normalize-space(string-join($string,''))" separator="" />
    </xsl:function>
    
    <xsl:function name="f:normaliseCoordinates" as="xs:double+">
        <xsl:param name="coord1" as="xs:double+" />
        <xsl:param name="coord2" as="xs:double+" />
        
        <xsl:variable name="x1" select="$coord1[1]" as="xs:double" />
        <xsl:variable name="y1" select="$coord1[2]" as="xs:double" />
        <xsl:variable name="x2" select="$coord2[1]" as="xs:double" />
        <xsl:variable name="y2" select="$coord2[2]" as="xs:double" />
        
        <xsl:variable name="x1-new" select="if ($x2 >= $x1) then 0 else $x1 - $x2" as="xs:double" />
        <xsl:variable name="x2-new" select="if ($x2 >= $x1) then $x2 - $x1 else 0" as="xs:double" />
        <xsl:variable name="y1-new" select="if ($y2 >= $y1) then 0 else $y1 - $y2" as="xs:double" />
        <xsl:variable name="y2-new" select="if ($y2 >= $y1) then $y2 - $y1 else 0" as="xs:double" />
        
        <xsl:sequence select="($x1-new,$y1-new,$x2-new,$y2-new)" />
    </xsl:function>
    
    <!-- This function calculates an aproximate euclidean distance between two points (there is an error factor that may cause mistakes) -->
    <xsl:function name="f:getDistance" as="xs:double">
        <xsl:param name="coord1" as="xs:double+" />
        <xsl:param name="coord2" as="xs:double+" />
        
        <xsl:variable name="x1" select="$coord1[1]" as="xs:double" />
        <xsl:variable name="y1" select="$coord1[2]" as="xs:double" />
        <xsl:variable name="x2" select="$coord2[1]" as="xs:double" />
        <xsl:variable name="y2" select="$coord2[2]" as="xs:double" />
        
        <xsl:variable name="dx" select="abs($x1 - $x2)" as="xs:double" />
        <xsl:variable name="dy" select="abs($y1 - $y2)" as="xs:double" />
        
        <xsl:choose> <!-- Approsimation from http://it.wikipedia.org/wiki/Distanza_euclidea -->
            <xsl:when test="$dy > $dx">
                <xsl:value-of select="(0.41 * $dx)+(0.941246 * $dy)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="(0.41 * $dy)+(0.941246 * $dx)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- This function calculates the exponential value of the euclidean distance, which means that the value returned is not the real distance but can be used for comparing distances so as to understand if a distance is greater/less than another -->
    <xsl:function name="f:getDistanceExponential" as="xs:double">
        <xsl:param name="coord1" as="xs:double+" />
        <xsl:param name="coord2" as="xs:double+" />
        
        <xsl:variable name="x1" select="$coord1[1]" as="xs:double" />
        <xsl:variable name="y1" select="$coord1[2]" as="xs:double" />
        <xsl:variable name="x2" select="$coord2[1]" as="xs:double" />
        <xsl:variable name="y2" select="$coord2[2]" as="xs:double" />
        
        <xsl:variable name="dx" select="($x1 - $x2) * ($x1 - $x2)" as="xs:double" />
        <xsl:variable name="dy" select="($y1 - $y2) * ($y1 - $y2)" as="xs:double" />
        
        <!-- Approsimation from http://en.wikibooks.org/wiki/Algorithms/Distance_approximations -->
        <xsl:value-of select="$dx + $dy" />
    </xsl:function>
    
    <xsl:function name="f:isCamelCase" as="xs:boolean">
        <xsl:param name="string" as="xs:string" />
        <xsl:value-of select="matches($string,'([A-Z]|[a-z])[a-z]+[A-Z].*')" />
    </xsl:function>
    
    <xsl:function name="f:classLocalURI" as="xs:anyURI">
        <xsl:param name="string" as="xs:string+" />
        
        <xsl:value-of select="for $i in f:split(string-join($string,'')) return f:capitaliseFirst($i)" separator="" />
    </xsl:function>
    
    <xsl:function name="f:propertyLocalURI" as="xs:anyURI">
        <xsl:param name="string" as="xs:string+" />
        <xsl:variable name="string-split" select="f:split(string-join($string,''))" as="xs:string+" />
        
        <xsl:value-of select="($string-split[1],for $i in subsequence($string-split,2) return f:capitaliseFirst($i))" separator="" />
    </xsl:function>
    
    <xsl:function name="f:split" as="xs:string+">
        <xsl:param name="string" as="xs:string" />
        <xsl:sequence select="tokenize(f:normaliseForURI($string),' ')" />
    </xsl:function>
    
    <xsl:function name="f:normaliseForURI" as="xs:string">
        <xsl:param name="string" as="xs:string" />
        <xsl:value-of select="normalize-space(lower-case(f:__normaliseForURI($string,1)))" />
    </xsl:function>
    
    <xsl:function name="f:__normaliseForURI" as="xs:string">
        <xsl:param name="string" as="xs:string" />
        <xsl:param name="count" as="xs:integer" />
        
        <xsl:variable name="original"    select="('-','è','é','à','ò','ì','ù','_','/',':','\(','\)',&quot;'&quot;)" as="xs:string*" />
        <xsl:variable name="replacement" select="(' ','e','e','a','o','i','u',' ',' ',' ',' ', ' ',' ')" as="xs:string*" />
        
        <xsl:choose>
            <xsl:when test="$count > count($original)">
                <xsl:value-of select="$string" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="replace(f:__normaliseForURI($string,$count+1),$original[$count],$replacement[$count])" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:capitaliseFirst">
        <xsl:param name="string" as="xs:string?" />
        <xsl:value-of select="concat(upper-case(substring($string,1,1)),substring($string,2))" />
    </xsl:function>
</xsl:stylesheet>