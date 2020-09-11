package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.animation.Animation;
	import fl.transitions.easing.Strong;
	import fl.transitions.easing.Regular;
	
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
		private var anim:Animation;
		
		public var openTime:int = 200;
		public var openEasing:Function = Regular.easeOut;
		public var closeTime:int = 200;
		public var closeEasing:Function = Regular.easeIn;
		
		public override function setWidth (w:int) :void {
			super.setWidth( w );
			if( btn ) btn.setWidth( w );
			if( itemList && itemList.items ) {
				for( var i:int = 0; i < itemList.items.length; i++ ) {
					itemList.items[i].setWidth(w);
				}
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
					// always open root node
					_opened = true;
				}
			}else{
				icons.push("Test BTN Label");
				btn = new Button( icons, 0,0, this, styleSheet, '', 'item-tree-btn', false);
				btn.addEventListener( MouseEvent.CLICK, toggle );
			}
			
			if( itemList && contains( itemList ) ) removeChild( itemList );
			itemList = new ItemList(0,0,this,styleSheet,'','tree-item-list');
			if( !_opened ) {
				removeChild( itemList );
			}
			
			itemList.y = btn ? Math.max(btn.cssMarginBottom, itemList.cssMarginTop ) + cssTop + btn.cssSizeY + 8 : cssTop + itemList.cssMarginTop;
		}
		
		public function addFolder ( icons:Array, noFormat:Boolean=false ) :ItemTree {
			var tr:ItemTree = new ItemTree(this,icons,0,0,itemList ,styleSheet,'','item-tree-element item-tree-folder',false);
			tr.rootNode = rootNode;
			itemList.addItem( tr, noFormat );
			return tr;
		}
		
		private static var animRunning:Boolean = false;
		private static var toOpened:Boolean = false;
		private static var animEvent:Event = new Event("animationFrame");
		private static var animDone:Event = new Event("animationComplete");
		
		private function toggleFrameHandler (e:Event) :void {
			rootNode.format(fsw);
			rootNode.dispatchEvent( animEvent );
		}
		
		private function animComplete (e:Event) :void
		{
			removeEventListener( Event.ENTER_FRAME, toggleFrameHandler );
			_opened = toOpened;
			
			if( !_opened && contains( itemList ) ) removeChild(itemList);
			animRunning = false;
			
			if( anim )
			{
				anim.removeEventListener( Event.COMPLETE, animComplete );
				if( contains( anim ) ) removeChild( anim );
				anim = null;
			}
			itemList.scaleY = 1;
			itemList.alpha = 1;
			
			rootNode.format(fsw);
			rootNode.dispatchEvent( animDone );
			
		}
		
		public function toggle (e:Event) :void
		{
			if( animRunning ) return;
			
			animRunning = true;
			
			if( !anim ) {
				anim = new Animation();
				anim.addEventListener( Event.COMPLETE, animComplete );
			}
			if( !contains( anim ) ) addChild( anim );
			
			if(e) e.stopPropagation();
			
			if( ! _opened )
			{
				// open animation
				itemList.scaleY = 0.001;
				itemList.alpha = 0;
				
				toOpened = _opened = true;
				if( !contains( itemList ) ) addChild(itemList);
				anim.run( itemList, { scaleY:1, alpha:1 }, openTime, openEasing );
			}
			else
			{
				// close animation
				itemList.scaleY = 1;
				toOpened = false;
				anim.run( itemList, { scaleY:0.001, alpha:0 }, closeTime, closeEasing );
				
			}
			
			addEventListener( Event.ENTER_FRAME, toggleFrameHandler); 
			
			
			//else if( contains( itemList ) ) removeChild( itemList );
			
			//rootNode.format(fsw);
		}
		public function open (e:Event) :void {
			if( !_opened )
			{
				_opened = true;
				itemList.scaleY = 1;
				itemList.alpha = 1;
				if( !contains( itemList ) ) addChild(itemList);
				rootNode.format(fsw);
			}
		}
		public function close (e:Event) :void {
			if( _opened ) {
				_opened = false;
				if( contains( itemList ) ) removeChild( itemList );
				rootNode.format(fsw);
			}
		}
		
		public function addItem ( item:DisplayObject, noFormat:Boolean=false ) :void {
			itemList.addItem( item, noFormat );
		}
		public function removeItem ( item:DisplayObject, noFormat:Boolean=false ) :int {
			return itemList.removeItem( item, noFormat );
		}
		public function clearAllItems ( ) :void {
			itemList.clearAllItems();
		}
		
		public function format (forceSameWidth:Boolean=false) :void {
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
						}
					}
					list.format( forceSameWidth );
				}
			}
		}
		
	}
}