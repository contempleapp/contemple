
package agf.icons
{
	import flash.display.Sprite;
	
	public class NumericInputIcon extends WEIcon 
	{
		public function NumericInputIcon () 
		{
			graphics.beginFill(defaultColorEnabled, 1);
			graphics.moveTo( 4, 0);
			graphics.lineTo( 0, 4);
			graphics.lineTo( 4, 8);
			graphics.endFill();
			
			graphics.beginFill(defaultColorEnabled, 1);
			graphics.moveTo( 6, 0);
			graphics.lineTo( 11, 4);
			graphics.lineTo( 6, 8);
			graphics.endFill();
		}
	}
	
}