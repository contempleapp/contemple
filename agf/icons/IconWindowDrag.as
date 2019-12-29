package agf.icons
{
	import flash.display.Sprite;
	
	public class IconWindowDrag extends Sprite
	{
		public function IconWindowDrag (col:Number=0, alpha:Number=1, w:Number=8, h:Number=8)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=8, h:Number=8) :void {
			graphics.clear();
			
			graphics.beginFill( col,alpha);
			graphics.drawRect(0,0,w,h);
			graphics.endFill();
			/*
			graphics.lineStyle(2, col, alpha);
			graphics.moveTo(0, 0);
			graphics.lineTo(w, h);
			graphics.moveTo(w, 0);
			graphics.lineTo(0, h);
			*/
		}
		
	}
}