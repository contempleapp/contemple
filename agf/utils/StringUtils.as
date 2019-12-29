package agf.utils {
	
	public class StringUtils
	{
		public function StringUtils () {}
		
		public static function isWhite (s:String) :Boolean
		{			
			if( !s || s == " " ) return true;
			var L:int = s.length;
			for( var i:int=0; i<L; i++) {
				if( s.charCodeAt(i) > 32 ) {
					return false;
				}
			}
			return true;
		}
		

	}
	
}
