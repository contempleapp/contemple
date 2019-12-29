package ct {
	
	import flash.filesystem.*;
	import flash.display.*;
	import agf.tools.*;
	import agf.Main;
	import agf.io.Resource;
	import flash.events.Event;
	import flash.net.URLVariables;
	import com.adobe.crypto.*;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	import flash.net.SharedObject;
	import flash.display.Sprite;
    import flash.events.*;
    import flash.net.FileReference;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
	
	public class CTUploader extends BaseTool 
	{
		public function CTUploader() {}
		
		private static var dirInfo:String="";
		private static var dirInfoXml:XML;
		public static var uploading:Boolean = false;
		private static var uploadError:Boolean = false;
		private static var uploadCompleteHandler:Function=null;
		private static var upFiles:Array;
		private static var filesChecked:int=0;
		private static var fileHashes:Object;
		private static var currWebDir:String;
		private static var patchFiles:Array;
		private static var patchFolder:Array;
		private static var currFolder:int;
		private static var currFile:int;
		internal static var maxFileSize:int ; //= 24 * 1000 * 1000; // 24 MB
		
		internal static var viewPanel:UploadView;
		internal static var ltProgress:Number = 0;
		private static var waitInterval:int = 70;
		
		private static var prgStep:Number;
		
		private static var fileStore:Array;
		private static var currFileStore:int;
		internal static var fileErrors:Array;
		
		private static function showProgress (v:Number) :void {
			ltProgress = v;
			if( viewPanel ) viewPanel.showProgress(v);
		}
		public static function uploadSite ( completeHandler:Function ) :void
		{
			if( uploading ) return;
			
			forceExit = false;
			
			if( CTTools.activeTemplate ) {
				uploading = true;
				uploadCompleteHandler = completeHandler;
				
				if( CTOptions.verboseMode ) {
					viewPanel = null;
					Application.instance.cmd("Console clear show console");
				}else{
					// Display Starting of Upload...
					viewPanel = UploadView( Application.instance.view.panel.src );
					showProgress(0);
				}
				
				Console.log( "Downloading Directory Info with algo '" + CTOptions.hashCompareAlgorithm  +"' from " + CTOptions.uploadScript );
				
				var pwd:String = "";
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( sh ) {
					if( sh.data && sh.data.userPwd ) {
						pwd = sh.data.userPwd;
					}else{
						Application.instance.cmd( "CTTools get-password", resumeOnPwd);
						uploading = false;
						return;
					}
				}
				showProgress(0.001);
				
				var res:Resource = new Resource();
				var vars:URLVariables = new URLVariables();
				vars.dirinfo = 1;
				vars.algo = CTOptions.hashCompareAlgorithm;
				vars.pwd = pwd;
				
				if( CTOptions.uploadSendFileList )
				{
					// Gen file list of all website files with sha codes and send to server..
					// Server sends a list of file hashes to compare
					currWebDir = "";
					fileStore = [];
					filesChecked = 0;
					genFileList();
					vars.filelist = webFiles.join(",");
				}
				
				res.load( CTOptions.uploadScript, true, onDirInfo, vars);
				
				showProgress(0.005);
			}
		}
		private static function resumeOnPwd () :void {
			uploadSite( uploadCompleteHandler );
		}
		public static function onDirInfo ( e:Event, r:Resource ) :void {
			
			if( forceExit ) return preExit();
			
			try {
				dirInfo = String(r.obj) || "";
			}catch(e:Error) {
				dirInfo = "";
			}
			if( dirInfo == null || dirInfo == "null") {
				dirInfo = "";
			}
			if( CTOptions.verboseMode || CTOptions.debugOutput ) {
				Console.log( "Response: " + dirInfo);
			}
			showProgress(0.04);
			
			if( dirInfo == "no-pass" ) {
				Application.instance.cmd("CTTools reset-password");
				uploading = false;
				uploadSite(uploadCompleteHandler);
				return;
			}
			
			if( dirInfo == "" ) {
				Console.log( "Error connecting to web server: " + CTOptions.uploadScript);
				if( viewPanel ) {
					// Show error...
					viewPanel.log("Error connecting to web server."); 
				}
				forceExit = true;
				uploadFinish();
			}else{
				dirInfoXml = new XML(dirInfo);
				fileHashes = {};
				
				if( CTOptions.debugOutput ) {
					Console.log("DIR-INFO\n" + dirInfo );
				}
				
				maxFileSize = parseInt( dirInfoXml.@maxsize );
				
				var xm:XMLList = dirInfoXml.f;
				var L:int = xm.length();
				
				Console.log("Comparing " + L + " Web Files With '" + CTTools.projectDir.substring(8) + "'");
				if( viewPanel ) {
					viewPanel.log( "Searching ("+L+" files)" );
				}
				for( var i:int=0; i<L; i++){
					fileHashes[ xm[i].@url.toString() ] = xm[i].@c.toString();
				}
				setTimeout( startUpload, waitInterval );
			}
		}
		public static var webFiles:Array;
		
		public static function genFileList () :void
		{
			webFiles = [];
			
			var activeTemplate = CTTools.activeTemplate;
			
			if( activeTemplate.indexFile ) {
				webFiles.push( activeTemplate.indexFile );
			}
			
			var i:int;
			
			if( activeTemplate.files ) {
				patchFiles = activeTemplate.files.split(",");
				for( i=0; i<patchFiles.length; i++) {
					webFiles.push( patchFiles[i] );
				}
			}
			
			if( CTTools.pages && CTTools.pages.length > 0 ){
				for(i=0; i < CTTools.pages.length; i++) {
					webFiles.push( CTTools.pages[i].filename );
				}
			}
			
			if( activeTemplate.folders ) {
				patchFolder = activeTemplate.folders.split(",");
				var filedir:String;
				
				for(i=0; i<patchFolder.length; i++)
				{
					filedir = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.localUploadFolder;
					
					fileListFolder( filedir, patchFolder[i], "");
					currWebDir = "";
				}
				for(i=0; i< fileStore.length; i++) {
					webFiles.push( fileStore[i].webdir + fileStore[i].name );
				}
			}
		}
		
		
		public static function fileListFolder (filedir:String, foldername:String, webdir:String) :void
		{
			if( forceExit ) return preExit();
			
			var folder:File = new File( filedir + CTOptions.urlSeparator + foldername );
			
			if( folder.isDirectory ) {
				
				currWebDir += foldername + "/";
				
				Console.log( "ListFolder: " + currWebDir );
				
				// Loop through files in local folder ..
				var filename:String;
				var fid:int;
				var list:Array = folder.getDirectoryListing();
				var i:int;
				var k:int;
				
				for (i = 0; i < list.length; i++) {
					filename = list[i].url;
					
					fid = filename.lastIndexOf( CTOptions.urlSeparator );
					if( fid >= 0 ) filename = filename.substring( fid+1 );
					if( filename.charAt(0) != "." ) {
						if( ! list[i].isDirectory ) {
							fileStore.push( { dir:folder.url, name:filename, webdir:currWebDir } );
						}
					}
				}
				
				for (i = 0; i < list.length; i++) {
					filename = list[i].url;
					
					fid = filename.lastIndexOf( CTOptions.urlSeparator );
					if( fid >= 0 ) filename = filename.substring( fid+1 );
					if( filename.charAt(0) != "." )
					{
						if( list[i].isDirectory ) {
							fileListFolder( folder.url, filename, "");
							currWebDir = currWebDir.substring( 0, currWebDir.length-2 );
							k = currWebDir.lastIndexOf("/");
							
							if( k >= 0 ) {
								currWebDir = currWebDir.substring( 0, k+1 );
							}
						}
					}
				}
			}
		}
		
		
		public static function startUpload () :void		
		{
			if( forceExit ) return preExit();
			
			showProgress(0.05);
			
			fileErrors = [];
			fileStore = [];
			upFiles = [];
			filesChecked = 0;
			currWebDir = "";
			uploadError = false;
			
			var activeTemplate = CTTools.activeTemplate;
			
			if( activeTemplate.indexFile ) {
				uploadFile(  CTTools.projectDir + CTOptions.urlSeparator + CTOptions.localUploadFolder, activeTemplate.indexFile, currWebDir );
			}
			if( activeTemplate.files ) {
				patchFiles = activeTemplate.files.split(",");
				if(patchFiles.length > 0 ) {
					prgStep = 0.05 / patchFiles.length;
					currFile = 0;
					setTimeout( checkTemplateFile, waitInterval );
				}else{
					showProgress(0.15);
					setTimeout( checkTemplateFolders, waitInterval );
				}
			}
			
		}
		
		public static function templateFilesDone () :void {
			if( forceExit ) return preExit();
			
			showProgress(0.15);
			checkTemplateFolders();
		}
		public static function pagesDone () :void {
			if( forceExit ) return preExit();
			
			if( fileStore.length > 0 ) {
				currFileStore = 0;
				showProgress( 0.225 );
				prgStep = 0.6 / fileStore.length;
				setTimeout(nextFileStore, waitInterval);
			}else{
				setTimeout(fileStoreDone, waitInterval);
			}
		}
		public static function checkPage () :void {
			if( forceExit ) return preExit();
			
			uploadFile(  CTTools.projectDir + CTOptions.urlSeparator + CTOptions.localUploadFolder, CTTools.pages[currPage].filename, currWebDir );
			
			currPage++;
			showProgress( ltProgress + prgStep );
			
			if( currPage >= CTTools.pages.length ) {
				setTimeout( pagesDone, waitInterval);
			}else{
				setTimeout( checkPage, waitInterval);
			}
		}
		
		public static function checkTemplateFile () :void {
			if( forceExit ) return preExit();
			
			uploadFile(  CTTools.projectDir + CTOptions.urlSeparator + CTOptions.localUploadFolder, patchFiles[currFile], currWebDir );
			currFile++;
			showProgress( ltProgress + prgStep );
			
			if( currFile >= patchFiles.length ) {
				setTimeout( templateFilesDone, waitInterval);
			}else{
				setTimeout(checkTemplateFile, waitInterval);
			}
		}
		
		public static function checkTemplateFolders () :void {
			if( forceExit ) return preExit();
			
			var activeTemplate = CTTools.activeTemplate;
			if( activeTemplate.folders ) {
				patchFolder = activeTemplate.folders.split(",");
				if(patchFolder.length > 0 ) {
					prgStep = 0.05 / patchFolder.length;
					currFolder = 0;
					setTimeout( checkFolders, waitInterval );
				}else{
					foldersDone();
				}
			}
		}
		
		
		private static function fileStoreDone () :void {
			if( forceExit ) return preExit();
			
			if( upFiles.length == 0 ) {
				Console.log("Website up to date. "+ filesChecked + " files checked.");
				if(viewPanel) viewPanel.log( "Website Up To Date. "+filesChecked+" Files Checked, 0 Uploads \n");
				uploadFinish();
			}else{
				
				syncFiles();
				var dir:String = dirInfoXml.@path.toString();
				var webroot:String = CTOptions.uploadScript + dir;
				
				Console.log("Upload To: " + webroot );
				Console.log("Updating " + upFiles.length + " of " + filesChecked + " files ");
				
				if(viewPanel) {
					viewPanel.log( "Upload To: " + webroot );
					viewPanel.log( "Updating " + upFiles.length + " of " + filesChecked + " files ");
				}
				
				currFile = 0;
				showProgress( 0.8 );
				prgStep = 0.2 / upFiles.length;
				uploadNext();
			}
		}
		private static var currPage:int=0;
		
		private static function foldersDone () :void {
			if( forceExit ) return preExit();
			
			if( CTTools.pages && CTTools.pages.length > 0 ) {
				currPage = 0;
				currWebDir = "";
				showProgress( 0.02 );
				prgStep = 0.025 / CTTools.pages.length;
				setTimeout(checkPage, waitInterval);
			}else{
				setTimeout(pagesDone, waitInterval);
			}
		}
		
		private static function checkFolders () :void {
			if( forceExit ) return preExit();
			
			uploadFolder( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.localUploadFolder, patchFolder[currFolder], "" );
			currWebDir = "";
			currFolder ++;
			showProgress( ltProgress + prgStep );
			
			if( currFolder >= patchFolder.length ) foldersDone();
			else setTimeout( checkFolders, waitInterval );
		}
		private static function findCode ( filedir:String, filename:String ) :String {
			return fileHashes[ filedir + filename ] || "";
		}
		
		public static function uploadFolder (filedir:String, foldername:String, webdir:String) :void
		{
			if( forceExit ) return preExit();
			
			var folder:File = new File( filedir + CTOptions.urlSeparator + foldername );
			
			if( folder.isDirectory ) {
				
				currWebDir += foldername + "/";
				if( CTOptions.verboseMode || CTOptions.debugOutput ) Console.log( "Searching: " + currWebDir );
				
				// Loop through files in local folder ..
				var filename:String;
				var fid:int;
				var list:Array = folder.getDirectoryListing();
				var i:int;
				var k:int;
				
				for (i = 0; i < list.length; i++) {
					filename = list[i].url;
					
					fid = filename.lastIndexOf( CTOptions.urlSeparator );
					if( fid >= 0 ) filename = filename.substring( fid+1 );
					if( filename.charAt(0) != "." ) {
						if( ! list[i].isDirectory ) {
							fileStore.push( { dir:folder.url, name:filename, webdir:currWebDir } );
						}
					}
				}
				
				for (i = 0; i < list.length; i++) {
					filename = list[i].url;
					
					fid = filename.lastIndexOf( CTOptions.urlSeparator );
					if( fid >= 0 ) filename = filename.substring( fid+1 );
					if( filename.charAt(0) != "." )
					{
						if( list[i].isDirectory ) {
							uploadFolder( folder.url, filename, "");
							currWebDir = currWebDir.substring( 0, currWebDir.length-2 );
							k = currWebDir.lastIndexOf("/");
							
							if( k >= 0 ) {
								currWebDir = currWebDir.substring( 0, k+1 );
							}
						}
					}
				}
			}
		}
		
		private static function nextFileStore ( ) :void
		{
			if( forceExit ) return preExit();
			
			if( currFileStore >= fileStore.length ) {
				fileStoreDone();
			}else{
				showProgress( ltProgress + prgStep );
				var o:Object = fileStore[currFileStore];
				
				uploadFile( o.dir, o.name, o.webdir );
				currFileStore++;
				setTimeout(nextFileStore, waitInterval);
			}
		}
		
		public static function pushFile( dir, name, webdir ) :void {
			upFiles.push( {dir:dir, name:name, webdir:webdir} );
		}
		
		public static function uploadFile ( filedir:String, filename:String, webdir:String ) :void
		{
			if( forceExit ) return preExit();
			
			filesChecked++;
			
			var url:String = filedir + CTOptions.urlSeparator + filename;
			var file:File = new File(url);
			
			if( file.exists && !file.isDirectory)
			{
				if( viewPanel && CTOptions.uploadViewShowFileInfo ) viewPanel.log( "Searching " + webdir + filename );
				
				var fileStream:FileStream = new FileStream();
				fileStream.open(file, FileMode.READ);
				var b:ByteArray = new ByteArray();
				fileStream.readBytes(b);
				fileStream.close();
				
				// test if file is too large
				
				var mb:Number = (b.length/1000/1000);
				
				if ( mb > maxFileSize ) {
					Console.log("File too big (" + mb + " MB/"+maxFileSize+" MB): " + filedir + filename );
					fileErrors.push( {dir:filedir, name:filename, webdir:webdir} );
					return;
				}
				
				var c:String = findCode( webdir, filename );
				
				var newFileHash:String = CTTools.hashBytes( b );
				
				if( CTOptions.verboseMode || CTOptions.debugOutput ) {
					Console.log( filename + " Local "+ CTOptions.hashCompareAlgorithm +": " + newFileHash + " equal: " + (c == newFileHash) );
				}
				if( c != newFileHash ) {
					pushFile( filedir, filename, webdir );
				}
			}
		}
		
		private static function syncFiles () :void
		{
			// Upload db
			if( CTOptions.autoSync && CTOptions.syncDatabase ) 
			{
				// Upload DB:
				var dbfilename:String="";
				var dbindex:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.dbIndexFileName );
				if( dbindex.exists ) {
					var dbistr:String = CTTools.readTextFile( dbindex.url );
					var xo:XML = new XML( dbistr );
					dbfilename = xo.db.@filename;
				}
				
				var logStr:String = "Uploading Database: " + dbfilename + " in " + CTTools.projectDir; 
				if( viewPanel ) viewPanel.log( logStr );
				Console.log( logStr );
				
				uploadFile( CTTools.projectDir, dbfilename, "cthub/sync/" );
				
				if( CTOptions.syncTemplate )
				{
					Console.log("Uploading Template: " + CTTools.projectDir + "/" + CTOptions.projectFolderTemplate + " to: "  +  "cthub/sync/tmpl/");
					uploadFile( CTTools.projectDir, CTOptions.projectFolderTemplate, "cthub/sync/tmpl/" );
				}
			}
		}
		
		private static var uploadURL:URLRequest;
		
		private static function uploadNext () :void
		{
			if( forceExit ) {
				UploadView.showAbortError();
				currFile--;
				preExit();
				return;
			}
			
			var o:Object = upFiles[currFile]; // name, dir, webdir
			
			if( CTOptions.uploadMethod == CTOptions.UPLOAD_METHOD_PHP || CTOptions.uploadMethod == CTOptions.UPLOAD_METHOD_ASP )
			{
				var vars:URLVariables = new URLVariables();
				vars['path'] = o.webdir;
				var pwd:String = "";
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( sh ) {
					if( sh.data && sh.data.userPwd ) {
						pwd = sh.data.userPwd;
					}
				}
				vars.pwd = pwd;
				
				uploadURL = new URLRequest();
				uploadURL.url = CTOptions.uploadScript; // "http://localhost:8888/hugup/cthub/cthub.php";
				uploadURL.method = URLRequestMethod.POST;
				uploadURL.data = vars;
				uploadURL.userAgent = CTOptions.UPLOAD_USER_AGENT;
				
				var file:File = new File( o.dir + (o.dir == "" ? "" : "/") + o.name );
				
				if( file.exists )
				{
					Console.log("Uploading: "  + o.webdir + "" + o.name + "...");
					
					if( viewPanel ) {
						viewPanel.log("\nUploading: "  + o.webdir + "" + o.name + "...", true);
					}
					
					configureListeners( FileReference(file) );
					FileReference(file).upload(uploadURL,"fileToUpload");
				}
			}
		}
		public static function nextFile () :void {
			currFile++;
			if( currFile < upFiles.length ) {
				showProgress( ltProgress + prgStep );
				uploadNext();
			}else{
				uploadFinish();
				Console.log(uploadError ? "Error while uploading" : "Website updated");
			}
		}
		private static function hideProgress () :void {
			if(viewPanel) {
				viewPanel.hideProgress();
			}
		}
		private static function uploadFinish () :void {
			if( uploadCompleteHandler != null ) uploadCompleteHandler(uploadError);
			showProgress( 1 );
			if(viewPanel) {
				setTimeout( hideProgress, 500 );
			}
			uploading = false;
		}
		private static function configureListeners(dispatcher:IEventDispatcher):void {
            dispatcher.addEventListener(Event.CANCEL, cancelHandler);
            dispatcher.addEventListener(Event.COMPLETE, completeHandler);
            dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            dispatcher.addEventListener(Event.OPEN, openHandler);
            dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            dispatcher.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA,uploadCompleteDataHandler);
        }
		private static function cancelHandler(event:Event):void {
            Console.log("cancelHandler: " + event);
        }

        private static function completeHandler(event:Event):void {
			if(viewPanel) {
				viewPanel.log(" done", true);
			}
			setTimeout( nextFile, waitInterval );
        }

        private static function uploadCompleteDataHandler(event:DataEvent):void {
            Console.log("uploadCompleteData: " + event);
        }

        private static function httpStatusHandler(event:HTTPStatusEvent):void {
            Console.log("httpStatusHandler: " + event);
        }
        
        private static function ioErrorHandler(event:IOErrorEvent):void {
            Console.log("ioErrorHandler: " + event);
			uploadError = true;
			if(viewPanel) {
				viewPanel.log(" error " + event, true);
			}
			setTimeout( nextFile, waitInterval );
        }

        private static function openHandler(event:Event):void {
          //  Console.log("openHandler: " + event);
        }

        private static function progressHandler(event:ProgressEvent):void {
          //  var file:FileReference = FileReference(event.target);
		  // Console.log("progressHandler name=" + file.name + " bytesLoaded=" + event.bytesLoaded + " bytesTotal=" + event.bytesTotal);
        }

        private static function securityErrorHandler(event:SecurityErrorEvent):void {
            Console.log("securityErrorHandler: " + event);
			uploadError = true;
			if(viewPanel) {
				viewPanel.log(" error " + event, true);
			}
			setTimeout( nextFile, waitInterval );
        }
		
		private static function preExit () :void {
			uploading = false;
			if( viewPanel ) {
				viewPanel.hideProgress(true);
			}
		}
		
		public static var forceExit:Boolean=false;
		
		
		
		public static function command (argv:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null) :void {
			var args:Array = argv2Array(argv);
			var i:int;
			var sh:SharedObject;
			var ish:SharedObject;
			
			var serverInfo:int = args.indexOf( "server-info" );			
			if( serverInfo >= 0 ) {
				
				var info:String = "Project: " + CTTools.projectDir + "\n";
				info += "Server: " + CTOptions.clientHost + "\n";
				info += "Script: " + CTOptions.uploadScript + "\n";
				
				Console.log( "SERVER-INFO:" );
				Console.log( info );
				
				Application.instance.cmd( "Console show console" );
				
				
				return;
			}
			
			
			complete(cmdComplete, cmdCompleteArgs);
		}
	}
	
}
