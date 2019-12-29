package ct
{
	import agf.html.*;
	import agf.events.*;
	import flash.events.*;
	import agf.icons.*;
	import agf.tools.*;
	import flash.filesystem.File;
	import ct.ctrl.*;
	import agf.db.DBResult;
	import agf.ui.*;
	import agf.utils.*;
	import agf.io.ResourceMgr;
	import agf.Main;
	import agf.Options;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.utils.setTimeout;
	import flash.utils.getTimer;
	import flash.display.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.filesystem.*;
	import flash.net.FileReference;
	import flash.net.SharedObject;
	import flash.events.FileListEvent;

	public class MediaEditor extends CssSprite
	{
		public function MediaEditor( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
			Application.instance.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
			create();
		}
		
		private var scrollpane:ScrollContainer;
		private var itemList:ItemList;
		private var currDir:String="";
		internal static var clickScrolling:Boolean=false;
		private var clickY:Number=0; 
		
		public function create () :void {}
		
		private function removePanel (e:Event) :void {
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnUp );
			}
			Main(Application.instance).view.removeEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		public override function setWidth( w:int) :void {
			super.setWidth(w);
			var sbw:int = 0;
			if( scrollpane && scrollpane.slider.visible ) sbw = 8;
			if( itemList) {
				if(itemList.items) {
					for( var i:int=0; i < itemList.items.length; i++) {
						itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + cssBoxX + cssLeft + sbw) );
					}
				}
				itemList.setWidth(0);
				itemList.init();
			}
			if( scrollpane ) scrollpane.setWidth( w - cssBoxX );
		}
		public override function setHeight (h:int) :void {
			super.setHeight(h);
			if(scrollpane) {
				var sldv:Boolean = scrollpane.slider.visible;
				scrollpane.setHeight( h - (cssBoxY) );
				scrollpane.contentHeightChange();
				if( scrollpane.slider.visible != sldv ) setWidth( getWidth() );
			}
		}
		
		private function inputHeightChange (e:Event):void {
			if( itemList ) {
				itemList.format();
			}
			if( scrollpane ) scrollpane.contentHeightChange();
		}
		
		public function showMediaItems ( directory:String="" ) :void
		{
			if(scrollpane) {
				if( itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
				if( contains( scrollpane) ) removeChild( scrollpane );
			}
			
			var w:Number = getWidth();
			var h:Number = getHeight() - cssTop;
			
			scrollpane = new ScrollContainer( w, h, this, styleSheet,'', 'media-scroll-container', false);
			scrollpane.setHeight( cssSizeY );
			scrollpane.setWidth( cssSizeX );
			scrollpane.y = cssTop;
			scrollpane.x = cssLeft;
			scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
			
			itemList = new ItemList(w, 0, scrollpane.content, styleSheet, '', 'media-container', false);
			itemList.x = 0;
			itemList.y = 0;
			itemList.margin = 1;
			
			var rootDir:String =  CTTools.projectDir + CTOptions.urlSeparator + CTOptions.localUploadFolder;
			
			// Display files in min or raw folder...
			if( directory ) {
				if( directory != rootDir ) {
					var ico:Button = new Button([ new IconFromFile("app:/"+Options.iconDir+"/reply.png"), ".." ], 0, 0, itemList, styleSheet, '', 'media-item-btn',false);
					ico.addEventListener( MouseEvent.CLICK, parentBtnClick );
					itemList.addItem( ico, true);
				}
				listDirectory( directory );
			}else{
				if( CTTools.projectDir ) {
					listDirectory( rootDir );
				}
			}
		}
		
		private function listDirectory (url) :void {
			var f:File = new File(url);
			if( f.isDirectory ) {
				currDir = url;
				f.getDirectoryListingAsync();
				f.addEventListener(FileListEvent.DIRECTORY_LISTING, dirlistAsync);
			}
		}
		
		private function displayFile( file:File ) :void {
			var ico:Button;
			var fi:FileInfo = FileUtils.fileInfo( file.url);
			
			if( file.isDirectory ) {
				// display folder icon
				ico = new Button([ new IconFromFile("app:/"+Options.iconDir+"/folder.png"), fi.filename ], 0, 0, itemList, styleSheet, '', 'media-item-btn',false);
				ico.addEventListener( MouseEvent.CLICK, folderBtnClick );
				
			}else{
				// display file icon
				var file_ico:Sprite;
				if( fi.type == "image" || fi.type == "svg" ) {
					file_ico = new IconFromFile("app:/"+Options.iconDir+"/file-image.png");
				}else if( fi.type == "html" || fi.type == "script" ) {
					file_ico = new IconFromFile("app:/"+Options.iconDir+"/file-code.png");
				}else if( fi.type == "audio" ) {
					file_ico = new IconFromFile("app:/"+Options.iconDir+"/file-audio.png");
				}else{
					file_ico = new IconFromFile("app:/"+Options.iconDir+"/file-text.png");
				}
				ico = new Button([ file_ico, fi.filename ], 0, 0, itemList, styleSheet, '', 'media-item-btn',false);
				ico.options.opened = false;
				ico.addEventListener( MouseEvent.CLICK, fileBtnClick );
				
			}
			itemList.addItem( ico, true);
		}
				
		private function showFileInfo (file:File, btn:Button):void
		{
			if( btn.options.opened == true )
			{
				var id:int = itemList.items.indexOf(btn);
				if( id >= 0 && itemList.items.length > id )
				{
					itemList.removeItem( itemList.items[id+1] );
					btn.options.opened = false;
					inputHeightChange(null);
				}
			}
			else
			{
				var mfi:MediaFileInfo = new MediaFileInfo( file.url, 0, 0, itemList, styleSheet, '', 'media-file-info', false );
				btn.options.opened = true;
				
				itemList.addItemAt( mfi, itemList.items.indexOf(btn)+1 );
				inputHeightChange(null);
			}
		}
		
		public function abortClickScrolling () :void {
			btnUp(null);
			clickScrolling=false;
		}
		
		private function btnUp (event:MouseEvent) :void {
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
		}
		private function btnMove (event:MouseEvent) :void {
			var dy:Number = mouseY - clickY;
			
			if( ! clickScrolling )
			{
				if( Math.abs(dy) > CTOptions.mobileWheelMove )
				{
					clickScrolling = true;
				}
			}else{
				// scroll
				scrollpane.slider.value -= dy;
				scrollpane.scrollbarChange(null);
				clickY = mouseY;
			}
		}
		private function btnDown (event:MouseEvent) :void {
			stage.addEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, btnUp );
			clickScrolling = false;
			clickY = mouseY;
		}
		
		private function fileBtnClick(event:MouseEvent):void
		{
			if( clickScrolling )
			{
				clickScrolling = false;
			}
			else
			{
				var btn:Button = Button(event.currentTarget);
				var file:File = new File( currDir + CTOptions.urlSeparator + btn.label );
				if( file.exists ) 
				{
					var fi:FileInfo = FileUtils.fileInfo( file.url );
					
					if( fi.type == "image" || fi.type == "svg" ) {
						showFileInfo ( file, btn );
					}
					
					if( fi.type == "html" || fi.type == "script" || fi.type == "image" || fi.type == "svg" ) {
						try {
							var ed:HtmlEditor = HtmlEditor( Application.instance.view.panel.src );
							if( ed ) {
								ed.loadWebURL( file.url );
							}
						}catch( e:Error) {
							Console.log("Load Web URL : " + e);
						}
					}else if( fi.type == "audio" ) {
						
					}else{
						
					}
				}
			}
		}
		
		private function folderBtnClick(event:MouseEvent):void {
			showMediaItems( currDir + CTOptions.urlSeparator + Button(event.currentTarget).label );
		}
		private function parentBtnClick(event:MouseEvent):void {
			var cid:int = currDir.lastIndexOf(CTOptions.urlSeparator);
			if( cid>=0 ) {
				showMediaItems( currDir.substring(0,cid) );
			}
		}
		private function dirlistAsync(event:FileListEvent):void {
			var list:Array = event.files;
			for (var i:uint = 0; i < list.length; i++)
			{
				displayFile( list[i] );
			}
			itemList.format();
			itemList.init();
			scrollpane.contentHeightChange();
			
			setWidth( getWidth() );
		}
	}
}
