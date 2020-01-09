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
	
	public dynamic class Toggle extends Button
	{
		public function Toggle ( lb:Array, w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(lb, w, h, parentCS, css, cssId, cssClasses, noInit);
			autoSwapState = "";
			addEventListener( MouseEvent.MOUSE_DOWN, toggleHandler );
		}
		
		private var _value:Boolean = false;
		public function set value ( v:Boolean ) :void {
			_value = v;
			if( _value == true ) {
				swapState("active");
			}else{
				swapState( "normal" );
			}
		}
		public function get value () :Boolean {
			return _value;
		}
		public function toggleHandler (e:Event) :void {
			value = !_value;
			dispatchEvent( new Event( Event.CHANGE ) );
		}
	}
}