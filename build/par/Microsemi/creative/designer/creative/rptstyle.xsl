<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>

<xsl:template match="/">
    <html>
    <head>
     <style>
      body { font-family:arial; font-size:10pt; text-align:left; }
      h1, h2 {
          padding-top: 30px;
      }
      h3 {
          padding-top: 20px;
      }
      h4, h5, h6 {
          padding-top: 10px;
          font-size:12pt;
      }
      table {
          font-family:arial; font-size:10pt; text-align:left;
          border-color:#B0B0B0;
          border-style:solid;
          border-width:1px;
          border-collapse:collapse;
      }
      table th, table td {
          font-family:arial; font-size:10pt; text-align:left;
          border-color:#B0B0B0;
          border-style:solid;
          border-width:1px;
          padding: 4px;
      }
     </style>
    </head>
    <body>
        <xsl:apply-templates/>
    </body></html>
</xsl:template>

<xsl:template match="/doc/title">
    <h1 align="center"> <xsl:apply-templates/> </h1>
</xsl:template>

<xsl:template match="text">
    <p> <xsl:apply-templates/> </p>
</xsl:template>

<xsl:template match="/doc/section">
    <h2> <xsl:apply-templates select="name"/> </h2>
    <xsl:apply-templates select="table|text|list|section"/>
</xsl:template>

<xsl:template match="/doc/section/section">
    <h3> <xsl:apply-templates select="name"/> </h3>
    <xsl:apply-templates select="table|text|list|section"/>
</xsl:template>

<xsl:template match="/doc/section/section/section">
    <h4> <xsl:apply-templates select="name"/> </h4>
    <xsl:apply-templates select="table|text|list|section"/>
</xsl:template>
<xsl:template match="/doc/section/section/section/section">
    <h5> <xsl:apply-templates select="name"/> </h5>
    <xsl:apply-templates select="table|text|list|section"/>
</xsl:template>
<xsl:template match="/doc/section/section/section/section/section">
    <h6> <xsl:apply-templates select="name"/> </h6>
    <xsl:apply-templates select="table|text|list"/>
</xsl:template>

<xsl:template match="section/name">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="table">
    <table cellpadding="4"> <xsl:apply-templates/> </table>
</xsl:template>

<xsl:template match="header">
    <tr> <xsl:apply-templates/> </tr>
</xsl:template>

<xsl:template match="header/cell">
    <th> <xsl:apply-templates/> </th>
</xsl:template>

<xsl:template match="row">
    <tr> <xsl:apply-templates/> </tr>
</xsl:template>

<xsl:template match="row/cell">
    <td> <xsl:apply-templates/> </td>
</xsl:template>

<xsl:template match="list">
    <ul> <xsl:apply-templates/> </ul>
</xsl:template>

<xsl:template match="item">
    <li> <xsl:apply-templates/> </li>
</xsl:template>

</xsl:stylesheet>
