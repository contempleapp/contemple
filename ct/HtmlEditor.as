package ct
{
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.utils.setTimeout; 
	import agf.Main;
	import agf.Options;
	import agf.tools.*;
	import agf.events.*;
	import agf.icons.*;
	import agf.ui.*;
	import agf.html.*;
	import agf.html.CompactCode;
	import agf.html.HtmlParser;
	import flash.utils.setTimeout;
	import flash.filesystem.File;
	import flash.filters.*;
	import agf.html.CssUtils;
	import agf.utils.NumberUtils;
	import agf.animation.EnvelopeChannel;
	import ct.ctrl.InputTextBox;
	import flash.media.StageWebView; 
    import flash.geom.Rectangle; 

	public class HtmlEditor extends Sprite
	{
		public function HtmlEditor ()
		{
			if( ! CTTools.activeTemplate ) {
				Application.instance.cmd( "Application view StartScreen" );
				return;
			}
			
			var main:Main = Main(Application.instance);
			container = main.view.panel;
			main.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
			container.addEventListener(Event.RESIZE, newSize);
			create();
			displayFiles();
			newSize(null);
		}
		
		private function removePanel (e:Event) :void {
			if( webView ) {
				webView.stage = null;
			}
			Main(Application.instance).view.removeEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		public var container:Panel;
		public var editor:TemplateEditor;
		public static var webView:StageWebView; 
		public var reloadBtn:Button;
		public var adresBar:TextField;
		public var adresBarFMT:TextFormat;
		public var previewBg:CssSprite;
		public var resizeIcon:Button;
		
		public static var renderPreview:Boolean = true;
		public static var env:EnvelopeChannel;
		private static var history:Vector.<Object> = new Vector.<Object>();
		public static var maxHistory:int = 2;
		
		internal static var tmpEditorW:Number = 1;
		internal static var tmpEditorH:Number = 0.6;
		
		public function historyBack () :void {
			if( history && history.length > 0 ) {
				var uo:Object = history.pop();
				if( webView && webView.stage ) {
					webView.loadURL( uo.uri + InputTextBox.getUniqueName("?", 1) + uo.hash );
					if( adresBar ) adresBar.text = uo.uri;
				}
			}
		}
		
		public static function get isPreviewOpen () :Boolean {
			return (webView && webView.stage);
		}
		public static function get previewX () :int {
			return isPreviewOpen ? webView.viewPort.x : 0;
		}
		
		public static function get previewY () :int {
			return isPreviewOpen ? webView.viewPort.y : 0;
		}
		
		private function create () :void
		{
			var editor_w:Number = TemplateTools.editor_w;
			var editor_h:Number = TemplateTools.editor_h;
			
			if( webView == null ) webView = new StageWebView( CTOptions.nativePreview );
			if( previewBg && container.contains(previewBg)) container.removeChild( previewBg );
			if( reloadBtn && container.contains(reloadBtn)) container.removeChild( reloadBtn );
			if( resizeIcon && container.contains(resizeIcon)) container.removeChild( resizeIcon );
			if( adresBar && container.contains(adresBar) ) container.removeChild( adresBar );		
			if( editor && container.contains(editor) ) {
				container.removeChild( editor );
				editor = null;
			}
			
			var w:int = container.cssSizeX - container.cssBoxX;
			var h:int = container.cssSizeY - container.cssBoxY;
			
			editor = new TemplateEditor ( (w * editor_w), (h * editor_h), container, container.styleSheet, 'body', '','editor', false);
			container.addEventListener( MouseEvent.MOUSE_DOWN, resizeEditor );
			
			if( CTOptions.previewInEditor )				
			{
				previewBg = new CssSprite( 1,1, container, container.styleSheet, 'div', '', 'preview-bg', false );
				
				resizeIcon = new Button( [new IconFromFile("app:/"+Options.iconDir + CTOptions.urlSeparator + "ziehen-h.png", Options.btnSize, Options.btnSize)], 0, 0, container, container.styleSheet, '', 'preview-resize-icon', false);
				resizeIcon.addEventListener( MouseEvent.MOUSE_DOWN, resizeIconClick );
				
				reloadBtn = new Button( [new IconFromFile("app:/"+Options.iconDir + CTOptions.urlSeparator + "sync-btn.png",Options.iconSize,Options.iconSize)], 0, 0, container, container.styleSheet, '', 'preview-reload-btn', false);
				reloadBtn.addEventListener( MouseEvent.CLICK, reloadClick );
				
				adresBar = new TextField();
				adresBar.type = TextFieldType.INPUT;
				
				if( !adresBarFMT ) adresBarFMT = container.styleSheet.getTextFormat( ["*","body",".preview-adres-bar"] );
				adresBar.text = "AypQÜÄÖ";
				adresBar.setTextFormat( adresBarFMT );
				adresBar.height = adresBar.textHeight + (4*CssUtils.numericScale);
				adresBar.text = "";
				adresBar.embedFonts = Options.embedFonts;
				adresBar.antiAliasType = Options.antiAliasType;
				adresBar.addEventListener( FocusEvent.FOCUS_IN, adresActivate );
				adresBar.addEventListener( FocusEvent.FOCUS_OUT, adresDeactivate );
				
				var mh:Number = Math.max( resizeIcon.cssSizeY, reloadBtn.cssSizeY, adresBar.height );
				var list:Array = [resizeIcon,reloadBtn,adresBar];
				var L:int = list.length;
				for( var i:int=0; i < L; i++ ) {
					list[i].y = Math.floor( (mh-list[i].height) * .5 );
				}
				
				container.addChild( adresBar );
			}
			
			newSize(null);
			
			if(CTOptions.animateBackground ) {
				createDayChannel();
				redrawBG();
			}
		}
		
		private function adresActivate ( e:FocusEvent ) :void {
			if( stage ) {
				stage.addEventListener( KeyboardEvent.KEY_DOWN, adresKeyDown );
			}
		}
		
		private function adresKeyDown ( e:KeyboardEvent ) :void {
			if ( e.charCode == 13 ) {
				var filepath:String = adresBar.text;
				var s7:String = filepath.substring(0, 7);
				if( filepath.substring(0,4) == "www." ) {
					filepath = "http://" + filepath;
				}else if( s7 != "http://" && s7 != "file://" && filepath.substring(0, 8) != "https://" ) {
					filepath = CTTools.projectDir + CTOptions.urlSeparator +  CTOptions.previewFolder + CTOptions.urlSeparator + filepath;
				}
				loadWebURL( filepath );
			}
		}
		
		private function adresDeactivate ( e:FocusEvent ) :void {
			stage.removeEventListener( KeyboardEvent.KEY_DOWN, adresKeyDown );
		}
		
		public function reloadClick (e:Event=null): void {
			if( webView && webView.stage ) {
				var uo:Object = history[ history.length - 1 ];
				webView.loadURL(uo.uri + InputTextBox.getUniqueName("?", 1) + uo.hash );
			}
		}
		
		public static function showPreview( enabled:Boolean=true ) :void {
			if( !enabled ) {
				renderPreview = false;
				if( webView ) webView.stage = null;
				tmpEditorW = TemplateTools.editor_w;
				tmpEditorH = TemplateTools.editor_h;
				TemplateTools.editor_w = 1;
				TemplateTools.editor_h = 1;
			}else{
				renderPreview = true;
				TemplateTools.editor_w = tmpEditorW;
				TemplateTools.editor_h = tmpEditorH;
			}
		}
		
		public function collapseClick (e:Event=null) :void {
			if( renderPreview ) {
				renderPreview = false;
				webView.stage = null;
				tmpEditorW = TemplateTools.editor_w;
				tmpEditorH = TemplateTools.editor_h;
				TemplateTools.editor_w = 1;
			}else{
				renderPreview = true;
				TemplateTools.editor_w = tmpEditorW;
				TemplateTools.editor_h = tmpEditorH;
				setTimeout( displayFiles, 0 );
			}
			setTimeout( newSize, 50 );
			setTimeout( newSize, 120 );
		}
		
		public function newSize (e:Event=null) :void
		{
			var editor_w:Number = TemplateTools.editor_w;
			var editor_h:Number = TemplateTools.editor_h;
			
			var w:Number = Math.ceil( container.getWidth() );// container.cssSizeX - ( container.cssBoxX + 4 ) );				
			var h:Number = Math.ceil( container.getHeight() );
			
			if( editor ) {
				editor.setWidth( Math.ceil( w * editor_w) );
				editor.setHeight( Math.ceil( h * editor_h) );
			}
			
			if( Popup.topContainer ) {
				Popup.topContainer.setWidth( w * editor_w );
				Popup.topContainer.setHeight(Application.instance.mainMenu.cssSizeY + h * editor_h );
			}
			
			var tbh:int;
			var bw:int;
			var pvx:Number;
			var pvpos:Number;
			var pvwidth:int;
			var stw:Number;
			var sth:Number;
					
			
			if( CTOptions.previewAtBottom )
			{
				if(  editor_h >= 1 )
				{
					// Hide preview
					if( previewBg && previewBg.visible == true ) previewBg.visible = false;
					if( resizeIcon && resizeIcon.visible == true ) resizeIcon.visible = false;
					if( reloadBtn && reloadBtn.visible == true ) reloadBtn.visible = false;
					if( adresBar && adresBar.visible == true ) adresBar.visible = false;
				}
				else
				{
					bw = 0;
					pvx = h * (1-editor_h);
					pvpos = Math.ceil(h * editor_h );
					pvwidth = Math.ceil( h * (1-editor_h));
					
					if( previewBg ) {
						previewBg.x = 0;
						previewBg.y = pvpos;
						previewBg.setWidth( w );
						previewBg.setHeight( pvwidth );
						if( !previewBg.visible ) previewBg.visible = true;
					}
					
					if( resizeIcon && adresBar && reloadBtn ) {
						resizeIcon.x = 0;
						bw += resizeIcon.cssSizeX + resizeIcon.cssMarginX;
						tbh = Math.max( tbh, resizeIcon.height + resizeIcon.cssMarginY );
						if( !resizeIcon.visible ) resizeIcon.visible = true;
				
						adresBar.x = resizeIcon.x + resizeIcon.cssSizeX + resizeIcon.cssMarginRight;
						
						bw += reloadBtn.cssSizeX + reloadBtn.cssMarginX;
						adresBar.width = w - (bw + 4);
						tbh = Math.max( tbh, adresBar.height );
						if( !adresBar.visible ) adresBar.visible = true;
				
						reloadBtn.x = container.cssSizeX - (reloadBtn.cssSizeX + reloadBtn.cssMarginRight);
						
						tbh = Math.max( tbh, reloadBtn.height + reloadBtn.cssMarginY );
						if( !reloadBtn.visible ) reloadBtn.visible = true;
					
						resizeIcon.y = pvpos + Math.floor( (tbh - resizeIcon.cssSizeY) * .5 );
						reloadBtn.y = pvpos + Math.floor( (tbh - reloadBtn.cssSizeY) * .5 );
						adresBar.y = pvpos + Math.floor( (tbh - adresBar.height) * .5 );
					}
					
					stw = Application.instance.mainMenu.cssSizeY + tbh;
					sth = container.stage.stageHeight - (Application.instance.mainMenu.cssSizeY + 2 + tbh);
					
					if( webView && webView.stage && sth > 0 && stw > 0 ) {
						webView.viewPort = new Rectangle( 	Math.floor( 4 * CssUtils.numericScale), 
															stw + pvpos, 
															container.stage.stageWidth - ( 8 * CssUtils.numericScale), 
															pvwidth - (Math.floor( 4 * CssUtils.numericScale) + tbh) );
					}
					
				}
				
			}else{
				
				if(  editor_w >= 1 )
				{
					// Hide preview
					if( previewBg && previewBg.visible == true ) previewBg.visible = false;
					if( resizeIcon && resizeIcon.visible == true ) resizeIcon.visible = false;
					if( reloadBtn && reloadBtn.visible == true ) reloadBtn.visible = false;
					if( adresBar && adresBar.visible == true ) adresBar.visible = false;
				}
				else
				{
					tbh = 0;
					bw = 0;
					pvx = w * (1-editor_w);
					pvpos = Math.ceil(w * editor_w );
					pvwidth = Math.ceil( w * (1-editor_w));
					
					if( previewBg ) {
						previewBg.x = pvpos;
						previewBg.y = 0;
						previewBg.setWidth( pvwidth+1 );
						previewBg.setHeight( h );
						if( !previewBg.visible ) previewBg.visible = true;
					}
					
					if( resizeIcon && adresBar && reloadBtn ) {
						resizeIcon.x = pvpos + resizeIcon.cssMarginLeft;
						bw += resizeIcon.cssSizeX + resizeIcon.cssMarginX;
						tbh = Math.max( tbh, resizeIcon.height + resizeIcon.cssMarginY );
						if( !resizeIcon.visible ) resizeIcon.visible = true;
				
						adresBar.x = resizeIcon.x + resizeIcon.cssSizeX + resizeIcon.cssMarginRight;
						bw += reloadBtn.cssSizeX + reloadBtn.cssMarginX;
						adresBar.width = pvx - (bw + 4);
						tbh = Math.max( tbh, adresBar.height );
						if( !adresBar.visible ) adresBar.visible = true;
				
						reloadBtn.x = container.cssSizeX - (reloadBtn.cssSizeX + reloadBtn.cssMarginRight);
						tbh = Math.max( tbh, reloadBtn.height + reloadBtn.cssMarginY );
						if( !reloadBtn.visible ) reloadBtn.visible = true;
					
						resizeIcon.y = Math.floor( (tbh - resizeIcon.cssSizeY) * .5 );
						reloadBtn.y = Math.floor( (tbh - reloadBtn.cssSizeY) * .5 );
						adresBar.y = Math.floor( (tbh - adresBar.height) * .5 );
					}
					
					stw = Application.instance.mainMenu.cssSizeY + tbh;
					sth = container.stage.stageHeight - (Application.instance.mainMenu.cssSizeY + 2 + tbh);
					
					if( webView && webView.stage && sth > 0 && stw > 0 ) {
						webView.viewPort = new Rectangle( 	w * editor_w + 4, 
															stw, 
															pvwidth - 2, 
															sth );
					}
				}
				
			}
		}
		
		private function resizeIconClick (e:MouseEvent) :void {
			stage.addEventListener( MouseEvent.MOUSE_MOVE, resizeEditorMove);
			stage.addEventListener( MouseEvent.MOUSE_UP, resizeEditorUp);
		}
		
		private function resizeEditor (e:MouseEvent) :void {
			var d:int = 10 * CssUtils.numericScale;
			if( CTOptions.previewAtBottom ) {
				if( editor.mouseY > editor.getHeight() - d && editor.mouseY < editor.getHeight() + d *2) {
					stage.addEventListener( MouseEvent.MOUSE_MOVE, resizeEditorMove);
					stage.addEventListener( MouseEvent.MOUSE_UP, resizeEditorUp);
				}
			}else{
				if( editor.mouseX > editor.getWidth() -d && editor.mouseX < editor.getWidth() + d ) {
					stage.addEventListener( MouseEvent.MOUSE_MOVE, resizeEditorMove);
					stage.addEventListener( MouseEvent.MOUSE_UP, resizeEditorUp);
				}
			}
		}
	
		private function resizeEditorMove (e:MouseEvent) :void {
			if( CTOptions.previewAtBottom ) {
				TemplateTools.editor_h = NumberUtils.clamp( mouseY / container.getHeight(), .3, .8);
				TemplateTools.editor_w = 1;
			}else{
				TemplateTools.editor_w = NumberUtils.clamp( mouseX / container.getWidth(), .3, .8);
				TemplateTools.editor_h = 1;
			}
			newSize(null);
		}
		private function resizeEditorUp (e:MouseEvent) :void {
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, resizeEditorMove);
			stage.removeEventListener( MouseEvent.MOUSE_UP, resizeEditorUp);
		}
		
		public function displayFiles () :void {
			if( renderPreview && CTTools.procFiles ) {
				updateText();
			}
		}
		
		private function updateText ():void
		{
			var T:Template;
			var cpf:ProjectFile;
			var loc:String = "";
			
			if( (editor.currentEditor is ConstantsEditor) ) {
				T = ConstantsEditor(editor.currentEditor).currentTemplate;
				if( ConstantsEditor.currPF != null ) cpf = ConstantsEditor.currPF;
			}else if( (editor.currentEditor is AreaEditor) ) {
				T = AreaEditor(editor.currentEditor).currentTemplate;
				if( AreaEditor.currPF != null ) cpf = AreaEditor.currPF;
				if( AreaEditor.currItemName != "" ) loc += "#" + AreaEditor.currItemName;
			}
			if( !T ) {
				T = CTTools.activeTemplate;
			}
			if( !T ) return;
			
			// Get Templatr Index.html
			var pf: ProjectFile;
			
			if( !cpf ) pf = ProjectFile( CTTools.procFiles[ CTTools.projFileBy(T.indexFile, "filename") ]);
			else pf = cpf;
			
			if (pf && pf.type == "html")
			{
				var editor_w:Number = TemplateTools.editor_w;
				var editor_h:Number = TemplateTools.editor_h;
				
				var p:CssSprite = CssSprite( Application.instance.view );
				var w:Number = p.getWidth() * (1-editor_w);
				var h:Number = p.getHeight() * (1-editor_h);
				var tbh:int = 0;
				
				if(reloadBtn) {
					tbh = Math.max( tbh, reloadBtn.cssSizeY);
				}
				
				if( container && container.stage ) {
					var main:CTMain = CTMain(Application.instance);
					if( webView.stage == null ) webView.stage = container.stage;
					var filepath:String;
					filepath = CTTools.projectDir + CTOptions.urlSeparator +  CTOptions.previewFolder + CTOptions.urlSeparator + pf.filename;
					loadWebURL( filepath, loc );
				}
			}else{
				if( CTOptions.debugOutput ) Console.log( "Preview: No Project File Found");
			}
		}
		
		public function loadWebURL (uri:String, hash:String="") :void {
			if( renderPreview && webView )
			{
				newSize( null );
				
				var rnd:String = InputTextBox.getUniqueName("?", 1);
				if( history ) { 
					history.push( { hash:hash, rnd:rnd, uri:uri } );
					if( history.length > maxHistory ) history.shift();
				}
				
				webView.loadURL( uri + rnd + hash );
				
				if( adresBar ) 
				{
					var fid:int = uri.lastIndexOf( "/" );
					var f:String;
					if( fid >= 0 ) {
						f = uri.substring( fid+1);
					}else{
						f = uri;
					}
					
					if( !CTOptions.userMode ) {
						f += rnd + hash;
					}else if (  CTOptions.showLinkHash ) {
						f += hash;
					}
					adresBar.text = f;
					adresBar.setTextFormat( adresBarFMT );
				}
			}
		}
		
		private function createDayChannel () :void {
			var dt:Date = new Date();
			if ( env == null ) {
				env = new EnvelopeChannel();
				if( dt.month < 4 || dt.month > 9 ) {
					env.storeFrame(1, CTOptions.animateBackgroundMin);
					env.storeFrame(6.5, CTOptions.animateBackgroundMin);
					env.storeFrame(7.5, CTOptions.animateBackgroundMin + (CTOptions.animateBackgroundMax-CTOptions.animateBackgroundMin)/2);
					env.storeFrame(14, CTOptions.animateBackgroundMax);
					env.storeFrame(16, CTOptions.animateBackgroundMin + (CTOptions.animateBackgroundMax-CTOptions.animateBackgroundMin)/2);
					env.storeFrame(20, CTOptions.animateBackgroundMin);
					env.storeFrame(25, CTOptions.animateBackgroundMin);
				}else{
					// summertime
					env.storeFrame(1, CTOptions.animateBackgroundMin);
					env.storeFrame(4, CTOptions.animateBackgroundMin);
					env.storeFrame(5, CTOptions.animateBackgroundMin + (CTOptions.animateBackgroundMax-CTOptions.animateBackgroundMin)/2);
					env.storeFrame(9, CTOptions.animateBackgroundMax);
					env.storeFrame(18, CTOptions.animateBackgroundMax);
					env.storeFrame(19, CTOptions.animateBackgroundMin + (CTOptions.animateBackgroundMax-CTOptions.animateBackgroundMin)/2);
					env.storeFrame(23, CTOptions.animateBackgroundMin);
					env.storeFrame(25, CTOptions.animateBackgroundMin);
				}
			}
		}
		
		public static function dayColorClip (sp:Sprite) :void {
			if( env ) {
				var dt:Date = new Date();
				var d:Number = dt.hours + (dt.minutes/60);
				var val:Number = env.getValue(d);
				var matrix:Array = new Array();
				matrix = matrix.concat([val, 0, 0, 0, 0]); // red
				matrix = matrix.concat([0, val, 0, 0, 0]); // green
				matrix = matrix.concat([0, 0, val, 0, 0]); // blue
				matrix = matrix.concat([0, 0, 0, 1, 0]); // alpha
				var cmf:ColorMatrixFilter = new ColorMatrixFilter(matrix);
				sp.filters = [ cmf ];
			}
		}
		
		private function redrawBG () :void {
			dayColorClip( editor.bgSprite );
			if ( CTOptions.animateBackground ) {
				setTimeout( redrawBG, 5 * 60 * 1000 ); // 5 min
			}
		}
		
	}
}