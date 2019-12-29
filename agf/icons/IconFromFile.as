package agf.icons
{
	import flash.display.*;
	import flash.events.Event;
	import flash.geom.Matrix;
	
	import agf.io.Resource;
	import agf.io.ResourceMgr;
	
	public class IconFromFile extends Sprite
	{
		public function IconFromFile (url:String, w:Number=16, h:Number=16)
		{
			bmd = new BitmapData(w, h, true, 0x00000000);
			bmp = new Bitmap(bmd);
			addChild( bmp );
			loadFile(url);
		}
		
		private function loadFile (url:String, w:Number=16, h:Number=16):void
		{
			ResourceMgr.getInstance().loadResource( url, onLoaded, false );
			/*
			graphics.clear();
			graphics.beginFill(0x0, 0);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();*/
			
		}
		
		private var _res:Resource;
		private var bmd:BitmapData;
		private var bmp:Bitmap;
		
		private function onLoaded (res:Resource) :void {
			_res = res;
			var sp:DisplayObject = DisplayObject( _res.obj);
			if(sp) {
				var scx:Number=1;
				var scy:Number=1;
				
				if( sp.width > bmp.width ) {
					scx = bmp.width / sp.width;
				}
				if( sp.height > bmp.height ) {
					scy = bmp.height / sp.height;
				}
				var s:Number = Math.min(scx,scy);
				
				var m:Matrix = new Matrix();
				m.scale( s, s );
				
				//graphics.clear();
				bmd.fillRect( bmd.rect, 0x00000000 );
				bmd.draw( sp, m );
				//addChild( sp );
			}
		}
		
	}
}