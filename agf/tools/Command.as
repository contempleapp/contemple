package agf.tools
{	
	import agf.tools.Application;
	
	public class Command extends BaseTool
	{
		public static function command (argv:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null) :void 
		{
			// Nothing to do here ...
			// var args:Array = argv2Array(argv);
			// var showIndex:int = args.indexOf( "show" );
			//if( cmdComplete != null) cmdComplete();
			complete( cmdComplete, cmdCompleteArgs);
		}
		
		public static function process ( cmd:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null ) :void
		{
			if(cmd)
			{
				var commands:Array = cmd.split(";");
				var _cmd:String;
				var ed:int;
				var tool:String;
				var text:String;
				var cl:Object;
				
				for( var i:int = 0; i< commands.length; i++ )
				{
					_cmd = commands[i];
					if(_cmd ) {
						ed = _cmd.indexOf(" ");
						
						// Split command name (first word)
						
						tool;
						text = "";
						
						if( ed >= 0 ) {
							tool = _cmd.substring( 0, ed );
							text = _cmd.substring( ed + 1 );
						}else{
							tool = _cmd;
						}
						
						cl = Application.getClass( tool );
						
						if( cl && typeof cl.command == "function" )
						{
							// Found Class object
							// Console.log("Run command: " + cl + ' "' + tool + ' ' + text + '"');
							
							cl.command( text, cmdComplete, cmdCompleteArgs );
						}
						else
						{
							Console.log( "Command not found: " + _cmd);
						}
					}
				}
			}
		}
		
		/*
		public static function getClass ( path:String ) :Object {
			
			var c:Object;
			try {
				c = getDefinitionByName(path);
			}catch(e:Error) {
				c = null;
			}
			if(c == null) 
			{
				if( Application.instance ) 
				{
					var paths:Array = Application.instance.toolPaths;
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
			return c;
		}
		*/
		
	}
	
}
