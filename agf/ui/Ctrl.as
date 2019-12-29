package agf.ui
{
	import flash.display.Sprite;
	
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	
	/**
	* Base Class for a control (Button, Menu...)
	*/
	public class Ctrl extends Sprite
	{
		public function Ctrl () {}
		
		// dynamic object properties
		public var options:Object = {};
		
		protected var _enabled:Boolean = true;
		public function set enabled (v:Boolean) :void {	_enabled = v; }
		public function get enabled () :Boolean { return _enabled; }
		
		public function setWidth (w:int) :void {}		
		public function getWidth () :int { return width; }
		
		public function setHeight (h:int) :void {}
		public function getHeight () :int { return height; }
	}
}