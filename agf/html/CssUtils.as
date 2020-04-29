package agf.html
{
    import agf.utils.StringMath;
    import ct.ctrl.VectorTextField;
	import flash.display.DisplayObject;
	import flash.system.Capabilities;
    import flash.text.*;
    import agf.tools.Console;
    
	public class CssUtils
	{
		public function CssUtils() {}
		
		public static var numericScale:Number = 1;
		
		// trim " and ' from the beginning and end of a string
		public static function trimQuotes (s:String="") :String 
		{
			if(s && s.length > 1) {
				if( (s.charCodeAt(0) == 34 && s.charCodeAt(s.length-1) == 34) || (s.charCodeAt(0) == 39 && s.charCodeAt(s.length-1) == 39) ) 
				{
					return s.substring(1, s.length-1);
				}
				else if( s.charCodeAt(s.length-1) == 34 || s.charCodeAt(s.length-1) == 39)
				{
					return s.substring(0, s.length-1);
				}
				else if ( s.charCodeAt(0) == 34 ||  s.charCodeAt(0) == 39 )
				{
					return s.substring(1, s.length);
				}
			}
			return s;
		}
		
		
		public static function initScreenDpi () :void
		{
			// 72 DPI = 1
			// 240 DPI = 1.6
			// 320 DPI = 2.5
			if( flash.system.Capabilities.screenDPI > 96 )
			{
				numericScale = flash.system.Capabilities.screenDPI / 72 / 2;
			}
			else
			{
				numericScale = 1;
			}
			
			// trace("SCREEN DPI: " +  flash.system.Capabilities.screenDPI + ", scale: " + numericScale );
		}
		
		// trim whitespace from the beginning, end, and duplicate whitespace of a string
		public static function trim (e:String) :String {
			var str:String = "";
			var i:int;
			var igstart:int=0;
			
			for(i=0; i<e.length; i++) {
				if(e.charCodeAt(i) > 32) {
					igstart = i;	
					break;	
				}
			}
			if(igstart > 0) e = e.substring(igstart, e.length);
			
			str = e.charCodeAt(e.length-1) <= 32 ? "" : e.charAt(e.length-1);
			for(i=e.length-2; i>=0; i--) {
				if(e.charCodeAt(i) > 32 || e.charCodeAt(i+1) > 32) {
					str = e.charAt(i) + str;
				}
			}
			
			return str;
		}
		
		// convert a css string to a boolen (the strings: 1, yes or true will convert to true)
		public static function stringToBool (s:String) :Boolean {
			return (s === "1" || s.toLowerCase() === "true" || s.toLowerCase() === "yes");
		}
		
		
		/**
		 *	Returns the numeric value of a html color string <br/>
		 * 	The string should be trimmed with trim
		 *	#F00, #FF0000 returns the number for full red
		 *	rgb(255,255,255) returns the number for white
		 */
		public static function stringToColor (str:String) :int 
		{
			// *** Uncommented cause rarely used, css default color values: red, green, blue, black etc
			// *** Uncomment all this comments in this file to add support:
			//
			// if( defaultColors[str] ) return defaultColors[str];
			//
			
			if(str.charAt(0)/*.toLowerCase()*/ === "r")
			{
				// rgb(0,0,0)
				var op:int = str.indexOf( "(", 0 );
				if(op == -1) return 0;
				
				var cl:int = str.indexOf(")", op);
				if(cl == -1) cl = str.length;
				if(op >= cl) return 0;
				
				var arr:Array = str.substring(op+1, cl).split(",");				
				cl = arr.length;
				
				var rv:int = 0;
				if(cl >= 4) rv = int(arr[4]) << 24 // Alpha #ff996633
				if(cl >= 1) rv |= int(arr[0]) << 16 
				if(cl >= 2) rv |= int(arr[1]) << 8 
				if(cl >= 3) rv |= int(arr[2]);
				
				return rv;
			}
			else
			{
				if(str.length == 4) { // Parse html color shortcut #FFF 
					str = str.charAt(0) + str.charAt(1) + str.charAt(1) + str.charAt(2) + str.charAt(2) + str.charAt(3) + str.charAt(3);
				}
				return parseInt( "0x" + str.substring(1) );
			}
		}
		
		public static function isColor (str:String) :Boolean
		{
			// *** Uncommented color names cause rarely used, css default color values: red, green, blue, black etc
			// *** Uncomment all this comments in this file to add support:
			//
			//return ( str.indexOf("#") != -1 || str.indexOf("rgb(") != -1);
			return (/*defaultColors[str] != null || */ str.charAt(0) == "#" || str.substring(0,4) == "rgb(");
		}
        
		private static var tf:TextField;
		private static var fmt:TextFormat;
		
        // return unquoted first font family from the list
		public static function parseFontFamily ( font:String ) :String {
			if( font )
            {
				var c:int = font.indexOf(",");
                
				if( c >= 0 ) {
                    var fonts:Array = font.split(",");
                    var f:String;
                    for( var i:int=0; i<fonts.length; i++ ) {
                        f = trimQuotes(trim(fonts[i]) );
                        if( TextField.isFontCompatible( f, FontStyle.REGULAR ) ) {
                            return f;
                        }
                    }
                    
					return font;
				}
			}
			return font;
		}
		
		/**
		* Parse css values:
		*	Boolean: true, false, yes, no
		*	Color: #FFF, #FFFFFF, rgb(255,255,255)
		*	Numeric: px, em, %, numeric
		*	
		*/
		public static function parse (v:*, container:DisplayObject=null, hv:String="h") : * {
			if(v is String) 
			{
				if(isNaN(Number(v))) 
				{
					v = trim(v);
					
					if( v==="true" || v==="yes") return true
					else if( v==="false" || v==="no") return false;
					
					// *** Uncommented color names cause rarely used, css default color values: red, green, blue, black etc
					// *** Uncomment all this comments in this file to add support:
					//
					// if(defaultColors[v] != null) return defaultColors[v];
					//
					
					if(v.charAt(0) === "#" || v.substring(0,4).toLowerCase() == "rgb(") return stringToColor(v);
					
					var nm:String = "";
					var unit:String = "";
					var c:String;
					
					// Parse px, em and % Numbers
					for(var i:int=0; i < v.length; i++) {
						if(v.charCodeAt(i)>32) {
							c = v.charAt(i);
							if(c != "." && isNaN(Number(c))) unit += c;
							else nm += c;
						}
					}
					
					switch( unit ) {
						case "px":
						case "pt":
							v = Number( nm );
							break;
						case "em":
						case "rem":
							// TODO calculate em vales
							v = Number( nm ) * numericScale * 0.567;
							break;
						case "%":
							if(container) {
								var o:Object = Object(container);
								return ( hv === "v" ? (o.cssHeight || o.height) : (o.cssWidth || o.width) ) * ( Number(nm)/100 );
							} 
							break;
					}
				}
				else
				{
					v = Number(v);
				}
			}
			
			return v;
		}
		
		// *** Uncommented color names cause rarely used, css default color values: red, green, blue, black etc
		// *** Uncomment all this comments in this file to add support
		/*
		public static var defaultColors:Object = 
		{
			white: 		0xFFFFFF,
			black:		0x000000,
			gray:		0x999999,
			red: 		0xCC0000,
			green: 		0x00CC00,
			blue: 		0x0000CC
		}
		*/
		
	}
}