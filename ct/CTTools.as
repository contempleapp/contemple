package ct
{
	import agf.Main;
	import agf.Options;
	import agf.tools.*;
	import agf.icons.IconBoolean;
	import agf.icons.IconLoading;
	import agf.ui.*;
	import agf.events.*;
	import agf.html.*;
	import agf.db.*;
	import agf.io.*;
	import agf.db.DBResult;
	import agf.utils.StringMath;
	import agf.utils.FileInfo;
	import agf.utils.FileUtils;
	import com.airhttp.FileController;
	import com.airhttp.HttpServer;
	import ct.ctrl.InputTextBox;
	import ct.ctrl.CommandEditor;
	import ct.ctrl.DownloadOverview;
	import ct.ctrl.DownloadInfo;
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
	import flash.system.*;

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
		public static var projectDir:String = "-1";
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
		
		public static function clearFiles () :void {
			if( procFiles ) createFileArrays();
			articleProcFiles = null;
			projectDir = "";
			db = null;
			activeTemplate = null;
			subTemplates = new Vector.<Template>();
			currFile = -1;
			currentArea = "";
			internPageItem=null;
			internSubTempl=null;
			pendingSQLQuerys=null;
			sqlQuerys=null;
			pages=[];
			articlePages=[];
			pageItems=[];
			pageTable={};
			articlePageTable={};
			pageItemTable={};
			templateConstants={};
			saveAsFirst = false;
			saveDirty = false;
			Template.randoms = {};
			if ( CTOptions.verboseMode ) Console.log("Data cleared");
		}
		
		// Load sqlite DB
		public static function loadDB ( file:String, dbtype:Class ) :void {
			db = new DBAL();
			db.useDB( file, dbtype );
			if ( CTOptions.verboseMode ) Console.log("DB Loaded");
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
			var pftmp:ProjectFile = pfTmp;
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
							pftmp.clear();
							pftmp.setUrl( pftxt.path );
							pftmp.templateId = T.name;
							pftmp.setTemplate( pftxt.template, pgitems[j].name, true );
							
							if( CTOptions.insertItemLocation && !T.nolocation ) { // Insert Anker Tags
								areatxt += CTOptions.insertItemPre + T.dbProps.name + CTOptions.insertItemPost;
							}
							areatxt += pftmp.getText();
							T.dbProps = tmpdbprops;
						}else{
							Console.log("Warning: Template File '" + filepath + "' Not Found");
						}
					}else{
						Console.log("Warning: Template '" + stName + "' Not Found");
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
		
		private static function delSTHandler (res:DBResult) :void
		{
			if( reloadSubTItems && reloadSubTItems.length > 0 ) {
				loadSubTemplate( reloadSubTPath, reloadSubTStoreItems);
			}else{
				loadSubTemplate( reloadSubTPath, reloadSubTCompleteHandler);
			}
		}
		
		private static function reloadNextSubTItem (s:Boolean=false) :void {
			if( reloadSubTCurrItem >= reloadSubTItems.length ) {
				reloadSubTItems = null;
				if( typeof( reloadSubTCompleteHandler ) == "function" ) {
					reloadSubTCompleteHandler(null);
				}
			}
			else
			{
				var item:Object = reloadSubTItems[ reloadSubTCurrItem ];
				
				var extValues:Object = {};
				for( var nm:String in item ) {
					if( nm != "name" && nm != "visible" && nm != "subtemplate" && nm != "area" && nm != "sortid" && nm != "crdate" ) {
						extValues[nm] = item[nm];
					}
				}
				if( pageItems ) pageItems.push( item );
				
				reloadSubTCurrItem ++;
				insertPageItem( reloadNextSubTItem, 
								item.name,
								item.visible || "true",
								item.subtemplate,
								item.area,
								item.sortid, 
								"now",
								extValues );
			}
				
		}
		
		private static function reloadSubTStoreItems (res:DBResult=null) :void
		{
			reloadSubTCurrItem = 0;
			reloadNextSubTItem ();
		}
		
		private static function delTblHandler (res:DBResult) :void
		{
			var pms:Object = {};
			pms[":nam"] = reloadSubTName;
			
			var dv:Boolean = db.deleteQuery (delSTHandler, "template", "name=:nam", pms)
			
			if(!dv) {
				Console.log("Error: Can Not Delete Subtemplate: " + reloadSubTName );
				delSTHandler(null);
			}
		}
		
		private static var reloadSubTCurrItem:int;
		private static var reloadSubTItems:Array;
		private static var reloadSubTName:String;
		private static var reloadSubTPath:String;
		private static var reloadSubTCompleteHandler:Function;
		
		public static function loadPlugin ( name:String, file:String ) :void
		{
			Application.instance.loadPlugin(name, parseFilePath(file) );
		}
		
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
					
					if( CTTools.internDBCreateCmds || CTOptions.debugOutput ) Console.log("Load Subtemplate " + nam );
				
				}else{
					// reload and delete sql tables from subtemplate
					if( st.tables != "" )
					{
						reloadSubTName = nam;
						reloadSubTPath = path;
						reloadSubTCompleteHandler = completeHandler;
						var stid:int = CTTools.subTemplates.indexOf(st);
						
						if( stid >= 0 ) {
							CTTools.subTemplates.splice(stid, 1);
						}
						
						reloadSubTItems = null;
						
						var tmp:Object;
						
						if( pageItems && pageItems.length > 0 )
						{
							reloadSubTItems = [];
							for( var i:int = pageItems.length-1; i>=0; i-- )
							{
								if( pageItems[i].subtemplate == nam ) {
									tmp = pageItems[i];
									pageItems.splice( i, 1);
									reloadSubTItems.push( tmp );
								}
							}
						}
						
						var dv:Boolean = db.query( delTblHandler, "DROP TABLE " + st.tables, {});
						
						if(!dv) {
							if( CTTools.internDBCreateCmds || CTOptions.debugOutput ) Console.log( "Error: No subtemplate table found " + nam  + ": " + st.tables );
							loadSubTemplate( reloadSubTPath, reloadSubTCompleteHandler);
						}else{
							if( CTTools.internDBCreateCmds || CTOptions.debugOutput ) Console.log("Subtemplate " + nam  + " cleared");
						}
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
					if ( internSubTempl.indexStr != null ) {
						if ( CTOptions.verboseMode ) Console.log("Write Index File " +  internSubTempl.name + CTOptions.urlSeparator + CTOptions.templateIndexFile );
						// write template index file to subtemplate dir
						if(!writeTextFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + CTOptions.templateIndexFile ,
										internSubTempl.indexStr ) ) {
											Console.log("Error: Subtemplate Index File Write Error " + internSubTempl.name );
										}
					}else{
						Console.log("Error: Subtemplate Index File Error " + internSubTempl.name );
					}
					
					var i:int;
					var L:int;
					
					if( internSubTempl.staticfiles ) {
						
						var src:File;
						var dst:File;
						var sourceFile:FileReference;
						var destination:FileReference;
						
						var folders:Array = internSubTempl.staticfiles.split(",");
						L=folders.length;
						
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log( "Copy " + L + " Static Files " + folders);
						
						for(i=0; i<L; i++)
						{
							src = new File( internSubTempl.genericPath + CTOptions.urlSeparator + folders[i] );
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + folders[i] );
							destination = dst;
							src.copyTo(destination, true)
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + folders[i] );
							destination = dst;
							src.copyTo(destination, true);
						}
					}
					
					// Copy Template Files to project folder
					if( internSubTempl.folders )
					{
						folders = internSubTempl.folders.split(",");
						L = folders.length;
						if(CTOptions.debugOutput || CTOptions.verboseMode) Console.log( "Copy " + L + " Directories " + folders);
						for(i=0; i<L; i++) {
							src = new File( internSubTempl.genericPath + CTOptions.urlSeparator + folders[i] );
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + folders[i] );
							
							if( !dst.exists ) {
								destination = dst;
								src.copyTo(destination, true)
							}
								
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + folders[i] );
							
							if( !dst.exists ) {
								destination = dst;
								src.copyTo(destination, true);
							}
						}
					}
					
					// Copy Template folders to subtemplate folder
					if( internSubTempl.templatefolders ) {
						folders = internSubTempl.templatefolders.split(",");
						L=folders.length;
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy " + L + " Template-Folders " + folders);
						for(i=0; i<L; i++) {
							src = new File( internSubTempl.genericPath + CTOptions.urlSeparator + folders[i] );
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + 
											CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + folders[i] );
							if( !dst.exists ) {
								destination = dst;    
								src.copyTo(destination, true);
							}
						}
					}
					
					// Copy Page templates to project folder
					if( internSubTempl.pagetemplates ) {
						folders = internSubTempl.pagetemplates.split(",");
						L=folders.length;
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy " + L + " Page Templates " + folders);
						for(i=0; i<L; i++) {
							src = new File( internSubTempl.genericPath + CTOptions.urlSeparator + folders[i] );
							dst = new File( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + 
											CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + folders[i] );
							destination = dst;    
							src.copyTo(destination, true)
						}
					}
					
					// copy help file to subtemplate project dir 
					if ( internSubTempl.help && internSubTempl.help != "" ) {
						if ( CTOptions.verboseMode ) Console.log("Copy Help File " + internSubTempl.help );
						if(!copyFile(  internSubTempl.genericPath + CTOptions.urlSeparator + internSubTempl.help, 
									projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + internSubTempl.help) ) {
										Console.log("Error: Subtemplate Help File Copy Error " + internSubTempl.help );
									}
					}
					
					var pth:String;
					
					// copy embedscripts:
					if( internSubTempl.jsfiles ) {
						L = internSubTempl.jsfiles.length;
						if( L > 0 )
						{
							if (CTOptions.debugOutput ||  CTOptions.verboseMode) Console.log("Copy " + L + " JS Files " + internSubTempl.jsfiles );
							
							for(i=0; i<L; i++)
							{
								pth = internSubTempl.jsfiles[i].src;
								
								if(!copyFile( internSubTempl.genericPath + CTOptions.urlSeparator + pth, 
									projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + pth)) {
										Console.log("Error: Subtemplate Embed JS File Copy Error " + internSubTempl.name + ": " + pth );
									}
							}
							
						}
					}
					// copy embedstyles
					if( internSubTempl.cssfiles ) {
						L = internSubTempl.cssfiles.length;
						if( L > 0 )
						{
							if (CTOptions.debugOutput ||  CTOptions.verboseMode) Console.log("Copy " + L + " CSS Files " + internSubTempl.cssfiles );
							
							for(i=0; i<L; i++)
							{
								pth = internSubTempl.cssfiles[i].src;
								
								if(!copyFile( internSubTempl.genericPath + CTOptions.urlSeparator + pth, 
									projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + pth)) {
										Console.log("Error: Subtemplate Embed CSS File Copy Error " + internSubTempl.name + ": " + pth );
									}
							}
						}
					}
					if ( internSubTempl.articlepage )
					{
						if (CTOptions.debugOutput ||  CTOptions.verboseMode) Console.log("Copy Article Page Template " + internSubTempl.articlepage + ", Articlename: " + internSubTempl.articlename );
							
						if(!copyFile( internSubTempl.genericPath + CTOptions.urlSeparator +  internSubTempl.articlepage, 
							projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + 
							internSubTempl.name + CTOptions.urlSeparator + internSubTempl.articlepage )) {
								Console.log("Error: Subtemplate Article Page Copy Error " + internSubTempl.name + ": " + internSubTempl.articlepage );
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
						if ( CTOptions.verboseMode ) Console.log( "Run Insert Query " +  xo.template.@initquery.toString() );
						if( sql ) {
							sql = TemplateTools.replaceNewlines( sql );
							
							if( !writeTextFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + xo.template.@initquery.toString(),
												sql )) 
							{
								Console.log("Error: Subtemplate Initquery Write error " + xo.template.@initquery.toString() );
							}else{
								execSql(sql, onInsertSubTQuery);
								return;
							}
						}
					}else{
						
						if( xo.template.@fields && xo.template.@fields != ""  )
						{
							if ( CTOptions.verboseMode ) Console.log( "Build Insert Query " + xo.template.@name.toString() );
							
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
						
						if ( CTOptions.verboseMode ) Console.log( "Run Content Query " + xo.template.@defaultquery.toString() );
						
						if( !writeTextFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTempl.name + CTOptions.urlSeparator + xo.template.@defaultquery.toString(),
											sql )) 
						{
							Console.log("Error: Subtemplate Defaultquery Write Error " + xo.template.@defaultquery.toString() );
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
				if( txo.template.@version != undefined && txo.template.@version != "") tmpl.version = txo.template.@version.toString();
				
				if( txo.template.@type != undefined && txo.template.@type != "") tmpl.type = txo.template.@type.toString();
				if( txo.template.@sortproperties != undefined  && txo.template.@sortproperties != "") tmpl.sortproperties = txo.template.@sortproperties.toString();
				if( txo.template.@help != undefined  && txo.template.@help != "") {
					tmpl.help = txo.template.@help.toString();
					if( internDBCreateCmds && CTOptions.debugOutput || CTOptions.verboseMode ) Console.log("Load Help File: " +  path + CTOptions.urlSeparator + tmpl.help); // Log while installing
					loadHelpFile( path + CTOptions.urlSeparator + tmpl.help, tmpl.name );
				}
				if( txo.template.@dbcmds != undefined  && txo.template.@dbcmds != "") tmpl.dbcmds = txo.template.@dbcmds.toString();
				if( txo.template.@section != undefined  && txo.template.@section != "") tmpl.section = txo.template.@section.toString();
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
					if ( CTOptions.verboseMode ) Console.log( "Load Index File " + tmpl.indexFile );
					
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
					if ( L > 0 && CTOptions.verboseMode ) Console.log( "Load " + L + " Template Files: " +  filenames );
					
					for(i=0; i<L; i++) {
						if ( filenames[i] && filenames[i] != " " )
						{
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
					if (L > 0 && CTOptions.verboseMode ) Console.log( "Load " + L + " Embed Scripts: " + scr );
					
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
					
					if ( L > 0 && CTOptions.verboseMode ) Console.log( "Load " + L + " Embed Stylesheets: " + scr );
					
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
				try
				{
					if ( CTOptions.verboseMode ) Console.log( "Load Help File " + path );
					
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
				if ( CTOptions.verboseMode ) Console.log( "Load Root Template " + loadTemplate__FolderName );
					
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
				
				if ( CTOptions.verboseMode ) Console.log( "Generic Path: " + path );
				
				clearFiles ();
				
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
						installProgress.showPercentValue = false;
					}
				}
				
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
					Console.log("´Error No Template Index File Found: '" + CTOptions.templateIndexFile +"'  In: " + path);
					Application.instance.window.InfoWindow( "TmplLoadError", Language.getKeyword("Error"), Language.getKeyword("Template-Load-Error"), { allowCancel: false, autoHeight:true}, '' );
				}
				else
				{
					if ( CTOptions.verboseMode ) Console.log( "Template OK" );
					
					saveFirstHandler(true);
				}
			}
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
					if( !sh.data.templates) {
						sh.data.templates = [];
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
				if( txo.template.@defaultcontent != undefined && txo.template.@defaultcontent != "") activeTemplate.defaultcontent = txo.template.@defaultcontent.toString();
				
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
				
				//if( txo.template.@imgdir != undefined  && txo.template.@imgdir != "") activeTemplate.imgdir = txo.template.@imgdir.toString();
				
				if ( txo.template.@index != undefined  && txo.template.@index != "") {
					
					activeTemplate.indexFile = txo.template.@index.toString();
					if ( CTOptions.verboseMode ) Console.log( "Index File: " + activeTemplate.indexFile );
					addFile( path + CTOptions.urlSeparator + activeTemplate.indexFile );
				}
				if( txo.template.@files != undefined  && txo.template.@files != "") {
					activeTemplate.files = txo.template.@files.toString();
					var filenames:Array = activeTemplate.files.split(",");
					L = filenames.length;
					if ( CTOptions.verboseMode ) Console.log( "Add " + L + " Template Files: " + filenames );
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
				
				if ( CTOptions.verboseMode ) Console.log( "Select Root Template: " + activeTemplate.name );
				
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
				if(CTOptions.verboseMode) Console.log("Selected Active Template: " + activeTemplate.sqlUid );
			}else{
				var pm:Object = {};
				// Insert active template in db...
				pm[":name"] = activeTemplate.name;
				pm[":indexfile"] = activeTemplate.indexFile;
				saveAsFirst = true;
				if ( CTOptions.verboseMode ) Console.log( "Insert");
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
					if(CTOptions.debugOutput || CTOptions.verboseMode) Console.log( "Generic Path: " +  activeTemplate.genericPath);
					
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
						if(CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Files " + L + ": " + folders);
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
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Folders " + L + ": " + folders);
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
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Page Templates " + L + ": " + folders);
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
						if (CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Static Files " + L + ": " + folders);
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
					
					var s:String;
					
					if( activeTemplate.defaultcontent )
					{
						s = readTextFile( activeTemplate.genericPath + CTOptions.urlSeparator + activeTemplate.defaultcontent );
						// Write defaultcontent to template project dir
						if( !writeTextFile( projectDir + CTOptions.urlSeparator+CTOptions.projectFolderTemplate+CTOptions.urlSeparator + activeTemplate.defaultcontent, s) ) {
							Console.log( "Error: Write Template defaultcontent: " + activeTemplate.defaultcontent );
						}
					}
					
					if(installProgress) installProgress.value = 0.7;
					
					saveAsFirst = false;
					saveDirty = false;
					
					// Run DB-CREATE COMMANDS
					internDBCreateCmds = null;
					
					if( activeTemplate.dbcmds ) {
						s = readTextFile( activeTemplate.genericPath + CTOptions.urlSeparator + activeTemplate.dbcmds );
						
						if ( s )
						{
							if ( CTOptions.verboseMode ) Console.log( "Write db-cmds " + activeTemplate.dbcmds);
							
							// Write dbcmds to template project dir
							if( !writeTextFile(projectDir + CTOptions.urlSeparator+CTOptions.projectFolderTemplate+CTOptions.urlSeparator + activeTemplate.dbcmds, s) ) {
								Console.log( "Error: Write Template dbcmds: " + activeTemplate.dbcmds );
							}
							
							// Execute cmds
							try {
								var x:XML = new XML(s);
							}catch(e:Error) {
								Console.log("Error: Parse Command File: " + s);
							}
							if(x) {
								if( x.dbcreate ) {
									var xm:XMLList = x.dbcreate.cmd;
									if ( CTOptions.verboseMode ) Console.log("Run " + xm.length() + " dbcreate commands..");
									internDBCreateCmds = xm;
									internCurrDBCreate = 0;
								}
							}else{
								Console.log("Error: Parse Command File: " + s);
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
				if ( CTOptions.verboseMode ) Console.log( "Dbcmds Complete");
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
						Console.log("Error: Parse Command File: " + e);
					}
				}
			}
			if(xo) {
				if( xo[nam] ) {
					runCmd = xo[nam].cmd;
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
				
				if( activeTemplate.defaultcontent )
				{
					var win:Window = Window( Application.instance.window.GetBooleanWindow( "InstallDC", Language.getKeyword("Install default content"), Language.getKeyword("InstallDC-MSG"), {
					complete: dc_yn,
					continueLabel:Language.getKeyword( "InstallDC-MSG-Yes" ),
					allowCancel: true,
					autoWidth:false,
					autoHeight:true,
					cancelLabel: Language.getKeyword("InstallDC-MSG-Cancel")
					}, 'installdc-yn-window') );
					
					Application.instance.windows.addChild( win );
					
					return;
				}
				
				firstRestart();
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
		
		public static var overrideDC:Boolean = false; // TODO... Add Default Content to current DB 
		
		private static var dc_xml:XML;
		private static var dc_list:XMLList;
		private static var dc_curr:int;
		private static var dc_complete:Function;
		
		public static function dc_yn ( y:Boolean ) :void
		{			
			if( y ) {
				loadDefaultContent( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + activeTemplate.defaultcontent, firstRestart );
			}else{
				firstRestart();
			}
		}
		
		public static function loadDefaultContent ( filepath:String, complete:Function ) :void
		{			
			var s:String = readTextFile( filepath );
			
			dc_complete = complete;
			
			try
			{
				var x:XML = new XML(s);
				dc_xml = x;
				
				if( !overrideDC )
				{
					// clear all from pageitem..
					if( db ) {
						if( ! db.query( delExtTables, "DELETE FROM pageitem;" ) ) {
							Console.log("Error Delete Pageitem Table");
							delExtTables(null);
						}
					}
				}
				else
				{
					updateDCItems(null);
				}
			} catch( e:Error ) {
				Console.log("Error In Parse Default Content File: " + e); 
				dc_complete();
			}
		}
		private static function updateDCItems ( res:DBResult ) :void { // test if pageitem is in CTTools.pageItems only..
			
		}
		
		private static function delNextExtTable ( res:DBResult ) :void
		{
			if( dc_list && dc_list.length() > dc_curr )
			{
				var T:Template = findTemplate( dc_list[ dc_curr ].@name.toString(), "name");
				
				dc_curr++;
				
				if( db && T && T.tables )
				{
					if( ! db.query( delNextExtTable, "DELETE FROM " + T.tables +";") ) {
						Console.log( "Error Delete Extension Table: " + T.name + ": " + T.tables );
						delNextExtTable( null );
					}
				}
				else
				{
					delNextExtTable( null );
				}
			}
			else
			{
				delProps(null);
			}
		}
		
		private static function delExtTables ( res:DBResult ):void {
			if( dc_xml.tmpl ) {
				dc_list = dc_xml.tmpl;
				dc_curr = 0;
				delNextExtTable(null);
			}else{
				delProps(null);
			}
		}
		
		private static function delProps ( res:DBResult ) :void {
			if( ! db.query( delPages, "DELETE FROM tmplprop;" ) ) {
				Console.log( "Error Delete Property Table: ");
				delPages(null);
			}
		}
			
		private static function delPages ( res:DBResult ) :void {
			if( ! db.query( insertDCItems, "DELETE FROM page;" ) ) {
				Console.log( "Error Delete Property Table: ");
				insertDCItems(null);
			}
		}
		
		private static function insertDCItems ( res:DBResult ):void {
			if( dc_xml.item ){
				dc_list = dc_xml.item;
				dc_curr = 0;
				insertNextDCItem(true);
			}else{
				insertDCProps();
			}
		}
		
		private static function insertNextDCItem ( success:Boolean ) :void
		{
			if( dc_list && dc_list.length() > dc_curr )
			{
				var id:int = dc_curr;
				dc_curr++;
				
				var extValues:Object = {};
				
				var atts:XMLList = dc_list[ id ].attributes();
				var nm:String;

				for (var i:int = 0; i < atts.length(); i++){ 
					nm = atts[i].name().toString();
					if( nm != "name" && nm != "visible" && nm != "subtemplate" && nm != "area" && nm != "sortid" && nm != "crdate" ) {
						extValues[nm] = HtmlParser.toDBText( dc_list[ id ].attribute(nm).toString(), true, true );
					}
				}
							
				insertPageItem( insertNextDCItem, 
								dc_list[ id ].@name,
								dc_list[ id ].@visible || "true",
								dc_list[ id ].@subtemplate,
								dc_list[ id ].@area,
								dc_list[ id ].@sortid, 
								dc_list[ id ].@crdate || "now",
								extValues );
				
			}else{
				insertDCProps();
			}
		}
		
		private static function insertDCProps ():void
		{
			if( dc_xml.prop )
			{
				dc_list = dc_xml.prop;
				dc_curr = 0;
				insertNextDCProp( null );
			}
			else
			{
				insertDCPages();
			}
		}
		
		private static function insertNextDCProp ( res:DBResult ) :void
		{
			if( dc_list && dc_list.length() > dc_curr )
			{
				var id:int = dc_curr;
				dc_curr++;
				
				var tp:String = dc_list[ id ].@type == undefined ? "text" :  dc_list[ id ].@type.toString();
				var val:String =  dc_list[ id ].@value == undefined ? "" : dc_list[ id ].@value.toString();
				
				var pms:Object = {};
				pms[":name"] = dc_list[ id ].@name.toString();
				pms[":type"] = tp;
				pms[":value"] = val;
				pms[":section"] = dc_list[ id ].@section == undefined ? "" : dc_list[ id ].@section.toString();
				pms[":templateid"] = dc_list[ id ].@templateid == undefined ? "0" : dc_list[ id ].@templateid.toString();
				
				if( ! CTTools.db.insertQuery( insertNextDCProp, "tmplprop", 'name,section,type,value,templateid',':name,:section,:type,:value,:templateid', pms)) {
					Console.log( "Error: INSERT Statement Failed On Template Properties Table " + pms[":name"] + ", " + pms[":type"] );
					insertNextDCProp(null);
				}
			}else{
				insertDCPages();
			}
		}
		
		private static function insertDCPages ():void
		{
			if( dc_xml.page )
			{
				dc_list = dc_xml.page;
				dc_curr = -1;
				insertNextDCPage();
			}
			else
			{
				dc_complete();
			}
		}
		
		private static function insertPageComplete ( res:DBResult ) :void
		{
			if( dc_list && dc_list.length() > dc_curr )
			{
				var id:int = dc_curr;
				
				var name:String = dc_list[ id ].@name.toString();
				var visible:String = dc_list[ id ].@visible == undefined ? "true" :  dc_list[ id ].@visible.toString();
				var title:String = dc_list[ id ].@title == undefined ? "" :  dc_list[ id ].@title.toString();
				var type:String = dc_list[ id ].@type == undefined ? "" :  dc_list[ id ].@type.toString();
				var template:String = dc_list[ id ].@template == undefined ? "" : dc_list[ id ].@template.toString();
				var parent:String = dc_list[ id ].@parent == undefined ? "" : dc_list[ id ].@parent.toString();
				var webdir:String = dc_list[ id ].@webdir == undefined ? "" : dc_list[ id ].@webdir.toString();
				var filename:String = dc_list[ id ].@filename == undefined ? "" : dc_list[ id ].@filename.toString();
				var crdate:String = dc_list[ id ].@crdate == undefined ? "now" : dc_list[ id ].@crdate.toString();
				
				PageEditor.createPage ( name, CssUtils.stringToBool( visible ), title, type, template, parent, webdir, crdate, insertNextDCPage, null, null, null );
			}
		}
		
		private static function insertNextDCPage( success:Boolean=false ) :void
		{
			if( dc_list && dc_list.length() > dc_curr+1 )
			{
				var id:int = dc_curr;
				dc_curr++;
				
				var pms:Object = {};
				pms[":name"] = dc_list[ id ].@name.toString();
				pms[":visible"] = dc_list[ id ].@visible == undefined ? "true" :  dc_list[ id ].@visible.toString();
				pms[":title"] = dc_list[ id ].@title == undefined ? "" :  dc_list[ id ].@title.toString();
				pms[":type"] = dc_list[ id ].@type == undefined ? "" :  dc_list[ id ].@type.toString();
				pms[":template"] = dc_list[ id ].@template == undefined ? "" : dc_list[ id ].@template.toString();
				pms[":parent"] = dc_list[ id ].@parent == undefined ? "" : dc_list[ id ].@parent.toString();
				pms[":webdir"] = dc_list[ id ].@webdir == undefined ? "" : dc_list[ id ].@webdir.toString();
				pms[":filename"] = dc_list[ id ].@filename == undefined ? "" : dc_list[ id ].@filename.toString();
				pms[":crdate"] = dc_list[ id ].@crdate == undefined ? "now" : dc_list[ id ].@crdate.toString();
				
				if( ! CTTools.db.insertQuery( insertPageComplete, "page", 'name,visible,title,type,template,parent,webdir,filename,crdate',':name,:visible,:title,:type,:template,:parent,:webdir,:filename,:crdate', pms)) {
					Console.log( "Error: INSERT Statement Failed On Page " + pms[":name"] + ", " + pms[":type"] );
					insertNextDCPage();
				}
			}else{
				Console.log("Default content added..");
				dc_complete();
			}
		}
		
		private static var newPageItemTmp:Object;
		private static var extPageItemTmp:Object;
		private static var insertPageItemComplete:Function;  // args: success:Boolean
		
		public static function insertPageItem ( complete:Function, name:String, visible:String, subtemplate:String, area:String, sortid:String, crdate:String, extValues:Object ) :void
		{
			insertPageItemComplete = complete;
			
			var pms:Object = {};
			pms[":nam"] = name;
			pms[":vis"] = visible;
			pms[":tmpl"] = subtemplate;
			pms[":ara"] = area;
			pms[":sortid"] = sortid;
			pms[":date"] =  crdate;
			
			newPageItemTmp = { uid:-1, name: pms[":nam"], area: pms[":ara"], sortid: pms[":sortid"], subtemplate: pms[":tmpl"], crdate: pms[":date"] };
			
			if( extValues ) {
				// copy extension fields to intern db item
				for( var aname:String in extValues ) {
					newPageItemTmp[ aname ] = extValues[ aname ];
				}
				extPageItemTmp = extValues;
			}else{
				extPageItemTmp = null;
			}
			
			var rv:Boolean = CTTools.db.insertQuery( onPageItemInsert, "pageitem", "name,visible,area,sortid,subtemplate,crdate", ":nam,:vis,:ara,:sortid,:tmpl,:date", pms);
			
			if(!rv) { 
				Console.log("ERROR Insert Page Item " + pms[":nam"]);
				if( typeof(insertPageItemComplete) == "function" ) insertPageItemComplete( false );
			}
		}
		
		private static function onPageItemInsert  (res:DBResult) :void
		{
			if (res && res.rowsAffected > 0) 
			{
				if( newPageItemTmp && extPageItemTmp )
				{
					newPageItemTmp.uid = res.lastInsertRowID;
					
					var T:Template = findTemplate( newPageItemTmp.subtemplate, "name" );
					
					if( T && T.tables && T.fields )
					{
						var i:int;
						var L:int;
						var fieldVal:String = ":_name";
						var fields:Array = T.fields.split(",");
						var pms:Object = {};
						pms[":_name"] = newPageItemTmp.name;
						
						L = fields.length;
						for (i = 0; i < L; i++) 
						{
							if( fields[i] == "crdate")
							{
								pms[ ":_crdate" ] = "now";
								fieldVal += ",:_crdate";
							}
							else if( fields[i] != "name")
							{
								//pms[ ":_"+ fields[i] ] = extPageItemTmp[fields[i]] ? HtmlParser.toDBText( extPageItemTmp[fields[i]], false, true ) : "";
								pms[ ":_"+ fields[i] ] = extPageItemTmp[fields[i]] ? /*HtmlParser.toInputText(*/extPageItemTmp[fields[i]]/*)*/ : "";
								fieldVal += ",:_" +  fields[i];
							}
						}
						
						var rv:Boolean = CTTools.db.insertQuery( onInsertExTable, T.tables, T.fields, fieldVal, pms );
						
						if(!rv) {
							Console.log("ERROR Insert Item Extension Table " + pms[":_name"]);
							if( typeof(insertPageItemComplete) == "function" ) insertPageItemComplete( false );
						}
					}
				}
			}
		}
		
		private static function onInsertExTable  (res:DBResult) :void {
			if(res && res.rowsAffected ) {
				newPageItemTmp.ext_uid = res.lastInsertRowID;
				if( typeof(insertPageItemComplete) == "function" ) insertPageItemComplete( true );
			}else{
				if( typeof(insertPageItemComplete) == "function" ) insertPageItemComplete( false );
			}
		}
		
		private static function onSyncInfo ( e:Event, r:Resource ) :void
		{			
			if( r.loaded == 1 ) {
				var hubsyncversion:String;
				
				try {
					hubsyncversion = String(r.obj) || "";
				}catch(e:Error) {
					hubsyncversion = "";
				}
				
				Console.log( "Hub Sync Version: " + hubsyncversion );
				
				if ( hubsyncversion != "" && hubsyncversion != "0" )
				{
					var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
					if( sh && sh.data ) {
						sh.data.tmpSyncVersion = hubsyncversion;
					}
					
					var win:Window = Window( Application.instance.window.GetBooleanWindow( "ContentSync", Language.getKeyword("Install latest website content"), Language.getKeyword("ContentSync-MSG") + " \nContent Version " + hubsyncversion + "?", {
					complete: contentSync_yn,
					continueLabel:Language.getKeyword( "ContentSync-MSG-Yes" ),
					allowCancel: true,
					autoWidth:false,
					autoHeight:true,
					cancelLabel: Language.getKeyword("ContentSync-MSG-Cancel")
					}, 'ContentSync-yn-window') );
					
					Application.instance.windows.addChild( win );
					
					return;
				}else{
					Console.log("Error: Sync version is null");
					onContentSync(false);
				}
			}else{
				Console.log("Error Loading Sync Version");
				onContentSync(false);
			}
		}
		
		private static function contentSync_yn ( y:Boolean ) :void {
			if( y ) {
				firstContentSync();
			}else{
				onContentSync( false );
			}
		}
		
		private static function firstContentSync () :void
		{			
			// Download new content:
			
			var res:Resource = new Resource();
			var vars:URLVariables = new URLVariables();
			vars.content = 1;
			
			var pwd:String = "";
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			if( sh ) {
				if( sh.data && sh.data.userPwd ) {
					pwd = sh.data.userPwd;
				}else{
					Application.instance.cmd( "CTTools get-password", firstContentSync);
					return;
				}
			}
			vars.pwd = pwd;
			
			res.load( CTOptions.uploadScript, true, onSyncContent, vars);
		}
		
		private static function onContentSync ( success:Boolean = true ) :void {
			if ( success ) {
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				
				if( sh && sh.data && sh.data.tmpSyncVersion ) {
					sh.data.syncVersion = sh.data.tmpSyncVersion;
				}
				Console.log("Content Synced");
				invalidateFiles();
			}
			onFirstSync();
		}
		
		private static function onSyncContent ( e:Event, r:Resource ) :void
		{
			var hubcontent:String;
			
			try {
				hubcontent = String(r.obj) || "";
			}catch(e:Error) {
				hubcontent = "";
			}
			
			if ( hubcontent )
			{
				var f:File = File.applicationStorageDirectory.resolvePath( CTOptions.tmpDir + CTOptions.urlSeparator + "content.xml" );
				
				writeTextFile( f.url, hubcontent );
				
				loadDefaultContent( f.url, onContentSync );
			}
			else
			{
				Console.log("Error: No Hub Content File");
				onContentSync( false );
			}
		}
		
		private static function firstRestart () :void
		{
			// after install default content
			if ( CTOptions.uploadScript != "" )
			{
				Console.log("Loading Content Sync Version.. ");
				
				// Download content version:
				
				var res:Resource = new Resource();
				var vars:URLVariables = new URLVariables();
				vars.latest = 1;
				
				var pwd:String = "";
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( sh ) {
					if( sh.data && sh.data.userPwd ) {
						pwd = sh.data.userPwd;
					}else{
						Application.instance.cmd( "CTTools get-password", firstRestart);
						return;
					}
				}
				vars.pwd = pwd;
				res.load( CTOptions.uploadScript, true, onSyncInfo, vars);
			}
			else
			{
				onFirstSync();
			}
		}
		
		
		private static function firstSyncSaveComplete ():void {
			setTimeout( restartLater, 990 );
		}
		
		private static function restartLater ():void
		{
			if ( CTOptions.verboseMode ) Console.log ( "Restart" );
			Application.command("restart");
		}
		
		public static function onFirstSync () :void
		{
			save(firstSyncSaveComplete);
		}
		
		private static function openAfterDBCreate () :void
		{
			// Hide app-config from styleSheet
			Application.instance.config.media = "all";
			
			if(installProgress) installProgress.value = 1;
			
			if ( CTOptions.verboseMode ) Console.log( "DB Setup Complete" );
			
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
				Console.log( "Error Select Active Template Failed");
			}else{
				if( !CTOptions.verboseMode ) {
					try {
						var iv:InstallView;
						iv = InstallView( Application.instance.view.panel.src );
						iv.showProgress( 0.1 );
					}catch(e:Error) {
						
					}
				}else{
					Console.log("Selecting Root Template.");
				}
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
					Console.log( "Error Select On Template Properties Failed");
				}
			}else{
				// Insert active template in db...
				pm[":name"] = activeTemplate.name;
				pm[":indexfile"] = activeTemplate.indexFile;
				if(! db.insertQuery( onInsertTmplDBLoad, "template", "name,indexfile", ":name,:indexfile", pm ) ) {
					Console.log( "Error Insert Active Template Error");
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
					if ( CTOptions.verboseMode ) Console.log( "Loading Template Properties");
					var rv:Boolean = db.query( onActiveTmplPropsDBLoad, sql, pm );
					
					if( !rv) Console.log( "Error Select On Active Template Pproperties Failed");
				}
			}
		}
		
		private static function onActiveTmplPropsDBLoad ( res:DBResult ):void {
			// --> loadDBHandler 1
			if(res && res.data && res.data.length > 0) {
				var L:int = res.data.length;
				var sec:String;
				var nm:String;
				var tp:String;
				var val:String;
				if ( CTOptions.verboseMode ) Console.log( L + " Properties");
				
				for(var i:int=0; i<L; i++) 
				{
					nm = res.data[i].name;
					sec = res.data[i].section;
					tp = res.data[i].type;
					val = res.data[i].value;
					
					activeTemplate.dbProps[nm] = { name:nm, type:tp, value: res.data[i].value, section:"", _templateid:res.data[i].templateid };
					
					if( sec != "" ) {
						activeTemplate.dbProps[sec + "." + nm] = { name:nm, type:res.data[i].type, value:res.data[i].value, section:sec, _templateid:res.data[i].templateid};
					}
				}
			}
			
			// Load pages
			var sql:String = 'SELECT uid,name,visible,parent,webdir,title,type,template,filename,crdate FROM page;';
			if ( CTOptions.verboseMode ) Console.log( "Loading Pages");
			var rv:Boolean = db.query( onPagesDBLoad, sql, null );
			if( !rv) Console.log( "Error Select On Pages Failed");
		}
		
		private static function onPagesDBLoad ( res:DBResult ):void
		{	
			if( res && res.data && res.data.length > 0 )
			{
				pages = [];
				pageTable = {};
				
				articlePages = [];
				articlePageTable = {};
				
				var L:int = res.data.length;
				var n:String;
				var tp:String;
				var newFile:String;
				var prjFile:ProjectFile;
				var tmp:String;
				var pg:Page;
				if ( CTOptions.verboseMode ) Console.log( L + " Pages");
				
				for(var i:int=0; i<L; i++)
				{
					n = res.data[i].name;
					
					tp = res.data[i].type.toLowerCase();
					
					if( tp == "article" )
					{
						if( articlePageTable[ n ] != null) continue;
						articlePageTable[ n ] = new Page(n, res.data[i].uid, res.data[i].type, res.data[i].title, res.data[i].template, res.data[i].crdate, true, res.data[i].parent, res.data[i].webdir, res.data[i].filename  );
						articlePages.push( articlePageTable[ n ] );
					}
					else
					{
						if( pageTable[ n ] != null) continue;
						pageTable[ n ] = new Page(n, res.data[i].uid, res.data[i].type, res.data[i].title, res.data[i].template, res.data[i].crdate, true, res.data[i].parent, res.data[i].webdir, res.data[i].filename  );
						pages.push( pageTable[ n ] );
						loadPage( pageTable[ n ] );
					}
				}
			}
			if( !CTOptions.verboseMode ) {
				try {
					var iv:InstallView;
					iv = InstallView( Application.instance.view.panel.src );
					iv.showProgress( 0.4 );
				
				}catch(e:Error) {
					
				}
			}else{
				Console.log("Loading Subtemplates");
			}
			// load subtemplates
			var sql:String = 'SELECT uid,name,indexfile FROM template;';
			if ( CTOptions.verboseMode ) Console.log( "Loading Subtemplates");
			var rv:Boolean = db.query( onSubtemplatesDBLoad, sql, null );
			if( !rv) Console.log( "Error Select On Active Template Properties Failed");
		}
		private static function onSubtemplatesDBLoad ( res:DBResult ):void {
			if (res && res.data && res.data.length > 1) {
				if ( CTOptions.verboseMode ) Console.log( res.data.length +" Subtemplates");
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
				setTimeout( loadPageItems, 0);
				return;
			}
			if( internSubTemplData[internCurrSubTempl].name != activeTemplate.name ) {
				CTTools.loadSubTemplate( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + internSubTemplData[internCurrSubTempl].name, loadNextSubTemplate);//onLoadNextSubTemplate);
				internCurrSubTempl++;
				return;
			}
			
			internCurrSubTempl++;
			loadNextSubTemplate();
			return;
		}
		
		private static function loadPageItems () :void
		{
			tmpArticlePageItems = [];
			tmpInlineAreaItems = [];
			if( !CTOptions.verboseMode ) {
				try {
					var iv:InstallView;
					iv = InstallView( Application.instance.view.panel.src );
					iv.showProgress( 0.8 );
				}catch(e:Error) {
					
				}
			}else{
				Console.log("Loading Page Items");
			}
			
			var sql:String = 'SELECT uid,name,visible,area,sortid,subtemplate,crdate FROM pageitem;';
			
			var rv:Boolean = db.query( onPageItemsLoaded, sql, null );
			if(!rv) Console.log( "Error Select On Page Items Failed");
		}
		
		private static function onPageItemsLoaded (res:DBResult) :void {
			if( res && res.data && res.data.length > 0 )
			{
				if ( CTOptions.verboseMode ) Console.log( res.data.length + " Page Items");
				internPageItemData = res.data;
				internCurrPageItem = 0;
				loadNextPageItem();
			}
			else
			{
				// No Page Items...
				if ( CTOptions.verboseMode ) Console.log( "No Page Items");
				onloadComplete();
			}
		}
		
		private static function pageItemsLoaded () :void {
			internPageItemData = null;
			internCurrPageItem = 0;
			CTTools.onloadComplete();
		}
		
		private static function loadNextArticlePageItem () :void {
			var r:Object = CTTools.pageItemTable [ tmpArticlePageItems[ tmpArticlePageItemCurr ] ] ;
			tmpArticlePageItemCurr++;
			
			if( r )
			{
				var T:Template = CTTools.findTemplate( r["subtemplate"], "name" );
				
				if( T && T.articlepage != "" )
				{
					r["inputname"] = r.name;
					
					var nm:String = CTTools.webFileName( T.articlename, r);
					var fi:FileInfo = FileUtils.fileInfo( nm );
					nm = fi.name;
					var _props:Object = { name: r.name, inputname: r.name };
					var _args:Object = {};
					var _tmpl:Object = {};
					
					if( articlePageTable && articlePageTable[nm] )
					{
						_ltPage_webdir = articlePageTable[nm].webdir;
						_ltPage_filename = articlePageTable[nm].filename;
						var T2:Template;
						
						T2 = findTemplate( CTTools.pageItemTable[ r.name ]['subtemplate'], "name" );
						
						if( T2 )
						{
							for( var str:String in CTTools.pageItemTable[ r.name ] )
							{
								if( str != "name" && str != "area" && str != "sortid" && str != "subtemplate" && str != "crdate" )
								{
									if( T2.propertiesByName[ str ] )
									{
										_props[ str ] =  CTTools.pageItemTable[ r.name ][str];
										_args[ str ] = T2.propertiesByName[ str ].args;
										_tmpl[ str ] = T2;
									}
								
								}
							}
							PageEditor.createPage( nm, true, articlePageTable[nm].title, articlePageTable[nm].type, articlePageTable[nm].template,
							articlePageTable[nm].parent, articlePageTable[nm].webdir, "now", onApLoaded, /*CTTools.pageItemTable[ r.name ]*/ _props, _args, _tmpl );
						}
						return; // wait for onApLoaded..
					}
				}else{
					setTimeout( loadNextArticlePageItem, 0 );
				}
			}
		}
		
		
		private static function loadNextPageItem () :void {
			if( internCurrPageItem >= internPageItemData.length) {
				setTimeout( pageItemsLoaded, 0);
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
			
			if( piobj.visible != undefined ) piobj.visible = CssUtils.stringToBool( piobj.visible );
			piobj.inputname = piobj.name;
			
			CTTools.pageItemTable[ r.name ] = piobj;
			CTTools.pageItems.push( piobj );
			
			var T:Template = CTTools.findTemplate( r.subtemplate, "name" );
			
			if(T && T.tables )
			{
				_ltPageItem_T = T;
				
				// Select subtemplate db data
				var pms:Object={};
				pms[":nam"] = r.name;
				
				var rv:Boolean = CTTools.db.selectQuery( onPageItem, "uid," + T.fields, T.tables, 'name=:nam', '', '', '', pms);
				if(!rv) {
					internCurrPageItem++;
					Console.log("Error Select Page Item Extension Table: " +  T.tables + ", " + T.fields);
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
		
		private static var _ltPageItem_T:Template;
		private static var pfTmp:ProjectFile = new ProjectFile();
		
		private static var tmpArticlePageItems:Array;
		private static var tmpArticlePageItemCurr:int;
		
		private static var tmpInlineAreaItems:Array;
		
		private static function onPageItem (res:DBResult) :void
		{
			if(res && res.data && res.data.length > 0)
			{
				// Page Item Extension tables loaded...
				
				var r:Object;
				var clone:Object;
				var n:String;
				var i:int;
				var L:int = res.data.length;
				var nm:String;
				var fi:FileInfo;
				var tmpdbprops:Object;
				var pftmp:ProjectFile = pfTmp;
				
				
				var tmplFolder:String = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator;
				var filepath:String;
				var pftxt:ProjectFile;
				var areatxt:String;
				var j:int;
				var L2:int;
				var pt:String;
				var flds:Array;
				var args:Array;
				
				for( i=0; i < L; i++ )
				{
					r = res.data[i];
					
					if( r.name ) {
						
						CTTools.cloneTo(r, CTTools.pageItemTable[ r.name ], true );
						
						var T:Template = _ltPageItem_T;
						
						if( T && T.articlepage != "" )
						{
							tmpArticlePageItems.push( r.name );
						}
						
						// parse pageitem with sub-template
						
						filepath = tmplFolder + T.name + CTOptions.urlSeparator + T.indexFile;
						pftxt = ProjectFile( CTTools.procFiles[ CTTools.projFileBy(filepath, "path") ]);
						
						if( pftxt )
						{
							tmpdbprops = T.dbProps;
							pfTmp.clear();
							T.dbProps = CTTools.pageItemTable[ r.name ];
							CTTools.pageItemTable[ r.name ]["itemname"] = r.name;
							
							pftmp.setUrl( pftxt.path );
							pftmp.templateId = T.name;
							pftmp.setTemplate( pftxt.template, r.name );
							
							areatxt = pftmp.getText();
							
							L2 = pftmp.templateProperties.length;
							
							//L2 = flds.length;
							var areaName:String;
							var areaType:String;
							var areaOffset:int;
							var areaLimit:int;
							var areaSubTemplateFilter:String;
							
							for( j=0; j<L2; j++ )
							{								
								pt = pftmp.templateProperties[j].defType.toLowerCase();
								
								if ( pt == "plugin" )
								{
									// init plugin property: plugin.initPageItem ( page-name, item-name, property-name, args );
									
								}
								/*else if( pt == "text" || pt == "richtext" || pt == "line" )
								{
									if( T.dbProps[pftmp.templateProperties[j].name] != undefined ) {
										T.dbProps[pftmp.templateProperties[j].name] = Template.transformRichText ( T.dbProps[pftmp.templateProperties[j].name], pftmp.templateProperties[j].args, T );
									}else{
										pftmp.templateProperties[j].defValue = Template.transformRichText ( pftmp.templateProperties[j].defValue, pftmp.templateProperties[j].args, T );
									}
								}*/
								//else if(  pt == "audio" || pt == "image"|| pt == "file" || pt == "pdf" || pt == "video" )
								else if( pt == "area" ) 
								{
									
									args = pftmp.templateProperties[j].args;
									
									if( args && args.length > 0 ) {
											
										areaName =  CTTools.webFileName( String(args[0]), CTTools.pageItemTable[ r.name ] );
										
										if( args.length > 1 ) areaType = String(args[1]);
										if( args.length > 2 ) areaOffset = parseInt( args[2] );
										else areaOffset = 0;
										
										if( args.length > 3 ) areaLimit = parseInt( args[3] );
										else areaLimit = 0;
										
										if( args.length > 4 ) areaSubTemplateFilter = String(args[4]);
										else areaSubTemplateFilter = "";
										
										invalidateArea( areaName );
										//CTTools.pageItemTable[ r.name ][ pftmp.templateProperties[j].name ] = CTTools.getAreaText ( areaName, areaOffset, areaLimit, areaSubTemplateFilter );
										
										tmpInlineAreaItems.push( {tgt:r.name , field: pftmp.templateProperties[j].name, name: areaName, type: areaType, offset: areaOffset, limit:areaLimit, stFilter:areaSubTemplateFilter } );
									}
								}
							}
							
							L2 = pftmp.templateAreas.length;
							for( j=0; j<L2; j++ ) {
								invalidateArea( pftmp.templateAreas[j].name );
							}
							
							
							T.dbProps = tmpdbprops;
							
						}else{
							Console.log("Warning: Template File '" + filepath + "' Not Found");
						}
						
					}else{
						Console.log( "Error Extension-Page-Item Has No Name Attribute");
					}
				}
			}
			setTimeout(loadNextPageItem, 0);
		}
				
		public static var pagelist:String="";
		
		private static var _ltPage_webdir:String="";
		private static var _ltPage_filename:String="";
		
		private static function onApLoaded ( success:Boolean ) :void {
			if( success )
			{
				var s:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + (_ltPage_webdir ? _ltPage_webdir + CTOptions.urlSeparator : "") + _ltPage_filename;
				var pf:ProjectFile = CTTools.findArticleProjectFile( s, "path" );
				
				if ( pf )
				{
					if ( CTOptions.verboseMode ) Console.log( "Save Article File " + pf.name);
					pf.settingDirty();
					CTTools.saveArticleFile( pf, _ltPage_webdir );
				}
			}
			loadNextArticlePageItem();
		}
		
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
		public static function createPage ( page:Page, props:Object=null, args:Object=null, tmpl:Object=null ) :void
		{
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
				
				var sp:int = page.template.indexOf(":");
			
				if( sp == -1 ) {
					Console.log("Error Article Page Template Not Found: " + page.template );
				}else{
					var tmplname:String = page.template.substring( 0, sp );
					var tmpl1:String = page.template.substring( sp + 1 );
					
					// template source file
					f = new File(projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + tmplname + CTOptions.urlSeparator + tmpl1);
					
					if( f.exists )
					{
						txt = readTextFile( f.url );
						rt = TemplateTools.rewritePage( txt, page.name, props, args, tmpl );
						
						if ( !page.webdir ) {
							newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.filename;
						}else{
							newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.webdir + CTOptions.urlSeparator + page.filename;
						}
						
						writeTextFile( newFile, rt );
						loadArticlePage( page, props["inputname"] );
					}
					else
					{
						Console.log("Error Article Page Template File Error " + f);
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
					rt = TemplateTools.rewritePage( txt, page.name, props, args, tmpl );
					newFile = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + page.filename;
					
					writeTextFile( newFile, rt );
					
					if ( pages.indexOf( page ) == -1 )
					{
						pages.push( page );
						loadPage( page );
					}
				}
				else
				{
					Console.log("Error Page Template File Error " + f);
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
					Console.log("Error Article Page Template not found: " + page.template );
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
						pf.settingDirty();
						articleProcFiles.push( pf );
					}
					else
					{
						// Update
						prjFile.setTemplate( str, itemName );
						prjFile.settingDirty();
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
		
		private static function displayLater () :void {
			if( tmpInlineAreaItems.length > 0 ) {
				//
				for( var i:int = 0; i<tmpInlineAreaItems.length; i++) {
				//	CTTools.invalidateArea(  tmpInlineAreaItems[i].name );
					CTTools.pageItemTable[tmpInlineAreaItems[i].tgt][tmpInlineAreaItems[i].field] = CTTools.getAreaText ( tmpInlineAreaItems[i].name, tmpInlineAreaItems[i].offset, tmpInlineAreaItems[i].limit/*, tmpInlineAreaItems[i].stFilter*/ );
				}
				
				tmpInlineAreaItems = null;
				//tmpInlineAreaItems.push( {name: areaName, type: areaType, offset: areaOffset, limit:areaLimit, stFilter:areaSubTemplateFilter } );
			}
			invalidateAndBuildFiles();
			if( CTOptions.autoSave ) save();
			Application.instance.cmd( "TemplateTools edit-content");
			try {
				Application.instance.view.panel.src["displayFiles"]();
			}catch(e:Error) {
				
			}
			
			if( tmpArticlePageItems.length > 0 ) {
				tmpArticlePageItemCurr = 0;
				loadNextArticlePageItem();
			}
		}
		
		private static function onloadComplete () :void {
			
			if ( CTTools.internDBCreateCmds )
			{
				if ( CTOptions.verboseMode ) Console.log("Run dbcreate cmds..");
				// run dbcreate commands
				CTTools.runNextDBCreateCmd();
			}
			else
			{
				
				if( !CTOptions.verboseMode ) {
					try {
						var iv:InstallView;
						iv = InstallView( Application.instance.view.panel.src );
						iv.showProgress( 1 );
						iv.setLabel("");
					}catch(e:Error) {
						
					}
				}else{
					Console.log("Loading Complete");
				}
				
				// Finally Opened the project...
				//.............../||||Loaded||||\.................
				
				invalidateAndBuildFiles();
				
				Application.instance.hideLoading();
				
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
			
			Console.log( "* Installation Complete\n* Loading Project.. \n\n"  );
			
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
			
			//if( activeTemplate ) invalidateTemplateFiles ( activeTemplate, true );
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
				Console.log("Error Open Project " + error.message);
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
				if( !CTOptions.verboseMode )
				{
					Application.command( "view InstallView" );
					
					try {
						var iv:InstallView;
						iv = InstallView( Application.instance.view.panel.src );
						iv.progress.showPercentValue = false;
						iv.showProgress( 0.05 );
						iv.setLabel(Language.getKeyword("Loading") );
					}catch(e:Error) {
						
					}
				}
				else
				{
					Console.command("show console");
				}
				if ( CTOptions.verboseMode ) Console.log( "Open " + projectDir );
				
				var ish:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
				var gp:String = (CTOptions.installTemplate == "" || CTOptions.installTemplate == "current") ? CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate : CTOptions.installTemplate;
				
				CTOptions.uploadScript = "";
				CTMain.overrideInstallOptions( null, true );
				
				// override options from install.xml file
				if( ish && ish.data )
				{	
					if( ish.data.installTemplates )
					{
						var L:int = ish.data.installTemplates.length;
						for(var i:int=0; i<L; i++) {
							if( ish.data.installTemplates[i].prjDir == projectDir && ish.data.installTemplates[i].installOp )
							{
								try {
									var x:XML = new XML( ish.data.installTemplates[i].installOp );
									CTMain.overrideInstallOptions( x.templates );
									CTMain.overrideInstallOptions(  x.templates.template.(@name==ish.data.installTemplates[i].name) );
								}
								catch(e:Error)
								{
									Console.log("Project " + projectDir + " InstallOptions Error: " + e );
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
				
				var currct:Template = activeTemplate;
				
				activeTemplate = new Template("root");
				
				var tistr:String = readTextFile( projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.templateIndexFile );
				if( tistr ) {
					var txo:XML = new XML( tistr );
					if( txo.template ) {
						loadTmplByIndexFile(txo, projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate);
					}else{
						tistr = "";
					}
				}
				
				if( !tistr ) {
					Console.log("Error No '" +CTOptions.templateIndexFile+"' File Or Template Node In File Missing");
					activeTemplate = currct;
					return false;
				}
				
				Application.instance.showLoading();
				
				activeTemplate.genericPath = gp;
				activeTemplate.indexStr = tistr;
				
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
					
					if( dbType == "sqlite" )
					{
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
					
					storeProjectLocal();
					
					return true;
				}else{
					Console.log( "Error " + CTOptions.dbIndexFileName + " Missing");
					showTemplate = true;
					if(! CTTools.internDBCreateCmds && !saveAsFirst) displayFiles(); // leave console open while installing...
				}
			}
			
			return false;
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
				Console.log("Error Save As " + error.message);
			}
		}
		public static function storeProjectLocal () :void {
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh ) {
				if( sh.data ) {
					if( CTOptions.verboseMode ) Console.log( "Set Last Project: " + projectDir + " in SH-OBJ: " +  CTOptions.installSharedObjectId );
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
				if(!CTOptions.isMobile) {
					for( i=0; i<procFiles.length; i++) {
						procFiles[i].monitorFile(false);
					}
				}
				
				saveCompleteHandler = completeHandler;
				
				var dir:File = new File( projectDir );
				var files:Array = CTTools.procFiles;
				var L:int = files.length;
				
				if ( CTOptions.verboseMode ) Console.log( "Save " + L + " Project Files");
				
				// save all prj files
				if( !saveAsFirst ) {
					for( i=0; i < L; i++) {
						saveFile( ProjectFile( files[i]), dir );
					}
				}else{
					// copy template files to prj-dir
					var file:File;
					var fileStream:FileStream;
					if ( CTOptions.verboseMode ) Console.log( "Copy " + L + " Template Files To Template Directory");
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
							Console.log("Error Cant Create Default DB Index File");
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
						if ( dbType == "sqlite" )
						{
							
							var filename:String = xo.db.@filename;
							var cid:int =  filename.indexOf("/");
							if( cid >= 0 ) {
								if( cid == 0 ) { // remove first slash
									filename = filename.substring( 1 );
								}
							}
							var filepath:String = projectDir + CTOptions.urlSeparator + filename;
							
							if ( CTOptions.verboseMode ) Console.log( "Load DB: " + filepath );
							
							// Create DB File if not available
							loadDB ( filepath, SqliteDB );
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
					
					if ( CTOptions.verboseMode ) Console.log( "Save Complete");
					
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
					Console.log( "Error " + File.applicationDirectory.url + "/" + initquery + " Missing");
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
			
			if( sqlExec )
			{
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
			
			// split querys
			for(var i:int = 0; i<L; i++) {
				cc = sqlstr.charCodeAt(i);
				if( cc == 34 || cc == 39 ) { // Ignore in Strings
					cc2 = cc;
					for(i++; i<L; i++) { 
						if( sqlstr.charCodeAt(i) == cc2 ) break;
					}
				}
				if( cc == 59 ) { // ;
					q = sqlstr.substring( qstart, i );
					querys.push( q );
					qstart = i+1;
				}
			}
			
			if ( querys.length > 0 )
			{
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
					if ( sh.data.installTemplates[i].prjDir == "" )
					{
						sh.data.installTemplates[i].prjDir = projectDir;
						sh.flush();
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
					if ( CTOptions.verboseMode ) Console.log( "Save Project File :"  + pf.name );
					
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
		
		public static function command (argv:String, cmdComplete:Function = null, cmdCompleteArgs:Array = null) :void
		{
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
								Console.log("Error InstObjID is undefined");
							}
						}else{
							fi3 =  CTOptions.mobileParentFolder.resolvePath( CTOptions.mobileProjectFolderName );
						}
						if( fi3 ) {
							for(i=0; i<ish.data.installTemplates.length; i++)
							{
								if( ish.data.installTemplates[i].prjDir == projectDir ||  ish.data.installTemplates[i].prjDir == fi3.url  )
								{
									generic = ish.data.installTemplates[i].genericPath;
									
									break;
								}
							}
						}
					}
					pth1 = generic + CTOptions.urlSeparator + pth1.substring(18);
					
				}
				else if( pth1.substring(0,10) == "template:/" ) {
					pth1 =  projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + /* CTOptions.urlSeparator + CTOptions.subtemplateFolder +*/ CTOptions.urlSeparator + pth1.substring(10);
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
									if(CTOptions.debugOutput ) Console.log( "Installing Installed Template From " + loadTemplate__FolderName);
									break;
								}	
							}
						}else{
							Console.log("Warning: No Local Install Options");
						}
					}else{
						// No project dir with template available.. show install templates or get-host-info
						Console.log("Warning: No Project Directory");
						Main(Application.instance).cmd( "Application view StartScreen" );
						return;
					}
				}
				
				var ih:Boolean = false;
				
				// search empty prjDir or create inst obj (instobj from CTMain)
				if( ish.data.installTemplates ) {
					for( k=0; k<ish.data.installTemplates.length; k++) {
						if ( ish.data.installTemplates[k].prjDir == "" ) {
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
							complete(cmdComplete, cmdCompleteArgs);
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
				clearFiles();
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
				clearFiles();
				displayFiles();
			}
			
			var brpreview:int = args.indexOf( "browser-preview" );			
			if( brpreview >= 0 ) {
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
					complete(cmdComplete, cmdCompleteArgs);
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
					complete(cmdComplete, cmdCompleteArgs);
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
					complete(cmdComplete, cmdCompleteArgs);
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
					complete(cmdComplete, cmdCompleteArgs);
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
			var plg:int = args.indexOf( "load-plugin" );			
			if( plg >= 0 ) {
				loadPlugin( args[plg +1], BaseTool.arrStringFrom( args, plg + 2) );
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
				var nme:String;
				
				if ( sh && sh.data ) {
					for (nme in sh.data) {
						sh.data[nme] = null;
						delete sh.data[nme];
					}
					 sh.flush();
					 sh.close();
				 }
				 sh = SharedObject.getLocal( CTOptions.localSharedObjectId );
				
				if ( sh && sh.data ) {
					for (nme in sh.data) {
						sh.data[nme] = null;
						delete sh.data[nme];
					}
					sh.flush();
					sh.close();
				}
				 
				if( CTOptions.isMobile ) {
					 clearMobileFolder();
				}
				
				Application.command("restart");
			}
			
			
			var sysInfo:int = args.indexOf( "system-info" );			
			if( sysInfo >= 0 ){
				Console.log( "--- SYSTEM INFO ------------" );
				Console.log( "- OS: " + Capabilities.os );
				Console.log( "- Manufacturer: " + Capabilities.manufacturer );
				Console.log( "- Version: " + Capabilities.version );
				Console.log( "- Language: " + Capabilities.languages );
				Console.log( "- Total Memory: " + System.totalMemory / 1000000 + " MB");
				Console.log( "- Free Memory: " + System.freeMemory / 1000000 + " MB");
				Console.log( "- Touchscreen Type: " + Capabilities.touchscreenType );
				Console.log( "- Screen Resolution: " + Capabilities.screenResolutionX + " x " + Capabilities.screenResolutionY );
				Console.log( "- Screen Color: " + Capabilities.screenColor );
				Console.log( "- Screen DPI: " + Capabilities.screenDPI );
				Console.log( "- Screen Pixel Aspect Ration: " + Capabilities.pixelAspectRatio );
				Console.log( "- File Read Disable: " + Capabilities.localFileReadDisable );
				Console.log( "- 32BIT / 64BIT: " + Capabilities.supports32BitProcesses + " / " + Capabilities.supports64BitProcesses );
				Console.log( "- TLS: " + Capabilities.hasTLS );
				Console.log( "- IME: " + Capabilities.hasIME );
				Console.log( "- Printing: " + Capabilities.hasPrinting );
				Console.log( "- Audio: " + Capabilities.hasAudio );
				Console.log( "- MP3: " + Capabilities.hasMP3 );
				Console.log( "- Streaming Audio: " + Capabilities.hasStreamingAudio );
				Console.log( "- Streaming Video: " + Capabilities.hasStreamingVideo );
				Console.log( "- CPU Architecture: " + Capabilities.cpuArchitecture );
				Console.log( "- CPU AddressSize: " + Capabilities.cpuAddressSize );
				Console.log( "----------------------------" );
			}
			
			var showUrl:int = args.indexOf( "show-url" );			
			if( showUrl >= 0 ){
				try {
					var ed:HtmlEditor = HtmlEditor( Application.instance.view.panel.src );
					if( ed ) {
						ed.loadWebURL( BaseTool.arrStringFrom( args, showUrl+1 ) );
					}
				}catch( e:Error) {
					Console.log("Error Load Web URL : " + e);
				}
			}
			
			var displayIndex:int = args.indexOf( "display" );			
			if( displayIndex >= 0 ){
				displayFiles();
			}
			complete(cmdComplete, cmdCompleteArgs);
		}
		private static var internCmdComplete:Function;
		
		internal static function clearPrjRef () :void {
			var sh:SharedObject;
			
			sh = SharedObject.getLocal( CTOptions.installSharedObjectId );
			var nme:String;
			
			if ( sh && sh.data ) {
				for (nme in sh.data) {
					sh.data[nme] = null;
					delete sh.data[nme];
				}
				 sh.flush();
				 sh.close();
			}
			sh = SharedObject.getLocal( CTOptions.localSharedObjectId );
			
			if ( sh && sh.data ) {
				for (nme in sh.data) {
					sh.data[nme] = null;
					delete sh.data[nme];
				}
				sh.flush();
				sh.close();
			}
		}
		
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
				Console.log( "Can Not Set New Password, Wrong Password Sent?");
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
				Console.log("Error While Setting New Password");
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
			
			Console.log("HttpServer Listening On Port "+CTOptions.httpServerPort+", WWW-Root: " + webroot.url);
		}
		private static function onNeedBPSave () : void
		{
			if ( CTOptions.useHttpServer ) {
				runServer();
				Console.log("Preview With Server : " + server + " Path: " + webroot.url + "/" + activeTemplate.indexFile );
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
			
		public static function compareVersions ( oldVersion:String, newVersion:String ) :String
		{
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
			var L:int;
			var pf:ProjectFile;
			var text:String;
			var i:int;
			saveDirty = true;
			Template.resetPrios();
			if(procFiles) {
				L = procFiles.length;
				for(i=0; i<L; i++) {
					pf = ProjectFile(procFiles[i]);
					pf.allDirty();
					text = pf.getCompact();
				}
			}
			if(articleProcFiles) {
				L = articleProcFiles.length;
				for(i=0; i<L; i++) {
					pf = ProjectFile(articleProcFiles[i]);
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
				var i:int;
				for(i=0; i<L; i++) {
					pf = ProjectFile(procFiles[i]);
					if ( pf.templateId == T.name ) {
						pf.allDirty();
					}
					if(build) {
						btext = pf.getCompact();
					}
				}
			}
		}
		
		public static function invalidateArea ( name:String ) :void
		{
			var L:int;
			var i:int;
			var j:int;
			var L2:int;
			var pf:ProjectFile;
			
			if(procFiles)
			{
				saveDirty = true;
				L = procFiles.length;
				
				for(i=0; i<L; i++)
				{
					pf = ProjectFile(procFiles[i]);
					if( pf.templateAreas )
					{
						L2 = pf.templateAreas.length;
						for( j=0; j<L2; j++)
						{
							if ( pf.templateAreas[j].name == name || pf.templateAreas[j].link == name )
							{
								pf.contentDirty();
							}
						}
					}
					
				}
			}
			
			if( articleProcFiles )
			{
				saveDirty = true;
				
				L = articleProcFiles.length;
				
				for(i=0; i<L; i++)
				{
					pf = ProjectFile( articleProcFiles[i] );
					
					if( pf.templateAreas )
					{
						L2 = pf.templateAreas.length;
						
						for( j=0; j<L2; j++)
						{
							if ( pf.templateAreas[j].name == name || pf.templateAreas[j].link == name )
							{
								pf.contentDirty();
								
								for( var k:int=0; k<articlePages.length; k++ ) {
									if ( articlePages[k].name == pf.name ) {
										saveArticleFile( pf, articlePages[k].webdir );
										break;
									}
								}
							}
						}
					}
				}
			}
		}
		
		public static function invalidateProperty ( name:String ) :void
		{
			var L:int;
			var i:int;
			var j:int;
			var L2:int;
			var pf:ProjectFile;
			
			if(procFiles)
			{
				saveDirty = true;
				L = procFiles.length;
				
				for(i=0; i<L; i++)
				{
					pf = ProjectFile(procFiles[i]);
					if( pf.templateProperties )
					{
						L2 = pf.templateProperties.length;
						for( j=0; j<L2; j++)
						{
							if ( pf.templateProperties[j].name == name )
							{
								pf.settingDirty();
								break;
							}
						}
					}
				}
			}
			
			if( articleProcFiles )
			{
				saveDirty = true;
				
				L = articleProcFiles.length;
				var k:int;
				
				for(i=0; i<L; i++)
				{
					pf = ProjectFile( articleProcFiles[i] );
					
					if ( CTOptions.isMobile || !CTOptions.fixRandomsOnlyOnMobile ) {
						if ( pf.hasRandoms ) {
							pf.settingDirty();
							continue;
						}
					}
					
					if( pf.templateProperties )
					{
						L2 = pf.templateProperties.length;
						
						for( j=0; j<L2; j++)
						{
							if ( pf.templateProperties[j].name == name )
							{
								pf.settingDirty();
								
								for(k=0; k<articlePages.length; k++ ) {
									if ( articlePages[k].name == pf.name ) {
										saveArticleFile( pf, articlePages[k].webdir );
										break;
									}
								}
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
				else if( s.substring(0, 18) == "template-generic:/" ) 
				{
					return (CTTools.activeTemplate && CTTools.activeTemplate.genericPath ? CTTools.activeTemplate.genericPath : projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate) + CTOptions.urlSeparator + s.substring(18);
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
		
		// convret strings to script names (a-z, A-Z, 0-9, _$)
		public static function convertName ( n:String ) :String
		{
			if( !n) return n;
			
			var L:int = n.length;
			var rv:String = "";
			var cc:int;
			
			for( var i:int=0; i<L; i++)
			{
				cc = n.charCodeAt(i);
				if( cc <= 32 || cc == 46 || cc == 45  || cc == 44 || cc == 47  || cc == 58 || cc == 59 ) { // .-,/
					if( rv.charAt( rv.length-1) != "_" ) {
						rv += "_";
					}
				}else if( cc == 36 || cc == 95 ) {
					rv += n.charAt(i);
				}else if( (cc >= 48 && cc <= 57) || (cc >= 65 && cc <= 90) || (cc >= 97 && cc <= 122) ) {
					rv += n.charAt(i);
				}
			}
			
			return rv;
		}
		
		
		public static function fileExists ( src_url:String ) :Boolean
		{
			var f:File = new File( src_url );
			return f.exists;
		}
		
		public static function copyFile ( src_url:String, dst_url:String, complete:Function=null ) :Boolean
		{
			if( src_url == dst_url ) return true;
			
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
				try {
					var src:File = new File( src_url );
					var dst:File = new File( dst_url );
					if( src.exists ) {
						var destination:FileReference = dst;
						src.copyTo(destination, true);
						return true;
					}
				}catch(e:Error) {
					Console.log("Error File copy: " + src_url + ", " + dst_url );
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
		
		
		// img/errfile.jpg, complete, return true if file is being downloaded, otherwise false (file have been fixed localy), use complete(success) handler
		public static function findWebFile ( webdir_path:String, complete:Function ) :Boolean
		{
			if( !CTOptions.resolveWebFiles ) return false;
			
			if( CTTools.activeTemplate && CTTools.projectDir )
			{
				var file_raw:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + webdir_path;
				var fileRaw:File = new File( file_raw );
				
				var file_min:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + webdir_path;
				var fileMin:File = new File( file_min );
				
				if( fileMin.exists && !fileRaw.exists )
				{
					// copy from min to raw foldder
					copyFile( file_min, file_raw );
					Console.log("Warning: Fix Missing File " + webdir_path + " In /raw Folder");
					return false;
				}
				else if( !fileMin.exists && fileRaw.exists )
				{
					// copy from raw to min foldder
					copyFile( file_raw, file_min );
					Console.log("Warning: Fix Missing File " + webdir_path + " In /min Folder");
					return false;
				}
				else if( !fileMin.exists && !fileRaw.exists )
				{
					if( CTOptions.uploadScript != "" ) {
						var vars:URLVariables = new URLVariables();
						vars.lookup = 1;
						vars.file = webdir_path;
						
						// try download file from hub
						var res:Resource = new Resource();
						res.udfData.webdir_path = webdir_path;
						res.udfData.complete = complete;
						res.udfData.vars = vars;
						
						findWebFileResume( res, vars );
					}
				}
			}
			return true;
		}
		private static var hostRoot:String = "";
		
		public static function onFindWebFileHandler ( e:Event, res:Resource ) :void
		{
			var rv:String = "";
			
			if( res && res.loaded==1) {
				rv = String(res.obj);
			}
			
			if( !rv )
			{
				Console.log("Error: Error downloading '" + res.udfData.webdir_path + "'" );
				if( typeof( res.udfData.complete ) == "function" ) res.udfData.complete( false );
			}
			else if( rv == "no-pass" )
			{
				Application.instance.cmd("CTTools reset-password");
				findWebFileResume( res, res.udfData.vars );
			}
			else if( rv == "not-found" )
			{
				Console.log("Error: File '" + res.udfData.webdir_path + "' not found on the server");
				if( typeof( res.udfData.complete) == "function" ) res.udfData.complete( false );
			}
			else
			{
				// Download Binary File
				var dl:Sprite = Application.instance.topContent.getChildByName("downloadOverview_mc");
				if( !dl ) 
				{
					dlOverview = new DownloadOverview("Resolving Files", 0, 0, Application.instance.topContent, Application.instance.config, '', '', false );
					dlOverview.name = "downloadOverview_mc";
					dlOverview.addEventListener( "reload", reloadDownloadHandler );
					dlOverview.addEventListener( "cancel", cancelDownloadHandler );
			
				}
				else
				{
					dlOverview = DownloadOverview( dl );
				}
				
				if( dlOverview.visible == false ) dlOverview.visible = true;
				
				var res2:Resource = new Resource();
				res2.udfData.webdir_path = res.udfData.webdir_path;
				res2.udfData.complete = res.udfData.complete;
				res2.load( rv, true, onWebfileDownload, null, true);
				
				if( CTOptions.debugOutput ) Console.log("Download missing file: " + res.udfData.webdir_path );
				
				if( !Application.instance.topContent.contains( dlOverview ) ) Application.instance.topContent.addChild( dlOverview );
				dlOverview.onEmpty = removeDLInfo;
				dlOverview.addDownload( res2.udfData.webdir_path, res2 );
				dlOverview.init();
				dlOverview.x = 10;
				dlOverview.y = ( Application.instance.appContent.getHeight() * TemplateTools.editor_h ) - (dlOverview.cssSizeY + 10);
				dlOverview.setWidth(CTOptions.downloadOverviewWidth);
			}
		}
		
		public static function cancelDownloadHandler ( e:CTEvent ) :void {
			Resource( DownloadInfo( e.obj ).dlTgt ).abort();
			DownloadInfo( e.obj ).showReload();
			if( dlOverview ) {
				dlOverview.setWidth( CTOptions.downloadOverviewWidth );
			}
		}
		
		public static function reloadDownloadHandler ( e:CTEvent ) :void {
			if( dlOverview ) {
				dlOverview.removeDownload( DownloadInfo( e.obj ).dlName );
			}
			findWebFile( DownloadInfo( e.obj ).dlName, null );
			
		}
		private static var dlOverview:DownloadOverview;
		
		public static function removeDLInfo () :void {
			var dl:Sprite = Application.instance.topContent.getChildByName("downloadOverview_mc");
			if( dl ) {
				DownloadOverview(dl).show(false);
				setTimeout( function() {
					 if( Application.instance.topContent.contains( dl ) ) {
						Application.instance.topContent.removeChild( dl );
					}
					if( dlOverview ) dlOverview = null;
				}, 4000);
			}
			
		}
		public static function onWebfileDownload ( e:Event, res:Resource ) :void
		{
			if( res && res.loaded == 1 )
			{
				var b:ByteArray = ByteArray( res.obj );
				
				if( b )
				{
					if( dlOverview ) {
						
						dlOverview.removeDownload( res.udfData.webdir_path);
						if( dlOverview ) {
							dlOverview.setWidth( CTOptions.downloadOverviewWidth );
						}
					}
					
					if( CTOptions.debugOutput ) Console.log("File Downloaded: " + res.udfData.webdir_path + " copy to: " +  CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + res.udfData.webdir_path );
					writeBinaryFile( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + res.udfData.webdir_path, b );
					writeBinaryFile( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + res.udfData.webdir_path, b );
					if( typeof( res.udfData.complete) == "function" ) res.udfData.complete( true );
				}
			}else{
				
				if ( dlOverview )
				{
					var dli:DownloadInfo = dlOverview.getDownload( res.udfData.webdir_path );
					if ( dli ) {
						dli.showReload();
						dlOverview.setWidth( CTOptions.downloadOverviewWidth );
						
					}
				}
			}
			if( typeof( res.udfData.complete) == "function" ) res.udfData.complete( false );
		}
		
		public static function findWebFileResume ( res:Resource, vars:URLVariables ) :void {
			var pwd:String = "";
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			if( sh && sh.data && sh.data.userPwd ) {
				pwd = sh.data.userPwd;
			}else{
				Application.instance.cmd( "CTTools get-password", findWebFileResume, [res, vars] );
				return;
			}
			vars.pwd = pwd;
			
			if( CTOptions.debugOutput || CTOptions.verboseMode ) {
				Console.log("LOOK-UP Missing File: '" + vars.file + "' From " + CTOptions.uploadScript);
			}
			
			res.load( CTOptions.uploadScript, true, onFindWebFileHandler, vars);
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
			if( ctm && ctm.stage )
			{
				if( ctm.stage.softKeyboardRect.width == 0 || ctm.stage.softKeyboardRect.height == 0 )
				{
					// deactivate
					ctm.setSize( ctm.stage.stageWidth, ctm.stage.stageHeight );
				}
				else
				{
					var h:int = ctm.stage.softKeyboardRect.y / ( CssUtils.numericScale / 2) /* - (ctm.mainMenu.cssSizeY * CssUtils.numericScale)*/;
					ctm.setSize( ctm.stage.stageWidth, h );
					
					try {
						Object(ctm.view.panel.src).newSize(null);
					}catch(e:Error) {
						Console.log("Error setting SoftKeyboard Size");
					}
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
		
		// returns the html of an area with out comments. used only by area-properties
		public static function getAreaText ( areaname:String, offset:int=0, limit:int=0 ) :String
		{
			var areatxt:String = "";
			
			var L:int = pageItems.length;
			var itc:int = 0;
			var pgitems:Array = [];
			var itemCount:int = 0;
			var pftxt:ProjectFile;
			
			var filepath:String;
			var tmpdbprops:Object;
			var pftmp:ProjectFile = new ProjectFile("tmp");
			var T:Template;
				
			if( pageItems )
			{
				L = pageItems.length;
				
				for( var i:int = 0; i < L; i++ )
				{
					if(pageItems[i].area == areaname && pageItems[i].visible != false )
					{
						if( offset > 0 && itc < offset ) {
							itc++;
						}else{
							itemCount = pgitems.push( pageItems[i] );
							if( limit > 0 && itemCount >= limit ) {
								break; 
							}
						}
					}
				}
				
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
			}
			
			var tmplFolder:String = projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator;
			var stName:String;
			
			L = pgitems.length;
			
			for(i=0; i < L; i++)
			{
				stName = pgitems[i].subtemplate;
				T = findTemplate( stName, "name" );
				
				if( T )
				{
					filepath = tmplFolder + T.name + CTOptions.urlSeparator + T.indexFile;
					pftxt = ProjectFile( CTTools.procFiles[ CTTools.projFileBy(filepath, "path") ]);
					
					if( pftxt )
					{
						tmpdbprops = T.dbProps;
						T.dbProps = pgitems[i];
						pftmp.setUrl( pftxt.path );
						pftmp.templateId = T.name;
						pftmp.setTemplate( pftxt.template, pgitems[i].name );
						
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
			return areatxt;
		}
		
	}
}