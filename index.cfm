<!---
   Copyright 2011 Blue River Interactive

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
--->
<cfinclude template="plugin/config.cfm">
<cfset myRequest = structNew()>
<cfset structAppend(myRequest, url)>
<cfset structAppend(myRequest, form)>
<cfset event = createObject("component", "mura.event").init(myRequest)>

<cfset oLC = createObject("component", "linkCheck")>

<cfif event.getValue('gfa') eq "">
	<cfset event.setValue('gfa', 'show')>
</cfif>

<cfsavecontent variable="header">
	<cfoutput>
		<link href="css/style.css" rel="stylesheet" type="text/css" media="screen" />
		<script language="javascript" type="text/javascript" src="js/progress.js"></script>
		<script language="javascript" type="text/javascript" src="js/scriptaculous.js"></script>
		<h2>#pluginConfig.getName()#</h2>
	</cfoutput>
</cfsavecontent>

<cfset body = "">

<cfswitch expression="#event.getValue('gfa')#">
	<cfcase value="show">
		<cfset header = header & '<ul id="navTask"><li><a href="?gfa=check">Check for broken links</a></li></ul>'>
		<cfif fileExists(expandPath('report.html'))>
			<cfsavecontent variable="body">
				<cfinclude template="report.html">
			</cfsavecontent>
		</cfif>
		<cfoutput>#application.pluginManager.renderAdminTemplate(body=header & body, pageTitle=pluginConfig.getName())#</cfoutput>
	</cfcase>
	<cfcase value="check">
		<cfset body = "<script>display('element1', 0, 1);</script>">
		<cfoutput>#application.pluginManager.renderAdminTemplate(body=header & body, pageTitle=pluginConfig.getName())#</cfoutput>
		<cfflush interval="1">
		<cfset oLC.checkSite()>
	</cfcase>
</cfswitch>