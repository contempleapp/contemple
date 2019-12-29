package  agf.ui {
	import flash.display.Sprite;
	
	public interface WindowsController {

		// Interface methods:
		
		// Empty window with body CssSprie */
		function ContentWindow ( nameUid:String, title:String="", content:Sprite=null, options:Object=null, cssClass:String="" ) :Sprite;
		
		/** Events: complete( void ) */
		function InfoWindow ( nameUid:String, title:String="", msg:String="", options:Object=null, cssClass:String="" ) :Sprite;
		
		/** Events: complete( Boolean ) */
		function GetBooleanWindow ( nameUid:String, title:String="", msg:String="", options:Object=null, cssClass:String="" ) :Sprite;
		
		/** Events: complete( String ) */
		function GetStringWindow ( nameUid:String, title:String="", msg:String="", options:Object=null, cssClass:String="" ) :Sprite;
		
		/** Create and return a empty window */
		function CreateWindow ( nameUid:String, title:String, options:Object=null, cssClass:String="" ) :Window;
		
	}
	
}
