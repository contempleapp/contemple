
package agf.icons
{
	import flash.display.Sprite;
	
	public class ScrollDownIcon extends WEIcon 
	{
		public function ScrollDownIcon () {
			graphics.clear();
			graphics.beginFill(defaultColorEnabled,1);
			graphics.moveTo(0,0);
			graphics.lineTo(4,4);
			graphics.lineTo(8,0);
			graphics.lineTo(0,0);
			graphics.endFill();
		}
	}
	
}