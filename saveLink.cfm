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
<cfsilent>

<cffunction name="findAndReplace" returntype="void" output="false">
	<cfargument name="find" type="string" default="" required="true">
	<cfargument name="replace" type="string" default="" required="true">
	<cfargument name="siteID" type="string" default="" required="true">
	<cfargument name="contentHistID" type="string" default="" required="true">

	<cfset bean = application.configBean.getBean('content').loadBy(contentHistID=arguments.contentHistID, siteID=arguments.siteID)>
	<cfset bean.setBody(replaceNoCase(bean.getBody(),"#arguments.find#", "#arguments.replace#", "ALL"))>
	<cfset bean.setSummary(replaceNoCase(bean.getSummary(),"#arguments.find#", "#arguments.replace#", "ALL"))>
	<cfset bean.save()>

</cffunction>

<cffunction name="updateReport" returntype="void" output="false">
	<cfargument name="editorID" type="string" default="" required="true">
	<cfargument name="findMe" type="string" default="" required="true">
	<cfargument name="replaceWith" type="string" default="" required="true">
	<cfset theReport = "">
	<cfset start = 0>
	<cfset end = 0>
	<cfset fileStart = "">
	<cfset fileEnd = "">

	<cffile action="read" file="#expandPath('report.html')#" variable="theReport">
	<cfset start = findNoCase('<dd id="#editorID#">', theReport)>

	<cfif start gt 0>
		<cfset end = findNoCase('</dd>', theReport, start) + 5>
		<cfset fileStart = mid(theReport, 1, start - 1)>
		<cfset fileEnd = mid(theReport, end, len(theReport) - end)>
		<cfset theReport = fileStart & '<dd id="#editorID#">#replaceWith#</dd>' & fileEnd>
		<cffile action="write" file="#expandPath('report.html')#" output="#theReport#" >
	</cfif>
</cffunction>


<cfparam name="form.siteID" default="">
<cfparam name="form.contentHistID" default="">
<cfparam name="form.original_value" default="">
<cfparam name="form.update_value" default="">
<cfparam name="form.editorID" default="">

<cfset findAndReplace(form.original_value, form.update_value, form.siteID, form.contentHistID)>
<cfset updateReport(form.editorID, form.original_value, form.update_value)>

</cfsilent><cfoutput>#form.update_value#</cfoutput>
