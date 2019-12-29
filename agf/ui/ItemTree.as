package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	 
	public class ItemTree extends CssSprite
	{
		public function ItemTree ( _parentTree:ItemTree, icons:Array, w:Number=0, h:Number=0, 
								parentCS:CssSprite=null, style:CssStyleSheet=null,
								cssId:String='', cssClasses:String='',
								noInit:Boolean=false) {
			super(w, h, parentCS, style, "itemtree", cssId, cssClasses, noInit);
			
			if( _parentTree == null ) {
				rootNode = this;
			}else{
				parentTree = _parentTree;
			}
			create(icons);
		}

		public var btn:Button;
		public var itemList:ItemList;
		private var _opened:Boolean = false;
		private var fsw:Boolean=false;
		
		public var rootNode:ItemTree;
		public var parentTree:ItemTree;
		public override function setWidth (w:int) :void {
			super.setWidth( w );
			if( btn ) btn.setWidth( w );
			if( itemList && itemList.items ) {
				for( var i:int = 0; i < itemList.items.length; i++ ) {
					itemList.items[i].setWidth(w);
				}
				itemList.setWidth(0);
				itemList.init();
			}
		}
		public override function getHeight () :int {
			if( _opened ) {
				return itemList ? itemList.cssSizeY + itemList.y : cssSizeY;
			}else{
				return btn ? btn.cssSizeY : cssSizeY;
			}
		}
		
		public function get label () :String {
			return btn ? btn.label : "";
		}
		public function set label (v:String) :void {
			if( btn ) btn.label = v;
		}
		private function create ( icons:Array ) :void {
			if( btn && contains( btn ) ) removeChild( btn );
			
			if( this == rootNode ) {
				if(!_opened) {
					if( itemList) itemList.visible = true;
					_opened = true;
				}
			}else{
				btn = new Button( icons, 0,0, this, styleSheet, '', 'item-tree-btn', false);
				btn.addEventListener( MouseEvent.CLICK, toggle );
			}
			
			if( itemList && contains( itemList ) ) removeChild( itemList );
			itemList = new ItemList(0,0,this,styleSheet,'','tree-item-list');
			itemList.visible = _opened;
			
			itemList.y = btn ? Math.max(btn.cssMarginBottom, itemList.cssMarginTop ) + cssTop + btn.cssSizeY + 4 : cssTop + itemList.cssMarginTop;
		}
		
		public function addFolder ( icons:Array, noFormat:Boolean=false ) :ItemTree {
			var tr:ItemTree = new ItemTree(this,icons,0,0,itemList ,styleSheet,'','item-tree-element item-tree-folder',false);
			tr.rootNode = rootNode;
			itemList.addItem( tr, noFormat );
			return tr;
		}
		
		private function folderClick (e:MouseEvent ) :void {
			toggle(null);
		}
		public function toggle (e:Event) :void {
			itemList.visible = _opened = !_opened;
			rootNode.format(fsw);
		}
		public function open (e:Event) :void {
			if( !_opened ) {
				itemList.visible = _opened = true;
				rootNode.format(fsw);
			}
		}
		public function close (e:Event) :void {
			if( _opened ) {
				itemList.visible = _opened = false;
				rootNode.format(fsw);
			}
		}
		
		public function addItem ( item:DisplayObject, noFormat:Boolean=false ) :void {
			itemList.addItem( item, noFormat );
		}
		/*public override function addItemAt ( item:Sprite, id:uint, noFormat:Boolean=false ) :void {
			super.addItemAt ( item, id, noFormat );
			_content.addChild( item );
		}*/
		
		public function removeItem ( item:DisplayObject, noFormat:Boolean=false ) :int {
			return itemList.removeItem( item, noFormat );
		}
		public function clearAllItems ( ) :void {
			itemList.clearAllItems();
		}
		
		public function format (forceSameWidth:Boolean=false) :void {
			//itemList.format(forceSameWidth);
			fsw = forceSameWidth;
			treeFormat( itemList, forceSameWidth );
		}
		
		private function treeFormat ( list:ItemList, forceSameWidth:Boolean=false) :void {
			if( list ) {
				var c:CssSprite;
								
				if( list.items && list.items.length > 0 )
				{
					for( var i:int=0; i < list.items.length; i++ )
					{
						c = CssSprite( list.items[i] );
						
						if( (c is ItemTree) ) {
							ItemTree(c).format( forceSameWidth );
							c.init();
						}
					}
					list.format( forceSameWidth );
					list.init();
				}
			}
		}
		
		
	}
}