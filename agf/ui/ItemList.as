package agf.ui
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import flash.utils.setTimeout;
	
	public class ItemList extends ItemBar
	{
		public function ItemList (w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null,cssId:String='',cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style,cssId,cssClasses, noInit);
		}
		
		public var vert:Boolean = true; // v or h
		
		public override function format (forceSameWidth:Boolean=false) :void 
		{
			if(items)
			{
				if( !vert ) {
					super.format(forceSameWidth);
					return;
				}
				
				var L:int = items.length;
				
				if(L > 0) 
				{
					var i:int;
					var it:CssSprite;
					var tmp:CssSprite = CssSprite(items[0]);
					tmp.y = cssTop + margin;
					
					if(!contains(tmp)) addChild(tmp);
				
					var mw:Number=0;
					var w:int;
					for(i=0; i<L; i++) {
						Ctrl( items[i] ).setWidth(mw);
					}
					
					for(i=1; i<L; i++) 
					{
						it = CssSprite( items[i] );
						if( it ) {
							if( !contains(it) ) addChild(it);
							it.y = tmp.y + tmp.cssSizeY + margin;
							tmp = it;
						}
					}
				}
				init();
			}
		}
		
	}
}