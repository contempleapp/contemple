package agf.ui
{
	import flash.events.*;
	import agf.Options;
	import agf.events.MenuEvent;
	import agf.events.PopupEvent;
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.io.Resource;
	import agf.utils.StrVal;
	import agf.html.CssUtils;
	import agf.Main;
	import agf.ui.Language;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import agf.icons.IconFromFile;
	import agf.tools.Application;
	import agf.icons.IconArrowDown;
	import agf.icons.IconArrowUp;
	import agf.icons.IconArrowLeft;
	import agf.icons.IconArrowRight;
	
	public class Menu extends ItemBar
	{
		public function Menu (w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false) 
		{
			super( w, h, parentCS, style, cssId, cssClasses, true );
			nodeName = "menu";
			
			// embed some icons
			var icoFile:IconFromFile;
			var icoLeft:IconArrowLeft;
			var icoRight:IconArrowRight;
			
			if(!noInit) init();
		}
		
		public var autoIconColor:Boolean = true;
		public var iconColor:uint=0;
		
		private var _activated:Boolean = false;
		private var currPP:Popup;
		
		public override function setWidth (w:int) :void {
			super.setWidth(w);
			
			if( fluid )
			{
				// stretch root items..
				if( items ) {
					var L =  items.length;
					if( L > 0 ) {
						var pps:int=0;
						var ppw:int=0;
						for(var i:int=0; i<L; i++) {
							if( ! items[i].fluid ) { 
								pps++;
								ppw += Button(items[i]).cssSizeX;
								
							}
						}
						
						var s:Number = Math.floor(((w-ppw)-_parentNode.cssBoxX) / (L-pps));
						
						for(i=0; i<L; i++) {
							if( !(items[i] is Popup) ) {
								items[i].setWidth(s- items[i].cssBoxX);
							}
						}
						format(true);
					}
				}
				if( activeRootItem && activeRootItem.state != "active" ) activeRootItem.swapState("active");
			}
		}
		
		public function parseMenu (x:XML, itemClass:String) :void 
		{
			clearAllItems();
			
			var csp:int = 4;
			
			if( x.menu.@mode != undefined ) fluid = String(x.menu.@mode.toString()).toLowerCase() == "fluid" ? true : false;
			if( x.menu.@clipspacing != undefined ) csp = Number(x.menu.@clipspacing.toString());
			
			var n:XMLList = x.menu.item;
			var c:Button;
			
			if( autoIconColor )
			{
				// Use Button font color for icon coloring
				c = new Button(null,0,0,this,styleSheet,'',itemClass);
				var cs:Object = styleSheet.getMultiStyle( c.stylesArray );
				removeChild( c );
				if( cs.color ) {
					iconColor = CssUtils.stringToColor( cs.color );
				}
			}
			
			for(var i:int=0; i<n.length(); i++) 
			{
				if( n[i].children().length() > 0)
				{
					c = new Popup( getButtonIcons(n[i]), 0, 0, this, styleSheet, '', itemClass );
					c.clipSpacing = csp;
					
					currPP = Popup(c);
					currPP.blockBackground = false;
					currPP.alignV = alignV; // popup-aligning 
					currPP.alignH = alignH; // popup-aligning 
					if( n[i].@mode != undefined ) currPP.fluid = n[i].@mode == "fluid" ? true : false;
					else currPP.fluid = true;
					
					addMenuList( currPP.rootNode, n[i].children(), itemClass );
					c.addEventListener( Event.SELECT, itemSelect );
					c.addEventListener( Event.CLOSE, closeHandler );
					c.addEventListener( Event.OPEN, openHandler );
				}
				else
				{
					c = new Button( getButtonIcons(n[i]), 0, 0, this, styleSheet, '', itemClass );
					c.autoSwapState = "active";
					
					c.clipSpacing = csp;
					if(n[i].@cmd != undefined) c.options.cmd = StrVal.getval(n[i].@cmd);
					var ic:DisplayObject;
					if( n[i].@mode != undefined ) c.fluid = n[i].@mode == "fluid" ? true : false;
					else c.fluid = true;
					
					if( n[i].@icontop != undefined ) {
						ic = getIcon( n[i].@icontop );
						if( ic ) c.iconTop = Sprite(ic);
					}
					if( n[i].@icontopalign != undefined ) c.iconTopAlign = String(n[i].@icontopalign);
					
					if( n[i].@iconbottom != undefined ) {
						ic = getIcon( n[i].@iconbottom );
						if( ic ) c.iconBottom = Sprite(ic);
					}
					if( n[i].@iconbottomalign != null ) c.iconBottomAlign = String(n[i].@iconbottomalign);
					
					c.addEventListener( MouseEvent.CLICK, itemSelect );
				}
				
				c.addEventListener( MouseEvent.MOUSE_DOWN, itemDown );
				c.addEventListener( MouseEvent.CLICK, itemClick );
				c.addEventListener( MouseEvent.MOUSE_OVER, itemOver );
				
				addItem(c, true);
			}
			
			format(true);
		}
		
		private function getButtonIcons ( nd:XML ) :Array {
			var icons:Array;
			var icons_right:Array;
			
			icons = parseIconList( nd, "iconleft" );
			icons_right = parseIconList( nd, "iconright" );
			
			icons.push( Language.getKeyword( StrVal.getval( nd.@name ) ) ); // Label
			for( var i:int =0; i< icons_right.length; i++) {
				icons.push( icons_right[i] );
			}
			return icons;
		}
		
		private function getIcon ( str:String ) :DisplayObject {
			var obj:*;
			try {
				obj = Application.getClass( str );
			}catch(e:Error) {
				obj = null;
			}
			if( obj ) {
				// Instanciate icon
				return new obj(iconColor);
			}else{
				try {
					obj = Application.instance.strval( str, true );
				}catch(e:Error) {
					obj = null;
				}
				if( obj is DisplayObject ){
					return DisplayObject(obj);
				}else{
					// Load Icon
					if( str.substring(0, 5) == "ico:/" )
					{
						str = Options.iconDir + "/" + str.substring(5);
					}
					return new IconFromFile(str, Options.iconSize, Options.iconSize);
				}
			}
			return null;
		}
		
		private function parseIconList ( nd:XML, listname:String ) :Array {
			var list_str:String = nd.attribute(listname).toString();
			var rv:Array = [];
			
			if( list_str )
			{
				var list:Array = list_str.split(",");
				var L:int = list.length;
				var obj:DisplayObject;
				var str:String;
				
				for(var i:int=0; i<L; i++)
				{
					str = CssUtils.trim( list[i] );
					obj = getIcon( str );
					if( obj ) {
						rv.push(obj);
					}
				}
			}
			
			return rv;
		}
		
		public function addMenuList (c:PopupItem, n:XMLList, itemClass:String) :void
		{
			var L:int = n.length();
			var it:PopupItem;
			var icons:Array;
			var btico:Array;
			
			for( var i:int=0; i<L; i++)
			{				
				if( n[i].children().length() > 0) {
					btico = getButtonIcons( n[i] );
					btico.push( new IconArrowRight( iconColor ) );
					it = c.addItem( btico, styleSheet );
					addMenuList( it, n[i].children(), itemClass );
				}else{
					it = c.addItem( getButtonIcons( n[i] ), styleSheet );
				}
				
				if(n[i].@cmd != null) it.options.cmd = StrVal.getval(n[i].@cmd);
				it.nodeClass = itemClass;
			}
		}
		
		private function itemSelect (e:Event) :void {
			_activated = false;
			var lb:String;
			var ctl:Ctrl;
			if(e is PopupEvent) {
				ctl = PopupEvent(e).selectedItem;
				lb = PopupEvent(e).selectedItem.label;
			}else{ // button
				ctl = Button(e.currentTarget);
				lb = Button(e.currentTarget).label;
			}
			dispatchEvent( new MenuEvent( Event.SELECT, lb, ctl.options.cmd) );
		}
		
		private function itemDown (e:Event) :void {
			if(e.currentTarget is Popup) {
				_activated = true;
			}
			else {
				// button in root level
				var it:Button;
				
				// close all
				for(var i:int=0; i<items.length; i++) {
					it = Button(items[i]);
					if( !(it is Popup) ) {
						if(it.state != "normal") it.swapState("normal");
					}
				}
				it  = Button(e.currentTarget);
				if(it.state != "active") it.swapState("active");
			}
		}
		private var activeRootItem:Button;
		
		private function itemClick (e:Event) :void
		{
			if( e.currentTarget is Popup ) {
				if(activeRootItem && activeRootItem.state != "active") activeRootItem.swapState("active");
			}else{
				// button in root level
				var it:Button;
				
				// close all
				for(var i:int=0; i<items.length; i++) {
					it = Button(items[i]);
					if( !(it is Popup) ) {
						if(it.state != "normal") it.swapState("normal");
					}
				}
				
				it  = Button(e.currentTarget);
				activeRootItem = it;
				if(it.state != "active") it.swapState("active");
			}
		}
		private function closeMenu (e:Event) :void {
			_activated = false;
		}
		private function closeHandler (e:Event) :void {
			if(stage) stage.removeEventListener( MouseEvent.MOUSE_DOWN, closeMenu );
			if( hasEventListener( Event.CLOSE) ) dispatchEvent(e);
		}
		private function openHandler (e:Event) :void {
			if( hasEventListener( "open" ) ) {
				dispatchEvent( e );
			}
			if(stage) stage.addEventListener( MouseEvent.MOUSE_DOWN, closeMenu );
		}
		private function itemOver (e:Event) :void 
		{
			if(_activated) 
			{
				var it:Button = Button(e.currentTarget);
				
				if(it is Popup ) {
					if(Popup(it).opened) {
						return;
					}
				}else{
					return;
				}
				// close all
				for(var i:int=0; i<items.length; i++) {
					if( items[i] is Popup && Popup(items[i]).opened) {
						Popup(items[i]).closeListFrom(0);
						Popup(items[i]).close();
					}
				}
				if(it is Popup) {
					Popup(it).open();
				}
			}
		}
	}
}