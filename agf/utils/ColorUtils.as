package agf.utils {
	
	public class ColorUtils
	{
		private static var strcol:Object={};
		
		public static function colorToString (col:uint, hex:Boolean=true) :String
		{
			var rv:String = "";
			
			getRGBComponents( col, strcol );
			
			if( hex ) {
				if(strcol.r < 16 ) rv += "0"+ strcol.r.toString(16);
				else rv += strcol.r.toString(16);
				
				if(strcol.g < 16 ) rv += "0"+ strcol.g.toString(16);
				else rv += strcol.g.toString(16);
				
				if(strcol.b < 16 ) rv += "0"+ strcol.b.toString(16);
				else rv += strcol.b.toString(16);
			}else{
				rv = "" + strcol.r + ","+strcol.g+","+strcol.b;
			}
			
			return rv;
		}
		
		public static function getRGBComponents (_color:uint, rv:Object) :void
		{
			rv.r = (_color >> 16 & 255);
			rv.g = (_color >> 8 & 255);
			rv.b = (_color & 255);
		}
		
		public static function getRGBAComponents (_color:uint, rv:Object) :void
		{
			rv.a = (_color >> 24 & 255);
			rv.r = (_color >> 16 & 255);
			rv.g = (_color >> 8 & 255);
			rv.b = (_color & 255);
		}
		
		public static function combineRGB ( r:uint, g:uint, b:uint ) :uint
		{
			if( r > 255 ) r = 255;
			if( g > 255 ) g = 255;
			if( b > 255 ) b = 255;
			
			var rv:uint = r << 16;
			rv |= g << 8;
			rv |= b;
			return rv;
		}
		
		public static function combineRGBA ( r:uint, g:uint, b:uint, a:uint ) :uint
		{				
			if( r > 255 ) r = 255;
			if( g > 255 ) g = 255;
			if( b > 255 ) b = 255;
			if( a > 255 ) a = 255;
			
			var rv:uint = a << 24;
			rv |= r << 16 ;
			rv |= g << 8;
			rv |= b;
		
			return rv;
		}
	}
	
}

