package agf.ui
{
	import flash.text.*;
	import agf.Options;
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.tools.Console;
	
	public class Label extends CssSprite
	{
		public function Label (w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false)
		{
			super(w, h, parentCS, css, "textfield", cssId, cssClasses, true);
			
			textField = new TextField();
			textField.selectable = false;
			textField.autoSize = TextFieldAutoSize.LEFT;
			textField.embedFonts = Options.embedFonts;
			textField.antiAliasType = Options.antiAliasType;
			
			autoSwapState = "";
			
			if(css) {
				styleSheet = css;
				textField.styleSheet = css;
			}
			addChild(textField);
			
			if(parentCS) parentCS.addChild(this);
		}
		
		private var _label:String="";
		
		public override function init (dontDraw:Boolean=false):void {
			super.init(dontDraw);
			textField.x = int(cssLeft);
			textField.y = int(cssTop);
		}
		public override function setWidth ( w:int) :void {
			cssWidth = 0;
			if( w == 0 ) {
				textField.autoSize = TextFieldAutoSize.LEFT;
			}else{
				textField.autoSize = TextFieldAutoSize.NONE;
				textField.width = w;
			}
			init();
		}
		
		public override function setHeight ( h:int) :void {
			cssHeight = 0;
			textField.autoSize = TextFieldAutoSize.NONE;
			textField.height = h;
			init();
		}
		
		public function set label (v:String) :void {
			_label = v;
			textField.htmlText = buildHtmlText(v);
		}
		public function get label () :String { return _label; }
		
		public var textField:TextField;
		
	}
}