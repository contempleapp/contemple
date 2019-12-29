package agf.icons{	import flash.display.Sprite;	import agf.utils.ColorUtils;
	
		public class IconEmpty extends Sprite
	{
				public function IconEmpty (w:Number=20, h:Number=28)
		{			draw( w, h);
		}
		 
		private function draw( w:Number=20, h:Number=28) :void
		{
			graphics.clear();
			graphics.beginFill( 0, 0 );
			graphics.drawRect( 0, 0, w, h );
			graphics.endFill();
		}	}}