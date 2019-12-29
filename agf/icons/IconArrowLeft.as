package agf.icons
{
	import flash.display.Sprite;
	
	public class IconArrowLeft extends Sprite
	{
		public function IconArrowLeft (col:Number=0, alpha:Number=1, w:Number=8, h:Number=14)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=8, h:Number=14) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.moveTo(w,0);
			graphics.lineTo(0,h/2);
			graphics.lineTo(w, h);
			graphics.endFill();
		}
		
	}
}