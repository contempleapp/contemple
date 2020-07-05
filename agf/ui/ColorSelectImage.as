package agf.ui
{
	import flash.display.*;
	import flash.geom.Rectangle;
	
	public class ColorSelectImage extends Sprite 
	{
		// type: rgb, kelvin, wavelength or overlay ( vertical : white to transparent to black
		public function ColorSelectImage( type:String="rgb", w:int = 246, h:int = 148, transparent:Boolean=false, bgColor:int=0x00FFFFFF, params:Object=null ) 
		{
			bitmapData = new BitmapData(w, h, transparent, bgColor);
			bitmap = new Bitmap(bitmapData);
			drawColorBmp( type, params );
			addChild(bitmap);
		}
		
		private var _type:String; // kelvin, wavelength
		public function get type () :String { return _type; }
		
		public var bitmap:Bitmap;
		private var bitmapData:BitmapData;
		
		public function drawColorBmp (t:String, params:Object=null) :void {
			
			_type = t.toLowerCase();
			
			var w:int = bitmapData.width;
			var h:int = bitmapData.height;
			
			var col:uint;
			var r:Number;
			var g:Number;
			var b:Number;
			var a:Number=255;
			
			var r2:int;
			var g2:int;
			var b2:int;
			
			var i:int;
			var sr:Number;
			var sg:Number;
			var sb:Number;
			
			var cnt:int = Math.round(w/2);
			
			var rc:Rectangle = new Rectangle(-1, 0, 1, h);
			
			if( _type == "kelvin" ) {
				
				// Red:  255, 55, 0, To White: 255 255 255, To Blue: 155 188 255
				r = 255; g = 56; b = 0;
				r2 = 255; g2 = 249; b2 = 255;
				sg = (g2 - g) / cnt;
				sb = (b2 - b) / cnt;
				// orange to white
				for(i=0; i<cnt; i++) {
					rc.x++;
					g += sg; b += sb;
					
					//if( r > 255 ) r = 255;
					if( g > 255 ) g = 255;
					if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				r = 230; g = 255; b = 255;
				r2 = 16; g2 = 77; b2 = 255;
				sr = (r2 - r) / cnt;
				sg = (g2 - g) / cnt;
				sb = (b2 - b) / cnt;
				
				// white to light blue
				for(i=0; i<cnt; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0;
					if( g < 0 ) g = 0;
					if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;
					if( g > 255 ) g = 255;
					if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				
			}else if( _type == "bw" ) {
				
				// Black:  255, 55, 0, To White: 255 245 245
				r = 0; g = 0; b = 0;
				r2 = 255; g2 = 255; b2 = 255;
				sr = (r2 - r) / w;
				sg = (g2 - g) / w;
				sb = (b2 - b) / w;
				// orange to white
				for(i=0; i<w; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					
					if( r > 255 ) r = 255;
					if( g > 255 ) g = 255;
					if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
			}
			else if( _type == "rgb" )
			{
				// black - red - green - blue - black
				
				var cnt3:int = Math.round(cnt/3);
				
				r = 255; g = 0; b = 0;
				r2 = 255; g2 = 255; b2 = 0;
				sr = (r2 - r) / cnt3;
				sg = (g2 - g) / cnt3;
				sb = (b2 - b) / cnt3;

				// red to yellow
				for(i=0; i<cnt3; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				r2 = 0; g2 = 255; b2 = 0;
				sr = (r2 - r) / cnt3;
				sg = (g2 - g) / cnt3;
				sb = (b2 - b) / cnt3;
				// yellow to green
				for(i=0; i<cnt3; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				r2 = 0; g2 = 255; b2 = 255;
				sr = (r2 - r) / cnt3;
				sg = (g2 - g) / cnt3;
				sb = (b2 - b) / cnt3;
				// green to turkis
				for(i=0; i<cnt3; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				
				r2 = 0; g2 = 0; b2 = 255;
				sr = (r2 - r) / cnt3;
				sg = (g2 - g) / cnt3;
				sb = (b2 - b) / cnt3;
				// turkis to blue
				for(i=0; i<cnt3; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				r2 = 255; g2 = 0; b2 = 255;
				sr = (r2 - r) / cnt3;
				sg = (g2 - g) / cnt3;
				sb = (b2 - b) / cnt3;
				// blue to pink
				for(i=0; i<cnt3; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				r2 = 255; g2 = 0; b2 = 0;
				sr = (r2 - r) / cnt3;
				sg = (g2 - g) / cnt3;
				sb = (b2 - b) / cnt3;
				// to red
				for(i=0; i<cnt3; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
			}
			else if( _type == "wavelength" )
			{
				
				// black - red - green - blue - black
				
				var cnt4:int = Math.round(cnt/2);
				
				r = 0; g = 0; b = 0;
				r2 = 255; g2 = 0; b2 = 0;
				sr = (r2 - r) / cnt4;
				sg = (g2 - g) / cnt4;
				sb = (b2 - b) / cnt4;

				// black to red
				for(i=0; i<cnt4; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				r2 = 0; g2 = 255; b2 = 0;
				sr = (r2 - r) / cnt4;
				sg = (g2 - g) / cnt4;
				sb = (b2 - b) / cnt4;
				// red to green
				for(i=0; i<cnt4; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				r2 = 0; g2 = 0; b2 = 255;
				sr = (r2 - r) / cnt4;
				sg = (g2 - g) / cnt4;
				sb = (b2 - b) / cnt4;
				// green to blue
				for(i=0; i<cnt4; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
				r2 = 0; g2 = 0; b2 = 0;
				sr = (r2 - r) / cnt4;
				sg = (g2 - g) / cnt4;
				sb = (b2 - b) / cnt4;
				// blue to black
				for(i=0; i<cnt4; i++) {
					rc.x++;
					r += sr; g += sg; b += sb;
					if( r < 0 ) r = 0; if( g < 0 ) g = 0;if( b < 0 ) b = 0;
					if( r > 255 ) r = 255;if( g > 255 ) g = 255;if( b > 255 ) b = 255;
					bitmapData.fillRect(rc, bitmapData.transparent ? (int(a) << 24 | int(r) << 16 | int(g) << 8 | int(b)) :(int(r) << 16 | int(g) << 8 | int(b)) );
				}
			}
			else if(_type == "overlay") {
				if( bitmapData.transparent ) {
					// vertical white - transparent - transparent - black
					var cth:Number  = params ? (params.center) || 0.4 : 0.4;
					if( cth < 0.05 ) cth = 0.05
					if( cth > 0.495 ) cth = 0.495;
					var maxval:Number = params ? (params.maxValue) || 255 : 255;
					var minval:Number = 0;
					var h2:int=Math.round( h * cth );
					
					rc.x = 0;
					rc.y = -1;
					rc.height = 1;
					rc.width = w;
					
					r = 255; g = 255*maxval;
					g2 = 255*minval;
					sg = (g2 - g) / h2;
					// white to transparent
					for(i=0; i<h2; i++) {
						rc.y++;
						g += sg;
						if( g < 0 ) g = 0;
						if( g > 255 ) g = 255;
						bitmapData.fillRect(rc, int(g) << 24 | int(r) << 16 | int(r) << 8 | int(r) );
					
					}
					
					rc.y = Math.round(h - h2);
					r2 = 0;
					g2 = maxval*255;
					sg = (g2 - g) / h2;
					sr = (r2 - r) / cnt4;
					// transparent black
					for(i=0; i<h2; i++) {
						rc.y++;
						r += sr;
						g += sg;
						if( r < 0 ) r = 0;
						if( r > 255 ) r = 255;
						if( g < 0 ) g = 0;
						if( g > 255 ) g = 255;
						
						bitmapData.fillRect(rc, int(g) << 24 | int(r) << 16 | int(r) << 8 | int(r) );
					}
				}
			}
		}
	}
	
}
