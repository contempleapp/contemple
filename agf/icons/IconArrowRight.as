package agf.icons
{
	import flash.display.Sprite;
	
	public class IconArrowRight extends Sprite
	{
		public function IconArrowRight (col:Number=0, alpha:Number=1, w:Number=8, h:Number=14)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=8, h:Number=14) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.moveTo(w/4,1);
			graphics.lineTo(w-w/4,h/2);
			graphics.lineTo(w/4, h-2);
			graphics.endFill();
		}
		
	}
}