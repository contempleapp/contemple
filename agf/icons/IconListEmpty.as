package agf.icons{	import flash.display.Sprite;	import agf.utils.ColorUtils;
	
		public class IconListEmpty extends Sprite
	{
				public function IconListEmpty (col:Number=0x777777, alpha:Number=1, w:Number=20, h:Number=28)
		{			draw(col, alpha, w, h);
		}
		 
		private function draw( col:Number=0x777777, alpha:Number=1, w:Number=20, h:Number=28) :void
		{
			col = 0x444444;
			
			var tk:Number = 1;
			var c:Object = {};
			ColorUtils.getRGBComponents( col, c );
			
			graphics.clear();
			graphics.beginFill( col, alpha);
			graphics.drawRect( 0, 0, w, h );
			graphics.endFill();
			
			graphics.lineStyle(0, ColorUtils.combineRGB( int(c.r*1.5), int(c.g*1.5), int(c.b*1.5) ) , alpha);
			graphics.moveTo( 0, 0 );
			graphics.lineTo( 0, h );
			
			graphics.lineStyle(0, ColorUtils.combineRGB( int(c.r/2), int(c.g/2), int(c.b/2) ), alpha);
			graphics.moveTo( w, 0 );
			graphics.lineTo( w, h );
		}	}}