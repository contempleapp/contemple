package ct
{
	import agf.html.*;
	import agf.events.*;
	import flash.events.*;
	import flash.net.*;
	import agf.icons.*;
	import agf.tools.*;
	import flash.filesystem.*;
	
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
	import agf.animation.Animation;
	import fl.transitions.easing.Regular;
	import fl.transitions.easing.Strong;
	
	public class MediaEditor extends CssSprite
	{
		public function MediaEditor( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
			Application.instance.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
			create();
		}
		
		private var scrollpane:ScrollContainer;
		private var addFileBtn:Button;
		
		private var itemList:ItemList;
		private var currDir:String="";
		internal static var clickScrolling:Boolean=false;
		private var clickY:Number=0;
		
		private var pathLabels:ItemBar;
		
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
			if( scrollpane && scrollpane.slider.visible ) sbw = scrollpane.slider.cssSizeX + 4;
			if( addFileBtn ) addFileBtn.x = (w - cssLeft) - (addFileBtn.cssSizeX + addFileBtn.cssMarginRight);
			if( itemList) {
				if(itemList.items) {
					for( var i:int=0; i < itemList.items.length; i++) {
						itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + cssBoxX + sbw) );
					}
				}
				itemList.setWidth(0);
				itemList.init();
			}
			if( scrollpane ) scrollpane.setWidth( w - cssBoxX );
		}
		
		public override function setHeight (h:int) :void {
			super.setHeight(h);
			if(scrollpane)
			{
				var sldv:Boolean = scrollpane.slider.visible;
				var mh:int = 0;
				
				if( addFileBtn && pathLabels )
				mh = Math.max( cssTop + pathLabels.height + pathLabels.cssMarginBottom, cssTop + addFileBtn.cssSizeY + addFileBtn.cssMarginBottom);
			
				scrollpane.setHeight( h - (cssBoxY + mh) );
				scrollpane.y = cssTop + mh;
				
				scrollpane.contentHeightChange();
				if( scrollpane.slider.visible != sldv ) setWidth( getWidth() );
			}
		}
		
		private function inputHeightChange (e:Event):void
		{
			if( itemList ) {
				itemList.format();
			}
			
			var tmp:Number = scrollpane.slider.friction;
			scrollpane.slider.friction = 1;
			if( scrollpane ) scrollpane.contentHeightChange();
			setTimeout( function () {
				scrollpane.slider.friction = tmp;
			}, 234);
		}
		
		// gotoDirection: 0 = backward, forward = 1, 2 = same level, 3 = upward, 4 = downward
		public function showMediaItems ( directory:String="", gotoDirection:int=1, forceLevel:Boolean = false ) :void
		{
			if( pathLabels && contains( pathLabels) ) removeChild( pathLabels );
			if( addFileBtn && contains( addFileBtn) ) removeChild( addFileBtn );
			
			if(scrollpane) {
				if( itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
				if( contains( scrollpane) ) removeChild( scrollpane );
			}
			
			var w:Number = getWidth();
			var h:Number = getHeight();
			
			pathLabels = new ItemBar(0, 0, this, styleSheet,'', 'media-path', false);
			pathLabels.x = cssLeft + 4;
			pathLabels.y = cssTop;
			
			var bt:Button;
			var rootDir:String =  CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw;
			var i:int;
			
			if( directory ) {
				var dirs:Array = String( "Root" + directory.substring( rootDir.length ) ).split(CTOptions.urlSeparator);
				
				for( i=0; i < dirs.length; i++) {
					if( dirs[i] ) {
						bt = new Button( [ new IconFromFile(Options.iconDir + (i==0?"/tree-structure.png":"/folder-open.png"), Options.iconSize, Options.iconSize), dirs[i] ], 0, 0, pathLabels, styleSheet, '', 'media-path-btn', false);
						bt.addEventListener(MouseEvent.CLICK, pathClick);
						pathLabels.addItem( bt, true );
					}
				}
			}
			else
			{
				bt = new Button( [new IconFromFile(Options.iconDir + "/tree-structure.png", Options.iconSize, Options.iconSize), "Root"], 0, 0, pathLabels, styleSheet, '', 'media-path-btn', false);
				bt.addEventListener(MouseEvent.CLICK, pathClick);
				pathLabels.addItem( bt, true );
			}
			
			pathLabels.margin = int(4 * CssUtils.numericScale);
			pathLabels.format(false);
			pathLabels.init();
			
			addFileBtn = new Button( [Language.getKeyword("Add New File"), new IconFromFile(Options.iconDir + "/new.png", Options.iconSize, Options.iconSize)], 0,0, this, styleSheet, '', 'media-add-file-btn', false);
			addFileBtn.addEventListener( MouseEvent.CLICK, addFileHandler );
			addFileBtn.x = w - (addFileBtn.cssSizeX + addFileBtn.cssMarginRight);
			addFileBtn.y = cssTop;
			
			
			if( pathLabels.width + pathLabels.x > addFileBtn.x - 4 ) {
				var sp:int = addFileBtn.x -(pathLabels.x + 4);
				var sp1:int = sp / pathLabels.numItems;
				var csp:Button;
				var lbl:String;
				
				for( i = 0; i<pathLabels.numItems; i++ ) {
					csp = Button(pathLabels.items[i]);
					csp.clips = [csp.label];
					csp.init();
					if( csp.cssSizeX + 8 > sp1 ) {
						csp.setWidth( sp1 - (csp.cssBoxX + 8) );
					}
				}
				pathLabels.format(false);
				pathLabels.init();
			}
			
			var mh:int  = Math.max( cssTop + pathLabels.height + pathLabels.cssMarginBottom, cssTop + addFileBtn.cssSizeY + addFileBtn.cssMarginBottom);
			
			scrollpane = new ScrollContainer( 0, 0, this, styleSheet,'', 'media-scroll-container', false);
			scrollpane.setHeight( cssSizeY - (cssBoxX + mh) );
			scrollpane.setWidth( cssSizeX );
			scrollpane.y = cssTop + mh;
			scrollpane.x = cssLeft;
			scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
			
			itemList = new ItemList(w, 0, scrollpane.content, styleSheet, '', 'media-container', false);
			
			// Display files in min or raw folder...
			if( directory ) {
				listDirectory( directory );
			}else{
				if( CTTools.projectDir ) {
					listDirectory( rootDir );
				}
			}
			addChild( anim );
			addChild( anim2 );
			
			scrollpane.content.alpha = 0;
			scrollpane.contentHeightChange();
			
			setTimeout( function () {
				
				if( gotoDirection == 1 )
				{
					scrollpane.content.x = CssSprite(parent).cssSizeX;
					anim.run( scrollpane.content, { x:0 }, 345, Strong.easeOut );
					anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
				}
				else if( gotoDirection == 2 )
				{
					anim.run( scrollpane.content, { alpha: 1 }, 600, Strong.easeOut );
				}
				else if( gotoDirection == 3)
				{
					scrollpane.content.y = CssSprite(parent).cssSizeY;
					anim.run( scrollpane.content, { y:0 }, 345, Strong.easeOut );
					anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
				}
				else if( gotoDirection == 4)
				{
					scrollpane.content.y = -CssSprite(parent).cssSizeY;
					anim.run( scrollpane.content, { y:0 }, 345, Strong.easeOut );
					anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
				}
				else
				{
					// go back
					scrollpane.content.x = -CssSprite(parent).cssSizeX;
					anim.run( scrollpane.content, { x: 0 }, 345, Strong.easeOut );
					anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
				}
				
			}, 0);
		}
		
		private static var anim = new Animation();
		private static var anim2 = new Animation();
		
		private function pathClick (e:MouseEvent) :void
		{
			var btn:Button = Button(e.currentTarget);
			var lb:String = btn.label;
			var pth:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator;
			var bt:Button;
			var i:int;
			
			for( i= 0; i<pathLabels.items.length; i++ ) {
				bt = Button(pathLabels.items[i]);
				if( bt.label != "Root" ) {
					pth += bt.label + CTOptions.urlSeparator;
				}
				if( bt.label == lb ) {
					break;
				}
			}
			
			showMediaItems( pth, i >= pathLabels.items.length-1 ? 2 : 0 );
			
			setTimeout( function() {
				try {
					Application.instance.view.panel.src.newSize(null);
				}catch(e:Error) {
					Console.log( "New Size Error " + e);
				}
			}, 0);
		}
		
		private function addFileHandler (e:MouseEvent) :void {
			selectFile();
		}
		
		// browser for import file to raw and min folders
		private function selectFile () :void
		{
			var docsDir:File = File.desktopDirectory;
			
			try {
				docsDir.browseForOpen("Select File");
				docsDir.addEventListener(Event.SELECT, fileSelected); 
			}catch (error:Error){
				Console.log("Select template file error: " + error.message);
			}
		}
		
		private function fileSelected (event:Event) :void
		{
			var file:File = File( event.target );
			
			if( file.exists )
			{
				// Copy file to /raw and /min folders
				var fi:FileInfo = FileUtils.fileInfo( file.url );
				//var fi:FileInfo = di.clone(); // FileInfo returns static object 
				//di = FileUtils.fileInfo( currDir );
				
				var dir:String = CTTools.projectDir + CTOptions.urlSeparator;
				var webdir:String = currDir.substring( CTTools.projectDir.length + 4 );
				
				var f1:String =  dir + CTOptions.projectFolderRaw + CTOptions.urlSeparator + (webdir == "" ? "" : webdir + CTOptions.urlSeparator ) + fi.filename;
				var f2:String =  dir + CTOptions.projectFolderMinified + CTOptions.urlSeparator + (webdir == "" ? "" : webdir + CTOptions.urlSeparator ) + fi.filename;
				
				if( CTOptions.verboseMode ) {
					Console.log("Copy "+file.url+"to: " + f1 + " and " + f2 );
				}
				
				CTTools.copyFile( file.url, f1 );
				CTTools.copyFile( file.url, f2 );
				
				setTimeout( function () {
					showMediaItems( currDir, 2 );
				}, 0);
				
			}
		}
		
		private function listDirectory (url:String) :void {
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
				ico = new Button([ new IconFromFile("app:/"+Options.iconDir+"/folder.png", Options.iconSize, Options.iconSize), fi.filename ], 0, 0, itemList, styleSheet, '', 'media-item-btn',false);
				ico.addEventListener( MouseEvent.CLICK, folderBtnClick );
				
			}else{
				// display file icon
				var file_ico:Sprite;
				if( fi.type.substring(0,5) == "image") {
					file_ico = new IconFromFile("app:/"+Options.iconDir+"/file-image.png", Options.iconSize, Options.iconSize);
				}else if( fi.type == "html" || fi.type == "script" ) {
					file_ico = new IconFromFile("app:/"+Options.iconDir+"/file-code.png", Options.iconSize, Options.iconSize);
				}else if( fi.type == "audio" ) {
					file_ico = new IconFromFile("app:/"+Options.iconDir+"/file-audio.png", Options.iconSize, Options.iconSize);
				}else{
					file_ico = new IconFromFile("app:/"+Options.iconDir+"/file-text.png", Options.iconSize, Options.iconSize);
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
				
				mfi.x = cssLeft;
				
				mfi.setWidth( btn.cssSizeX - cssLeft*2 );
				
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
					showFileInfo ( file, btn );
					
					var fi:FileInfo = FileUtils.fileInfo( file.url );
					
					if( fi.type == "html" || fi.type == "script" || fi.type.substring(0,5) == "image" ) {
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
			if( clickScrolling ) {
				clickScrolling = false;
			}else{
				showMediaItems( currDir + CTOptions.urlSeparator + Button(event.currentTarget).label, 1 );
			}
		}
		
		private function dirlistAsync (event:FileListEvent) :void {
			var list:Array = event.files;
			var files:Array = new Array();
			var folders:Array = new Array();
			var file:File;
			var i:int;
			var fi:FileInfo;
			
			for (i = 0; i < list.length; i++) {
				file = File( list[i] );
				fi = FileUtils.fileInfo( file.url );
				if( file.isDirectory ) {
					folders.push( { name: fi.filename, url: list[i] } );
				}else{
					files.push(  { name: fi.filename, url: list[i] });
				}
				
			}
			folders.sortOn("name");
			files.sortOn("name");
			
			for(i=0; i<folders.length; i++) {
				displayFile( folders[i].url );
			}
			for(i=0; i<files.length; i++) {
				displayFile( files[i].url );
			}
			
			itemList.format();
			itemList.init();
			scrollpane.contentHeightChange();
			
			setWidth( getWidth() );
		}
	}
}
