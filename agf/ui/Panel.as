package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	
	public class Panel extends CssSprite
	{
		public function Panel(vtype:String="", w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='')
		{
			super(w, h, parentCS, style, "panel", cssId, cssClasses, true);
			_e  = new Event(Event.CHANGE);
			
			viewType = vtype || "panel";
		}
		
		// User Defined Data
		public var udfData:Object = { xmlRenderer:null };
		public var src:DisplayObject;
		
		public function setSrc ( _src:DisplayObject ):void {
			if( src && contains(src) ) removeChild (src);
			
			src = _src;
			
			if( !contains(src) )addChild( src );
		}
		
		private var _e:Event;
		private var _vtype:String;
		/*
		public function loadXml (file:String) :void {
			var rm:ResourceMgr = ResourceMgr.getInstance();
			rm.loadResource( file, xmlLoaded );
		}
		
		private function xmlLoaded (res:Resource) :void {
			var xo:XML = XML( String(res.obj) );
			var xr:XmlUiRenderer = new XmlUiRenderer(getWidth(), getHeight(), this, cssStyleSheet);
			xr.render(xo);
		}
		*/
		
		/**
		* Get and set the viewType
		* Sets the nodeId to the viewType String
		* Redraw the style sheet
		* Dispatches Event.CHANGE if the viewType has been changed
		*/
		public function get viewType () :String { return _vtype; }
		public function set viewType ( type:String ) :void 
		{
			if(_vtype == type) return;
			
			_vtype = nodeId = type;
			
			init();
			dispatchEvent(_e);
		}
	}
}