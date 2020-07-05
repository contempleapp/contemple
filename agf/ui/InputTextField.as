package agf.ui
{
	import flash.text.*;
	import agf.Options;
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.tools.Console;
	
	public class InputTextField extends CssSprite
	{
		public function InputTextField (w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false)
		{
			super(w, h, parentCS, css, "textfield", cssId, cssClasses, true);
			
			textField = new TextField();
			textField.selectable = true;
			textField.type = TextFieldType.INPUT;
			textField.autoSize = TextFieldAutoSize.NONE;
			
			autoSwapState = "";
			
			if(css) {
				styleSheet = css;
				if( txtfmt == null ) {
					txtfmt = css.getTextFormat( [ "*", "body", ".searchbox-textfield" ] );
					textField.defaultTextFormat = txtfmt;
				}
			}
			addChild(textField);
			
			if(parentCS) parentCS.addChild(this);
		}
		
		private var _label:String="";
		private var txtfmt:TextFormat = null;
		
		public override function init (dontDraw:Boolean=false):void {
			super.init(dontDraw);
			textField.x = cssLeft;
			textField.y = cssTop;
		}
		public override function setWidth ( w:int) :void {
			cssWidth = 0;
			textField.width = w;
			init();
		}
		
		public override function setHeight ( h:int) :void {
			cssHeight = 0;
			textField.height = h;
			init();
		}
		
		public function set text (v:String) :void {
			if( textField ) {
				textField.text = v;
			}
		}
		public function get text () :String { 
			return textField ? textField.text : "";
		}
		
		public var textField:TextField;
	}
}