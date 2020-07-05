package agf.utils
{	
	public class NumberUtils
	{
		public static function getUnit (str:String) :String
		{	
			var rv:String="";
			var b:int=-1;
			var c:String;
			
			if(str)
			{
				var L:int = str.length;
				
				for(var i:int=0; i<L; i++) 
				{
					if( str.charCodeAt( i ) <= 32 ) {
						continue;
					}
					if( b == -1 ) {
						c = str.charAt(i);
						if( isNaN(Number(c)) && c != "." ) {
							b = i;
							rv = str.charAt(i);
						}
					}else{
						rv += str.charAt(i);
					}
				}
			}
			
			return rv;
		}
		
		public static function forceNumber (str:String, dp:uint=14) :Number
		{
			if(isNaN(Number(str))) {
				var co:Number = 0;
				var min:Boolean = false;
				dp = dp > 0 ? dp : 14;
				var a:int;
				var c:String;
				var s2:String = "";
				var l:int = str.length;
				for( var i:int=0; i<l; i++) {
					c = str.charAt(i);
					a = str.charCodeAt(i);
					if( (a >= 48 && a <= 57) || (a == 45 && min==false) ) {
						if(a==45) min = true;
						s2 += c;
						if(co > 0) co++;
					}
					else if(co==0) {
						if(a==46) {
							s2 += c;
							co = 1;
						}else if(a==44){
							s2 += ".";
							co = 1;
						}
					}
					if(co >= dp) break;
				}
				return Number(s2);
			}
			else{
				return Number(str);
			}
		}
		
	}
}
