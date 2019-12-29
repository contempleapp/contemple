package agf.icons
{
	import flash.display.Sprite;
	
	public class IconMenu extends Sprite
	{
		public function IconMenu (col:Number=0, alpha:Number=1, w:Number=12, h:Number=12)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=15, h:Number=15) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.drawRect(0,0,w, h/4);
			graphics.drawRect(0,h/3,w, h/4);
			graphics.drawRect(0,h/1.5,w, h/4);
			graphics.endFill();
		}
		
	}
}