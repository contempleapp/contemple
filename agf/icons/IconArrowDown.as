package agf.icons
{
	import flash.display.Sprite;
	
	public class IconArrowDown extends Sprite
	{
		public function IconArrowDown(col:Number=0, alpha:Number=1, w:Number=16, h:Number=16)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=16, h:Number=16) :void {
			graphics.clear();
			
			graphics.beginFill(0,0);
			graphics.drawRect(0,0,w,h);
			graphics.endFill();
			
			graphics.beginFill(col, alpha);
			
			graphics.moveTo(1, h/4);
			graphics.lineTo(w/2,h-h/4);
			graphics.lineTo(w-2, h/4);
			graphics.endFill();
		}
		
	}
}