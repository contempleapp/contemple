package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	import flash.utils.setTimeout;
	
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.icons.IconAppLogo;
	import agf.tools.Application;
	import agf.html.CssUtils;
	import flash.geom.Rectangle;
	import agf.tools.Console;
	
	public class ScrollContainer extends CssSprite
	{
		public function ScrollContainer ( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style, "scrollcontainer", cssId, cssClasses, noInit);
			create();
		}
		
		public var content:CssSprite;
		private var scrollbar:Slider;
		public static var scrollbarWidth:Number=12;
		public var friction:Number = 2.7;
		public var accel:Number = 2;
		private var speed:Number = 0;
		
		public function get slider () :Slider { return scrollbar; }
		
		public function create () :void
		{
			if(content && contains(content)) removeChild(content);
			content = new CssSprite(0,0,this,styleSheet,"scrollcontent",'',nodeClass, false);
			
			if(scrollbar && contains(scrollbar)) removeChild(scrollbar);
			var sld:Slider = new Slider( scrollbarWidth, cssSizeY, this, styleSheet, '', nodeClass, false);
			sld.setScrollerHeight( 50 * CssUtils.numericScale );
			sld.setWidth( scrollbarWidth * CssUtils.numericScale );
			sld.setHeight( cssSizeY );
			sld.wheelScrollTarget = this;
			sld.addEventListener( Event.CHANGE, scrollbarChange);
			//sld.addEventListener( "begin", scrollbarStart );
			//sld.addEventListener( MouseEvent.MOUSE_UP, scrollbarEnd);
			scrollbar = sld;
		}
		
		public function applyScrollValue ( val:Number ) :void {
			removeEventListener(Event.ENTER_FRAME, animPos);
			scrollbar.value = val;
			content.y = toY = int( -scrollbar.value );
		}
		
		public function setScrollerWidth (w:int) :void {
			if(scrollbar){
				scrollbarWidth = w;
				scrollbar.setWidth( w - scrollbar.cssBoxX );
				scrollbar.x = cssSizeX - scrollbar.getWidth();
			}
		}
		
		public override function setWidth (w:int) :void {
			super.setWidth( w - cssBoxX );
			
			var sld:Slider = scrollbar;
			sld.x = cssSizeX - sld.getWidth();
			if(sld.x < 0) sld.x = 0;
			
			scrollRect = new Rectangle( cssLeft, cssTop, getWidth(), getHeight() );
		}
		
		public override function setHeight (h:int) :void {
			var pc:Number = scrollbar.value;
			super.setHeight(h - cssBoxY);
			
			if(scrollbar) {
				scrollbar.setHeight( getHeight() - scrollbar.cssBoxY);
				scrollbar.value = pc;
			}
			scrollRect = new Rectangle( cssLeft, cssTop, getWidth(), getHeight() );
		}
		
		private var toY:int;
		private function animPos (e:Event) :void {
			if( Math.abs(toY-content.y) > 0 ) {
				content.y = int( content.y + (toY-content.y)/friction );
			}else{
				content.y = toY;
				removeEventListener( Event.ENTER_FRAME, animPos);
			}
		}
		
		public function scrollbarChange (e:Event=null) :void {
			if( friction <= 1 ) {
				content.y = int(-scrollbar.value);
			}else{
				toY = -scrollbar.value;
				addEventListener(Event.ENTER_FRAME, animPos);
			}
		}
		
		public function contentHeightChange () :void {
			var ch:Number = content.getHeight();
			var overflow:Number = ch - cssSizeY;
			if( overflow > 0 ) {
				scrollbar.maxValue = int(overflow);
				var h:Number = scrollbar.getHeight();
				scrollbar.wheelStepSize = int( (h*.3) /  Math.round( ch / h ) );
				scrollbar.visible = true;
			}else{
				scrollbar.maxValue = 0.0001;
				scrollbar.visible = false;
			}
			var tmp:Number = friction;
			applyScrollValue( slider.value );
		}
	}
}