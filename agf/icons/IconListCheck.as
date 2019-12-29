package agf.icons{	import flash.display.Sprite;		public class IconListCheck extends Sprite
	{		public function IconListCheck (col:Number=0, alpha:Number=1, w:Number=8, h:Number=14)
		{
			draw(col, alpha, w, h);
		}
		
		private function draw( col:Number=0, alpha:Number=1, w:Number=8, h:Number=14) :void
		{
			var tk:Number = 2;
						graphics.clear();			graphics.beginFill(1, 0);			graphics.drawRect( 0, 0, w, h );			graphics.endFill();						graphics.beginFill(col, alpha);			graphics.moveTo( w-tk, 0 );			graphics.lineTo( w, 0 );
			graphics.lineTo( w, tk );
			graphics.lineTo( w/2, h );
			graphics.lineTo( 0, h/2 + tk );
			graphics.lineTo( 0, h/2 );
			graphics.lineTo( tk, h/2 );
			graphics.lineTo( w/2, h-tk );			graphics.endFill();		}	}	}