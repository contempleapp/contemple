package agf.tools
{	
	public class BaseTool
	{
		public static function argv2Array (argv:String) :Array 
		{
			return argv.split(" ");
		}
		
		/**
		* returns the end of an Array as text line with
		*/
		public static function arrStringFrom (arr:Array, i:int=0) :String 
		{
			var s:String = "";
			if(arr && arr.length >= i) 
			{
				while( i < arr.length-1 ) {
					s += arr[i] + " ";
					i++;
				}
				s += arr[arr.length-1];
			}	
			return s;
		}
		
		public static function complete (cmdComplete:Function=null, cmdCompleteArgs:Array=null) :void
		{
			if ( cmdComplete != null )
			{
				if( cmdCompleteArgs != null) {
					cmdComplete.apply(null, cmdCompleteArgs);
				}else{
					cmdComplete();
				}
			}
		}
		
	}
}