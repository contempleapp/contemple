package agf.icons
{
	import flash.display.Sprite;
	
	public class IconArrowLeft extends Sprite
	{
		public function IconArrowLeft (col:Number=0, alpha:Number=1, w:Number=16, h:Number=16)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=16, h:Number=16) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			
			graphics.moveTo(w - w/4, 1);
			graphics.lineTo(w/4,h/2);
			graphics.lineTo(w - w/4, h - 2);
			graphics.endFill();
		}
		
	}
}