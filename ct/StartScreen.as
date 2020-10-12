package ct
{
	import agf.events.PopupEvent;
	import agf.utils.FileUtils;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import flash.filesystem.*;
	import agf.Main;
	import agf.Options;
	import agf.ui.*;
	import agf.html.*;
	import agf.tools.*;
	import agf.icons.IconFromFile;
	import agf.icons.IconArrowDown;
	
	/**
	* StartScreen provides options to install a website/template
	*
	* - Connect to Website (Install website)
	* - New with Template Folder / ZipFile
	* - Select previously installed Template
	*/
	public class StartScreen extends BaseScreen
	{
		public function StartScreen () {}
		
		protected override function create () :void
		{
			super.create();
			
			var i:int;
			var pi:PopupItem;
			
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			title = new Label(0, 0, scrollpane.content, container.styleSheet, '', 'start-screen-title', false);
			title.label = Language.getKeyword( "Install a Website or Template" );
			title.textField.autoSize = TextFieldAutoSize.LEFT;
		
			installBtn = new Button( [ new IconFromFile( Options.iconDir + "/earth.png",Options.iconSize,Options.iconSize), Language.getKeyword("Connect to website") ], 0, 0, scrollpane.content, container.styleSheet, '','start-screen-btn', false);
			installBtn.addEventListener( MouseEvent.CLICK, installBtnHandler);
			
			if( !CTOptions.isMobile ) {
				installText = new Label( 0, 0, scrollpane.content, container.styleSheet, '', 'start-screen-info', false);
				installText.textField.multiline = true;
				installText.textField.wordWrap = true;
				installText.textField.autoSize = TextFieldAutoSize.LEFT;
				installText.label = Language.getKeyword("Connect to a Website with Contemple Hub enabled");
				
				newBtn = new Button( [ new IconFromFile( Options.iconDir + "/folder.png",Options.iconSize,Options.iconSize), Language.getKeyword("Install a new Template Folder") ], 0, 0, scrollpane.content, container.styleSheet, '','start-screen-btn', false);
				newBtn.addEventListener( MouseEvent.CLICK, newBtnHandler);
				
				newZipBtn = new Button( [ new IconFromFile( Options.iconDir + "/file-code.png",Options.iconSize,Options.iconSize), Language.getKeyword("Install a new Template Zip") ], 0, 0, scrollpane.content, container.styleSheet, '','start-screen-btn', false);
				newZipBtn.addEventListener( MouseEvent.CLICK, newZipBtnHandler);
			}
			
			installedTemplates = new Popup( [new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize )
			, Language.getKeyword("Select Installed Template") ], 0, 0, scrollpane.content, container.styleSheet, '','start-screen-popup', false);
			installedTemplates.alignH = "parent";
			installedTemplates.addEventListener( PopupEvent.SELECT, selectInstallTemplate);
			
			if ( CTTools.activeTemplate ) {
				pi = installedTemplates.rootNode.addItem([CTTools.activeTemplate.name + "(current)"], container.styleSheet );
				pi.options.instid = -1;
			}
			
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			var tmpls:Object = {};
			
			if( sh && sh.data && sh.data.installTemplates )
			{
				for ( i = 0; i < sh.data.installTemplates.length; i++)
				{
					if( sh.data.installTemplates[i] && sh.data.installTemplates[i].name && sh.data.installTemplates[i].version )
					{
						if( typeof(tmpls[sh.data.installTemplates[i].name + "-" +sh.data.installTemplates[i].version]) != "undefined" ) continue;
						tmpls[sh.data.installTemplates[i].name + "-" +sh.data.installTemplates[i].version] = true;
						
						pi = installedTemplates.rootNode.addItem([sh.data.installTemplates[i].name + " ("+sh.data.installTemplates[i].version+")"], container.styleSheet );
						pi.options.instid = i;
					}
				}
			}
			
			if( installedTemplates && installedTemplates.rootNode && installedTemplates.rootNode.children && installedTemplates.rootNode.children.length > 0 ) {
				newText = new Button( [  Language.getKeyword("Select a Folder or a ZIP file with a Template") ], 0, 0, scrollpane.content, container.styleSheet, '','start-screen-new-template', false);
				newText.addEventListener( MouseEvent.CLICK, newTextHandler);
				
				currTmplText = new Label( 0, 0, scrollpane.content, container.styleSheet, '', 'start-screen-info', false);
				currTmplText.textField.multiline = true;
				currTmplText.textField.wordWrap = true;
				currTmplText.textField.autoSize = TextFieldAutoSize.LEFT;
				currTmplText.label = Language.getKeyword("Selected a previously used Template:");
			}
			
			if(newBtn) newBtn.visible = false;
			if(newZipBtn) newZipBtn.visible = false;
			if(installedTemplates) installedTemplates.visible = false;
			if(currTmplText) currTmplText.visible = false;
		}
		
		public var title:Label;
		public var installText:Label;
		public var currTmplText:Label;
		public var newText:Button; // toggle button:
		
		private var installBtn:Button;
		private var newBtn:Button;
		private var newZipBtn:Button;
		private var installedTemplates:Popup;
		
		private var showNewTmpl:Boolean = false;
		
		private function installBtnHandler (e:Event) :void {
			Main(Application.instance).cmd("CTTools client-host-info");
		}
		
		private function newBtnHandler (e:Event) :void
		{
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			
			var directory:File;
			if ( sh && sh.data && sh.data.startScreenTemplateFolder ) {
				 directory = new File(sh.data.startScreenTemplateFolder);
			}
			else directory = File.documentsDirectory;
			
			try {
				directory.browseForDirectory("Select a Template Folder");
				directory.addEventListener(Event.SELECT, tmplFolderSelected);
			}catch (error:Error){
				Console.log("ERROR OPEN PRJ:" + error.message);
			}
		}
		
		private static function tmplFolderSelected (event:Event) :void 
		{
			var directory:File = event.target as File;
			
			if ( directory && directory.exists && directory.isDirectory ) 
			{
				var cfg:File = directory.resolvePath( CTOptions.templateIndexFile );
				
				if ( !cfg.exists ) {
					Console.log("Folder is no template folder");
					return;
				}
				var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
				
				if ( sh && sh.data ) {
					sh.data.startScreenTemplateFolder = directory.url;
					sh.flush();
				}
				
				if ( CTOptions.debugOutput || CTOptions.verboseMode ) Console.log( "Selected Template Folder: " + directory.url);
				
				CTOptions.uploadScript = "";
				CTMain.overrideInstallOptions(null, true);
				Main(Application.instance).cmd( "CTTools template " + directory.url);
			}
		}
		
		private function newZipBtnHandler (e:Event) :void {
			Main(Application.instance).cmd("TemplateTools install-template");
		}
		
		private function newTextHandler (e:Event) :void {
			showNewTmpl = !showNewTmpl;
			if(newBtn) newBtn.visible = showNewTmpl;
			if(newZipBtn) newZipBtn.visible = showNewTmpl;
			if(installedTemplates) installedTemplates.visible = showNewTmpl;
			if(currTmplText) currTmplText.visible = showNewTmpl;
		}
		
		private function selectInstallTemplate (e:PopupEvent) :void
		{
			var curr:PopupItem = e.selectedItem;
			
			if ( curr.options.instid == -1 ) 
			{
				CTOptions.uploadScript = "";
				CTMain.overrideInstallOptions(null, true);
				Main(Application.instance).cmd( "CTTools template current");
			}
			else
			{
				var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
				
				if ( sh && sh.data && sh.data.installTemplates && sh.data.installTemplates.length > curr.options.instid )
				{
					if( CTOptions.debugOutput || CTOptions.verboseMode ) Console.log( "Install Template ID: " + curr.options.instid );
					if ( sh.data.installTemplates[curr.options.instid].src  )
					{
						CTOptions.uploadScript = "";
						CTMain.overrideInstallOptions(null, true);
						Main(Application.instance).cmd( "TemplateTools install-template " + sh.data.installTemplates[curr.options.instid].src );
					}
				}
			}
		}
		
		protected override function newSize (e:Event=null) :void
		{
			super.newSize(e);
			
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			var w3:int = Math.floor((w - (body.cssBoxX + container.cssBoxX)) / 3);
			
			var cx:int = 0;
			var cy:int = 0;
			
			if ( title ) {
				title.x = Math.floor( (w - (title.getWidth()+body.cssBoxX) ) * .5);
				title.y = 0;
				cy = title.height + title.cssMarginBottom;
			}
			if ( installText ) {
				installText.x = cx;
				installText.y = cy;
				installText.textField.width = w - body.cssBoxX;
				installText.init();
				cy += installText.height + 4;
			}
			if ( installBtn ) {
				installBtn.x = cx;
				installBtn.y = cy + installBtn.cssMarginTop;
				cy += installBtn.cssSizeY + installBtn.cssMarginBottom;
			}
			if ( newText ) {
				newText.x = cx;
				newText.y = cy + newText.cssMarginTop;
				cy += newText.cssSizeY + newText.cssMarginY;
			}
			
			if ( newBtn ) {
				newBtn.x = cx;
				newBtn.y = cy + newBtn.cssMarginTop;
			}
			if ( newZipBtn && newBtn ) {
				newZipBtn.x = cx + newBtn.cssSizeX + newBtn.cssMarginRight;
				newZipBtn.y =  newBtn.y;
				cy += newZipBtn.cssSizeY + newZipBtn.cssMarginY;
			}
			if ( currTmplText ) {
				currTmplText.x = cx;
				currTmplText.y = cy;
				currTmplText.textField.width = w - body.cssBoxX;
				currTmplText.init();
				cy += currTmplText.height + 4;
			}
			if ( installedTemplates && newText ) {
				installedTemplates.x = cx;
				installedTemplates.y = cy + installedTemplates.cssMarginTop;
				cy += installedTemplates.cssSizeY + newText.cssMarginY;
			}
		}
	}
}
