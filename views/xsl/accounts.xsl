<!--
Program: http://www.regdel.com
Component: accounts.xsl
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
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" omit-xml-declaration="yes" />
<xsl:template match="/">
<div class="block">
  <div class="hd">
  <h2>
    <span id="i18n-accounts">Accounts</span>
  </h2>
  </div>
  <div class="bd">
<table class="accounts tablesorter">
<thead>
<tr>
<th><span class="i18n i18n-account_name">Account Name</span></th>
<th><span class="i18n i18n-account_balance">Account Balance</span></th>
<th><span class="i18n i18n-account_type">Account Type</span></th>
</tr>
</thead>
<tbody>
<xsl:apply-templates />
</tbody>
</table>
</div>
</div>
</xsl:template>

<xsl:template match="//account">
<tr id="{@id}">
  <td class="editacc" style="padding:0">
    <a href="/account/edit/{@id}" style="display:none;float:right;padding:5px;">
    <img src="/s/img/pkgs/docunext-webapp-icons/eclipse/write_obj.gif" alt=""/>
    </a>
    <a href="/account/edit/{@id}" style="padding:5px;display:block;" title="Edit">
      <xsl:value-of select="@name"/>
    </a>
  </td>
  <td>
  <xsl:value-of select="@balance"/>
  </td>
  <td>
  <xsl:value-of select="@type"/>
  </td>
</tr>
</xsl:template>

</xsl:stylesheet>
