package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	import flash.utils.setTimeout;
	
	import agf.icons.IconArrowDown;
	import agf.events.PopupEvent;
	import agf.html.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public dynamic class Toggle extends CssSprite
	{
		public function Toggle ( w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false)
		{
			super(w, h, parentCS, css, "toggle", cssId, cssClasses, true);
			autoSwapState = "";
			create();
			addEventListener( MouseEvent.MOUSE_DOWN, toggleHandler);
		}
		
		public var toggleBtn:CssSprite;
		public var activeDiv:CssSprite;
		
		public function create () :void {
			if( !toggleBtn ) {
				toggleBtn = new CssSprite(0,0, this, this.styleSheet, "togglebutton", '', this.nodeClass, false);
				toggleBtn.autoSwapState = "";
			}
			
			setChildIndex( toggleBtn, numChildren - 1 );
			
			init();
			
			toggleBtn.x = cssLeft;
			toggleBtn.y = cssTop;
		}
		
		private var _value:Boolean = false;
		
		public function set value ( v:Boolean ) :void {
			_value = v;
			
			if( _value ) {
				toggleBtn.swapState("active");
				swapState("active");
				toggleBtn.x = cssRight - toggleBtn.width;
			}else{
				toggleBtn.swapState( "normal" );
				swapState( "normal" );
				toggleBtn.x = cssLeft;
			}
			
		}
		
		public function get value () :Boolean {
			return _value;
		}
		
		public function toggleHandler (e:Event) :void
		{
			trace("TOGGLE: " + value);
			value = !_value;
			
			dispatchEvent( new Event( Event.CHANGE ) );
		}
		
	}
}