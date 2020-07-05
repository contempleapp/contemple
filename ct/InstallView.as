package ct
{	
	import agf.tools.Application;
	import agf.Main;
	import agf.ui.Panel;
	import agf.tools.Console;
	import flash.html.*;
	import flash.display.*;
	import flash.text.*;
	import flash.net.URLRequest;
	import flash.filesystem.File;
	import flash.events.*;
	import flash.utils.setTimeout;
	import agf.ui.*;
	import agf.html.CssStyleSheet;
	import agf.html.CssSprite;
	
	public class InstallView extends Sprite
	{
		public function InstallView ( label:String="") { //Installing Website Template") {
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			init(label);
			displayFiles();
		}
		
		public var container: Panel;
		private var styleSheet:CssStyleSheet;
		
		private var cont:CssSprite;
		private var body:CssSprite;
		
		public var progress:Progress;		
		private var abortBtn:Button;
		public var title:Label;
		private var infoText:TextField;
		
		public function setLabel ( s:String ):Boolean
		{
			if( title ) 
			{
				title.label = s;
				
				if( container && body ) {
					var w:int = container.getWidth() - body.cssBoxX;
					title.x = (w - title.getWidth())/2 /*+ body.cssLeft*/;
					if( title.x < body.cssLeft ) title.x = body.cssLeft;
				}
				return true;
			}
			return false;
		}
		public function getLabel () :String {
			if( title ) return title.label;
			return "";
		}
		public function getProgress (  ) :Number {
			return progress ? progress.value : 0;
		}
		public function showProgress ( v ) :void {
			if( progress ) {
				progress.value = v;
			}
		}
		
		public function init (label:String): void
		{
			if( styleSheet == null ) styleSheet = Main(Application.instance).config;
			
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			if(cont != null)  {
				if( body != null) {
					if( body.contains( title ) ) body.removeChild( title);
					if( body.contains( progress ) ) body.removeChild( progress);
					if( body.contains( abortBtn ) ) body.removeChild( abortBtn);
					if( body.contains( infoText ) ) body.removeChild( infoText);
					if( cont.contains( body ) ) cont.removeChild( body);
				}
				if(contains(cont)) removeChild(cont);
				body = null;
				cont = null;
			}
			
			cont = new CssSprite( w, h, null, styleSheet, 'body', '', '', true);
			addChild(cont);
			cont.init();
			
			body = new CssSprite(w, h, cont, styleSheet, 'div', '', 'editor install-view', false);
			
			title = new Label(0, 0, body, styleSheet, '', 'install-title', false);
			title.label = Language.getKeyword( label );
			
			progress = new Progress( int(w*.5), 0, body, styleSheet, '', 'install-progress', false);
			progress.value = 0;
			
			//abortBtn = new Button( [Language.getKeyword("Cancel Installing")], 0, 0, body, styleSheet, '', 'install-abort', false);
			//abortBtn.addEventListener(MouseEvent.CLICK, abortHandler);
			
			infoText =  new TextField();
			infoText.width = w - body.cssBoxX;
			infoText.height = h - 100;
			infoText.border = false;
			infoText.defaultTextFormat = styleSheet.getTextFormat( ["*","body",".install-view","progress",".install-text"] );
			
			body.addChild( infoText );
			newSize(null);
		}
		
		public function log (v:String, append:Boolean = false): void {
			infoText.text = append ? infoText.text + v : v;
		}
		
		public function abortHandler(e: Event): void {
			
		}
		
		public function newSize(e: Event): void
		{
			var w:int = container.getWidth() - body.cssBoxX;
			var h:int = container.getHeight() - body.cssBoxY;
			var w2:int = int(w*.5);
			var h2:int = int(h*.5);
			
			body.setWidth( w );
			
			if( progress ) {
				progress.setWidth( w2 );
				progress.x = int((w - w2)*.5);
				progress.y = h2;
			}
			
			if( title ) {
				title.x = (w - title.getWidth())/2 + body.cssLeft
				if( title.x < body.cssLeft ) title.x = body.cssLeft;
				title.y = int((h2 - body.cssTop)*.5) - 4;
			}
			
			/*if( abortBtn ) {
				abortBtn.x = progress ? (progress.x + w2)-abortBtn.getWidth() : w - abortBtn.getWidth();
				if( abortBtn.x < body.cssLeft ) abortBtn.x = body.cssLeft;
				abortBtn.y = progress ? progress.y + progress.cssSizeY + abortBtn.cssMarginTop : h2;
			}*/
		
			if( infoText ) {
				infoText.x = body.cssLeft;
				infoText.width = container.getWidth() - body.cssBoxX;
				infoText.height = h - (h2 + (progress ? progress.cssSizeY : 0) + ( abortBtn ? abortBtn.cssSizeY : 0) );
				infoText.y = h2 + h2*0.5 - 4;
			}
		}
		
		// requird method for CTTools
		public function displayFiles(): void {}
		
	}
}
