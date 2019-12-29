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
	
	/**
	* StartScreen provides three options to intall a website/template
	*
	* - Open existing Project
	* - Connect to Website (Install website)
	* - New with Template Folder/ZipFile
	*/
	
	public class Settings extends Sprite 
	{
		public function Settings () 
		{
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			
			create();
		}
		private function create () :void
		{
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			cont = new CssSprite( w, h, null, container.styleSheet, 'body', '', '', true);
			addChild(cont);
			cont.init();
			
			body = new CssSprite(w, h, cont, container.styleSheet, 'div', '', 'editor settings', false);
			body.setWidth( w - body.cssBoxX );
			body.setHeight( h - body.cssBoxY );
			
			scrollpane = new ScrollContainer(0, 0, body, body.styleSheet, '', '', false);
			
			if( CTOptions.animateBackground ) {
				HtmlEditor.dayColorClip( body.bgSprite );
			}
			
			title = new Label(0, 0, scrollpane.content, container.styleSheet, '', 'settings-title', false);
			title.label = Language.getKeyword( "Application Settings" );
			title.textField.autoSize = TextFieldAutoSize.LEFT;
			
		}
		
		public var cont:CssSprite;
		public var body:CssSprite;
		public var title:Label;
		public var container: Panel;
		public var scrollpane:ScrollContainer;
		
		private function newSize (e:Event) :void
		{
			var w:int = container.getWidth();
			var h:int = container.getHeight();
		
			body.setWidth(w);
			body.setHeight(h);
			
			var cy:int = 0;
			
			if ( title ) {
				title.x = Math.floor( (w - title.getWidth() ) * .5);
				title.y = body.cssTop;
				cy = title.y + title.height + title.cssMarginBottom;
			}
			
		}
	}
}
