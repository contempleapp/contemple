package agf.icons
{
	import flash.display.Sprite;
	
	public class IconAppNew extends Sprite
	{
		public function IconAppNew(col:Number=0, alpha:Number=1, w:Number=14, h:Number=11) 
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=10, h:Number=10 ) :void
		{
			var th1:int = Math.round( (h / 2) / 1.6186 );
			var th2:int = h - th1*2;
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.moveTo( 0, 0/*th1*/ );
			graphics.lineTo( w/2, th2 );
			graphics.lineTo( w, th1 );
			graphics.lineTo( w, th1+th2 );
			graphics.lineTo(w/2, h);
			graphics.lineTo(0, th1+th2);
			graphics.lineTo( 0, th1 );
			graphics.endFill();
		}
		
	}
}