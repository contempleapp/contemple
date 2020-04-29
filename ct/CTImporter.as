package ct
{
	import deng.fzip.FZip;
    import deng.fzip.FZipFile;
    import deng.fzip.FZipErrorEvent;
	import flash.net.*;
	import flash.utils.setTimeout;
	import flash.filesystem.*;
	import flash.utils.ByteArray;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import agf.tools.*;
	import agf.utils.FileUtils;
	import agf.ui.*;
	import agf.io.*;
	import agf.Main;
	
	public class CTImporter
	{
		public function CTImporter() {}
		
		public static function lookForAppUpdate () :void
        {
            if( CTOptions.updateUrl ) {
                if(CTOptions.debugOutput) Console.log( "Load Update Info from " + CTOptions.updateUrl );
                ResourceMgr.getInstance().loadResource( CTOptions.updateUrl, onUpdateCFG, true );
            }
        }
		// App Update
		private static function onUpdateCFG (res:Resource) :void {
			if( res && res.loaded == 1 ) {
				var x:XML = new XML( String(res.obj) );
				if( x.update.@version != undefined )
				{
					var updateType:String = CTTools.compareVersions( CTOptions.version,  x.update.@version.toString() );
					
					if( updateType != "none" ) {
						// Display update info and download link...
						Application.instance.cmd("Console log Update Available: "+ x.update.@name + " " +x.update.@date + ": " + updateType + " " + x.update.@version + " download at "  + x.update.@src ); 
						
						var msg:String =  Language.getKeyword("CT-Update-MSG");
						var obj:Object = { name:x.update.@name.toString(), date: x.update.@date.toString(), type:updateType, version:x.update.@version.toString(), src:x.update.@src.toString() };
						msg = ct.TemplateTools.obj2Text( msg, '#', obj);
						
						var win:Window = Window( Main(Application.instance).window.GetBooleanWindow( "UpdateWindow", Language.getKeyword("Update"), msg, {
						complete: function (bool:Boolean) { 
							if (bool) {
								navigateToURL( new URLRequest(x.update.@src.toString()) );
								Application.instance.cmd("Application quit");
							}
						},
						continueLabel: Language.getKeyword("Download Update"),
						allowCancel: true,
						autoWidth:false,
						autoHeight:true,
						cancelLabel: Language.getKeyword("Cancel")
						}, 'update-window') );
						
						Main(Application.instance).windows.addChild( win );
					}
				
				}
			}
		}
		
		
		   
        public static function lookForTemplateUpdate () :void
        {
            if( CTTools.activeTemplate && CTTools.activeTemplate.update )
			{
				if(CTOptions.debugOutput) Console.log("Downloading template update information from " + CTTools.activeTemplate.update);
				ResourceMgr.getInstance().loadResource(CTTools.activeTemplate.update, onTemplateUpdateCFG, true );
            }
        }
		
		private static function onTemplateUpdateCFG (res:Resource) :void {
			if( res && res.loaded == 1 )
			{
				var x:XML = new XML( String(res.obj) );
				var win:Window;
				
				if( x.update.@version != undefined )
				{
					var updateType:String = CTTools.compareVersions( CTTools.activeTemplate.version, x.update.@version.toString() );
					
					if( updateType != "none" ) {
						// Display update info and download link...
						if( CTOptions.debugOutput || CTOptions.verboseMode ) Console.log("Template Update Available:"+ x.update.@name + " " + x.update.@date + ": " + updateType + ": " + x.update.@type + " " + x.update.@version + " download: "  + x.update.@src ); 
					
						var msg:String = Language.getKeyword("CT-Template-Update-MSG");
						var obj:Object = { name:x.update.@name.toString(), date: x.update.@date.toString(), type:x.update.@type.toString(), version:x.update.@version.toString(), src:x.update.@src.toString() };
						msg = ct.TemplateTools.obj2Text( msg, '#', obj);
						
						win = Window( Main(Application.instance).window.GetBooleanWindow( "TemplateUpdateWindow", Language.getKeyword("Template Update"), msg, {
						complete: function (bool:Boolean) { 
							if (bool) {
								CTImporter.downloadUpdate( x.update.@src.toString() );
							}
						},
						continueLabel: Language.getKeyword("Install Update"),
						allowCancel: true,
						autoWidth:false,
						autoHeight:true,
						cancelLabel: Language.getKeyword("Cancel")
						}, 'template-update-window') );
						
						Main(Application.instance).windows.addChild( win );
					}else{
						if( CTOptions.debugOutput || CTOptions.verboseMode ) Console.log("Template up to date");
						win = Window( Main(Application.instance).window.InfoWindow( "TemplateUpdateWindow2", Language.getKeyword("Template Update"), Language.getKeyword("Template up to date"), {
						continueLabel: Language.getKeyword("Ok"),
						autoWidth:false,
						autoHeight:true
						}, 'template-update-window-2') );
						
					}
				}
			}
		}
	
		public static function downloadUpdate (src:String) :void {
			try {
				Application.instance.cmd( "Application view InstallView" );
			}catch( e:Error ) {
				Console.log("Error: No InstallView View found in menu");
			}
			var iv:InstallView = InstallView( Application.instance.view.panel.src );
			if( iv ) {
				iv.showProgress( 0.25 );
				iv.setLabel( Language.getKeyword( "Downloading Template Update" ) );
			}
			ResourceMgr.getInstance().loadResource( src, onZipFile, true, true );
		}
		
		private static function onZipFile (res:Resource) :void {
			if( res && res.loaded == 1 ) {
				var f:File = File.applicationStorageDirectory.resolvePath ( CTOptions.tmpDir + CTOptions.urlSeparator + FileUtils.fileInfo( res.url ).filename);
				var fs:FileStream = new FileStream();
				fs.open( f, FileMode.WRITE );
				fs.writeBytes( ByteArray(res.obj) );
				fs.close();
				
				var iv:InstallView = InstallView( Application.instance.view.panel.src );
				if( iv ) {
					iv.showProgress( 0.5 );
				}
				
				TemplateTools.updateTemplate( f.url );
			}
		}
		
		
		
		/// ////////////////////////////////////// ///
		public static var ziplib:String = "fzip"; // fzip, zip-ane
		
		/**
		* Extract a zip file in Air Applications
		* @param url the zip file to extract
		* @param parentDirectory folder for extracted files
		* @param complete function on extract completes
		* @return the new folder name wich is the zip-filename without file extension
		*/
		public static function extractZipFile ( url:URLRequest, parentDirectory:File, complete:Function=null ) :String {
			// only fzip supported currently..
			return fzipExtract ( url, parentDirectory, complete );
		}
		
		private static var extracting:Boolean = false;
		
		// FZip Vars
		private static var zip:FZip;
		private static var numFiles:int = 0;
		private static var numFilesLoaded:int = 0;
		private static var done:Boolean = false;
		private static var parentDir:File;
		private static var cwd:File;
		private static var step:int=0;
		private static var rootCwd:File;
		private static var frameTime:int = 100;
		private static var _complete:Function;
		
		private static function fzipExtract ( url:URLRequest, parentDirectory:File, complete:Function=null ) :String
		{
			if( extracting ) return "";
			
			parentDir = parentDirectory;
			done = false;
			numFiles = numFilesLoaded = step = progress = 0;
			
			var filename:String = "";
			_complete = complete;
			
			if( parentDir && parentDir.isDirectory )
			{
				var cid:int = url.url.lastIndexOf("/");
				
				if( cid >= 0) filename = url.url.substring( cid+1 );
				else filename = url.url;
				
				cid = filename.lastIndexOf(".");
				if( cid >= 1 ) filename = filename.substring(0,cid);
				
				cwd = parentDir.resolvePath( filename );
				cwd.createDirectory();
				
				rootCwd = cwd;
				
				extracting = true;
				prginc = false;
				
				zip = new FZip();
				zip.addEventListener(Event.OPEN, onOpen);
				zip.addEventListener(FZipErrorEvent.PARSE_ERROR, onParseError);
				zip.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				zip.addEventListener(Event.COMPLETE, onComplete);
				
				
				zip.load( url );
			}else{
				throw new Error("No Parent Directory to extract " + url.url);
			}
			return filename;
		}
		private static var prginc:Boolean = false;
		
		private static function onIoError (evt:IOErrorEvent):void {
			done = true;
			Console.log("FZip File Error " + evt);
		}
		
		private static function onParseError (evt:FZipErrorEvent):void {
			done = true;
			Console.log( "FZip Parse Error " + evt.text );
		}
		
		private static function onOpen(evt:Event):void {
			setTimeout( onFrame, frameTime );
		}
		private static function onComplete (evt:Event):void {
			done = true;
		}
		private static var progress:Number=0;
		
		public static function getProgress () :Number {
			return progress;
		}
		private static function onFrame () :void
		{
			var cid:int, eid:int;
			var filename:String;
			step++;
			
			progress = ( numFiles / zip.getFileCount() ) * 100;
			
			if( CTOptions.verboseMode ||  CTOptions.debugOutput )
			{
				Console.log("Extract: " + Math.floor(progress) +"%");
				
				if( progress > 30 && !prginc) {
					prginc = true;
					try {
						var iv:InstallView;
						iv = InstallView( Application.instance.view.panel.src );
						iv.showProgress( 0.1 + progress/50 );
						iv.setLabel( Language.getKeyword("Extracting template files") );
					}catch(e:Error) {
						
					}
				}
			}
			
			//Only load few files per frame, to save processing power
			for(var i:int = 0; i < 16; i++)
			{
				if(zip.getFileCount() > numFiles)
				{
					var file:FZipFile = zip.getFileAt(numFiles);
					
					try
					{
						cid = file.filename.indexOf("/");
						
						if( cid >= 0 ) {
							eid = file.filename.lastIndexOf("/");
							if( eid == file.filename.length - 1 ) { // create directory
								cwd = rootCwd.resolvePath( file.filename.substring(0,eid) );
								cwd.createDirectory();
								numFiles++;
								continue;
							}else{ // set cwd
								cwd = rootCwd.resolvePath( file.filename.substring(0, eid) );
								filename = file.filename.substring(eid+1);
							}
						}else{
							cwd = rootCwd;
							filename = file.filename;
						}
						if( filename.charAt(0) == "." ) { // ignore hidden files..
							numFiles++;
							continue;
						}
						if( CTTools.writeBinaryFile(cwd.resolvePath(filename).url, file.content) ) numFilesLoaded++;
						numFiles++;
					}
					catch(e:Error)
					{
						if( CTOptions.verboseMode ||  CTOptions.debugOutput ) Console.logInline(" *** FZIP Extract Error *** " + e + "*** ");
						numFiles++;
					}
					
				}else{
					if(done) {
						if( CTOptions.verboseMode || CTOptions.debugOutput ) Console.log( numFilesLoaded +" files extracted to " + rootCwd.url );
						extracting = false;
						if( typeof(_complete) == "function" ) _complete();
					}
					break;
				}
			}
			
			if( extracting ) {
				setTimeout( onFrame, frameTime );
			}
		}

	}
}
