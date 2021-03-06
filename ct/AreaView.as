﻿package ct
 {
	import agf.html.*;
	import agf.tools.*;
	import agf.Options;
	import agf.ui.*;
	import agf.icons.IconFromFile;
	import flash.utils.getTimer;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Rectangle;
	import flash.utils.setTimeout;
	 
	public class AreaView extends CssSprite
	{
		public function AreaView(w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
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
		private var sizeH:Number = 100;
		private var sizeButton:Button;
		private var currItemId:int=-1;
		private var currItemName:String="";
		private var newItemDrag:Boolean=false;
		private var viewSizeStartY:Number=0;
		
		public var backBtn:Button;
		public var branchTitle:Label;
		
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
			itemList1.itemList.margin = 0;
			
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
			
			branchTitle = new Label(0,0,this,styleSheet,'','areaview-branch-title',false);
			
			backBtn = new Button( [ new IconFromFile(Options.iconDir+CTOptions.urlSeparator+"navi-left-btn.png", Options.iconSize, Options.iconSize) ], 0, 0, this, styleSheet, '', 'areaview-backbtn', false );
			backBtn.autoSwapState = "";
			backBtn.visible = false;
			
			setWidth( getWidth() );
			setHeight(getHeight());
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
				btn = new Button([new IconFromFile(icon, Options.iconSize, Options.iconSize), Language.getKeyword(nameLabel)], 0, 0, itemList2, styleSheet, '', 'areaview-item-btn', false);
			}else{
				btn = new Button([Language.getKeyword(nameLabel)], 0, 0, itemList2, styleSheet, '', 'areaview-item-btn', false);
			}
			itemList2.addItem( btn );
			btn.options.intid = itemList2.numItems-1;
			btn.options.templateId = nameLabel;
			btn.addEventListener( MouseEvent.MOUSE_DOWN, newItemDown );
		}
		
		private function newItemUp (e:MouseEvent) :void
		{
			if( e ) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}
			stage.removeEventListener( MouseEvent.MOUSE_UP, newItemUp );
			
			if( newItemDrag ) {
				newItemDrag = false;
			}else{
				if ( !clickScrolling && !longClick ) {
					editor.newItem( currItemId, currItemName );
				}
				removeEventListener( Event.ENTER_FRAME, newItemMove );
				setTimeout( function () {
					clickScrolling = false;
				}, 77);
			}
		}
		
		private var longClick:Boolean=false;
		
		private function newItemMove (e:Event) :void
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
						
						removeEventListener( Event.ENTER_FRAME, newItemMove );
						stage.removeEventListener( MouseEvent.MOUSE_UP, newItemUp );
						
						newItemDrag = true;
						editor.startDragNewItem( currItemId, currItemName );
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
			if( e ) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}
			var currItem:Button = Button(e.currentTarget);
			
			currItemId = currItem.options.intid;
			currItemName = currItem.options.templateId;
			stage.addEventListener( MouseEvent.MOUSE_UP, newItemUp );
			
			clickScrolling = false;
			newItemDrag = false;
			longClick = false;
			
			clickTime = getTimer();
			clickY = mouseY;
			addEventListener( Event.ENTER_FRAME, newItemMove );
		}
		
		public override function setWidth (w:int) :void { 
			super.setWidth(w);
			
			var i:int;
			var L:int;
			var sbw:int;
			var itm:CssSprite;
			var btn:Button;
			
			if ( backBtn ) {
				backBtn.setWidth( w );
			}
			
			if ( branchTitle ) {
				branchTitle.x = Options.iconSize + (8 * CssUtils.numericScale);
				branchTitle.setWidth( w - Options.btnSize );
				branchTitle.setHeight( branchTitle.textField.textHeight + (8 * CssUtils.numericScale));
			}
			
			if( scrollpane1 ) {
				sbw = 0;
				if( scrollpane1.slider.visible ) sbw = (8*CssUtils.numericScale);
				
				scrollpane1.setWidth ( w );
				
				if( itemList1 && itemList1.itemList.items) {
					L = itemList1.itemList.items.length;
					for(i=0; i<L; i++) {
						itm = CssSprite( itemList1.itemList.items[i] );
						itm.setWidth( w - (sbw + itm.cssBoxX ) );
					}
				}
			}
			if( scrollpane2 ) {
				sbw = 0;
				if( scrollpane2.slider.visible ) sbw = (8*CssUtils.numericScale);
				
				scrollpane2.setWidth( w );
				
				if( itemList2 && itemList2.items ) {
					L = itemList2.items.length;
					for(i=0; i<L; i++) {
						btn = Button( itemList2.items[i] );
						btn.setWidth( w - ( cssBoxX + btn.cssBoxX + sbw ) );
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
			
			if ( backBtn && backBtn.visible ) {
				backBtn.y = itemList1.cssTop;
				h -= backBtn.cssSizeY + backBtn.cssMarginBottom;
			}
			
			if ( branchTitle ) {
				branchTitle.y = itemList1.cssTop;
			}
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
				if ( backBtn && backBtn.visible ) {
					scrollpane1.y = cssTop + backBtn.cssSizeY + backBtn.cssMarginBottom;
				}else{
					scrollpane1.y = cssTop;
				}
			}
			if( scrollpane2 ) {
				scrollpane2.y = scrollpane1.y + cssTop + h1 + newItemLabel.cssSizeY + (2*CssUtils.numericScale);
				scrollpane2.setHeight ( h2 - newItemLabel.height );
				scrollpane2.contentHeightChange();
			}
			if(newItemLabel) {
				newItemLabel.y = scrollpane1.y + cssTop + h1;
				scrollpane2.y += scrollpane2.cssTop + newItemLabel.cssSizeY + newItemLabel.cssMarginBottom;
			}
			if( sizeButton ) {
				sizeButton.y = scrollpane1.y + cssTop + h1;
			}
		}
		
		private var shooting:Boolean = false;
		private var ltFramePos:Number;
		
		private function shootHandler (event:Event) :void
		{
			if ( Math.abs(ltFramePos) > 1.05 ) {
				scrollpane1.slider.value -= ltFramePos;
				scrollpane1.scrollbarChange(null);
				ltFramePos /= 1.15;
			}else{
				removeEventListener( Event.ENTER_FRAME, shootHandler );
				shooting = false;
			}
		}
		
		// area tree click
		private function btnUp (event:MouseEvent) :void
		{
			/*if( event ) {
				event.stopImmediatePropagation();
				event.preventDefault();
			}*/
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
			
			if ( ltFramePos > 9 || ltFramePos < -9 )
			{
				shooting = true;
				addEventListener( Event.ENTER_FRAME, shootHandler );
			}
		}
		private function btnMove (event:MouseEvent) :void {
			var dy:Number = mouseY - clickY;
			
			ltFramePos = dy * 3;
			
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
		/*	if( event ) {
				event.stopImmediatePropagation();
				event.preventDefault();
			}*/
			ltFramePos = 0;
			
			if ( shooting ) {
				removeEventListener( Event.ENTER_FRAME, shootHandler );
				shooting = false;
			}
			
			stage.addEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, btnUp );
			clickScrolling = false;
			clickY = mouseY;
		}
		
		// resizing height 
		private function viewSizeDown (e:MouseEvent) :void {
			if( e ) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}
			if( stage ) {
				stage.addEventListener( MouseEvent.MOUSE_UP, viewSizeUp );
				addEventListener( Event.ENTER_FRAME, viewSizeFrame );
				viewSizeStartY = mouseY;
			}
		}
		private function viewSizeUp (e:MouseEvent) :void {
			if( e ) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}
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
		}
	}
}
