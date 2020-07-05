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
	* - Open project from disk
	* - Open previous project
	*/
	public class OpenScreen extends Sprite 
	{
		public function OpenScreen () 
		{
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			create();
		}
		
		private function create () :void
		{
			var i:int;
			var pi:PopupItem;
			
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			cont = new CssSprite( w, h, null, container.styleSheet, 'body', '', '', true);
			addChild(cont);
			cont.init();
			
			body = new CssSprite(w, h, cont, container.styleSheet, 'div', '', 'editor start-screen', false);
			body.setWidth( w - body.cssBoxX );
			body.setHeight( h - body.cssBoxY );
			
			if( CTOptions.animateBackground ) {
				HtmlEditor.dayColorClip( body.bgSprite );
			}
			
			title = new Label(0, 0, body, container.styleSheet, '', 'start-screen-title', false);
			title.label = Language.getKeyword( "Open previous Project" );
			title.textField.autoSize = TextFieldAutoSize.LEFT;
			
			openBtn = new Button( [ new IconFromFile( Options.iconDir + "/open.png",Options.iconSize,Options.iconSize), Language.getKeyword("Open existing Project Folder") ], 0, 0, body, container.styleSheet, '','start-screen-btn', false);
			openBtn.addEventListener( MouseEvent.CLICK, openBtnHandler);
			
			openText = new Label( 0, 0, body, container.styleSheet, '', 'start-screen-info', false);
			openText.textField.multiline = true;
			openText.textField.wordWrap = true;
			openText.textField.autoSize = TextFieldAutoSize.LEFT;
			openText.label = Language.getKeyword("Open Recent Project");
			
			recentProjects = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize*.5 ), Language.getKeyword("Select Recent Project") ], 0, 0, body, container.styleSheet, '','start-screen-popup', false);
			recentProjects.addEventListener( PopupEvent.SELECT, selectRecentProject );
			
			var ish:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
				
			// override options from install.xml file
			
			if( ish && ish.data && ish.data.recentProjects && ish.data.recentProjects.length > 0 )
			{
				var fd_name:String;
				var fid:int;
				var file:File;
				
				for( i=ish.data.recentProjects.length-1; i >= 0; i--)
				{
					if( ish.data.recentProjects[i] ) {
						file = new File( ish.data.recentProjects[i] );
						
						if( file && file.exists && file.isDirectory) 
						{
							fid = ish.data.recentProjects[i].lastIndexOf( CTOptions.urlSeparator );
							if( fid >= 0 ) {
								fd_name = ish.data.recentProjects[i].substring( fid+1 );
							}else{
								fd_name = ish.data.recentProjects[i];
							}
							pi = recentProjects.rootNode.addItem( [fd_name], recentProjects.styleSheet );
							pi.options.folder = ish.data.recentProjects[i];
						}else{
							ish.data.recentProjects.splice(i,1);
						}
					}
				}
			}
		}
		
		public var title:Label;
		public var container: Panel;
		public var openText:Label;
		private var scrollContainer:ScrollContainer;
		private var openBtn:Button;
		private var recentProjects:Popup;
		private var cont:CssSprite;
		private var body:CssSprite;
		
		private function openBtnHandler (e:Event) :void {
			Main(Application.instance).cmd("CTTools openproject");
		}
		
		private function selectRecentProject (e:PopupEvent) :void
		{
			var curr:PopupItem = e.selectedItem;
			Main(Application.instance).cmd( "CTTools open " + curr.options.folder );
		}
		
		private function newSize (e:Event) :void
		{
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			var w3:int = Math.floor((w - (body.cssBoxX + container.cssBoxX)) / 3);
			
			var cx:int = body.cssLeft;
			var cy:int = 0;
			
			body.setWidth(w);
			body.setHeight(h);
			
			if ( title ) {
				title.x = Math.floor( (w - title.getWidth() ) * .5);
				title.y = body.cssTop;
				
				cy = title.y + title.height + title.cssMarginBottom;
			}
			
			if ( openBtn ) {
				openBtn.x = cx + openBtn.cssMarginLeft;
				openBtn.y = cy + openBtn.cssMarginTop;
				cy += openBtn.cssSizeY + openBtn.cssMarginBottom;
			}
			
			if ( openText ) {
				openText.x = cx;
				openText.y = cy;
				openText.textField.width = w - body.cssBoxX;
				openText.init();
				cy += openText.height + 4;
			}
			if( recentProjects ) {
				recentProjects.x = cx + recentProjects.cssMarginLeft;
				recentProjects.y = cy + recentProjects.cssMarginTop;
				cy += recentProjects.cssSizeY + recentProjects.cssMarginBottom;
			}
		}
	}
}
