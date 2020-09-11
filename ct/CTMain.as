package ct
{
	import agf.icons.IconBoolean;
	import flash.display.Sprite;
	import flash.filesystem.*;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	import agf.Main;
	import agf.Options;
	import agf.events.AppEvent;
	import agf.events.PopupEvent;
	import flash.events.Event;
	import ct.CTTools;
	import agf.icons.IconAppLogo;
	import agf.icons.IconData;
	import agf.icons.IconDots;
	import agf.icons.IconFromFile;
	import ct.HtmlEditorTool;
	import agf.ui.Button;
	import agf.ui.Window;
	import agf.ui.Toggle;
	import agf.ui.Label;
	import agf.ui.Popup;
	import agf.ui.PopupItem;
	import agf.ui.Progress;
	import agf.ui.Label;
	import flash.events.MediaEvent;
	import flash.events.MouseEvent;
	import agf.ui.Language;
	import agf.tools.Application;
	import flash.net.*;
	import agf.html.CssSprite;
	import agf.html.CssUtils;
	import agf.tools.Console;
	import agf.io.*;
	import agf.icons.IconArrowDown;
	import agf.utils.FileUtils;
	import agf.utils.FileInfo;
	import com.adobe.crypto.*;
	
	/**
	* Main Application
	* (app target used for css and xml strParser) 
	*/
	public class CTMain extends Main {

		public function CTMain (w:Number, h:Number) :void 
		{
			super(w, h, File.applicationStorageDirectory.resolvePath( CTOptions.configFolder + CTOptions.urlSeparator + CTOptions.startConfig).url, CTWindows );
			
			// embed tools and some icons
			addToolPath( "ct" );
			
			var st:Settings;
			var sc:StartScreen;
			var oc:OpenScreen;
			var ts:TemplateScreen;
			var pv:Preview;
			var pg:PageEditor;
			var uv:UploadView;
			var iv:InstallView;
			var he:HtmlEditor;
			var het:HtmlEditorTool;
			var te:TextEditor;
			var tools:CTTools;
			var ico1:IconAppLogo;
			var ico2:IconDots;
			var ico3:IconData;
			
			if( mainMenu ) {
				mainMenu.visible = false;
			}	
		}
		
		// Nothing from the app is created just yet, not even CTMain..(called early on app start)
		public static function setupConfigFiles () :void
		{
			// Override Install Options from lastProjectDir..
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			
			if( sh ) {
				if( sh.data )
				{
					
					if( sh.data.preferences ) {
						var prefs:Object = sh.data.preferences;
						
						if( prefs.autoSave != undefined ) CTOptions.autoSave = prefs.autoSave;
						if( prefs.debugOutput != undefined ) CTOptions.debugOutput = prefs.debugOutput;
						if( prefs.monitorFiles != undefined ) CTOptions.monitorFiles = prefs.monitorFiles;
						if( prefs.nativePreview != undefined ) CTOptions.nativePreview = prefs.nativePreview;
						if( prefs.softKeyboard != undefined ) CTOptions.softKeyboard = prefs.softKeyboard;
						if( prefs.previewInEditor != undefined ) CTOptions.previewInEditor = prefs.previewInEditor;
						if( prefs.previewAlign != undefined ) {
							CTOptions.previewAtBottom = prefs.previewAlign;
						}else{
							if( CTOptions.isMobile ) {
								// bottom preview by default on mobile
								CTOptions.previewAtBottom = true;	
							}
						}
					}
					
					if( CTOptions.previewAtBottom ) {
						TemplateTools.editor_w = HtmlEditor.tmpEditorW = 1;
						TemplateTools.editor_h = HtmlEditor.tmpEditorH = 0.6;
					}else{
						TemplateTools.editor_w = HtmlEditor.tmpEditorW = 0.6;
						TemplateTools.editor_h = HtmlEditor.tmpEditorH = 1;
					}
					
					if( !CTOptions.previewInEditor ) {
						HtmlEditor.showPreview( false );
					}
					if ( sh.data.installOptions != undefined ) {
						try {
							var x:XML = new XML(sh.data.installOptions );
						}catch(e:Error) {
							Console.log("Error Load Install Options: " + e);
						}
						
						if ( x ) {
							overrideInstallOptions( x.templates );
							
							if( sh.data.lastProjectDir != undefined )
							{
								if( sh.data.installTemplates != undefined ) {
									var L:int = sh.data.installTemplates.length;
									var xn:XMLList;
									
									for(var i:int=0; i<L; i++) {
										if( sh.data.installTemplates[i].prjDir == sh.data.lastProjectDir ) {
										
											xn = x.templates.template.(@name==sh.data.installTemplates[i].name);
											
											if( xn ) {
												overrideInstallOptions( xn );
												if( CTOptions.debugOutput || CTOptions.verboseMode ) Console.log( "Override Options On Startup : " + CTOptions.installSharedObjectId + ", Dir: " + sh.data.lastProjectDir );
											}
											break;
										}
									}
								}
							}
						}
					}
				}
			}
			
			// Copy config files from CTOptions.appConfigDir to CTOptions.configFolder because app dir is not writable..
			
			var f:File = File.applicationStorageDirectory.resolvePath( CTOptions.configFolder );
			
			if( !f || !f.exists ) 
			{
				CTTools.copyFolder( File.applicationDirectory.resolvePath( CTOptions.appConfigDir ).url, f.url );
			}
			else
			{
				
				// Test if the config.css file has changed (this happens after a re-compile of the app with new config files)
				var cfile:File = f.resolvePath( CTOptions.startConfig );
				var overrid:Boolean = false;
				
				if ( cfile.exists )
				{
					var fileStream:FileStream = new FileStream();
					fileStream.open( cfile, FileMode.READ);
					var b:ByteArray = new ByteArray();
					fileStream.readBytes(b);
					fileStream.close();
					
					var intFileStream:FileStream = new FileStream();
					intFileStream.open(File.applicationDirectory.resolvePath(CTOptions.appConfigDir).resolvePath(CTOptions.startConfig), FileMode.READ);
					var b2:ByteArray = new ByteArray();
					intFileStream.readBytes(b2);
					intFileStream.close();
				
					
					var r:String = MD5.hashBytes( b );
					var r2:String = MD5.hashBytes( b2 );
					
					if( r != r2 ) 
					{
						overrid = true;
					}
				}else{
					overrid = true;
				}
				
				if( overrid ) {
					// the config.css file has changed in the app directory..
					// if something in the other files (menu.xml etc.) changes the config.css file needs to be slightly modified too
					// in order to override all config files in the user config directory..
					
					if(CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy Embed Config Files To " + CTOptions.configFolder);
					
					CTTools.copyFolder( File.applicationDirectory.resolvePath( CTOptions.appConfigDir ).url, f.url );
				}
			}
		}
		
		// Mainmenu, Window and app containers just created, but not fully setup..
		private function on_setup (e:Event) :void {
			CTTools.clearFiles();
		}
		
		// CTMain just instantiated
		public override function setupApp () :void {
			
			if( HtmlEditor.webView ) {
				HtmlEditor.webView.stage = null;
				HtmlEditor.webView = null;
			}
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh && sh.data && sh.data.userLang ) {
				Language.language = sh.data.userLang;
			}
			Language.onChangeLanguage = changeLanguage;
			addEventListener( AppEvent.SETUP, on_setup);
			
			super.setupApp();
			addEventListener ( AppEvent.START, on_load );
			
		}
		
		private static function changeLanguage () :void {
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh ) {
				 if( sh.data ) {
					sh.data.userLang = Language.language;
					sh.flush();
				 }
				 sh.close();
			 }
		}
		
		// On open-last-project when app starts
		private function startupOpenHandler () :void
		{
			if( CTOptions.debugOutput ) Console.log( "Contemple " + CTOptions.version);
			
			if( CTTools.activeTemplate ) {
				Console.log(CTTools.activeTemplate.name + " " + CTTools.activeTemplate.version);
				if( stage && stage.nativeWindow ) stage.nativeWindow.title = CTOptions.appName + " " + CTTools.activeTemplate.version;
			}else{
				if( stage && stage.nativeWindow ) stage.nativeWindow.title = CTOptions.appName + " " + CTOptions.version;
			}
			Application.instance.hideLoading();
			
			if( ! appOpened ) {
				appOpened = true;
				CTTools.runCommandList("appload", onAppLoadCmds);
			}else{
				onAppLoadCmds();
			}
		}
		private static var appOpened:Boolean=false;
		
		private function onAppLoadCmds ():void {
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh.data && sh.data.userLang ) {
				Language.language = sh.data.userLang;
			}
			CTTools.runCommandList("appstart", onAppStartCmds );
		}
		
		private function onResetDBSave () :void {
			// restart
			Application.instance.cmd("Application restart");
		}
		
		private function onAppStartCmds () :void
		{
			// App started and last project fully loaded..
			if( _resetDB ) {
				// fix old content showing up..
				try {
				CTTools.invalidateFiles();
				CTTools.save( onResetDBSave );
				}catch (e:Error) {
					Console.log("ResetDB Save Error: " + e);
				}
			}
			if( CTTools.activeTemplate ) {
				if ( CTOptions.autoTemplateUpdate )
				{
					// load template update.xml
					CTImporter.lookForTemplateUpdate();
				}
				
				if( CTOptions.syncOnStart ) {
					// download content sync version
				}
			}
		}
		
		internal var tmpHost:String = "";
		
		private static var tmpHostList:Vector.<String>;
		private static var currHost:int=-1;
		
		private function downloadHostInfo (host:String="") :void 
		{
			if( CTOptions.verboseMode ) {
				Application.instance.cmd( "Console show console");
			}
			
			if( host == "" )
			{
				// on password...
				host = tmpHost;
			}
			else
			{
				// first time called...
				tmpHost = host;
			}
			
			if ( host != "" )
			{
				var ish:SharedObject = SharedObject.getLocal(CTOptions.installSharedObjectId);
				if( ish ) {
					// store entered web uri
					ish.data.hostInfoUrl = tmpHost;
					ish.flush();
				}
				
				tmpHostList = new Vector.<String>();
				tmpHostList.push( tmpHost );
				
				if( host.charAt( host.length-1) != "/" ) host += "/";
				
				var fold:int = tmpHost.indexOf( CTOptions.hubFolder );
				var scri:int = tmpHost.indexOf( CTOptions.hubScriptFilename );
				
				tmpHostList.push( host );
				
				if( fold == -1 && scri == -1 ) tmpHostList.push( host + CTOptions.hubFolder + "/" + CTOptions.hubScriptFilename );
				if( scri == -1 ) tmpHostList.push( host + CTOptions.hubScriptFilename );
				
				if( host.substring( 0, 7 ) == "http://" )
				{
					host = "https://" + host.substring(7);
					tmpHostList.push( host  );
					if( fold == -1 && scri == -1 ) tmpHostList.push( host + CTOptions.hubFolder + "/" + CTOptions.hubScriptFilename );
					if( scri == -1 ) tmpHostList.push( host + CTOptions.hubScriptFilename );
				}
				else if( host.substring( 0, 8 ) == "https://" )
				{
					host = "http://" + host.substring(8);
					tmpHostList.push( host  );
					if( fold == -1 && scri == -1 ) tmpHostList.push( host + CTOptions.hubFolder + "/" + CTOptions.hubScriptFilename );
					if( scri == -1 ) tmpHostList.push( host + CTOptions.hubScriptFilename );
				}
				
				currHost = -1;
				tryNextUrl();
			}
		}
			
		internal function tryNextUrl () :void 
		{
			currHost++;
			if( currHost < tmpHostList.length )
			{
				var pwd:String = "";
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( sh && sh.data && sh.data.userPwd ) {
					pwd = sh.data.userPwd;
				}else{
					Application.instance.cmd( "CTTools get-password", downloadHostInfo );
					return;
				}
				var res:Resource = new Resource();
				var vars:URLVariables = new URLVariables();
				vars.install = 1;
				vars.pwd = pwd;
				if(CTOptions.debugOutput) Console.log( "Downloading Template Information From '" + tmpHostList[currHost] + "'");
				res.load( tmpHostList[currHost], true, onInstallInfo, vars);
			}
			else
			{
				// Error connect to hub..
				Console.log( "Error Finding Hub At " + tmpHost );
				windows.addChild( Window( window.InfoWindow( "ErrorNetCnx", Language.getKeyword("Error"), Language.getKeyword("Error no connection"), null, 'error-cnx-window') ) );
			}
		}
		
		public static function overrideInstallOptions ( x:XMLList, reset:Boolean=false ) :void
		{
			if( reset ) {
				
				// Reset critical project settings
				CTOptions.projectName = "";
				CTOptions.appName = "Contemple";
				CTOptions.version = CTOptions.contempleVersion; // "1.0.12";
				CTOptions.hubFolder = CTOptions.hubFolderDefault;
				CTOptions.hubScriptFilename = CTOptions.hubScriptFilenameDefault;
				CTOptions.localUploadFolder = "min";
				CTOptions.hashCompareAlgorithm = "md5";
				CTOptions.localSharedObjectId = CTOptions.localSharedObjectIdDefault;
				CTOptions.dbInitFileName = "db-index.xml";
				CTOptions.uploadViewShowFileInfo = true;
				CTOptions.reverseAreasPopup = true;
				CTOptions.updateUrl = "";
				CTOptions.mobileProjectFolderName "ask";
			}
			
			if( x )
			{
				// Override options by install.xml:
				if( CTTools.activeTemplate ) {
					if( x.@name != undefined ) {
						CTTools.activeTemplate.name = x.@name.toString();
					}
					if( x.@templateUpdateUrl != undefined) {
						CTTools.activeTemplate.update = x.@templateUpdateUrl.toString();
					}
				}
				
				if( x.@projectName != undefined)            CTOptions.projectName = x.@projectName.toString();
				if( x.@uploadScript != undefined)           CTOptions.uploadScript = x.@uploadScript.toString();
				if( x.@hubScriptFilename != undefined)      CTOptions.hubScriptFilename = x.@hubScriptFilename.toString();
				if( x.@overrideInstallDB != undefined)      CTOptions.overrideInstallDB = x.@overrideInstallDB.toString();
				if( x.@appName != undefined)                CTOptions.appName = x.@appName.toString();
				if( x.@localSharedObjectId != undefined)    CTOptions.localSharedObjectId = x.@localSharedObjectId.toString();
				if( x.@homeAreaName != undefined)           CTOptions.homeAreaName = x.@homeAreaName.toString();
				if( x.@dbInitFileName != undefined)         CTOptions.dbInitFileName = x.@dbInitFileName.toString();
				if( x.@uploadViewShowFileInfo != undefined) CTOptions.uploadViewShowFileInfo = CssUtils.stringToBool( x.@uploadViewShowFileInfo.toString() );
				if( x.@reverseAreasPopup != undefined)      CTOptions.reverseAreasPopup = CssUtils.stringToBool( x.@reverseAreasPopup.toString() );
				if( x.@localUploadFolder != undefined)      CTOptions.localUploadFolder = x.@localUploadFolder.toString();
				if( x.@uploadMethod != undefined)           CTOptions.uploadMethod = x.@uploadMethod.toString();
				if( x.@updateUrl != undefined)              CTOptions.updateUrl = x.@updateUrl.toString();
				if( x.@hashCompareAlgorithm != undefined)   CTOptions.hashCompareAlgorithm = x.@hashCompareAlgorithm.toString();
				if( x.@mobileProjectFolderName != undefined) CTOptions.mobileProjectFolderName = x.@mobileProjectFolderName.toString();
			}
		}
		
		private function onInstallInfo ( e:Event, r:Resource ) :void
		{
			if( !r || r.loaded != 1 ) {
				tryNextUrl();
				return;	
			}
			
			var installInfo:String="";
			
			try {
				installInfo = String(r.obj) || "";
			}catch(e:Error) {
				installInfo = "";
			}
			if( installInfo == null || installInfo == "null") {
				installInfo = "";
			}
			
			if( installInfo == "no-pass" ) {
				Application.instance.cmd("CTTools reset-password");
				downloadHostInfo( tmpHost );
				return;
			}
			
			if( !CTOptions.verboseMode ) {
				Application.instance.cmd( "Application view InstallView" );
				installProgress = InstallView( Application.instance.view.panel.src ).progress;
			}
			if(installProgress) installProgress.value = 0;
			
			if( CTOptions.verboseMode ) Console.log( "Install Info: " + installInfo);
			
			if( installInfo != "" ) {
				var ish:SharedObject = SharedObject.getLocal(CTOptions.installSharedObjectId);
				if( ish && ish.data ) {
					ish.data.installOptions = installInfo;
					ish.flush();
				}
				setTimeout( showInstallTemplates, 357 );
			}
		}
		
		private static var installProgress:Progress;
		
		private static var installCmdComplete:Function;
		
		public static function showInstallTemplates ( cmdComplete:Function=null, testStore:Boolean=false ) :void
		{
			var ish:SharedObject = SharedObject.getLocal(CTOptions.installSharedObjectId);
			var i:int;
			var L:int;
			
			if( ish && ish.data )
			{
				installCmdComplete = cmdComplete;
				
				try {
					var x:XML = new XML( ish.data.installOptions );
				}catch (e:Error) {
					
					CTMain(Application.instance).tryNextUrl();
					return;
					
				}
				if( x.templates )
				{
					// installSharedObjectId and localSharedObjectId have to be the same in CTOptions or in CTApp
					// Overriding sharedObjectId !
					var main:CTMain = CTMain(Application.instance);
					
					var templates:XMLList = x.templates.template;
					L = templates.length();
					
					if( L == 0 ) {
						if( CTOptions.clientHost == "" )
						{
							// try again..
							CTMain(Application.instance).tryNextUrl();
							return;
						}
						else
						{
							// App is packaged with clientHost info ...
							main.downloadHostInfo( CTOptions.clientHost );
						}
						return;
					}
					
					CTOptions.uploadScript = tmpHostList[currHost];
					var fi:FileInfo = FileUtils.fileInfo( CTOptions.uploadScript );
					
					CTOptions.hubFolder = fi.directory;
					CTOptions.hubScriptFilename = fi.filename;
					
					overrideInstallOptions( x.templates, true );
					
					if( CTOptions.verboseMode || CTOptions.debugOutput ) Console.log( L + " Templates found.." );
					
					var instobj:Object;
					var sh:SharedObject;
					
					if( L == 1 ) {
						
						// Install Template..
						instobj = {
							name:x.templates.template.@name.toString(),
							src: x.templates.template.@src.toString(),
							version: x.templates.template.@version.toString(),
							genericPath: "",
							prjDir:"",
							installOp: ish.data.installOptions
						};
						
						overrideInstallOptions( templates.template );
						
						sh = SharedObject.getLocal( CTOptions.localSharedObjectId );
						if( sh && sh.data ) {
							sh.data.installTemplateName = x.templates.template.@name.toString();
							sh.flush();
						}
						
						if(CTOptions.overrideInstallDB != "") {
							if(CTOptions.debugOutput) Console.log("Reset Override DB..");
							sh.data.overrideDBDone = false;
							sh.flush();
						}
						try {
							var iv:InstallView;
							iv = InstallView( Application.instance.view.panel.src );
							iv.showProgress( 0.05 );
							iv.setLabel("Downloading Template Files");
						}catch(e:Error) {
							
						}
						
						if( ish.data.installTemplates == undefined ) ish.data.installTemplates = [];
						ish.data.installTemplates.push( instobj );
						ish.flush();
						
						TemplateTools.installTemplate( x.templates.template.@src.toString() );
						
						instobj.genericPath = "app-storage:/" + CTOptions.templateStorage + CTOptions.urlSeparator + TemplateTools.lastExtractedTemplate;
					}
					else
					{
						// Select a template..
						
						main.templateSelect = new CssSprite( 0, 0, null, main.styleSheet, 'body', '', '', false );
						
						var selwin:Window = Window( main.window.ContentWindow( "TemplateSelWindow", Language.getKeyword( "Select a Template"), main.templateSelect, {
						complete: function (s:Boolean) { 
							if ( s ) {
								var nm:String;
								var xm:XMLList = x.templates.template;
								var L:int = xm.length();
								var iv:InstallView;
								
								for(i =0 ; i<L; i++ )
								{
									nm = xm[i].@name.toString();
									if( nm == main.selectedInstallTemplate )
									{
										instobj = {
											name: main.selectedInstallTemplate,
											src: xm[i].@src.toString(),
											version: xm[i].@version.toString(),
											genericPath: "",
											prjDir:"",
											installOp: ish.data.installOptions
										};
										
										
										overrideInstallOptions( xm[i] );
										
										sh = SharedObject.getLocal( CTOptions.localSharedObjectId );
										if( sh && sh.data ) {
											sh.data.installTemplateName = main.selectedInstallTemplate;
											sh.flush();
										}
										
										if(CTOptions.overrideInstallDB != "") { 
											if(CTOptions.debugOutput) Console.log("Reset Override DB..");
											sh.data.overrideDBDone = false;
											sh.flush();
										}
										
										try {
											iv = InstallView( Application.instance.view.panel.src );
											iv.setProgress( 0.05 );
											iv.setLabel("Downloading Template Files");
										}catch(e:Error) {
											
										}
										
										if( ish.data.installTemplates == undefined ) ish.data.installTemplates = [];
										ish.data.installTemplates.push( instobj );										
										ish.flush();
										
										TemplateTools.installTemplate( xm[i].@src.toString() );
										
										instobj.genericPath = "app-storage:/" +  CTOptions.templateStorage + CTOptions.urlSeparator + TemplateTools.lastExtractedTemplate;
										
										break;
									}
								}
							}
						},
						continueLabel: Language.getKeyword("SelectTemplate-OK"),
						allowCancel: true,
						autoWidth:false,
						autoHeight:false,
						height: int(220 * CssUtils.numericScale),
						cancelLabel: Language.getKeyword("SelectTemplate-Cancel")
						}, 'select-template-window') );
						
						main.windows.addChild( selwin );
						
						main.templateSelect.setWidth( selwin.getWidth() );
						
						var tdiv:CssSprite = new CssSprite( 0, 0, main.templateSelect, main.styleSheet, 'div', '', 'install-template-select', false);
						
						var lb:Label = new Label(0,0,tdiv,main.styleSheet,'','install-template-select-label',true);
						lb.label = Language.getKeyword( "Multiple Templates are available to install" );
						lb.init();
						lb.x = tdiv.cssLeft;
						lb.y = tdiv.cssTop + 8;
						
						var pp:Popup = new Popup( [ "Select..", new IconArrowDown( main.mainMenu.iconColor ) ], 0,0, tdiv, main.styleSheet, '', 'install-template-popup', false);
						
						pp.x = main.templateSelect.cssLeft + Math.floor( ( main.templateSelect.getWidth() - pp.cssSizeX) / 2);
						pp.y = lb.y + lb.getHeight() + 16;
						var n:String;
						var ppi:PopupItem;
						
						for ( i = 0; i < L; i++ ) {
							n = x.templates.template[i].@name.toString();
							ppi = pp.rootNode.addItem( [ Language.getKeyword( n ) ], main.styleSheet ); 
							ppi.options.name = n;
						}
						
						pp.addEventListener( PopupEvent.SELECT, CTMain( main ).selectInstallTemplate );
					}
				}else{
					CTMain(Application.instance).tryNextUrl();
					return;
				}
			}
		}
		
		private function selectInstallTemplate (e:PopupEvent) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			selectedInstallTemplate = curr.options.name;
			e.currentPopup.label = lb;
			e.currentPopup.x = templateSelect.cssLeft + Math.floor( ( templateSelect.getWidth() - e.currentPopup.cssSizeX) / 2);
		}
		
		internal var selectedHistoryContent:String="";
		internal var selectedInstallTemplate:String="";
		internal var templateSelect:CssSprite=null;
		internal var publishHistorySprite:CssSprite=null;
		internal var publishHistoryID:int=-1;
		
		public function showPublishHistory () :void
		{
			var res:Resource = new Resource();
			var vars:URLVariables = new URLVariables();
			vars.versions = 1;
			var pwd:String = "";
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			if ( sh ) {
				if( sh.data && sh.data.userPwd ) {
					pwd = sh.data.userPwd;
				}else{
					Application.instance.cmd( "CTTools get-password", showPublishHistory);
					return;
				}
			}
			vars.pwd = pwd;
			res.load( CTOptions.uploadScript, true, onPublishHistoryIds, vars);
		}
		
		private function onHistoryContent ( e:Event, r:Resource ) :void
		{
			if ( r.loaded == 1 ) {
				
				var cnt:String;
				
				try {
					cnt = String(r.obj) || "";
				}catch(e:Error) {
					cnt = "";
				}
				if( cnt == null ||cnt == "null") {
					cnt = "";
				}
				
				if ( cnt != "" )
				{
					Console.log( "Content Version " + publishHistoryID + ":\n" + cnt );
					var f:File = File.applicationStorageDirectory.resolvePath( CTOptions.tmpDir + CTOptions.urlSeparator + "content.xml" );
					CTTools.writeTextFile( f.url, cnt );
					CTTools.loadDefaultContent( f.url, onContentSync );
				}
			}else{
				Console.log("Error: Can Not Load Content Version " + publishHistoryID );
			}
		}
		
		private function onContentSync ( success:Boolean=false ) :void
		{
			// Save and Restart the app
			CTTools.onFirstSync();
		}
		
		public function installContentHistory ( id:int ) :void
		{
			publishHistoryID = id;
			
			// Download latest online content version:
				
			var res:Resource = new Resource();
			var vars:URLVariables = new URLVariables();
			vars.content = 1;
			vars.version = id;
			var pwd:String = "";
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			if( sh ) {
				if( sh.data && sh.data.userPwd ) {
					pwd = sh.data.userPwd;
				}
			}
			vars.pwd = pwd;
			
			res.load( CTOptions.uploadScript, true, onHistoryContent, vars);
		}
		
			
		private function selectContentHistory (e:PopupEvent) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			selectedHistoryContent = lb;
			e.currentPopup.label = lb;
			e.currentPopup.x = publishHistorySprite.cssLeft + Math.floor( ( publishHistorySprite.getWidth() - e.currentPopup.cssSizeX) / 2);
		}
		
		
		public function onPublishHistoryIds ( e:Event, r:Resource ) :void {

			if( r.loaded == 1 ) {
				
				var ids:String = "";
				
				try {
					ids = String(r.obj) || "";
				}catch(e:Error) {
					ids = "";
				}
				if( ids == null ||ids == "null") {
					ids = "";
				}
				
				if( ids != "" )
				{
					publishHistorySprite = new CssSprite( 0, 0, null, styleSheet, 'body', '', '', false );
					
					var selwin:Window = Window( window.ContentWindow( "PublishHistoryWindow", Language.getKeyword( "Select a Content Version"), publishHistorySprite, {
					complete: function (s:Boolean) { 
						if ( s )
						{
							installContentHistory( parseInt( selectedHistoryContent ) );
						}
					},
					continueLabel: Language.getKeyword("SelectPublishHistory-OK"),
					allowCancel: true,
					autoWidth:false,
					autoHeight:false,
					height: int(220 * CssUtils.numericScale),
					cancelLabel: Language.getKeyword("SelectPublishHistory-Cancel")
					}, 'select-publish-history-window') );
					
					windows.addChild( selwin );
					
					publishHistorySprite.setWidth( selwin.getWidth() );
					
					var tdiv:CssSprite = new CssSprite( 0, 0, publishHistorySprite, styleSheet, 'div', '', 'install-template-select', false);
					
					var lb:Label = new Label(0,0,tdiv,styleSheet,'','install-template-select-label',true);
					lb.label = Language.getKeyword( "Multiple versions of the website content are available:" );
					lb.init();
					lb.x = tdiv.cssLeft;
					lb.y = tdiv.cssTop + 8;
					
					var pp:Popup = new Popup( [ "Select..", new IconArrowDown( mainMenu.iconColor ) ], 0,0, tdiv, styleSheet, '', 'install-template-popup', false);
					
					pp.x = publishHistorySprite.cssLeft + Math.floor( ( publishHistorySprite.getWidth() - pp.cssSizeX) / 2);
					pp.y = lb.y + lb.getHeight() + 16;
					
					
					var hids:Array = ids.split(",");
					hids.sort( Array.NUMERIC );
					var L:int = hids.length;
					
					for ( var i:int = 0; i < L; i++ )
					{
						pp.rootNode.addItem( [ hids[i] ], styleSheet ); 
					}
					
					pp.addEventListener( PopupEvent.SELECT, selectContentHistory );
					
				}else{
					Console.log("Error History ID'S");
				}
			}else{
				Console.log( "Error Can Not Load History Index" );
			}
		}
		
		public function getClientHostInfo ():void
		{
			var msg:String = Language.getKeyword("CT-Get-Client-Host-MSG");
			var obj:Object = {};
			msg = ct.TemplateTools.obj2Text( msg, '#', obj);
			
			var ish:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			var weburi:String = CTOptions.defaultServerStartUrl;
			
			if( ish && ish.data && ish.data.hostInfoUrl != undefined && ish.data.hostInfoUrl != "" ) {
				weburi = ish.data.hostInfoUrl;
			}
			
			var win2:Window = Window( window.GetStringWindow( "WelcomeWindow2", msg, weburi, {
				complete: function (s:String) {
					if ( s )
					{
						if( s.substring( 0, 4) != "http" ) {
							downloadHostInfo( "http://" + s );
						}else{
							downloadHostInfo( s );
						}
					}
				},
				continueLabel: Language.getKeyword("Welcome-Host-OK"),
				multiline:false,
				allowCancel: true,
				autoWidth:false,
				autoHeight:true,
				cancelLabel: Language.getKeyword("Welcome-Cancel")
			}, 'startup2-window') );
			windows.addChild( win2 );
		}
		
		private var _resetDB:Boolean=false;
		
		// app loaded and setup complete handler
		private function overrideComplete () :void
		{
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			var lsh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			
			if ( sh && sh.data && sh.data.lastProjectDir && sh.data.lastProjectDir != "")
			{
				lsh.data.overrideDBDone = true;
				if(CTOptions.debugOutput) Console.log( "-> Override DB: local.db - "  + sh.data.lastProjectDir  + ", db: " + CTOptions.overrideInstallDB );
				_resetDB = true;
				
				CTTools.setProjectDirUrl( sh.data.lastProjectDir );
				sh.flush();
				var rv:Boolean = CTTools.open(startupOpenHandler);
			}
		} 
		
		private function on_load (e:AppEvent) :void
		{
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			var rv:Boolean = false;
			if(mainMenu)
			{
				mainMenu.visible = true;
				
				// set content button active
				if( mainMenu.items && mainMenu.items.length > 2 ) {
					Button(mainMenu.items[2]).swapState("active");
				}	
			}
			
			//var sc:String = '<?xml version="1.0" encoding="utf-8"?><agf><menu><item iconleft="'+Options.iconDir+'/sidebar-left.png" cmd="TemplateTools show-areas"/><item iconleft="'+Options.iconDir+'/sidebar-right.png" cmd="TemplateTools show-preview"/></menu></agf>';
			//var sc:String = '<?xml version="1.0" encoding="utf-8"?><agf><menu><item iconleft="'+Options.iconDir+'/glasses.png" cmd="TemplateTools show-preview"/></menu></agf>';
			//secMenu.parseMenu( new XML(sc), "secmenu");
			
			var tmpd:File = File.applicationStorageDirectory.resolvePath ( CTOptions.tmpDir );
			tmpd.createDirectory();
			var templateStorage:File = File.applicationStorageDirectory.resolvePath( CTOptions.templateStorage );
			templateStorage.createDirectory();
			
			if ( sh && sh.data && sh.data.lastProjectDir && sh.data.lastProjectDir != "")
			{
				// Open the last PROJECT from previous session
				
				_resetDB = false;
				if( CTOptions.verboseMode || CTOptions.debugOutput ) {
					Console.log("Opening Previous Project: " +  sh.data.lastProjectDir );
				}
				
				if( CTOptions.overrideInstallDB != "" ) {
					var lsh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
					if( lsh.data.overrideDBDone != true )
					{
						// override the database by install.xml config
						var nm:String = "local.db";
						
						try 
						{
							CTTools.copyFile( CTOptions.overrideInstallDB, sh.data.lastProjectDir + CTOptions.urlSeparator + nm, overrideComplete );
							
							return;
						}catch(e:Error) {
							Console.log("Database Override Error: " + e);
						}
					}
				}
				
				CTTools.setProjectDirUrl( sh.data.lastProjectDir );
				sh.flush();
				rv = CTTools.open(startupOpenHandler);
				
			}else{
				if( CTOptions.isMobile )
				{
					if( CTOptions.mobileProjectFolderName != "ask" )
					{
						var fi:File = CTOptions.mobileParentFolder.resolvePath( CTOptions.mobileProjectFolderName );
						if( fi.exists && fi.isDirectory) {
							CTTools.setProjectDirUrl( fi.url );
							rv = CTTools.open(startupOpenHandler);
						}
					}
				}
			}
			
			if( !rv )
			{
				// Open Failed...
				
				Application.instance.hideLoading();
				var msg:String;
				var obj:Object;
				
				if( CTOptions.installTemplate != "" )
				{
					// The App is packaged with an embeded template:
					// ---
					// Add theme-folder to Air export settings, 
					// Set CTOptions.installTemplate to theme-folder added (app:/theme-dir) 
					// Then re-compile the air app
					// ---
					var iv:InstallView;
					msg = Language.getKeyword("CT-Install-Embed-MSG");
					obj = {path: CTOptions.installTemplate, project:Language.getKeyword( CTOptions.projectName ) };
					msg = TemplateTools.obj2Text( msg, '#', obj );
					
					if( CTOptions.verboseMode ) 
					{
						Application.instance.cmd("Console show console");
						Console.log(msg);
						
					}
					else
					{
						try {
							Application.instance.cmd( "Application view InstallView" );
							iv = InstallView( Application.instance.view.panel.src );
						}catch( e:Error ) {
							Console.log("Error: No InstallView View Found In Menu");
						}
					}
					
					if( iv ) {
						iv.setLabel( msg );
					}
					
					Application.instance.cmd( "CTTools template " + CTOptions.installTemplate );
					
				}
				else
				{
					// Download template form clientHost or ask user for clientHost url
					if ( CTOptions.clientHost == "" ) {
						cmd("Application view StartScreen");
					} else {
						// App is packaged with clientHost info
						downloadHostInfo( CTOptions.clientHost );
					}
				}
			}
			
			if( CTOptions.autoUpdate && CTOptions.clientHost != "" ) {
                CTImporter.lookForAppUpdate();
			}
		}
		
	}
}
