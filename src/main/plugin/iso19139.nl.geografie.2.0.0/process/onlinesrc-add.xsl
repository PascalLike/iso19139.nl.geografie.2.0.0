<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ Copyright (C) 2001-2016 Food and Agriculture Organization of the
  ~ United Nations (FAO-UN), United Nations World Food Programme (WFP)
  ~ and United Nations Environment Programme (UNEP)
  ~
  ~ This program is free software; you can redistribute it and/or modify
  ~ it under the terms of the GNU General Public License as published by
  ~ the Free Software Foundation; either version 2 of the License, or (at
  ~ your option) any later version.
  ~
  ~ This program is distributed in the hope that it will be useful, but
  ~ WITHOUT ANY WARRANTY; without even the implied warranty of
  ~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  ~ General Public License for more details.
  ~
  ~ You should have received a copy of the GNU General Public License
  ~ along with this program; if not, write to the Free Software
  ~ Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
  ~
  ~ Contact: Jeroen Ticheler - FAO - Viale delle Terme di Caracalla 2,
  ~ Rome - Italy. email: geonetwork@osgeo.org
  -->

<xsl:stylesheet  xmlns:gmd="http://www.isotc211.org/2005/gmd"
                 xmlns:gco="http://www.isotc211.org/2005/gco"
                 xmlns:gmx="http://www.isotc211.org/2005/gmx"
                 xmlns:xlink="http://www.w3.org/1999/xlink"
                 xmlns:geonet="http://www.fao.org/geonetwork"
                 xmlns:java="java:org.fao.geonet.util.XslUtil"
                 xmlns:xs="http://www.w3.org/2001/XMLSchema"
                 xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:import href="../../iso19139/process/onlinesrc-add.xsl"/>

  <!-- Override templates to handle protocol anchor -->

  <!-- Updating the link matching the update key. -->
  <xsl:template match="gmd:onLine[
                        normalize-space($updateKey) = concat(
                        gmd:CI_OnlineResource/gmd:linkage/gmd:URL,
                        gmd:CI_OnlineResource/gmd:protocol/*/text(),
                        gmd:CI_OnlineResource/gmd:applicationProfile/*/text(),
                        gmd:CI_OnlineResource/gmd:name/gco:CharacterString,
                        gmd:CI_OnlineResource/gmd:name/gmd:PT_FreeText/gmd:textGroup/gmd:LocalisedCharacterString[@locale = '#DE'])
                        ]">
    <xsl:call-template name="createOnlineSrc"/>
  </xsl:template>

  <xsl:template name="createOnlineSrc">
    <!-- Check protocol value in labels.xml to retrieve the anchor link value -->
    <!-- Fixed to dutch labels as it's the main resource updated -->
    <xsl:variable name="labels"
                  select="document('../loc/dut/labels.xml')"/>

    <!-- Add all online source from the target metadata to the
    current one -->
    <xsl:if test="//extra">
      <xsl:for-each select="//extra//gmd:onLine">
        <gmd:onLine>
          <xsl:if test="$extra_metadata_uuid">
            <xsl:attribute name="uuidref" select="$extra_metadata_uuid"/>
          </xsl:if>
          <xsl:apply-templates select="*"/>
        </gmd:onLine>
      </xsl:for-each>
    </xsl:if>

    <xsl:variable name="separator" select="'\|'"/>
    <xsl:variable name="useOnlyPTFreeText">
      <xsl:value-of
        select="count(//*[gmd:PT_FreeText and not(gco:CharacterString)]) > 0"/>
    </xsl:variable>

    <xsl:if test="$url">
      <!-- In case the protocol is an OGC protocol
      the name parameter may contains a list of layers
      separated by comma.
      In that case on one online element is added per
      layer/featureType.
      -->
      <xsl:choose>
        <xsl:when test="starts-with($protocol, 'OGC:') and $name != ''">

          <xsl:for-each select="tokenize($name, ',')">
            <xsl:variable name="pos" select="position()"/>

            <gmd:onLine>
              <xsl:if test="$uuidref">
                <xsl:attribute name="uuidref" select="$uuidref"/>
              </xsl:if>
              <gmd:CI_OnlineResource>
                <gmd:linkage>
                  <gmd:URL>
                    <xsl:value-of select="$url"/>
                  </gmd:URL>
                </gmd:linkage>
                <gmd:protocol>
                  <xsl:variable name="protocolLink" select="$labels/labels/element[@name='gmd:protocol']/helper/option[@value=$protocol]/@id" />

                  <xsl:choose>
                    <xsl:when test="string($protocolLink)">
                      <gmx:Anchor xlink:href="{$protocolLink}">
                        <xsl:value-of select="$protocol"/>
                      </gmx:Anchor>
                    </xsl:when>
                    <xsl:otherwise>
                      <gco:CharacterString><xsl:value-of select="$protocol"/></gco:CharacterString>
                    </xsl:otherwise>
                  </xsl:choose>
                </gmd:protocol>

                <!-- gmd:applicationProfile -->
                <xsl:choose>
                  <xsl:when test="geonet:contains-any-of($applicationProfile, ('discovery','view','download','transformation','invoke','other'))">
                    <gmd:applicationProfile>
                      <gmx:Anchor xlink:href="http://inspire.ec.europa.eu/metadata-codelist/SpatialDataServiceType/{$applicationProfile}">
                        {$applicationProfile}
                      </gmx:Anchor>
                    </gmd:applicationProfile>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="gmd:applicationProfile"/>
                  </xsl:otherwise>
                </xsl:choose>

                <xsl:variable name="curName" select="."></xsl:variable>
                <xsl:if test="$curName != ''">
                  <gmd:name>
                    <xsl:choose>

                      <!--Multilingual-->
                      <xsl:when test="contains($curName, '#')">
                        <xsl:for-each select="tokenize($curName, $separator)">
                          <xsl:variable name="nameLang"
                                        select="substring-before(., '#')"></xsl:variable>
                          <xsl:variable name="nameValue"
                                        select="substring-after(., '#')"></xsl:variable>
                          <xsl:if
                            test="$useOnlyPTFreeText = 'false' and $nameLang = $mainLang">
                            <gco:CharacterString>
                              <xsl:value-of select="$nameValue"/>
                            </gco:CharacterString>
                          </xsl:if>
                        </xsl:for-each>

                        <gmd:PT_FreeText>
                          <xsl:for-each select="tokenize($curName, $separator)">
                            <xsl:variable name="nameLang"
                                          select="substring-before(., '#')"></xsl:variable>
                            <xsl:variable name="nameValue"
                                          select="substring-after(., '#')"></xsl:variable>

                            <xsl:if
                              test="$useOnlyPTFreeText = 'true' or $nameLang != $mainLang">
                              <gmd:textGroup>
                                <gmd:LocalisedCharacterString
                                  locale="{concat('#', $nameLang)}">
                                  <xsl:value-of select="$nameValue"/>
                                </gmd:LocalisedCharacterString>
                              </gmd:textGroup>
                            </xsl:if>

                          </xsl:for-each>
                        </gmd:PT_FreeText>
                      </xsl:when>
                      <xsl:otherwise>
                        <gco:CharacterString>
                          <xsl:value-of select="$curName"/>
                        </gco:CharacterString>
                      </xsl:otherwise>
                    </xsl:choose>
                  </gmd:name>
                </xsl:if>

                <xsl:variable name="curDesc" select="tokenize($desc, ',')[position() = $pos]"></xsl:variable>
                <xsl:if test="$curDesc != ''">
                  <gmd:description>
                    <xsl:choose>
                      <xsl:when test="contains($curDesc, '#')">
                        <xsl:for-each select="tokenize($curDesc, $separator)">
                          <xsl:variable name="descLang"
                                        select="substring-before(., '#')"></xsl:variable>
                          <xsl:variable name="descValue"
                                        select="substring-after(., '#')"></xsl:variable>
                          <xsl:if
                            test="$useOnlyPTFreeText = 'false' and $descLang = $mainLang">
                            <gco:CharacterString>
                              <xsl:value-of select="$descValue"/>
                            </gco:CharacterString>
                          </xsl:if>
                        </xsl:for-each>

                        <gmd:PT_FreeText>
                          <xsl:for-each select="tokenize($desc, $separator)">
                            <xsl:variable name="descLang"
                                          select="substring-before(., '#')"></xsl:variable>
                            <xsl:variable name="descValue"
                                          select="substring-after(., '#')"></xsl:variable>
                            <xsl:if
                              test="$useOnlyPTFreeText = 'true' or $descLang != $mainLang">
                              <gmd:textGroup>
                                <gmd:LocalisedCharacterString
                                  locale="{concat('#', $descLang)}">
                                  <xsl:value-of select="$descValue"/>
                                </gmd:LocalisedCharacterString>
                              </gmd:textGroup>
                            </xsl:if>
                          </xsl:for-each>
                        </gmd:PT_FreeText>
                      </xsl:when>
                      <xsl:otherwise>
                        <gco:CharacterString>
                          <xsl:value-of select="$curDesc"/>
                        </gco:CharacterString>
                      </xsl:otherwise>
                    </xsl:choose>
                  </gmd:description>
                </xsl:if>

                <xsl:if test="$function != ''">
                  <gmd:function>
                    <gmd:CI_OnLineFunctionCode
                      codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/codelist/ML_gmxCodelists.xml#CI_OnLineFunctionCode"
                      codeListValue="{$function}"/>
                  </gmd:function>
                </xsl:if>
              </gmd:CI_OnlineResource>
            </gmd:onLine>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <!-- ... the name is simply added in the newly
          created online element. -->
          <gmd:onLine>
            <xsl:if test="$uuidref">
              <xsl:attribute name="uuidref" select="$uuidref"/>
            </xsl:if>
            <gmd:CI_OnlineResource>
              <gmd:linkage>
                <gmd:URL>
                  <xsl:value-of select="$url"/>
                </gmd:URL>
              </gmd:linkage>

              <xsl:if test="$protocol != ''">
                <gmd:protocol>
                  <xsl:variable name="protocolLink" select="$labels/labels/element[@name='gmd:protocol']/helper/option[@value=$protocol]/@id" />

                  <xsl:choose>
                    <xsl:when test="string($protocolLink)">
                      <gmx:Anchor xlink:href="{$protocolLink}">
                        <xsl:value-of select="$protocol"/>
                      </gmx:Anchor>
                    </xsl:when>
                    <xsl:otherwise>
                      <gco:CharacterString><xsl:value-of select="$protocol"/></gco:CharacterString>
                    </xsl:otherwise>
                  </xsl:choose>
                </gmd:protocol>
              </xsl:if>

              <!-- gmd:applicationProfile -->
              <xsl:choose>
                <xsl:when test="geonet:contains-any-of($applicationProfile, ('discovery','view','download','transformation','invoke','other'))">
                  <gmd:applicationProfile>
                    <gmx:Anchor xlink:href="http://inspire.ec.europa.eu/metadata-codelist/SpatialDataServiceType/{$applicationProfile}">
                      {$applicationProfile}
                    </gmx:Anchor>
                  </gmd:applicationProfile>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="gmd:applicationProfile"/>
                </xsl:otherwise>
              </xsl:choose>

              <xsl:if test="$name != ''">
                <gmd:name>
                  <xsl:choose>

                    <!--Multilingual-->
                    <xsl:when test="contains($name, '#')">
                      <xsl:for-each select="tokenize($name, $separator)">
                        <xsl:variable name="nameLang"
                                      select="substring-before(., '#')"></xsl:variable>
                        <xsl:variable name="nameValue"
                                      select="substring-after(., '#')"></xsl:variable>
                        <xsl:if
                          test="$useOnlyPTFreeText = 'false' and $nameLang = $mainLang">
                          <gco:CharacterString>
                            <xsl:value-of select="$nameValue"/>
                          </gco:CharacterString>
                        </xsl:if>
                      </xsl:for-each>

                      <gmd:PT_FreeText>
                        <xsl:for-each select="tokenize($name, $separator)">
                          <xsl:variable name="nameLang"
                                        select="substring-before(., '#')"></xsl:variable>
                          <xsl:variable name="nameValue"
                                        select="substring-after(., '#')"></xsl:variable>

                          <xsl:if
                            test="$useOnlyPTFreeText = 'true' or $nameLang != $mainLang">
                            <gmd:textGroup>
                              <gmd:LocalisedCharacterString
                                locale="{concat('#', $nameLang)}">
                                <xsl:value-of select="$nameValue"/>
                              </gmd:LocalisedCharacterString>
                            </gmd:textGroup>
                          </xsl:if>

                        </xsl:for-each>
                      </gmd:PT_FreeText>
                    </xsl:when>
                    <xsl:otherwise>
                      <gco:CharacterString>
                        <xsl:value-of select="$name"/>
                      </gco:CharacterString>
                    </xsl:otherwise>
                  </xsl:choose>
                </gmd:name>
              </xsl:if>

              <xsl:if test="$desc != ''">
                <gmd:description>
                  <xsl:choose>
                    <xsl:when test="contains($desc, '#')">
                      <xsl:for-each select="tokenize($desc, $separator)">
                        <xsl:variable name="descLang"
                                      select="substring-before(., '#')"></xsl:variable>
                        <xsl:variable name="descValue"
                                      select="substring-after(., '#')"></xsl:variable>
                        <xsl:if
                          test="$useOnlyPTFreeText = 'false' and $descLang = $mainLang">
                          <gco:CharacterString>
                            <xsl:value-of select="$descValue"/>
                          </gco:CharacterString>
                        </xsl:if>
                      </xsl:for-each>

                      <gmd:PT_FreeText>
                        <xsl:for-each select="tokenize($desc, $separator)">
                          <xsl:variable name="descLang"
                                        select="substring-before(., '#')"></xsl:variable>
                          <xsl:variable name="descValue"
                                        select="substring-after(., '#')"></xsl:variable>
                          <xsl:if
                            test="$useOnlyPTFreeText = 'true' or $descLang != $mainLang">
                            <gmd:textGroup>
                              <gmd:LocalisedCharacterString
                                locale="{concat('#', $descLang)}">
                                <xsl:value-of select="$descValue"/>
                              </gmd:LocalisedCharacterString>
                            </gmd:textGroup>
                          </xsl:if>
                        </xsl:for-each>
                      </gmd:PT_FreeText>
                    </xsl:when>
                    <xsl:otherwise>
                      <gco:CharacterString>
                        <xsl:value-of select="$desc"/>
                      </gco:CharacterString>
                    </xsl:otherwise>
                  </xsl:choose>
                </gmd:description>
              </xsl:if>

              <xsl:if test="$function != ''">
                <gmd:function>
                  <gmd:CI_OnLineFunctionCode
                    codeList="http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/codelist/ML_gmxCodelists.xml#CI_OnLineFunctionCode"
                    codeListValue="{$function}"/>
                </gmd:function>
              </xsl:if>
            </gmd:CI_OnlineResource>
          </gmd:onLine>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- Search for any of the searchStrings provided -->
  <xsl:function name="geonet:contains-any-of" as="xs:boolean">
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:param name="searchStrings" as="xs:string*"/>

    <xsl:sequence
      select="
      some $searchString in $searchStrings
      satisfies contains($arg,$searchString)
      "
    />
  </xsl:function>

</xsl:stylesheet>
