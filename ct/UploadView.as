package ct
{	
	import agf.tools.Application;
	import agf.Main;
	import agf.Options;
	import agf.icons.IconFromFile;
	import agf.tools.Console;
	import flash.html.*;
	import flash.display.*;
	import flash.text.*;
	import flash.net.URLRequest;
	import flash.net.SharedObject;
	import flash.filesystem.File;
	import flash.events.*;
	import flash.utils.setTimeout;
	import agf.ui.*;
	import agf.html.CssStyleSheet;
	import agf.html.CssSprite;
	
	public class UploadView extends Sprite
	{
		public function UploadView () 
		{
			if( CTTools.activeTemplate ) {
				CTUploader.forceExit = false;
				container = Application.instance.view.panel;
				container.addEventListener(Event.RESIZE, newSize);
				if( CTUploader.uploading ) {
					init();
					displayFiles();
					return;
				}
					
				var w:int = container.getWidth();
				var h:int = container.getHeight();
				
				upl_cont = new CssSprite( w, h, null, container.styleSheet, 'body', '', '', true);
				addChild(upl_cont);
				upl_cont.init();
				
				upl_body = new CssSprite(w, h, upl_cont, container.styleSheet, 'div', '', 'editor upload-container', false);
				upl_body.setWidth( w - upl_body.cssBoxX );
				upl_body.setHeight( h - upl_body.cssBoxY );
				if( CTOptions.animateBackground ) {
					HtmlEditor.dayColorClip( upl_body.bgSprite );
				}
				
				uploadText = new Label( w, 20, upl_body, container.styleSheet, '', 'upload-title', false);
				uploadText.label = Language.getKeyword( "Start Upload Website" );
				uploadText.x = upl_body.cssLeft;
				uploadText.y = upl_body.cssTop;
				
				startBtn = new Button( [  new IconFromFile(Options.iconDir + "/connect.png",Options.iconSize, Options.iconSize), Language.getKeyword("Start Publish") ],0,0,upl_body, container.styleSheet, '','publish-start-btn',false);
				startBtn.x = upl_body.cssLeft + startBtn.cssMarginLeft;
				startBtn.y = upl_body.cssTop + uploadText.y + uploadText.cssSizeY + startBtn.cssMarginTop;
				startBtn.addEventListener( MouseEvent.CLICK, startBtnHandler);
				
				infoText = new TextField();
				infoText.embedFonts = Options.embedFonts;
				infoText.antiAliasType = Options.antiAliasType;
				infoText.x = upl_body.cssLeft;
				infoText.y = startBtn.y + startBtn.cssSizeY + startBtn.cssMarginBottom;
				infoText.width = startBtn.x - infoText.x;
				infoText.height = h - infoText.y;
				infoText.border = false;
				infoText.defaultTextFormat = container.styleSheet.getTextFormat( ["*", "body", ".upload-container", ".upload-text", ".upload-info"] );
				
				var info:String = "Information\n\n";
				info += "Server-Path:  " + CTOptions.uploadScript  + "\n";
				if( ( CTOptions.debugOutput || CTOptions.verboseMode ) && !CTOptions.userMode ) {
					info += "Method:       " + CTOptions.uploadMethod.toUpperCase() + "\n";
					info += "Folder:       " + CTTools.projectDir + CTOptions.urlSeparator + CTOptions.localUploadFolder  + "\n";
					info += "Send List:    " + CTOptions.uploadSendFileList  + "\n";
					info += "Template:     " + CTTools.activeTemplate.name + " " + CTTools.activeTemplate.version + "\n";
					info +=  CTOptions.appName  + " " +CTOptions.version + "\n"
				}
				
				infoText.text = info;
				addChild( infoText );
				
			}
		}
		
		private function startBtnHandler (e:Event):void
		{
			init();
			displayFiles();
		}
		
		public var container: Panel;
		public var infoText:TextField;
		private var scrollContainer:ScrollContainer;
		private var styleSheet:CssStyleSheet;
		
		private var upl_cont:CssSprite;
		private var upl_body:CssSprite;
		
		private var progress:Progress;
		private var startBtn:Button;
		private var abortBtn:Button;
		
		private var uploadText:Label;
		
		public function getProgress (  ) :Number {
			return progress ? progress.value : 0;
		}
		public function showProgress ( v ) :void {
			if( progress ) {
				progress.value = v;
			}
		}
		
		public function init (): void
		{
			if( styleSheet == null ) styleSheet = Main(Application.instance).config;
			
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			if(upl_cont != null)  {
				if( upl_body != null) {
					if( uploadText && upl_body.contains( uploadText ) ) upl_body.removeChild( uploadText );
					if( progress && upl_body.contains( progress ) ) upl_body.removeChild( progress);
					if( abortBtn && upl_body.contains( abortBtn ) ) upl_body.removeChild( abortBtn);
					if( infoText && upl_body.contains( infoText ) ) upl_body.removeChild( infoText);
					if( upl_cont.contains( upl_body ) ) upl_cont.removeChild( upl_body);
				}
				if(contains(upl_cont)) removeChild(upl_cont);
				upl_body = null;
				upl_cont = null;
			}
			
			upl_cont = new CssSprite( w, h, null, styleSheet, 'body', '', '', true);
			addChild(upl_cont);
			upl_cont.init();
			
			upl_body = new CssSprite(w, h, upl_cont, styleSheet, 'div', '', 'editor upload-container', false);
			upl_body.setWidth( w - upl_body.cssBoxX );
			upl_body.setHeight( h - upl_body.cssBoxY );
			
			if( CTOptions.animateBackground ) {
				HtmlEditor.dayColorClip( upl_body.bgSprite );
			}
			
			uploadText = new Label(w, 20, upl_body, styleSheet, '', 'upload-title', false);
			uploadText.label = Language.getKeyword( "Upgrading Website" );
			uploadText.x = upl_body.cssLeft;
			uploadText.y = upl_body.cssTop;
			
			abortBtn = new Button( [Language.getKeyword("Cancel Upload")], 0, 19, upl_body, styleSheet, '', 'upload-abort', false);
			
			progress = new Progress( w-(abortBtn.getWidth() + upl_body.cssBoxX + 10), 19, upl_body, styleSheet, '', 'upload-progress', false);
			
			var rs:Number = Math.max(progress.cssSizeY, abortBtn.cssSizeY);
			
			abortBtn.x = Math.floor( upl_body.cssRight-(abortBtn.getWidth() + upl_body.cssBoxX) );
			abortBtn.y = upl_body.cssTop + uploadText.cssSizeY + uploadText.cssMarginBottom + rs - (abortBtn.cssSizeY * .5);
			abortBtn.addEventListener(MouseEvent.CLICK, abortHandler);
			
			progress.value = 0;
			progress.x = upl_body.cssLeft;
			progress.y = upl_body.cssTop + uploadText.cssSizeY + uploadText.cssMarginBottom + rs - progress.cssSizeY * .5;
		
			infoText = new TextField();
			infoText.embedFonts = Options.embedFonts;
			infoText.antiAliasType = Options.antiAliasType;
			infoText.x = upl_body.cssLeft;
			infoText.y = progress.y + rs + Math.max(progress.cssMarginBottom, abortBtn.cssMarginBottom);
			infoText.width = w - upl_body.cssBoxX;
			infoText.height = h - 100;
			infoText.border = false;
			infoText.defaultTextFormat = styleSheet.getTextFormat( ["*","body",".upload-container",".upload-text"] );
			upl_body.addChild( infoText );
		}
		
		private function goExit () :void {
			Application.instance.cmd("TemplateTools edit-content");
		}
		
		public function hideProgress (aborted:Boolean=false): void {
			if( uploadText && upl_body ) {
				uploadText.label = aborted ? Language.getKeyword("Upload Aborted") : Language.getKeyword("Website Upgraded");
				uploadText.x = upl_body.cssLeft + (upl_body.getWidth() - uploadText.getWidth())/2; 
				if( uploadText.x < upl_body.cssLeft ) uploadText.x = upl_body.cssLeft;
				infoText.y = upl_body.cssTop + 40;
				if( aborted ) {
					infoText.text = "";
					setTimeout( goExit, 2500 );
				}
			}
			if( abortBtn ) abortBtn.visible = false;
			if( progress ) progress.visible = false;
		}
		public function unhideProgress (): void {
			if( uploadText && upl_body ) {
				uploadText.label = Language.getKeyword( "Upgrading Website" );
				uploadText.x = upl_body.cssLeft + (upl_body.getWidth() - uploadText.getWidth())/2; 
				if( uploadText.x < upl_body.cssLeft ) uploadText.x = upl_body.cssLeft;
				infoText.y = upl_body.cssTop + 70;
			}
			if( abortBtn ) abortBtn.visible = true;
			if( progress ) progress.visible = true;
			if( infoText ) infoText.visible = true;
			
		}
		public function log (v:String, append:Boolean = false): void {
			infoText.text = append ? infoText.text + v : v;
		}
		
		public function newSize(e: Event): void {
			var w:int = container.getWidth();
			if( upl_body ) upl_body.setWidth( w - upl_body.cssBoxX );
			if( upl_cont ) upl_cont.setWidth( w - upl_cont.cssBoxX );
			if( abortBtn ) abortBtn.x = upl_body.cssRight - (abortBtn.cssSizeX + upl_body.cssBoxX);
			if( progress ) progress.setWidth( w-(abortBtn.cssSizeX + upl_body.cssBoxX + 10) );
			if( infoText ) {
				infoText.width = w - upl_body.cssBoxX;
				infoText.height = w - (infoText.y + upl_body.cssBoxX);
			}
			if( uploadText ){ 
				uploadText.setWidth( w - uploadText.cssBoxX );
				uploadText.setHeight( uploadText.textField.textHeight );
			}
		}
		
		private function saveDone () :void {
			setTimeout(displayUpload, 350);
		}
		
		// requird method for CTTools
		public function displayFiles(): void {
			if( CTTools.projectDir ) {
				if(	CTTools.saveDirty ) {
					CTTools.showRequireSave( saveDone ); 
				}else{
					setTimeout(displayUpload, 350);
				}
			}
		}
		private static function uploadComplete (errors:Boolean = false) :void {
			if( errors ) {
				var win:Window = Window( Application.instance.window.InfoWindow( 
								"UploadCompleteWindow", errors ? Language.getKeyword("Upload Errors") : Language.getKeyword("Upload Complete"), errors ? Language.getKeyword("CT-UploadErrors-MSG") : Language.getKeyword("CT-UploadComplete-MSG"), {
					continueLabel:Language.getKeyword( "Upload Complete OK" ),
					allowCancel: false,
					autoWidth:false,
					autoHeight:true
					}, 'upload-complete-window') );
				
				Application.instance.windows.addChild( win );
			}
			if( errors && !CTOptions.verboseMode ) {
				Application.instance.cmd("Console show console");
			}
			if( CTUploader.fileErrors ) {
				var errs:Array = CTUploader.fileErrors;
				var str:String;
				if( errs.length > 0 ) {
					if( CTUploader.viewPanel ) CTUploader.viewPanel.log( "\nProblems:\n", true) ;
					for( var i:int=0; i<errs.length; i++ ) {
						str = "" + errs[i].name + " is too large";
						Console.log( str); 
						if( CTUploader.viewPanel ) CTUploader.viewPanel.log( str + "\n", true) ;
					}
				}
			}
		}
		public static function showAbortError () :void {
			var win:Window = Window( Application.instance.window.InfoWindow( 
							"UploadAbortErrorWindow", Language.getKeyword("Upload Abort"),  Language.getKeyword("CT-UploadAbort-MSG") , {
				complete: function(ok:Boolean):void {
					if( ok ) {
						CTUploader.forceExit = true;
					}else{
						CTUploader.forceExit = false;
						CTUploader.uploading = true;
						CTUploader.nextFile();
					}
				},
				continueLabel:Language.getKeyword( "Abort Upload" ),
				allowCancel: true,
				cancelLabel: Language.getKeyword( "Continue Uploading" ),
				autoWidth:false,
				autoHeight:true
				}, 'upload-abort-window') );
			
			Application.instance.windows.addChild( win );
		}
		private function abortHandler (e:Event): void {
			log("Aborting...");
			CTUploader.forceExit = true;
		}
		private function displayUpload (): void {
			// Init upload if not running..
			if( !CTUploader.uploading ) {
				log("Preparing");
				CTUploader.uploadSite( uploadComplete );
			}else{
				// fix viewPanel ref
				log("Searching");
				showProgress( CTUploader.ltProgress );
				CTUploader.viewPanel = this;
			}
		}
	
	}
}
