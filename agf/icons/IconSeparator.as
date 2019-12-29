package agf.icons
{
	import flash.display.Sprite;
	
	public class IconSeparator extends Sprite
	{
		public function IconSeparator (col:Number=0, alpha:Number=1, w:Number=10, h:Number=1)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=10, h:Number=1) :void {
			graphics.clear();
			
			graphics.lineStyle( 0, col, alpha );
			graphics.moveTo(0, 0);
			graphics.lineTo(w, 0);
			
			graphics.lineStyle(0, 0xFFFFFF-col, alpha );
			graphics.moveTo(0, h);
			graphics.lineTo(w, h);
		}
		
	}
}