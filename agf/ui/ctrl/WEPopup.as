package agf.ui.ctrl
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.geom.Rectangle;
	
	import agf.tools.Application;
	import agf.ui.ctrl.UiCtrl;
	import agf.ui.ctrl.WEPopupEvent;
	import agf.ui.ctrl.WEPopupItem;
	import agf.ui.ctrl.WEPopupList;
	import agf.icons.TriDown;
	import flash.display.Stage;
	
	dynamic public class WEPopup extends WEButton 
	{	
		public function WEPopup () {
			initialize();
		}
		
		public static var popup_list_nd:WEPopupListNd=null;
		public static var popup_list:WEPopupList=null;
		
		public static function prepare ( stage:Stage, topContent:Sprite ) :void {
		
			if(popup_list != null) {
				if(topContent.contains(popup_list)) topContent.removeChild( popup_list );
			}
			if(popup_list_nd != null) {
				if(topContent.contains(popup_list_nd)) topContent.removeChild( popup_list_nd );
			}
			popup_list = null;
			popup_list_nd = null;
			
			popup_list = new WEPopupList();
			popup_list.stagerect = new Rectangle(0,0, stage.stageWidth, stage.stageHeight);
			
			popup_list_nd = new WEPopupListNd(popup_list.stagerect);
			
			WEPopupList.popup_list_nd = popup_list_nd;
			WEPopup.list_mc = popup_list;
			
			topContent.addChild( popup_list );
			topContent.addChild( popup_list_nd );
			
		}
		
		public var rootNode:WEPopupItem;
		public var selectedItem:WEPopupItem;
		public var selectedLabel:String;
		
		public static var list_mc:WEPopupList;
		
		public var borderLeft:int=2;
		public var borderTop:int=1;
		public var borderRight:int=2;
		public var borderBottom:int=1;
		
		public var maxScrollHeight:int=390;
		public var maxScrollItem:int=7;
		public var mouseIsOver:Boolean=false;
		
		public function get opened () :Boolean { return rootNode.opened; }
		
		public override function initialize () :void {
			super.initialize();
			
			label = "";
			
			if(rootNode == null) {
				rootNode = new WEPopupItem();
				rootNode.label = label;
			}
			if(selectedItem == null)
				selectedItem = rootNode;
			
			addEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			
			scaleY = 1;
			scaleX = 1;
			
			iconPos = "right";
			icon = new TriDown();
		}
		
		public function assignXml (xo:XML) :void 
		{
			rootNode.assignXml(xo);
		}
		
		public function closeList (currItem:*) :void 
		{
			if(currItem != null && currItem is WEPopupItem) {
				if(currItem.sel_id >= 0) {
					selectedItem = currItem;
					selectedLabel = selectedItem.items[selectedItem.sel_id].label;
					
					fireEvent( Event.SELECT, list_mc, selectedItem.items[selectedItem.sel_id] );
				}else{
					selectedItem = null;
				}
			}else{
				selectedItem = null;
			}
			
			focusOut();
			
			WEPopupList.popup_list_nd.closeChilds(0);
			list_mc.removeList();
			
			
			addEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			
			if(stage != null)
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, closeHandler);
			
			fireEvent( Event.CLOSE, list_mc, selectedItem == null ? null : selectedItem.items[selectedItem.sel_id] );
			
		}
		
		public function fireEvent (type:String, list:WEPopupList, item:WEPopupItem) :void {
			dispatchEvent( new WEPopupEvent(type, this, list, item) );
		}
		
		public function openList (px:*=undefined, py:*=undefined, scrollStart:int=-1) :void {
			if(list_mc.opened) {
				list_mc.removeList();
			}
			
			mouseIsOver = true;
			if(rootNode != null && rootNode.items != null && rootNode.items.length > 0) {
				
				fireEvent(Event.OPEN, list_mc, rootNode);
				removeEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
				
				selectedItem = rootNode;
				var curr_id:int = selectedItem.sel_id;
				
				if(list_mc.createList(this, rootNode)) {
					list_mc.showList(px,py,scrollStart);
					list_mc.selectCurrent();
				}
				if(stage) {
					stage.addEventListener(MouseEvent.MOUSE_DOWN, closeHandler);
				}
			}
		}
		
		private function closeHandler (e:Event) :void {
			if(!mouseIsOver) {
				closeList(null);
			}
		}
		
		public function addPopupItem (_label:String, shortcut:String="", data:*=null) :WEPopupItem {
			if(rootNode == null) {
				rootNode = new WEPopupItem();
				rootNode.label = label;
			}
			return rootNode.addPopupItem(_label, shortcut, data);
		}
		
		public function clearList () :void {
			var scroll:int=rootNode.scrollStart;
			rootNode = new WEPopupItem();
			rootNode.label = label;
			rootNode.scrollStart = scroll;
		}
		
		private function clickHandler (event:MouseEvent) :void {
			focusIn();
			openList();
		}
		
		private function hasIcon(pos:String) :Boolean {
			var ic:* = this["icon"+pos.charAt(0).toUpperCase()];
			if(ic != null && contains(ic)) {
				return true;
			}
			return false;
		}
		
	}
}