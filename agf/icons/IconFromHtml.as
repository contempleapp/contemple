package agf.icons
{
	import flash.display.*;
	import flash.text.*;
	import agf.html.CssStyleSheet;
	
	public class IconFromHtml extends Sprite
	{
		public function IconFromHtml (html:String, style:CssStyleSheet=null, cssClass:String="", w:Number=16, h:Number=16)
		{
			var tf:TextField = new TextField();
			tf.autoSize = TextFieldAutoSize.LEFT;
			if( style ) {
				var txtfmt:TextFormat = style.getTextFormat( ["*", "body", "p", cssClass] );
				tf.defaultTextFormat = txtfmt;
				tf.styleSheet = style;
			}
			tf.htmlText = html;
			addChild( tf );
		}
		
		private var tf:TextField;
	}
}