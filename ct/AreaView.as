 package ct
 {
	import agf.html.*;
	import agf.tools.*;
	import agf.Options;
	import agf.ui.*;
	import agf.icons.IconFromFile;
	import flash.utils.getTimer;
	import flash.display.Sprite;
	import flash.events.*;
	
	public class AreaView extends CssSprite
	{
		public function AreaView(w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false)  {
			super( w,h,parentCS,style,name,id,classes,noInit);
			clickScrolling = false;
			create();
		}
		
		public static var minH:Number=100;
		public var editor:AreaEditor;
		
		// areas
		public var scrollpane1:ScrollContainer;
		public var itemList1:ItemTree;
		public var newItemLabel:Label;
		
		// new items
		public var scrollpane2:ScrollContainer;
		public var itemList2:ItemList;
		private var sizeH:Number = 290;
		private var sizeButton:Button;
		private var currItemId:int=-1;
		private var currItemName:String="";
		private var newItemDrag:Boolean=false;
		private var viewSizeStartY:Number=0;
		
		internal static var clickScrolling:Boolean=false;
		private var clickTime:Number=0;
		private var clickY:Number=0;
		
		public function get rootNode () :ItemTree { return itemList1; } 
		
		private function create () :void {
			if(scrollpane1) {
				if( itemList1 && scrollpane1.content.contains( itemList1 ) ) scrollpane1.content.removeChild( itemList1 );
				if( contains( scrollpane1 ) ) removeChild( scrollpane1 );
			}
			
			if(scrollpane2) {
				if( itemList1 && scrollpane2.content.contains( itemList2 ) ) scrollpane1.content.removeChild( itemList2 );
				if( contains( scrollpane2 ) ) removeChild( scrollpane2 );
			}
			
			if( sizeButton && contains(sizeButton)) removeChild( sizeButton );
			
			scrollpane1 = new ScrollContainer( 0,0, this, styleSheet, '', 'areaview-scroll-container', false );
			scrollpane1.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
			
			itemList1 = new ItemTree( null, ["root"], 0, 0, scrollpane1.content, styleSheet, '', 'areaview-container', false );
			
			scrollpane2 = new ScrollContainer( 0,0, this, styleSheet, '', 'areaview-scroll-container', false );
			if(CTOptions.isMobile ) {
				scrollpane2.slider.wheelScrollTarget = null;
			}
			itemList2 = new ItemList( 0, 0, scrollpane2.content, styleSheet, '', 'areaview-container', false );
			itemList2.margin = 0;
			
			var lb:Label = new Label(0,0,this,styleSheet,'','areaview-new-label',false);
			lb.label = Language.getKeyword("New Item In");
			lb.x = cssLeft;
			
			newItemLabel = lb;
			
			sizeButton = new Button ([],0,0,this,styleSheet,'','area-sizebutton-v',false);
			sizeButton.addEventListener( MouseEvent.MOUSE_DOWN, viewSizeDown );
			
			setWidth( getWidth() );
		}
		
		public function clearAreas () :void {
			itemList1.clearAllItems();
			scrollpane1.contentHeightChange();
		}
		
		public function clearItems () :void {
			itemList2.clearAllItems();
			scrollpane2.contentHeightChange();
		}
		
		public function addItem ( nameLabel:String, icon:String="") :void
		{
			var btn:Button;
			if( icon != "" ) {
				btn = new Button([new IconFromFile(icon, Options.iconSize, Options.iconSize), Language.getKeyword(nameLabel), new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "forward-btn.png",Options.iconSize,Options.iconSize)], 0, 0, itemList2, styleSheet, '', 'areaview-item-btn', false);
			}else{
				btn = new Button([Language.getKeyword(nameLabel), new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "neu-anordnen.png",Options.iconSize,Options.iconSize)], 0, 0, itemList2, styleSheet, '', 'areaview-item-btn', false);
			}
			itemList2.addItem( btn );
			btn.options.intid = itemList2.numItems-1;
			btn.options.templateId = nameLabel;
			btn.addEventListener( MouseEvent.MOUSE_DOWN, newItemDown );
			btn.addEventListener( MouseEvent.CLICK, newItemClick );
		}
		
		private function newItemClick (e:MouseEvent) :void {
			if( clickScrolling ) {
				clickScrolling = false;
			}
			else
			{
				editor.newItem( currItemId, currItemName );
			}
		}
		private function newItemUp (e:MouseEvent) :void
		{
			stage.removeEventListener( MouseEvent.MOUSE_UP, newItemUp );
			
			if( newItemDrag ) {
				newItemDrag = false;
			}else{
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, newItemMove );
				clickScrolling = false;
			}
		}
		
		private var longClick:Boolean=false;
		
		private function newItemMove (e:MouseEvent) :void
		{
			var dy:Number = mouseY - clickY;
			if( !clickScrolling )
			{
				if( !longClick ) {
					if( Math.abs( dy ) > CTOptions.mobileWheelMove )
					{
						clickScrolling = true;
					}
				}
				if( !clickScrolling ) {
					if( getTimer() - clickTime > CTOptions.longClickTime ) {
						longClick = true;
					}
				}
			}else{
				scrollpane2.slider.value -= dy;
				scrollpane2.scrollbarChange(null);
				clickY = mouseY;
			}
		}
		
		private function newItemDown (e:MouseEvent) :void
		{
			var currItem:Button = Button(e.currentTarget);
			
			currItemId = currItem.options.intid;
			currItemName = currItem.options.templateId;
			stage.addEventListener( MouseEvent.MOUSE_UP, newItemUp );
			
			clickScrolling = false;
			newItemDrag = false;
			longClick = false;
			
			if( currItem.mouseX > currItem.contRight.x - currItem.clipSpacing ) {
				newItemDrag = true;
				editor.startDragNewItem( currItemId, currItemName );
			} 
			else 
			{
				clickTime = getTimer();
				clickY = mouseY;
				stage.addEventListener( MouseEvent.MOUSE_MOVE, newItemMove );
			}
		}
		
		public override function setWidth (w:int) :void { 
			super.setWidth(w);
			
			var i:int;
			var L:int;
			var sbw:int;
			
			if( scrollpane1 ) {
				sbw = 0;
				if( scrollpane1.slider.visible ) sbw = 10;
				
				scrollpane1.setWidth ( w );
				if( itemList1 && itemList1.itemList.items) {
					L = itemList1.itemList.items.length;
					var itm:CssSprite;
					
					for(i=0; i<L; i++) {
						itm = CssSprite( itemList1.itemList.items[i] );
						itm.setWidth( w - (sbw + itm.cssPaddingLeft + cssPaddingLeft + cssLeft) );
					}
					itemList1.itemList.setWidth(0);
					itemList1.itemList.init();
				}
			}
			if( scrollpane2 ) {
				sbw = 0;
				if( scrollpane2.slider.visible ) sbw = 10;
				
				scrollpane2.setWidth( w );
				if( itemList2 && itemList2.items ) {
					L = itemList2.items.length;
					for(i=0; i<L; i++) {
						itm = CssSprite( itemList2.items[i] );
						itm.setWidth( w - ( cssBoxX + itm.cssBoxX + sbw ) );
					}
					itemList2.setWidth(0);
					itemList2.init();
				}
			}
			if( sizeButton ) {
				sizeButton.setWidth( w - (cssBoxX + sizeButton.cssBoxX) );
				setChildIndex( sizeButton, numChildren-1);
			}
		}
		public override function setHeight (h:int) :void { 
			super.setHeight(h);
			
			var h1:Number = Math.floor( h - sizeH );
			if( h1 < minH ) {
				h1 = minH;
			}
			
			var h2:Number = Math.floor( sizeH );
			if( h2 < minH ) {
				h2 = minH;
			}
			if( scrollpane1 ) {
				scrollpane1.setHeight ( h1 );
				scrollpane1.contentHeightChange();
			}
			if( scrollpane2 ) {
				scrollpane2.y = cssTop + h1 + newItemLabel.cssSizeY + cssTop + 2;
				scrollpane2.setHeight ( h2 - (newItemLabel.cssSizeY) );
				scrollpane2.contentHeightChange();
			}
			if(newItemLabel) {
				newItemLabel.y = cssTop + h1;
				scrollpane2.y += scrollpane2.cssTop + newItemLabel.cssSizeY + newItemLabel.cssMarginBottom;
			}
			if( sizeButton ) {
				sizeButton.y = cssTop + h1;
			}
		}
		
		private function btnUp (event:MouseEvent) :void {
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
		}
		private function btnMove (event:MouseEvent) :void {
			var dy:Number = mouseY - clickY;
			
			if( ! clickScrolling )
			{
				if( Math.abs(dy) > CTOptions.mobileWheelMove )
				{
					clickScrolling = true;
				}
			}else{
				// scroll
				scrollpane1.slider.value -= dy;
				scrollpane1.scrollbarChange(null);
				clickY = mouseY;
			}
		}
		private function btnDown (event:MouseEvent) :void {
			stage.addEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, btnUp );
			clickScrolling = false;
			clickY = mouseY;
		}
		
		private function viewSizeDown (e:MouseEvent) :void {
			if( stage ) {
				stage.addEventListener( MouseEvent.MOUSE_UP, viewSizeUp );
				addEventListener( Event.ENTER_FRAME, viewSizeFrame );
				viewSizeStartY = mouseY;
			}
		}
		
		private function viewSizeUp (e:MouseEvent) :void {
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_UP, viewSizeUp );
				removeEventListener( Event.ENTER_FRAME, viewSizeFrame );
			}
		}
		
		private function viewSizeFrame (e:Event) :void {
			var my:Number = getHeight() - mouseY;
			if( my > minH ) {
				if( my > getHeight() - minH ) {
					sizeH = getHeight() - minH;
				}else{
					sizeH = my;
				}
			}else{
				sizeH = minH;
			}
			setHeight( getHeight() );
			setWidth(getWidth());
		}

	}
}
