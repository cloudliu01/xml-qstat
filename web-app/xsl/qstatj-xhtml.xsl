<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY  newline "<xsl:text>&#x0a;</xsl:text>">
<!ENTITY  space   "<xsl:text>&#x20;</xsl:text>">
]>
<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="date"
>
<!--
Copyright 2006-2007 Chris Dagdigian (chris@bioteam.net)
Copyright 2009-2011 Mark Olesen

    This file is part of xml-qstat.

    xml-qstat is free software: you can redistribute it and/or modify it under
    the terms of the GNU Affero General Public License as published by the
    Free Software Foundation, either version 3 of the License,
    or (at your option) any later version.

    xml-qstat is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with xml-qstat. If not, see <http://www.gnu.org/licenses/>.

Description
    process XML generated by
        "qstat -xml -j job_identifier_list"
    to produce a list of active and pending jobs
    with their details
    The menuMode only affects the top menu
-->

<!-- ======================= Imports / Includes =========================== -->
<!-- Include exslt templates -->
<xsl:include href="exslt-templates/date.add-duration.function.xsl"/>
<xsl:include href="exslt-templates/date.add.template.xsl"/>
<xsl:include href="exslt-templates/date.duration.template.xsl"/>

<!-- Include our masthead and templates -->
<xsl:include href="xmlqstat-masthead.xsl"/>
<xsl:include href="xmlqstat-templates.xsl"/>
<!-- Include processor-instruction parsing -->
<xsl:include href="pi-param.xsl"/>

<!-- ======================== Passed Parameters =========================== -->
<xsl:param name="clusterName">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'clusterName'"/>
  </xsl:call-template>
</xsl:param>
<xsl:param name="serverName">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'serverName'"/>
  </xsl:call-template>
</xsl:param>
<xsl:param name="timestamp">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'timestamp'"/>
  </xsl:call-template>
</xsl:param>
<xsl:param name="menuMode">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'menuMode'"/>
  </xsl:call-template>
</xsl:param>
<xsl:param name="urlExt">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'urlExt'"/>
  </xsl:call-template>
</xsl:param>


<!-- ======================= Internal Parameters ========================== -->
<!-- configuration parameters -->

<!-- site-specific or generic config -->
<xsl:variable name="config-file">
  <xsl:call-template name="config-file">
    <xsl:with-param  name="dir"   select="'../config/'" />
    <xsl:with-param  name="site"  select="$serverName" />
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="config" select="document($config-file)/config"/>

<xsl:variable
    name="viewfile"
    select="$config/programs/viewfile" />
<xsl:variable
    name="viewlog"
    select="$config/programs/viewlog" />
<xsl:variable
    name="clusterNode"
    select="$config/clusters/cluster[@name=$clusterName]"/>

<!-- possibly append ~{clusterName} to urls -->
<xsl:variable name="clusterSuffix">
  <xsl:if test="$clusterName">~<xsl:value-of select="$clusterName"/></xsl:if>
</xsl:variable>

<xsl:variable name="cgi-params">
  <xsl:call-template name="cgi-params">
    <xsl:with-param name="clusterName"  select="$clusterName"/>
    <xsl:with-param name="config-file"  select="$config-file"/>
  </xsl:call-template>
</xsl:variable>

<!-- our bitmask translations for configuration file -->
<xsl:variable
    name="statusCodes"
    select="document('../config/status-codes.xml')/statusCodes" />


<!-- ======================= Output Declaration =========================== -->
<xsl:output method="xml" indent="yes" version="1.0" encoding="UTF-8"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
/>


<!-- ============================ Matching ================================ -->
<xsl:template match="/">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<link rel="icon" type="image/png" href="css/screen/icons/magnifier_zoom_in.png"/>
&newline;
<title> job details
<xsl:if test="$clusterName"> @<xsl:value-of select="$clusterName"/></xsl:if>
</title>
&newline;
<!-- load css -->
<link href="css/xmlqstat.css" media="screen" rel="Stylesheet" type="text/css" />
</head>
&newline;


