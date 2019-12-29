package agf.events
{

	import flash.events.Event;
	
	public class AppEvent extends Event
	{
		/**
		* Dispatched after the Application has been setup and initialized
		*/
		public static var START:String = "start";
		
		/**
		* Dispatched before the Application is setup and when
		* the Application is restarted.
		* Containers and values can be null or undefined
		* In case of a restart one can use this event
		* to clear up everything
		*/
		public static var SETUP:String = "setup";
		
		
		/**
		* Dispatched right after the main menu, top and window containers
		* have been created, but not fully loaded/initialized
		* Use this Event to display graphics very early on app load
		* Otherwise better use the START Event when erverything is loaded..
		**/
		public static var CREATE:String = "create";
		
		public static var VIEW_CHANGE:String = "view-change";
		public static var VIEW_CHANGED:String = "view-changed";
		
		
		public function AppEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type,bubbles,cancelable);
		}
	}
}