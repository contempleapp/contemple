
package agf.icons
{
	import flash.display.Sprite;
	
	public class PopupFolderIcon extends WEIcon 
	{
		public function PopupFolderIcon () {
			graphics.clear();
			graphics.beginFill(defaultColorEnabled,1);
			graphics.moveTo(0,0);
			graphics.lineTo(8,4);
			graphics.lineTo(0,8);
			graphics.lineTo(0,0);
			graphics.endFill();
		}
	}
	
}