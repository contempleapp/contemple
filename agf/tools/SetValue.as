package  agf.tools 
{
	import agf.tools.BaseTool;
	import agf.tools.Application;
	import agf.html.CssUtils;
	
	public class SetValue extends BaseTool
	{
		// Interface methods:
		public static function command ( argv:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null ) :void 
		{
			var args:Array = argv2Array( argv );
		
			// Command: Application set variable value
			var vartype:String = args[0] || "";
			var varname:String = args[1] || "";
			var value:String = args[2] || "";
			
			if( vartype && varname )
			{
				var pt:int = varname.lastIndexOf(".");
				
				if( pt >= 0 ) 
				{
					var tar:String = varname.substring(0, pt);
					var prop:String = varname.substring( pt+1 );
					var obj:* = Application.getClass( tar );
					if(!obj) obj = Application.instance.strval(tar, true );
					
					if( obj ) {
						switch( vartype ) {
							case "Boolean":
								obj[ prop ] = (value === "1" || value === "true");
								break;
							case "Number":
								obj[ prop ] = Number(value);
								break;
							case "String":
								obj[ prop ] = value;
								break;
							case "Object":
								obj[ prop ] = Application.instance.strval( value, true );
								break;
							case "Class":
								obj[ prop ] = new (Application.getClass(value))();
								break;
							case "CssValue":
								obj[ prop ] = CssUtils.parse(value);
								break;
						}
					}
					else{
						Console.log( "SetValue::Target not found: " + tar);
					}
				}
			}
			complete( cmdComplete, cmdCompleteArgs );
		}
	}
}