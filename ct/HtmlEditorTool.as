package  ct {
	import agf.tools.BaseTool;
	import flash.display.Sprite;
	import agf.Main;
	import agf.tools.Application;
	
	public class HtmlEditorTool extends BaseTool {

		public static function command (argv:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null) :void 
		{
			var args:Array = argv2Array(argv);
			
			var ind:int = args.indexOf( "newproject" );
			if( ind >= 0 ) {
				var nameUid:String = args.length > ind+2 ? args[ ind+2 ] : "";
				var path:String = args.length > ind+3 ? args[ ind+3 ] : "";
				
				newProject ( nameUid, path );
			}
			complete( cmdComplete, cmdCompleteArgs );
		}
		
		private static var newProjectName:String="";
		
		public static function newProject ( nameUid:String="", path:String="" ):void {
			
			if( !nameUid )
			{
				var mn:Main = Main( agf.tools.Application.instance );
				var cb:Object = {
					complete: function (projectName:String) :void {
						trace( projectName);
						newProjectName = projectName;
					}
				}
				mn.window.GetStringWindow ( "inset_path", "Project Name", "Enter a name for the new project", cb, "");
				return;
			}
			
			if( !path ) {
				
				// Get Folder path for new project
				
				
			}
		
		}
		
	}
	
}
