package ct
{
	import agf.Main;
	import agf.html.*;
	import agf.db.*;
	import agf.io.*;
	import agf.ui.*;
	import agf.tools.*;
	import agf.utils.*;
	import flash.utils.*;
	import flash.text.TextField;
	import flash.display.Sprite;
	import ct.ctrl.*;
	import flash.events.*;
	import flash.filesystem.*;
	import flash.net.*;
	
	/**
	* Template Update XML
	<ct>
		<ctx name="Version-Code-Name | subtemplate-name | plugin-name" version="1.0.0" date="22-11-2018" 
			type="template | sub-template | config | plugin |" src="plugin-file" dependencies="template-name | plugin-name,..."
			sqlquery="update-sql.sql" 
		/>
	</ct>
	**/
	
	public class TemplateTools extends BaseTool
	{
		
		// right preview by default
		public static var editor_w:Number = 0.6; // Resize var in percent
		public static var editor_h:Number = 1; // Resize var in percent
		
		private static var currTLog:int;
		private static var deco_chars:int = 96;
		private static var deco_h:String = ".";
		private static var deco_v:String = ":";
		private static var _fieldWidth:int = 15;
		private static var fieldWidth:int = 15;
		
		public static function emptyProject () :void {}
		
		
		public static function command (argv:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null) :void 
		{
			var args:Array = argv2Array(argv);
			
			var editContent:int = args.indexOf( "edit-content" );			
			if( editContent >= 0 ) {
				try{
					Application.command( "view HtmlView" );
					Application.instance.view.panel.src.editor.showSection( Language.getKeyword("Content") );
				}catch(e:Error){
					
				}
			}
			var createTmpl:int = args.indexOf( "create-template" );			
			if( createTmpl >= 0 ) {
				newTemplate();
			}
			
			var c:int = args.indexOf( "show-preview" );			
			if( c >= 0 ) {
				try {
					Application.instance.view.panel.src["collapseClick"]();
				}catch( e:Error ) {
					// No HtmlEditor Open
				}
			}
			c = args.indexOf( "show-areas" );			
			if( c >= 0 ) {
				try {
					Application.instance.view.panel.src["editor"]["currentEditor"]["toggleAreaView"]();
				}catch( e:Error ) {
					// No HtmlEditor Open
				}

			}
			
			// Install Template from zip file
			var installTmpl:int = args.indexOf( "install-template" );			
			if( installTmpl >= 0 ) {
				// Install a new root template (runs inataller with db-create)
				if( args.length > installTmpl+1 ) {
					// Use path to zip-file from arguments
					installTemplate( arrStringFrom( args, installTmpl+1 ) );
				}else{
					// Select zip-file with file selector
					selectInstallTemplateFile();
				}
			}
			
			// Update Template from zip-file
			var updateTmpl:int = args.indexOf( "update-template" );			
			if( updateTmpl >= 0 ) {
				// Update currently used template..
				if( args.length > updateTmpl+1 ) {
					updateTemplate( arrStringFrom( args, updateTmpl+1 ) );
				}else{
					selectUpdateTemplateFile();
				}
			}
			
			var editOptions:int = args.indexOf( "edit-options" );			
			if( editOptions >= 0 ) {
				try{
					Application.command( "view HtmlView" );
					Application.instance.view.panel.src.editor.showSection( Language.getKeyword("Options") );
				}catch(e:Error){
					
				}	
			}
			var editMedia:int = args.indexOf( "edit-media" );			
			if( editMedia >= 0 ) {
				try{
					Application.command( "view HtmlView" );
					Application.instance.view.panel.src.editor.showSection( Language.getKeyword("Media") );
				}catch(e:Error){
					
				}	
			}
			var logTemplates:int = args.indexOf( "template-info" );			
			if( logTemplates >= 0 ) {
				var tmpl:String = arrStringFrom( args, logTemplates+1);
				if( tmpl ) {
					var tdc:String =  (new Array(deco_chars).join(deco_h));
					Application.instance.cmd( "Console show console log " + tdc + "\n" + tdc + "\n" + tdc);
					Console.log( deco_v + " \n" + deco_v + " Template Information:\n" + deco_v + "\n" + deco_v + tdc + "\n" + deco_v + " \n" + deco_v + " Template: " + tmpl +"\n"+ deco_v + " ============" + (new Array(tmpl.length).join("=")) +"\n" + deco_v );
					logTemplateByName(tmpl);
				}else{
					logTemplateInfo();
				}
			}
			
			var logPrio:int = args.indexOf( "template-priorities" );			
			if( logPrio >= 0 ) {
				logTemplatePriorities();
			}
			
			// export sub template extension table as sql:
			var exp:int = args.indexOf("export-sql");
			if( exp >= 0  ) {
				var template:Template = CTTools.findTemplate( arrStringFrom( args, exp+1 ) );
				var sql:String = export_sql( template );
				if( CTOptions.debugOutput ) {
					Console.log( "SQL for '"+template.name+"':");
					Console.log(sql);
				}
			}
			
			// export sub template extension table as xml:
			var exp2:int = args.indexOf("export-xml");
			if( exp2 >= 0  ) {
				var template2:Template = CTTools.findTemplate( arrStringFrom( args, exp2+1 ) );
				var xm:String = export_xml( template2 );
				
				if( CTOptions.debugOutput ) {
					Console.log( "XML for '"+template2.name+"':");
					Console.log(xm);
				}
			}
			
			// export website content as xml (theme default content):
			var exp3:int = args.indexOf("export-all");
			if( exp3 >= 0  ) {
				var xm2:String = export_all();
				Console.log( xm2 );
			}
			
			// export website content as xml (theme default content):
			var impatch:int = args.indexOf("import-patch");
			if( impatch >= 0  ) {
				if( args.length > impatch+1 ) {
					importContentPatchFile( arrStringFrom( args, impatch+1 ) );
				}else{
					selectImportPatchFile();
				}
			}
			
			// export website content as xml (theme default content):
			var pubhistory:int = args.indexOf("publish-history");
			if ( pubhistory >= 0  )
			{
				if ( args.length > pubhistory + 1 )
				{
					
				//	importContentPatchFile( arrStringFrom( args, pubhistory+1 ) );
				}
				else
				{
					CTMain(Application.instance).showPublishHistory();
				}
			}
			
			complete( cmdComplete, cmdCompleteArgs );
		}
		
		/**
		* Rewrite a page template's areas and properties
		* example on Blog Page with name "Blog":
		*
		* Areas:
		* 
		* {##page#-CONTENT("ico:/falcon.png"):content} -> {##Blog-CONTENT("ico:/blog.png"):content}
		* {##10.Folder.10.page#-CONTENT:content} -> {##10.Folder.10.Blog-CONTENT}
		*
		* Properties:
		*
		* {#page#-BG:Image} -> {#Blog-BG:Image}
		* {#Folder.10.page#-BG:Image} -> {#Folder.10.Blog-BG:Image}
		**/
		public static function rewritePage (txt:String, pageName:String, props:Object=null, args:Object=null, tmpl:Object=null) :String
		{
			var src:String = "page#";
			
			var st:int = txt.indexOf( src );
			while( st >= 0 ) {
				txt = txt.substring(0,st) + pageName + txt.substring( st+5 );
				st = txt.indexOf( src, st );
			}
			
			src = "page-uid#";
			var id:int = CTTools.pages.length;
			
			st = txt.indexOf( src );
			while( st >= 0 ) {
				txt = txt.substring(0,st) + id + txt.substring( st+9 );
				st = txt.indexOf( src, st );
			}
			
			if ( props && args && tmpl) {
				for( var n:String in props ) 
				{
					src = "{#" + n + "}";
					st = txt.indexOf( src );
					while ( st >= 0 ) {
						txt = txt.substring(0,st) + ( (typeof(args[n]) == "undefined" && typeof(tmpl[n]) == "undefined") ? props[n] : Template.transformRichText(props[n], args[n], tmpl[n]) ) + txt.substring( st+3+n.length );
						st = txt.indexOf( src, st );
					}
				}
			}
			return txt;
		}
		private static var _uploadUrl:String;
		
		public static function installTemplate (url:String) :void
		{
			installingTemplate = true;
			
			if( url.indexOf(":/") > 3 )
			{
				// load directly
				
				var r:URLRequest = new URLRequest( url );
				var tmplDir:File = File.applicationStorageDirectory.resolvePath( CTOptions.templateStorage );
				tmplDir.createDirectory();
				
				newFolder = CTImporter.extractZipFile( r, tmplDir, installTmplExtractComplete );
				
			}
			else
			{
				_uploadUrl = url;
				newFolder = url;
				
				var pwd:String = "";
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if ( sh )
				{
					if( sh.data && sh.data.userPwd ) {
						pwd = sh.data.userPwd;
					}else{
						Application.instance.cmd( "CTTools get-password", resumeOnPwd);
						installingTemplate = false;
						return;
					}
				}
				
				// get zip file from cthub by template-name
				var res:Resource = new Resource();
				var vars:URLVariables = new URLVariables();
				vars.src = 1;
				vars.name = url;
				vars.pwd = pwd;
				
				// download zip file..
				res.load( CTOptions.uploadScript, true, onHubZipFile, vars, true );
			}
		}
		
		private static function resumeOnPwd () :void {
			installTemplate( _uploadUrl );
		}
		
		private static function resumeOnPwdUpdate () :void {
			updateTemplate( _uploadUrl );
		}
		
		public static function onHubZipFile ( e:Event, res:Resource ) :void
		{
			if (res && res.loaded == 1 )
			{
				var f:File = File.applicationStorageDirectory.resolvePath ( CTOptions.tmpDir + CTOptions.urlSeparator + _uploadUrl + ".zip");
				var fs:FileStream = new FileStream();
				fs.open( f, FileMode.WRITE );
				fs.writeBytes( ByteArray(res.obj) );
				fs.close();
				
				setTimeout( function () {
					installTemplate( f.url );
				}, 789);
			}
			else
			{
				Console.log("Error: Install package not available");
			}
		}
		
		public static function onHubZipFileUpdate ( e:Event, res:Resource ) :void
		{
			if ( res.loaded == 1 )
			{
				var f:File = File.applicationStorageDirectory.resolvePath ( CTOptions.tmpDir + CTOptions.urlSeparator + _uploadUrl + ".zip");
				var fs:FileStream = new FileStream();
				fs.open( f, FileMode.WRITE );
				fs.writeBytes( ByteArray(res.obj) );
				fs.close();
				setTimeout( function () {
					updateTemplate( f.url );
				}, 789);
			}
			else
			{
				Console.log("Error: Update package not available");
			}
		}
		
		public static function updateTemplate (url:String) :void
		{
			installingTemplate = true;
			
			if( url.indexOf(":/") > 3 )
			{
				// load directly
				var r:URLRequest = new URLRequest( url );
				var tmplDir:File =  File.applicationStorageDirectory.resolvePath( CTOptions.tmpDir );
				tmplDir.createDirectory();
				newFolder = CTImporter.extractZipFile( r, tmplDir, updateTmplExtractComplete );
			}
			else
			{
				_uploadUrl = url;
				newFolder = url;
				
				var pwd:String = "";
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if ( sh )
				{
					if( sh.data && sh.data.userPwd ) {
						pwd = sh.data.userPwd;
					}else{
						Application.instance.cmd( "CTTools get-password", resumeOnPwdUpdate);
						installingTemplate = false;
						return;
					}
				}
				
				// get zip file from cthub by template-name
				var res:Resource = new Resource();
				var vars:URLVariables = new URLVariables();
				vars.src = 1;
				vars.patch = 1;
				vars.name = url;
				vars.pwd = pwd;
				
				// dowload zip file..
				res.load( CTOptions.uploadScript, true, onHubZipFileUpdate, vars, true );
			}
		}
		
		
		
		private static var installingTemplate:Boolean = false;
		private static var newFolder:String="";
		
		private static function installTmplExtractComplete () :void {
			if( newFolder != "" )
			{
				if( CTOptions.verboseMode ) {
					Console.log( "Installing template files from: " + CTOptions.templateStorage + CTOptions.urlSeparator + newFolder );
				}
				try {
					var iv:InstallView;
					iv = InstallView( Application.instance.view.panel.src );
					iv.showProgress( 0.1 );
					iv.setLabel("Installing template files");
				}catch(e:Error) {
					
				}
				Application.instance.cmd( "CTTools template app-storage:/" + CTOptions.templateStorage + CTOptions.urlSeparator + newFolder );
			}
			installingTemplate = false;
		}
		public static function get lastExtractedTemplate () :String {
			return newFolder; 
		}
		
		
		private static var importingPatch:Boolean = false;
		
		private static function importPatch ( patch:XML ) :void
		{
			if ( importingPatch == false )
			{
				
				importingPatch = true;
				
				// process insert, update and delete querys on the db
				
				// TODO Import patch Files...
				
			}
		}
		
		
		private static function importContentPatchFile (url:String) :void {
			var txt:String = CTTools.readTextFile( url );
			if ( importingPatch == false )
			{
				if ( txt )
				{
					try
					{
						var x:XML = new XML( txt );
						importPatch( x );
					}
					catch (e:Error)
					{
						Console.log("Error Import Patch: " + e);
					}
				}
				else
				{
					Console.log("Error: Import Patch file is empty");
				}
			}
			else
			{
				Console.log("Error: Already importing Patch file..");
			}
		}
		
		private static function importPatchSelected (event:Event) :void
		{
			importContentPatchFile( File(event.target).url );
		}
		
		private static function installTemplateSelected (event:Event) :void {
			installingTemplate = true;
			var r:URLRequest = new URLRequest( File( event.target ).url );
			var tmplDir:File =  File.applicationStorageDirectory.resolvePath( CTOptions.templateStorage );
			tmplDir.createDirectory();
			newFolder = CTImporter.extractZipFile( r, tmplDir, installTmplExtractComplete );
		}
		private static var tmplUpdateConfig:XML;
		private static var updateType:String="template";
		
		private static function updateTmplDone ( res:DBResult ) :void
		{
			CTTools.saveDirty = true;
			CTTools.invalidateFiles();
			
			if( templateUpdateCmds != "") {
				CTTools.runCommandList (templateUpdateCmds, updateTmplCmdsDone);
			}else{
				updateTmplCmdsDone();
			}
		}
		private static function updateTmplCmdsDone () :void {
			installingTemplate = false;
			Application.instance.cmd("Application restart");
		}
		private static var templateUpdateCmds:String="";
		
		private static function updateTmplExtractComplete () :void
		{
			if( newFolder != "" )
			{
				var dir:File = File.applicationStorageDirectory.resolvePath( CTOptions.tmpDir + CTOptions.urlSeparator + newFolder );
				
				var fs:Array = dir.getDirectoryListing();
				var L:int = fs.length;
				var i:int;
				var f:File = dir.resolvePath("ctx.xml");
				
				updateType = "template";
				templateUpdateCmds = "";
				
				if( f.exists )
				{
					var updateConfig:XML = new XML( CTTools.readTextFile(f.url) );
					tmplUpdateConfig = updateConfig;
					var s:String = " Installing Update\n==================\n";
					
					if( updateConfig.ctx.@name != undefined ) s += "Name: "+ updateConfig.ctx.@name + "\n";
					if( updateConfig.ctx.@version != undefined ) s += " - "+ updateConfig.ctx.@version + "";
					if( updateConfig.ctx.@date != undefined ) s += " ("+ updateConfig.ctx.@date + ")\n";
					if( updateConfig.ctx.@cmds != undefined ) templateUpdateCmds = updateConfig.ctx.@cmds.toString();
					
					if( updateConfig.ctx.@type != undefined ) {
						updateType = updateConfig.ctx.@type;
						s += "Type: "+ updateType + "\n";
					}
				}
				
				if( updateType == "template" )
				{
					// Copy zip contents to project-dir/tmpl/
					// move ctx/st/subtempl/ to tmpl/subtempl/
					// leave st/icons in tmpl/st/icons
					// Console.log("Update Template");
					
					for (i=0; i<L; i++) {
						
						f = fs[i];
						
						if( f.isDirectory )
						{
							if( f.name == CTOptions.subtemplateFolder ) {
								// update subtemplates 
								updateSTFolder( f );
							}else{
								// Copy files in folder to /tmpl/
								CTTools.copyFolder( f.url, CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + f.name );
							}
						}
						else
						{
							// Copy file in folder to /tmpl/
							CTTools.copyFile( f.url, CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + f.name );
						}
					}
					
					if( updateConfig ) {
						// Execute Template Update SQL commands if set in ctx.xml
						if( updateConfig.ctx.@sqlquery != undefined ) {
							var sql:String = CTTools.readTextFile( dir.resolvePath(updateConfig.ctx.@sqlquery.toString()).url );
							CTTools.execSql( sql, updateTmplDone );
							return;
						}
					}
				}
				else if( updateType == "sub-template" ) {
					// Copy files in zip to tmpl/subtemplate-name
					// Copy icons in zip/icons to tmpl/st/icons
					// Update cmd.xml
					// Store New Subtemplate local for app-restarts to load installed subtemplates
					for (i=0; i<L; i++)
					{						
						f = fs[i];
						if( f.isDirectory ) {
							Application.instance.cmd( "CTTools subtemplate " + f.url );
						}
					}
					
				}
				else if( updateType == "config" )
				{
					// Copy files to config directory and restart
					var cfgFolder:File = File.applicationStorageDirectory.resolvePath(  CTOptions.configFolder );
					
					for (i=0; i<L; i++)
					{						
						f = fs[i];
						if( f.isDirectory ) {
							CTTools.copyFolder( f.url, cfgFolder.url );
						}else{
							CTTools.copyFile( f.url, cfgFolder.resolvePath(f.name).url );
						}
					}
					Application.instance.cmd("Application restart");
				}
				else if( updateType == "plugin" ) {
					// copy files from zip to plugin-directory
					
				}
				updateTmplDone(null);
			}
		}
		
		private static function updateSTFolder (f:File) :void
		{
			var dir:File = f;
			if( dir.exists  && dir.isDirectory ) 
			{
				var fs:Array = dir.getDirectoryListing();
				var L:int = fs.length;
				for (var i:int=0; i<L; i++) {
					f = fs[i];
					if( f.isDirectory ) {
						if( f.name == "icons" ) {
							CTTools.copyFolder( f.url, CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + "icons" );
						}else{
							copySTFolder( f );
						}
					}
				}
			}
		}
		
		
		private static function copySTFolder (f:File) :void {
			var dir:File = f;
			if( dir.exists  && dir.isDirectory )
			{
				var ti:File = dir.resolvePath( CTOptions.templateIndexFile );
				if( ti.exists ) {
					
					var txi:XML = new XML( CTTools.readTextFile( ti.url ) );
					
					var stName:String = txi.template.@name || dir.name;
					
					if( CTOptions.debugOutput )  Console.log( "Update Subtemplate: " + stName );
					
					var parentFolder:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + stName);
					if( !parentFolder.exists ) parentFolder.createDirectory();
					
					// Copy files to project-dir/tmpl/subtemplate-name/
					var fs:Array = dir.getDirectoryListing();
					var L:int = fs.length;
					for (var i:int=0; i<L; i++) {
						f = fs[i];
						var destUrl:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + stName + CTOptions.urlSeparator + f.name;
						CTTools.copyFile( f.url, destUrl );
					}
				}else{
					CTTools.copyFolder( f.url, CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + CTOptions.subtemplateFolder + CTOptions.urlSeparator + f.name );
				}
			}
		}
		
		private static function updateTemplateSelected (event:Event) :void {
			installingTemplate = true;
			var r:URLRequest = new URLRequest( File( event.target ).url );
			var tmplDir:File =  File.applicationStorageDirectory.resolvePath( CTOptions.tmpDir );
			tmplDir.createDirectory();
			newFolder = CTImporter.extractZipFile( r, tmplDir, updateTmplExtractComplete );
		}
		
		public static function export_sql ( T:Template ) :String
		{
			var tistr:String = CTTools.readTextFile( T.genericPath + CTOptions.urlSeparator + CTOptions.templateIndexFile );
			if( tistr )
			{
				var txo:XML = new XML( tistr );
				
				if( txo.@template )
				{
					var i:int;
					var j:int;
					var L2:int;
					
					var name:String = txo.template.@name;
					var tbl:String = txo.template.@tables;
					var fld:String = txo.template.@fields;
					var fields:Array = fld.split(",");
					L2 = fields.length;
					
					var sql:String="";
					
					sql += "CREATE TABLE IF NOT EXISTS " + tbl + "(\n";
					sql += "uid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,\n";
					sql += "name TEXT,\n";
					for(i=0; i<L2-1; i++) {
						sql += fields[i] + " TEXT,\n";
					}
					sql += fields[ fields.length-1 ] + " TEXT\n";
					sql += ");\n";
					
					var pi:Array = CTTools.pageItems;
					var pg:Object;
					
					var L:int = pi.length;
					var sid:int=0;
					
					for( i=0; i<L; i++) 
					{
						pg = pi[i];
						
						if( pg.subtemplate == name ) 
						{
							sql += 'INSERT INTO pageitem ("name","visible","area","sortid","subtemplate","crdate") VALUES ("'+pg.name+'","'+(pg.visible==null||!pg.visible?"false":"true")+'","'+pg.area+'",'+sid+',"'+name+'","now");\n';
							sql += 'INSERT INTO ' + tbl + ' (';
							
							for(j=0; j<L2-1; j++) {
								sql += '"' + fields[j] + '",';
							}
							sql += '"' + fields[L2-1] + '") VALUES (';
							
							for(j=0; j<L2-1; j++) {
								
								if( fields[j] == "crdate" ) {
									sql += '"now",';
								}else{
									sql += '"' + HtmlParser.toDBText( pg[ fields[j] ], true, true ) + '",';
								}
							}
							if( fields[L2-1] == "crdate" ) {
								sql += '"now");\n';
							}else{
								sql += '"' + HtmlParser.toDBText( pg[ fields[L2-1] ], true, true ) + '");\n';
							}
							sid++;
						}					
					}
					return sql;					
				}
				else Console.log("TEMPLATE-ERROR No Template Node Found: Missing In " + T.genericPath );
			}
			else Console.log("TEMPLATE-ERROR No Template Index File Found: 'config.xml' Missing In " + T.genericPath );
			return "";
		}
		
		public static function export_xml ( T:Template ) :String
		{
			var tistr:String = CTTools.readTextFile( T.genericPath + CTOptions.urlSeparator + CTOptions.templateIndexFile );
			
			if( tistr )
			{
				var txo:XML = new XML( tistr );
				
				if( txo.@template )
				{
					var i:int;
					var j:int;
					var L2:int;
					
					var name:String = txo.template.@name;
					
					var fld:String = txo.template.@fields;
					var fields:Array = fld.split(",");
					L2 = fields.length;
					var xm:String = "";
					var pi:Array = CTTools.pageItems;
					var pg:Object;
					
					var L:int = pi.length;
					
					for( i=0; i<L; i++) 
					{
						pg = pi[i];
						
						if( pg.subtemplate == name ) 
						{
							xm += "<item";
							for(j=0; j<L2-1; j++) {
								if( fields[j] == "crdate" ) {
									xm += ' crdate="now"'
								}else{
									xm += ' ' + fields[j] + '="' + HtmlParser.toDBText( pg[ fields[j] ], true, true) + '"';
								}
							}
							if( fields[L2-1] == "crdate" ) {
								xm += ' crdate="now"/>\n'
							}else{
								xm += ' ' + fields[L2-1] + '="' + HtmlParser.toDBText( pg[ fields[L2-1] ], true, true ) + '"/>\n';
							}
						}					
					}
					return xm;					
				}
				else Console.log("EXPORT-XML: TEMPLATE-ERROR No Template Node Found: Missing In " + T.genericPath );
			}
			else Console.log("EXPORT-XML: TEMPLATE-ERROR No Template Index File Found: 'config.xml' Missing In " + T.genericPath );
			return "";
		}
		
		public static function export_all () :String
		{
			// Export all PageItems in sorting order as xml..
			// Sort PageItems By Area & sortid
			
			var xm:String = '<?xml version="1.0" encoding="utf-8" ?>\n<ct>\n';
			var tmpl:Template = CTTools.activeTemplate;
			
			if( tmpl )
			{
				var L:int;
				var i:int;
				var aname:String;
				
				var date:Date = new Date();
				xm += "<!-- \n   Contemple "+CTOptions.version+"\n   Website Content Export\n   Theme: " + Language.getKeyword(tmpl.name) + " (" + tmpl.name +")\n   Date: " + date.getDate() + ". " + (date.getMonth()+1) + ". " + date.getFullYear() + "\n-->\n";
				
				// Export <tmpl from activeTemplate + CTTools.subTemplates
				
				xm += "\n   <!-- Templates -->\n";
				xm += '   <tmpl name="'+ tmpl.name +'" indexfile="'+ tmpl.indexFile +'" />\n';
				if( CTTools.subTemplates && CTTools.subTemplates.length > 0 ) {
					L = CTTools.subTemplates.length;
					for( i=0; i<L; i++) {
						xm += '   <tmpl name="'+ CTTools.subTemplates[i].name +'" indexfile="'+ CTTools.subTemplates[i].indexFile + '" />\n';
					}
				}
				
				xm += "\n   <!-- Template Properties -->\n";
				
				// Export <prop form activeTemplate.dbProps
				if( tmpl.dbProps )
				{	
					L = CTTools.procFiles.length;
					var pf:ProjectFile;
					var jL:int;
					var j:int;
					var propName:String;
					var propType:String;
					var secj:String;
					var propVal:String;
					var propStore:Object = {};
					
					for(i = 0; i<L; i++)
					{
						pf = CTTools.procFiles[ i ] as ProjectFile;
						
						if( pf.templateId == tmpl.name )
						{
							if( pf.templateProperties )
							{
								jL = pf.templateProperties.length;
								for(j=0; j<jL; j++)
								{
									propName = pf.templateProperties[j].name;
									if( propName == "name" ) continue;
									propType = pf.templateProperties[j].defType.toLowerCase();
									
									if( propType == "folder" || propType == "label" || propType == "section" ) {
										continue;
									}
									
									
									if( pf.templateProperties[j].sections != null ) {
										secj = pf.templateProperties[j].sections.join(".");
									}else{
										secj = "";
									}
									
									
									// Input
									if( secj && tmpl.dbProps[ secj + "." + propName ] )
									{
										if( propStore[ secj + "." + propName] ) continue;
										propStore[ secj + "." + propName] = true;
										
										propVal = tmpl.dbProps[secj + "." + propName].value;
										
	xm += '   <prop name="'+propName+'" type="'+pf.templateProperties[j].defType+'" section="' + secj + '" value="'+ HtmlParser.toDBText( propVal, true, true)+'" templateid="1" />\n';

									}
									else if( !secj && tmpl.dbProps[ propName ] )
									{
										propVal = typeof tmpl.dbProps[ propName ] == "object" ? tmpl.dbProps[ propName ].value : tmpl.dbProps[ propName ];
	xm += '   <prop name="'+propName+'" type="'+pf.templateProperties[j].defType+'" section="" value="'+ HtmlParser.toDBText( propVal, true, true)+'" templateid="'+pf.templateId+'" />\n';

									}
								}
							}
						}
					}
				}
				
				if( CTTools.pageItems )
				{	
					var pageItems:Array = CTTools.pageItems;
					
					pageItems.sortOn("sortid", Array.NUMERIC);
					
					L = pageItems.length;
					var piByArea:Object = { };
					
					for( i = 0; i < L; i++ ) {
						if( piByArea[ pageItems[i].area ] == undefined ) {
							piByArea[ pageItems[i].area ] = [];
						}
						piByArea[ pageItems[i].area ].push( pageItems[i] );
					}
					
					var arr:Array;
					var fields:Array;
					var T:Template;
					var L2:int;
					
					for( aname in piByArea )
					{
						xm += "\n   <!-- Page Items in Area '" + aname + "' -->\n";
						
						arr = piByArea[ aname ];
						L = arr.length;
						
						for( i=0; i<L; i++ )
						{
							xm += '   <item name="' + arr[i].name + '" sortid="'+i+'" visible="' + (( arr[i].visible == undefined || arr[i].visible == null)  ? "true" : arr[i].visible) + '" area="' + aname + '" subtemplate="'+arr[i].subtemplate+'" ';
							
							T = CTTools.findTemplate( arr[i].subtemplate, "name" );
							
							if( T ) {
								fields = T.fields.split(",");
								
								if( fields && fields.length > 0 ) {
									L2 = fields.length;
									for(j=0; j<L2; j++ )
									{
										if( arr[i][fields[j]] != undefined )
										{
											if( fields[j] != "name" && fields[j] != "visible" && fields[j] != "crdate"  ) {
												xm += " " + fields[j] + '="'+ HtmlParser.toDBText( arr[i][fields[j]], true, true ) +'"';
											}
										}
									}
									xm += "/>\n";
								}
							}
							// for fields...
						} // for area items
					} // for areas
				}
				
				xm += "\n   <!-- Pages -->\n";
				// Export <page from CTTools.pages + CTTools.articlePages
				if( CTTools.pages )
				{
					L = CTTools.pages.length;
					for( i=0; i<L; i++) {
						xm += '   <page name="'+CTTools.pages[i].name+'" visible="'+CTTools.pages[i].visible+'" title="'+CTTools.pages[i].title+'" type="'+CTTools.pages[i].type+'" template="'+CTTools.pages[i].template+'" parent="'+CTTools.pages[i].parent+'" webdir="'+CTTools.pages[i].webdir+'" filename="'+CTTools.pages[i].filename+'" crdate="now" />\n';
					}
				}
				if( CTTools.articlePages )
				{
					L = CTTools.articlePages.length;
					for( i=0; i<L; i++) {
						xm += '   <page name="'+CTTools.articlePages[i].name+'" visible="'+CTTools.articlePages[i].visible+'" title="'+CTTools.articlePages[i].title+'" type="'+CTTools.articlePages[i].type+'" template="'+CTTools.articlePages[i].template+'" parent="'+CTTools.articlePages[i].parent+'" webdir="'+CTTools.articlePages[i].webdir+'" filename="'+CTTools.articlePages[i].filename+'" crdate="now" />\n';
					}
				}
			}
			
			xm += "\n</ct>\n";
			
			return xm;
		}
		
		public static function createTemplate ( name:String, type:String, index:String, files:String="", folders:String="", tables:String="", fields:String="", sortproperties:String="priority", 
												label:String="", icon:String="", articlepage:String="", articlename:String="", parselistlabel:Boolean=false ) :Boolean {
			newSTName = name;
			newSTType = type;
			newSTIndex = index;
			newSTFiles = files;
			newSTFolders = folders;
			newSTTables = tables;
			newSTFields = fields;
			newSTSortproperties = sortproperties;
			newSTLabel = label;
			newSTIcon = icon;
			newSTArticlename = articlename;
			newSTArticlepage = articlepage;
			newSTParselistlabel = parselistlabel;
			
			if( type == "root" ) {
				// Ask for new template folder
				getNewTmplFolder( createRootTemplate );
			}else{
				// Create folder with 'name' in current project/tmpl/st folder
				var tmpl:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate );
				var st :File = tmpl.resolvePath( CTOptions.subtemplateFolder );
				st.createDirectory();
				
				createSubTemplate( st, newSTName, newSTType, newSTIndex, "", newSTFiles, newSTFolders, newSTLabel, newSTIcon, newSTFields, newSTTables, newSTSortproperties, newSTArticlepage, newSTArticlename, newSTParselistlabel );
				
				setTimeout( function () {
					Application.instance.cmd( "CTTools subtemplate template:/st/" + newSTName );
				}, 0 );
				
			}
			return true;
		}
		private static function dirForOpenSelected (event:Event) :void {
			var directory:File = event.target as File;
			var dir:String = directory.url;
			newSTTemplateFolder = dir;
			if(newSTCompleteHandler != null) newSTCompleteHandler();
		}
		
		public static function folderNameSelected (name:String) :void {
			var directory:File = File.documentsDirectory.resolvePath( name );
			var dir:String = directory.url;
			newSTTemplateFolder = dir;
			if(newSTCompleteHandler != null) newSTCompleteHandler();
		}
		
		
		private static function createSubTemplate ( stFolder:File, name:String, type:String, index_name:String, index_str:String, files:String, folders:String, listlabel:String, listicon:String, fields:String, table:String, sort:String="priority", 
													articlepage:String="", articlename:String="", parselistlabel:Boolean=false) :void
		{
			var st_folder:File = stFolder.resolvePath(name);
			st_folder.createDirectory();
			
			var dp:int =  fields.indexOf(":");
			
			if(dp >= 0 )
			{
				var sp:Array = fields.split(",");
				var f:String = "";
				
				for( var i:int=0; i<sp.length; i++ ) {
					dp = sp[i].indexOf(":");
					if( dp >= 0 ) {
						f += sp[i].substring(dp + 1) + ",";
					}else{
						f += sp[i] + ",";
					}
				}
				fields = f.substring( 0, f.length -1);
			}
			var ti:File = st_folder.resolvePath(CTOptions.templateIndexFile);
			var tistr:String = '<template \r\n        name="' + name+'" \r\n        type="'+type+'" \r\n        index="'+index_name+'" \r\n        files="' + 
								files+'" \r\n        folders="'+folders+'"  \r\n        fields="'+fields+'"  \r\n        tables="'+ table + 
			'" \r\n        help="help.xml" \r\n        initquery="" \r\n        defaultquery="" \r\n        sortareas="priority" \r\n        sortproperties="priority" \r\n        templatefolders="" \r\n        listlabel="' + 
								listlabel+'" \r\n        listicon="'+listicon+'"  \r\n        articlepage="'+articlepage+'"  \r\n        articlename="'+articlename+'" \r\n        parselistlabel="'+parselistlabel+'">\r\n    </template>';
			
			CTTools.writeTextFile( ti.url, '<?xml version="1.0" encoding="utf-8"?>\r\n<ct>\r\n    '+tistr+'\r\n</ct>' );
			
			var help:File = st_folder.resolvePath("help.xml");
			CTTools.writeTextFile( help.url, '<?xml version="1.0" encoding="utf-8" ?>\r\n<ct>\r\n\r\n<item name="'+name+'">\r\n        <lang name="en" value="'+name+'"/>\r\n        <lang name="de" value="'+name+'"/>\r\n    </item>\r\n</ct>' );
			
			var indexfile:File = st_folder.resolvePath(index_name);
			CTTools.writeTextFile( indexfile.url, index_str );
		}
		
		private static function createRootTemplate () :void
		{
			var tmpl:File = new File( newSTTemplateFolder );
			var st :File = tmpl.resolvePath( CTOptions.subtemplateFolder );
			st.createDirectory();
			
			var text_html:String = "<!-- \r\n#def:\r\nname:Name;\r\nvalue:RichText('cssclass1,cssclass2','<p>|</p>');\r\n#def;\r\n-->\r\n<p>{#value}</p>\r\n";
			var img_html:String = '<!-- \r\n#def:\r\nname:Name;\r\nstyle:List("original","fullsize","left","center","right");\r\npicture:Image("img","image-#year#-#month#-#date#-#hour#-#minutes#-#inputname#.#extension#");\r\n#def;\r\n-->\r\n<img class="{#style}" src="{#picture}">\r\n';
			var menu_html:String = "<!-- \r\n#def:\r\nname:Name;\r\nvalue:RichText('cssclass1,cssclass2','<p>|</p>');\r\n#def;\r\n-->\r\n<p>{#value}</p>\r\n";
			
			
			createSubTemplate( st, "app.contemple.text", "content", "text.html", text_html, "", "", "Text: #value#", "ico:/pencil.png", "name,style,value", "app_contemple_text" ); 
			createSubTemplate( st, "app.contemple.image", "content", "image.html", img_html, "", "", "Image: #value#", "ico:/iamge.png", "name,style,picture", "app_contemple_image" );
			createSubTemplate( st, "app.contemple.menu", "menu", "link.html", menu_html, "", "", "Link: #label#", "ico:/menu.png", "name,label,link", "app_contemple_menu" );
			
			
			var ti:File = tmpl.resolvePath(CTOptions.templateIndexFile);
			var tistr:String = '<template \r\n        name="' + newSTName+'" \r\n        type="'+newSTType+'" \r\n        index="'+newSTIndex+'" \r\n        files="'+newSTFiles+'" \r\n        folders="'+newSTFolders+'" \r\n        help="help.xml" \r\n        dbcmds="cmd.xml" \r\n        sortareas="priority" \r\n        sortproperties="'+newSTSortproperties+'" \r\n        templatefolders="">\r\n    </template>';
			
			CTTools.writeTextFile( ti.url, '<?xml version="1.0" encoding="utf-8"?>\r\n<ct>\r\n    '+tistr+'\r\n</ct>' );
			
			var cmd:File = tmpl.resolvePath("cmd.xml");
			var cmdstr:String = '    <appload>\r\n    <!-- App Load Commands Execute Once On Load -->\r\n</appload>\r\n    <dbcreate>\r\n        <cmd name="CTTools subtemplate template-generic:/st/app.contemple.text"/>\r\n        <cmd name="CTTools subtemplate template-generic:/st/app.contemple.image"/>\r\n        <cmd name="CTTools subtemplate template-generic:/st/app.contemple.menu-item"/>\r\n    </dbcreate>';
			CTTools.writeTextFile( cmd.url, '<?xml version="1.0" encoding="utf-8"?>\r\n<ct>\r\n    <appstart>\r\n    <!-- App Start Commands Execute Every Restart -->\r\n    </appstart>\r\n'+cmdstr+'\r\n</ct>' );
			
			var help:File = tmpl.resolvePath("help.xml");
			CTTools.writeTextFile( help.url, '<?xml version="1.0" encoding="utf-8" ?>\r\n<ct>\r\n    <item name="Welcome">\r\n        <lang name="en" value="Welcome"/>\r\n        <lang name="de" value="Willkommen"/>\r\n    </item>\r\n<item name="'+newSTName+'">\r\n        <lang name="en" value="'+newSTName+'"/>\r\n        <lang name="de" value="'+newSTName+'"/>\r\n    </item>\r\n</ct>' );
			
			var jsw:Boolean = false;
			var cssw:Boolean = false;
			var flist:Array = newSTFiles.split(",");
			var L:int = flist.length;
			var filetext:String;
			var i:int;
			var file:File;
			var embedfiles:String='';
			var tmpString:String;
			var pathOk:Boolean;
			var pathName:String;
			var pathExtension:String;
			var pathSt:int;
			
			for(i=0; i<L; i++)
			{
				tmpString = flist[i];
				if( CTOptions.debugOutput ) Console.log( "file: " +tmpString +'');
				pathOk = true;
				
				try {
					file = new File(flist[i]);
				}catch(e:Error) {
					pathOk = false;
					pathSt = tmpString.lastIndexOf(CTOptions.urlSeparator);
					if( pathSt >= 0  ) {
						pathName = tmpString.substring( pathSt+1 );
					}else{
						pathName = tmpString;
					}
					pathSt = pathName.lastIndexOf(".");
					if( pathSt >= 0 ) {
						pathExtension = pathName.substring(pathSt+1);
						pathName = pathName.substring(0, pathSt);
					}else{
						pathExtension = "";
					}
				}
				
				if( pathOk ) {
					if( file.isDirectory ) continue;
					if( CTOptions.debugOutput ) Console.log("Copy File: " + file.name + " " + file.extension);
					CTTools.copyFile( file.url, tmpl.resolvePath( file.name /*+ "."+file.extension*/).url );
				}else{
					
					file = tmpl.resolvePath( pathName + ( pathExtension == "" ? "" : "."+pathExtension) );
					
					filetext = '';
					
					if( file.extension == "js" && !jsw) {
						jsw = true;
						filetext = "";//'(function ($) {\r\n    if(typeof onepage_p1 == "undefined") \r\n{\r\n     onepage_p1 = {\r\n    docStart:function() {}\r\n}\r\n     var p = onepage_p1;\r\n  };\r\n})(jQuery);';
						embedfiles += '\r\n    <script type=text/javascript src='+file.name+"."+file.extension+'></script>';
					} else if( file.extension == "css" && !cssw) {
						cssw = true;
						filetext = 'html { font-size:13px; overflow:hidden; }\r\nbody,div,dl,dt,dd,ul,ol,li,nav,h1,h2,h3,h4,h5,h6,pre,code,form,fieldset,legend,input,button,textarea,blockquote,th,td,a {\r\n    margin:0px; padding:0px;\r\n    border-width: 0;\r\n    text-shadow:none;\r\n    -webkit-transform-origin: left top;\r\n    -ms-transform-origin: left top;\r\n    -o-transform-origin: left top;\r\n    transform-origin: left top;\r\n    -webkit-box-sizing: border-box;\r\n    -moz-box-sizing: border-box;\r\n    box-sizing: border-box;\r\n    font-family:"Roboto", "Myriad Pro", Arial;\r\n}\r\nb { font-weight:bold; }\r\nimg,table { margin:0px; padding:0px; border-width: 0; }';
						embedfiles += '\r\n    <link href='+file.name + "." + file.extension+' rel=stylesheet>';
					}
					CTTools.writeTextFile( file.url, filetext );
				}
			}
			
			pathOk = true;
			var indexFile:File;
			
			try {
				indexFile = new File(newSTIndex);
			}catch(e:Error) {
				
				tmpString  =  newSTIndex;
				
				pathOk = false;
				pathSt = tmpString.lastIndexOf(CTOptions.urlSeparator);
				if( pathSt >= 0 ) {
					pathName = tmpString.substring( pathSt+1 );
				}else{
					pathName = tmpString;
				}
				pathSt = pathName.lastIndexOf(".");
				if( pathSt >= 0 ) {
					pathExtension = pathName.substring(pathSt+1);
					pathName = pathName.substring(0, pathSt);
				}else{
					pathExtension = "";
				}
				indexFile = tmpl.resolvePath( pathName + ( pathExtension == "" ? "" : "."+pathExtension) );
			}
			
			if( indexFile.exists )
			{
				CTTools.copyFile( indexFile.url, tmpl.resolvePath(newSTIndex).url );
			}
			else
			{
				//newSTIndex);
				var head:String = '\r\n    <meta charset=utf-8>\r\n    <meta name=mobile-web-app-capable content=yes>\r\n    <meta name=viewport content=width=device-width,initial-scale=1.0,minimum-scale={#8.MOBILE-MIN-SCALE:Number(0.1,20,0.1)=1},maximum-scale={#9.MOBILE-MAX-SCALE:Number(0.1,20,0.1)=1},user-scalable={#7.ALLOW-SCALE-ON-MOBILE-DEVICES:Boolean(1,0)=0}>';
				head += '\r\n    <meta name="apple-mobile-web-app-capable" content="yes">\r\n    <meta name="apple-mobile-web-app-status-bar-style" content="black">\r\n    <meta name="description" content="{#4.PAGE-DESCRIPTION:String}">\r\n    <meta name="author" content="{#3.PAGE-AUTHOR:String}">\r\n';
				var body:String = '\r\n    <div class=header>\r\n        <img src={#10.LOGO:Image(images,logo.jpg,*.jpg;*.png;*.gif,*.svg)}>\r\n    </div>\r\n    <div class=menu>\r\n        {##MENU:menu}\r\n    </div>\r\n    <div class=content>\r\n        {##CONTENT:content}\r\n    </div>';
				CTTools.writeTextFile( indexFile.url, '<!DOCTYPE html>\r\n<html lang=de>\r\n<head>\r\n    {#1.GeneralOptionsLabel:Section("Gerneral Options")}'+head+embedfiles+'\r\n</head>\r\n<body>'+body+'\r\n</body>\r\n</html>');
			}
			
			flist = newSTFolders.split(",");
			L = flist.length;
			
			for(i=0; i<L; i++)
			{
				pathOk = true;
				
				try {
					file = new File(flist[i]);
				}catch( e:Error ) {
					tmpString  =  flist[i];
					pathOk = false;
				}
				
				if( pathOk  ) {
					if( file.isDirectory ) {
						if( CTOptions.debugOutput ) Console.log("Copy Folder: " + file.name);
						CTTools.copyFolder( file.url, tmpl.resolvePath( file.name /*+ "."+file.extension*/).url );
					}
				}else{
					file = tmpl.resolvePath( flist[i] );
					if( CTOptions.debugOutput ) Console.log("Create Folder: " + file.name);
					file.createDirectory();
				}
			}
			
			if( CTOptions.debugOutput ) Console.log("Root Template Created in " + tmpl.url);
			
			Application.instance.cmd( "CTTools template "  +  tmpl.url );
			
		}
		
		private static function newTemplate () :void
		{
			if( newSTWin != null) return;
			
			
			var main:CTMain = CTMain( Application.instance );
			
			var win:Window = Window( main.window.ContentWindow( "NewSubtemplateWindow", agf.ui.Language.getKeyword("CT-NewsubtemplateTitle"), null, {
				complete: function (b:Boolean) {
					if ( b ) {
						Application.instance.cmd("Console clear show console;Console log Create Template");
							createTemplate ( win.options.content.getChildByName("name_pc").textBox.value,
												win.options.content.getChildByName("type_pc").textBox.value,
												win.options.content.getChildByName("index_pc").textBox.value,
												win.options.content.getChildByName("files_pc").textBox.value,
												win.options.content.getChildByName("folders_pc").textBox.value,
												win.options.content.getChildByName("tables_pc").textBox.value,
												win.options.content.getChildByName("fields_pc").textBox.value,
												win.options.content.getChildByName("sortproperties_pc").textBox.value,
												win.options.content.getChildByName("listlabel_pc").textBox.value,
												win.options.content.getChildByName("listicon_pc").textBox.value
							);
					}
				},
				close: function () {
					newSTWin = null;
				},
				continueLabel:Language.getKeyword("Create Template"),
				allowCancel: true,
				autoWidth:false,
				autoHeight:false,
				cancelLabel: Language.getKeyword("Cancel")
				}, 'newsubtemplate-window') );
				
			var form:CssSprite = new CssSprite(0,0,win.body,styl,"newtemplateform",'','new-subtemplate-form', false);
			form.y = win.title.cssSizeY;
				
			newSTWin = win;
			
			var ww:int = win.getWidth();
			var wh:int = win.getHeight()-win.title.getHeight();
				
			var cw:Number = main.view.panel.getWidth() - HtmlEditor.previewX;
			var ch:Number = main.view.panel.getHeight() - main.mainMenu.cssSizeY;
			
			var ww2:int = cw - 48;
			Application.instance.windows.addChild( win );
			
			form.cssWidth = 0;
			form.cssHeight = 0;
			form.init();
			
			var sp:ScrollContainer = new ScrollContainer(ww,ch-48,form,styl,'','new-subtemplate-form-container',false);
			var styl:CssStyleSheet = Main(Application.instance).config;
			var tmplTypes:Array = ["root"];
			var prjat:Object={};
			var arr:Vector.<String>;
			var k:int;
			
			if( CTTools.activeTemplate ) {
				var areas:Object = CTTools.activeTemplate.areasByName;
				var a:String;
				var nam:String;
				for(nam in areas) {
					if( areas[nam].types != undefined) {
						arr = areas[nam].types;
						for(k=0;k<arr.length;k++) {
							prjat[arr[k]]=true;
						}
					}
					prjat[areas[nam].type]=true;
				}
				
				for(nam in prjat) tmplTypes.push(nam);
			}
			
			// type can be intern, hiddem, name, string, code, richtext, number, integer, screennumber, screeninteger, boolean, color, list, listappend, labellist, arealist, vector<T>, vectorlink,
			// file, files, image, audio, video, pdf, or directory
			var content:ItemList = new ItemList(0,0,sp.content,styl,"contentform",'',false);
			content.margin = 0;
			var name_pc:PropertyCtrl = new PropertyCtrl( "Name", "name_pc", "name", "", null, null, ww2, 0, content, styl,'','',false);
			var type_pc:PropertyCtrl = new PropertyCtrl( "Type", "type_pc", "list", "", null, tmplTypes, ww2, 0, content, styl,'','',false);
			var index_pc:PropertyCtrl = new PropertyCtrl( "Index File", "index_pc", "file", "", null, ["","","Select Index File","*.*"], ww2, 0, content, styl,'','',false);
			var files_pc:PropertyCtrl = new PropertyCtrl( "Files", "files_pc", "vector", "", null,  [0,"File","",",",true,"","","Select folder with static files","*.*"], ww2, 0, content, styl,'','',false);
			var folders_pc:PropertyCtrl = new PropertyCtrl( "Folders", "folders_pc", "vector", "", null,  [0,"Directory","",",",true,"","","Select folder with static files","*.*"], ww2, 0, content, styl,'','',false);
			var tables_pc:PropertyCtrl = new PropertyCtrl( "Tables", "tables_pc", "vector", "", null,  [0,"String","",",",true], ww2, 0, content, styl,'','',false);
			var fields_pc:PropertyCtrl = new PropertyCtrl(  "Fields", "fields_pc", "vector", "", null, [0,"Typed","",",",true,
				["AreaList","Audio","Boolean","Code","Color","Directory","File","Files","Hidden","Image","Integer","Intern","List","ListAppend","ListMultiple","LabelList","Label","Name","Number","Pdf","ScreenInteger",
			"ScreenNumber","Section","String","Richtext","Text","Vector","VectorLink","Video"]], ww2, 0, content, styl,'','',false);
			var sortproperties_pc:PropertyCtrl = new PropertyCtrl( "Sort Properties", "sortproperties_pc", "list", "", null, ["name","priority"], ww2, 0, content, styl,'','',false);
			var listlabel_pc:PropertyCtrl = new PropertyCtrl( "Label", "listlabel_pc", "string", "", null, null, ww2, 0, content, styl,'','',false);
			var listicon_pc:PropertyCtrl = new PropertyCtrl( "Icon", "listicon_pc", "list", "", null, ["st/icons/image.png","st/icons/monitor.png","st/icons/pencil.png","st/icons/image.png","st/icons/paper-plane.png","st/icons/list.png","st/icons/lr.png","st/icons/row.png","st/icons/spacer.png"], ww2, 0, content, styl,'','',false);
			
			files_pc.textBox.addEventListener( "heightChange", newSTFormUpdate);
			folders_pc.textBox.addEventListener( "heightChange", newSTFormUpdate);
			tables_pc.textBox.addEventListener( "heightChange", newSTFormUpdate);
			fields_pc.textBox.addEventListener( "heightChange", newSTFormUpdate);
			
			content.addItem( name_pc, true );
			content.addItem( type_pc, true );
			content.addItem( index_pc, true );
			content.addItem( files_pc, true );
			content.addItem( folders_pc, true );
			content.addItem( tables_pc, true );
			content.addItem( fields_pc, true );
			content.addItem( sortproperties_pc, true );
			content.addItem( listlabel_pc, true );
			content.addItem( listicon_pc, true );
			
			content.format(true);
			content.init();
			
			sp.setWidth( ww - 48 );
			sp.setHeight( ch  );
			
			win.options.content = content;
			win.options.sp = sp;
			sp.contentHeightChange();
			
			return;
		}
		
		// browser for project
		public static function getNewTmplFolder ( completeHandler:Function=null ) :void {
			
			if( CTOptions.isMobile ) {
				// Get folder name in documents dir
				var win1:Window = Window( Application.instance.window.GetStringWindow( "NewTemplateMBNameWindow", agf.ui.Language.getKeyword("CT-New-Template-Name"), Language.getKeyword("CT-New-Template-Name-Msg"), {
					complete: function (str:String)
					{
						newSTCompleteHandler = createRootTemplate;
						TemplateTools.folderNameSelected(str);
					}, 
					continueLabel:Language.getKeyword("Create Folder"),
					allowCancel: true,
					autoWidth:false,
					autoHeight:true, 
					password:false,
					cancelLabel: Language.getKeyword("Cancel")
				}, 'new-template-name-window') );
				
				Application.instance.windows.addChild( win1 );
			}else{
				var directory:File;
				if( CTTools.projectDir ) directory = new File(CTTools.projectDir); 
				else directory = File.documentsDirectory;
				try {
					//Console.log("Select folder for the new root Template");
					newSTCompleteHandler = completeHandler;
					directory.browseForDirectory("Select New Project Folder");
					directory.addEventListener(Event.SELECT, dirForOpenSelected);
				}catch (error:Error) {
					Console.log("ERROR GET FOLDER:" + error.message);
				}
			}
		}
		
		// browser for import patch xml-file (.ctx)
		private static function selectImportPatchFile () :void
		{
			if( importingPatch == false ) {
				var docsDir:File = File.desktopDirectory;
				var flt:FileFilter = new FileFilter( Language.getKeyword("XML"), "*.ct;*.xml;" );
				try {
					docsDir.browseForOpen("Select Content Patch File", [flt]);
					docsDir.addEventListener(Event.SELECT, importPatchSelected); 
				}catch (error:Error){
					Console.log("Select template file error: " + error.message);
				}
			}
		}
		
		// browser for template zip-file (.ctx)
		private static function selectInstallTemplateFile () :void {
			// Get template ctx file from User
			if( installingTemplate == false ) {
				var docsDir:File = File.desktopDirectory;
				var flt:FileFilter = new FileFilter( Language.getKeyword("CTX"), "*.ctx;*.zip;" );
				try {
					docsDir.browseForOpen("Select Template File", [flt]);
					docsDir.addEventListener(Event.SELECT, installTemplateSelected); 
				}catch (error:Error){
					Console.log("Select template file error: " + error.message);
				}
			}
		}
		
		private static function selectUpdateTemplateFile () :void {
			// Get template ctx file from User
			if( installingTemplate == false ) {
				var docsDir:File = File.desktopDirectory;
				var flt:FileFilter = new FileFilter( Language.getKeyword("CTX"), "*.ctx;*.zip;" );
				try {
					docsDir.browseForOpen("Select Template File", [flt]);
					docsDir.addEventListener(Event.SELECT, updateTemplateSelected);
				}catch (error:Error){
					Console.log("Select template file error: " + error.message);
				}
			}
		}
		
		private static var newSTName:String;
		private static var newSTType:String;
		private static var newSTIndex:String;
		private static var newSTFiles:String;
		private static var newSTFolders:String;
		private static var newSTTables:String;
		private static var newSTFields:String;
		private static var newSTSortproperties:String;
		private static var newSTLabel:String;
		private static var newSTIcon:String;
		private static var newSTArticlename:String;
		private static var newSTArticlepage:String;
		private static var newSTParselistlabel:Boolean;
		
		private static var newSTTemplateFolder:String="";
		private static var newSTCompleteHandler:Function;
		private static var newSTWin:Window=null;
		
		private static function newSTFormUpdate (e:Event) :void {
			newSTWin.options.content.format();
			newSTWin.options.content.init();
			newSTWin.options.sp.contentHeightChange();
		}
		
		public static function replaceNewlines ( s:String ) :String {
			var p:RegExp = /#br#/gi;  
			return s.replace(p, " \n");  
		}
		public static function obj2Text ( s:String, filterChar:String="#", props:Object=null, isHtml:Boolean=false, useLanguage:Boolean=true ) :String
		{
			if( s ) {
				
				var L:int = s.length;
				var out:String = "";
				
				var cb:int = filterChar.charCodeAt(0);
				var ts:int; // start
				var te:int; // end
				var se:Boolean = false; // search end - flag
				var cc:int; 
				var tmp:String;
				var tmp4:String;
				var tmp5:int;
				var tmp6:int;
				var tmp2:int;
				var tmp3:int;
				var subnm:String;
				var nm:String;
				var val:String;
				var k:int;
				var k2:int;
				var n:Boolean;
				var ltlf:int = -1;
				var mdc:String = "";
				
				var mdo:int = 0;
				var mdt:String;
				var mdi:int = 0;
				var mdn:int = 0;
				var mda:String;
				
				for (var i:int=0; i<L; i++) 
				{
					cc = s.charCodeAt(i);
					
					if( cc == 9 || cc == 10 || cc == 13 )
					{
						if( mdc != "" ) {
							mdt = out.substring( mdo );
							out = out.substring( 0, mdo) + "<"+mdc+">" + mdt + "</"+mdc+">\n";
							mdc = "";
						}else{
							out += "\n";
						}
						if( i < L-1 ) {
							cc = s.charCodeAt(i+1);
							if( cc == 9 || cc == 10  || cc == 13 ) i++;
						}
						ltlf = i;
						continue;
					}
					
					if( ltlf == i - 1 )
					{
						// markdown action
						mdc = "";
						
						if( cc == 45 ) // -
						{
							if( L > i + 2 ) 
							{
								if( s.charCodeAt(i + 1) == 45 ) { // ---
									if( s.charCodeAt(i + 2) == 45 ) {
										out += "<hr/>";
										i+=2;
										continue;
									}
								}else{
									if( s.charCodeAt(i + 1) <= 32 ) { // - list
										mdc = "li";
										mdo = out.length;
										continue;
									}
								}
							}
						}else if( cc == 35 ) { // #
							
							if( L > i + 1 ) {
								mdi = s.charCodeAt(i + 1);
								if ( mdi <= 32 || mdi == 35 ) {
									for( mdi = 1; mdi <= 7; mdi++ ) {
										if( i+mdi >= L  ) break;
										if( s.charCodeAt(i + mdi) != 35 ) {
											mdc = "h" + mdi;
											mdo = out.length;
											i += mdi;
											break;
										}
									}
									continue;
								}
							}
							// ignore continue to parse old format..
						}
					}
					
					// Ignore in blocks [ .. ]
					
					if( cc == 91 ) { // [
						
						k = s.indexOf("]", i+1 );
						
						if( k >= 0 && L > k+1 && s.charCodeAt( k+1 ) == 40 )
						{
							// test for md link: [label](url)
							for( mdi = k+2; mdi < L; mdi++ )
							{
								k2 = s.charCodeAt(mdi);
								if( k2 <= 32 ) {
									// not a uri
									break;
								}else if( k2 == 41 ) {
									
									if( i > 1 && s.charAt(i-1) == "!" ) {
										out = out.substring(0, out.length-1);
										out += '<img src="'+s.substring(k+2,mdi)+'" alt="'+s.substring(i+1,k)+'" />';
									}else{
										out += '<a href="'+s.substring(k+2,mdi)+'">'+s.substring(i+1,k)+'</a>';
									}
									i = mdi+1;
									k = -1;
									break;
								}
							}
							if(k==-1) continue;
						}
						if( k > i ) {
							out += s.substring( i, k + 1 );
							i = k;
							continue;
						}
					}
					
					if(cc == cb)
					{
						if( i>0 && s.charCodeAt(i-1) == 123) continue; // ignore {#
						if( se == false && L > i+1 && s.charCodeAt(i+1) <= 32 ) continue; // ignore '# '
						
						
						if( se == false && L > i+9 && s.substring(i, i+10).toLowerCase() == "#separator" ) {
							out += "#separator";
							i += 10;
							continue;
						}
						
						if( cb == 35 && i>0 && s.charCodeAt(i-1) == 38 ) { // &#
							//test for &#NNNN;
							n = false;
							for( k = i+1; k < L; k++ ) {
								if( s.charCodeAt( k ) == 59 ) { // ;
									if( !isNaN(Number(s.substring(i+1, k))) ) {
										n = true;
										out += "#";
										break;
									}
								}
								if( k-i > 4 ) break;
							}
							if( n ) continue;
						}
						
						if(se) 
						{
							te = i;
							nm = s.substring(ts, te);
							
							// Markdown features:
							// --- <HR>
							// *italic text*
							// **bold text**
							// ***bold italic text***
							// [link-label](link-url)
							// # H1
							// ## H2 .. ###### H6
							// - list
							// 1. ordered list
							//
							//
							// Other features
							//#A:url(c.com):link #B:text#/B#/A
							//
							//
							// Parse property: nm can be a string like
							//
							// #prop# --> Object Property Value
							// #name# --> DB-Item-Name
							// #L:English Label# --> German or English Text
							// #L:name# --> German or English version of Text Of Item Name
							// #S:32:name# --> German Tex... display only the first 32 characters in name (Start)
							// #E:32:name# --> German Tex... display only the last 32 characters in name (End)
							// #C:css-calss:text#
							// #B:Bold Text# --> <b>German Bold Text</b>
							// #I:Italic Text# --> <i>German Italic Text</i>
							// #A:url(url.com):Link Text# --> <a href=url>German Link Text</a>
							// #T:url(img-path.gif):css-classes# --> <div class=css-classes><img src=url/></div>
							// #P:url(img-path.gif):css-classes# <img src=url class=css-classes>
							// #br# --> <br/> if isHtml or \n
							// #hr# --> <hr/>
							// #tab# --> return three "nbsp;" if isHtml is true, or three whitespaces
							// #app-name# --> CTOptions.appName
							// #app-verison# --> CTOptions.version
							// #template-name# --> Name or Root Template
							// #insert-template# --> Name of Sub Template while inserting or updating a subtemplate item
							// #insert-area# --> Name of the Area an item is inserted or updated
							// #insert-property# --> Name of Property that is inserted in Settings (ConstantsEditor)
							// ... 
							if(nm.length > 2 && nm.charAt(1) == ":" ) 
							{
								tmp = nm.charAt(0).toUpperCase();
								
								if( tmp == "L" || tmp == "B" || tmp == "I" /*|| tmp == "C"*/) {
									// #L:General Options#
									subnm = nm.substring(2);
									if( props && props[subnm] != undefined) {
										if( isHtml ) {
											if( tmp == "B" ) {
												val = "<b>" + (useLanguage ? Language.getKeyword( props[subnm] ) : props[subnm]) + "</b>";
											}else if( tmp == "I" ) {
												val = "<i>" + (useLanguage ? Language.getKeyword( props[subnm] ) : props[subnm]) + "</i>";
											}
										}else{
											val = (useLanguage ? Language.getKeyword( props[subnm] ) : props[subnm]);
										}
									}else{
										if( isHtml ) {
											if( tmp == "B" ) {
												val = "<b>" + (useLanguage ? Language.getKeyword( subnm ) : subnm) + "</b>";
											}else if( tmp == "I" ) {
												val = "<i>" + (useLanguage ? Language.getKeyword( subnm ) : subnm) + "</i>";
											}
										}else{
											val = (useLanguage ? Language.getKeyword( subnm ) : subnm);
										}
									}
								}else{
									tmp3 = nm.indexOf(":", 3);
									
									if( tmp3 == -1)
									{
										tmp3 = nm.length;
										
									}
									
									subnm = nm.substring(tmp3+1);
									
									if( tmp == "S" )
									{
										// #S:12:name#
										tmp4 = nm.substring(2, tmp3);
										
										if ( props && props[subnm] != undefined ) {
											if ( isNaN(Number(tmp4)) ) {
												tmp2 =  props[subnm].indexOf(tmp4);
											}else{
												tmp2 = parseInt(tmp4);
											}
											val = props[subnm].substring( 0, tmp2 );
										}else {
											if ( isNaN(Number(tmp4)) ) {
												tmp2 = subnm.indexOf(tmp4);
											}else{
												tmp2 = parseInt(tmp4);
											}	
											val = subnm.substring( 0, tmp2 );
										}
										
									}else if ( tmp == "E" ) {
										
										// #E:17:name#
										tmp4 = nm.substring(2, tmp3);
										
										if ( props && props[subnm] != undefined ) {
											if ( isNaN(Number(tmp4)) ) {
												tmp2 =  props[subnm].lastIndexOf(tmp4);
											}else{
												tmp2 = props[subnm].length - parseInt(tmp4);
											}
											if ( tmp2 < props[subnm].length ) {
												val = props[subnm].substring(tmp2);
											}else{
												val = props[subnm];
											}
										}else {
											if ( isNaN(Number(tmp4)) ) {
												tmp2 = subnm.indexOf(tmp4);
											}else{
												tmp2 = subnm.length - parseInt(tmp4);
											}	
											if ( tmp2 < subnm.length ) {
												val = subnm.substring(tmp2);
											}else{
												val = subnm;
											}
										}
										
									}else{
										if( isHtml ) 
										{
											if( tmp == "A" ) 
											{
												tmp5 = nm.indexOf(")",2);
												tmp6 = nm.indexOf("(",2);
												
												if( tmp5 == -1 || tmp6 == -1 || tmp5 < tmp6 ) {
													val = '<a href="'+nm.substring(2,tmp3)+'">'+ subnm + "</a>";
												}else{
													subnm = nm.substring( tmp5+2 );
													val = '<a href="'+nm.substring(tmp6+1,tmp5)+'">'+ subnm + "</a>";
												}
											}
											else if(tmp == "T") 
											{
												tmp5 = nm.indexOf(")",2);
												tmp6 = nm.indexOf("(",2);
												
												if( tmp5 == -1 || tmp6 == -1 || tmp5 < tmp6 ) {
													subnm = nm.substring( tmp3+1 );
													val = '<div class="'+nm.substring(2,tmp3)+'">'+ subnm + "</div>";
												}else{
													if( nm.length > tmp5 && nm.charAt(tmp5+1) == ":" ) {
														val = '<div class="'+nm.substring(tmp5+2)+'"><img src="'+nm.substring(tmp6+1,tmp5)+'"/></div>';
													}else{
														val = '<div class="container-fluid"><img src="'+nm.substring(tmp6+1,tmp5)+'"/></div>';
													}
												}
											}
											else if(tmp == "C") 
											{
												subnm = nm.substring( tmp3+1 );
												val = '<span class="'+nm.substring(2,tmp3)+'">'+ subnm + "</span>";
											}
											else if(tmp == "P") 
											{
												tmp5 = nm.indexOf(")",2);
												tmp6 = nm.indexOf("(",2);
												
												if( tmp5 == -1 || tmp6 == -1 || tmp5 < tmp6 ) {
													val = '<img src="'+subnm+'"/>';
												}else{
													if( nm.length > tmp5 && nm.charAt(tmp5+1) == ":" ) {
														val = '<img src="'+nm.substring(tmp6+1,tmp5)+'" class="'+nm.substring(tmp5+2)+'"/>';
													}else{
														val = '<img src="'+nm.substring(tmp6+1,tmp5)+'"/>';
													}
												}
											}
										}
									}
								}
							}else{
								
								// parse property 
								if ( props && props[nm] != undefined ) {
									val = props[nm];
								}else {
									nm = nm.toLowerCase();
									
									if ( props && props[nm] != undefined ) {
										val = props[nm];
									}else if( nm == "quote") {
										val =  isHtml ? "&quot;" : '"';
									}else if( nm == "squote") {
										val = isHtml ? "&apos;" : "'";
									}else if( nm == "at") {
										val = "@";
									}else if( nm == "hashtag") {
										val = "#";
									/*}else if( nm == "lt") {
										val = "&lt;";
									}else if( nm == "gt") {
										val = "&gt;";
									}else if( nm == "sbro") {
										val = "[";
									}else if( nm == "sbrc") {
										val = "]";*/
									/*}else if( nm == "separator") {
										val = "#separator";*/
									}else if( nm == "br") {
										val = isHtml ? "<br/>" : " \n";
									}else if( nm == "hr") {
										val = isHtml ? "<hr/>" : " \n";
									}else if( nm == "tab") {
										val = isHtml ? "&nbsp;&nbsp;&nbsp;" : "\t";
									}else if( nm == "copyright") {
										val = "&copy;";
									}else if( nm == "app-name") {
										val = CTOptions.appName;
									}else if( nm == "app-version") {
										val = CTOptions.version;
									}else if( nm == "template-name") {
										val = CTTools.activeTemplate.name;
									}else{
										try {
											
											var p:Sprite = HtmlEditor( Application.instance.view.panel.src ).editor.currentEditor;
											
											if( nm == "insert-template" ) {
												if(p is AreaEditor) {
													val = AreaEditor(p).currentTemplate.name;
												}else if( p is ConstantsEditor ) {
													val = ConstantsEditor(p).currentTemplate.name
												}else{
													val = "";
												}
											}else if( nm == "insert-area" ) {
												if(p is AreaEditor) {
													val = AreaEditor(p).currentArea.name;
												}else{
													val = "";
												}
											}else if( nm == "insert-property" ) {
												if(p is AreaEditor) {
													val = AreaEditor(p).updateItem.name || "";
												}else if(p is ConstantsEditor) {
													var pc:PropertyCtrl = ConstantsEditor(p).currentItem;
													if( pc ) {
														val = pc.name;
													}
												}else{
													val = "";
												}
											}else{
												val = nm;
											}
										}catch(e:Error) {
											if(CTOptions.debugOutput) Console.log("Error: Editor Undefined " +e);
											val = nm;
										}
									}
								}
							}
							
							out += val;
							
							// reset
							se = false;
							continue;
						}else{
							
							ts = i+1;
							se = true;
						}
						// Found property in text
					}
					else if( cc == 42 ) 
					{
						// Inline MD: * ** ***
						
						if( L > i )
						{
							if( s.charCodeAt(i + 1) == 42 ) {
								if( L > i + 2 && s.charCodeAt( i + 2 ) == 42 ) {
									// ***
									if( mda == "ib" ) {
										mdt = out.substring(mdn);
										out = out.substring(0, mdn) + "<b><i>" + mdt + "</i></b>";
										mda = "";
									}else{
										mda = "ib";
									}
									i += 2;
								}else{
									// **
									if( mda == "b" ) {
										mdt = out.substring(mdn);
										out = out.substring(0, mdn) + "<b>" + mdt + "</b>";
										mda = "";
									}else{
										mda = "b";
									}
									i += 1;
								}
							}else{
								// *
								if( mda == "i" ) {
									mdt = out.substring(mdn);
									out = out.substring(0, mdn) + "<i>" + mdt + "</i>";
									mda = "";
								}else{
									mda = "i";
								}
								
							}
							if( mda != "" ) {
								mdn = out.length;
							}
							continue;
						}
					}
					
					if( !se ) out += String.fromCharCode(cc);
				}
				
				if( mdc != "" ) {
					mdt = out.substring( mdo );
					out = out.substring( 0, mdo) + "<"+mdc+">" + mdt + "</"+mdc+">\n";
					mdc = "";
				}
				
				return out;
			}
			return s;
		}
		
		public static function logTemplatePriorities () :void
		{
			if (CTTools.procFiles && CTTools.activeTemplate) {
				
				fieldWidth = _fieldWidth;
				var tdc:String = new Array(deco_chars).join(deco_h);
				
				Application.instance.cmd( "Console show console log " + tdc + "\n" + tdc + "\n" + tdc);
				Console.log( deco_v + " \n" + deco_v + " \nRoot Template Priorities:\n" + deco_v );
				
				var i:int;
				var pf:ProjectFile;
				var sortarr:Array = [];
				var L2:int;
				var nam:String;
				var o:Object = CTTools.activeTemplate.propertiesByName; 
				for( nam in o ) {
					sortarr.push( { name: nam, 
									sorting: o[nam].priority, 
									sections:o[nam].sections, 
									hsort: String(o[nam].sections + o[nam].priority)  } );
				}
				
				sortarr.sortOn("hsort");
				
				var L:int = sortarr.length;
				for (i = 0; i < L; i++) {
					Consolelog( deco_v + " " + sortarr[i].sections + " " + sortarr[i].sorting + " : ", sortarr[i].name);
				}
			}
		}
		
		
		public static function logInfo () :void {
			
			Console.log("\nInfo:\n=====\n");
			
			if( CTTools.activeTemplate ) {
				Console.log("Root Template:")
				Console.log("Name: " + CTTools.activeTemplate.name );
				Console.log("Version: " + CTTools.activeTemplate.version );
				
			}
			if ( CTTools.subTemplates && CTTools.subTemplates.length > 0 ) {
				var L:int = CTTools.subTemplates.length;
				Console.log("Sub Templates: " + L );
				for (var i:int = 0; i < L; i++) {
					Console.log("Name: " + CTTools.subTemplates[i].name );
					Console.log("Version: " + CTTools.subTemplates[i].version );
					Console.log("Type: " + CTTools.subTemplates[i].types.join(",") );
				}
			}
		}
		
		
		public static function logTemplateInfo () :void
		{
			if( CTTools.activeTemplate )
			{
				fieldWidth = _fieldWidth;
				
				var tdc:String = new Array(deco_chars).join(deco_h);
				Application.instance.cmd( "Console show console log " + tdc + "\n" + tdc + "\n" + tdc);
				
				Console.log( deco_v + " \n" + deco_v + " Template Information:\n" + deco_v + "\n" + deco_v + tdc + "\n" + deco_v + " \n" + deco_v + " Root Template: " + CTTools.activeTemplate.name+"\n"+ deco_v + " =================" + (new Array(CTTools.activeTemplate.name.length).join("=")) +"\n" + deco_v );

				logTemplate (CTTools.activeTemplate);
				
				Console.log( deco_v +"\n" + deco_v + " " + CTTools.subTemplates.length + " Subtemplates\n" + deco_v + " " + (new Array(13 + (String("" + CTTools.subTemplates.length).length) ).join("=")) );
				
				currTLog = 0;
				setTimeout( logNextSubT, 55);
			}
		}
		
		private static function logNextSubT () :void {
			
			if (CTTools.subTemplates) {
				
				var i:int = currTLog;
				
				if( i <  CTTools.subTemplates.length ) {
					currTLog++
					Console.log( (new Array(deco_chars).join(deco_h) ));
					Console.log( deco_v + "\n" + deco_v + " " + "Sub Template: " + CTTools.subTemplates[i].name);
					Console.log( deco_v + " " + "================" + (new Array(CTTools.subTemplates[i].name.length).join("=")) +"\n"+ deco_v );
					logTemplate( CTTools.subTemplates[i] );
					Console.log( (new Array(deco_chars).join(deco_h) ));
					var tf:TextField = Console.getTextField();
					if(tf) {
						tf.scrollV = tf.maxScrollV;
					}
					setTimeout( logNextSubT, 5);
				}
			}
		}
		public static function Consolelog( n:String, v:*) :void {
			var len:int = fieldWidth - n.length;
			if( len > 0 ) {
				Console.log( n  + (new Array(len).join(" ") + v));
			}else{
				fieldWidth = n.length +1;
				Console.log( n + " " + v);
			}
			
		}
		
		public static function logTemplateByName ( T:String ) :void
		{
			logTemplate(CTTools.findTemplate( T, "name"));
		}
		
		public static function logTemplate( T:Template ) :void
		{
			if( CTTools.procFiles && T && CTTools.activeTemplate ) {
				
				fieldWidth = _fieldWidth;
				Consolelog( deco_v + "  " + ".type: " ,T.type);
				Consolelog( deco_v + "  " + ".sqlUid: " , T.sqlUid);
				Consolelog( deco_v + "  " + ".files: " , T.files);
				Consolelog( deco_v + "  " + ".folders: " , T.folders);
				Consolelog( deco_v + "  " + ".relativePath: " , T.relativePath);
				Consolelog( deco_v + "  " + ".genericPath: " , T.genericPath);
				Consolelog( deco_v + "  " + ".types: " , T.types);
				Consolelog( deco_v + "  " + ".indexFile: " , T.indexFile);
				Consolelog( deco_v + "  " + ".dbcmds: ", T.dbcmds);
				Consolelog( deco_v + "  " + ".help: " ,T.help);
				Consolelog( deco_v + "  " + ".sortareas: " , T.sortareas);
				Consolelog( deco_v + "  " + ".sortproperties: " , T.sortproperties);
				Consolelog( deco_v + "  " + ".tables: ",T.tables);
				Consolelog( deco_v + "  " + ".fields: ", T.fields);
				Consolelog( deco_v + "  " + ".jsfiles: " , T.jsfiles);
				Consolelog( deco_v + "  " + ".cssfiles: " , T.cssfiles);
				
				if(T.dbProps) {
					Consolelog( deco_v + "  " + ".dbProps: " ,T.dbProps);
					for (var nm:String in T.dbProps) {
						Consolelog( deco_v + "  " + "DBProp '" + nm + "': ", T.dbProps[nm].value );
					}
				}
				var pf:ProjectFile;
				var k:int;
				for( var i:int=0; i<CTTools.procFiles.length; i++) {
					pf = ProjectFile( CTTools.procFiles[i] );
					if( pf.templateId == T.name ) {
						Console.log( deco_v + " ");
						Console.log( deco_v + " " + "Template File '"+ pf.filename + "':");
						Console.log( deco_v + " " + ".................." + (new Array(pf.filename.length).join(deco_h)));
						
						Consolelog( deco_v + " " + ".path: " , pf.path);
						Consolelog( deco_v + " " + ".name: " , pf.name);
						Consolelog( deco_v + " " + ".extension: ", pf.extension);
						Consolelog( deco_v + " " + ".type: " , pf.type);
						Consolelog( deco_v + " " + "Structs: " , pf.templateStruct.length );
						Consolelog( deco_v + " " + "Areas: " , pf.templateAreas.length );
						
						for(k=0; k<pf.templateAreas.length; k++) {
							Console.log( deco_v + " ");
							Console.log( deco_v + " " + "Area '" + pf.templateAreas[k].name+"'" );
							Console.log( deco_v + " " + "........" + (new Array(pf.templateAreas[k].name.length).join(deco_h)));
							Consolelog( deco_v + " " + ".type:", pf.templateAreas[k].type );
							Consolelog( deco_v + " " + ".types:", pf.templateAreas[k].types );
							Consolelog( deco_v + " " + ".priority:", pf.templateAreas[k].priority );
							Consolelog( deco_v + " " + ".sections:", pf.templateAreas[k].sections );
						}
						
						Console.log( deco_v + " " + "Properties: " + pf.templateProperties.length );
						for(k=0; k<pf.templateProperties.length; k++) {
							Console.log( deco_v + " ");
							Console.log( deco_v + " " + "Property '" + pf.templateProperties[k].name+"'" );
							Console.log( deco_v + " " + "............" + (new Array(pf.templateProperties[k].name.length).join(deco_h)));
							Consolelog( deco_v + " " + ".type:" , pf.templateProperties[k].defType );
							Consolelog( deco_v + " " + ".defValue:", pf.templateProperties[k].defValue );
							Consolelog( deco_v + " " + ".priority:", pf.templateProperties[k].priority );
							Consolelog( deco_v + " " + ".sections:", pf.templateProperties[k].sections );
							Consolelog( deco_v + " " + ".argv:", pf.templateProperties[k].argv );
							Consolelog( deco_v + " " + ".args:" , pf.templateProperties[k].args );
						}
					}
				}
			}
		}
		
		
	}

}
