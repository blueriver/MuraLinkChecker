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
<cfcomponent output="false" extends="mura.cfobject">
	<cffunction name="testLink" access="public" output="no" returntype="boolean">
		<cfargument name="link" required="yes">
		<cfset var tempLink = "">
		<cfset var tempList = "">
		<cfset var i = "">
		<cfset returnVar = false>
		
		<cfif link contains "/#session.siteID#/index.cfm/" or (application.configBean.getStub() neq "" and link contains application.configBean.getStub())>
			<!--- check local links --->
			<cfset tempList = replaceNoCase(link, '/#session.siteID#/index.cfm/', '')>
			<cfif listLen(tempList, '/') gte 1>
				<cfset tempLink = "">
				<cfloop list="#tempList#" delimiters="/" index="i">
					<cfset tempLink = tempLink & i & '/'>
				</cfloop>
				<cfset tempLink = left(tempLink, len(tempLink) - 1)>
				
				<cfquery name="rsCheck" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDBUsername()#" password="#application.configBean.getDBPassword()#">
					select contentID from tcontent 
					where active = 1 and siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#session.siteid#">
					and filename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#tempLink#">
				</cfquery>
				
				<cfif rsCheck.recordCount eq 0>
					<cfset returnVar = true>
				</cfif>
			</cfif>
		<cfelse>
			<!--- check external, image or static links --->
			<cftry>
				<cfif left(link, 4) neq "http">
					<cfset tempLink = "http://" & application.settingsManager.getSite(session.siteID).getDomain() & link>
				<cfelse>
					<cfset tempLink = link>
				</cfif>
				<cfhttp method="head" url="#tempLink#" timeout="1" />
				<cfif findNoCase("404",cfhttp.statusCode) or findNoCase("Connection Failure",cfhttp.statusCode)>
					<cfset returnVar = true>
				</cfif>
				<cfcatch>
					<cfset returnVar = true>
				</cfcatch>
			</cftry>
		</cfif>
		
		<cfreturn returnVar>
	</cffunction>
	
	<cffunction name="parseLink" access="public" output="no" returntype="string">
		<cfargument name="s" required="yes">
		<cfargument name="pos" required="yes">
		<cfset var returnVar = "">
		<cfset var start = 0>
		<cfset var end = 0>
		
		<cfset start = refind("(""|')", arguments.s, arguments.pos) + 1>
		<cfset end = find(mid(arguments.s, start - 1, 1), arguments.s, start)>
		
		<cfset returnVar = mid(arguments.s, start, end - start)>
		
		<cfreturn returnVar>
	</cffunction>
	
	<cffunction name="findLinks" access="public" output="no" returntype="array">
		<cfargument name="find" required="yes">
		<cfargument name="content" required="yes">
		<cfset var pos = 0>
		<cfset var continue = true>
		<cfset var a = arrayNew(1)>
		<cfset var link = "">
		<cfset var matches = reMatchNoCase("(<a.*?>.*?</a>)|(<img.*?>)", arguments.content)>

		<cfloop from="1" to="#arrayLen(matches)#" index="i">
			<cfset pos = 0>
			<cfset continue = true>
			<cfloop condition="#continue#">
				<cfset pos = find(arguments.find, matches[i], pos + 1)>
				<cfif pos gt 0>
					<cfset link = parseLink(matches[i], pos)>
					<cfif testLink(link)>
						<cfset arrayAppend(a, link)>
					</cfif>			
				<cfelse>
					<cfset continue = false>
				</cfif>
			</cfloop>
		</cfloop>	
			
		<cfreturn a>
	</cffunction>
	
	<cffunction name="checkSite" access="public" output="yes" returntype="void">
		<cfquery name="rsContent" datasource="#application.configBean.getDatasource()#" username="#application.configBean.getDBUsername()#" password="#application.configBean.getDBPassword()#">
			select contentID, contentHistID, siteid, parentid, moduleid, type, title, summary, body from tcontent 
			where active = 1 and siteID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#session.siteid#">
			<!---limit 250--->
		</cfquery>
		
		<!---
		<script>
			//document.getElementById('siteCheckStatus').innerHTML = '0% Complete';
			display('element1', 0, 1);
		</script>
		--->

		<cfset brokenLinkCount = 0>
		<cfset list = arrayNew(1)>
		<cfloop query="rsContent">
			<cfset s = structNew()>
			<cfset s.links = arrayNew(1)>
			<cfset s.imgs = arrayNew(1)>
			<cfset s.contentID = contentID>
			<cfset s.contentHistID = contentHistID>
			<cfset s.siteid = siteid>
			<cfset s.type = type>
			<cfset s.parentid = parentid>
			<cfset s.moduleid = moduleid>
			<cfset s.title = title>
	
			<cfset s.links = findLinks('href', summary & body)>
			<cfset s.imgs = findLinks('src', summary & body)>
			
			<cfif arrayLen(s.links) gt 0 or arrayLen(s.imgs) gt 0>
				<cfset arrayAppend(list, s)>
				<cfset brokenLinkCount = brokenLinkCount + arrayLen(s.links) + arrayLen(s.imgs)>
			</cfif>
			<cfif rsContent.currentRow mod 5 eq 0>
				<script>
					//document.getElementById('siteCheckStatus').innerHTML = '<cfoutput>#(rsContent.currentRow / rsContent.recordCount) * 100#</cfoutput>% Complete';
					fillProgress('element1', <cfoutput>#(rsContent.currentRow / rsContent.recordCount) * 100#</cfoutput>);
				</script>
			</cfif>
		</cfloop>

		<cfsavecontent variable="body">
			<cfoutput>
			<div id="linkChecker">
				<h3>Your site has <strong>#brokenLinkCount#</strong> broken link<cfif brokenLinkCount neq 1>s</cfif> on <strong>#arrayLen(list)#</strong> page<cfif arrayLen(list) neq 1>s</cfif>:</h3>
				<dl id="lc-nodeList">
				<cfloop from="1" to="#arrayLen(list)#" index="i">
					<dt class="divide"><a href="/admin/index.cfm?fuseaction=cArch.edit&siteid=#list[i].siteid#&contentid=#list[i].contentid#&topid=00000000000000000000000000000000001&type=#list[i].type#&parentid=#list[i].parentID#&moduleid=#list[i].moduleID#">#list[i].title#</a></dt>
					<cfloop from="1" to="#arrayLen(list[i].links)#" index="j">
						<cfset id = createUUID()>
						<dd id="#id#">#list[i].links[j]#</dd>
						<script type="text/javascript">
							new Ajax.InPlaceEditor('#id#', 'saveLink.cfm', {
								callback: function(form, value) { return 'siteid=#list[i].siteid#&contentHistID=#list[i].contenthistid#&findMe=#urlEncodedFormat(list[i].links[j])#&replaceWith=' + encodeURIComponent(value) }
							});
						</script>
					</cfloop>
					<cfloop from="1" to="#arrayLen(list[i].imgs)#" index="k">
						<cfset id = createUUID()>
						<dd id="#id#">#list[i].imgs[k]#</dd>
						<script type="text/javascript">
							new Ajax.InPlaceEditor('#id#', 'saveLink.cfm', {
								callback: function(form, value) { return 'siteid=#list[i].siteid#&contentHistID=#list[i].contenthistid#&findMe=#urlEncodedFormat(list[i].imgs[k])#&replaceWith=' + encodeURIComponent(value) }
							});
						</script>
					</cfloop>
				</cfloop>
				</dl>
			</cfoutput>
		</div>
		</cfsavecontent>
		
		<cfif arrayLen(list) eq 0>
			<cfset body = '<p class="success">No broken links found.</p>'>
		</cfif>
	
		<cffile action="write" file="#expandPath('report.html')#" output="#body#">
		
		<script>
			window.location = 'index.cfm?gfa=show';
		</script>
	
	</cffunction>
	
</cfcomponent>