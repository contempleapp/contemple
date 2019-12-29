package agf.tools
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	import flash.display.Sprite;
	
	public class Application extends BaseTool
	{
		private static var _instance:Object;

		/**
		* Access the application
		**/
		public static function get instance () :Object {
			return _instance;
		}
		
		/**
		*	Command: Application
		*	Args: start | quit 
		*/
		public static function command ( argv:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null ) :void 
		{
			if( argv.indexOf( "quit" ) >= 0 ) 
			{
				// Command: Application quit
				var e:Error;
				try {
					getClass("flash.desktop.NativeApplication").nativeApplication.exit(0);
				}
				catch(e:Error) {
					Console.log( "Error: Native_app: " + e.name + ": " + e.message );
				}
			}
			
			if(_instance) {
				
				if( argv.indexOf( "start" ) >= 0 ) {
					// Command: "Application start"
					_instance.setupApp();
					return;
				}
				
				var args:Array = argv2Array( argv );
				
				var viewIndex:int = args.indexOf( "view" );				
				if( viewIndex >= 0 ) {
					// Command: Application view ViewName
					var s:String = arrStringFrom( args, viewIndex + 1 );
					
					if( s != "" ) {
						_instance.view.setView( s );
						_instance.setSize( _instance.stage.stageWidth, _instance.stage.stageHeight );
					}
				}
			}
			
			complete( cmdComplete, cmdCompleteArgs);
		}
		
		/**
		* Returns the class of a corresponding string if available or null
		* Example:
		* var aclass:MyCtrl = MyCtrl( Application.getClass( "agf.ui.MyCtrl" ) );
		* var myCtrl:MyCtrl = new aclass();
		**/
		public static function getClass ( path:String ) :Object {
			
			var c:Object;
			var e:Error;
			
			try {
				c = getDefinitionByName(path);
			}catch(e:Error) { 
				c = null;
			}
			
			if(c == null) 
			{
				if( _instance && _instance.toolPaths) 
				{
					var paths:Array = _instance.toolPaths;
					
					if( paths )
					{
						for(var i:int=0; i<paths.length; i++) {
							try {
								c = getDefinitionByName(paths[i] + "." + path);
								break;
							}catch(e:Error) {
								c = null;
							}
						}
					}
				}
			}
			
			return c;
		}
		
		public static function init (app:Object) :Object {
			_instance = app;
			return app;
		}
		
	}
}