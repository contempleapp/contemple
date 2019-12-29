package agf.ui
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	 
	public class ItemBar extends CssSprite
	{
		public function ItemBar (w:Number=0, h:Number=0, 
								parentCS:CssSprite=null, style:CssStyleSheet=null,
								cssId:String='', cssClasses:String='',
								noInit:Boolean=false) {
			super(w, h, parentCS, style, "itembar", cssId, cssClasses, noInit);
		}
		
		public var margin:Number = 0;
		public var alignV:String = "left"; // left center mouse right.. todo..
		public var alignH:String = "bottom"; // top middle current mouse bottom.. todo..
		
		public var items:Array;
		
		public function get numItems () :uint {
			return items ? items.length : 0;
		}
		
		public function getItemAt ( index:uint ) :Sprite {
			if( items ) {
				if( index < items.length ) {
					return items[index];
				}
			}
			return null;
		}
		
		public function addItem ( item:DisplayObject, noFormat:Boolean=false ) :void {
			if( items == null ) items = [];
			if( items.push( item ) > 1 && !noFormat ) format();
		}
		
		public function addItemAt ( item:DisplayObject, id:uint, noFormat:Boolean=false ) :void {
			if( items == null ) items = [];
			items.splice(id, 0, item);
			if( items.length > 1 && !noFormat ) format();
		}
		
		public function removeItem ( item:DisplayObject, noFormat:Boolean=false ) :int {
			if( items )
			{
				var id:int = items.indexOf( item );
				if( contains(item) ) removeChild( item );
				if( id >= 0 ) {
					items.splice( id, 1 );
					
				}
				if( !noFormat  ) format();
				return id;
			}
			return -1;
		}
		
		public function clearAllItems ( ) :void {
			if( items ){
				for(var i:int = items.length-1; i >= 0; i-- ) {
					if( contains(items[i]) ) removeChild( items[i] );
				}
				items = null;
			}
		}
		
		public function format (forceSameHeight:Boolean=false) :void
		{
			if( items )
			{
				var L:int = items.length;
				var it:DisplayObject;
				var tmp:DisplayObject;
				var i:int;
				var maxH:Number=0;
				var hgt:Number;
				
				tmp = DisplayObject( items[0] );
				
				if(!contains(tmp)) addChild(tmp);
				
				if( L > 1 ) {
					tmp.x = 0;
					
					// position items
					for(i=1; i<L; i++) 
					{
						it = Ctrl( items[i] );
						if(!contains(it)) addChild(it);
						it.x = tmp.x + tmp.width + margin;
						hgt = Math.floor( tmp.height );
						if(hgt > maxH) maxH = hgt;
						
						tmp = it;
					}
				}
				
				var totalW:Number = tmp.x + (tmp.width);
				var offset:Number = 0;
				
				// align
				if( alignV == "right" ){
					offset = (width - totalW);
				}else if( alignV == "center"){
					offset = width/2 - totalW/2;
				}
				
				if( offset != 0 ) {
					for(i=0; i<L; i++) {
						items[i].x += offset;
					}
				}
				
				if( forceSameHeight ) {
					for(i=0; i<L; i++) {
						try {
							items[i]["setHeight"]( maxH );
						}catch(e:Error) {
							
						}
					}
				}
				
			}
		}
		
		
	}
}