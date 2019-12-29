package agf.tools
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.StyleSheet;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import agf.Options;
	import agf.events.AppEvent;
	import agf.utils.StrVal;
	import agf.ui.Label;
	import agf.html.CssSprite;
	import agf.html.CssUtils;
	import agf.view.PanelType;
	
	public class Console extends BaseTool
	{
		public static var DEFAULT_FONT:String = "Courier New";
		public static var DEFAULT_TEXT_COLOR:uint = 0xDFDFDF;
		public static var DEFAULT_TEXT_SIZE:uint = 14;
		public static var txtfmt:TextFormat;
		 
		/**
		*	Command: Console
		* 	Default: Shows Console Window
		*	Args: show | clear, log any msg text ...
		*/
		public static function command (argv:String, cmdComplete:Function=null, cmdCompleteArgs:Array=null) :void 
		{
			var args:Array = argv2Array(argv);
			
			var hideIndex:int = args.indexOf( "hide" );
			if( hideIndex >= 0 ) {
				hide();
			}
			
			var showIndex:int = args.indexOf( "show" );
			if( showIndex >= 0 ) {
				// Command: Console show <target>
				if( args.length <= showIndex + 1 ) {
					log( "Console show CONSOLE ERROR: No Target Specified In '"+ argv + "'");
					complete( cmdComplete, cmdCompleteArgs);
					return;
				}
				show( StrVal.strval( "{*"+args[showIndex+1]+"}" ) );
			}
			
			if( args.indexOf( "clear" ) >= 0 ) {
				// Command: Console clear
				_logStr = "";
				if( _consoleOpen ) update();
			}
			
			var logIndex:int = args.indexOf( "log" );
			if( logIndex >= 0 ) {
				// Command: Console log any message..
				log( arrStringFrom(args, logIndex+1) );
			}
			
			complete( cmdComplete, cmdCompleteArgs);
		}
		
		private static var newLine:String = "\n";
		private static var _consoleOpen:Boolean;
		private static var _consoleTarget:Sprite;
		private static var _consoleLabel:Label;
		private static var _logStr:String = "";
		
		public static function show ( t:* /*CssSprite*/ ) :void
		{
			if( _consoleOpen ) hide();
			
			if( t is CssSprite )
			{
                var l:Label = new Label(0, 0, t, t.styleSheet, "", "agf-console-textfield", false);
                var styles:Object = t.styleSheet.getMultiStyle( l.stylesArray );
                var fnt:String;
                var color:uint;
                var size:uint;
                
                if( styles.fontFamily ) {
                    fnt = CssUtils.parseFontFamily( styles.fontFamily );
                }else{
                    fnt = DEFAULT_FONT;
                }
                
                if( styles.color ) {
                    color = CssUtils.parse(styles.color);
                }else{
                    color = DEFAULT_TEXT_COLOR;
                }
                
                if( styles.fontSize ) {
                    size = CssUtils.parse(styles.fontSize);
                }else{
                    size = DEFAULT_TEXT_SIZE;
                }
                                    
                txtfmt = new TextFormat(fnt, size, color);
                l.textField.styleSheet = null;
                l.textField.defaultTextFormat = txtfmt;
                l.textField.textColor = color;
                l.textField.autoSize = TextFieldAutoSize.NONE;
                l.textField.embedFonts = Options.embedFonts;
                l.textField.antiAliasType = Options.antiAliasType;
                l.textField.multiline = true;
                l.textField.selectable = true;
                l.textField.text = _logStr;
                l.textField.type = flash.text.TextFieldType.DYNAMIC;
                l.x = t.cssLeft || 2;
                l.y = t.cssTop || 2;
				
				// Try setting Panel view mode to "console"
				try{
					t["viewType"] = PanelType.CONSOLE;
				}catch(e:Error) {
					 log( "Console should be opened in a agf.html.CssSprite object or agf.ui.Panel, etc.");
				}
				
				_consoleOpen = true;
				_consoleTarget = t;
				_consoleLabel = l;
				Application.instance.view.panel.addEventListener( Event.RESIZE, resizeConsole );
				resizeConsole(null);
				update();
				
			}
			else
			{
				if( typeof t == "string" ) {
					// Switch main view to console
					Application.command( "view " + t.substring(2, t.length-1) );
					Application.instance.view.addEventListener( agf.events.AppEvent.VIEW_CHANGE, removeFromView );
					show( Application.instance.view.panel );
				}
			}
		}		
		
		public static function resizeConsole (e:Event) :void {
			if( _consoleLabel && _consoleTarget ) {
				if( _consoleTarget is CssSprite ) {
					var t:CssSprite = CssSprite( _consoleTarget );
					_consoleLabel.textField.width = t.cssSizeX - t.cssBoxX;
					_consoleLabel.textField.height = t.cssSizeY - t.cssBoxY;
				}else{
					_consoleLabel.textField.width = t.width - 4;
					_consoleLabel.textField.height = t.height - 4;
				}
			}
		}
		public static function removeFromView (e:AppEvent) :void {
			hide();
		}
		public static function hide () :void{		
			if(_consoleOpen) {
				Application.instance.view.panel.removeEventListener( Event.RESIZE, resizeConsole );
				if(_consoleLabel){
					if(_consoleTarget) _consoleTarget.removeChild( _consoleLabel );
					else if(_consoleLabel.parent && _consoleLabel.parent.contains(_consoleLabel)) _consoleLabel.parent.removeChild( _consoleLabel );
					_consoleLabel = null;
					_consoleTarget = null;
					_consoleOpen = false;
				}
			}
		}
		public static function getTextField () :TextField {
			if ( _consoleLabel && _consoleLabel.textField ) {
				return _consoleLabel.textField;
			}
			return null;
		}
		public static function update () :void {
			_consoleLabel.textField.text = _logStr;
			_consoleLabel.textField.scrollV = _consoleLabel.textField.maxScrollV;
		}
		public static function log ( s:String ) :void {
			_logStr += s + newLine;
			if( _consoleOpen ) update();
			trace("Console: " + s);
		}
		public static function logInline ( s:String ) :void {
			_logStr += s;
			if( _consoleOpen ) update();
			trace("Console: " + s);
		}
		
	}
}