package agf.ui
{	
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

	import agf.html.*;
	import agf.ui.ctrl.UiCtrl;
	
	dynamic public class Slider extends CssSprite {
		
		public function Slider ( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style, "slider", cssId, cssClasses, false);
			create();
		}
		
		public var scroller:CssSprite;
		public var minValue:Number = 0;
		public var maxValue:Number = 100;
		public var wheelStepSize:Number = 16; // in px
		public var wheelFrameTime:int = 30; // in ms
		private var ltWheelTime:int=0;
		private var start_pos:Number = 0;
		private var _wheelScrolling:Boolean = true;
		private var _wheelScrollTarget:Sprite;
		
		public function isVertical () :Boolean {
			return rotation == 0 || rotation == 180;
		}
		
		public function create () :void {
			if(scroller && contains(scroller)) removeChild(scroller);
			scroller = new CssSprite(0, 0,this, styleSheet, 'sliderbutton','', this.nodeClass + '-button', false);
			scroller.x = cssLeft;
			scroller.y = cssTop;
			scroller.addEventListener( MouseEvent.MOUSE_DOWN, onDown );
		}

		public function get percent () :Number {
			var size:Number = getHeight() - scroller.getHeight();
			return (scroller.y-cssTop)/size;
		}

		public function set percent (v:Number) :void {
			if(v < 0) v = 0;
			else if (v > 1) v = 1;
			var size:Number = Number(getHeight() - scroller.getHeight());
			scroller.y = cssTop + size * v;
		}

		public function get value () :Number {
			return minValue + (maxValue-minValue) * percent;
		}
		
		public function set value ( v:Number ) :void {
			var p:Number;
			var hp:Number;
			var percentValue:Number;
			var size:Number = getHeight() - scroller.getHeight();
			
			if( maxValue > minValue) {
				if(v < minValue) v = minValue;
				else if (v > maxValue) v = maxValue;
				p = v-minValue;
				hp = maxValue-minValue;
				percentValue = p/hp;
				
			}else{
				if(v < maxValue) v = maxValue;
				else if (v > minValue) v = minValue;
				p = v-maxValue;
				hp = minValue-maxValue;
				percentValue = 1-(p/hp);
			}
			percent = percentValue;
		}

		public override function setWidth (w:int) :void {
			super.setWidth( w - cssBoxX );
			scroller.setWidth( w - scroller.cssBoxX - cssBoxX );
		}

		public override function setHeight (h:int) :void {
			var pc:Number = percent;
			super.setHeight( h - cssBoxY );
			percent = pc;
		}
		private function onUp ( e:MouseEvent ) :void {
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, onUp );
			e.stopImmediatePropagation();
			e.stopPropagation();
			dispatchEvent(e);
		}

		private function onMove ( e:MouseEvent ) :void {
			var ypos:Number = this.mouseY;
			var dy:Number = ypos - start_pos;
			scroller.y += dy;
			if( scroller.y  < this.cssTop ) scroller.y = this.cssTop; // min
			else if( scroller.y + scroller.getHeight() > this.cssBottom ) scroller.y = this.cssBottom - scroller.getHeight(); // max
			start_pos = ypos;
			
			dispatchEvent( new Event( Event.CHANGE ) );
		}
		
		private function onDown ( e:MouseEvent ) :void {
			dispatchEvent( new Event("begin") );
			start_pos = this.mouseY;
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, onUp );
		}
		
		public function setScrollerHeight (h:int) :void {
			scroller.setHeight( h - scroller.cssBoxY );
		}
		
		public function get wheelScrolling():Boolean {return _wheelScrolling;}
		public function get wheelScrollTarget () :Sprite {	return _wheelScrollTarget;	}
		public function set wheelScrollTarget (v:Sprite) :void
		{
			if( _wheelScrollTarget && _wheelScrollTarget.hasEventListener(MouseEvent.MOUSE_WHEEL) ) 
				_wheelScrollTarget.removeEventListener( MouseEvent.MOUSE_WHEEL, wheelHandler );
			
			_wheelScrollTarget = v;
			
			if( v != null ) {
				_wheelScrolling = true;
				v.addEventListener( MouseEvent.MOUSE_WHEEL, wheelHandler );
			}else{
				_wheelScrolling = false;
			}
		}
		
		public function wheelHandler ( e:MouseEvent ) :void {
			if( enabled )
			{
				var t:int = getTimer();
				if( t - ltWheelTime > wheelFrameTime )
				{
					ltWheelTime = t;
					
					var d:int = e.delta;
					if(d < 0) {
						scroller.y += wheelStepSize;
					}else if(d > 0) {
						scroller.y -= wheelStepSize;
					}else{
						return; // d = 0
					}
					percent = percent;
					dispatchEvent( new Event( Event.CHANGE ) );
				}
			}
		}
	}
}