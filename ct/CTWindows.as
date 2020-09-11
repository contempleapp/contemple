package ct
{	
	import agf.ui.*;
	import agf.tools.*;
	
	public class CTWindows extends DefaultWindows {

		public function CTWindows() {
			super();
		}

		public override function CreateWindow ( nameUid:String, title:String, options:Object=null, cssClass:String="" ) :Window
		{
			if(options == null || typeof options.width != "number" ) {
				// auto width
				if( HtmlEditor.isPreviewOpen && ! CTOptions.previewAtBottom ) {
					var pvx:int = HtmlEditor.previewX;
					if( options == null ) options = {};
					options.width = pvx - 20;
				}
			}
			return super.CreateWindow( nameUid, title, options, cssClass );
		}
	}
	
}
