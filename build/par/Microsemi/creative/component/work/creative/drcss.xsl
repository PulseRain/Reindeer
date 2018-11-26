<?xml version="1.0" encoding="iso-8859-1" ?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template match="/">
      <head>
        <xsl:call-template name="css"/>
      </head>
      <body>
        <p>
        <div class="header">DRC Report: <xsl:value-of select="drcreport/header" /></div>
        </p>
        <table  class="drctable"  align="left"  border="1" width="75%" cellspacing="0" cellpadding="4">
          <tr>
            <th>Status</th>
            <th>Message</th>
            <th>Details</th>
          </tr>
          
          <xsl:for-each select="drcreport/drc">
            <tr>
              <td style="padding-left:20px"> <img width="16" height="16"> 
                      <xsl:attribute name="src"> <xsl:value-of select="status"/> </xsl:attribute> 
                      <xsl:attribute name="alt"> <xsl:value-of select="StatusMessage"/> </xsl:attribute>  
                      <xsl:attribute name="title"> <xsl:value-of select="StatusMessage"/> </xsl:attribute>  
                    </img>
              </td>
              <td> <a> <xsl:attribute name="href"> <xsl:value-of select="crossprobe"/> </xsl:attribute> <xsl:value-of select="message" /></a></td>
              <td> <xsl:value-of select="detail" /></td>
            </tr>
           </xsl:for-each>
        </table> 
      </body>
    </xsl:template>
    
    <xsl:template name="css">
    <style>

        body 
        { 
          font-family:arial; 
          font-size: 11pt; 
          text-align:center; 
        } 
        div.header 
        { 
          padding-top: 7px; 
          padding-bottom: 7px; 
          color:#003399; 
          background-color: #D0D0D0; 
          width=100%; 
          font-family:arial; 
          font-size:14pt; 
          font-weight: bold; 
          text-align: center; 
        } 
        table.drctable 
        { 
          border-color: #B0B0B0; 
          border-style:solid; 
          border-width:1px; 
          border-spacing:0px; 
          border-collapse:collapse; 
          width=75%; 
          font-family:couriernew; 
          font-size: 11pt; 
        }
        table.drctable th 
        { 
          background-color: #F0F0F0; 
          border-color: #B0B0B0; 
          border-width:1px; 
          color: darkslategray; 
          font-weight:bold; 
        } 
        table.drctable td 
        { 
          text-align:left; 
        }        

    </style>

    <!--============================= END CSS ===================================-->
  </xsl:template>

</xsl:stylesheet>
