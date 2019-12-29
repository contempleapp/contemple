package agf.ui
{
	import flash.events.*;
	import agf.html.*;
	import agf.utils.ColorUtils;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.display.Sprite;
	
	public class Progress extends CssSprite {

		public function Progress ( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style, "progress", cssId, cssClasses, noInit);//false);
			
			argW = w;
			argH = h;
		}
		private var argW:Number=0;
		private var argH:Number=0;
		public var showProgressBar:Boolean = true;
		public var showPercentValue:Boolean = true;
		public var percentChar:String=" %";
		private var _value:Number=0; // current progress value 0-1
		private var _prg:CssSprite;
		private var _lbl:Label;
		
		public override function init (dontDraw:Boolean=false):void {
			super.init( dontDraw );
			create(cssWidth,cssHeight,nodeClass);
		}
		public function get value () :Number {
			return _value;
		}
		public function set value (v:Number) :void {
			if( v < 0 ) v = 0;
			else if( v > 1) v = 1;
			_value = v;
			if( showProgressBar ) updateProgressBar();
			if( showPercentValue ) updatePercentValue();
		}
		
		public override function setWidth( w:int) :void
		{
			super.setWidth(w);
			if( _prg ) _prg.setWidth( w );
			if( _lbl ) _lbl.x = cssLeft;
			if( showProgressBar ) updateProgressBar()
		}
		private function updatePercentValue () :void {
			if( _lbl != null ) _lbl.label = "" + (Math.round(_value*100)) + percentChar;
		}
		
		private function updateProgressBar () :void {
			if( _prg != null ) {
				_prg.setWidth ( Math.round(getWidth() * _value) );
			}
		}
		
		public function create ( w:Number=0, h:Number=0, cssClasses:String="" ) :void
		{
			if( _prg && contains( _prg ) ) removeChild(_prg);
			if( _lbl && contains( _lbl ) ) removeChild(_lbl);
			
			_prg = new CssSprite(w, 0, this, styleSheet, "progressvalue", '', cssClasses + '-value', false);
			_lbl = new Label(w, 0, this, styleSheet, '', "progress-label " + cssClasses + '-label', false);
			
			_prg.x = _lbl.x = cssLeft;
			_prg.y = cssTop;
			
			_lbl.y = _prg.y + _prg.cssSizeY + _lbl.cssMarginTop;
			
			value = 0;
			
			if( !showProgressBar ) {
				_prg.visible = false;
			}
			if(!showPercentValue) {
				_lbl.visible = false;
			}
			
		}
		

	}
	
}