<!-- begin body -->
<body>
&newline;<xsl:comment> Main body content </xsl:comment>&newline;

<div id="main">
<!-- Topomost Logo Div -->
<xsl:call-template name="topLogo">
  <xsl:with-param name="config-file" select="$config-file" />
</xsl:call-template>
<!-- Top Menu Bar -->
<xsl:choose>
<xsl:when test="$menuMode = 'qstatf'">
  <xsl:call-template name="qstatfMenu">
    <xsl:with-param name="clusterSuffix" select="$clusterSuffix"/>
    <xsl:with-param name="jobinfo" select="'less'"/>
    <xsl:with-param name="urlExt"  select="$urlExt"/>
  </xsl:call-template>
</xsl:when>
<xsl:otherwise>
  <xsl:call-template name="topMenu">
    <xsl:with-param name="jobinfo" select="'less'"/>
    <xsl:with-param name="urlExt"  select="$urlExt"/>
  </xsl:call-template>
</xsl:otherwise>
</xsl:choose>

&newline;
<xsl:comment> Top dotted line bar (holds the qmaster host and update time) </xsl:comment>
&newline;
<xsl:choose>
<xsl:when test="$clusterNode">
  <div class="dividerBarBelow">
    <!-- cluster/cell name -->
    <xsl:value-of select="$clusterNode/@name"/>
    <xsl:if test="string-length($clusterNode/@cell) and
        $clusterNode/@cell != 'default'">/<xsl:value-of
        select="$clusterNode/@cell"/>
    </xsl:if>
  </div>
</xsl:when>
<xsl:when test="//query/host">
  <!-- fallback to query information -->
  <div class="dividerBarBelow">
    [<xsl:value-of select="//query/host"/>]
    <!-- remove 'T' in dateTime for easier reading -->
    <xsl:value-of select="translate(//query/time, 'T', '_')"/>
  </div>
</xsl:when>
</xsl:choose>

&newline;<xsl:comment> Overview table </xsl:comment>&newline;

<!--
  overview table
-->
<blockquote>
<table class="listing">
  <tr>
    <td>
      <div class="tableCaption">Overview</div>
    </td>
  </tr>
</table>
&newline;
<div id="queueStatusTable">
<table class="listing">
  <tr>
    <th>jobId</th>
    <th>owner</th>
    <th>name</th>
    <th>submitted</th>
    <th>execFile</th>
    <th>group</th>
    <th>state</th>
  </tr>
&newline;
  <!-- 6.1: //detailed_job_info/djob_info/qmaster_response -->
  <!-- running jobs first -->
  <xsl:apply-templates
      select="
        //detailed_job_info/djob_info/element[JB_ja_tasks]
      | //detailed_job_info/djob_info/qmaster_response[JB_ja_tasks]
      "
      mode="overview"
  />
  <!-- pending jobs next -->
  <xsl:apply-templates
      select="
        //detailed_job_info/djob_info/element[not(JB_ja_tasks)]
      | //detailed_job_info/djob_info/qmaster_response[not(JB_ja_tasks)]
      "
      mode="overview"
  />
</table>
</div>
</blockquote>
&newline;

&newline;<xsl:comment> Context table </xsl:comment>&newline;

<!--
  context table
-->
<blockquote>
<table class="listing">
  <tr>
  <td>
    <div class="tableCaption">Context</div>
  </td>
  </tr>
</table>
<div>
&newline;
<table class="listing">
  <th>jobId</th>
  <th>context</th>
  <th>cwd</th>
  <!-- 6.1: //detailed_job_info/djob_info/qmaster_response -->
  <!-- running jobs first -->
  <xsl:apply-templates
      select="
        //detailed_job_info/djob_info/element[JB_ja_tasks]
      | //detailed_job_info/djob_info/qmaster_response[JB_ja_tasks]
      "
      mode="context"
  />
  <!-- pending jobs next -->
  <xsl:apply-templates
      select="
        //detailed_job_info/djob_info/element[not(JB_ja_tasks)]
      | //detailed_job_info/djob_info/qmaster_response[not(JB_ja_tasks)]
      "
      mode="context"
  />
