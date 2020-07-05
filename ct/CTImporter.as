package ct
{
	import agf.utils.StringMath;
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
            if ( CTOptions.updateUrl )
			{
                if(CTOptions.debugOutput) Console.log( "Load Update Info From " + CTOptions.updateUrl );
                ResourceMgr.getInstance().loadResource( CTOptions.updateUrl, onUpdateCFG, true, false, true );
            }
			else
			{
				Console.log( "Application-Update URL Is Not Set. Please Navigate To WWW.CONTEMPLE.APP To Download The Latest Version");
			}
        }
		
		// App Update
		private static function onUpdateCFG (res:Resource) :void
		{
			if( res && res.loaded == 1 ) {
				var x:XML = new XML( String(res.obj) );
				if( x.update.@version != undefined )
				{
					var updateType:String = CTTools.compareVersions( CTOptions.version,  x.update.@version.toString() );
					
					if( updateType != "none" )
					{
						// Display update info and download link...
						Application.instance.cmd("Console log Update Available: "+ x.update.@name + " " +x.update.@date + ": " + updateType + " " + x.update.@version + " Download At "  + x.update.@src ); 
						
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
			// load update xml from hub
			if ( CTOptions.uploadScript )
			{
				var pwd:String = "";
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if ( sh )
				{
					if( sh.data && sh.data.userPwd ) {
						pwd = sh.data.userPwd;
					}else{
						Application.instance.cmd( "CTTools get-password", lookForTemplateUpdate);
						return;
					}
				}
				
				// get zip file from cthub by template-name
				var res:Resource = new Resource();
				var vars:URLVariables = new URLVariables();
				vars.update = 1;
				vars.name = CTTools.activeTemplate.name;
				vars.pwd = pwd;
				
				// dowload zip file..
				res.load( CTOptions.uploadScript, true, onTemplateUpdateCFG, vars, true );
			}
        }
		
		private static function onTemplateUpdateCFG (e:Event, res:Resource) :void
		{
			if( res && res.loaded == 1 )
			{
				var x:XML;
				var s:String = String( res.obj );
				
				var st:int = s.indexOf( "<?xml" );
				
				if ( st >= 0 )
				{
					s = s.substring( st ) ;
					
					try {
						x = new XML( s );
					}catch (e:Event) {
						Console.log("Error Update XML: " + e );
					}
				}
				
				if( x ) {
					var win:Window;
					
					if( x.update.@version != undefined )
					{
						Console.log("Compare Versions: Current: " + CTTools.activeTemplate.version +" - Online: " + x.update.@version.toString() );
						
						var updateType:String = CTTools.compareVersions( CTTools.activeTemplate.version, x.update.@version.toString() );
						
						if( updateType != "none" ) {
							// Display update info and download link...
							if( CTOptions.debugOutput || CTOptions.verboseMode ) Console.log("Template Update Available:"+ x.update.@name + " " + x.update.@date + ": " + updateType + ": " + x.update.@type + " " + x.update.@version ); 
						
							var msg:String = Language.getKeyword("CT-Template-Update-MSG");
							var obj:Object = { name:x.update.@name.toString(), date: x.update.@date.toString(), type:x.update.@type.toString(), version:x.update.@version.toString() };
							msg = ct.TemplateTools.obj2Text( msg, '#', obj);
							
							win = Window( Main(Application.instance).window.GetBooleanWindow( "TemplateUpdateWindow", Language.getKeyword("Template Update"), msg, {
							complete: function (bool:Boolean) { 
								if (bool) {
									TemplateTools.updateTemplate(  x.update.@src.toString() );
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
							if( CTOptions.debugOutput || CTOptions.verboseMode ) Console.log("Template Up To Date");
							win = Window( Main(Application.instance).window.InfoWindow( "TemplateUpdateWindow2", Language.getKeyword("Template Update"), Language.getKeyword("Template up to date"), {
							continueLabel: Language.getKeyword("Ok"),
							autoWidth:false,
							autoHeight:true
							}, 'template-update-window-2') );
							
						}
					}
				}
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
		
		public static function get isExtracting () :Boolean { return extracting; }
		
		// FZip Vars
		private static var zip:FZip;
		private static var numFiles:int = 0;
		private static var numFilesLoaded:int = 0;
		private static var done:Boolean = false;
		private static var parentDir:File;
		private static var cwd:File;
	//	private static var step:int=0;
		private static var rootCwd:File;
		private static var frameTime:int = 0;
		private static var _complete:Function;
		private static var _showInstallView:Boolean;
		
		private static function fzipExtract ( url:URLRequest, parentDirectory:File, complete:Function=null, showInstallView:Boolean=true ) :String
		{
			if( extracting ) return "";
			
			_showInstallView = showInstallView;
			
			parentDir = parentDirectory;
			done = false;
			numFiles = numFilesLoaded /*= step*/ = progress = 0;
			
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
				
				if( _showInstallView )
				{
					var iv:InstallView;
					try {
						iv = InstallView( Application.instance.view.panel.src );
					}
					catch(e:Error)
					{
						Application.command( "view InstallView");
						iv = InstallView( Application.instance.view.panel.src );
					}
					if( iv ) {
						iv.showProgress( 0 );
						iv.setLabel( Language.getKeyword("Extracting files") );
					}
				}
				
				
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
			//step++;
			
			progress = ( numFiles / zip.getFileCount() ) * 100;
			
			/*if( CTOptions.verboseMode || CTOptions.debugOutput )
			{
				Console.log("Extract: " + Math.floor(progress) +"%");
			}*/
			
			if( _showInstallView && progress > 0)
			{
				var iv:InstallView;
				try{
					iv = InstallView( Application.instance.view.panel.src );
					iv.showProgress( progress / 100 );
					iv.setLabel( Language.getKeyword("Extracting files") );
				}catch(e:Error){
					_showInstallView = false;
				}
			}
			//for(var i:int = 0; i < 1; i++)
			//{

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
								//continue;
								if( extracting ) {
									setTimeout( onFrame, frameTime );
								}
								return;
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
							//continue;
							if( extracting ) {
								setTimeout( onFrame, frameTime );
							}
							return;
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
						if( CTOptions.verboseMode || CTOptions.debugOutput ) Console.log( numFilesLoaded +" Files Extracted To " + rootCwd.url );
						extracting = false;
						if( typeof(_complete) == "function" ) _complete();
					}
					// break;
				}
			//}
			
			if( extracting ) {
				setTimeout( onFrame, frameTime );
			}
		}

	}
}
