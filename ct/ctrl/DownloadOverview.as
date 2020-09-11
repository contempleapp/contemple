package ct.ctrl 
{
	import flash.events.*;
	import flash.text.*;
	import agf.Options;
	import agf.html.*;
	import agf.ui.*;
	import agf.animation.Animation;
	import fl.transitions.easing.Regular;
	import agf.icons.IconFromFile;
	import ct.CTEvent;
	
	public class DownloadOverview extends CssSprite 
	{
		public function DownloadOverview( _label:String="Downloads:", w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false ) {
			super(w, h, parentCS, css, "downloadoverview", cssId, cssClasses, true);
			if(!noInit) init();
			create(_label);
		}
		
		public var onEmpty:Function;
		public var label:Label;
		public var itemList:ItemList;
		public var closeButton:Button;
		private var anim:Animation;
		private var animating:Boolean=false;
		private static var downloads:Array = null;
		
		public function create ( labelText:String ) :void
		{
			if( !downloads ) downloads = [];
			if( itemList && contains(itemList) ) removeChild( itemList );
			if( label && contains( label ) ) removeChild( label );
			if( closeButton && contains( closeButton ) ) removeChild( closeButton );
			
			label = new Label (0,0,this,styleSheet,'','download-info-label',true);
			label.x = cssLeft;
			label.y = cssTop;
			label.textField.autoSize = TextFieldAutoSize.LEFT;
			label.label = labelText;
			label.init();
			
			itemList = new ItemList(0,0,this,styleSheet,'','downloadinfo-list',false);
			itemList.margin = 4;
			itemList.x = cssLeft;
			itemList.y = cssTop + label.cssSizeY;
			
			closeButton = new Button([new IconFromFile(Options.iconDir+"/close-btn.png",Options.btnSize,Options.btnSize)],0,0,this,styleSheet,'','download-overview-close',false);
			closeButton.addEventListener(MouseEvent.CLICK, closeHandler );
			
			anim = new Animation();
			anim.addEventListener( Event.COMPLETE, animComplete);
			addChild( anim );
			
			visible = false;
			
			showDownloads();
			
			show(true);
		}
		
		public function animComplete ( e:Event ) :void {
			if( alpha < 0.5 ) {
				alpha = 1;
				visible = false;
				for( var i:int=downloads.length-1; i>=0; i-- ) {
					if( downloads[i].finish ) downloads.splice(i,1);
				}
				if( downloads.length == 0 ) downloads = null;
			}
		}
		public function show ( vis:Boolean = true ) :void {
			
			if( animating ) {
				anim.stop();
			}
			if( vis ) {
				visible = true;
				alpha = 1;
			}else{
				
				anim.run(this, {alpha:0}, 456, Regular.easeOut, 3000 );
			}
		}
		
		public function closeHandler (e:MouseEvent) :void {
			show(false);
		}
		
		public function showDownloads () :void
		{
			var w:int = getWidth();
			
			itemList.clearAllItems();
			
			for( var i:int=0; i<downloads.length; i++) {
				DownloadInfo(downloads[i]).setWidth( w );
				itemList.addItem( DownloadInfo(downloads[i]) );
			}
			itemList.format(true);
			itemList.init();
			
			init();
		}
		
		public function addDownload ( name:String, tgt:Object ) :void 
		{
			for( var i:int = downloads.length - 1; i >= 0; i-- ) {
				if( downloads[i].dlName == name ) { 
					if( downloads[i].aborted ) {
						// removeDownload( downloads[i].dlName );
						downloads[i].clear();
						downloads.splice(i,1);
						break;
					}else{
						return;
					}
				}
			}
			
			var dli:DownloadInfo = new DownloadInfo( name, tgt, 0, 0, itemList, styleSheet, '', 'download-info', false) ;
			dli.dlOverview = this;
			
			downloads.push( dli );
			showDownloads();
		}
		public function cancelDL ( dl:DownloadInfo ) :void {
			dispatchEvent( new CTEvent( dl, CTEvent.CANCEL) );
		}
		
		public function reloadDL ( dl:DownloadInfo ) :void {
			dispatchEvent( new CTEvent( dl, CTEvent.RELOAD) );
		}
		
		public function hasDownload ( name:String ) :Boolean 
		{
			for( var i:int=0; i < downloads.length; i++ ) {
				if( downloads[i].dlName == name ) {
					return true;
				}
			}
			return false;
		}
		public function getDownload ( name:String ) :DownloadInfo 
		{
			for( var i:int=0; i < downloads.length; i++ ) {
				if( downloads[i].dlName == name ) {
					return DownloadInfo( downloads[i] );
				}
			}
			return null;
		}
		public function removeDownload ( name:String ) :void 
		{
			for( var i:int=downloads.length-1; i>=0; i-- ) {
				if( !downloads[i].finish ) {
					return;
				}
			}
			onEmpty();
		}
		
		public override function setHeight (h:int) :void {
			// no set height..
		}
		
		public override function setWidth (w:int) :void
		{
			super.setWidth( w  - cssBoxX);
			
			if( itemList && itemList.items ) {
				for( var i:int=0; i<itemList.items.length; i++) {
					itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + cssBoxX) );
				}
				itemList.init();
			}
			if( closeButton ) {
				closeButton.y = 0;
				closeButton.x = w - (closeButton.cssSizeX + closeButton.cssMarginX) + 4;
			}
		}
		
	}
	
}