</table>
</div>
</blockquote>
&newline;

<!-- 6.1: //detailed_job_info/djob_info/qmaster_response -->
<!--
  detailed_job_info
  running jobs
-->
<xsl:apply-templates
    select="
      //detailed_job_info/djob_info/element[JB_ja_tasks]
    | //detailed_job_info/djob_info/qmaster_response[JB_ja_tasks]
    "
/>
<!--
  detailed_job_info
  pending jobs
-->
<xsl:apply-templates
    select="
      //detailed_job_info/djob_info/element[not(JB_ja_tasks)]
    | //detailed_job_info/djob_info/qmaster_response[not(JB_ja_tasks)]
    "
/>

&newline;<xsl:comment> Scheduling info </xsl:comment>&newline;

<!--
  scheduling info
-->
<blockquote>
<table class="listing">
  <tr>
    <td>
      <div class="tableCaption">
      <!-- 6.1: //detailed_job_info/messages/qmaster_response -->
        <xsl:value-of
            select="
              count(//detailed_job_info/messages/element/SME_global_message_list/element/MES_message)
            + count(//detailed_job_info/messages/qmaster_response/SME_global_message_list/element/MES_message)
            "
        />
        Scheduling Messages
      </div>
    </td>
  </tr>
</table>
<table class="listing">
  <tr>
    <td>
      <!-- 6.1: //detailed_job_info/messages/qmaster_response -->
      <xsl:apply-templates
          select="
            //detailed_job_info/messages/element/SME_global_message_list
          | //detailed_job_info/messages/qmaster_response/SME_global_message_list
          "
      />
    </td>
  </tr>
</table>
&newline;

<!-- DISABLE FOR NOW

<table class="listing">
<tr>
  <th>share</th>
  <th>fshare</th>
  <th>oticket</th>
  <th>fticket</th>
  <th>sticket</th>
  <th>priority</th>
  <th>ntix</th>
</tr>
  <tr id="priorityJobRow" class="jobDetailRow">
    <td><xsl:value-of select="//JB_ja_template/ulong_sublist/JAT_share"/></td>
    <td><xsl:value-of select="//JB_ja_template/ulong_sublist/JAT_fshare"/></td>
    <td><xsl:value-of select="//JB_ja_template/ulong_sublist/JAT_oticket"/></td>
    <td><xsl:value-of select="//JB_ja_template/ulong_sublist/JAT_fticket"/></td>
    <td><xsl:value-of select="//JB_ja_template/ulong_sublist/JAT_sticket"/></td>
    <td><xsl:value-of select="//JB_ja_template/ulong_sublist/JAT_prio"/></td>
    <td><xsl:value-of select="//JB_ja_template/ulong_sublist/JAT_ntix"/></td>
  </tr>
</table>

-->
</blockquote>
&newline;

<!-- bottom status bar with rendered time -->
<xsl:call-template name="bottomStatusBar">
  <xsl:with-param name="timestamp" select="$timestamp" />
</xsl:call-template>

&newline;
</div>
</body></html>
<!-- end body/html -->
</xsl:template>

<!--
   overview table: contents
   6.1: //djob_info/qmaster_response
-->
<xsl:template
    match="//djob_info/element | //djob_info/qmaster_response"
    mode="overview"
>
  <xsl:variable name="jobs-href">
    <xsl:text>jobs</xsl:text>
    <xsl:if test="$menuMode = 'qstatf'">
      <xsl:value-of select="$clusterSuffix"/>
    </xsl:if>
    <xsl:if test="string-length($urlExt)">
      <xsl:value-of select="$urlExt"/>
    </xsl:if>
    <xsl:text>?user=</xsl:text><xsl:value-of select="JB_owner"/>
  </xsl:variable>

  <tr>
    <!-- jobId with link to details listing -->
    <td>
      <xsl:element name="a">
        <xsl:attribute name="title">details <xsl:value-of select="JB_job_number"/></xsl:attribute>
        <xsl:attribute name="href">#<xsl:value-of select="JB_job_number"/></xsl:attribute>
        <xsl:value-of select="JB_job_number" />
      </xsl:element>
    </td>

    <!-- owner/uid : link owner names to "jobs?user={owner}" -->
    <td>
     <xsl:element name="a">
       <xsl:attribute name="title">uid <xsl:value-of select="JB_uid"/></xsl:attribute>
       <xsl:attribute name="href"><xsl:value-of select="$jobs-href"/></xsl:attribute>
       <xsl:value-of select="JB_owner" />
     </xsl:element>
    </td>

    <!-- job name -->
    <td><xsl:value-of select="JB_job_name" /></td>

    <!-- submitted: convert epoch to dateTime -->
    <td>
      <xsl:apply-templates select="JB_submission_time" />
    </td>

    <!-- Exec file / script -->
    <td>
      <xsl:element name="abbr">
        <xsl:attribute name="title">script=<xsl:value-of select="JB_script_file" /></xsl:attribute>
        <xsl:value-of select="JB_exec_file" />
      </xsl:element>
    </td>

    <!-- POSIX: group / gid -->
    <td>
      <xsl:element name="abbr">
        <xsl:attribute name="title">gid <xsl:value-of select="JB_gid"/></xsl:attribute>
        <xsl:value-of select="JB_group" />
      </xsl:element>
    </td>

    <!-- state: different state XPath for active and pending/held jobs -->
    <td>
      <xsl:choose>
      <xsl:when test="JB_ja_tasks">
        <xsl:call-template name="statusTranslation">
          <xsl:with-param name="status" select="JB_ja_tasks/ulong_sublist/JAT_status" />
        </xsl:call-template>
        <xsl:if test="string-length($viewlog)">
          <xsl:apply-templates select="JB_hard_resource_list" mode="viewlog"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="statusTranslation">
          <xsl:with-param name="status" select="JB_ja_template/ulong_sublist/JAT_state" />
        </xsl:call-template>
      </xsl:otherwise>
      </xsl:choose>
    </td>
  </tr>
&newline;
</xsl:template>


<!--
  context table: contents
  6.1: //djob_info/qmaster_response
-->
<xsl:template
    match="//djob_info/element | //djob_info/qmaster_response"
    mode="context"
>
<tr>
  <td>
    <xsl:element name="a">
      <xsl:attribute name="title">details <xsl:value-of select="JB_job_number"/></xsl:attribute>
      <xsl:attribute name="href">#<xsl:value-of select="JB_job_number"/></xsl:attribute>
      <xsl:value-of select="JB_job_number" />
    </xsl:element>
  </td>
  <td><xsl:apply-templates select="JB_context/context_list"/></td>
  <td><xsl:value-of select="JB_cwd"/></td>
</tr>
&newline;
</xsl:template>

<!--
  details table
  6.1: //djob_info/qmaster_response
-->
<xsl:template match="//djob_info/element | //djob_info/qmaster_response">
<xsl:variable name="jobId" select="JB_job_number"/>

&newline;<xsl:comment> Details table </xsl:comment>&newline;

<blockquote>
<xsl:element name="table">
  <xsl:attribute name="class">listing</xsl:attribute>
  <xsl:attribute name="id"><xsl:value-of select="$jobId"/></xsl:attribute>
  <tr>
    <td>
      <div class="tableCaption">Details for job
        <strong><xsl:value-of select="$jobId"/></strong>
        <xsl:if test="JB_ja_tasks/ulong_sublist/JAT_master_queue">
          master queue
          <strong><xsl:apply-templates
              select="JB_ja_tasks/ulong_sublist/JAT_master_queue"
          /></strong>
        </xsl:if>
      </div>
    </td>
  </tr>
</xsl:element>
<table class="listing fixedTH">
  <tr>
    <th>owner</th>
    <td><xsl:value-of select="JB_owner"/></td>
  </tr>
  <tr>
    <th>script</th>
    <td><xsl:value-of select="JB_script_file"/></td>
  </tr>
  <tr>
    <th>job name</th>
    <td><xsl:value-of select="JB_job_name"/></td>
  </tr>
  <tr>
    <th>cwd</th>
    <td><xsl:value-of select="JB_cwd"/></td>
  </tr>

  <!-- url viewfile?jobid=...&file={stdout} -->
  <tr>
    <th>stdout</th>
    <td>
      <xsl:variable name="PN_path" select="JB_stdout_path_list/path_list/PN_path" />
      <xsl:choose>
      <xsl:when test="string-length($viewfile)">
        <xsl:element name="a">
        <xsl:attribute name="title">view stdout</xsl:attribute>
        <xsl:attribute name="href"><xsl:value-of
            select="$viewfile"/>?jobid=<xsl:value-of
            select="JB_job_number"/>;file=<xsl:choose>
            <xsl:when test='starts-with($PN_path,"/")' >
              <!-- absolute path -->
              <xsl:value-of select="$PN_path"/>
            </xsl:when>
            <xsl:when test='starts-with($PN_path,"$HOME/")' >
              <!-- $HOME/path -->
              <xsl:value-of select="JB_env_list/job_sublist[VA_variable='__SGE_PREFIX__O_HOME']/VA_value" />
              <xsl:value-of select='substring($PN_path, 6)' />
            </xsl:when>
            <xsl:otherwise>
              <!-- relative path -->
            <xsl:value-of select="JB_cwd"/>/<xsl:value-of select="$PN_path"/>
          </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:value-of select="$PN_path"/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$PN_path"/>
      </xsl:otherwise>
      </xsl:choose>
    </td>
  </tr>
  <tr>
    <th>context</th>
    <td><xsl:apply-templates select="JB_context/context_list"/></td>
  </tr>
  <tr>
    <th>job args</th>
    <td><xsl:apply-templates select="JB_job_args"/></td>
  </tr>
  <tr>
    <th>queue request</th>
    <td><xsl:apply-templates select="JB_hard_queue_list"/></td>
  </tr>
  <tr>
    <th>resource request</th>
    <td><xsl:apply-templates select="JB_hard_resource_list/qstat_l_requests"/></td>
  </tr>

  <!-- only for active/running jobs -->
  <xsl:choose>
  <xsl:when test="count(JB_ja_tasks)">
    <xsl:if test="JB_ja_tasks/ulong_sublist/JAT_granted_pe">
      <tr>
        <th>pe granted</th>
        <td>
          <xsl:apply-templates
              select="JB_ja_tasks/ulong_sublist/JAT_granted_pe"
          />
&newline;
          <xsl:value-of
select="sum(JB_ja_tasks/ulong_sublist/JAT_granted_destin_identifier_list/element/JG_slots
or JB_ja_tasks/ulong_sublist/JAT_task_list/element/JG_slots)"/>
        </td>
      </tr>
    </xsl:if>
    <tr>
    </tr>

    <xsl:if test="JB_ja_tasks/ulong_sublist/JAT_granted_destin_identifier_list">
    <tr>
      <th>slot info</th>
      <td>
        <xsl:apply-templates
            select="JB_ja_tasks/ulong_sublist/JAT_granted_destin_identifier_list/element"
        />
      </td>
    </tr>
    </xsl:if>
<!--
    //
    // does not seem terribly useful for us
    //
    <tr>
      <th>tickets</th>
      <td>
        <xsl:apply-templates
            select="JB_ja_tasks/ulong_sublist"
            mode="tickets"/>
      </td>
    </tr>
-->
    <tr>
      <th>task info</th>
      <td>
        task = <xsl:value-of select="JB_ja_tasks/ulong_sublist/JAT_task_number"/>
        <xsl:apply-templates
            select="JB_ja_tasks/ulong_sublist/JAT_granted_destin_identifier_list/element"
            mode="tasks"
        />
      </td>
    </tr>
  </xsl:when>
  <xsl:otherwise>
    <xsl:if test="JB_pe">
      <tr>
        <th>pe requested</th>
        <td>
          <xsl:value-of select="JB_pe"/>
&newline;
          <xsl:value-of select="JB_pe_range/ranges/RN_max"/>
        </td>
      </tr>
    </xsl:if>
    <tr>
      <th>predecessor</th>
      <td>
        <xsl:for-each
            select="JB_jid_predecessor_list/job_predecessors/JRE_job_number"
        >
          <xsl:value-of select="." />
&newline;
        </xsl:for-each>
      </td>
    </tr>
  </xsl:otherwise>
  </xsl:choose>

  <tr>
    <th>posix</th>
    <td>
      uid = <xsl:value-of select="JB_uid"/>
      <br/>
      gid = <xsl:value-of select="JB_gid"/>
      <br/>
      group = <xsl:value-of select="JB_group"/>
    </td>
  </tr>

  <!-- department: seems to be missing in 6.1u3 -->
  <xsl:if test="JB_department">
    <tr>
      <th>department</th>
      <td>
        <xsl:value-of select="JB_department"/>
      </td>
    </tr>
  </xsl:if>

  <!-- project info -->
  <xsl:if test="JB_project">
    <tr>
      <th>project</th>
      <td>
        <xsl:value-of select="JB_project"/>
      </td>
    </tr>
  </xsl:if>

  <!-- path aliases: seems to be missing in 6.1u3 -->
  <xsl:if test="JB_path_aliases">
    <tr>
      <th>path aliases</th>
      <td>
        <xsl:apply-templates select="JB_path_aliases/PathAliases"/>
      </td>
    </tr>
  </xsl:if>

  <!-- job resource usage -->
  <xsl:if test="JB_ja_tasks/ulong_sublist/JAT_usage_list">
    <tr>
      <th>usage</th>
      <td>
        <xsl:apply-templates select="JB_ja_tasks/ulong_sublist/JAT_usage_list/element" />
      </td>
    </tr>
  </xsl:if>

  <!-- scaled job resource usage -->
  <xsl:if test="JB_ja_tasks/ulong_sublist/JAT_scaled_usage_list">
    <tr>
      <th>scaled usage</th>
      <td>
        <xsl:apply-templates select="JB_ja_tasks/ulong_sublist/JAT_scaled_usage_list/scaled"/>
      </td>
    </tr>
  </xsl:if>

<!-- 6.1: /detailed_job_info/messages/qmaster_response -->
  <xsl:if test="
      count(//detailed_job_info/messages/element/SME_message_list/element[MES_job_number_list/element/ULNG = $jobId])
    + count(//detailed_job_info/messages/qmaster_response/SME_message_list/element[MES_job_number_list/element/ULNG = $jobId])
    ">
    <tr>
      <th>
      scheduler messages
      </th>
      <td>
        <xsl:apply-templates
            select="
                //detailed_job_info/messages/element/SME_message_list/element[MES_job_number_list/element/ULNG = $jobId]
              | //detailed_job_info/messages/qmaster_response/SME_message_list/element[MES_job_number_list/element/ULNG = $jobId]
            "
        />
      </td>
    </tr>
  </xsl:if>
</table>
</blockquote>
&newline;
</xsl:template>

<!-- (scaled) usage -->
<xsl:template match="JAT_usage_list/element|JAT_scaled_usage_list/scaled">
  <xsl:value-of select="UA_name"/> = <xsl:value-of select="UA_value"/>
  <br/>
</xsl:template>

<xsl:template match="JB_env_list/job_sublist">
  <xsl:value-of select="VA_variable"/> = <xsl:value-of select="VA_value"/>
  <br/>
</xsl:template>

<!-- path aliases -->
<xsl:template match="JB_path_aliases/PathAliases">
  <xsl:value-of select="PA_origin"/>
&newline;
  <xsl:value-of select="PA_submit_host"/>
&newline;
  <xsl:value-of select="PA_exec_host"/>
&newline;
  <xsl:value-of select="PA_translation"/>
  <br/>
</xsl:template>

<xsl:template
    match="JAT_granted_destin_identifier_list/element |
    JAT_task_list/element/PET_granted_destin_identifier_list/element"
    mode="tasks"
>
  <div class="odd">tag_slave_job = <xsl:value-of select="JG_tag_slave_job"/></div>
  <div class="even">task_id_range = <xsl:value-of select="JG_task_id_range"/></div>
</xsl:template>

<xsl:template match="JAT_granted_destin_identifier_list/element">
  <div class="even">
    <strong><xsl:value-of select="JG_slots"/></strong>
    slots:
    <strong><xsl:apply-templates select="JG_qname"/></strong>
  </div>
</xsl:template>

<!-- extract tickets -->
<xsl:template match="JB_ja_tasks/ulong_sublist" mode="tickets">
  <div class="even">share = <xsl:value-of select="JAT_share" /></div>
  <div class="odd">fshare = <xsl:value-of select="JAT_fshare" /></div>
  <div class="even">ticket = <xsl:value-of select="JAT_tix" /></div>
  <div class="odd">oticket = <xsl:value-of select="JAT_oticket"/></div>
  <div class="even">fticket = <xsl:value-of select="JAT_fticket"/></div>
  <div class="odd">sticket = <xsl:value-of select="JAT_sticket"/></div>
  <div class="even">priority = <xsl:value-of select="JAT_prio"/></div>
  <div class="odd">ntix = <xsl:value-of select="JAT_ntix"/></div>
  <div class="even">overide_tickets = <xsl:value-of select="../../JB_override_tickets"/></div>
</xsl:template>

<xsl:template match="context_list">
  <xsl:value-of select="VA_variable"/>=<xsl:value-of select="VA_value"/><br/>
</xsl:template>

<xsl:template match="JB_job_args">
  <xsl:for-each select="element">
    <xsl:value-of select="./ST_name"/><br/>
  </xsl:for-each>
</xsl:template>


<!-- one of the components of a SGE scheduler message -->
<xsl:template match="MES_message_number">
  <!--
      funky stuff required to determine node position in context
      so we can use our standard mod math to determine even/odd class
      tag names
  -->
  <xsl:variable name="position"
      select="1 + count(parent::*/preceding-sibling::*)"
  />

  <xsl:choose>
  <xsl:when test="$position mod 2 = 1">
   <tr class="schedMesgRow">
     <td><span class="even"><xsl:value-of select="../MES_message"/></span></td>
   </tr>
  </xsl:when>
  <xsl:otherwise>
   <tr class="schedMesgRow">
     <td><span class="odd"><xsl:value-of select="../MES_message"/></span></td>
   </tr>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- do nothing because we output this in the template above -->
<xsl:template match="MES_message" />

<!-- job or global scheduling messages -->
<xsl:template match="SME_message_list/element|SME_global_message_list/element">
  <xsl:for-each select="MES_message">
    <xsl:value-of select="."/>
    <br/>
  </xsl:for-each>
</xsl:template>

<!--
  queue instance
-->
<xsl:template match="JG_qname|JAT_master_queue">
  <xsl:value-of select="substring-before(.,'@')"/>@<xsl:value-of select="substring-before(substring-after(.,'@'),'.')"/>
</xsl:template>

<xsl:template match="JB_hard_queue_list/destin_ident_list">
  <xsl:value-of select="QR_name" />
</xsl:template>

<xsl:template match="JB_hard_resource_list/qstat_l_requests">
  <xsl:value-of select="CE_name"/>=<xsl:value-of select="CE_stringval"/>
  <br/>
</xsl:template>


<!--
  create links for viewlog with plots
-->
<xsl:template match="JB_hard_resource_list" mode="viewlog">
<xsl:if test="count(qstat_l_requests/CE_name)">
  &newline;

  <!-- comma-separated list of resources -->
  <xsl:variable name="resources">
    <xsl:for-each
        select="qstat_l_requests/CE_name"><xsl:value-of
        select="."/>
        <xsl:if test="not(position() = last())">,</xsl:if>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="request">jobid=<xsl:value-of
        select="../JB_job_number"/>;resources=<xsl:value-of
        select="$resources"/>
  </xsl:variable>

  <!-- url viewlog?jobid=...;resources={resources} -->
  <xsl:element name="a">
    <xsl:attribute name="title">viewlog</xsl:attribute>
    <xsl:attribute name="href"><xsl:value-of
        select="$viewlog"/>?<xsl:value-of
        select="$request"/>;<xsl:value-of select="$cgi-params"/></xsl:attribute>
    <img alt="[v]" src="css/screen/icons/page_find.png" border="0" />
  </xsl:element>

  <!-- url viewlog?action=plot;jobid=...;resources={resources} -->
  <xsl:element name="a">
    <xsl:attribute name="title">plotlog</xsl:attribute>
    <xsl:attribute name="href"><xsl:value-of
        select="$viewlog"/>?action=plot;<xsl:value-of
        select="$request"/>;<xsl:value-of select="$cgi-params"/></xsl:attribute>
    <img alt="[p]" src="css/screen/icons/chart_curve.png" border="0" />
  </xsl:element>

  <!-- url viewlog?action=plot;owner=...;resources={resources} -->
  <xsl:element name="a">
    <xsl:attribute name="title">plotlogs</xsl:attribute>
    <xsl:attribute name="href"><xsl:value-of
        select="$viewlog"/>?action=plot;owner=<xsl:value-of
        select="../JB_owner"/>;resources=<xsl:value-of
        select="$resources"/>;<xsl:value-of select="$cgi-params"/></xsl:attribute>
    <img alt="[P]" src="css/screen/icons/chart_curve_add.png" border="0" />
  </xsl:element>
</xsl:if>
</xsl:template>


<!-- these nodes might contain the epoch instead of the proper date/time -->
<xsl:template match="JB_submission_time | JAT_start_time">
  <xsl:choose>
  <xsl:when test="contains(., ':')">
    <xsl:value-of select="."/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="epochToDate">
      <xsl:with-param name="epoch" select="." />
    </xsl:call-template>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- ========================= Named Templates ============================ -->

<!-- convert Unix epoch (seconds since 1970-01-01T00:00:00') to dateTime -->
<xsl:template name="epochToDate">
  <xsl:param name="epoch" />
  <xsl:param name="begin" select="'1970-01-01T00:00:00'" />

  <xsl:variable name="duration">
    <xsl:call-template name="date:duration">
      <xsl:with-param name="seconds" select="$epoch" />
    </xsl:call-template>
  </xsl:variable>
  <xsl:call-template name="date:add">
    <xsl:with-param name="date-time" select="$begin" />
    <xsl:with-param name="duration"  select="$duration" />
  </xsl:call-template>
</xsl:template>


<xsl:template name="statusTranslation">
  <xsl:param name="status" />

  <xsl:element name="abbr">
    <xsl:attribute name="title">
      <!-- this lookup translates JAT_state to something more readable -->
      <xsl:value-of
          select="$statusCodes/status[@bitmask=$status]/long"
      />. The raw JAT_status bitmask code = <xsl:value-of select="$status"/>
    </xsl:attribute>
    <xsl:value-of
        select="$statusCodes/status[@bitmask=$status]/@state"
    />
  </xsl:element>
</xsl:template>


</xsl:stylesheet>

<!-- =========================== End of File ============================== -->
