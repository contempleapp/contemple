package ct.ctrl 
{
	import flash.events.*;
	import flash.text.*;
	import agf.Options;
	import agf.html.*;
	import agf.ui.*;
	import agf.icons.IconFromFile;
	import ct.CTEvent;
	
	public class DownloadInfo extends CssSprite 
	{
		public function DownloadInfo( name:String, tgt:Object, w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false ) {
			super(w, h, parentCS, css, "downloadinfo", cssId, cssClasses, true);
			dlName = name;
			dlTgt = tgt;
			if( typeof( tgt.addEventListener) == "function" ) {
				tgt.addEventListener( ProgressEvent.PROGRESS, progressHandler );
			}
			if(!noInit) init();
			
			create();
		}
		
		internal var dlOverview:DownloadOverview;
		
		public var finish:Boolean = false;
		public var dlName:String;
		public var dlTgt:Object;
		
		private var _aborted:Boolean = false;
		public function get aborted () :Boolean {
			return _aborted;
		}
		
		public var progress:Progress;
		public var cancelButton:Button;
		public var label:Label;
		
		public function showReload () :void {
			if( cancelButton && contains( cancelButton ) ) removeChild( cancelButton );
			cancelButton = new Button([new IconFromFile(Options.iconDir + "/sync-btn.png",Options.btnSize,Options.btnSize)], 0,0,this,styleSheet,'','download-info-close',false);
			cancelButton.y = progress.y + Math.ceil( ( progress.cssSizeY - cancelButton.cssSizeY) / 2) + 2;
			_aborted = true;
			cancelButton.addEventListener( MouseEvent.CLICK, reloadHandler );
			progress.swapState("active");
		}
		
		private function reloadHandler (event:Event) :void
		{
			dlOverview.reloadDL( this );
		}
		
		private function cancelHandler (event:Event) :void
		{
			dlOverview.cancelDL( this );
		}
		
		public function clear () :void {
			if( dlTgt ) {
				if( typeof( dlTgt.removeEventListener) == "function" ) {
					dlTgt.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
				}
			}
		}
		
		public function create () :void
		{
			if( cancelButton && contains( cancelButton ) ) removeChild( cancelButton );
			if( progress && contains( progress ) ) removeChild( progress );
			if( label && contains( label ) ) removeChild( label );
			
			label = new Label (0,0,this,styleSheet,'','download-info-label',true);
  			
			label.textField.autoSize = TextFieldAutoSize.LEFT;
			label.label = dlName;
			label.init();
			
			progress = new Progress(0,20,this,styleSheet,'','download-info-progress',false);
			progress.y = cssTop + label.cssSizeY + Math.max( progress.cssMarginTop, label.cssMarginBottom );
			progress.x =  cssLeft + progress.cssMarginX;
			progress.showPercentValue = false;
			progress.value = 0;
			
			label.x = cssLeft + progress.cssMarginLeft;
			label.y = cssTop;
			cancelButton = new Button([new IconFromFile(Options.iconDir + "/close-btn.png",Options.btnSize,Options.btnSize)], 0,0,this,styleSheet,'','download-info-close',false);
			cancelButton.y = progress.y + Math.ceil( ( progress.cssSizeY - cancelButton.cssSizeY) / 2) + 2;
			cancelButton.addEventListener( MouseEvent.CLICK, cancelHandler );
			
			setHeight( cancelButton.cssSizeY + cancelButton.y );
		}
		
		private function progressHandler ( e:ProgressEvent) :void {
			if( e.bytesLoaded >= e.bytesTotal ) {
				dlTgt.removeEventListener( ProgressEvent.PROGRESS, progressHandler );
				progress.value = 1;
				finish = true;
			}else{
				progress.value = e.bytesLoaded / e.bytesTotal;
			}
		}
		
		public override function setWidth ( w:int ) :void {
			super.setWidth(w);
			progress.setWidth( w - (cancelButton.cssSizeX + cancelButton.cssBoxX + cancelButton.cssMarginX + progress.cssBoxX + progress.cssMarginX + cssBoxX ) );
			cancelButton.x = progress.x + progress.cssSizeX;
		}
		
	}
}
