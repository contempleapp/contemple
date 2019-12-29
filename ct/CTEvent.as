package agf.events
{
	import flash.events.Event;
	
	import agf.ui.Popup;
	import agf.ui.PopupItem;
	
	public class PopupEvent extends Event
	{
		public static const SELECT:String="select";
		
		public function PopupEvent(pp:Popup, selitem:PopupItem, type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type,bubbles,cancelable);
			currentPopup = pp;
			selectedItem = selitem;
		}
		
		public var currentPopup:Popup;
		public var selectedItem:PopupItem;
	}
}