package ct
{
	import agf.events.PopupEvent;
	import agf.utils.FileUtils;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import flash.filesystem.*;
	import agf.Main;
	import agf.Options;
	import agf.ui.*;
	import agf.html.*;
	import agf.tools.*;
	import agf.icons.IconFromFile;
	
	/**
	* StartScreen provides three options to intall a website/template
	*
	* - Open existing Project
	* - Connect to Website (Install website)
	* - New with Template Folder/ZipFile
	*/
	
	public class Settings extends Sprite 
	{
		public function Settings () 
		{
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			create();
		}
		
		private function create () :void
		{
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			cont = new CssSprite( w, h, null, container.styleSheet, 'body', '', '', true);
			addChild(cont);
			cont.init();
			
			body = new CssSprite(w, h, cont, container.styleSheet, 'div', '', 'editor preferences', false);
			body.setWidth( w - body.cssBoxX );
			body.setHeight( h - body.cssBoxY );
			
			scrollpane = new ScrollContainer(0, 0, body, body.styleSheet, '', '', false);
			
			if( CTOptions.animateBackground ) {
				HtmlEditor.dayColorClip( body.bgSprite );
			}
			
			title = new Label(0, 0, scrollpane.content, container.styleSheet, '', 'preferences-title', false);
			title.label = Language.getKeyword( "Application Settings" );
			title.textField.autoSize = TextFieldAutoSize.LEFT;
			
			if ( !CTOptions.isMobile )
			{
				monitorFilesLabel = new Label(w,20, scrollpane.content, container.styleSheet, '', 'preferences-label', false );
				monitorFilesLabel.label = Language.getKeyword( "Monitor Files" );
				monitorFilesLabel.textField.autoSize = TextFieldAutoSize.LEFT;
				
				monitorFilesValue = new Toggle([CTOptions.monitorFiles ? "On":"Off"], 0, 0, scrollpane.content, container.styleSheet, '', 'preferences-toggle', false );
				monitorFilesValue.value = CTOptions.monitorFiles;
				monitorFilesValue.addEventListener( Event.CHANGE, monitorFilesClick );
			}
			else
			{
				softKeyboardLabel = new Label(w,20, scrollpane.content, container.styleSheet, '', 'preferences-label', false );
				softKeyboardLabel.label = Language.getKeyword( "Recognize Soft Keyboard" );
				softKeyboardLabel.textField.autoSize = TextFieldAutoSize.LEFT;
				
				softKeyboardValue = new Toggle([CTOptions.softKeyboard ? "On":"Off"], 0, 0, scrollpane.content, container.styleSheet, '', 'preferences-toggle', false );
				softKeyboardValue.value = CTOptions.softKeyboard;
				softKeyboardValue.addEventListener( Event.CHANGE, softKeyboardClick );
			}
			
			autoSaveLabel = new Label(w,20, scrollpane.content, container.styleSheet, '', 'preferences-label', false );
			autoSaveLabel.label = Language.getKeyword( "Auto Save" );
			autoSaveLabel.textField.autoSize = TextFieldAutoSize.LEFT;
			
			autoSaveValue = new Toggle([CTOptions.autoSave ? "On":"Off"], 0, 0, scrollpane.content, container.styleSheet, '', 'preferences-toggle', false );
			autoSaveValue.value = CTOptions.autoSave;
			autoSaveValue.addEventListener( Event.CHANGE, autoSaveClick );
			
			
			debugOutLabel = new Label(w,20, scrollpane.content, container.styleSheet, '', 'preferences-label', false );
			debugOutLabel.label = Language.getKeyword( "Debug Output" );
			debugOutLabel.textField.autoSize = TextFieldAutoSize.LEFT;
			
			debugOutValue = new Toggle([CTOptions.debugOutput ? "On":"Off"], 0, 0, scrollpane.content, container.styleSheet, '', 'preferences-toggle', false );
			debugOutValue.value = CTOptions.debugOutput;
			debugOutValue.addEventListener( Event.CHANGE, debugOutClick );
			
			if ( !CTOptions.isMobile )
			{
				nativePreviewLabel = new Label(w,20, scrollpane.content, container.styleSheet, '', 'preferences-label', false );
				nativePreviewLabel.label = Language.getKeyword( "Use System Browser for Preview" );
				nativePreviewLabel.textField.autoSize = TextFieldAutoSize.LEFT;
				
				nativePreviewValue = new Toggle([CTOptions.nativePreview ? "On":"Off"], 0, 0, scrollpane.content, container.styleSheet, '', 'preferences-toggle', false );
				nativePreviewValue.value = CTOptions.nativePreview;
				nativePreviewValue.addEventListener( Event.CHANGE, nativePreviewClick );
			}
			
			restartLabel = new Label(w,20, scrollpane.content, container.styleSheet, '', 'preferences-label', false );
			restartLabel.label = Language.getKeyword( "Restart Application" );
			restartLabel.textField.autoSize = TextFieldAutoSize.LEFT;
			
			restartBtn = new Button(["Restart"], 0, 0, scrollpane.content, container.styleSheet, '', 'preferences-button', false );
			restartBtn.addEventListener( MouseEvent.CLICK, restartClick );
			
			newSize(null);
		}
		
		private function restartClick (e:MouseEvent) :void
		{
			Application.instance.cmd( "Application restart");
		}
		
		private function nativePreviewClick (e:Event) :void {
			if( nativePreviewValue.value ) {
				nativePreviewValue.label = "On";
				CTOptions.nativePreview = true;
				nativePreviewValue.swapState("active");
			}else{
				nativePreviewValue.label = "Off";
				CTOptions.nativePreview = false;
			}
			storeBooleanPref( "nativePreview", CTOptions.nativePreview);
		}
		
		private function debugOutClick (e:Event) :void {
			if( debugOutValue.value ) {
				debugOutValue.label = "On";
				CTOptions.debugOutput = true;
				debugOutValue.swapState("active");
			}else{
				debugOutValue.label = "Off";
				CTOptions.debugOutput = false;
			}
			storeBooleanPref( "debugOutput", CTOptions.debugOutput);
		}
		private function autoSaveClick (e:Event) :void {
			if ( autoSaveValue.value ) {
				autoSaveValue.label = "On";
				CTOptions.autoSave = true;
				autoSaveValue.swapState("active");
			}else{
				autoSaveValue.label = "Off";
				CTOptions.autoSave = false;
			}
			storeBooleanPref( "autoSave", CTOptions.autoSave);
		}
		
		private function softKeyboardClick (e:Event) :void {
			if ( softKeyboardValue.value ) {
				softKeyboardValue.label = "On";
				CTOptions.softKeyboard = true;
				softKeyboardValue.swapState("active");
			}else{
				softKeyboardValue.label = "Off";
				CTOptions.softKeyboard = false;
			}
			storeBooleanPref( "softKeyboard", CTOptions.softKeyboard);
		}
		
		private function monitorFilesClick (e:Event) :void {
			if ( monitorFilesValue.value ) {
				monitorFilesValue.label = "On";
				CTOptions.monitorFiles = true;
				monitorFilesValue.swapState("active");
			}else{
				monitorFilesValue.label = "Off";
				CTOptions.monitorFiles = false;
			}
			storeBooleanPref( "monitorFiles", CTOptions.monitorFiles);
			if( CTOptions.autoSave ) {
				CTTools.save();
			}
		}
		
		public var cont:CssSprite;
		public var body:CssSprite;
		public var title:Label;
		public var container: Panel;
		public var scrollpane:ScrollContainer;
		
		
		public var monitorFilesLabel:Label;
		public var monitorFilesValue:Toggle;
		
		public var softKeyboardLabel:Label;
		public var softKeyboardValue:Toggle;
		
		public var autoSaveLabel:Label;
		public var autoSaveValue:Toggle;
		
		public var debugOutLabel:Label;
		public var debugOutValue:Toggle;
		
		public var nativePreviewLabel:Label;
		public var nativePreviewValue:Toggle;
		
		public var restartLabel:Label;
		public var restartBtn:Button;
		
		private function newSize (e:Event) :void
		{
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			cont.setWidth( w );
			cont.setHeight( h );
			body.setWidth(w);
			body.setHeight(h);
			
			var cy:int = 0;
			var margin:int = 4;
			var marginX:int = 16;
			
			if( scrollpane )
			{
				
				if ( title ) {
					title.x = Math.floor( (w - title.getWidth() ) * .5);
					title.y = body.cssTop;
					cy = title.y + title.height + title.cssMarginBottom;
				}
				
				if ( monitorFilesLabel && monitorFilesValue )
				{
					monitorFilesLabel.x = body.cssLeft + monitorFilesLabel.cssMarginLeft;
					monitorFilesLabel.y = cy;
					cy += monitorFilesLabel.height + monitorFilesLabel.cssMarginBottom + margin;
					
					monitorFilesValue.x = body.cssLeft + marginX;
					monitorFilesValue.y = cy;
					cy += monitorFilesValue.cssSizeY + monitorFilesValue.cssMarginBottom + margin;
				}
				
				if ( softKeyboardLabel && softKeyboardValue )
				{
					softKeyboardLabel.x = body.cssLeft + softKeyboardLabel.cssMarginLeft;
					softKeyboardLabel.y = cy;
					cy += softKeyboardLabel.height + softKeyboardLabel.cssMarginBottom + margin;
					
					softKeyboardValue.x = body.cssLeft + marginX;
					softKeyboardValue.y = cy;
					cy += softKeyboardValue.cssSizeY + softKeyboardValue.cssMarginBottom + margin;
				}
				
				if ( autoSaveLabel && autoSaveValue )
				{
					autoSaveLabel.x = body.cssLeft + autoSaveLabel.cssMarginLeft;
					autoSaveLabel.y = cy;
					cy += autoSaveLabel.height + autoSaveLabel.cssMarginBottom;
					
					autoSaveValue.x = body.cssLeft + marginX;
					autoSaveValue.y = cy;
					cy += autoSaveValue.cssSizeY + autoSaveValue.cssMarginBottom;
				}
				
				if ( debugOutLabel && debugOutValue )
				{
					debugOutLabel.x = body.cssLeft + debugOutLabel.cssMarginLeft;
					debugOutLabel.y = cy;
					cy += debugOutLabel.height + debugOutLabel.cssMarginBottom;
					
					debugOutValue.x = body.cssLeft + marginX;
					debugOutValue.y = cy;
					cy += debugOutValue.cssSizeY + debugOutValue.cssMarginBottom;
				}
				
				if ( nativePreviewLabel && nativePreviewValue )
				{
					nativePreviewLabel.x = body.cssLeft + nativePreviewLabel.cssMarginLeft;
					nativePreviewLabel.y = cy;
					cy += nativePreviewLabel.height + nativePreviewLabel.cssMarginBottom;
					
					nativePreviewValue.x = body.cssLeft + marginX;
					nativePreviewValue.y = cy;
					cy += nativePreviewValue.cssSizeY + nativePreviewValue.cssMarginBottom;
				}
				
				if ( restartLabel && restartBtn )
				{
					restartLabel.x = body.cssLeft + restartLabel.cssMarginLeft;
					restartLabel.y = cy;
					cy += restartLabel.height + restartLabel.cssMarginBottom;
					
					restartBtn.x = body.cssLeft;
					restartBtn.y = cy + marginX;
					cy += restartBtn.cssSizeY + restartBtn.cssMarginBottom;
				}
				
				scrollpane.x = body.cssLeft;
				scrollpane.y = body.cssTop;
				scrollpane.setWidth( w - body.cssBoxX );
				scrollpane.setHeight( h - body.cssBoxY );
				scrollpane.contentHeightChange();
			}
				
		}
		
		
		private function storeBooleanPref ( name:String, value:Boolean ) :void {
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh && sh.data ) {
				if( !sh.data.preferences ) sh.data.preferences = {};
				sh.data.preferences[name] = value;
				sh.flush();
			}
		}
		private function storeStringPref ( name:String, value:String ) :void{
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh && sh.data ) {
				if( !sh.data.preferences ) sh.data.preferences = {};
				sh.data.preferences[name] = value;
				sh.flush();
			}
		}
		private function storeNumberPref ( name:String, value:Number ) :void{
			var sh:SharedObject = SharedObject.getLocal( CTOptions.installSharedObjectId );
			if( sh && sh.data ) {
				if( !sh.data.preferences ) sh.data.preferences = {};
				sh.data.preferences[name] = value;
				sh.flush();
			}
		}
		
	}
}
