package agf.ui.ctrl 
{
	import flash.events.Event;
	import agf.ui.ctrl.WEPopup;
	import agf.ui.ctrl.WEPopupList;
	import agf.ui.ctrl.WEPopupItem;
	
	public class WEPopupEvent extends Event 
	{
		public var currentPopup:WEPopup;
		public var currentList:WEPopupList;
		public var currentItem:WEPopupItem;
		
		public function WEPopupEvent (type:String, pp:WEPopup, list:WEPopupList, item:WEPopupItem) 
		{
			super(type);
			currentList = list;
			currentPopup = pp;
			currentItem = item;
		}
	}
	
}