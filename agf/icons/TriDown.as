
package agf.icons
{
	import flash.display.Sprite;
	
	public class TriDown extends WEIcon 
	{
		public function TriDown () 
		{
			graphics.clear();
			graphics.beginFill(defaultColorEnabled,1);
			graphics.moveTo(0,0);
			graphics.lineTo(8,0);
			graphics.lineTo(4,8);
			graphics.lineTo(0,0);
			graphics.endFill();
		}
	}
	
}