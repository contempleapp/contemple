package agf
{	
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.ui.*;

	
	import agf.view.ViewContainer;
	import agf.events.AppEvent;
	import agf.events.MenuEvent;
	import agf.events.ShortcutEvent;
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.html.CssUtils;
	import agf.io.Resource;
	import agf.io.ResourceMgr;
	import agf.tools.Application;
	import agf.tools.Command;
	import agf.tools.Console;
	import agf.ui.Ctrl;
	import agf.ui.Menu;
	import agf.ui.ShortcutMgr;
	import agf.utils.StrVal;
	import agf.ui.Window;
	import agf.ui.Popup;
	import agf.ui.DefaultWindows;
	import agf.tools.SetValue;
	import agf.ui.Language;
	import agf.icons.IconLoading;
	
	
	/**
	 * 
	 * Abstract Main Application Class
	 * 
	 * - Loads conf.css file (main.conf)
	 * - Load plugin files set in the configuration
	 * - Load view.xml and menu.xml configuration files
	 * - Initialize shortcuts
	 * - Display main menu and view panels
	 * - Handle file resource loading
	 * - Handle toolpaths
	 *
	 * Create and Access
	 *
	 *   use:  import agf.tools.Application;
	 *       
	 *   create the appliction in  swf root Class:
	 *
	 *       - Application.init ( new ExMain (550,400,"res/conf-user.css") );  // Create your Application ExMain wich simply extends Main
	 *       
	 *   access the Application:
	 *       
	 *       - var tmp:Object = Application.instance;                      // Generic Object
	 *       - var tmp:Main = Main( Application.instance );                // Default Main Class
	 *		 - var tmp:ExMain = ExMain ( Application.instance );           // Overriden Main Class
	 */
	public class Main extends CssSprite
	{
		public function Main ( w:Number=0, h:Number=0, configUrl:String="", winController:Class=null ) :void 
		{
			super(w, h, null, null, 'app', '', '', false);
			
			// Embed console
			var console:Console;
			var setVal:SetValue;
			
			window = winController == null ? new DefaultWindows() : new winController();
			autoSwapState = "";
			
			// Use config file from arguments
			if( configUrl != "" ) _config = configUrl;
		}
		
		public var toolPaths:Array = ["agf.tools", "agf.icons", "plugins"];
		
		public var rtContainer:CssSprite; // the root of the app on the stage, everything should be in here 
		public var view:ViewContainer;
		protected var plugins:Object;
		protected var pluginCount:int;
		protected var pluginsLoaded:int;
		protected var pluginContainer:Sprite;
		private var loadSprite:CssSprite;
		private var loadSpriteContent:Sprite;
		public var shortcutMgr:ShortcutMgr;
		public var mainMenu:Menu;
		public var secMenu:Menu;
		public var appContent:CssSprite;
		public var windows:CssSprite;
		public var topContent:CssSprite;
		protected var _configFile:String="";
		protected var conf:CssStyleSheet;
		protected var tMenuConfLoaded:Boolean=false;
		protected var tLangConfLoaded:Boolean=false;
		protected var tViewConfLoaded:Boolean=false;
		protected var tAppInitialized:Boolean=false;
		public var resourceMgr:ResourceMgr;
		public var window:DefaultWindows;
		
		public function get config () :CssStyleSheet {	return conf;  }
		
		/**
		* This method have to be called before any other application initializing/creation
		* @param swfroot the root of the swf where the application is running
		* @param useDPIScale auto font-size scale, this should be enabled only on mobile devices with older AIR Runtimes older than version 20
		*/
		public static function prepare ( swfRoot:MovieClip, useDPIScale:Boolean=true ) :void
		{
			// Set swf root for string eval
			StrVal.swfRoot = swfRoot;
			
			// Calculate scale for screen dpi on different devices
			CssUtils.initScreenDpi();
			CssStyleSheet.fontSizeScale = CssUtils.numericScale;
			
			// auto-scale font-size values in stylesheets to match screen dpi better
			CssStyleSheet.scaleFonts = useDPIScale;
		}
		
		// Requires a Application restart command
		public function set _config (cfg :String) :void {
			_configFile = cfg
		}
		public function get _config() :String {
			return _configFile 
		}
		
		public function setupApp () :void 
		{
			// ***** Clean up on restart *****
			
			if( resourceMgr ) {
				resourceMgr = null;
			}
			
			if( pluginContainer )
			{
				for( var name:String in plugins ) {
					var plg:Loader = Loader(plugins[name].parent);
					if( plg ) plg.unload();
					plg=null;
				}
				
				plugins = null;
				pluginContainer = null;
				pluginCount = 0;
			}
			
			if( shortcutMgr ) {
				if(rtContainer && rtContainer.contains(shortcutMgr)) rtContainer.removeChild(shortcutMgr);
				shortcutMgr = null;
			}
			if( mainMenu ) {
				if(rtContainer && rtContainer.contains(mainMenu)) rtContainer.removeChild(mainMenu);
				mainMenu = null;
			}
			if( secMenu ) {
				if(rtContainer && rtContainer.contains(secMenu)) rtContainer.removeChild(secMenu);
				secMenu = null;
			}
			if( view ) {
				if(appContent && appContent.contains(view)) appContent.removeChild(view);
				view = null;
			}
			if( appContent ) {
				if(rtContainer.contains(appContent)) rtContainer.removeChild(appContent);
				appContent = null;
			}
			if( windows ) {
				if(rtContainer.contains(windows)) rtContainer.removeChild(windows);
				windows = null;
			}
			if( topContent ) {
				if(rtContainer.contains(topContent)) rtContainer.removeChild(topContent);
				topContent = null;
			}
			if( rtContainer ) {
				if(contains(rtContainer)) removeChild(rtContainer);
				rtContainer = null;
			}
			tMenuConfLoaded = false;
			tViewConfLoaded = false;
			tAppInitialized = false;
			
			// ***** Start fresh *****
			resourceMgr = new ResourceMgr();
			
			dispatchEvent( new AppEvent(AppEvent.SETUP) );
			
			if( _configFile != "" ) {
				var r:Resource = new Resource();
				r.load( _configFile, true, confLoaded );
			}
		}
		
		protected function confLoaded (e:Event, res:Resource) :void
		{
			conf = new CssStyleSheet( String(res.obj) );
			
			rtContainer = new CssSprite(stage.stageWidth,stage.stageHeight,null,conf,"root-container");
			
			shortcutMgr = new ShortcutMgr();
			shortcutMgr.addEventListener(ShortcutEvent.SHORTCUT, shortcutHandler);
			
			appContent = new CssSprite(stage.stageWidth,stage.stageHeight,rtContainer,conf,"content-container");
			windows = new CssSprite(0,0,rtContainer,conf,"windows-container");
			topContent = new CssSprite(0,0,rtContainer,conf,"top-container",'','',true);
			
			window.windowContainer = windows;
			
			rtContainer.autoSwapState = appContent.autoSwapState = 
			windows.autoSwapState = topContent.autoSwapState = "";
			
			Popup.topContainer = topContent;
			
			addChild( rtContainer );
			rtContainer.addChild(shortcutMgr);
			
			// Use config styles until AppStart
			conf.media = "agfconf";
			
			cssStyleSheet = conf;
			
			var appConf:Object = conf.getStyle("conf#app");
			
			if(appConf.menu) {
				resourceMgr.loadResource( appConf.menu, menuLoaded );
				mainMenu = new Menu(0, 0, rtContainer, conf, "menu1", "mainmenu");
				mainMenu.autoSwapState = "";
				mainMenu.addEventListener( Event.SELECT, menuSelect );
				
				secMenu = new Menu(0,0,rtContainer, conf, "secmenu", "secmenu");
				secMenu.autoSwapState = "";
				secMenu.addEventListener( Event.SELECT, menuSelect );
			}
			
			if( appConf.language ) {
				resourceMgr.loadResource( appConf.language, langLoaded );
			}
			if(view == null) {
				view = new ViewContainer(550,385,appContent,conf);
				view.autoSwapState = "";
			}
				
			dispatchEvent( new AppEvent(AppEvent.CREATE) );
			
			pluginsLoaded = 0;
			
			if( appConf.loadPlugins )
			{
				if( CssUtils.stringToBool( appConf.loadPlugins ) ) 
				{
					if(plugins == null) plugins = {};
					if(pluginContainer == null) pluginContainer = new Sprite();
					
					var p:Array = conf.getStyleArray("conf#plugins");
					
					if(p.length>0) {
						for(var i:int=0; i<p.length; i++) {
							loadPlugin( p[i][0], p[i][1] );
						}
					}
				}
				else{
					startApp();
				}
			}
		}
		
		public function cmd ( text:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null) :void {
			Command.process( text, cmdComplete, cmdCompleteArgs );
		}
		public function strval ( str:String, forceSingleProp:Boolean=false ) :* {
			return forceSingleProp ? StrVal.strval( "{*"+str+"}" ) : StrVal.strval( str );
		}
		
		public function setSize (w:Number, h:Number) :void 
		{
			if(view)
			{
				rtContainer.cssWidth = topContent.cssWidth = appContent.cssWidth = view.cssWidth = cssWidth = w;
				rtContainer.cssHeight = topContent.cssHeight = appContent.cssHeight = view.cssHeight = cssHeight = h;
				
				
				topContent.setWidth( w );
				topContent.setHeight( h );
				
				
				appContent.setWidth( w );
				appContent.setHeight( h );
				
				view.setWidth( w );
				view.setHeight( h );
				
				
				view.y = mainMenu.getHeight();
				view.cssHeight -= mainMenu.getHeight();
				view.resize(w, h);
				
				if(mainMenu) {
					var sw:int = 0;
					if( secMenu ) {
						sw = secMenu.cssSizeX;
						secMenu.x = w - sw;
					}
					mainMenu.setWidth(w - sw);
					mainMenu.format();
					mainMenu.init();
				}
			}
			if(loadSprite) setLoadingSize(w,h);
		}
		
		public function showLoading (loadDisplay:Sprite = null) :void {
			
			if ( loadSprite && loadSpriteContent && loadSprite.contains(loadSpriteContent) ) loadSprite.removeChild(loadSpriteContent);
			if ( loadSprite && topContent.contains(loadSprite) ) topContent.removeChild(loadSprite);
			
			loadSprite = new CssSprite( 0,0, topContent, config, 'loader', '', 'app-loading', false);
			loadSprite.addEventListener(MouseEvent.CLICK, loadHandlerClick );
			
			if ( loadDisplay == null) {
				loadDisplay = new IconLoading(0x0, 1, 6, 48);
				loadDisplay.rotation = -90;
				loadDisplay.addEventListener( MouseEvent.CLICK, loadIconClickHandler);
			}
			loadSpriteContent = loadDisplay;
			loadSprite.addChild( loadSpriteContent );
			
			setLoadingSize( stage.stageWidth, stage.stageHeight);
		}
		
		private function loadIconClickHandler (e:MouseEvent) :void 
		{
				var msg:String = Language.getKeyword("There may be an error somewhere during the action, open the Console?");
				
				// Have to load a project or template...
				var win:Window = Window( window.GetBooleanWindow( "ExitLoadWindow", Language.getKeyword("Abort-Loading"), msg, {
				complete: function (bool:Boolean) { 
					if (bool) {
						hideLoading();
						Application.instance.cmd( "Console show console");
					}
				},
				continueLabel: Language.getKeyword("Abort-Loading-OK"),
				allowCancel: true,
				autoWidth:false,
				autoHeight:true,
				cancelLabel: Language.getKeyword("Abort-Loading-Cancel")
				}, 'load-abort-window') );
				this.topContent.addChild( win );
				
		}
		private function loadHandlerClick (e:MouseEvent) :void {
			//Console.log("Application Click Handler: Application is currently loading");
		}
		
		public function hideLoading (disableApp:Boolean = true) :void {
			if( loadSprite ) {
				if( topContent.contains(loadSprite)) topContent.removeChild(loadSprite);
				loadSprite = null;
			}
		}
		
		public function setLoadingSize (w:Number, h:Number) :void {
			loadSprite.setWidth( w - loadSprite.cssBoxX);
			loadSprite.setHeight( h - loadSprite.cssBoxY);
			if( loadSpriteContent ) {
				if( loadSprite.textAlign == "center" ) {
					loadSpriteContent.x = Math.round( w/2 - loadSpriteContent.width/2 );
				}else if( loadSprite.textAlign == "right") {
					loadSpriteContent.x = loadSprite.cssRight - loadSpriteContent.width;
				}else{
					loadSpriteContent.x = loadSprite.cssLeft;
				}
				if( loadSpriteContent.x < loadSprite.cssLeft ) loadSpriteContent.x = loadSprite.cssLeft;
				
				if( loadSprite.verticalAlign == "middle" ) {
					loadSpriteContent.y = Math.round( h/2 - loadSpriteContent.height/2 );
				}else if( loadSprite.verticalAlign == "bottom") {
					loadSpriteContent.y = loadSprite.cssBottom - loadSpriteContent.height;
				}else{
					loadSpriteContent.y = loadSprite.cssTop;
				}
				if( loadSpriteContent.y < loadSprite.cssTop ) loadSpriteContent.y = loadSprite.cssTop;
			}
		}
		
		private function shortcutHandler ( e:ShortcutEvent ) :void {
			if( e.command ) cmd( e.command.name );
		}
		
		private function menuSelect (e:MenuEvent) :void {
			cmd( e.uid );
		}
		
		protected var mouseIcon:Sprite=null;
		private function mouseCursorHandler (e:MouseEvent) :void {
			if(mouseIcon != null) {
				if(e!= null){
					mouseIcon.x = e.stageX;
					mouseIcon.y = e.stageY;
				}else{
					mouseIcon.x = topContent.mouseX;
					mouseIcon.y = topContent.mouseY;
				}
				if(topContent.contains(mouseIcon)) {
					if(topContent.getChildIndex(mouseIcon) != topContent.numChildren-1) {
						topContent.setChildIndex(mouseIcon, topContent.numChildren-1);
					}
				}
				Mouse.hide();
			}else{
				Mouse.show()
			}
		}
		
		public function get mouseCursor () :Sprite
		{
			return mouseIcon;
		}
		
		public function showCursor (icon:Sprite) :void
		{
			if(icon == null) {
				Mouse.show();
				if(mouseIcon != null && topContent.contains(mouseIcon)) topContent.removeChild( mouseIcon );
				mouseIcon = null;
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseCursorHandler);
			}else{
				
				if(mouseIcon != null && topContent.contains(mouseIcon)) topContent.removeChild( mouseIcon );
				
				mouseIcon = icon;
				mouseIcon.mouseEnabled = false;
				topContent.addChild( mouseIcon );
				stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseCursorHandler);
				mouseCursorHandler(null);
			}
		}
		
		private function chFirstInit () :void 
		{
			if(tAppInitialized == false){
				if(tMenuConfLoaded && tViewConfLoaded && tLangConfLoaded)
				{
					var appConf:Object = conf.getStyle("conf#app");
					var res:Resource;
					if(appConf.language) {
						res = resourceMgr.getResource( appConf.language );
						var xo:XML = new XML( String(res.obj) );
						if( xo ) {
							Language.addXmlKeywords( xo.item );
						}
					}
					if(appConf.menu) {
						res = resourceMgr.getResource( appConf.menu );
						try {
							var xm:XML = new XML(String(res.obj));
							
							mainMenu.parseMenu(  xm , "mainmenu");
						}catch(e:Error) {
							Console.log("XML PARSE ERROR IN MENU.XML: " + e);
						}
					}
					if(appConf.view) {
						res = resourceMgr.getResource( appConf.view );
						view.parseXml(res);
					}
					// After Config files and plugins are loaded and Application displayed
					dispatchEvent( new AppEvent(AppEvent.START) );
					tAppInitialized = true;
					mainMenu.init();
					secMenu.init();
					secMenu.iconColor = mainMenu.iconColor;
					
					rtContainer.setChildIndex( topContent, rtContainer.numChildren-1 );
					rtContainer.setChildIndex( windows, rtContainer.numChildren-2 );
					rtContainer.setChildIndex( mainMenu, rtContainer.numChildren-3 );
					
					conf.media = "all"; // Use only root styles
					
					setSize( cssWidth, cssHeight );
				}
			}	
		}
		
		private function viewLoaded (res:Resource) :void {
			tViewConfLoaded=true;
			chFirstInit();
		}
		private function langLoaded (res:Resource) :void {
			tLangConfLoaded=true;
			chFirstInit();
		}
		private function menuLoaded (res:Resource) :void {
			tMenuConfLoaded=true;
			chFirstInit();
		}
		
		protected function startApp () :void {
			styleSheet = conf;
			
			setSize(cssWidth, cssHeight);
			var name:String;
			var e:Error;
			
			// init plugins
			for(name in plugins)
			{
				try 
				{
					plugins[name]["pluginLoaded"](this);
				}
				catch(e:Error)
				{
					Console.log("Plugin error " + e.name + ": " + e.message);
				}
			}
			
			// init shortcuts
			var sc:Object = conf.getStyle("shortcut#app");
			for(name in sc) {
				shortcutMgr.addShortcut( sc[name], name, "app");
			}
			
			var appConf:Object = conf.getStyle("conf#app");
			
			// load view menu
			if(appConf.view) 
			{
				resourceMgr.loadResource( appConf.view, viewLoaded );
			}
		}
		
		private function pluginLoaded (e:Event) :void {
			pluginsLoaded++;
			var ldr:Loader = LoaderInfo(e.target).loader;
			plugins[ldr.name] = ldr.content as MovieClip;
			if(pluginsLoaded == pluginCount) {
				startApp();
			}
		}
		
		private function pluginError (e:IOErrorEvent) :void {
			pluginsLoaded++;
			if(pluginsLoaded == pluginCount) {
				startApp();
			}
		}
		
		public function loadPlugin (name:String, file:String) :void
		{
			var ldr:Loader = new Loader();
			var ldrContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain );
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, pluginLoaded);
			ldr.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, pluginError);
			
			try 
			{
				ldr.load( new URLRequest(file), ldrContext );
				pluginCount++;
				ldr.name = name;
				pluginContainer.addChild( ldr );
			}
			catch( e:Error ) 
			{
				Console.log( "Plugin not found: " + file );
			}
		}
				
		public function addToolPath (path:String) :void {
			if(toolPaths.indexOf(path) == -1) toolPaths.push( path );
		}
	}
}
