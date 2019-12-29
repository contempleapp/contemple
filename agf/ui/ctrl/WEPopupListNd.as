package agf.ui.ctrl
{
	import flash.events.Event;
	import flash.geom.Rectangle; 
	import agf.ui.ctrl.UiCtrl;
	import agf.ui.ctrl.WEPopup;
	import agf.ui.ctrl.WEPopupList;
	import agf.ui.ctrl.WEPopupItem;
	
	public class WEPopupListNd extends UiCtrl 
	{
		public function WEPopupListNd (srect:Rectangle) {
			stagerect = srect;
			initialize();
		}
		
		public static var maxDepth:int = 4;
		
		public var stagerect:Rectangle = new Rectangle(0,0,900,500);
		public var pp1:WEPopupList;
		public var pp2:WEPopupList;
		public var pp3:WEPopupList;
		public var pp4:WEPopupList;
		
		public var opened_depth:int=0;
		
		public function initialize () :void {
			if(pp1 == null) {
				pp1 = new WEPopupList();
				addChild(pp1);
			}
			if(pp2 == null) {
				pp2 = new WEPopupList();
				addChild(pp2);
			}
			if(pp3 == null) {
				pp3 = new WEPopupList();
				addChild(pp3);
			}
			if(pp4 == null) {
				pp4 = new WEPopupList();
				addChild(pp4);
			}
			
			pp1.visible = pp2.visible = pp3.visible = pp4.visible =  false;
			pp1.stagerect = stagerect;
			pp2.stagerect = stagerect;
			pp3.stagerect = stagerect;
			pp4.stagerect = stagerect;
		}	
		
		public function closeChilds (dim_id:int) :void {
			if(opened_depth > dim_id) {
				for(var i:int=dim_id+1; i<=maxDepth; i++) {
					if(this["pp"+i].opened)	
						this["pp"+i].removeList();	
				}
				opened_depth = dim_id;
			}
		}
		
		public function showList (ppInst:WEPopup, ppItem:WEPopupItem) :void {	
			
			if(opened_depth >= maxDepth) {
				//throw new Error("WEPopupListNd maxDepth " + maxDepth + " reached");
				return;
			}
			
			var lst:WEPopupList = this["pp"+(opened_depth+1)];
			
			parent.setChildIndex( this, parent.numChildren-1 );
			
			if(lst != null) {
				opened_depth++;
				
				lst.parent.setChildIndex( lst, lst.parent.numChildren-1 );
				ppInst.fireEvent(Event.OPEN, lst, ppItem);
				lst.dim_id = opened_depth;
				lst.createList(ppInst, ppItem);
				lst.showList();
				
				if(opened_depth == 1) {
					// Align on PopupList
					lst.x = WEPopup.list_mc.x + WEPopup.list_mc.getWidth();
					if(lst.x + lst.getWidth() > lst.stagerect.x + lst.stagerect.width) {
						// Align on left side
						lst.x = WEPopup.list_mc.x - lst.getWidth();
					}
				}else{
					// Align on previous list
					var pp:WEPopupList = this["pp"+(opened_depth-1)];
					lst.x = pp.x + pp.getWidth();
					
					if(lst.x + lst.getWidth() > lst.stagerect.x + lst.stagerect.width) {
						// Align on left side
						lst.x = pp.x - lst.getWidth();
					}
				}
			}
		}
		
		public function removeList ():void {
			if(opened_depth > 0) {
				var lst:WEPopupList = this["pp"+opened_depth];
				if(lst != null) {
					lst.removeList();
				}
				opened_depth--;
				if(opened_depth < 0) opened_depth = 0;
			}
		}
		
	}
}