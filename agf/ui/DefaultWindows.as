package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.ui.Keyboard;
	import fl.transitions.easing.Regular;
	import agf.Options;
	import agf.events.AppEvent;
	import agf.animation.Animation;
	import agf.tools.Console;
	import agf.io.Resource;
	import agf.io.ResourceMgr;
	import agf.ui.Window;
	import agf.tools.Application;
	import agf.ui.WindowsController;
	import agf.html.CssSprite;
	import agf.html.CssUtils;
	
	/**
	*
	* Default Window Controller for standard windows
	*
	**/
	public class DefaultWindows implements WindowsController {

		public function DefaultWindows () {}
		
		public var windowContainer:CssSprite;
		private var callbacks:Object={};

		public function ContentWindow ( nameUid:String, title:String="", content:Sprite=null, options:Object=null, cssClass:String="" ) :Sprite {			
			callbacks[ nameUid ] = options;
			
			var win:Window = CreateWindow( nameUid, title, options, cssClass );
			win.options.wintype = "content";
			if( content != null ) {
				win.body.addChild( content );
				content.y = win.title.getHeight()+2;
			}
			YesNoControls( win, options );
			
			return win;	
		}
		
		/**
		* Property options.continueLabel : String || "Continue"
		* Property options.allowCancel : Boolean || false
		* Property options.cancelLabel : String || "Cancel"
		* Property options.styleSheet : CssStyleSheet || app.config
		* Property options.x : Number || 10
		* Property options.y : Number || app.menu.height + 10
		* Property options.width : Number || stageWidth
		* Property options.height : Number || stageHeight
		* Property options.icon : String filepath || undefined
		*
		* Event: complete()
		* Event: close()
		**/
		public function InfoWindow ( nameUid:String, title:String="", msg:String="", options:Object=null, cssClass:String="" ) :Sprite{			
			callbacks[ nameUid ] = options;
			
			var win:Window = CreateWindow( nameUid, title, options, cssClass );
			win.options.wintype = "info";
		
			YesNoControls( win, options );
			MsgTextField( win, options, msg, "info_tf", false, true );
				
			if( options && options.icon != undefined && options.icon != "" ) {
				var uid:int = ResourceMgr.getInstance().loadResource( options.icon, onIcon, false );
				iconsById["_"+uid] = win;
			}
			
			return win;	
		}
		private static var iconsById:Object = {};
		
		private static function onIcon ( r:Resource ) :void {
			var win:Window = Window( iconsById["_"+r.uid] );
			var bmp:Bitmap = Bitmap( r.obj );
			
			if( bmp )
			{
				var bmd:BitmapData = new BitmapData( bmp.width, bmp.height, true, 0x00FFFFFF);
				bmd.draw( bmp );
				
				var newbmp:Bitmap = new Bitmap(bmd);
				
				win.body.addChild( newbmp );
				
				newbmp.x = win.bg.cssLeft;
				newbmp.y = win.bg.cssTop;
			}
		}
		
		/**
		* Property options.continueLabel : String
		* Property options.cancelLabel : String
		* Event: options.complete( Boolean )
		* Event: options.close()
		*/
		public function GetBooleanWindow ( nameUid:String, title:String="", msg:String="", options:Object=null, cssClass:String="" ) :Sprite {				
			callbacks[ nameUid ] = options;
			
			var win:Window = CreateWindow( nameUid, title, options, cssClass );
			win.options.wintype = "boolean";
			
			YesNoControls( win, options );
			MsgTextField( win, options, msg, "msg_tf", false, true );
			
			return win;
		}
		
		public function GetStringWindow ( nameUid:String, title:String="", msg:String="", options:Object=null, cssClass:String="" ) :Sprite {
			callbacks[ nameUid ] = options;
			
			var win:Window = CreateWindow( nameUid, title, options, cssClass );
			win.options.wintype = "string";

			YesNoControls( win, options );
			MsgTextField( win, options, msg, "string_tf", true, true );
			
			if( options && options.icon != undefined && options.icon != "" ) {
				var uid:int = ResourceMgr.getInstance().loadResource( options.icon, onIcon, false );
				iconsById["_"+uid] = win;
			}
			return win;
		}
		public static var msgTFMT:TextFormat = null;
		public static var msgWIconTFMT:TextFormat = null;
		
		public function CreateWindow ( nameUid:String, title:String, options:Object=null, cssClass:String="" ) :Window {
			var mainMenuHeight:Number = Application.instance.mainMenu.cssSizeY;
			var w:Number = options && typeof options.width == "number" ? options.width : Application.instance.stage.stageWidth - 20;
			var h:Number = options && typeof options.height == "number" ? options.height : Application.instance.stage.stageHeight - 20 - mainMenuHeight;
			
			var win:Window = new Window( nameUid, title, w, h, windowContainer, Application.instance.config, '', cssClass);
			win.options.wintype = "string";
			win.setWidth( w - ( win.cssBoxX + win.bg.cssBoxX ) );
			win.setHeight( h - ( win.cssBoxY + win.bg.cssBoxY) );
			
			if( options ) {
				win.y = typeof options.y == "number" ? options.y : mainMenuHeight + 10;
				win.x = typeof options.x == "number" ? options.x : win.x = 10;
			}else{
				win.y = mainMenuHeight + 10;
				win.x = win.x = 10;
			}
			win.addEventListener("close", closeButtonHandler);
			
			if( !options || !options.noAnimation )
			{
				var toX:Number = win.x;
				var toY:Number = win.y;
				
				var s:Number = 0.84;
				var d:Number = 387;
				var e:Function = Regular.easeOut;
				var t:String = "pop"; // wipe-top, wipe-left.., fade
				
				if( options ) {
					if( options.animScale != undefined ) s = Number( options.animScale ); 
					if( options.animDuration != undefined ) d = Number( options.animDuration ); 
					if( options.animEaseFunc != undefined ) e = options.animEaseFunc;
					if( options.animType != undefined ) t = options.animType;
				}
				
				var anim:Animation = new Animation();
				anim.loop = false;
				win.addChild( anim );
				
				win.options.anim = anim;
				win.options.animScale = s;
				win.options.animDuration = d;
				win.options.animEaseFunc = e;
				win.options.animType = t;
				
				win.x += (w - w * s) / 2;
				win.y += (h - h * s) / 2 ;
				
				win.scaleX = win.scaleY = s;
				win.alpha = 0;
				anim.run( win, { x:toX, y:toY, scaleX:1, scaleY:1, alpha:1 }, d, e );
			}
			
			return win;
		}
		
		public function MsgTextField (win:Window, options:Object=null, msg:String="", tf_name:String="msg_tf", inputText:Boolean=false, multi_line:Boolean=true) :void {
			
			var tf:TextField = new TextField();
			tf.name = tf_name;
			tf.wordWrap = true;
			tf.embedFonts = Options.embedFonts;
			tf.antiAliasType = Options.antiAliasType;
			
			if( options && options.multiline != undefined ) {
				tf.multiline = options.multiline;
			}else{
				tf.multiline = multi_line;
			}
			if(inputText) tf.type = TextFieldType.INPUT;
			else tf.type = TextFieldType.DYNAMIC;
			
			var styl:Object = win.styleSheet.getStyle( ".window-" + (inputText ? "input" : "message") );
			
			if( styl.backgroundColor ) {
				tf.background = true;
				tf.backgroundColor = CssUtils.stringToColor( styl.backgroundColor );
			}
			
			if( styl.color ) tf.textColor = CssUtils.stringToColor( styl.color );
			
			if( styl.borderColor ) {
				tf.border = true;
				tf.borderColor = CssUtils.stringToColor( styl.borderColor );
			}
			var marginLeft:int = 2;
			var marginTop:int = 2;
			var marginRight:int = 2;
			var marginBottom:int = 2;
			
			if( styl.marginLeft != undefined ) {
				marginLeft = CssUtils.parse( styl.marginLeft, win.body );
			}
			if( styl.marginTop != undefined ) {
				marginTop = CssUtils.parse( styl.marginTop, win.body, "v" );
			}
			
			if( styl.marginRight != undefined ) {
				marginRight = CssUtils.parse( styl.marginRight, win.body );
			}
			if( styl.marginBottom != undefined ) {
				marginBottom = CssUtils.parse( styl.marginBottom, win.body, "v" );
			}
			
			win.options.marginLeft = marginLeft;
			win.options.marginTop = marginTop;
			win.options.marginRight = marginRight;
			win.options.marginBottom = marginBottom;
			
			tf.text = msg;
			
			if( options && options.icon != undefined && options.icon != "" ) {
				if( msgWIconTFMT == null ) msgWIconTFMT = win.styleSheet.getTextFormat( ["*","window",".window","body",".window-"+ (inputText ? "input" : "message") + "-wimg"  ]);
				tf.setTextFormat( msgWIconTFMT );
			}else{
				if( msgTFMT == null ) msgTFMT = win.styleSheet.getTextFormat( ["*","window",".window","body",".window-" + (inputText ? "input" : "message")]); 
				tf.setTextFormat( msgTFMT );
			}
			if( options && options.autoWidth ) {
				tf.autoSize = TextFieldAutoSize.LEFT;
				tf.autoSize = TextFieldAutoSize.NONE;
				tf.width = tf.width - (marginLeft + marginRight);
				win.setWidth( tf.width + (marginLeft + marginRight) );
			}
			
			tf.width = win.bg.getWidth() - (win.cssBoxX + win.bg.cssBoxX + marginLeft + marginRight + 4);
			
			var bt:Button = Button(win.body.getChildByName("okButton_button"));
			var bt2:Button;
			
			if( options && options.autoHeight ) {
				tf.autoSize = TextFieldAutoSize.LEFT;
				win.setHeight( tf.height + win.title.cssSizeY + win.title.y + bt.cssSizeY + bt.cssMarginY + win.bg.cssBoxY + win.cssBoxY + marginTop + marginBottom );
				
				tf.autoSize = TextFieldAutoSize.NONE;
				tf.width = win.getWidth() - (win.bg.cssBoxX  + marginLeft + marginRight + 4);
				
			}else{
				tf.height = win.getHeight() - ( win.title.cssSizeY + win.title.y + bt.cssSizeY + bt.cssMarginY + win.bg.cssBoxY + marginTop + marginBottom /* + 8*/ );
			}
			
			tf.x = win.bg.cssLeft + win.cssLeft + marginLeft;
			tf.y = win.title.cssSizeY + win.title.y + win.cssTop + win.bg.cssTop + marginTop;
			
			if( options && options.autoHeight ) {
				if( bt ) {
					bt.y = win.getHeight() - bt.cssMarginBottom - bt.getHeight() - 4;
				}
				bt2 = Button( win.body.getChildByName( "cancelButton_button" ) );
				if( bt2 ) {
					bt2.y = win.getHeight() - bt2.cssMarginBottom - bt2.getHeight() - 4;
				}
			}
			if( options && options.autoWidth ) {
				if( bt ) {
					bt2 = Button( win.body.getChildByName( "cancelButton_button" ) );
					if( bt2 ) {
						var mg:Number = Math.round( Math.max(bt2.cssMarginRight, bt.cssMarginLeft)*.5 );
						bt2.x = win.getWidth()/2 - bt.cssSizeX - mg - 2;
						bt.x = win.getWidth()/2 + mg + 2;
					}else{
						bt.x = win.getWidth()/2 - bt.cssSizeX/2;
					}
				}
			}
			if( options && options.password ) {
				tf.multiline = false;
				tf.displayAsPassword = true;
			}
			win.options.multiline = tf.multiline;
			win.body.addChild( tf );
		}
		
		public function YesNoControls (win:Window, options:Object=null) :void {
			var okButton:Button = new Button([(options && options.continueLabel) || "Continue"],0,0, win.body, win.styleSheet,'','window-ok-button');
			okButton.name = "okButton_button";
			okButton.addEventListener( MouseEvent.CLICK, okButtonHandler );
			okButton.y = win.getHeight() - okButton.cssSizeY - okButton.cssMarginY;
			
			var btnsW:Number = okButton.cssSizeX;
			
			if( options && options.allowCancel ) {
				var cancelButton:Button = new Button( [(options && options.cancelLabel) || "Cancel"],0,0, win.body, win.styleSheet,'','window-cancel-button');
				cancelButton.addEventListener( MouseEvent.CLICK, cancelButtonHandler );
				cancelButton.y = win.getHeight() - cancelButton.cssSizeY - cancelButton.cssMarginY;
				cancelButton.name = "cancelButton_button";
				btnsW += cancelButton.cssSizeX;
				var mg:Number = Math.round( Math.max(cancelButton.cssMarginRight, okButton.cssMarginLeft)*.5 );
				cancelButton.x = Math.floor( win.getWidth()/2 - btnsW/2 ) - (1+mg);
				okButton.x = cancelButton.x + cancelButton.cssSizeX + mg;
			}else{
				okButton.x = Math.floor( win.getWidth()/2 - btnsW/2 ) - 1;
				if( win.options.wintype == "info" ) {
					win.addEventListener( MouseEvent.CLICK, winÇlickHandler );
				}
			}
			
			if( options && options.keyboardShortcuts != false ) {
				win.enterListener( winKeyHandler );
			}
			focusWindow = win;
		}
		
		// Last created window 
		private var focusWindow:Window;
		
		private function winKeyHandler (event:KeyboardEvent) :void
		{
			var id:String="";
			var win:Window = Window( focusWindow );
			if( win && win.stage ) 
			{
				if( win.stage.focus != null ){
					if(!win.options.multiline) return;
				}
				if(event.keyCode == Keyboard.DELETE) {
					id = "del";
				}else if(event.keyCode == Keyboard.BACKSPACE) {
					id = "backspace";
				}else if(event.keyCode == Keyboard.ENTER || event.keyCode == 10 || event.keyCode == 13) {
					id = "enter";
				}else if(event.keyCode == Keyboard.ESCAPE) {
					id ="esc";
				}else if(event.keyCode == Keyboard.NUMPAD_ADD) {
					id ="+";
				}else if(event.keyCode == Keyboard.NUMPAD_SUBTRACT) {
					id ="-";
				}else if(event.keyCode == Keyboard.END) {
					id="end";
				}else if(event.keyCode == Keyboard.HOME) {
					id="home";
				}else if(event.keyCode == Keyboard.INSERT) {
					id="ins";
				}else if(event.keyCode == Keyboard.PAGE_UP) {
					id="PgUp";
				}else if(event.keyCode == Keyboard.PAGE_DOWN) {
					id="PgDn";
				}else if(event.keyCode >= Keyboard.F1 && event.keyCode <= Keyboard.F15) {
					id = "F" + ((event.keyCode-Keyboard.F1)+1);
				}else{
					id = String.fromCharCode(event.charCode);
				}
				
				var sc:Object;
				var cb:Object = callbacks[ win.name ];
				
				if( id == "enter" ) {
					switch ( win.options.wintype ) {
						case "info":
						case "content":
						case "boolean":
							if( cb.complete) cb.complete(true);
							break;
						case "string":
							if( cb.complete ) cb.complete( TextField( win.body.getChildByName( "string_tf") ).text || "" );
							break;
					}
					win.close();
				}else if( id == "esc" ) {
					switch ( win.options.wintype ) {
						case "info":
						case "content":
						case "boolean":
							if( cb.complete ) cb.complete( false );
							break;
						case "string":
							if( cb.cancel ) cb.cancel();
							break;
					}
					win.close();
				}
			}
			
		}
		
		private function winÇlickHandler (e:Event) :void {
			var win:Window = Window( e.currentTarget );
			var cb:Object = callbacks[ win.name ];
			if( cb && cb.complete ) {
				switch ( win.options.wintype ) {
					case "info":
					case "content":
					case "boolean":
						cb.complete(true);
						break;
					case "string":
						cb.complete( TextField( win.body.getChildByName( "string_tf") ).text || "" );
						break;
				}
				
			}
			win.close();
		}
		
		private function okButtonHandler (e:Event) :void {
			var win:Window = Window( e.currentTarget.parent.parent );
			var cb:Object = callbacks[ win.name ];
			if( cb && cb.complete ) {
				switch ( win.options.wintype ) {
					case "info":
					case "content":
					case "boolean":
						cb.complete(true);
						break;
					case "string":
						cb.complete( TextField( win.body.getChildByName( "string_tf") ).text || "" );
						break;
				}
				
			}
			win.close();
		}
		
		private function cancelButtonHandler (e:Event) :void {
			var win:Window = Window( e.currentTarget.parent.parent );
			var cb:Object = callbacks[ win.name ];
			if( cb ) {
				switch ( win.options.wintype ) {
					case "info":
					case "content":
					case "boolean":
						if( cb.complete ) cb.complete(false );
						break;
					case "string":
						if( cb.cancel ) cb.cancel();
						break;
				}
			}
			
			win.close();
		}
		
		private function closeButtonHandler (e:Event) :void 
		{
			var win:Window = Window( e.currentTarget );
			var cb:Object = callbacks[ win.name ];
			
			if( cb ) {
				switch ( win.options.wintype ) {
					case "info":
					case "content":
					case "boolean":
					case "string":
						if( cb.close ) cb.close();
						break;
				}
			}
		}
	}
	
}
