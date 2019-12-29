package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	import flash.utils.setTimeout;
	
	import agf.icons.IconArrowDown;
	import agf.events.PopupEvent;
	import agf.html.*;
	import flash.geom.Point;
	
	public dynamic class Popup extends Button
	{
		public function Popup (icons:Array, w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(icons, w, h, parentCS, css, cssId, cssClasses, true);
			nodeName = "popup";
			rootNode = new PopupItem( null, this, this, css , cssId, cssClasses);
			if(!noInit) init();
			addEventListener( MouseEvent.MOUSE_DOWN, open);
		}
		public var blockBackground:Boolean=true;
		
		public var defaultIcons:Boolean = true;
		public var alignV:String = "left"; // left center current mouse right.. todo..
		public var alignH:String = "bottom"; // top center current mouse bottom.. todo..
		public var openList:Vector.<PopupItem>;
		public static var topContainer:CssSprite;
		public var rootNode:PopupItem;
		private var currentItem:PopupItem;
		
		public function get opened () :Boolean { return rootNode.opened; }
		
		public function closeListFrom ( depth:int, exclude:PopupItem=null ) :void
		{
			if( openList && openList.length > 0 ) {
				var L:int = openList.length;
				if( depth >= -1 && depth < L) {
					for(var i:int = L-1; i >= depth; i--) {
						if(exclude && openList[i] == exclude) continue;
						openList[i].close();
						openList.splice(i,1);
					}
				}
			}
		}
		
		public static var blocker:Sprite;
		
		private static function removeAllPopups () :void {
			if( topContainer ) {
				var d:DisplayObject;
				
				for( var i:int=0; i<topContainer.numChildren; i++ ) {
					d = topContainer.getChildAt( i );
					if( d is PopupItem )
					{
						PopupItem(d).popup.close();
						//topContainer.removeChild( d );
					}
				}
			}
		}
		private static function blockHandler (e:MouseEvent) :void {}
		
		public function open (e:Event=null) :void
		{			
			if( opened ) close();
			
			if( topContainer ) {
				if( blocker == null ) blocker = new Sprite();
				if( blockBackground ) {
					blocker.graphics.clear();
					blocker.graphics.beginFill( 0x0,0);
					blocker.graphics.drawRect( 0,0, topContainer.getWidth(), topContainer.getHeight() );
					blocker.graphics.endFill();
					blocker.addEventListener( MouseEvent.MOUSE_DOWN, blockHandler );
				}
				if( ! topContainer.contains( blocker) ) topContainer.addChild( blocker );
			}
			
			openList = new Vector.<PopupItem>();
			rootNode.open(e);
			
			CssSprite.mouseIsDown = false;
			autoSwapState = "";
			swapState("active");
			
			var container:CssSprite = rootNode.container;
			var gpos:Point = this.localToGlobal( new Point(0,0) );
			var w:int = topContainer.getWidth();
			var h:int = topContainer.getHeight();
			
			// Position::
			if(alignH == "right")  container.x = (gpos.x + width ) - container.width;
			else if(alignH == "center") container.x = gpos.x + (width - container.width)/2;
			else if(alignH == "mouse") container.x = (gpos.x - mouseX) - (container.width /2);
			else container.x = gpos.x; 
			
			if( alignV == "top" ) {
				container.y = gpos.y - container.height;
			}else if(alignV == "middle") {
				container.y = gpos.y - container.height /2;
			}else if(alignV == "current") {
				if(!currentItem)
					container.y = gpos.y + height
				else
					container.y = gpos.y - currentItem.y;
			}else if(alignV == "mouse") {
				container.y = gpos.y - mouseY;
			}else{
				container.y = gpos.y + height;
			}
			
			if( container.y < 0 ) {
				container.y = 0;
			}else if( container.y > h - container.height ) {
				container.y = h - container.height;
			}
			
			if( container.x < 0 ) {
				container.x = 0;
			}else if( container.x > w - container.width ) {
				container.x = w-container.width;
			}
			
			container.x = Math.floor( container.x );
			container.y = Math.floor( container.y );
			
			removeEventListener( MouseEvent.MOUSE_DOWN, open);
			stage.addEventListener( MouseEvent.MOUSE_DOWN, close);
			
			dispatchEvent( new Event( Event.OPEN ) );
		}
		
		public function close (e:Event=null) :void {
			closeListFrom( 0 );
			// use button behaviour
			swapState("normal");
			autoSwapState = "all";
			if( blocker && topContainer ) {
				if( topContainer.contains( blocker ) ) topContainer.removeChild( blocker );
				
			}
			if(stage) stage.removeEventListener( MouseEvent.MOUSE_DOWN, close);
			addEventListener( MouseEvent.MOUSE_DOWN, open );
			
			dispatchEvent( new Event(Event.CLOSE) );
			
			if( e ) {
				e.preventDefault();
				e.stopPropagation();
			}
		}
		
		public function sizeList (list:PopupItem=null) :void {
			rootNode.sizeList(list);
		}
		
		private function downHandler (e:Event) :void {
			if(e) e.stopPropagation();
		}
		
		public function selectItem (item:PopupItem) :void {
			currentItem = item;
			var selEv:PopupEvent = new PopupEvent( this, currentItem, Event.SELECT );
			closeListFrom(0);
			close();
			dispatchEvent(selEv);
		}
	}
}