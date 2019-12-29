package agf.icons
{
	import flash.display.Sprite;
	
	public class IconClose extends Sprite
	{
		public function IconClose (col:Number=0, alpha:Number=1, w:Number=12, h:Number=12)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=10, h:Number=10 ) :void {
			graphics.clear();
			graphics.lineStyle(3, col, alpha);
			graphics.moveTo(1,1);
			graphics.lineTo(w-1,h-1);
			graphics.moveTo(w-1,1);
			graphics.lineTo(1,h-1);
		}
		
	}
}