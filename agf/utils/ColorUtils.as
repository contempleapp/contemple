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
		
		public static function saturation ( col:Object, _multiplier:Number = 1 ) :uint
		{
			var hsb:Object = RGBtoHSV( col.r, col.g, col.b );
			
			var v:Number;
			var s:Number;
			
			if( _multiplier >= 1 ) {
				s = hsb.s * _multiplier;
				v = hsb.v * _multiplier;
			}else{
				s = hsb.s * _multiplier;
				v = hsb.v;
			}
			
			if ( v > 100 ) v = 100;
			else if ( v < 0) v = 0;
			
			if ( s > 100 ) s = 100;
			else if ( s < 0) s = 0;
			
			return HSVtoRGB( hsb.h, s, v );
		}
		
		public static function lightness ( col:Object, _multiplier:Number = 1 ) :uint
		{
			var hsb:Object = RGBtoHSV( col.r, col.g, col.b );
			var v:Number;
			var s:Number;
			
			if( _multiplier >= 1 ) {
				s = hsb.s / _multiplier;
				v = hsb.v * _multiplier;
			}else{
				s = hsb.s;
				v = hsb.v * _multiplier;
			}
			
			if ( v > 100 ) v = 100;
			else if ( v < 0) v = 0;
			if ( s > 100 ) s = 100;
			else if ( s < 0) s = 0;
			
			return HSVtoRGB( hsb.h, s, v);
		}
		
        /**
         * Converts RGB values to HSV values.
         * @param r: A uint from 0 to 255 representing the red color value.
         * @param g: A uint from 0 to 255 representing the green color value.
         * @param b: A uint from 0 to 255 representing the blue color value.
         * @return Returns an object with the properties h, s, and v defined.
         */
        public static function RGBtoHSV( r:uint, g:uint, b:uint ):Object
        {
            var max:uint = Math.max( r, g, b );
            var min:uint = Math.min( r, g, b );
            
            var hue:Number = 0;
            var saturation:Number = 0;
            var value:Number = 0;
            
            //get Hue
            if( max == min )
                hue = 0;
            else if( max == r )
                hue = ( 60 * ( g - b ) / ( max - min ) + 360 ) % 360;
            else if( max == g )
                hue = ( 60 * ( b - r ) / ( max - min ) + 120 );
            else if( max == b )
                hue = ( 60 * ( r - g ) / ( max - min ) + 240 );
            
            //get Value
            value = max;
            
            //get Saturation
            if(max == 0){
                saturation = 0;
            }else{
                saturation = ( max - min ) / max;
            }
            
            var hsv:Object = {};
            hsv.h = Math.round(hue);
            hsv.s = Math.round(saturation * 100);
            hsv.v = Math.round(value / 255 * 100);
            return hsv;
        }
		
		 /**
         * Converts HSV values to RGB values.
         * @param h: A uint from 0 to 360 representing the hue value.
         * @param s: A uint from 0 to 100 representing the saturation value.
         * @param v: A uint from 0 to 100 representing the lightness value.
         * @return Returns an object with the properties r, g, and b defined.
         */
        public static function HSVtoRGB( h:Number, s:Number, v:Number ):uint
        {
            var r:Number = 0;
            var g:Number = 0;
            var b:Number = 0;
            
            var tempS:Number = s / 100;
            var tempV:Number = v / 100;

            var hi:int = Math.floor(h/60) % 6;
            var f:Number = h/60 - Math.floor(h/60);
            var p:Number = (tempV * (1 - tempS));
            var q:Number = (tempV * (1 - f * tempS));
            var t:Number = (tempV * (1 - (1 - f) * tempS));

            switch(hi){
                case 0: r = tempV; g = t; b = p; break;
                case 1: r = q; g = tempV; b = p; break;
                case 2: r = p; g = tempV; b = t; break;
                case 3: r = p; g = q; b = tempV; break;
                case 4: r = t; g = p; b = tempV; break;
                case 5: r = tempV; g = p; b = q; break;
            }
			return (Math.round( r * 255 ) << 16 | Math.round( g * 255 ) << 8 | Math.round( b * 255 ));
        }
	}
}
