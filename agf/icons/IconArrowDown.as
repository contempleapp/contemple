package agf.icons
{
	import flash.display.Sprite;
	
	public class IconArrowDown extends Sprite
	{
		public function IconArrowDown(col:Number=0, alpha:Number=1, w:Number=14, h:Number=8)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=14, h:Number=8) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.moveTo(0,0);
			graphics.lineTo(w/2,h);
			graphics.lineTo(w, 0);
			graphics.endFill();
		}
		
	}
}