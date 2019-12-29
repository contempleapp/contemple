package agf.icons
{
	import flash.display.Sprite;
	
	public class IconArrowUp extends Sprite
	{
		public function IconArrowUp (col:Number=0, alpha:Number=1, w:Number=14, h:Number=8)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=14, h:Number=8) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.moveTo(0,h);
			graphics.lineTo(w/2,0);
			graphics.lineTo(w, h);
			graphics.endFill();
		}
		
	}
}