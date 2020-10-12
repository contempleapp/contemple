package ct
{
	import agf.events.AppEvent;
	import agf.ui.*;
	import agf.html.*;
	import agf.tools.*;
	import agf.Main;
	import agf.Options;
	import flash.display.*;
	import flash.events.*;
	
	public class BaseScreen extends Sprite 
	{
		public function BaseScreen () 
		{
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			create();
		}
		
		protected function removePanel (e:Event) :void {
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
				stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
			}
			
			Main(Application.instance).view.removeEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		protected function btnUp (event:MouseEvent) :void {
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
			
		}
		protected function btnMove (event:MouseEvent) :void {
			var dy:Number = mouseY - clickY;
			
			if( ! clickScrolling ) {
				if( Math.abs(dy) > CTOptions.mobileWheelMove ) {
					clickScrolling = true;
				}
			}else{
				// scroll
				scrollpane.slider.value -= dy;
				scrollpane.scrollbarChange(null);
				clickY = mouseY;
			}
		}
		
		protected function btnDown (event:MouseEvent) :void {
			stage.addEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, btnUp );
			clickScrolling = false;
			clickY = mouseY;
		}
		
		public static function get clickScrolling () : Boolean {
			return _clickScrolling || AreaView.clickScrolling;
		}
		
		public static function set clickScrolling (v:Boolean) :void {
			_clickScrolling = v;
			AreaView.clickScrolling = v; 
		}
		
		protected static var _clickScrolling:Boolean = false;
		protected var clickY:Number=0; 
		public function abortClickScrolling () :void {
			btnUp(null);
			clickScrolling=false;
		}
		
		protected function create () :void
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
			
			scrollpane = new ScrollContainer(0, 0, body, body.styleSheet, '', '', false);
			scrollpane.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
			
			
			if( CTOptions.animateBackground ) {
				HtmlEditor.dayColorClip( body.bgSprite );
			}
		}
		
		protected var container: Panel;
		protected var scrollpane:ScrollContainer;
		protected var cont:CssSprite;
		protected var body:CssSprite;
		
		protected function newSize (e:Event=null) :void
		{
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			if( cont ) {
				cont.setWidth( w );
				cont.setHeight( h );
			}
			if( body ) {
				body.setWidth(w);
				body.setHeight(h);
			}
			if( scrollpane ) {
				scrollpane.x = body.cssLeft;
				scrollpane.y = body.cssTop;
				scrollpane.setWidth( w - body.cssBoxX );
				scrollpane.setHeight( h - body.cssBoxY );
				scrollpane.contentHeightChange();
			}
		}
	}
}
