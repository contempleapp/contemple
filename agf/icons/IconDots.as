package agf.icons
{
	import flash.display.Sprite;
	
	public class IconDots extends Sprite
	{
		public function IconDots (col:Number=0, alpha:Number=1, w:Number=20, h:Number=14) 
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=20, h:Number=14 ) :void
		{
			var r:Number = h/7;
			var r2:Number = r/2;
			var w2:Number = w/2;
			
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.drawCircle( w2, r2, r );
			graphics.drawCircle( w2, h/2, r );
			graphics.drawCircle( w2, h-r2, r );
			graphics.endFill();
		}
		
	}
}