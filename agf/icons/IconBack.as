package agf.icons
{
	import flash.display.Sprite;
	
	public class IconBack extends Sprite
	{
		public function IconBack (col:Number=0, alpha:Number=1, w:Number=24, h:Number=18)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=24, h:Number=18) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);

			var c:Number = w/2;
			var m:Number = h/2;
			var t:Number = h/4;
			
			graphics.moveTo(c,0);
			graphics.lineTo(0,m);
			graphics.lineTo(c, h);
			graphics.lineTo(c, h-t);
			graphics.lineTo(w, h-t);
			graphics.lineTo(w, t);
			graphics.lineTo(c, t);
			graphics.lineTo(c, 0);
			graphics.endFill();
		}
		
	}
}