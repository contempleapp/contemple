package ct
{
	import flash.display.*;
	import flash.text.*;
	import flash.filesystem.*;
	import agf.utils.FileUtils;
	import agf.utils.FileInfo;
	import agf.html.*;
	import agf.io.*;
	import agf.ui.*;
	import agf.tools.Application;
	
	public class MediaFileInfo extends CssSprite {

		/**
		*   All File Types:
		*		- File Size in kb/MB/GB
		*		- File Type: web, script, stylesheet, image, audio, video, pdf
		*		
		*   Html, Php, Asp -> 
		*		- Click to open local and online
		*		- (Edit Text/Template ??)
		*
		*	Image
		*		- Display Thumbnail
		*		- Display Dimensions
		*		- (Edit Image: Brightness, Saturation, Blur, Compression, Image Type (png->jpg etc) etc ??)
		*		
		**/
		public function MediaFileInfo(url:String, w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false )
		{
			super(w, h, parentCS, css, "propctrl", cssId, cssClasses, noInit);
			createInfo (url);
		}
		
		private var _url:String="";
		private var _type:String="";
		private var _extension:String="";
		private var _name:String="";
		private var _path:String="";
		
		private var mediaContainer:Sprite;
		private var mediaInfoText:TextField;
		
		private var mediaWidth:int = 128;
		private var mediaHeight:int = 128;
		
		public function createInfo (url:String) :void
		{
			_url = url;
			var fi:FileInfo = FileUtils.fileInfo(url);
			_type = fi.type;
			_name = fi.name;
			_path = fi.path;
			
			if( mediaContainer && contains(mediaContainer) ) removeChild( mediaContainer );
			if( mediaInfoText && contains(mediaInfoText) ) removeChild( mediaInfoText );
			
			mediaContainer = new Sprite();
			
			mediaInfoText = new TextField();
			mediaInfoText.multiline = true;
			mediaInfoText.defaultTextFormat = styleSheet.getTextFormat( ["*","body",".media-info-text"], "normal" );
			mediaInfoText.height = mediaHeight-4;
			
			addChild( mediaContainer );
			addChild( mediaInfoText );
			
			if( _type == "image" ) {
				loadImage( _url );
			}
		}
		
		private function loadImage (path:String) :void
		{
			Application.instance.resourceMgr.clearResourceCache( path, true );
			Application.instance.resourceMgr.loadResource( path, onImageLoaded, false );
		}
		
		private function onImageLoaded ( _res:Resource ) :void {
			var sp:DisplayObject = DisplayObject(_res.obj);
			if(sp) {
				var f:File = new File( _url );
				mediaInfoText.text = f.extension.toUpperCase() + " Image\n" + int(sp.width) + " x " + int(sp.height) + " px ";
				mediaInfoText.appendText( "\n" + Math.round(f.size /1000) + " kb");
				
				var bmd:BitmapData = new BitmapData(mediaWidth, mediaHeight, true, 0x00999999);
				var bmp:Bitmap = new Bitmap(bmd);
				var dw:Number = mediaWidth/sp.width;
				var dh:Number = mediaHeight/sp.height;
				var scl:Number = Math.min( dw, dh);
				
				if( scl < 1 ) {
					sp.scaleX = sp.scaleY = scl;
				}
				bmd.draw( sp, sp.transform.matrix );
				
				var stylchain:Array = [".media-info"];				
				var m:Number = 0;
				var o:Object = styleSheet.getMultiStyle( stylchain );
				if( o.marginLeft ) m = CssUtils.parse( o.marginLeft, this, "h" );
				mediaInfoText.x = sp.width + m;
				mediaInfoText.y = 4;
				mediaInfoText.width = getWidth() - (cssBoxX + mediaInfoText.x + 4);
				mediaContainer.addChild( bmp );
			}
		}
		

	}
	
}
