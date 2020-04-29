package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	import flash.utils.setTimeout;
	import flash.geom.Point;
	import agf.icons.IconArrowDown;
	import agf.events.PopupEvent;
	import agf.html.*;
	import agf.icons.IconSeparator;
	
	public class PopupItem extends Button
	{
		public function PopupItem (icons:Array, _popup:Popup, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(icons, 0, 0, null, style, cssId, cssClasses, true);
			
			// SEPARATOR
			if( icons && icons.indexOf("#separator") >= 0) {
				this.clips = [new IconSeparator(0x444444)];
				this.nodeClass = "separator";
				this.label = "";
				this._hasLabel = false;
				isSeparator = true;
				autoSwapState = "";
			}
			
			nodeName = "popupitem";
			parentList = parentCS;
			popup = _popup
		}
		
		public var isSeparator:Boolean=false;
		public var parentList:CssSprite;
		public var popup:Popup;
		public var sortid:int;
		
		public var depth:int=0;
		private static var pxy0:Point = new Point(0,0);
		
		private var _children:Vector.<PopupItem>;
		public function get children () :Vector.<PopupItem> { return _children; }
		
		// Add an item with its icons, labels and other assets
		public function addItem ( items:Array, css:CssStyleSheet=null ) :PopupItem 
		{
			if(_children == null) _children = new Vector.<PopupItem>();
			addEventListener ( MouseEvent.MOUSE_OVER, open);
			return _children [ _children.push( new PopupItem(items, popup, this, css,'',nodeClass) ) - 1 ];
		}
		
		public function search ( k:String, rv:Array=null ) :Array {
			if( rv == null ) rv = [];
			
			if( _children ) {
				var L:int = _children.length;
				var ppi:PopupItem;
				
				for(var i:int=0; i<L; i++) {
					ppi = _children[i];
					if( ppi.label == k ) {
						rv.push( ppi );
					}
					if( ppi.children && ppi.children.length > 0 ) {
						rv = ppi.search(k, rv);
					}
				}
			}
			return rv;
		}
		
		public function getItemId (it:PopupItem) :int {
			return _children.indexOf(it);
		}
		public function getItemIdByLabel (label:String) :int {
			if(_children) {
				for (var i:int = _children.length - 1; i >= 0; i--) {
					if ( _children[i].label == label ) {
						return i;
					}
				}
			}
			
			return -1;
		}
		public function removeItemAt ( id:uint ) :void {
			if(id < _children.length) {
				_children.splice(id,1);
			}
		}
		public function removeItems () :void {
			 _children = new Vector.<PopupItem>();
		}
		
		public var alignV:String = "top"; // top center current mouse bottom.. todo..
		public var alignH:String = "right"; // left center current mouse right.. todo..
		public var listAutoSize:Boolean = true;
		
		public var container:CssSprite;
		public var currentItem:PopupItem;
		
		/**
		* controls the closing behaviour
		* if greater than 1, the popup is closed after the value in miliseconds 
		* if 1, removes the root node immediatly from the stage in the popup close handler
		* if 0, the popup.container have to be removed from Popup.topContain89er manually
		*/
		public var remOnClose:int = 1;//167;// 357;
		public var removing:Boolean = false; // the popup list is visible, but already closed
		private var _opened:Boolean=false;
		
		public override function setWidth (w:int) :void {
			super.setWidth(w);
			
			if( isSeparator ) {
				contLeft.x = 0;
				contLeft.y = 0;
				for(var i:int=0; i<contLeft.numChildren; i++) {
					contLeft.getChildAt(i).x = 0;
					contLeft.getChildAt(i).y = 0;
					contLeft.getChildAt(i).width = cssSizeX;
				}
			}
		}
		public override function getHeight () :int {
			if( isSeparator ) {
				return 3;
			}
			return super.getHeight();
		}
		public function get opened () :Boolean { return _opened; }
		
		public function open (e:Event) :void
		{
			if(removing || _opened) return;
			
			depth = popup.openList.length;
			popup.openList.push(this);
			
			_opened = true;
			
			if(container) {
				if(Popup.topContainer.contains(container)) Popup.topContainer.removeChild(container);
				container = null;
			}
			container = new CssSprite( 0, 0, Popup.topContainer, styleSheet, "popuplist", nodeId, nodeClass, true );
			
			CssSprite.mouseIsDown = false;
			autoSwapState = "";
			swapState("active");
			
			var yp:int=0;
			var xp:int=0;
			var i:int;
			
			var srcw:Number = Popup.topContainer.getWidth();
			var srch:Number = Popup.topContainer.getHeight();
			
			if( children && children.length > 0 ) 
			{
				var items:Vector.<PopupItem> = children;
				var it:PopupItem;
				var iw:int=0;
				var iwa:Array=[];
				var iwid:int=0;
				var tw:Number=0;
				
				var gpos:Point;
				if(this.parentList == this.popup ) {
					gpos = popup.localToGlobal( pxy0 );
				}else{
					gpos = this.localToGlobal( pxy0 );
				}
				
				var _alignV:String = alignV;
				var _alignH:String = alignH;
				var item_h:int;
				
				for( i=0; i<items.length; i++ ) 
				{
					it = items[i];
					it._parentNode = container;
					container.addChild( it );
					
					if(!it.initialized) {
						it.init();
					}
				}
				
				if( listAutoSize ) {
					for( i=0; i<items.length; i++ ) {
						it = items[i];
						tw = Math.floor( it.getWidth() );
						item_h = Math.floor(it.getHeight());
						if( yp + item_h * 2 + container.cssTop + gpos.y >= srch ) {
							iwa[iwid] = iw;
							iw = 0;
							iwid++;
							yp = 0;
						}
						yp += item_h;
						if(tw > iw) iw = tw;
					}
				}
				
				if( iwid == 0 ) iwa[0] = iw;
				
				yp = 0;
				iwid = 0;
				iw = iwa[0];
				
				for( i=0; i<items.length; i++ ) 
				{
					it = items[i];
					
					if(listAutoSize) it.setWidth(iw);
					
					if(!it.isSeparator) {
						it.addEventListener( MouseEvent.MOUSE_OVER, itemOver);
						it.addEventListener( MouseEvent.MOUSE_DOWN, downHandler);
						it.addEventListener( MouseEvent.MOUSE_UP, selectHandler);
					}
					
					item_h = Math.floor( it.getHeight() );
					if( yp + item_h * 2 + container.cssTop + gpos.y > srch ) {
						iwid++;
						yp = 0;
						xp += iw;
						iw = iwa[ iwid ];
					}
					it.y = Math.floor(yp);
					it.x = Math.floor(xp);
					yp += Math.floor( item_h );
					
				}
				var p_cont:CssSprite;
				
				if( parentList is PopupItem ) {
					p_cont = this;
				}else{
					// Popup
					p_cont = Popup(parentList).rootNode.container;
				}
				
				// Position::
				if(_alignH == "right") container.x = gpos.x + p_cont.getWidth();
				else if(_alignH == "center") container.x = gpos.x + p_cont.getWidth()/2;
				else if(_alignH == "mouse") container.x = gpos.x + mouseX - (p_cont.getWidth()/2);
				else container.x = gpos.x - p_cont.getWidth(); 
				
				if( container.x < 0 ) {
					container.x = 0;
				}
				
				if( _alignV == "current" && !currentItem) _alignV = "top";
				
				if( _alignV == "top" ) {
					container.y = gpos.y;
				}else if(alignV == "middle") {
					container.y = gpos.y - p_cont.getHeight()/2;
				}else if(alignV == "current") {
					container.y = gpos.y - currentItem.y;
				}else if(alignV == "mouse") {
					container.y = gpos.y - mouseY;
				}else{
					container.y = gpos.y + this.getHeight();// bottom
				}
				
				if( container.y < 0 ) {
					container.y = 0;
				}
				
				container.x = Math.floor( container.x );
				container.y = Math.floor( container.y );
				container.parent.setChildIndex( container, container.parent.numChildren-1);
				container.init();
				
				for( i=0; i<items.length; i++ ) {
					it = items[i];
					it.x += container.cssLeft;
					it.y += container.cssTop;
				}
				
				if(e) {
					e.stopPropagation();
				}
			}
			
		}
		
		public function close (e:Event=null) :void
		{
			// use button behaviour
			swapState("normal");
			autoSwapState = "all";
			
			_opened = false;
			removing = true;
			
			if( remOnClose )
			{
				if(container && Popup.topContainer.contains(container)) {
					
					if( remOnClose > 1 ){
						setTimeout( remClose, remOnClose );
					}else{
						removing = false;
						Popup.topContainer.removeChild( container );
					}
					
				}
			}
		}
		
		private function remClose():void {
			removing = false;
			if(container && Popup.topContainer.contains(container)) {
				Popup.topContainer.removeChild( container );
			}
		}
		
		public function sizeList (list:PopupItem=null) :void {
			
			var items:Vector.<PopupItem> = list == null ? children : list.children;
			var L:int = items.length;
			var i:int;
			var bw:Number=0;
			var tw:Number;
			
			for(i=0; i<L; i++) {
				tw = items[i].cssSizeX;//.getWidth();
				if(tw > bw) bw = tw;
			}
			
			bw = Math.ceil(bw);
			
			for(i=0; i<L; i++) {
				items[i].setWidth(bw - items[i].cssBoxX);
			}
		}
		private function itemOver (e:Event) :void
		{
			var ppi:PopupItem = PopupItem(e.currentTarget);
			if( !ppi.children || ppi.children.length == 0 )
			{
				if(ppi.parentList is PopupItem) {
					popup.closeListFrom( PopupItem(ppi.parentList).depth + 1 );
				}else{
					popup.closeListFrom(1);
				}
			}
			else
			{
				// close All except this folder
				if(ppi.parentList is PopupItem) {
					popup.closeListFrom( PopupItem(ppi.parentList).depth + 1, ppi );
				}else{
					popup.closeListFrom(1, ppi);
				}
			}
			
			if(e) {
				e.stopPropagation();
			}
		}
		private function downHandler (e:Event) :void {
			if(e) e.stopPropagation();
		}
		private function selectHandler (e:Event) :void
		{
			var ppi:PopupItem = PopupItem(e.currentTarget);
			if( ppi.children && ppi.children.length > 0 ) {
				ppi.open(null);
			}else{
				var it:PopupItem = PopupItem(e.currentTarget);
				if( parentList is PopupItem ) PopupItem(parentList).currentItem = it;
				popup.selectItem( it );
			}
			if(e) { 
				e.stopPropagation();
			}
		}
		
	}
}