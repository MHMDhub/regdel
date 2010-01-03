<!--
Program: http://www.regdel.com
Component: account_model_to_xhtml_form.xsl
Copyright: Savonix Corporation
Author: Albert L. Lash, IV
License: Gnu Affero Public License version 3
http://www.gnu.org/licenses

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program; if not, see http://www.gnu.org/licenses
or write to the Free Software Foundation, Inc., 51 Franklin Street,
Fifth Floor, Boston, MA 02110-1301 USA
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>
<xsl:output method="xml" omit-xml-declaration="yes" indent="yes"/>
<xsl:template match="/">
<div>
<div class="block">
  <div class="hd">
  <h2>
    <span class="i18n-account_form">Account Form</span>
  </h2>
  </div>
  <div class="bd">
    <form method="post" id="account-form" action="{$account_submit}">
    <div id="account_form_notice" class="hidden_div" />
    <div class="form-meta-controls">
      <input type="button" value="Hide" />
      <input type="button" value="Delete" />
    </div>
    <fieldset>
    <legend>Account Details</legend>
    <ul class="biglist">
<xsl:for-each select="//table[name='accounts']/declaration/field[@access='public']">
<li>
    <label for="{@name}">
      <span class="i18n-{@i18n}"><xsl:value-of select="@label"/></span>
    </label>
    <xsl:apply-templates select="."/>
</li>
</xsl:for-each>
  </ul>
  </fieldset>
  <div class="form-controls">
    <input type="submit" value="Save" name="submit"/>
    <input type="button" value="Cancel" />
  </div>
  </form>
  </div>
</div>
</div>
</xsl:template>

<xsl:template match="field[@type='string']">
  <input type="text" name="{@name}" id="{@name}" />
</xsl:template>
<xsl:template match="field[@type='text']">
  <textarea name="{@name}" id="{@name}"></textarea>
</xsl:template>
<xsl:template match="field[@type='boolean']">
  <input type="checkbox" name="{@name}" id="{@name}" />
</xsl:template>
<xsl:template match="field[@type='integer']">
  <select name="{@name}" id="{@name}" >
  </select>
</xsl:template>

<xsl:template match="text()">
</xsl:template>
</xsl:stylesheet>
