package agf.html
{
	import flash.display.Sprite;
	
	public class TableCell extends CssSprite
	{
		public function TableCell(w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null) {
			super(w, h, parentCS, style, "td",'','', true);
		}
		
		public var rowspan:int=1;
		public var colspan:int=1;
		public var fixedSize:Boolean = false;
		public var allowResize:Boolean = true;
		
	}
}