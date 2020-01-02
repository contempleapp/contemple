package ct
{
	import agf.html.*;
	import agf.events.PopupEvent;
	import agf.ui.Button;
	import agf.ui.PopupItem;
	import flash.events.*;
	import agf.ui.Popup;
	import agf.icons.IconArrowDown;
	import agf.tools.Application;
	import flash.filesystem.File;
	
	public class MenuEditor extends CssSprite {

		public function MenuEditor( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
			create();
		}
		
		public var menupp:Popup;
		public var plusButton:Button;
		public var currentMenu:String="";
		
		public function create () :void 
		{
			if(plusButton && contains(plusButton)) removeChild( plusButton );
			
			plusButton = new Button( [ "+" ],0,0,this,this.styleSheet,'','menueditor-plusbutton', false);
			plusButton.addEventListener( MouseEvent.CLICK, plusClick );
			
			if( menupp && contains(menupp) ) removeChild( menupp );
				menupp = null;
			
			//if( currentMenu == "" ) currentMenu = "Main Menu";
			
			menupp = new Popup([ currentMenu ], 0, 0, this, styleSheet, '', 'menueditor-menupopup', false);	
			menupp.addEventListener( PopupEvent.SELECT, menuppChange);
			
			var menus:Array = CTTools.menus;
			for(var i:int =0; i<menus.length; i++) {
				menupp.rootNode.addItem([ menus[i].name ],styleSheet);
			}
			
			if( currentMenu == "" ) {
				if( CTTools.currentMenu == "" ) {
					if( menus.length > 0 ) CTTools.currentMenu = currentMenu = menus[0].name;
				}
			}
			
			//showMenu();
		}
		
		public function showMenu () :void {
			// show current menu
			/*if( currentMenu ) {
				var it:Array = [];
				for(var i:int=0; i<CTTools.menuItems.length; i++) {
					//if(CTTools.menuItems[i].menu
				}
			}*/
		}
		
		private function menuppChange (e:PopupEvent) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			currentMenu = lb;
			menupp.label = lb;
		}
		
		private function plusClick (e:MouseEvent) :void
		{
			// provide item list for new/add item to select to current area
			trace("AddItem to Menu:" + currentMenu);
			
			
		}
	}
	
}
