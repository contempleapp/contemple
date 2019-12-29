package agf.html
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	
	public class Table extends CssSprite
	{
		public function Table (w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, noInit:Boolean=false) {
			super(w, h, parentCS, style,"table",'','', noInit);
			//if(!noInit) init();
		}
		
		public var marginX:Number = 1;
		public var marginY:Number = 1;
		protected var items:Array;
		
		public function addItem ( item:CssSprite, row:int=-1, col:int=-1, colspan:int=1, rowspan:int=1, noFormat:Boolean=false ) :TableCell 
		{
			if(items==null) items = [];
			if(row==-1) row = items.length;
			if(items.length <= row || items[row] == null) items[row] = [];
			
			var i:int;
			var id:int;
			var j:int;
			var L:int;
		
			if(col==-1){
				L = items[row].length;
				for(col=0; col<L; col++) {
					if(items[row][j] == null) {
						col = j;
						break;
					}
				}
			}
			
			var cell:TableCell;
			if(items[row][col] == null) {
				items[row][col] = new TableCell(0,0,this,cssStyleSheet);
				cell = TableCell(items[row][col]);
			}else if( !(items[row][col] is TableCell) ) {
				cell = TableCell(items[row][col]);
			}
			
			if(cell) 
			{
				
				if(item) {
					cell.addChild( item );
				}
				if(colspan > 1) {
					cell.colspan = colspan;
					for(i=1; i<colspan; i++) {
						items[row].splice( col+i, 0, "col:"+row+":"+col ); 
					}
				}
				
				if(rowspan > 1) {
					cell.rowspan = rowspan;
					for(i=1; i<rowspan; i++) {
						id = row + i;
						if(!(items[id] is Array)) {
							items[id] = [];
							for(j=0; j<col; j++) items[id][j] = null;
						}
						items[id][col] = "row:"+row+":"+col;
					}
				}
			}
			if(!noFormat) format();
			
			return cell;
		}
		
		public function removeItem ( item:CssSprite, noFormat:Boolean=false ) :void {
			/*var id:int = items.indexOf(item);
			if(id>=0) items.splice(id,1);
			if(contains(item)) removeChild(item);
			if(!noFormat) format();*/
		}
		
		public function format () :void 
		{
			if(items==null) return;
			var L:int = items.length;
			
			if(L>0) {
				var i:int;
				var j:int;
				var jL:int;
				var cell:TableCell;
				var xp:Number=cssLeft;
				var yp:Number=cssTop;
				var maxW:Number=0;
				var maxH:Number=0;
				var maxCellW:Array = [];
				var maxCellH:Array = [];
				var w:Number;
				var h:Number;
				
				for(i=0; i<L; i++) // for rows..
				{
					if(items[i]) {
						jL = items[i].length;
						xp = cssLeft;
						
						for(j=0; j<jL; j++)   // for cols.. 
						{
							if(items[i][j] is TableCell) 
							{
								cell = items[i][j];
								cell.styleSheet = cssStyleSheet;
								
								
								w = cell.cssSizeX;//cell.getWidth();
								h = cell.cssSizeY;// cell.getHeight();
								
								if(maxCellW.length <= j || w > maxCellW[j]) maxCellW[j] = w;
								if(maxCellH.length <= i || h > maxCellH[i]) maxCellH[i] = h;
								
							}else{
								
								if(items[i][j] is String) {
									var s:String = items[i][j];
									var t:String = s.substring(0,3);
									
									if( t == "row" ) {
										
									}else if( t == "col" ) {
										
									}
								}
								
							}
						}
						
						yp += maxH;
					}
				}
				
				trace("MaxW: " + maxCellW);
				trace("MaxH: " + maxCellH);
				
				var k:int;
				var distX:Number;
				var distY:Number;
				
				for(i=0; i<L; i++) // for rows..
				{
					if(items[i]) {
						jL = items[i].length;
						xp = cssLeft;
						
						for(j=0; j<jL; j++) // for cols.. 
						{
							if(items[i][j] is TableCell) 
							{
								cell = items[i][j];
								cell.swapState("normal");
								
								distX = maxCellW[j];
								if( cell.colspan > 1) {
									for(k=1; k < cell.colspan; k++) {
										distX += maxCellW[j + k];
									}
								}
								cell.setWidth( distX - (cell.cssBorderLeft + cell.cssBorderRight) );
								
								distY =  maxCellH[i];
								if( cell.rowspan > 1) {
									for(k=1; k < cell.rowspan; k++) {
										distY += maxCellH[i + k];
									}
								}
								cell.setHeight( distY - (cell.cssBorderTop + cell.cssBorderBottom) );
								
								cell.x = xp;
								cell.y = yp;
								
								xp += distX;//maxCellW[j];
							}
						}
						
						yp+=maxCellH[i];
					}
				}
			}
		}
		
		
		
	}
}