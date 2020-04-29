package ct
{
	import agf.Main;
	import agf.Options;
	import agf.tools.*;
	import agf.icons.IconLoading;
	import agf.ui.*;
	import agf.events.*;
	import agf.html.*;
	import agf.db.*;
	import agf.io.*;
	import agf.db.DBResult;
	import agf.utils.StringMath;
	import com.airhttp.FileController;
	import com.airhttp.HttpServer;
	import ct.ctrl.InputTextBox;
	import ct.ctrl.CommandEditor;
	import com.adobe.crypto.*;
	import com.airhttp.*;
	import flash.display.*;
	import flash.events.*;
	import flash.filesystem.*;
	import flash.net.*;
	import flash.text.*;
	import flash.text.*;
	import flash.desktop.*;
	import flash.utils.*;

	/**
	* Core functions to:
	* - install templates
	* - open and save projects
	* - create and load the database
	* - admin passwaord
	* - helper functions
	*/
	public class CTTools extends BaseTool
	{
		public static var showCompact:Boolean = false;
		public static var showTemplate:Boolean = false;
		public static var showOutput:Boolean=false;
		public static var currArea:String="";
		
		public static var activeTemplate:Template; // root template
		public static var subTemplates:Vector.<Template>;
		public static var procFiles:Array;  // ProjectFiles
		
		public static var currFile:int=-1;
		public static var projectDir:String = "";
		public static var currentArea:String;
		private static var dbiXml:XML;
		private static var _tgt:InteractiveObject;
		public static var db:DBAL;
		private static var sqlExec:Boolean = false;
		private static var sqlQuerys:Array;
		private static var currQuery:int;
		private static var sqlHandler:Function;
		private static var internSubTempl:Template;
		private static var internSubTemplLoadComplete:Function;
		private static var internSubTemplCreateComplete:Function;
		
		public static var pages:Array;
		public static var pageTable:Object;
		
		public static var articlePages:Array;	// Page
		public static var articlePageTable:Object;
		
		public static var pageItems:Array;
		public static var pageItemTable:Object;
		public static var articleProcFiles:Array; // ProjectFile
		
		private static var internSubTemplData:Array;
		private static var internCurrSubTempl:int=0;
		private static var internPageItemData:Array;
		private static var internCurrPageItem:int=0;
		private static var internDBCreateCmds:XMLList;
		private static var internCurrDBCreate:int;
		
		private static var internPageItem:Object;
		private static var saveAsFirst:Boolean=true;
		public static var saveDirty:Boolean = true;
		
		public static var templateConstants:Object;
		
		// Load sqlite DB
		public static function loadDB ( file:String, dbtype:Class ) :void {
			db = new DBAL();
			db.useDB( file, dbtype );
		}
		
		public static function fillTemplate (pf:ProjectFile) :void
		{
			var sr:Array = pf.templateStruct;
			var a:Area;
			var areas:Vector.<Area> = pf.templateAreas;
			var txt:String = sr[0];
			var j:int;
			var L2:int = pageItems.length;
			var pgitems:Array;
			var currarea:String;
			var pftmp:ProjectFile = new ProjectFile("tmp");
			var T:Template;
			var pftxt:ProjectFile;
			var areatxt:String;
			var filepath:String;
			var tmpdbprops:Object;
			var L:int = sr.length;
			
			var offset:int;
			var limit:int;
			var itemCount:int;
			var itc:int;
			
			pageItems.sortOn("sortid", Array.NUMERIC);
			
			for( var i:int = 1; i < L; i++ )
			{
				a = areas[i-1];
				
				if( a.link != "" )
				{
					currarea = a.link;
				}
				else
				{
					currarea = a.name;
					
					if( currarea == "SCRIPT-BEGIN" ) {
						txt += scriptBeginEmbeds;
						txt += sr[i];
						continue;
					}else if( currarea == "SCRIPT-END" ) {
						txt += scriptEndEmbeds;
						txt += sr[i];
						continue;
					}else if( currarea == "STYLE-BEGIN" ) {
						txt += styleBeginEmbeds;
						txt += sr[i];
						continue;
					}else if( currarea == "STYLE-END" ) {
						txt += styleEndEmbeds;
						txt += sr[i];
						continue;
					}
					
				}
				
				areatxt = "";
				offset = a.offset;
				limit = a.limit;
				itemCount = 0;
				itc = 0;
				pgitems = [];
				
				for( j=0; j<L2; j++)
				{
					if(pageItems[j].area == currarea && pageItems[j].visible != false )
					{
						if( offset > 0 && itc < offset ) {
							itc++;
						}else{
							itemCount = pgitems.push( pageItems[j] );
							if( limit > 0 && itemCount >= limit ) {
								break; 
							}
						}
					}
				}
				
				// pageItems already sorted by prio.. 
				// pgitems.sortOn( "sortid", Array.NUMERIC );
				
				if( offset < -1 )
				{
					offset++;
					if( -offset < pgitems.length ) {
						pgitems.splice( 0, -offset );
					}else{
						// large negative offset cuts all out
						pgitems = [];
					}
				}
				if( limit < -1 )
				{
					limit++;
					if( -limit < pgitems.length ) {
						pgitems.splice( pgitems.length + limit, -limit );
					}else{
						// large negative limit cuts all out
						pgitems = [];
					}
				}
				var tmplFolder:String = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator;
				var stName:String;
				
				for(j=0; j < pgitems.length; j++)
				{
					stName = pgitems[j].subtemplate;
					if( a.link != "" )
					{
						// swap sub template in link areas
						if( a.linkOverrides && a.linkOverrides[ stName ] != undefined ) {
							stName = a.linkOverrides[ stName ];
						}
					}
					
					T = findTemplate( stName, "name" );
					
					if( T )
					{
						filepath = tmplFolder + T.name + CTOptions.urlSeparator + T.indexFile;
						pftxt = ProjectFile( CTTools.procFiles[ CTTools.projFileBy(filepath, "path") ]);
						
						if( pftxt )
						{
							tmpdbprops = T.dbProps;
							T.dbProps = pgitems[j];
							pftmp.setUrl( pftxt.path );
							pftmp.templateId = T.name;
							pftmp.setTemplate( pftxt.template, pgitems[j].name );
							
							if( CTOptions.insertItemLocation && !T.nolocation ) { // Insert Anker Tags
								areatxt += CTOptions.insertItemPre + T.dbProps.name + CTOptions.insertItemPost;
							}
							areatxt += pftmp.getText();
							T.dbProps = tmpdbprops;
						}else{
							Console.log("Template File " + filepath + " Not Found");
						}
					}
				}
				
				txt += areatxt;
				txt += sr[i];
			}
			pf.setText(txt);
		}
		
		public static var scriptEmbedLookup:Object;
		public static var scriptBeginEmbeds:String = "";
		public static var scriptEndEmbeds:String = "";
		public static var scriptObjectEmbeds:Object;
		
		public static var styleEmbedLookup:Object;
		public static var styleBeginEmbeds:String = "";
		public static var styleEndEmbeds:String = "";
		public static var styleObjectEmbeds:Object;
		
		// collect script and style embeds from all subtemplates
		public static function collectEmbeds () :void
		{
			scriptEmbedLookup = {};
			scriptBeginEmbeds = "";
			scriptEndEmbeds = "";
			scriptObjectEmbeds = {};
			
			styleEmbedLookup = {};
			styleBeginEmbeds = "";
			styleEndEmbeds = "";
			styleObjectEmbeds = {};
			
			var scripts:Array = [];
			var styles:Array = [];
			
			var T:Template;
			var pth:String;
			var j:int;
			var L2:int;
			var ef:EmbedFile;
			var txt:String;
			var nm:String;
			var i:int;
			var L:int;
			
			if( subTemplates && subTemplates.length > 0 )
			{
				L = subTemplates.length;
				
				for( i = 0; i < L; i++ )
				{
					T = subTemplates[i];
					
					if( T.jsfiles )
					{
						L2 = T.jsfiles.length;
						
						for( j = 0; j < L2; j++ )
						{
							ef = T.jsfiles[j];
							
							if ( typeof( scriptEmbedLookup[ ef.name ] ) != "undefined" ) continue;
							scriptEmbedLookup[ ef.name ] = ef.src;
							 
							pth = ef.src;
							
							pth = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + T.name + CTOptions.urlSeparator + pth;
							txt = readTextFile(pth);
							
							if( txt ) {
								scripts.push( { name:ef.name, value: txt, priority:ef.priority, area:ef.area } );
							}
						}
					}
					
					if( T.cssfiles )
					{
						L2 = T.cssfiles.length;
						
						for( j = 0; j < L2; j++ )
						{
							ef = T.cssfiles[j];
							
							if ( typeof( scriptEmbedLookup[ ef.name ] ) != "undefined" ) continue;
							scriptEmbedLookup[ ef.name ] = ef.src;
							
							pth = ef.src;
							
							pth = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + T.name + CTOptions.urlSeparator + pth;
							txt = readTextFile(pth);
							
							if( txt ) {
								scripts.push( { name:ef.name, value: txt, priority:ef.priority, area:ef.area } );
							}
						}
					}
				}
				
				//scripts.sortOn("area");
				scripts.sortOn("priority", Array.NUMERIC);
				
				L = scripts.length;
				
				for(i = 0; i < L; i++) {
					nm = scripts[i].area.toLowerCase();
					if( nm == "script-begin" ) {
						scriptBeginEmbeds += scripts[i].value;
					}else if( nm == "script-end" ) {
						scriptEndEmbeds += scripts[i].value;
					}else if( nm.substring(0,14) == "script-object-" ) {
						j = parseInt( nm.substring(15) );
						scriptObjectEmbeds["_" + j] = scripts[i].value;
					}else if( nm == "style-begin" ) {
						styleBeginEmbeds += scripts[i].value;
					}else if( nm == "style-end" ) {
						styleEndEmbeds += scripts[i].value;
					}else if( nm.substring(0,14) == "style-object-" ) {
						j = parseInt( nm.substring(15) );
						styleObjectEmbeds["_" + j] = scripts[i].value;
					}
				}
				
			}
			
		}
		private static function delTblHandler (res:DBResult) :void {
			loadSubTemplate( reloadSubTPath, reloadSubTCompleteHandler);
		}
		
		private static var reloadSubTPath:String;
		private static var reloadSubTCompleteHandler:Function;
		
		// load a sub template 
		public static function loadSubTemplate (path:String, completeHandler:Function=null) :void
		{
			if( projectDir )
			{
				var slst:int = path.lastIndexOf( CTOptions.urlSeparator );
				var nam:String = path;
				if( slst >= 0 ) nam = path.substring( slst + 1 );
				
				var st:Template = findTemplate( nam, "name");
				
				if( st == null ) {
					st = new Template("sub");
					subTemplates.push( st );
					
					if( CTTools.internDBCreateCmds && CTOptions.debugOutput ) Console.log("Load Subtemplate " + nam );
				
				}else{
					if(saveAsFirst) {
						// reload and delete sql tables from subtemplate
						if( st.tables != "" ) {
							reloadSubTPath = path;
							reloadSubTCompleteHandler = completeHandler;
							var stid:int = CTTools.subTemplates.indexOf(st);
							if( stid >= 0 ) {
								CTTools.subTemplates.splice(stid, 1);
							}
							var dv:Boolean = db.query( delTblHandler, "DROP TABLE " + st.tables, {});
							if(!dv) loadSubTemplate( reloadSubTPath, reloadSubTCompleteHandler);
							if( CTTools.internDBCreateCmds && CTOptions.debugOutput ) Console.log("Clear Subtemplate " + nam );
						}
					}else{
						if( CTTools.internDBCreateCmds && CTOptions.debugOutput ) Console.log("Subtemplate '" + nam  + "' already loaded" );
						if( completeHandler != null ) completeHandler();
					}
					return;
				}
				 
				st.name = nam;
				internSubTemplLoadComplete = completeHandler;
				
				// Load subtemplate index file
				var tistr:String = readTextFile( path + CTOptions.urlSeparator + CTOptions.templateIndexFile );
				if( tistr ) {
					var txo:XML = new XML( tistr );
					if( txo.template ) {
						st.indexStr = tistr;
						loadSubTmplByIndexFile(st, txo, path);
					}else{
						tistr = "";
					}
				}
				if( !tistr ) Console.log("TEMPLATE-ERROR No Template Index File Found: '"+ CTOptions.templateIndexFile +"' Missing In " + path);
				
				internSubTempl = st;
				var pm:Object = {};
				pm[":name"] = st.name;
				var sql:String = 'SELECT uid,name FROM template WHERE name=:name;';
				var rv:Boolean = db.query( onSubTmplSelect, sql, pm );
				if(!rv) onSubTmplSelect(null);
			}
		}
		
		private static function onSubTmplSelect ( res:DBResult ):void {
			// --> loadDBHandler 1
			if(res && res.data && res.data.length > 0) {
				var T:Template = findTemplate( res.data[0].name, "name" );
				if( T ) {
					T.sqlUid = res.data[0].uid;
					if( internSubTemplLoadComplete != null ) internSubTemplLoadComplete();
				}
			}else{
				if( internSubTempl )
				{
					// copy config files to project dir
					if( internSubTempl.indexStr != null ) {
						// write template index file to subtemplate dir
						if(!writeTextFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + CTOptions.templateIndexFile ,
										internSubTempl.indexStr ) ) {
											Console.log("Error: Subtemplate index file write error " + internSubTempl.name );
										}
					}else{
						Console.log("Error: Subtemplate index file error " + internSubTempl.name );
					}
					
					// copy help file to subtemplate project dir 
					if( internSubTempl.help && internSubTempl.help != "" ) {
						if(!copyFile(  internSubTempl.genericPath + CTOptions.urlSeparator + internSubTempl.help, 
									projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + internSubTempl.help) ) {
										Console.log("Error: Subtemplate help file copy error " + internSubTempl.help );
									}
					}
					var i:int;
					var L:int;
					var pth:String;
					
					// copy embedscripts:
					if( internSubTempl.jsfiles ) {
						L = internSubTempl.jsfiles.length;
						if( L > 0 )
						{
							for(i=0; i<L; i++)
							{
								pth = internSubTempl.jsfiles[i].src;
								
								if(!copyFile( internSubTempl.genericPath + CTOptions.urlSeparator + pth, 
									projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + pth)) {
										Console.log("Error: Subtemplate embed js file copy error " + internSubTempl.name + ": " + pth );
									}
							}
							
						}
					}
					// copy embedstyles
					if( internSubTempl.cssfiles ) {
						L = internSubTempl.cssfiles.length;
						if( L > 0 )
						{
							for(i=0; i<L; i++)
							{
								pth = internSubTempl.cssfiles[i].src;
								
								if(!copyFile( internSubTempl.genericPath + CTOptions.urlSeparator + pth, 
									projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + pth)) {
										Console.log("Error: Subtemplate embed css file copy error " + internSubTempl.name + ": " + pth );
									}
							}
						}
					}
					if( internSubTempl.articlepage ) {
						if(!copyFile( internSubTempl.genericPath + CTOptions.urlSeparator +  internSubTempl.articlepage, 
							projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + 
							internSubTempl.name + CTOptions.urlSeparator + internSubTempl.articlepage )) {
								Console.log("Error: Subtemplate article page copy error " + internSubTempl.name + ": " + internSubTempl.articlepage );
							}
					}
					
					// Insert sub template into db:
					var pm:Object = {};
					pm[":name"] = internSubTempl.name;
					pm[":indexfile"] = internSubTempl.indexFile;
					var rv:Boolean = db.insertQuery( onInsertSubTmpl, "template", "name,indexfile", ":name,:indexfile", pm );
					if(!rv) Console.log( "DB-CREATE-ERROR: INSERT Subtemplate Error");
				}
			}
			collectEmbeds();
		}
		private static function onInsertSubTmpl ( res:DBResult ):void {
			if( res ) {
				// New Subtemplate has been inserted in the database..
				if( internSubTempl )
				{
					internSubTempl.sqlUid = res.lastInsertRowID;
					
					var xo:XML = new XML( internSubTempl.indexStr );
					var sql:String;
					
					if( xo.template.@initquery && xo.template.@initquery.toString() != "" )
					{
						// Run SQL file from config.xml initquery (with CREATE TABLE)
						sql = readTextFile( internSubTempl.genericPath + CTOptions.urlSeparator + xo.template.@initquery.toString() );
						
						if( sql ) {
							sql = TemplateTools.replaceNewlines( sql );
							
							if( !writeTextFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + xo.template.@initquery.toString(),
												sql )) 
							{
								
								Console.log("Error: Subtemplate initquery write error " + xo.template.@initquery.toString() );
								
							}else{
								execSql(sql, onInsertSubTQuery);
								return;
							}
						}
					}else{
						
						if( xo.template.@fields && xo.template.@fields != ""  )
						{
							// build db-create (initquery)
							var tbl:String = "ex_"+internSubTempl.name.toLowerCase();
							var flds:Array = xo.template.@fields.toString().split(",");
							
							if(  xo.template.@tables && xo.template.@tables != "" ) tbl = xo.template.@tables.toString();
							
							sql = "CREATE TABLE IF NOT EXISTS " + tbl + " (\nuid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n";
							
							if( flds.indexOf( "name" ) == -1 ) {
								flds.splice(0,0,"name");
							}
							
							var L:int = flds.length-1;
							for( var i:int=0; i<L; i++) {
								sql += flds[i]+" TEXT,\n";
							}
							
							sql += flds[flds.length-1] + " TEXT\n);";
							
							execSql(sql, onInsertSubTQuery);
							return;
						}
					}
				
					
				}
			}
			onInsertSubTQuery( null );
		}
		
		public static var installDefaultContent:Boolean=true;
		
		private static function onInsertSubTQuery ( res:DBResult ):void {
			
			if( internSubTempl && installDefaultContent )
			{
				// Sub template tables have just been created..
				
				var xo:XML = new XML( internSubTempl.indexStr );
				
				if( xo.template.@defaultquery != undefined && xo.template.@defaultquery != "" )
				{
					// Run SQL file with default content (with INSERT)
					var sql:String = readTextFile( internSubTempl.genericPath + CTOptions.urlSeparator + xo.template.@defaultquery);
					
					if( sql )
					{
						sql = TemplateTools.replaceNewlines( sql );
						
						if( !writeTextFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + xo.template.@defaultquery.toString(),
											sql )) 
						{
							Console.log("Error: Subtemplate defaultquery write error " + xo.template.@defaultquery.toString() );
						}else{
							execSql(sql, onInsertSubTQuery2);
							return;
						}
					}
				}
			}
			
			onInsertSubTQuery2( null );
		}
		
		private static function onInsertSubTQuery2 ( res:DBResult ):void {
			if(internSubTemplLoadComplete != null) internSubTemplLoadComplete();
		}
		
		public static function loadSubTmplByIndexFile (tmpl:Template, txo:XML, path:String) :void {
			tmpl.genericPath = path;
			if( txo != null && txo.template != null) {
				if( txo.template.@name != undefined  && txo.template.@name != "") tmpl.name = txo.template.@name.toString();
				if( txo.template.@type != undefined  && txo.template.@type != "") tmpl.type = txo.template.@type.toString();
				if( txo.template.@sortproperties != undefined  && txo.template.@sortproperties != "") tmpl.sortproperties = txo.template.@sortproperties.toString();
				if( txo.template.@help != undefined  && txo.template.@help != "") {
					tmpl.help = txo.template.@help.toString();
					// load Help file:
					if( internDBCreateCmds && CTOptions.debugOutput) Console.log("Load Help File: " +  path + CTOptions.urlSeparator + tmpl.help); // Log while installing
					
					loadHelpFile( path + CTOptions.urlSeparator + tmpl.help, tmpl.name );
				}
				if( txo.template.@dbcmds != undefined  && txo.template.@dbcmds != "") tmpl.dbcmds = txo.template.@dbcmds.toString();
				
				if( txo.template.@tables != undefined  && txo.template.@tables != "") tmpl.tables = txo.template.@tables.toString();
				if( txo.template.@fields != undefined  && txo.template.@fields != "") tmpl.fields = txo.template.@fields.toString();
				if( txo.template.@articlepage != undefined  && txo.template.@articlepage != "") tmpl.articlepage = txo.template.@articlepage.toString();
				if( txo.template.@articlename != undefined  && txo.template.@articlename != "") tmpl.articlename = txo.template.@articlename.toString();
				if( txo.template.@staticfiles != undefined  && txo.template.@staticfiles != "") tmpl.staticfiles = txo.template.@staticfiles.toString();
				if( txo.template.@folders != undefined && txo.template.@folders != "" ) tmpl.folders = txo.template.@folders.toString();
				if( txo.template.@templatefolders != undefined  && txo.template.@templatefolders != "") tmpl.templatefolders = txo.template.@templatefolders.toString();
				if( txo.template.@parselistlabel != undefined  && txo.template.@parselistlabel != "") tmpl.parselistlabel = CssUtils.stringToBool( txo.template.@parselistlabel.toString() );
				if( txo.template.@listlabel != undefined  && txo.template.@listlabel != "") tmpl.listlabel = txo.template.@listlabel.toString();
				if( txo.template.@listicon != undefined  && txo.template.@listicon != "") tmpl.listicon = txo.template.@listicon.toString();
				if( txo.template.@nolocation != undefined  && txo.template.@nolocation != "") tmpl.nolocation = CssUtils.stringToBool( txo.template.@nolocation.toString() );
				if( txo.template.@hidden != undefined && txo.template.@hidden != "") tmpl.hidden = CssUtils.stringToBool( txo.template.@hidden.toString() );
				
				if( txo.template.@index != undefined && txo.template.@index != "")
				{
					tmpl.indexFile = txo.template.@index.toString();
					addFile( path + CTOptions.urlSeparator + tmpl.indexFile, tmpl );
				}
				
				var L:int;
				var i:int;
				
				if( txo.template.@files != undefined  && txo.template.@files != "" )
				{
					tmpl.files = txo.template.@files.toString();
					var filenames:Array = tmpl.files.split(",");
					
					if( tmpl.indexFile == "" && filenames.length > 0 ) {
						tmpl.indexFile = filenames[0];
					}
					L = filenames.length;
					for(i=0; i<L; i++) {
						if( filenames[i] && filenames[i] != " " ) {
							addFile( path + CTOptions.urlSeparator + filenames[i], tmpl );
						}
					}
				}
				
				var scr:XMLList = txo.template.embedscript;
				var jf:Vector.<EmbedFile>;
				var ef:EmbedFile;
				var nm:String;
				
				if( scr )
				{
					tmpl.jsfiles = new Vector.<EmbedFile>();
					jf = tmpl.jsfiles;
					L = scr.length();
				
					// <embedscript name="a-name" src="afile.js" area="SCRIPT-BEGIN" priority="100"/>
					for(i = 0; i < L; i++)
					{
						nm = scr[i].@name.toString();
						ef = new EmbedFile( nm, scr[i].@src.toString(), scr[i].@area.toString() );
						if( scr[i].@priority != undefined && scr[i].@priority != "") ef.priority = parseInt(scr[i].@priority.toString());
						tmpl.jsfiles.push( ef );
					}
				}
				
				scr = txo.template.embedstyle;
				if( scr )	
				{
					tmpl.cssfiles = new Vector.<EmbedFile>();
					jf = tmpl.cssfiles;
					L = scr.length();
					
					// <embedstyle name="a-name" src="afile.css" area="STYLE-BEGIN" priority="100"/>
					for(i = 0; i < L; i++)
					{
						nm = scr[i].@name.toString();
						ef = new EmbedFile( nm, scr[i].@src.toString(), scr[i].@area.toString() );
						if( scr[i].@priority != undefined && scr[i].@priority != "") ef.priority = parseInt(scr[i].@priority.toString());
						tmpl.cssfiles.push( ef );
					}
				}
				
			}
		}
		
		public static function loadHelpFile (path:String, store:String="") :void {
			if( path ) {
				try {
					var hlp:String = readTextFile( path );
					var xo:XML = new XML( hlp );
					if( xo ) {
						Language.addXmlKeywords( xo.item, store );
					}
				}catch (e:Error) {
					Console.log("Error Load Help File '"+path+"' : " + e);
				}
			}
		}
		
		private static var installProgress:Progress;
		
		  ///////////////////////////////////
		 // load new default root template 
		///////////////////////////////////
		
		public static function loadTemplate () :void
		{			
			var main:Main = Main(Application.instance);
			
			if( CTOptions.isMobile ) {
				loadTemplate2(true);
			}else{
				main.window.InfoWindow("SaveFirstInfo", Language.getKeyword("Information"), Language.getKeyword("CT-SaveFirst-MSG"), { complete: loadTemplate2, allowCancel: true, cancelLabel:Language.getKeyword("Cancel"), continueLabel:Language.getKeyword("CT-SaveFirst-BTN"), autoHeight:true}, '');
			}
		}
		
		private static var loadTemplate__FolderName:String;
		
		public static function loadTemplate2 (bool:Boolean) :void {
			if (bool && loadTemplate__FolderName)
			{
				clearFiles ();
				displayFiles();
				
				saveAsFirst = true;
				saveDirty = true;
				showTemplate = true;
				
				if( !CTOptions.verboseMode ) {
					try {
						var iv:InstallView = InstallView( Application.instance.view.panel.src );
						installProgress = iv.progress;
					}catch(e:Error) {
						Application.instance.cmd( "Application view InstallView" );
						installProgress = InstallView( Application.instance.view.panel.src ).progress;
					}
				}
				var folder_name:String = loadTemplate__FolderName;
				var pth:String = folder_name;
				var file:File;
				var fileok:Boolean=false;
				
				try {
					file = new File( pth );
					if(file.exists) {
						fileok = true;
					}
				}catch( e:Error) {
					Console.log("File Error : " + e.message + ", " + pth);
				}
				if(!fileok) {
					pth = File.applicationDirectory.url + CTOptions.urlSeparator + folder_name;
				}
				
				var path:String = pth;
				
				activeTemplate = new Template("root");
				activeTemplate.genericPath = path;
				
				// Load template index file
				var tistr:String = readTextFile( path + CTOptions.urlSeparator + CTOptions.templateIndexFile );
				
				if( tistr ) {
					var txo:XML = new XML( tistr );
					if( txo.template ) {
						activeTemplate.indexStr = tistr; 
						loadTmplByIndexFile(txo, path);
					}else{
						tistr = "";
					}
				}
				
				if ( !tistr )
				{
					Console.log("TEMPLATE-ERROR No Template Index File Found: '" + CTOptions.templateIndexFile +"'  In: " + path);
					Application.instance.window.InfoWindow( "TmplLoadError", Language.getKeyword("Error"), Language.getKeyword("Template-Load-Error"), { allowCancel: false, autoHeight:true}, '' );
				}
				else
				{
				
					saveFirstHandler(true);
				}
			}
		}
		
		public static function compareVersions ( oldVersion:String, newVersion:String ) :String {
			var currVersion:Array = oldVersion.split(".");
			var version:Array = newVersion.split(".");
			var updateType:String = "none";
			
			if( currVersion.length == 0 ) return updateType;
			currVersion[0] = parseInt(currVersion[0]);
			if( currVersion.length > 1 ) currVersion[1] = parseInt(currVersion[1]);
			if( currVersion.length > 2 ) currVersion[2] = parseInt(currVersion[2]);
			
			if( version.length == 0 ) return updateType;
			version[0] = parseInt(version[0]);
			if( version.length > 1 ) version[1] = parseInt(version[1]);
			if( version.length > 2 ) version[2] = parseInt(version[2]);
			
			if( version[0] > currVersion[0] )
			{
				// mayor update...
				updateType = "Major";
			}
			else if( version[0] == currVersion[0] ) {
				if( version[1] > currVersion[1] ) {
					// minor update
					updateType = "Minor";
				}else if( version[1] == currVersion[1] ) {
					if( version[2] > currVersion[2] ) {
						// developer update
						updateType = "Patch";
					}
				}
			}
			return updateType;
		}
		
		public static function loadTmplByIndexFile (txo:XML, path:String) :void {
			if(activeTemplate)
			{
				if( txo.template.@name != undefined && txo.template.@name != "") activeTemplate.name = txo.template.@name.toString();
				if( txo.template.@version != undefined && txo.template.@version != "") activeTemplate.version = txo.template.@version.toString();
				
				var i:int;
				var L:int;
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				
				if ( sh && sh.data )
				{
					var latestVersion:String = activeTemplate.version;
					var latestId:int=-1;
					var found:int=-1;
					
					if( !sh.data.templates) {
						sh.data.templates = [];
					}
					else
					{
						if( CTOptions.cacheDownloads ) {
							// search for templates name and compare version
							L = sh.data.templates.length;
							var updateType:String;
							
							for( i=0; i<L; i++)
							{
								if( sh.data.templates[i].name == activeTemplate.name )
								{
									if( sh.data.templates[i].version == activeTemplate.version ) {
										found = i;
									}
									// test version
									updateType = compareVersions( latestVersion, sh.data.templates[i].version );
									
									if( updateType != "none" )
									{
										// found template with higher version
										latestVersion = sh.data.templates[i].version;
										latestId = i;
									}
								}
							}
						}
					}
					
					if( latestId >= 0 ) {
						if(CTOptions.debugOutput) Console.log("Found higher version in local template store " + latestVersion );
						// Install latest installed template
						loadTemplate__FolderName = sh.data.templates[latestId].path;
						loadTemplate2(true);
						return ;
					}
				}
				
				if( txo.template.@type != undefined && txo.template.@type != "" ) activeTemplate.type = txo.template.@type.toString();
				if( txo.template.@help != undefined && txo.template.@help != "") {
					activeTemplate.help = txo.template.@help.toString();
					// load Help file:
					loadHelpFile( path + CTOptions.urlSeparator + activeTemplate.help, activeTemplate.name );
				}
				if( txo.template.@sortareas  != undefined && txo.template.@sortareas != "") {
					activeTemplate.sortareas = txo.template.@sortareas.toString();
				}
				if( txo.template.@sortproperties != undefined && txo.template.@sortproperties != "") activeTemplate.sortproperties = txo.template.@sortproperties.toString();
				if( txo.template.@dbcmds != undefined && txo.template.@dbcmds != "") activeTemplate.dbcmds = txo.template.@dbcmds.toString();
				if( txo.template.@homeAreaName != undefined && txo.template.@homeAreaName != "") activeTemplate.homeAreaName = txo.template.@homeAreaName.toString();
				if( txo.template.@nocompress != undefined && txo.template.@nocompress != "") activeTemplate.nocompress = txo.template.@nocompress.toString();
				if( txo.template.@nolocareas != undefined && txo.template.@nolocareas != "") activeTemplate.nolocareas = txo.template.@nolocareas.toString();
				if( txo.template.@hiddenareas != undefined && txo.template.@hiddenareas != "") activeTemplate.hiddenareas = txo.template.@hiddenareas.toString();
				
				if( txo.template.@update != undefined && txo.template.@update != "") activeTemplate.update = txo.template.@update.toString();
				if( txo.template.@pagetemplates != undefined && txo.template.@pagetemplates != "") activeTemplate.pagetemplates = txo.template.@pagetemplates.toString();
				if( txo.template.@folders != undefined && txo.template.@folders != "") activeTemplate.folders = txo.template.@folders.toString();
				if( txo.template.@templatefolders != undefined && txo.template.@templatefolders != "") activeTemplate.templatefolders = txo.template.@templatefolders.toString();
				if( txo.template.@staticfiles != undefined  && txo.template.@staticfiles != "" ) activeTemplate.staticfiles = txo.template.@staticfiles.toString();
				if( txo.template.@listlabel != undefined  && txo.template.@listlabel != "") activeTemplate.listlabel = txo.template.@listlabel.toString();
				if( txo.template.@listicon != undefined  && txo.template.@listicon != "") activeTemplate.listicon = txo.template.@listicon.toString();
				if( txo.template.@index != undefined  && txo.template.@index != "") {
					activeTemplate.indexFile = txo.template.@index.toString();
					addFile( path + CTOptions.urlSeparator + activeTemplate.indexFile );
				}
				if( txo.template.@files != undefined  && txo.template.@files != "") {
					activeTemplate.files = txo.template.@files.toString();
					var filenames:Array = activeTemplate.files.split(",");
					L = filenames.length;
					for(i=0; i<L; i++) {
						if( filenames[i] ) {
							addFile( path + CTOptions.urlSeparator + filenames[i] );
						}
					}
				}
			}
		}
		
		private static function saveFirstHandler (ok:Boolean=true) :void {
			if (ok)
			{
				// ask for project dir to install template 
				if( CTOptions.isMobile )
				{
					if( CTOptions.mobileProjectFolderName != "ask" )
					{
					    var fi:File = CTOptions.mobileParentFolder.resolvePath( CTOptions.mobileProjectFolderName );
						projectDir = fi.url;
					}
					else
					{
						var ish:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
						
						if( ish && ish.data && ish.data.installTemplates && instObjId >= 0 && ish.data.installTemplates.length > instObjId ) {
							projectDir = ish.data.installTemplates[ instObjId ].prjDir;
							
						}
					}
					
					save();
				}
				else
				{
					saveAs();
				}
			}
		}
		
		//on save if db is empty (just created with initsql..)
		private static function createDBHandler ( res:DBResult ):void {
			// Insert active template into db...
			if( activeTemplate ) {
				var pm:Object = {};
				pm[":name"] = activeTemplate.name;
				if(! db.selectQuery( onActiveTmplDBCreate, "uid,name", "template", "name=:name", "", "", "", pm) ) {
					Console.log("DB-SELECT-ERROR: Can not select Root Template");
					Application.instance.hideLoading();
					if(installProgress) installProgress.value = 1;
					if( CTOptions.verboseMode ) Application.instance.cmd("Console show console");
				}else{
					if(installProgress) installProgress.value = 0.6;
				}
			}else{
				Console.log("DB-CREATE-ERROR: No Root Template");
				Application.instance.hideLoading();
				if(installProgress) installProgress.value = 1;
				if( CTOptions.verboseMode ) Application.instance.cmd("Console show console");
			}
		}
		private static function onActiveTmplDBCreate ( res:DBResult ):void {
			// --> loadDBHandler 1
			
			if(res && res.data && res.data.length > 0) {
				activeTemplate.sqlUid = res.data[0].uid;
				if(CTOptions.debugOutput) Console.log("Selected Active Template: " + activeTemplate.sqlUid );
				
			}else{
				var pm:Object = {};
				// Insert active template in db...
				pm[":name"] = activeTemplate.name;
				pm[":indexfile"] = activeTemplate.indexFile;
				saveAsFirst = true;
				if(!db.insertQuery( onInsertTmplDBCreate, "template", "name,indexfile", ":name,:indexfile", pm ) ) {
					Console.log( "DB-CREATE-ERROR: INSERT active-template error");
					Application.instance.hideLoading();
				}
			}
		}
		
		// NEW DB JUST CREATED..
		private static function onInsertTmplDBCreate ( res:DBResult ):void {
			if(res && res.rowsAffected > 0) {
				activeTemplate.sqlUid = res.lastInsertRowID;
				if(saveAsFirst) {
					
					if( installProgress ) installProgress.value = .5;
					if(CTOptions.debugOutput || CTOptions.verboseMode) Console.log( "Generic path :" +  activeTemplate.genericPath);
					
					var src:File;
					var dst:File;
					var sourceFile:FileReference;
					var destination:FileReference;
					var folders:Array;
					var L:int;
					var i:int;
					
					// Copy Template Files to project folder
					if( activeTemplate.folders ) {
						folders = activeTemplate.folders.split(",");
						L = folders.length;
						if(CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Files " + L + ":" + folders);
						for(i=0; i<L; i++) {
							src = new File( activeTemplate.genericPath + CTOptions.urlSeparator + folders[i] );
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + folders[i] );
							destination = dst;
							if(CTOptions.debugOutput) Console.log("Copy : " + folders[i] + ", " + src + ", " + destination);
							src.copyTo(destination, true)
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + folders[i] );
							destination = dst;
							src.copyTo(destination, true);
						}
					}
					
					// Copy Template folders to project folder
					if( activeTemplate.templatefolders ) {
						folders = activeTemplate.templatefolders.split(",");
						L=folders.length;
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Folders " + L + ":" + folders);
						for(i=0; i<L; i++) {
							src = new File( activeTemplate.genericPath + CTOptions.urlSeparator + folders[i] );
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + folders[i] );
							destination = dst;    
							src.copyTo(destination, true)
						}
					}
					// Copy Page templates to project folder
					if( activeTemplate.pagetemplates ) {
						folders = activeTemplate.pagetemplates.split(",");
						L=folders.length;
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Page Templates " + L + ":" + folders);
						for(i=0; i<L; i++) {
							src = new File( activeTemplate.genericPath + CTOptions.urlSeparator + folders[i] );
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + folders[i] );
							destination = dst;    
							src.copyTo(destination, true)
						}
					}
					if( activeTemplate.staticfiles ) {
						folders = activeTemplate.staticfiles.split(",");
						L=folders.length;
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Static Files " + L + ":" + folders);
						for(i=0; i<L; i++) {
							src = new File( activeTemplate.genericPath + CTOptions.urlSeparator + folders[i] );
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + folders[i] );
							destination = dst;
							src.copyTo(destination, true)
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + folders[i] );
							destination = dst;
							src.copyTo(destination, true);
						}
					}
					
					if( activeTemplate.help ) {
						// Copy help.xml
						if(CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Help File " +  activeTemplate.help);
						src = new File( activeTemplate.genericPath + CTOptions.urlSeparator + activeTemplate.help );
						dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + activeTemplate.help );
						destination = dst;
						src.copyTo(destination, true);
					}
					
					if(installProgress) installProgress.value = 0.7;
					saveAsFirst = false;
					saveDirty = false;
					
					// Run DB-CREATE COMMANDS
					internDBCreateCmds = null;
					
					if( activeTemplate.dbcmds ) {
						var s:String = readTextFile( activeTemplate.genericPath + CTOptions.urlSeparator + activeTemplate.dbcmds );
						
						if( s ) {
							// Write dbcmds to template project dir
							if( !writeTextFile(projectDir + CTOptions.urlSeparator+CTOptions.projectFolderTemplate+CTOptions.urlSeparator + activeTemplate.dbcmds, s) ) {
								Console.log( "Error: Write Template dbcmds: " + activeTemplate.dbcmds );
							}
							
							// Execute cmds
							try {
								var x:XML = new XML(s);
							}catch(e:Error) {
								Console.log("Error: Parse command file: " + s);
							}
							if(x) {
								if( x.dbcreate ) {
									var xm:XMLList = x.dbcreate.cmd;
									internDBCreateCmds = xm;
									internCurrDBCreate = 0;
								}
							}else{
								Console.log("Error: Parse command file: " + s);
							}
						}
					}
					
					if( installProgress ) installProgress.value = .7;
					openAfterDBCreate();
				}
			}
		}
		
		private static var runCmd:XMLList; // info by runCommandLists[ xml-node-name ] = { curr, xmllist, complete, etc }
		private static var _runCmdCurr:int=0;
		private static var _runCmdComplete:Function;
		
		private static function runNextCommand ():void
		{
			if ( !runCmd || _runCmdCurr > runCmd.length() ) {
				if(typeof( _runCmdComplete) == "function") _runCmdComplete();
				// All DBCommands processed
				runCmd = null;
				return;
			}
			if( runCmd[ _runCmdCurr] ) {
				var cd:String = runCmd[_runCmdCurr].@name;
				if(cd) {
					var ap:Main = Main ( Application.instance );
					_runCmdCurr++;
					ap.cmd( cd, runNextCommand );
					return;
				}
			}
			_runCmdCurr++;
			runNextCommand();
		}
		
		public static function runCommandList (nam:String="xml-node-name", complete:Function=null, xo:XML=null) :void
		{
			if( xo == null && activeTemplate.dbcmds ) {
				var s:String = readTextFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + activeTemplate.dbcmds);
				if(s) {
					
					try {
						var xo:XML = new XML(s);
					}catch(e:Error) {
						Console.log("Error: Parse command file: " + e);
					}
				}
			}
			if(xo) {
				if( xo[nam] ) {
					runCmd =  xo[nam].cmd;
					_runCmdCurr = 0;
					_runCmdComplete = complete;
					runNextCommand( );
				}
			}else{
				Console.log("No Commands found at node-name: " + nam  + ", xml: " + xo);
				if(typeof(complete)=="function") complete();
			}		
		}
		
		private static function runNextDBCreateCmd () :void
		{
			if ( !internDBCreateCmds || internCurrDBCreate > internDBCreateCmds.length() )
			{
				// All DBCommands processed
				internDBCreateCmds = null;
				
				if( installProgress ) installProgress.value = .75;
				
				Application.instance.hideLoading();
				
				if( CTOptions.overrideInstallDB != "" )
				{
					var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
					
					// TODO: bugfix with new subtemplates missing in old DB.. 
					// requires merge databases or compare subtemplates
					
					if( CTOptions.debugOutput ) Console.log("OVERRIDE DONE: SH-ID: " +CTOptions.localSharedObjectId  + ", value: " +  sh.data.overrideDBDone + ", " + CTOptions.overrideInstallDB );
					if( sh && sh.data && sh.data.overrideDBDone != true ) {
						save( showRestartMsg );
						return;
					}
				}
				
				save();
				Application.instance.addEventListener ( AppEvent.START, firstSave);
				Application.instance.cmd( "Application restart");
				return;
			}
			
			if( internDBCreateCmds[internCurrDBCreate] ) {
				var cd:String = internDBCreateCmds[ internCurrDBCreate ].@name.toString();
				if(cd) {
					var ap:Main = Main ( Application.instance );
					internCurrDBCreate++;
					
					ap.cmd( cd, runNextDBCreateCmd );
					return;
				}
			}
			internCurrDBCreate++;
			runNextDBCreateCmd();
		}
		
		private static function firstSave (e:AppEvent) :void
		{
			Application.instance.removeEventListener ( AppEvent.START, firstSave);
			saveDirty = true;
			setTimeout( saveLater, 950 );
		}
		
		private static function saveLater ():void {
			invalidateTemplateFiles( activeTemplate, true );
			
			save();
			
			try {
				Application.instance.view.panel.src["displayFiles"]();
			}catch(e:Error) {
				
			}
		}
		
		private static function openAfterDBCreate () :void
		{
			// Hide app-config from styleSheet
			Application.instance.config.media = "all";
			
			if(installProgress) installProgress.value = 1;
			
			var prj:String = projectDir;
			clearFiles();
			projectDir = prj;
			open();
		}
		
		// on open project
		private static function loadDBHandler ( res:SQLEvent ):void {
			// 1 load properties and sql-uid for active template
			var pm:Object = {};
			pm[":name"] = activeTemplate.name;
			var sql:String = 'SELECT uid,name FROM template WHERE name=:name;';
			if(!db.query( onActiveTmplDBLoad, sql, pm )) {
				Console.log( "DB-ERROR: SELECT active Template failed");
			}
		}
		
		private static function onActiveTmplDBLoad ( res:DBResult ):void {
			// --> loadDBHandler 1
			var pm:Object = {};
			if(res && res.data && res.data.length > 0) {
				activeTemplate.sqlUid = res.data[0]['uid'];
				// Load Root Template Properties
				pm[":tmplid"] = activeTemplate.sqlUid;
				var sql:String = 'SELECT uid,name,section,type,value,templateid FROM tmplprop WHERE templateid=:tmplid;';
				if(!db.query( onActiveTmplPropsDBLoad, sql, pm )) {
					Console.log( "DB-ERROR: SELECT ON active-template properties failed");
				}
			}else{
				// Insert active template in db...
				pm[":name"] = activeTemplate.name;
				pm[":indexfile"] = activeTemplate.indexFile;
				if(! db.insertQuery( onInsertTmplDBLoad, "template", "name,indexfile", ":name,:indexfile", pm ) ) {
					Console.log( "DB-ERROR: INSERT active-template error");
				}
			}
		}
		private static function onInsertTmplDBLoad ( res:DBResult ):void {
			if(res) {
				if( res.rowsAffected > 0 ) {
					// Active template inserted...
					activeTemplate.sqlUid = res.lastInsertRowID;
					var pm:Object = {};
					pm[":tmplid"] = activeTemplate.sqlUid;
					var sql:String = 'SELECT uid,name,section,type,value,templateid FROM tmplprop WHERE templateid=:tmplid;';
					var rv:Boolean = db.query( onActiveTmplPropsDBLoad, sql, pm );
					if( !rv) Console.log( "DB-ERROR: SELECT ON active-template properties failed");
				}
			}
		}
		private static function onActiveTmplPropsDBLoad ( res:DBResult ):void {
			// --> loadDBHandler 1
			if(res && res.data && res.data.length > 0) {
				var L:int = res.data.length;
				var sec:String;
				var nm:String;
				
				for(var i:int=0; i<L; i++) 
				{
					nm = res.data[i].name;
					sec = res.data[i].section;
					
					activeTemplate.dbProps[nm] = { name:nm, type:res.data[i].type, value:res.data[i].value, section:"" };
					
					if( sec != "" ) {
						activeTemplate.dbProps[sec + "." + nm] = { name:nm, type:res.data[i].type, value:res.data[i].value, section:sec};
					}
				}
			}
			// Load pages
			var sql:String = 'SELECT uid,name,visible,parent,webdir,title,type,template,filename,crdate FROM page;';
			var rv:Boolean = db.query( onPagesDBLoad, sql, null );
			if( !rv) Console.log( "DB-ERROR: SELECT ON pages failed");
		}
		private static function onPagesDBLoad ( res:DBResult ):void
		{	
			if( res && res.data && res.data.length > 0 )
			{
				pages = [];
				pageTable = {};
				
				// articlePages = [];
				// articlePageTable = {};
				
				var L:int = res.data.length;
				var n:String;
				var tp:String;
				var newFile:String;
				var prjFile:ProjectFile;
				var tmp:String;
				
				for(var i:int=0; i<L; i++)
				{
					n = res.data[i].name;
					
					tp = res.data[i].type.toLowerCase();
					
					if( tp == "article" ) {
						if( articlePageTable[ n ] != null) continue;
						articlePageTable[ n ] = new Page(n, res.data[i].uid, res.data[i].type, res.data[i].title, res.data[i].template, res.data[i].crdate, true, res.data[i].parent, res.data[i].webdir, res.data[i].filename  );
						articlePages.push( articlePageTable[ n ] );
						loadArticlePage( articlePageTable[ n ], res.data[i].parent );
						
						/*
						// parse file to know areas
						if ( !articlePageTable[ n ].webdir ) {
							newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + articlePageTable[ n ].filename;
						}else{
							newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + articlePageTable[ n ].webdir + CTOptions.urlSeparator + articlePageTable[ n ].filename;
						}
						prjFile = findArticleProjectFile( newFile, "path" );
						
						if ( prjFile ) {
							prjFile.allDirty();
							CTTools.saveArticleFile( prjFile, articlePageTable[ n ].webdir );
						}
						*/
						//
						
					}else{
						if( pageTable[ n ] != null) continue;
						
						pageTable[ n ] = new Page(n, res.data[i].uid, res.data[i].type, res.data[i].title, res.data[i].template, res.data[i].crdate, true, res.data[i].parent, res.data[i].webdir, res.data[i].filename  );
						pages.push( pageTable[ n ] );
						loadPage( pageTable[ n ] );
					}
				}
			}
			// load subtemplates
			var sql:String = 'SELECT uid,name,indexfile FROM template;';
			var rv:Boolean = db.query( onSubtemplatesDBLoad, sql, null );
			if( !rv) Console.log( "DB-ERROR: SELECT ON active-template properties failed");
		}
		private static function onSubtemplatesDBLoad ( res:DBResult ):void {
			if(res && res.data && res.data.length > 1) {
				internSubTemplData = res.data;
				internCurrSubTempl = 0;
				loadNextSubTemplate();
			}else{ // continue;
				// no subtemplates ..
				loadPageItems();
			}
		}
		
		private static function loadNextSubTemplate () :void {
			if( internCurrSubTempl >= internSubTemplData.length) {
				internSubTemplData = null;
				loadPageItems();
				return;
			}
			if( internSubTemplData[internCurrSubTempl].name != activeTemplate.name ) {
				CTTools.loadSubTemplate( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTemplData[internCurrSubTempl].name, onLoadNextSubTemplate);
				internCurrSubTempl++;
				return;
			}
			internCurrSubTempl++;
			loadNextSubTemplate();
			return;
		}
		
		private static function onLoadNextSubTemplate () :void {
			// Load DB PRoperties for subtemplate
			var pms:Object = {};
			pms[":nam"] = internSubTempl.sqlUid;
			var rv:Boolean = db.selectQuery(onLoadSubTemplProps, "uid,name,section,type,value,templateid", "tmplprop", "templateid=:nam","","","",pms);
			if(!rv) loadNextSubTemplate();
		}
		
		private static function onLoadSubTemplProps (res:DBResult) :void {
			if(res && res.data && res.data.length > 0) {
				var L:int = res.data.length;
				var sec:String;
				var nm:String;
				
				for(var i:int=0; i<L; i++)
				{
					nm = res.data[i].name;
					sec = res.data[i].section;
					
					internSubTempl.dbProps[nm] = { name:nm, type: res.data[i].type, value:res.data[i].value, section: sec};
						
					if( sec != "" ) {
						internSubTempl.dbProps[sec + "." + nm] =  {name:nm, type: res.data[i].type, value:res.data[i].value, section:sec};
					}
				}
			}
			loadNextSubTemplate()
		}
		private static function loadPageItems () :void
		{
			// load page items and parse subtemplate to area-code
			var sql:String = 'SELECT uid,name,visible,area,sortid,subtemplate,crdate FROM pageitem;';
			var rv:Boolean = db.query( onPageItemsLoaded, sql, null );
			if(!rv) Console.log( "DB-ERROR: SELECT ON page items failed");
		}
		
		private static function onPageItemsLoaded (res:DBResult) :void {
			if( res && res.data && res.data.length > 0 )
			{
				internPageItemData = res.data;
				internCurrPageItem = 0;
				loadNextPageItem();
			}
			else
			{
				// No Page Items...
				onloadComplete();
			}
		}
		
		private static function loadNextPageItem () :void {
			if( internCurrPageItem >= internPageItemData.length) {
				internPageItemData = null;
				internCurrPageItem = 0;
				CTTools.onloadComplete();
				return;
			}
			
			var r:Object = internPageItemData[internCurrPageItem];
			internPageItem = r;
			
			if( CTTools.pageItemTable[ r.name ] ) {
				// Page item already available
				internCurrPageItem++;
				loadNextPageItem();
				return;
			}
			
			var piobj:Object = {};
			CTTools.cloneTo( r, piobj );
			
			if( piobj.visible ) piobj.visible = CssUtils.stringToBool( piobj.visible );
			piobj.inputname = piobj.name;
			
			CTTools.pageItemTable[ r.name ] = piobj;
			CTTools.pageItems.push( piobj );
			
			// Parse page item with subtemplate and db-properties...
			// Select T.fields FROM T.tables..
			// parse with new tmp-ProjectFile for subtemplate and dbProps
			var T:Template = CTTools.findTemplate( r.subtemplate, "name" );
			
			if(T && T.tables ) {
				// Select subtemplate db data
				var pms:Object={};
				pms[":nam"] = r.name;
				var rv:Boolean = CTTools.db.selectQuery( onPageItem, "uid," + T.fields, T.tables, 'name=:nam', '', '', '', pms);
				if(!rv) {
					internCurrPageItem++;
					Console.log("DB-ERROR Select Page Item");
					loadNextPageItem();
					return;
				}
			}else{
				internCurrPageItem++;
				loadNextPageItem();
				return;
			}
	
			internCurrPageItem++;
		}
		
		public static var pagelist:String="";
		
		public static function genPageList () :void {
			var p:String = "";
			if( pages && pages.length > 0 ) {
				for(var i:int=0; i<pages.length-1; i++) { 
					p += pages[i].filename+",";
				}
				p += pages[pages.length-1].filename;
			}
			pagelist = p;
		}
		
		public static var articlepagelist:String="";
		
		public static function genArticlePageList () :void {
			var p:String = "";
			if( articlePages && articlePages.length > 0 ) {
				for(var i:int=0; i<articlePages.length-1; i++) { 
					p += articlePages[i].filename+",";
				}
				p += articlePages[articlePages.length-1].filename;
			}
			articlepagelist = p;
		}
		
		public static function loadPage ( page:Object ) :void {
			addFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.filename );
			genPageList();
		}
		
		public static function clearPage ( name:String ) :void {
			if( pages && pageTable && pageTable[name] != undefined ) {
				var L:int = pages.length;
				for(var i:int=0; i<L; i++) {
					if( pages[i].name == name ) {
						pages.splice(i,1);
						break;
					}
				}
				delete pageTable[name];
			}
		}
		public static function createPage ( page:Page, props:Object=null) :void
		{
			if ( CTOptions.debugOutput )
			{
				Console.log( "CreatePage: " 
				+ "\nname: " + page.name 
				+ "\ntitle: " + page.title 
				+ "\ntype: "+ page.type 
				+ "\ntemplate: "+ page.template 
				+ "\nparent: "+ page.parent 
				+ "\nwebdir: "+ page.webdir 
				+ "\nfilename: " + page.filename );
			}
			
			var f:File;
			var txt:String;
			var rt:String;
			var newFile:String;
			
			if( props && props["inputname"] )
			{
				// article page
				if ( articlePages.indexOf( page ) == -1 ) {
					var found:Boolean = false;
					for(var i:int=articlePages.length-1; i>=0; i--) {
						if( articlePages[i].name == page.name ) {
							found = true;
						}
					}
					if( !found ) {
						articlePages.push( page );
					}
				}
				
				// loadArticlePage( page );
				var sp:int = page.template.indexOf(":");
			
				if( sp == -1 ) {
					Console.log("Error: Article Page Template not found: " + page.template );
				}else{
					var tmplname:String = page.template.substring( 0, sp );
					var tmpl:String = page.template.substring( sp + 1 );
					
					// template source file
					f = new File(projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + tmplname + CTOptions.urlSeparator + tmpl);
					
					if( f.exists )
					{
						txt = readTextFile( f.url );
						rt = TemplateTools.rewritePage( txt, page.name, props );
						
						if ( !page.webdir ) {
							newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.filename;
						}else{
							newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.webdir + CTOptions.urlSeparator + page.filename;
						}
						if ( CTOptions.debugOutput ) {
							Console.log("Write Article Page: " + newFile);
						}
						
						writeTextFile( newFile, rt );
						loadArticlePage( page, props["inputname"] );
					}
					else
					{
						Console.log("Error: Article Page Template File Error " + f);
					}
				}
			}
			else
			{
				// template source file
				f = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.template );
				
				if( f.exists )
				{
					txt = readTextFile( f.url );
					rt = TemplateTools.rewritePage( txt, page.name, props );
					newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.filename;
					
					if ( CTOptions.debugOutput )
					{
						Console.log("Write Page: " + newFile);
					}
					
					writeTextFile( newFile, rt );
					
					if ( pages.indexOf( page ) == -1 )
					{
						pages.push( page );
						loadPage( page );
						
						if ( CTOptions.debugOutput )
						{
							Console.log("Page Loaded: " + newFile);
						}
					}
				}
				else
				{
					Console.log("Error: Page Template File Error " + f);
				}
			}
		}
		
		public static function loadArticlePage ( page:Page, itemName:String ) :void {
			addArticleFile( page, itemName );
			genArticlePageList();
		}
		
		// create article prj file if not available
		private static function addArticleFile ( page:Page, itemName:String ) :void
		{
			if( page )
			{
				if(!articleProcFiles) articleProcFiles = [];
				
				var sp:int = page.template.indexOf(":");
			
				if( sp == -1 ) {
					Console.log("Error: Article Page Template not found: " + page.template );
				}else{
					var tmplname:String = page.template.substring( 0, sp );
					var tmpl:String = page.template.substring( sp + 1 );
					var newFile:String;
					if ( !page.webdir ) {
						newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.filename;
					}else{
						newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.webdir + CTOptions.urlSeparator + page.filename;
					}
					var prjFile:ProjectFile = findArticleProjectFile( newFile, "path" );
					var str:String = readTextFile( newFile );
					
					if( prjFile == null )
					{
						var pf:ProjectFile = new ProjectFile( tmplname );
						pf.setUrl( newFile );
						pf.setTemplate( str, itemName );
						pf.allDirty();
						articleProcFiles.push( pf );
					}
					else
					{
						// Update
						prjFile.setTemplate( str, itemName );
						prjFile.allDirty();
					}
				}
			}
		}
		
		public static function saveArticleFile ( pf:ProjectFile, webdir:String ) :void
		{
			var file2:File = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + (webdir ? CTOptions.urlSeparator + webdir : "") + CTOptions.urlSeparator + pf.filename );
			var fileStream2:FileStream = new FileStream();
			fileStream2.open( file2, FileMode.WRITE );
			
			var rawtext:String = pf.getText();
			fileStream2.writeMultiByte( rawtext, CTOptions.charset );
			fileStream2.close();
			
			var minurl:String = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + (webdir ? CTOptions.urlSeparator + webdir : "") + CTOptions.urlSeparator + pf.filename;
			var file3:File = new File( minurl );
			var fileStream3:FileStream = new FileStream();
			fileStream3.open( file3, FileMode.WRITE );
					
			fileStream3.writeMultiByte( pf.getCompact(), CTOptions.charset );
			fileStream3.close();
			
			pf.textSaveDirty = false;
		}
		
		internal static function findArticleProjectFile ( value:String, key:String = "name" ) :ProjectFile
		{
			if( articleProcFiles ) {
				var L:int = articleProcFiles.length;
				
				for( var i:int = 0; i < L; i++ )
				{
					if( articleProcFiles[i][key] == value ) {
						return ProjectFile( articleProcFiles[i] );
					}
				}
			}
			return null;
		}
		
		public static function cloneTo (srcit:Object, dest:Object, extUid:Boolean=false) :void {
			var n:String;
			var r:Object = srcit;
			if(r && dest) {
				for(n in r) {
					// Change uid name to ext_uid in propObj
					if( extUid && n == "uid" ) {
						dest["ext_uid"] = r[n];
					}else{
						dest[n] = r[n];
					}
				}
			}
		}
		
		private static function onPageItem (res:DBResult) :void {
			if(res && res.data && res.data.length > 0) {
				var r:Object;
				var clone:Object;
				var n:String;
				for(var i:int=0; i<res.data.length; i++) {
					r = res.data[i];
					if( r.name ) {
						CTTools.cloneTo(r, CTTools.pageItemTable[ r.name ], true );
					}else{
						Console.log( "ERROR: EXTENSION-PAGE-ITEM has no name attribute");
					}
				}
			}
			loadNextPageItem();
		}
		
		private static function displayLater () :void {
			invalidateAndBuildFiles();
			if( CTOptions.autoSave ) save();
			Application.instance.cmd( "TemplateTools edit-content");
			try {
				Application.instance.view.panel.src["displayFiles"]();
			}catch(e:Error) {
				
			}
		}
		
		private static function onloadComplete () :void {
			
			if ( CTTools.internDBCreateCmds )
			{
				// run dbcreate commands
				CTTools.runNextDBCreateCmd();
			}
			else
			{
				// Finally Opened the project...
				//.............../||||Loaded||||\.................
				
				invalidateAndBuildFiles();
				
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( CTOptions.overrideInstallDB != "" ) {
					// TODO: bugfix with override-db and new subtemplates missing in DB wich is used to override..
					// Currently new sub templates have to be added manually into the override db
					// requires merge of databases and compare subtemplates..
					if( CTOptions.debugOutput ) Console.log("OVERRIDE DONE: SH-ID: " +CTOptions.localSharedObjectId  + ", value: " +  sh.data.overrideDBDone + ", " + CTOptions.overrideInstallDB );
					if( sh && sh.data && sh.data.overrideDBDone != true ) {
						save( showRestartMsg );
						return;
					}
				}
				
				setTimeout( displayLater, 950 );
				
				if ( openCompleteHandler != null) {
					openCompleteHandler ();	
					openCompleteHandler = null;
				}
			}
		}
		private static var quitCounter:int=0;
		
		public static function showRestartMsg () :void
		{
			if(!CTOptions.verboseMode ) 
				Application.instance.cmd("Console clear");
			
			Console.log( "* Installation complete\n* Loading Project.. \n\n"  );
			
			
			if( CTOptions.restartAfterInstall )
			{
				if(!CTOptions.verboseMode ) 
					Application.instance.cmd("Console clear");
				
				Application.instance.cmd("Console show console log * RESTART THE APPLICATION TO FINISH THE INSTALLATION.");
				Console.log( "* THE APPLICATION WILL QUIT AUTOMATICALLY IN 5 SECONDS."  );
				Console.log( "*\n* -- CLICK ANYWERE TO ABORT -- \n\n"  );
				
				quitCounter = 0;
				_abortQuit = false;
				Application.instance.addEventListener( MouseEvent.MOUSE_DOWN, quitAbort );
				
				setTimeout( restart, 1000 );
			}else{
				setTimeout( reloadAfterOverride, 1200 );
			}
		}
		private static var _abortQuit:Boolean=false;
		
		public static function quitAbort (e:MouseEvent) :void {
			_abortQuit = true;
			Application.instance.removeEventListener( MouseEvent.MOUSE_DOWN, quitAbort );
		}
		
		public static function onStartAfterOverride (e:AppEvent) :void {
			Application.instance.removeEventListener( AppEvent.START, onStartAfterOverride );
			setTimeout( reloadLast, 1200 );			
		}
		
		public static function reloadLast () :void {
			if( activeTemplate ) invalidateTemplateFiles ( activeTemplate, true );
			invalidateAndBuildFiles();
			save();
		}
		
		public static function reloadAfterOverride () :void {
			Application.instance.cmd("Application restart");
			Application.instance.addEventListener( AppEvent.START, onStartAfterOverride );
		}
		public static function restart () :void {
			if( _abortQuit ) return;
			
			if( quitCounter < 4 ) {
				quitCounter++;
				setTimeout( restart, 999 );
				Console.logInline( ".. "+(5-quitCounter) +" " );
			}else if( quitCounter == 4 ) {
				quitCounter++;
				setTimeout( restart, 999 );
				Application.instance.cmd("Console clear show console log PLEASE RE-LAUNCH THE APP..");
			}else{
				Application.command("quit");
			}
		}
		
		// browser for project
		public static function openProject ( completeHandler:Function=null ) :void {
			var directory:File;
			if( projectDir ) directory = new File(projectDir);
			else directory = File.documentsDirectory;
			
			try {
				directory.browseForDirectory("Open Project");
				directory.addEventListener(Event.SELECT, dirForOpenSelected);
				selOpenCompleteHandler = completeHandler;
			}catch (error:Error){
				Console.log("ERROR OPEN PRJ:" + error.message);
			}
		}
		
		private static function dirForOpenSelected (event:Event) :void {
			var directory:File = event.target as File;
			clearFiles();
			setProjectDirUrl( directory.url );
			open(selOpenCompleteHandler);
		}
		private static var selOpenCompleteHandler:Function = null;
		private static var openCompleteHandler:Function = null;
		
		// Open projectDir
		// Load Root Template Files
		// Load DB
		// Load DB (Sub)Templates
		public static function open ( completeHandler:Function=null ) :Boolean
		{
			if( projectDir )
			{
				var ish:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
				
				var gp:String=CTOptions.installTemplate == "current" ? "" : CTOptions.installTemplate ;
				
				// override options from install.xml file
				if( ish && ish.data )
				{
					if( ish.data.installOptions != undefined )
					{
						var x:XML = new XML( ish.data.installOptions );
						CTMain.overrideInstallOptions( x.templates );
						
						if( ish.data.installTemplates ) {
							var L:int = ish.data.installTemplates.length;
							for(var i:int=0; i<L; i++) {
								if( ish.data.installTemplates[i].prjDir == projectDir ) {
									gp = ish.data.installTemplates[i].genericPath;
									CTMain.overrideInstallOptions( XMLList( x.templates.template.(@name==ish.data.installTemplates[i].name)) );
								}
							}
						}
					}
					
					if( !ish.data.recentProjects ) {
						ish.data.recentProjects = new Array();
					}
					
					if( ish.data.recentProjects.indexOf(projectDir) == -1 ) {
						ish.data.recentProjects.push(projectDir);
					}
				}
				
				activeTemplate = new Template("root");
				activeTemplate.genericPath = gp;
				
				var tistr:String = readTextFile ( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.templateIndexFile );
				if( tistr ) {
					var txo:XML = new XML( tistr );
					if( txo.template ) {
						activeTemplate.indexStr = tistr;
						loadTmplByIndexFile(txo, projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate);
					}else{
						tistr = "";
					}
				}
				
				if( !tistr ) {
					Console.log("ERROR: No '" +CTOptions.templateIndexFile+"' file or template node in file missing");
					return false;
				}
				
				// Load DB:
				var dbindex:File = new File( projectDir + CTOptions.urlSeparator + CTOptions.dbIndexFileName );
				if( dbindex.exists ) {
					// Load db index file from project dir:
					var fs:FileStream = new FileStream();
					fs.open( dbindex, FileMode.READ );
					var dbistr:String = fs.readMultiByte(dbindex.size, CTOptions.charset);
					fs.close();
					// read db index file
					var xo:XML = new XML( dbistr );
					var dbType:String = xo.db.@type;
					var filename:String;
					var cid:int;
					if( dbType == "sqlite" ) {
						filename = xo.db.@filename;
						cid = filename.indexOf("/");
						if( cid >= 0 ) {
							if( cid == 0 ) { // remove first slash
								filename = filename.substring( 1 );
							}
							filename = filename.split("/").join( CTOptions.urlSeparator );
						}
						openCompleteHandler = completeHandler;
						
						// Create DB File if not available
						loadDB ( projectDir + CTOptions.urlSeparator + filename, SqliteDB );
						db.addEventListener( DBAL.DB_LOADED, loadDBHandler );
					}
				}else{
					Console.log( "DB-ERROR: '" + CTOptions.dbIndexFileName + "' missing");
					showTemplate = true;
					if(! CTTools.internDBCreateCmds && !saveAsFirst) displayFiles(); // leave console open while installing...
					return false;
				}
				
				storeProjectLocal();
			}
			
			return true;
		}
		
		private static var selSaveCompleteHandler:Function = null;
		private static var saveCompleteHandler:Function = null;
		
		public static function saveAs ( completeHandler:Function=null ) :void {
			var directory:File;
			if( projectDir ) directory = new File(projectDir);
			else directory = File.documentsDirectory;
			try {
				directory.browseForDirectory("Select Project Directory");
				selSaveCompleteHandler = completeHandler;
				
				directory.addEventListener(Event.SELECT, directorySelected);
			}catch (error:Error){
				Console.log("ERROR SAVE AS: " + error.message);
			}
		}
		public static function storeProjectLocal () :void {
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh ) {
				if( sh.data ) {
					if( CTOptions.debugOutput ) Console.log( "Set Last PRJ: " + projectDir + " in SH-OBJ: " +  CTOptions.installSharedObjectId );
					sh.data.lastProjectDir = projectDir;
					sh.flush();
				}
				sh.close();
			}
		}
		private static var preloaderClip:CssSprite;
		private static var preloaderDisplay:CssSprite;
		
		public static function save ( completeHandler:Function=null ) :void
		{
			if ( projectDir && procFiles )
			{
				var i:int;
				if(!CTOptions.isMobile /*&& CTOptions.monitorFiles*/) {
					for( i=0; i<procFiles.length; i++) {
						procFiles[i].monitorFile(false);
					}
				}
				
				saveCompleteHandler = completeHandler;
				
				var dir:File = new File( projectDir );
				var files:Array = CTTools.procFiles;
				var L:int = files.length;
				
				// save all prj files
				if( !saveAsFirst ) {
					for( i=0; i < L; i++) {
						saveFile( ProjectFile( files[i]), dir );
					}
				}else{
					// copy template files to prj-dir
					var file:File;
					var fileStream:FileStream;
					
					for( i=0; i < L; i++) {
						file = new File( dir.url + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + files[i].filename );
						fileStream = new FileStream();
						fileStream.open( file, FileMode.WRITE );
						fileStream.writeMultiByte( files[i].getTemplate(), CTOptions.charset);
						fileStream.close();
					}
				}
				
				if( !db )
				{
					//
					//  ...........................
					// : INSTALL START WITH NEW DB :
					//  ...........................
					//
					// On Save -> IF saveFirst == true
					// Or there is no db (null)
					// Create new Database in project folder
					//
					Application.instance.showLoading();
					if( CTOptions.verboseMode ) {
						Application.instance.cmd("Console show console clear log Installing '" + activeTemplate.name + "'");
					}else{
						Application.instance.cmd("Console clear log Installing '" + activeTemplate.name + "'");
						
					}
					
					// Save template-index to tmpl dir
					if( activeTemplate.indexStr ) {
						var ti:File = new File( projectDir +CTOptions.urlSeparator+ CTOptions.projectFolderTemplate +CTOptions.urlSeparator+ CTOptions.templateIndexFile );
						var fsi:FileStream = new FileStream();
						fsi.open( ti, FileMode.WRITE );
						fsi.writeMultiByte( activeTemplate.indexStr, CTOptions.charset);
						fsi.close();
					}
					
					// Create db-index file
					var dbi:File = new File( projectDir + CTOptions.urlSeparator + CTOptions.dbIndexFileName );
					var dbistr:String;
					var fs:FileStream;
					
					if( dbi.exists ) {
						// Load db index file from project dir:
						fs = new FileStream();
						fs.open( dbi, FileMode.READ );
						dbistr = fs.readMultiByte(dbi.size, CTOptions.charset);
						fs.close();
					}else{
						// Load a default db index file from (app:/ctres/db-index.xml)
						if(CTOptions.debugOutput) 
							Console.log("Loading DB Structure: " + CTOptions.configFolder + CTOptions.urlSeparator + CTOptions.dbInitFileName );
						
						var dbid:File = File.applicationStorageDirectory.resolvePath( CTOptions.configFolder + CTOptions.urlSeparator + CTOptions.dbInitFileName);
						if( dbid.exists ) {
							fs = new FileStream();
							fs.open( dbid, FileMode.READ );
							dbistr = fs.readMultiByte(dbid.size, CTOptions.charset);
							fs.close();
						}else{
							Console.log("ERROR Cant Create DEFAULT-DB-INDEX file");
						}
					}
					
					// overwrite db with no dbsetup + restart..
					
					if( dbistr )
					{
						var xo:XML = new XML( dbistr );
						var dbType:String = xo.db.@type;
						
						dbiXml = xo;
						
						// write db-index.xml to project dir
						var prjdbindex:File = new File( projectDir + CTOptions.urlSeparator + CTOptions.dbIndexFileName );
						var dbistream:FileStream = new FileStream();
						dbistream.open( prjdbindex, FileMode.WRITE );
						dbistream.writeMultiByte( dbistr, CTOptions.charset);
						dbistream.close();
						if( dbType == "sqlite" ) {
							var filename:String = xo.db.@filename;
							var cid:int =  filename.indexOf("/");
							if( cid >= 0 ) {
								if( cid == 0 ) { // remove first slash
									filename = filename.substring( 1 );
								}
							}
						
							// Create DB File if not available
							loadDB ( projectDir + CTOptions.urlSeparator + filename, SqliteDB );
							db.addEventListener( DBAL.DB_LOADED, onCreateDB );
						}
					}
				}
				else					
				{
					
					if( saveAsFirst ) {
						saveAsFirst = false;
					}
					
					saveDirty = false;
					if(completeHandler != null) completeHandler();
					
					if( !CTOptions.isMobile && CTOptions.monitorFiles ) {
						for(i=0; i<procFiles.length; i++) {
							procFiles[i].monitorFile(true);
						}
					}
				} // ! db//
			}
		}
		
		private static function onCreateDB (e:Event) :void {
			db.removeEventListener( DBAL.DB_LOADED, onCreateDB );
			
			if(!dbiXml) return ;
			
			var xo:XML = dbiXml;
			
			var initquery:String = xo.db.@initquery;
			
			if( initquery )
			{
				
				var sqlfile:File = File.applicationDirectory.resolvePath( initquery );
				
				if( !sqlfile.exists ) {
					sqlfile = new File( initquery );
				}
				
				if( sqlfile.exists ) {
					
					var sqlfileStream:FileStream = new FileStream();
					sqlfileStream.open( sqlfile, FileMode.READ );
					var sqlstr:String = sqlfileStream.readMultiByte(sqlfile.size, CTOptions.charset);
			
					sqlfileStream.close();
					
					if(installProgress) installProgress.value = 0.4;
					
					execSql( sqlstr, createDBHandler );
				}
			}
		}
		
		private static var pendingSQLQuerys:Array;
		
		/**
		* Execute sql statement(s) asyncronuosly to modify the database
		* @param sqlstr The sql text
		* @param resultHandler Callback function when the execution finished
		**/
		public static function execSql ( sqlstr:String, resultHandler:Function ) :void {
			
			if( sqlExec ) {
				if ( pendingSQLQuerys == null )  pendingSQLQuerys = [];
				else if( pendingSQLQuerys[ pendingSQLQuerys.length -1 ].sqlstr == sqlstr ) {
					if(CTOptions.debugOutput) Console.log("WARNING PROCESSING THE SAME SQL TWICE: " + sqlstr);
				}
				pendingSQLQuerys.push( { sqlstr:sqlstr, resultHandler:resultHandler } );
				return;
			}
			
			sqlstr = CompactCode.compactSql( sqlstr );
			
			var querys:Array = [];
			var L:int = sqlstr.length;
			var cc:int, cc2:int;
			var qstart:int=0;
			var q:String;
			
			for(var i:int = 0; i<L; i++) {
				cc = sqlstr.charCodeAt(i);
				if( cc == 34 || cc == 39 ) { // Ignore in Strings
					cc2 = cc;
					for(i++; i<L; i++) { 
						if( sqlstr.charCodeAt(i) == cc2 ) break;
					}
				}
				if( cc == 59 ) {
					q = sqlstr.substring( qstart, i );
					querys.push( q );
					qstart = i+1;
				}
			}
			if ( querys.length > 0 ) {
				
				if( querys.length == 1 ) {
					db.query( resultHandler, sqlstr+";", null );
				}else{
					currQuery = 0;
					sqlExec = true; 
					sqlQuerys = querys;
					sqlHandler = resultHandler;
					runNextQuery(null);
				}
			}
		}
		
		private static function runNextQuery (res:DBResult) :void {
			if( currQuery >= sqlQuerys.length ) {
				sqlExec = false;
				if ( sqlHandler != null ) sqlHandler(res);
				if ( pendingSQLQuerys ) {
					if( pendingSQLQuerys.length > 0 ) {
						var obj = pendingSQLQuerys.pop();
						execSql( obj.sqlstr, obj.resultHandler );
					}else {
						pendingSQLQuerys = null;	
					}
				}
				return;
			}
			
			db.query( runNextQuery, sqlQuerys[ currQuery ] + ";", null );
			currQuery++;
		}
		
		private static function directorySelected (event:Event) :void {
			var directory:File = event.target as File;
			setProjectDirUrl( directory.url );
			storeProjectLocal();
			save( CTTools.selSaveCompleteHandler );
		}
		
		//  .........
		// : PRJ-DIR :
		//  .........
		public static function setProjectDirUrl ( url:String ) :void
		{
			projectDir = url;
			if ( projectDir.charAt( projectDir.length - 1 ) == CTOptions.urlSeparator ) {
				projectDir = projectDir.substring(0, projectDir.length - 1);
			}
			
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh.data.installTemplates )
			{
				var L:int = sh.data.installTemplates.length;
				
				for(var i:int=0; i<L; i++) {
					if( sh.data.installTemplates[i].prjDir == "" ) {
						sh.data.installTemplates[i].prjDir = projectDir;
						break;
					}	
				}
			}
			
		}
		
		public static function saveFile ( pf:ProjectFile, dir:File ) :void
		{
			var T:Template = CTTools.findTemplate( pf.templateId, "name" );
			
			if( T ) {
				if ( T.type == "root" )
				{
					// Save file to /tmpl, /raw and /min folders inside the project directory
					
					if( pf.templateSaveDirty )
					{
						var file:File = new File( dir.url + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + pf.filename );
						var fileStream:FileStream = new FileStream();
						fileStream.open( file, FileMode.WRITE );
						fileStream.writeMultiByte( pf.getTemplate(), CTOptions.charset);
						fileStream.close();
						
						pf.templateSaveDirty = false;
					}
					
					if( pf.textSaveDirty )
					{
						var file2:File = new File( dir.url + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + pf.filename );
						var fileStream2:FileStream = new FileStream();
						fileStream2.open( file2, FileMode.WRITE );
						
						var rawtext:String = pf.getText();
						fileStream2.writeMultiByte( rawtext, CTOptions.charset );
						fileStream2.close();
						
						var minurl:String = dir.url + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + pf.filename;
						var file3:File = new File( minurl );
						var fileStream3:FileStream = new FileStream();
						fileStream3.open( file3, FileMode.WRITE );
						
						if( T.noCompressLookup[pf.filename] ) {
							// write raw content to file:
							fileStream3.writeMultiByte( rawtext, CTOptions.charset );
						}else{					
							fileStream3.writeMultiByte( pf.getCompact(), CTOptions.charset );
						}
						fileStream3.close();
						
						pf.textSaveDirty = false;
					}
				}
				else
				{
					// Save to "tmpl/st/sub-template" in project directory
					if( pf.templateSaveDirty )
					{
						var file4:File = new File(dir.url + CTOptions.urlSeparator + CTOptions.projectFolderTemplate +CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + T.name +CTOptions.urlSeparator+ pf.filename );
						var fileStream4:FileStream = new FileStream();
						fileStream4.open( file4, FileMode.WRITE );
						fileStream4.writeMultiByte( pf.getTemplate(), CTOptions.charset );
						fileStream4.close();
						
						pf.templateSaveDirty = false;
					}
				}
			}
		}
		
		private static var instObjId:int=-1;
		
		public static function command (argv:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null) :void {
			var args:Array = argv2Array(argv);
			var i:int;
			var sh:SharedObject;
			var ish:SharedObject;
			
			var saveAsIndex:int = args.indexOf( "saveas" );			
			if( saveAsIndex >= 0 ) {
				saveAs( cmdComplete );
				return;
			}
			var saveIndex:int = args.indexOf( "save" );			
			if( saveIndex >= 0 ) {
				save(cmdComplete);
				return;
			}
			
			var subtemplate:int = args.indexOf( "subtemplate" );			
			if( subtemplate >= 0 )
			{
				// Load or Install a Subtemplate
				var folder_name1:String = BaseTool.arrStringFrom( args, subtemplate+1 );
				var pth1:String = folder_name1;
				
				if( pth1.substring(0,18) == "template-generic:/" )
				{
					var generic:String = activeTemplate.genericPath;
					
					ish = SharedObject.getLocal( CTOptions.installSharedObjectId );
					if( ish && ish.data && ish.data.installTemplates )
					{
						var fi3:File;
						if( CTOptions.mobileProjectFolderName == "ask" ) {
							if( instObjId >= 0 ) {
								fi3 = new File( ish.data.installTemplates[instObjId].prjDir );
							}else{
								Console.log("Error: InstObjID is undefined");
							}
						}else{
							fi3 =  CTOptions.mobileParentFolder.resolvePath( CTOptions.mobileProjectFolderName );
						}
						
						for(i=0; i<ish.data.installTemplates.length; i++)
						{
							if( ish.data.installTemplates[i].prjDir == projectDir ||  ish.data.installTemplates[i].prjDir == fi3.url  )
							{
								generic = ish.data.installTemplates[i].genericPath;
								
								break;
							}
						}
					}
					pth1 = generic + CTOptions.urlSeparator + pth1.substring(18);
				}
				else if( pth1.substring(0,10) == "template:/" ) {
					pth1 =  projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + pth1.substring(10);
				}
				
				loadSubTemplate( pth1, cmdComplete );
				return;
			}
			
			
			
			var template:int = args.indexOf( "template" );			
			if( template >= 0 )
			{
				// New From Template
				if( CTOptions.overrideInstallDB != "" )
				{
					// Problem if local-sh changes after install host? 
					// after install override..
					
					sh = SharedObject.getLocal( CTOptions.localSharedObjectId );
					sh.data.overrideDBDone = false;
					sh.flush();
					sh.close();
					
				}
				
				loadTemplate__FolderName = BaseTool.arrStringFrom( args, template + 1 );
				
				ish = SharedObject.getLocal(CTOptions.installSharedObjectId);
				var k:int;
				
				if( loadTemplate__FolderName == "" || loadTemplate__FolderName == "current" )
				{
					// New installed template
					if( projectDir ) {
						if( ish && ish.data && ish.data.installTemplates ) 
						{
							for( k=0; k<ish.data.installTemplates.length; k++) {
								if( ish.data.installTemplates[k].prjDir == projectDir ) {
									loadTemplate__FolderName = ish.data.installTemplates[k].genericPath;
									instObjId = k;
									if(CTOptions.debugOutput ) Console.log( "Installing last installed Template from: " + loadTemplate__FolderName);
									break;
								}	
							}
						}
					}else{
						// No project dir with template available.. show install templates or get-host-info
						Main(Application.instance).cmd( "Application view StartScreen" );
						return;
					}
				}
				
				var ih:Boolean = false;
				
				// search empty prjDir or create inst obj
				if( ish.data.installTemplates ) {
					for( k=0; k<ish.data.installTemplates.length; k++) {
						if( ish.data.installTemplates[k].prjDir == "" ) {
							ih = true;
							instObjId = k;
							break;
						}
					}
				}
				
				if( !ih )
				{
					var instobj:Object = {
						name: activeTemplate ? activeTemplate.name : "",
						src: "",
						version: activeTemplate ? activeTemplate.version : "",
						genericPath: loadTemplate__FolderName,
						prjDir:""
					};
					
					if( ish.data.installTemplates == undefined ) ish.data.installTemplates = [];
					instObjId = ish.data.installTemplates.push( instobj ) - 1;		
				}
				
				if( CTOptions.isMobile )
				{
					if( CTOptions.mobileProjectFolderName == "ask" )
					{
						// folder names in install shared obj..
						
						var win0:Window = Window( Application.instance.window.GetStringWindow( "FolderNameWindow", agf.ui.Language.getKeyword("CT-Get-Mobile-Folder-Title"), Language.getKeyword("CT-Get-Mobile-Folder-MSG"), {
						complete: function (str:String) {
							var fi2:File = CTOptions.mobileParentFolder.resolvePath( str );
							fi2.createDirectory();
							ish.data.installTemplates[instObjId].prjDir = fi2.url;
							if(cmdComplete != null) cmdComplete();
							ish.flush();
							
							loadTemplate();
						}, 
						continueLabel:Language.getKeyword("Create Project"),
						allowCancel: true,
						multiline:false,
						autoWidth:false,
						autoHeight:true,
						password:false,
						cancelLabel: Language.getKeyword("Cancel")
						}, 'foldername-window') );
						
						Application.instance.windows.addChild( win0 );
						
						return;
						
					}
					else
					{
						clearMobileFolder();
						
						var fi2:File = CTOptions.mobileParentFolder.resolvePath( CTOptions.mobileProjectFolderName );
						ish.data.installTemplates[instObjId].prjDir = fi2.url;
					}
				}
				ish.flush();
				loadTemplate();
			}
			
			var clienthost:int = args.indexOf( "client-host-info" );			
			if( clienthost >= 0 ) {
				CTMain(Application.instance).getClientHostInfo();
			}
			
			var addIndex:int = args.indexOf( "addfiles" );			
			if( addIndex >= 0 ) {
				addFiles(cmdComplete);
				return;
			}
			
			var openFileIndex:int = args.indexOf( "openfile" );			
			if( openFileIndex >= 0 ) {
				addFile( BaseTool.arrStringFrom( args, openIndex + 1), activeTemplate );
			}
			var openprjIndex:int = args.indexOf( "openproject" );			
			if( openprjIndex >= 0 ) {
				// Get Open Dir
				openProject(cmdComplete);
				return;
			}
			
			var openIndex:int = args.indexOf( "open" );			
			if( openIndex >= 0 ) {
				setProjectDirUrl( BaseTool.arrStringFrom( args, openIndex + 1) );
				
				open( cmdComplete );
				return;
			}
			
			var navIndex:int = args.indexOf( "navigate" );			
			if( navIndex >= 0 ) {
				var rq:URLRequest = new URLRequest( BaseTool.arrStringFrom( args, navIndex + 1) );
				navigateToURL( rq, "_blank" );
				return;
			}
			
			var sqlIndex:int = args.indexOf( "query" );			
			if( sqlIndex >= 0 ) {
				execSql( BaseTool.arrStringFrom( args, openIndex + 1), cmdComplete );
				return;
			}
			
			var clearIndex:int = args.indexOf( "clearfiles" );			
			if( clearIndex >= 0 ) {
				// New
				clearFiles ();
				displayFiles();
			}
			var brpreview:int = args.indexOf( "browser-preview" );			
			if( brpreview >= 0 ) {
				// New
				if(projectDir) {
					if( CTTools.saveDirty ) {
						CTTools.showRequireSave( onNeedBPSave );
					}else{
						onNeedBPSave();
					}
				}
			}
			var resetPwdIndex:int = args.indexOf( "reset-password" );			
			if( resetPwdIndex >= 0 ) {
				CTTools.resetPwd();
			}
			var getPwdIndex:int = args.indexOf( "get-password" );			
			if( getPwdIndex >= 0 ) {
				var win1:Window = Window( Application.instance.window.GetStringWindow( "PasswordWindow", agf.ui.Language.getKeyword("CT-Get-Password"), Language.getKeyword("CT-Get-Password-MSG"), {
				complete: function (str:String) {
					var hs:String = SHA256.hash( str );
					CTTools.storePwd(hs);
					if(cmdComplete != null) cmdComplete();
				}, 
				continueLabel:Language.getKeyword("Send"),
				allowCancel: true,
				multiline:false,
				autoWidth:false,
				autoHeight:true,
				password:true,
				cancelLabel: Language.getKeyword("Cancel")
				}, 'password-window') );
				
				Application.instance.windows.addChild( win1 );
				return;
			}
			
			var getHashIndex:int = args.indexOf( "get-hashcode" );			
			if( getHashIndex >= 0 ) {
				var win4:Window = Window( Application.instance.window.GetStringWindow( "HashcodeWindow", agf.ui.Language.getKeyword("CT-Get-HashCode"), Language.getKeyword("CT-Get-HashCode-MSG"), {
				complete: function (str:String) {
					var hs:String = SHA256.hash( str );
					Application.instance.cmd("Console show console clear");
					Console.log("SHA256 HASH-CODE '"+str+"': ");
					Console.log(hs);
					if(cmdComplete != null) cmdComplete();
				}, 
				continueLabel:Language.getKeyword("Generate Hash"),
				allowCancel: true,
				multiline:false,
				autoWidth:false,
				autoHeight:true,
				password:false,
				cancelLabel: Language.getKeyword("Cancel")
				}, 'hashcoe-window') );
				
				Application.instance.windows.addChild( win4 );
				return;
			}
			
			var newPwdIndex:int = args.indexOf( "new-password" );			
			if( newPwdIndex >= 0 ) {
				var pwd:String = "";
				sh = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( sh ) {
					if( sh.data && sh.data.userPwd != undefined ) {
						pwd = sh.data.userPwd;
					}
				}
				if( pwd == "" ) {
					Application.instance.cmd( "CTTools get-password", setNewPassword);
					return ;
				}
				
				var win2:Window = Window( Application.instance.window.GetStringWindow( "NewPasswordWindow", agf.ui.Language.getKeyword("CT-New-Password"), Language.getKeyword("CT-New-Password-MSG"), {
				complete: function (str:String) {
					var hs:String = SHA256.hash( str );
					CTTools.sendNewPwd(hs);
					if(cmdComplete != null) cmdComplete();
				}, 
				continueLabel:Language.getKeyword("Send New Password"),
				allowCancel: true,
				multiline:false,
				autoWidth:false,
				autoHeight:true,
				password:false,
				cancelLabel: Language.getKeyword("Cancel")
				}, 'new-password-window') );
				
				Application.instance.windows.addChild( win2 );
				return;
			}
			var cmdIndex:int = args.indexOf( "commander" );			
			if( cmdIndex >= 0 ) {
				// Show Commander Window
				var win:Window = Window( Application.instance.window.GetStringWindow( "CommanderWindow", agf.ui.Language.getKeyword("CT-Commander"), Language.getKeyword("CT-Commander-MSG"), {
				complete: function (str:String) {
					if ( str ) Application.instance.cmd( str );
					if(cmdComplete != null) cmdComplete();
				},
				continueLabel:Language.getKeyword("Process"),
				allowCancel: true,
				multiline:false,
				autoWidth:false,
				autoHeight:true,
				cancelLabel: Language.getKeyword("Cancel")
				}, 'commander-window') );
				
				Application.instance.windows.addChild( win );
				return;
			}
			var cmd2Index:int = args.indexOf( "command-tools" );			
			if( cmd2Index >= 0 ) {
				// Show Extended Commander Window (experimental)
				var win41:Window = new CommandEditor();
				Application.instance.windows.addChild( win41 );
				win41.init();
				CommandEditor(win41).createEditor();
			}
            var info:int = args.indexOf( "app-info" );			
			if( info >= 0 ) {
				TemplateTools.logInfo();
			}
			var appUpdate:int = args.indexOf( "app-update" );			
			if( appUpdate >= 0 ) {
				CTImporter.lookForAppUpdate();
			}
            var templateUpdate:int = args.indexOf( "update" );			
			if( templateUpdate >= 0 ) {
				CTImporter.lookForTemplateUpdate();
			}
			var defConst:int = args.indexOf( "define-constant" );			
			if( defConst >= 0 ){
				var cdef:String = BaseTool.arrStringFrom( args, defConst+1 );
				var eqs:int = cdef.indexOf("=");
				if( eqs > 0 ) {
					var const_name:String = cdef.substring(0, eqs );
					
					if( templateConstants[ const_name ] != undefined ) {
						Console.log("ERROR: Attempting to overwrite template constant: " + const_name);
					}else{
						var const_value:String = cdef.substring( eqs+1 );
						templateConstants[ const_name ] = const_value;
					}
					
				}
			}
			
			var clearPrjRef:int = args.indexOf( "clear-project-reference" );			
			if( clearPrjRef >= 0 ){
				
				sh = SharedObject.getLocal( CTOptions.installSharedObjectId );
				if( sh && sh.data ) {
					 if( sh.data.lastProjectDir != undefined) {
						delete sh.data.lastProjectDir;
					 }
					 if( sh.data.installOptions != undefined ) {
						 delete sh.data.installOptions;
					 }
					 if( sh.data.installTemplates != undefined ) {
						 delete sh.data.installTemplates;
					 }
					 sh.flush();
					 sh.close();
				 }
				 if( CTOptions.isMobile ) {
					 clearMobileFolder();
				}
				
			}
			var displayIndex:int = args.indexOf( "display" );			
			if( displayIndex >= 0 ){
				displayFiles();
			}
			complete(cmdComplete, cmdCompleteArgs);
		}
		private static var internCmdComplete:Function;
		
		public static function clearMobileFolder () :void
		{
			if( CTOptions.mobileProjectFolderName != "ask" )
			{
				var fi:File = CTOptions.mobileParentFolder.resolvePath( CTOptions.mobileProjectFolderName );
				
				if( fi.exists && fi.isDirectory)
				{
					// Delete Folder...
					var fls:Array = fi.getDirectoryListing();
					var file3:File;
					for(var i:int=0; i<fls.length; i++) {
						file3 = File( fls[i] );
						if( file3.isDirectory ) {
							file3.deleteDirectory(true);
						}else{
							file3.deleteFile();
						}
					}
					fi.deleteDirectory(true);
					if( CTOptions.debugOutput ) Console.log("Mobile Project Dir Deleted..");
				}
			}
		}
		
		public static function hashBytes (b:ByteArray) :String {
			var r:String;
			var rv:ByteArray;
			switch (CTOptions.hashCompareAlgorithm) {
				case "sha224":
					r = SHA224.hashBytes( b );
					break;
				case "sha256":
					r = SHA256.hashBytes( b );
					break;
				default:
					r = MD5.hashBytes( b );
					break;
			}
			return r;
		}
		public static function hash (s:String) :String {
			var r:String;
			var b:ByteArray;
			var rv:ByteArray;
			switch (CTOptions.hashCompareAlgorithm) {
				case "sha224":
					r = SHA224.hash( s );
					break;
				case "sha256":
					r = SHA256.hash( s );
					break;
				default:
					r = MD5.hash( s );
					break;
			}
			return r;
		}
		
		private static function setNewPassword () :void {
			Application.instance.cmd( 'CTTools new-password');
		}
		private static function storePwd (pwd:String) :void {
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			if( sh ) {
				if( sh.data ) {
					sh.data.userPwd = pwd;
					sh.flush();
				}
			}
		}
		
		private static function onNewPwdSet (e:Event, r:Resource ) :void {
			
			var result:String = "";
			try {
				result = String(r.obj) || "";
			}catch(e:Error) {
				result = "";
			}
			var win:Window;
			
			var err:String = "";
			if( result == null ) {
				err = "No Network Connection";
			} else if( result == "no-pass" ) {
				// Error wrong old password...
				Console.log( "Can not set new password, Wrong password sent..");
				err = "Wrong Password";
			}else if( result == "ok" ) {
				Console.log("Password set..");
				win = Window( Application.instance.window.InfoWindow( "Password Changed", Language.getKeyword("Password Changed"), TemplateTools.obj2Text( Language.getKeyword("CT-PasswordChanged-MSG") ), {
				complete: onPwdChanged,
				continueLabel:Language.getKeyword( "Password Changed OK" ),
				allowCancel: false,
				autoWidth:false,
				autoHeight:true
				}, 'password-changed-window') );
				
			Application.instance.windows.addChild( win );	
			}else{
				// Error setting new Password
				Console.log("Error while setting new password");
				err = "Unknown Error";
			}
			
			if( err != "" ) {
				win = Window( Application.instance.window.InfoWindow( "Set Password Error", Language.getKeyword("Set Password Error"), TemplateTools.obj2Text( Language.getKeyword("CT-PasswordError-MSG") + " \n" + err ), {
				complete: onPwdError,
				continueLabel:Language.getKeyword( "Try Again?" ),
				allowCancel: true,
				autoWidth:false,
				autoHeight:true,
				cancelLabel: Language.getKeyword( "Password Error Cancel" )
				}, 'password-error-window') );
			}
		}
		
		private static function onPwdChanged (b:Boolean=false) :void {}
		
		private static function onPwdError (b:Boolean=false) :void {
			if( b ) {
				Application.instance.cmd( "CTTools reset-password" );
				Application.instance.cmd( "CTTools new-password" );
			}
		}
		private static function sendNewPwd (hs:String) :void {
			var res:Resource = new Resource();
			var vars:URLVariables = new URLVariables();
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			var pwd:String="";
			if( sh ) {
				if( sh.data && sh.data.userPwd != undefined ) {
					pwd = sh.data.userPwd;
				}
			}
			vars.newpwd = hs;
			vars.pwd = pwd;
			res.load( CTOptions.uploadScript, true, onNewPwdSet, vars);
		}
		
		private static function resetPwd () :void {
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			if( sh && sh.data && sh.data.userPwd != undefined ) {
				delete sh.data.userPwd;
				sh.flush();
			}
		}
		
		public static function clearFiles () :void {
			if( procFiles ) createFileArrays();
			projectDir = "";
			db = null;
			activeTemplate = null;
			subTemplates = new Vector.<Template>();
			currFile = -1;
			pages=[];
			articlePages=[];
			pageItems=[];
			pageTable={};
			articlePageTable={};
			pageItemTable={};
			templateConstants={};
			saveAsFirst = false;
			saveDirty = false;
			
			articlePages = [];
			articlePageTable = {};
			
			Template.randoms = {};
		}
		public static var showRequireSaveHandler:Function;
		
		private static var airHttpServer:HttpServer;
		
		private static function httpServerError ( err:*, msg:* ):void {
			Console.log("Error: " + msg);
		}
		
		public static var server:HttpServer;
		private static var webroot:File;
		
		private static function runServer () :void
		{
			var dcr:String =  projectDir + "/" + CTOptions.previewFolder;
			
			if ( !server || server.docRoot != dcr ) {
				server = null;
				webroot = new File(dcr);
				server = new HttpServer( webroot );
			}
			
			if ( !server.isConnected ) {
				server.listen( CTOptions.httpServerPort, httpServerError );
			}
			
			Console.log("HttpServer Listening on port "+CTOptions.httpServerPort+", www-root: " + webroot.url);
		}
		private static function onNeedBPSave () : void
		{
			if ( CTOptions.useHttpServer ) {
				runServer();
				Console.log("Preview with Server : " + server + " path: " + webroot.url + "/" + activeTemplate.indexFile );
				navigateToURL( new URLRequest("http://localhost:"+CTOptions.httpServerPort+"/" + activeTemplate.indexFile) );
			}
			else
			{
				// Local filesystem preview:
				var fil:File = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + activeTemplate.indexFile );
				
				// TODO.. Not supported on mobile..
				
				if(CTOptions.debugOutput) Console.log("Opening " + fil.url );
				fil.openWithDefaultApplication();
			}
		}
		
		private static function showRequireSaveDone () :void {
			if( typeof(showRequireSaveHandler) == "function" ) showRequireSaveHandler ();
		}
		
		private static function onRequireSave (bool:Boolean) :void {
			if( bool ) {
				Application.instance.cmd("CTTools save", showRequireSaveDone);
			}
		}
		
		public static function showRequireSave (onNeedSaveMsg:Function) :void
		{
			showRequireSaveHandler = onNeedSaveMsg;
			if( CTOptions.dontAskForSave ) {
				onRequireSave(true);
			}else{
				var win:Window = Window( Application.instance.window.InfoWindow( "RequireSaveWindow", Language.getKeyword("Require Save"), TemplateTools.obj2Text( Language.getKeyword("CT-RequireSave-MSG") ), {
					complete: onRequireSave,
					continueLabel:Language.getKeyword( "Require Save OK" ),
					allowCancel: true,
					autoWidth:false,
					autoHeight:true,
					cancelLabel: Language.getKeyword( "Require Save Cancel" )
					}, 'require-save-window') );
					
				Application.instance.windows.addChild( win );	
			}
		}
		public static function createFileArrays () :void {
			procFiles = [];
		}
		
		private static function displayFiles (curr:int=-1) :void
		{
			if(!saveAsFirst && ! CTTools.internDBCreateCmds)
			{
				var appViewType:String = Main( Application.instance ).view.panel.viewType;
				if( appViewType == "InstallView" ) return;
				if( appViewType != "HtmlView" ) {
					Application.command( "view HtmlView" );
				}
				if( curr >= 0 ) currFile = curr;
				try {
					Application.instance.view.panel.src.displayFiles();
				}catch(e:Error) {
					
				}
			}
		}
		
		public static function deleteFileAt ( i:uint ) :void {
			if( procFiles && procFiles.length > i) procFiles.splice( i, 1 );
			if( currFile > i && currFile > 0) currFile --;
			displayFiles();
		}
		public static function reorder (oldIndex:int, newIndex:int ) :void {
			if( !procFiles || procFiles.length <= 1 ) return;
			var file:ProjectFile = ProjectFile ( procFiles[ oldIndex ] );
			procFiles.splice( oldIndex, 1 );
			if( newIndex == -1 ) procFiles.push( file );
			else procFiles.splice( newIndex, 0, file );
		}
		
		public static function invalidateFiles () :void {
			if(procFiles)
			{
				saveDirty = true;
				Template.resetPrios();

				var L:int = procFiles.length;
				var pf:ProjectFile;
				for(var i:int=0; i<L; i++) {
					pf = ProjectFile(procFiles[i]);
					pf.allDirty();
				}
			}
		}
		public static function invalidateAndBuildFiles () :void {
			if(procFiles) {
				saveDirty = true;
				Template.resetPrios();
				
				var L:int = procFiles.length;
				var pf:ProjectFile;
				var text:String;
				for(var i:int=0; i<L; i++) {
					pf = ProjectFile(procFiles[i]);
					pf.allDirty();
					text = pf.getCompact();
				}
			}
		}
		public static function invalidateTemplateFiles (T:Template, build:Boolean=false) :void {
			if(procFiles) {
				saveDirty = true;
				Template.resetPrios();
				
				var L:int = procFiles.length;
				var pf:ProjectFile;
				var btext:String;
				for(var i:int=0; i<L; i++) {
					pf = ProjectFile(procFiles[i]);
					if ( pf.templateId == T.name ) {
						pf.allDirty();
						// TODO: invalidate only templates if required..
						// pf.contentDirty();
					}
					if(build) {
						btext = pf.getCompact();
					}
				}
			}
		}
		
		public static function invalidateArea ( name:String ) :void {
			if(procFiles)
			{
				saveDirty = true;
				
				var L:int = procFiles.length;
				var j:int;
				var L2:int;
				var pf:ProjectFile;
				
				for(var i:int=0; i<L; i++) {
					pf = ProjectFile(procFiles[i]);
					if( pf.templateAreas ) {
						L2 = pf.templateAreas.length;
						for( j=0; j<L2; j++) {
							if ( pf.templateAreas[j].name == name || pf.templateAreas[j].link == name ) {
								pf.contentDirty();
								//break;
							}
						}
					}
				}
				
			}
		}
		// copy files of src-folder to dst_folder
		public static function copyFolder ( src_url:String, dst_url:String ) :Boolean
		{
			var dir:File = new File( src_url );
			var pf:File= new File( dst_url );
			
			
			if( dir.exists  && dir.isDirectory )
			{
				if ( !pf.exists ) pf.createDirectory();
			
				// Copy files to dst
				var fs:Array = dir.getDirectoryListing();
				var f:File;
				var L:int = fs.length;
				for (var i:int=0; i<L; i++) {
					f = fs[i];
					if( f.name.charAt(0) != "." )
					{
						if( f.isDirectory ) {
							copyFolder( f.url, pf.resolvePath(f.name).url );
						}else{
							var destUrl:String = pf.resolvePath( f.name).url;
							CTTools.copyFile( f.url, destUrl );
						}
					}
				}
				return true;
			}
			return false;
		}
		
		
		public static function parseFilePath (s:String) :String
		{
			var t:String = s.substring(0, 5);
			
			if( t == "ico:/" )
			{
				return "app:/" + Options.iconDir + CTOptions.urlSeparator + s.substring(5);
			}
			else if( t == "prj:/" ) 
			{
				return CTTools.projectDir + CTOptions.urlSeparator + s.substring(5);
			}
			else if( t == "templ" ) 
			{
				if( s.substring(0, 10) == "template:/" ) 
				{
					return CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + s.substring(10);
				}
			}
			return s;	
		}
		
		private static var binaryWriteComplete:Object = {};
		
		public static function onLoadHttpFile ( r:Resource ) :void
		{
			writeBinaryFile( r.udfData.dst_url, ByteArray( r.obj ) );
			
			if( typeof(binaryWriteComplete[ r.udfData.dst_url ]) == "function" ) {
				binaryWriteComplete[ r.udfData.dst_url ]();
				binaryWriteComplete[ r.udfData.dst_url ] = null;
			}
		}
		
		public static function copyFile ( src_url:String, dst_url:String, complete:Function=null ) :Boolean
		{
			if( src_url.substring(0,7) == "http://" || src_url.substring(0,8)=="https://" ) {
				var rm:ResourceMgr = ResourceMgr.getInstance();
				var rid:int = rm.loadResource( src_url, onLoadHttpFile, true, true);
				
				var r:Resource = rm.getResourceById( rid );
				if( r ) {
					r.udfData.dst_url = dst_url;
					if( complete != null ) {
						binaryWriteComplete[dst_url] = complete;
					}
					return true;
				}else{
					
				}
			}else{
				var src:File = new File( src_url );
				var dst:File = new File( dst_url );
				if( src.exists ) {
					var destination:FileReference = dst;
					src.copyTo(destination, true);
					return true;
				}
			}
			return false;
		
		}
		public static function writeTextFile ( path:String, text:String ) :Boolean {
			var p:File = new File(path);
			var d:FileStream = new FileStream();
			try {
				d.open( p, FileMode.WRITE );
				d.writeMultiByte( text, CTOptions.charset);
				d.close();
				return true;
			}catch(e:Error) {
				Console.log( "Write Text File Error: " + e);
			}
			return false;
		}
		public static function writeBinaryFile ( path:String, content:ByteArray ) :Boolean {
			var p:File = new File(path);
			var d:FileStream = new FileStream();
			try {
				content.position = 0;
				d.endian = content.endian;
				d.open( p, FileMode.WRITE );
				d.writeBytes( content );
				d.close();
				return true;
			}catch(e:Error) {
				Console.log( "Write Binaty File Error: " + e);
			}
			return false;
		}
		
		public static function readTextFile ( path:String ) :String {
			try {
				var file:File = new File( path );
				if( file.exists ) {
					var fileStream:FileStream = new FileStream();
					fileStream.open(file, FileMode.READ);
					var str:String = fileStream.readMultiByte(file.size, CTOptions.charset);
					fileStream.close();
					return str;
				}
			}catch(e:Error) {
				Console.log( "Error reading '" + path + "': " + e.message);
			}
			return "";
		}
		
		// propNames: name, path, sqlUid
		public static function findTemplate( key:String, propName:String="name") :Template {
			if( activeTemplate && activeTemplate[propName] == key ) return activeTemplate;
			if( subTemplates ) {
				var L:int = subTemplates.length;
				for(var i:int = 0; i<L; i++) {
					if( subTemplates[i][propName] == key ) {
						return subTemplates[i];
					}
				}
			}
			return null;
		}
		public static function projFileBy (url:String, prop:String="path"): int {
			if (procFiles) {
				for (var i:int = procFiles.length-1; i>=0; i--) {
					if(procFiles[i][prop] == url) {
						return i;
					}
				}
			}
			return -1;
		}
		private static var addFileComplete:Function;
		
		// Open File Browser
		public static function addFiles (completeHandler:Function=null) :void {
			if( !procFiles ) createFileArrays();
			// Get Files from User
			var docsDir:File = File.documentsDirectory;
			try {
				docsDir.browseForOpenMultiple("Select Files");
				addFileComplete = completeHandler;
				docsDir.addEventListener(FileListEvent.SELECT_MULTIPLE, filesSelected);
			}catch (error:Error){
				Console.log(error.message);
			}
		}
		
		public static function addFile ( _file:*, tmpl:Template=null ) :void {
			if ( tmpl == null ) tmpl = activeTemplate;
			if( !tmpl ) {
				Console.log("Error: No Root Template loaded.");
				return;
			}
			if(!procFiles) createFileArrays();
			var file:File;
			if( _file is String ) {
				// TODO test for http: https: ftp: file: etc
				file = new File(_file);
			}else if( _file is File ) {
				file = File(_file);
			}else{
				return;
			}
			
			if(file.exists) {
				var str:String = readTextFile( file.url );
				var pf:ProjectFile = new ProjectFile( tmpl.name );
				pf.setUrl( file.url );
				pf.setTemplate(str);
				pf.allDirty();
				procFiles.push( pf );
			}else{
				Console.log("File: " + _file + " Does Not Exist");
			}
		}
		
		// File browser handler
		private static function filesSelected (event:FileListEvent) :void {
			for (var i:uint = 0; i < event.files.length; i++) {
				addFile( event.files[i].url);
			}
			if ( addFileComplete != null ) addFileComplete ();
			displayFiles();
		}
		
		public static function webFileName ( filename:String, obj:Object ) :String
		{
			var d:Date = new Date();
			obj.extension = "";
			var pid:int = filename.lastIndexOf(".");
			if( pid >= 0 ) obj.extension = filename.substring(pid+1);
			
			obj.year = d.fullYear;
			obj.month = d.month+1;
			obj.day = d.day;
			obj.date = d.date;
			obj.hours = d.hours;
			obj.minutes = d.minutes;
			obj.seconds = d.seconds;
			obj.milliseconds = d.milliseconds;
			obj.time = d.time;
			obj.timezoneOffset = d.timezoneOffset;
			
			return TemplateTools.obj2Text ( filename, "#", obj );
		}
		
		public static function softKeyboardChange (e:SoftKeyboardEvent) :void
		{
			var ctm:CTMain = CTMain(Application.instance);
			
			if( ctm.stage && ctm.stage.softKeyboardRect.width == 0 || ctm.stage.softKeyboardRect.height == 0 )
			{
				// deactivate
				ctm.setSize( ctm.stage.stageWidth, ctm.stage.stageHeight );
			}
			else
			{
				var h:int = ctm.stage.softKeyboardRect.y - ctm.mainMenu.cssSizeY;
				ctm.setSize( ctm.stage.stageWidth, h );
				
				try {
					Object(ctm.view.panel.src).newSize(null);
				}catch(e:Error) {
					Console.log("Error setting SoftKeyboard Size");
				}
				
			}
		}
		
		public static function prepare (_app:Sprite) :void {
			activeTemplate = new Template("root");
		}
		
		public static function changeStyle ( name:String, styles:Object ) :void {
			if( Application.instance.config ) {
				Application.instance.config.setStyle( name, styles );
				Application.instance.config.parseCSS( Application.instance.config );
			}
		}
	}
}