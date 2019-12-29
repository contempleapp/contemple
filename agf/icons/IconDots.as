package agf.icons
{
	import flash.display.Sprite;
	
	public class IconDots extends Sprite
	{
		public function IconDots (col:Number=0, alpha:Number=1, w:Number=20, h:Number=14) 
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=20, h:Number=14 ) :void
		{
			var r:Number = h/7;
			var r2:Number = r/2;
			var w2:Number = w/2;
			
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.drawCircle( w2, r2, r );
			graphics.drawCircle( w2, h/2, r );
			graphics.drawCircle( w2, h-r2, r );
			graphics.endFill();
			/*
			var th1:int = Math.round( (h / 2) / 1.6186 );
			var th2:int = h - th1*2;
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.moveTo( 0, th1 );
			graphics.lineTo( w/2, 0 );
			graphics.lineTo( w, th1 );
			graphics.lineTo( w, th1+th2 );
			graphics.lineTo(w/2, h);
			graphics.lineTo(0, th1+th2);
			graphics.lineTo( 0, th1 );
			graphics.endFill();
			*/
			
		}
		
	}
}