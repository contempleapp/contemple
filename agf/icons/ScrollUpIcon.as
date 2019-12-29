
package agf.icons
{
	import flash.display.Sprite;
	
	public class ScrollUpIcon extends WEIcon 
	{
		public function ScrollUpIcon () {
			graphics.clear();
			graphics.beginFill(defaultColorEnabled,1);
			graphics.moveTo(0,4);
			graphics.lineTo(4,0);
			graphics.lineTo(8,4);
			graphics.lineTo(0,4);
			graphics.endFill();
		}
	}
	
}