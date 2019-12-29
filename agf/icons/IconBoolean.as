package agf.icons
{
	import flash.display.Sprite;
	
	public class IconBoolean extends Sprite
	{
		public function IconBoolean (col:Number=0, alpha:Number=1, w:Number=12, h:Number=12)
		{
			_col = col;
			_w = w;
			_h = h;
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=15, h:Number=15) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.drawRect(0,0,w,h);
			graphics.endFill();
		}
		private var _col:int=0;
		private var _w:int=0;
		private var _h:int=0;
		private var _checkColor:int=0x0;
		private var _val:Boolean=false;
		private var check:Sprite;
		
		public function getValue ( ) :Boolean {
			return _val;
		}
		public function setValue ( val:Boolean ) :void {
			_val = val
			
			if( val ) {
				// draw check
				if( !check ) {
					check = new Sprite();
					var tk:Number = 5;
					var w:Number = _w;
					var h:Number = _h;
					check.graphics.beginFill(_col, 1);
					check.graphics.moveTo( w-tk, 0 );
					check.graphics.lineTo( w, 0 );
					check.graphics.lineTo( w, tk );
					check.graphics.lineTo( w/2, h );
					check.graphics.lineTo( 0, h/2 + tk/2 );
					check.graphics.lineTo( 0, h/2 );
					check.graphics.lineTo( tk, h/2 );
					check.graphics.lineTo( w/2, h-tk );
					check.x = 1;
					check.y = 1;
				}
				addChild(check);
			}else{
				if( check && contains(check) ) removeChild(check);
			}
			
		}
	}
}