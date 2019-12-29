package ct
{	
	import agf.tools.Application;
	import agf.Main;
	import agf.ui.Panel;
	import agf.tools.Console;
	import flash.html.*;
	import flash.display.*;
	import flash.net.URLRequest;
	import flash.filesystem.File;
	import flash.events.*;
	import agf.ui.*;
	import flash.media.StageWebView; 
    import flash.geom.Rectangle; 
	import ct.ctrl.InputTextBox;
	
	public class Preview extends Sprite
	{
		public function Preview () {
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			Main(Application.instance).mainMenu.addEventListener( MouseEvent.MOUSE_DOWN, mobilePopupOpen );
			
			webView = new StageWebView( CTOptions.nativePreview );
			displayFiles();
		}
		
		public var webView:StageWebView;
		
        public var container: Panel;
		
		/*
		private var _posLeft:int = 0;
		public function get posLeft () :int { 
			return _posLeft; 
		}
		public function set posLeft (v:int) :void {
			_posLeft = v; 
			newSize(null);
		}*/
		
		public function mobilePopupOpen ( e:Event) :void {
			Main(Application.instance).mainMenu.addEventListener( Event.CLOSE, mobilePopupClose );
			webView.stage = null;
		}
		  
		public function mobilePopupClose ( e:Event) :void {
			var m:Menu = Main(Application.instance).mainMenu;
			m.removeEventListener( MouseEvent.MOUSE_DOWN, mobilePopupOpen );
			m.removeEventListener( Event.CLOSE, mobilePopupClose );
		}
		
		public function newSize(e: Event): void {
			var main:CTMain = CTMain( Application.instance );
			if( webView.stage == null ) displayFiles();
			webView.viewPort = new Rectangle( 0, main.mainMenu.cssSizeY, container.stage.stageWidth, container.stage.stageHeight - main.mainMenu.cssSizeY ); 
		}
		
		public function stageOffsetY (n:int) :void {
			if( n == 0 ) {
				newSize(null);
			}else {
				var main:CTMain = CTMain( Application.instance );
				webView.viewPort = new Rectangle( 0, int( main.mainMenu.cssSizeY + n), container.stage.stageWidth, container.stage.stageHeight - main.mainMenu.cssSizeY ); 
			}
		}
		
		private function displayHTMLPreview () :void {
			if( CTTools.projectDir ) 
			{
				if( container && container.stage ) 
				{
					var main:CTMain = CTMain(Application.instance);
					
					webView.stage = container.stage;
					webView.viewPort = new Rectangle( 0, main.mainMenu.cssSizeY, container.stage.stageWidth, container.stage.stageHeight - main.mainMenu.cssSizeY );
					
					var filepath:String;
					filepath = CTTools.projectDir + CTOptions.urlSeparator +  CTOptions.previewFolder + CTOptions.urlSeparator + CTTools.activeTemplate.indexFile;
					 
					if( CTOptions.debugOutput ) Console.log("Preview: " + filepath);
					
					webView.loadURL( filepath + InputTextBox.getUniqueName("?") );
				}
			}
		}
		
		private function scriptError (e:Event) :void {
			Console.log( e.toString() );
		}
		
		private function saveDone () :void {
			displayHTMLPreview();
		}
		
		public function displayFiles(): void {
			if( CTTools.projectDir ) {
				if(	CTTools.saveDirty ) {
					CTTools.showRequireSave( saveDone ); 	
				}else{
					displayHTMLPreview();
				}
			}
		}
		
		private function updateText() :void {}
	
	}
}
