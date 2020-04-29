package ct
{
	import flash.display.Sprite;
	import flash.filesystem.*;
	import flash.utils.ByteArray;
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
			// Override Install Options
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			
			if( sh ) {
				if( sh.data && sh.data.installOptions != undefined )
				{
					try {
						var x:XML = new XML(sh.data.installOptions );
					}catch(e:Error) {
						Console.log("Error load install options: " + e);
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
									
										xn = XMLList( x.templates.template.(@name==sh.data.installTemplates[i].name) );
										
										if( xn ) {
											overrideInstallOptions( xn );
											if( CTOptions.debugOutput ) Console.log( "Override options on startup : " + CTOptions.installSharedObjectId + ", dir: " + sh.data.lastProjectDir );
										}
										break;
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
				
				var fileStream:FileStream = new FileStream();
				fileStream.open(f.resolvePath( CTOptions.startConfig), FileMode.READ);
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
					// the config.css file has changed in the app directory..
					// if something in the other files (menu.xml etc.) changes the config.css file needs to be slightly modified too
					// in order to override all config files in the user config directory..
					
					if(CTOptions.debugOutput || CTOptions.verboseMode) Console.log("Copy embed config files to " + CTOptions.configFolder + ".. ");
					
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
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
			if( sh && sh.data && sh.data.userLang ) {
				Language.language = sh.data.userLang;
			}
			Language.onChangeLanguage = changeLanguage;
			addEventListener( AppEvent.SETUP, on_setup);
			
			super.setupApp();
			addEventListener ( AppEvent.START, on_load );
			
		}
		
		private static function changeLanguage () :void {
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
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
			Console.log( "Contemple " + CTOptions.version);
			
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
			var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
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
			if( CTOptions.autoTemplateUpdate ) {
				if( CTTools.activeTemplate ) {
					// load template update.xml
                    CTImporter.lookForTemplateUpdate();
				}
			}
		}
		
		internal var tmpHost:String = "";
		
		private var tmpHostList:Vector.<String>;
		private var currHost:int=-1;
		
		private function downloadHostInfo (host:String="") :void 
		{
			if( CTOptions.verboseMode ) {
				Application.instance.cmd( "Console show console");
			}
			
			if( host == "" ) {
				host = tmpHost;
			}else{
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
				tmpHostList.push( host + CTOptions.hubFolder + "/" + CTOptions.hubScriptFilename );
				tmpHostList.push( host + CTOptions.hubScriptFilename );
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
				if(CTOptions.debugOutput) Console.log( "Downloading template information from '" + tmpHostList[currHost] + "'");
				res.load( tmpHostList[currHost], true, onInstallInfo, vars);
			}
			else
			{
				// Error connect to hub..
				Console.log( "Error finding hub at " + tmpHost );
				windows.addChild( Window( window.InfoWindow( "ErrorNetCnx", Language.getKeyword("Error"), Language.getKeyword("Error no connection"), null, 'error-cnx-window') ) );
			}
		}
		
		public static function overrideInstallOptions ( x:XMLList ) :void
		{		
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
				if( x.@hubScriptFilename != undefined)      CTOptions.hubScriptFilename = x.@hubScriptFilename.toString();
				if( x.@cacheDownloads != undefined)      	CTOptions.cacheDownloads =  CssUtils.stringToBool( x.@cacheDownloads.toString() );
				if( x.@overrideInstallDB != undefined)      CTOptions.overrideInstallDB = x.@overrideInstallDB.toString();
				if( x.@debugOutput != undefined)            CTOptions.debugOutput = CssUtils.stringToBool( x.@debugOutput.toString() );
				
				if( x.@appName != undefined)                CTOptions.appName = x.@appName.toString();
				//if( x.@version != undefined)                CTOptions.version = x.@version.toString();
				
				// if( x.@installTemplate != undefined)        CTOptions.installTemplate = x.@installTemplate.toString();
				if( x.@localSharedObjectId != undefined)    CTOptions.localSharedObjectId = x.@localSharedObjectId.toString();
				if( x.@homeAreaName != undefined)           CTOptions.homeAreaName = x.@homeAreaName.toString();
				if( x.@dbInitFileName != undefined)         CTOptions.dbInitFileName = x.@dbInitFileName.toString();
				if( x.@uploadViewShowFileInfo != undefined) CTOptions.uploadViewShowFileInfo = CssUtils.stringToBool( x.@uploadViewShowFileInfo.toString() );
				if( x.@reverseAreasPopup != undefined)      CTOptions.reverseAreasPopup = CssUtils.stringToBool( x.@reverseAreasPopup.toString() );
				//if( x.@animateBackground != undefined)      CTOptions.animateBackground = CssUtils.stringToBool( x.@animateBackground.toString() );
				//if( x.@animateBackgroundMin != undefined)   CTOptions.animateBackgroundMin = Number( x.@animateBackgroundMin.toString() );
				//if( x.@animateBackgroundMax != undefined)   CTOptions.animateBackgroundMax = Number( x.@animateBackgroundMax.toString() );
				if( x.@localUploadFolder != undefined)      CTOptions.localUploadFolder = x.@localUploadFolder.toString();
				if( x.@uploadMethod != undefined)           CTOptions.uploadMethod = x.@uploadMethod.toString();
				if( x.@uploadScript != undefined)           CTOptions.uploadScript = x.@uploadScript.toString();
				if( x.@updateUrl != undefined)              CTOptions.updateUrl = x.@updateUrl.toString();
				
				if( x.@hashCompareAlgorithm != undefined)   CTOptions.hashCompareAlgorithm = x.@hashCompareAlgorithm.toString();
				if( x.@mobileProjectFolderName != undefined) CTOptions.mobileProjectFolderName = x.@mobileProjectFolderName.toString();
				if( x.@richTextCssClasses != undefined) 	CTOptions.richTextCssClasses = x.@richTextCssClasses.toString().split(",");
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
			
			if(CTOptions.debugOutput) Console.log( "Install Info: " + installInfo);
			
			if( installInfo != "" ) {
				
				var ish:SharedObject = SharedObject.getLocal(CTOptions.installSharedObjectId);
				if( ish && ish.data ) {
					ish.data.installOptions = installInfo;
					ish.flush();
				}
				showInstallTemplates(null);
			}
		}
		
		private static var installProgress:Progress;
		
		private static var installCmdComplete:Function;
		
		public static function showInstallTemplates ( cmdComplete:Function, testStore:Boolean=false ) :void
		{
			var ish:SharedObject = SharedObject.getLocal(CTOptions.installSharedObjectId);
			var i:int;
			var L:int;
			
			if( ish && ish.data )
			{
				installCmdComplete = cmdComplete;
				try {
					var x:XML = new XML( ish.data.installOptions );
				}catch(e:Error) {
					CTMain(Application.instance).tryNextUrl();
					return;
				}
				if( x.templates )
				{
					// installSharedObjectId and localSharedObjectId have to be the same in CTOptions or in CTApp
					// Overriding sharedObjectId !
					var main:CTMain = CTMain(Application.instance);
					overrideInstallOptions( x.templates );
					
					var templates:XMLList = x.templates.template;
					L = templates.length();
					
					if( L == 0 ) {
						if( CTOptions.clientHost == "" ) {
							main.getClientHostInfo();
						} else {
							// App is packaged with clientHost info ...
							main.downloadHostInfo( CTOptions.clientHost );
						}
						return;
					}
					
					if(CTOptions.debugOutput) Console.log( L + " Templates found.." );
					
					var instobj:Object;
					var sh:SharedObject;
					
					if( L == 1 ) {
						
						// Search  @name in ish.installTemplates..
						if( testStore && CTOptions.cacheDownloads ) {
							if( ish.data.installTemplates ) {
								for(i=0; i<ish.data.installTemplates.length; i++) {
									if( ish.data.installTemplates[i].name == x.templates.template.@name.toString() 
										&& ish.data.installTemplates[i].genericPath != undefined 
										&& ish.data.installTemplates[i].genericPath != "" ) {
											
										// found cached 
										if( CTOptions.debugOutput ) Console.log( "Using cached download: " + ish.data.installTemplates[i].genericPath );
										
										Application.instance.cmd( "CTTools template " + ish.data.installTemplates[i].genericPath );
										overrideInstallOptions( templates[0] );
										
										sh = SharedObject.getLocal( CTOptions.localSharedObjectId );
										if( sh && sh.data ) {
											sh.data.installTemplateName = x.templates.template.@name.toString();
											
											if(CTOptions.overrideInstallDB != "") {
												if(CTOptions.debugOutput) Console.log("Reset Override DB..");
												sh.data.overrideDBDone = false;
											}
											sh.flush();
										}
										return;
									}
								}
							}
						}
						
						// Install Template..
						instobj = {
							name:x.templates.template.@name.toString(),
							src: x.templates.template.@src.toString(),
							version: x.templates.template.@version.toString(),
							genericPath: "",
							prjDir:""
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
							iv.setLabel("Downloading template files");
						}catch(e:Error) {
							
						}
						TemplateTools.installTemplate( x.templates.template.@src.toString() );
						
						instobj.genericPath = "app-storage:/" + CTOptions.templateStorage + CTOptions.urlSeparator + TemplateTools.lastExtractedTemplate;
						
						if( ish.data.installTemplates == undefined ) ish.data.installTemplates = [];
						ish.data.installTemplates.push( instobj );
						ish.flush();
						
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
										// Search  @name in ish.installTemplates..
										if( testStore  && CTOptions.cacheDownloads  ) {
											if( ish.data.installTemplates ) {
												for(i=0; i<ish.data.installTemplates.length; i++) {
													if( ish.data.installTemplates[i].name == nm 
														&& ish.data.installTemplates[i].genericPath != undefined 
														&& ish.data.installTemplates[i].genericPath != "" ) {
														// found cached 
														if( CTOptions.debugOutput ) Console.log( "Using cached download: " + ish.data.installTemplates[i].genericPath );
														
														Application.instance.cmd( "CTTools template " + ish.data.installTemplates[i].genericPath );
														
														overrideInstallOptions( XMLList(xm[i]) );
														sh = SharedObject.getLocal( CTOptions.localSharedObjectId );
														if( sh && sh.data ) {
															sh.data.installTemplateName = nm;
															sh.flush();
														}
														if(CTOptions.overrideInstallDB != "") {
															if(CTOptions.debugOutput) Console.log("Reset Override DB..");
															sh.data.overrideDBDone = false;
															sh.flush();
														}
														
														return;
													}
												}
											}
										}
										instobj = {
											name:main.selectedInstallTemplate,
											src: xm[i].@src.toString(),
											version: x.templates.template.@version.toString(),
											genericPath: "",
											prjDir:""
										};
										
										overrideInstallOptions( XMLList(xm[i]) );
										
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
											iv.setLabel("Downloading template files");
										}catch(e:Error) {
											
										}
										TemplateTools.installTemplate( xm[i].@src.toString() );
										
										instobj.genericPath = "app-storage:/" +  CTOptions.templateStorage + CTOptions.urlSeparator + TemplateTools.lastExtractedTemplate;
										
										if( ish.data.installTemplates == undefined ) ish.data.installTemplates = [];
										ish.data.installTemplates.push( instobj );										
										ish.flush();
										
										break;
									}
								}
							}
						},
						continueLabel: Language.getKeyword("SelectTemplate-OK"),
						allowCancel: true,
						autoWidth:false,
						autoHeight:false,
						height: 220,
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
						
						for( i=0; i<L; i++ ) {
							pp.rootNode.addItem( [ x.templates.template[i].@name.toString() ], main.styleSheet ); 
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
			selectedInstallTemplate = lb;
			e.currentPopup.label = lb;
			e.currentPopup.x = templateSelect.cssLeft + Math.floor( ( templateSelect.getWidth() - e.currentPopup.cssSizeX) / 2);
		}
		
		internal var selectedInstallTemplate:String="";
		internal var templateSelect:CssSprite=null;

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
					if ( s ) {
						downloadHostInfo( s );
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
			Console.log("Override Complete..");
			
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
			
			var sc:String = '<?xml version="1.0" encoding="utf-8"?><agf><menu><item iconleft="'+Options.iconDir+'/sidebar-left.png" cmd="TemplateTools show-areas"/><item iconleft="'+Options.iconDir+'/sidebar-right.png" cmd="TemplateTools show-preview"/></menu></agf>';
			secMenu.parseMenu( new XML(sc), "secmenu");
			
			var tmpd:File = File.applicationStorageDirectory.resolvePath ( CTOptions.tmpDir );
			tmpd.createDirectory();
			var templateStorage:File = File.applicationStorageDirectory.resolvePath( CTOptions.templateStorage );
			templateStorage.createDirectory();
			
			if ( sh && sh.data && sh.data.lastProjectDir && sh.data.lastProjectDir != "")
			{
				// Open the last PROJECT from previous session
				
				_resetDB = false;
				
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
					if( CTOptions.mobileProjectFolderName == "ask" )
					{
						/*if( sh && sh.data && sh.data.installTemplates )
						{
							for( var i:int=0; i<sh.data.installTemplates.length; i++) {
								
							}
						}*/
					}
					else
					{
						var fi:File = CTOptions.mobileParentFolder.resolvePath( CTOptions.mobileProjectFolderName );
						if( fi.exists && fi.isDirectory) {
							if(CTOptions.debugOutput) Console.log( "Main.on_load: in mobile " +  fi.url );
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
							Console.log("Error: No InstallView View found in menu");
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
