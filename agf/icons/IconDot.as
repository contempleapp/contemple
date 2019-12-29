package agf.icons
{
	import flash.display.Sprite;
	
	public class IconDot extends Sprite
	{
		public function IconDot (col:Number=0, alpha:Number=1, w:Number=20, h:Number=14) 
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=20, h:Number=14 ) :void
		{
			var r:Number = Math.min(w,h);
			var r2:Number = r/2;
			
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.drawCircle( w/2, h/2, r2 );
			graphics.endFill();
			
			
		}
		
	}
}