package ct.ctrl
{
	import agf.events.AppEvent;
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.external.ExtensionContext;
	import flash.net.FileFilter;
	import flash.utils.setTimeout;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.*;
	import flash.events.MediaEvent;
	import flash.events.MouseEvent;
	import flash.system.Capabilities;
	import flash.events.*;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.display.InteractiveObject;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import flash.ui.Mouse;
	import flash.utils.getTimer;
	import agf.icons.IconArrowDown;
	import agf.icons.IconData;
	import agf.icons.IconMenu;
	import agf.icons.IconBoolean;
	import agf.icons.IconFromFile;
	import agf.icons.IconFromHtml;
	import agf.icons.IconEmpty;
	import agf.tools.Application;
	import agf.events.PopupEvent;
	import agf.ui.*;
	import agf.Options;
	import agf.html.*;
	import agf.utils.StringMath;
	import agf.utils.ColorUtils;
	import ct.Area;
	import ct.AreaEditor;
	import ct.CTMain;
	import ct.ctrl.VectorTextField;
	import agf.tools.Console;
	import ct.TemplateTools;
	import ct.CTTools;
	import ct.HtmlEditor;
	import ct.TemplateEditor;
	import agf.events.CssEvent;
	import ct.CTOptions;
	import agf.io.Resource;
	import ct.Template;
	import ct.ProjectFile;
	import ct.AreaProcessor;
	import ct.ConstantsEditor;
	
	public class InputTextBox extends AreaProcessor
	{
		// TODO: Input Types: TextStyle, BackgroundStyle, ContainerStyle -> generates css for margin, border, padding, background, color, font-properties etc
		// type can be intern, hidden, name, string, code, richtext, number, integer, screennumber, screeninteger, boolean, color, list, listappend, listmultiple, labellist, arealist, pagelist, nodestyle, styleclass, vector<T>, vectorlink, file, files, image, audio, video, pdf, or directory
		public function InputTextBox ( __type:String="line", type_args:Array=null, prop_obj:Object=null, avalue:String="", w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false)
		{
			super(w, h, parentCS, css, "textbox", cssId, cssClasses, true);
			if(!noInit) init();
			autoSwapState = "";
			args = type_args;
			propObj = prop_obj;
			textField = new TextField();
			create();
			value = avalue;
			setType(__type);
		}
		
		public static const ENTER:String = "ctrl_enter";
		
		// For name types
		public static var uniqueNameLen:int = 2;
		public static function getUniqueName (prefix:String="Item_", len:int=0) :String
		{
			var rndstr:String = "";
			if( len < 1 ) len = uniqueNameLen;
			
			for(var i:int=0; i<len; i++)
			{
				rndstr += "" + int(Math.random() * 9999).toString(16).toUpperCase();
			}
			return prefix + rndstr;
		}
		
		public static var disableFileSearch:Boolean = false;
		
		public var trimValue:Boolean = true;
		public var trimQuotesValue:Boolean = true;
		
		public var textField:TextField;
		public var htmlTextField:TextField;
		public var rtViewCode:Boolean=true;
		
		private var fmt:TextFormat;
		
		// For color Type
		private var displayMode:String="hex"; // rgb, rgba, hsl, hsla or hex
		
		public var args:Array = null; // arguments for _type
		public var propObj:Object = null; // arguments for _type
		
		public var maxTextHeight:int = 1080;
		
		// For number and integer types if min and max values are set a slider is displayed
		public var sliderGrid:Number = 0;
		public var outsideRange:Boolean = true;
		public var decPlaces:int = 4;
		
		// For Boolean Types:
		public var _boolValue:Boolean=false;
		public var boolYes:String="true";
		public var boolNo:String="false";
		
		// For Vector types
		public var vectorTextFields:Vector.<VectorTextField>;
		public var vectorType:String="number";
		public var vectorFixRatio:Boolean=false;
		public var vectorDynamic:Boolean=false;
		public var vectorWrap:String="";	    // fillTemplate...
		public var vectorSeparator:String=",";  // DB separator
		public var vectorContainer:CssSprite;
		public var vectorPlusButton:Button;
		public var vectorMinusButton:Button;
		public var vectorCurrent:int=-1;
		
		public var defaultWWWFolder:String="";
		public var defaultRename:String="";
		public var defaultDescr:String="";
		public var defaultExtList:String="";

		// For file types
		public var www_folder:String;
		public var www_filename:String;
		public var fileFilterDescription:String=""; // "Text/XML";
		public var allowed_extensions:String=""; // "gif,jpg,png,mp3,mp4,flv,swf,htm,html,css,js,php,xml";
		public var rename_template:String="";    // "uploaded-file-#INPUTNAME#-#UID#-#YEAR#-#MONTH#-#DAY#-#HOUR#-#MINUTE#-#SECOND#.#EXTENSION#";
		public var generic_file:String;
		private static var lastSelectedFiles:Object={};
		public static var screenUnits:Array = ["rem","em","px","%","vw","vh"];
		
		public var labelText:String;
		public var colorClip:Sprite;
		
		private var _type:String;
		private var _tgt:InteractiveObject;
		public var tfBtn:Button;
		public var min:Number = Number.MIN_VALUE;
		public var max:Number = Number.MAX_VALUE;
		public var tfPopup:Popup;
		public var tfSlider:Slider;
		
		public var tfIcon:Sprite;
		public var btWidth:int = 0;
		
		public var wrapBegin:String="";
		public var wrapEnd:String="";
		
		public var lineWrapBegin:String="";
		public var lineWrapEnd:String="";
		public var helpIcon:Button;
		public var history:Vector.<String> = new Vector.<String>();
		public var future:Vector.<String> = new Vector.<String>();
		// Area
		public var areaName:String;
		public var areaType:String;
		public var areaOffset:int=0;
		public var areaLimit:int=0;
		public var areaSubTemplateFilter="";
		
		private var clickScrolling:Boolean = false;
		private static var sbClickValue:Number;
		public var activateValue:String="";
		private static var tmp_bool_value:Boolean=false;
		private var _color:uint=0;
		private var _dir:String="";
		private var _file:String="";
		public static var rtNodeName:String = "div";
		public var specialCharIcons: Object = {};
		
		public var plugin:Object;
		private var superType:String="";
		private var superArgs:Array;
		
		public static var specialChars:Object =
		{
			name:".Special Chars",
			whitespace: "&nbsp;",
			alpha: "&#945;",
			angle:"&#8736;",
			bullet:"&#8226;",
			middot:"&#183;",
			diamond:"&#9830;",
			heart:"&#9829;",
			club:"&#9827;",
			spade:"&#9824;",
			quarter:"&#188;",
			half:"&#189;",
			division:"&#247;",
			perpendicular:"&#8869;",
			ampersand:"&#38;",
			empty:"&#8709;",
			beta: "&#946;",
			copyright: "&#169;",
			delta: "&#948;",
			exist:"&#8707;",
			nabla:"&#8711;",
			verticalbar:"&#166;",
			gamma: "&#947;",
			micro:"&#181;",
			promil:"&#8240;",
			infinity:"&#8734;",
			plusminus:"&#177;",
			omega:"&#937;",
			pi:"&#960;",
			degree:"&#176;",
			aquoteleft:"&#171;",
			aquoteright:"&#187;",
			registered:"&#174;",
			lowast:"&#8727;",
			quotation:"&#34;",
			apostrophe:"&#39;",
			leftquote:"&#8220;",
			rightquote:"&#8221;",
			lowerquote:"&#8222;",
			trademark:"&#8482;",
			arrowright:"&#8594;",
			arrowleft:"&#8592;",
			arrowup:"&#8593;",
			arrowdown:"&#8595;",
			arrowlr:"&#8596;",
			carriagereturn:"&#8629;",
			less:"&#60;",
			greater:"&#62;",
			radic: "&#8730;",
			theta: "&#952;",
			delta:"&#914;",
			lambda:"&#916;",
			sigma:" &#931;",
			ypsilon: "&#933;",
			xi:"&#926;",
			euro:"&#8364;",
			yen:"&#165;",
			pound:"&#163;",
			cent:"&#162;"
		}
		
		public var richTextCssIcons: Array = [new IconFromFile( Options.iconDir + "/cap.png", Options.iconSize, Options.iconSize) ];
		
		public var rtItemList:ItemList;
		
		public var richTextButtons:Array;
		public var richTextIcons:Array;
		private var colorPicker:ColorPicker;
		
		private var listAppendSeparator:String=" ";
		
		private var mediaInfo:TextField;
		private var mediaContainer:Sprite;
		private var mediaWidth:int=160;
		private var mediaHeight:int=80;
		
		public var pageItemName:String = "";
		
		public function historyPop () :String
		{
			var s:String = history.pop();
			toggleUndoButtons();
			return s;
		}
		
		public function historyPush ( v:String ) :void
		{
			history.push( v );
			toggleUndoButtons();
		}
		
		public function futurePop () :String
		{
			var s:String = future.pop();
			toggleUndoButtons();
			return s;
		}
		
		public function futurePush ( v:String ) :void
		{
			future.push( v );
			toggleUndoButtons();
		}
		
		private function toggleUndoButtons () :void
		{
			if( rtItemList )
			{
				// Show Undo/Redo Button
				
				for( var i:int = 0; i< rtItemList.items.length; i++ )
				{
					if ( rtItemList.items[i].options.originalLabel == ".Undo" )
					{
						if( history.length > 1 )
						{
							rtItemList.items[i].alpha = 1;
						}
						else
						{
							rtItemList.items[i].alpha = .1;
						}
					}
					else if ( rtItemList.items[i].options.originalLabel == ".Redo" )
					{
						if( future.length > 1 )
						{
							rtItemList.items[i].alpha = 1;
						}
						else
						{
							rtItemList.items[i].alpha = .1;
						}
					}
				}
			}
		}
		
		public function get type () :String
		{
			return _type;
		}
		
		public function get _supertype () :String
		{
			return _type == "plugin" ? (superType == "" ? _type : superType) : _type;
		}
		
		public function create () :void
		{
			fmt = styleSheet.getTextFormat( stylesArray, "normal" );
			setupTextField( textField, textChange, onActivate, onDeactivate);
		}
		// allow only 0-9, a-s, A-Z and the _-$: specialChars
		// If string is empty, returns getUniqueName()
		// n: a trimmed string (with only single white-spaces
		private function parseName (n:String) :String
		{
			if( !n || n == " " ) return getUniqueName();
			var L:int = n.length;
			var i:int;
			var cc:int
			var o:String="";
			
			for( i=0; i<L; i++)
			{
				cc = n.charCodeAt(i);
				if( cc <= 32 )
				{
					o += "-";
				// 0 - 9 || a - z || A - Z || - || _ || $ || :
				}
				else if( (cc >= 48 && cc <= 57) || (cc >= 97 && cc <= 122) || (cc >= 65 && cc <= 90) || cc == 45 || cc == 95 || cc == 36 ||cc == 58 )
				{
					o += String.fromCharCode(cc);
				}
			}
			
			cc = o.charCodeAt(0);
			if( cc >= 48 && cc <= 57)
			{
				o = "_" + o;
			}
			
			if( cc == 45 )
			{
				// Search for "-----..."
				var allcc:Boolean=true;
				L = o.length;
				for( i=0; i<L; i++)
				{
					if( o.charCodeAt(i) != 45 )
					{
						allcc = false;
						break;
					}
				}
				if( allcc ) return getUniqueName();
			}
			
			if( !o || o == " ") return getUniqueName();
			return o;
		}
		
		private function setupTextField (tf:TextField, _onChange:Function=null, _onActivate:Function=null, _onDeactivate:Function=null) :void
		{			
			tf.type = TextFieldType.INPUT;
			tf.multiline = false;
			tf.defaultTextFormat = fmt;
			tf.setTextFormat( fmt );
			tf.embedFonts = Options.embedFonts;
			tf.antiAliasType = Options.antiAliasType;
			tf.width = getWidth();
			var tmp:String = tf.text;
			tf.text = "VGgyYÖÜ";
			tf.height = tf.textHeight + 4;
			tf.text = tmp;
			tf.x = cssLeft;
			tf.y = cssTop;
			if( _onActivate != null )    tf.addEventListener( FocusEvent.FOCUS_IN, _onActivate);
			if( _onDeactivate != null )  tf.addEventListener( FocusEvent.FOCUS_OUT, _onDeactivate );
			if( _onChange != null  )     tf.addEventListener( Event.CHANGE, _onChange );
			
			if( CTOptions.isMobile && CTOptions.softKeyboard ) {
				tf.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE, CTTools.softKeyboardChange );
				tf.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, CTTools.softKeyboardChange );
			}
			addChild(tf);
		}
		
		private function onImageLoaded ( _res:Resource ) :void
		{
			if( _res && _res.loaded == 1 )
			{
				var sp:DisplayObject = DisplayObject(_res.obj);
			
				if(sp)
				{
					var stylchain:Array = [".media-info"];
					var fmt:TextFormat = styleSheet.getTextFormat( stylchain, "normal" );
					
					if( mediaInfo == null ) 
					{
						mediaInfo = new TextField();
					}
					
					var f:File = new File( _res.url );
					mediaInfo.defaultTextFormat = fmt;
					mediaInfo.multiline = true;
					mediaInfo.selectable = false;
					mediaInfo.autoSize = TextFieldAutoSize.LEFT;
					
					mediaInfo.text = Math.round(f.size /1000) + " kb" + " \n" + int(sp.width) + " x " + int(sp.height) + " px \n" + f.extension.toUpperCase();
				
					var dw:Number = mediaWidth/sp.width;
					var dh:Number = mediaHeight/sp.height;
					var scl:Number = Math.min( dw, dh);
					
					if( scl < 1 ) {
						sp.scaleX = sp.scaleY = scl;
					}
					
					var bmd:BitmapData = new BitmapData( Math.ceil(sp.width), Math.ceil(sp.height), true, 0x00999999);
					var bmp:Bitmap = new Bitmap(bmd);
					
					bmd.draw( sp, sp.transform.matrix );
					
					mediaContainer.addChild( bmp );
					mediaContainer.addChild( mediaInfo );
					
					setChildIndex( textField, numChildren-1 );
					
					setHeight( Math.max( sp.height, mediaInfo.textHeight + (tfBtn ? tfBtn.cssSizeY : 4 )) + textField.textHeight + 8 );
					
					setWidth( /*cssSizeX*/ getWidth() );
					setTimeout( function(){
						dispatchEvent( new Event("heightChange") );
					},123);
				}
			}
			else
			{
				Console.log( "Can Not Load Image: " + value );
				
				if( !disableFileSearch )
				{
					// search image in min, raw, and online if hub-script.. hup->get-root-dir -> http://xyz.com/dir/ , hub->get-file ( value ) -> http://xyz.com/dir/value
					if( value.substring(0,7) != "file://" && lastWebFileChecked != value )
					{
						lastWebFileChecked = value;
						var rv:Boolean = CTTools.findWebFile( value, onFindFileComplete );
						
						if( !rv )
						{
							setTimeout(reloadImage, 350);
						}
						
					}
				}
			}
		}
		
		private  var lastWebFileChecked:String = "";
		
		private function onFindFileComplete (success:Boolean) :void
		{
			if( success )
			{
				var tmp:String = value;
				activateValue = value = "";
				lastWebFileChecked = "";
				value = tmp;
				textEnter();
			}
		}
		
		private function largeImagePreview (e:MouseEvent = null) :void
		{
			if( HtmlEditor.isPreviewOpen )
			{
				try {
					var he:HtmlEditor = HtmlEditor( Application.instance.view.panel.src );
					if( he ) {
						var imgpath:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + value;
						he.loadWebURL( imgpath );
					}
				}catch(e:Error) {
					Console.log("Error: " + e);
				}
			}
		}
		
		public function loadImage (path:String) :void
		{
			Application.instance.resourceMgr.clearResourceCache( path, true );
			Application.instance.resourceMgr.loadResource( path, onImageLoaded, false );
		}
		
		private function loadVideo (path:String) :void
		{
			var sp:Video = new Video ( mediaWidth, mediaHeight );
			
			// TODO: display video player
			mediaContainer.addChild( sp );
			setHeight( textField.height );	
		}
		
		private function initPlugin () :void
		{
			var i:int;
			var L:int;
			var cl:Object = Application.instance.findPluginClass( args[0], args[1] );
			
			if( cl )
			{
				var plg:Object = new cl( args );
				
				if( plg )
				{
					plugin = plg;
					superType = "";
					superArgs = null;
					
					L = args.length;
					
					if( cl.superType != "" )
					{
						superType = cl.superType;
						
						if( L > 2 ) {
							superArgs = [];
							for( i=2; i<L; i++ ) {
								superArgs.push( args[i] );
							}
						}
					}
					
					plg.init(this, Application, pageItemName);
					plg.setText( value );
					
					if( superType != "" )
					{
						var tmpargs:Array = args;
						args = superArgs;
						setType( superType );
						_type = "plugin";
						args = tmpargs;
					}
					setHeight( plg.getHeight() + 2 );
					setWidth( cssSizeX );
					dispatchEvent( new Event( "heightChange") );
				}
				else
				{
					Console.log("Error: Plugin '"+args[0]+"' Class Error");
				}
			}
			else
			{
				Console.log("Error: Plugin '"+args[0]+"' Class Not Found");
			}
			
		}
		
		public function convertColorTo ( mode:String ) :void
		{
			displayMode = mode;
			colorValue = 0xFF << 24 | color;
			textEnter();
		}
		
		public function setCurrentDate () :void
		{
			enterDate( new Date() );
			textEnter();
		}
		
		public function setVal ( val:String ) :void
		{
			if( _supertype == "listmultiple" || _supertype == "labellistmultiple" || _supertype == "listappend" ||  _supertype == "labellistappend" || _supertype == "itemlistmultiple" )
			{
				listAppend( val );
			}
			else
			{
				value = val;
				textEnter();
			}
		}
		
		public function setMin () :void
		{
			value = String(min);
			textEnter();
		}
		
		public function setMax () :void
		{
			value = String(max);
			textEnter();
		}
		
		private var dateFormat:String="d. m. y";
		
		private function enterDate (d:Date) :void
		{
			if( dateFormat )
			{
				var L:int = dateFormat.length;
				var c:String;
				var rv:String="";
				
				for(var i=0; i<L; i++ ) {
					c = dateFormat.charAt(i).toLowerCase();
					if( c == "d" ) {
						rv += d.getDate();
					}else if( c == "m" ) {
						rv += d.getMonth()+1;
					}else if( c == "y" ) {
						rv += d.getFullYear();
					}else if( c == "h" ) {
						rv += d.getHours();
					}else if( c == "i" ) {
						rv += d.getMinutes();
					}else if( c == "s" ) {
						rv += d.getSeconds();
					}else if( c == "t" ) {
						rv += d.getTimezoneOffset();
					}else{
						rv += c;
					}
				}
				
				value = rv;
			}
		}
		
		//      ..........
		//     : set type :
		//      ..........
		//
		public function setType (tp:String="text") :void
		{
			_type = tp;
			
			var i:int;
			var L:int;
			var s2:String;
			var tfh:int;
			var ta_str:String;
			var ta_arr:Array;
			var ta_i:int;
			var btn:Button;
			var pc:PropertyCtrl;
			
			try {
				pc = PropertyCtrl( parent );
			}catch( e:Error) {
				pc = null;
			}
			
			if( mediaContainer && contains(mediaContainer)) removeChild( mediaContainer );
			
			if( tfBtn && contains(tfBtn)) removeChild( tfBtn );
			tfBtn = null;
			if( tfPopup && contains(tfPopup)) removeChild( tfPopup );
			tfPopup = null;
			if( tfIcon && contains(tfIcon)) removeChild( tfIcon );
			tfIcon = null;
			if( tfSlider && contains(tfSlider)) removeChild( tfSlider );
			tfSlider = null;
			if( colorClip && contains(colorClip)) removeChild( colorClip );
			colorClip = null;
			if( colorPicker && contains(colorPicker)) removeChild( colorPicker );
			colorPicker = null;
			if( htmlTextField && contains( htmlTextField ) ) removeChild( htmlTextField );
			htmlTextField = null;
			
			if( vectorTextFields )
			{
				L = vectorTextFields.length;
				for(i=0; i<L; i++)
				{
					if(vectorTextFields[i] && vectorTextFields[i].textField && contains(vectorTextFields[i].textField)) removeChild(vectorTextFields[i].textField);
					if(vectorTextFields[i] && vectorTextFields[i].tfSlider && contains(vectorTextFields[i].tfSlider)) removeChild(vectorTextFields[i].tfSlider);
				}
				vectorTextFields = null;
			}
			
			if( vectorPlusButton && contains(vectorPlusButton)) removeChild(vectorPlusButton);
			if( vectorMinusButton && contains(vectorMinusButton)) removeChild(vectorMinusButton);
			if( vectorContainer && contains(vectorContainer)) removeChild(vectorContainer);
			
			vectorPlusButton = null;
			vectorMinusButton = null;
			vectorContainer = null;

			if( tp == "richtext" || tp == "text" || tp == "line" ) {
				value = HtmlParser.toInputText( value );
			}
			
			if( tp == "directory" || tp == "file"  ||  tp == "files" || tp == "image" || tp=="video" || tp=="audio" || tp=="pdf" || tp=="font" || tp == "zip")
			{
				var icoPath:String;
				if( tp == "image" ) {
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-image.png";
				}else if( tp == "video" ) {
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-video.png";
				}else if( tp == "audio" ) {
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-audio.png";
				}else if( tp == "pdf" ) {
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-pdf.png";
				}else if( tp == "zip" ) {
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-zip.png";
				}else{
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-text.png";
				}
				tfBtn = new Button([ new IconFromFile( icoPath,Options.iconSize,Options.iconSize ) ],btWidth,0,this,styleSheet,'','textbox-button', false);
				tfBtn.textAlign = "center";
				
				if(pc && !pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
					
				if( tp == "directory" )
				{
					tfBtn.addEventListener( MouseEvent.CLICK, selectDirectory );
					if( pc )
					{
						pc.uiCmds.push( new UICmd( [Language.getKeyword("Select Directory")], '', selectDirectory));
					}
				}
				else
				{
					initDragNDrop(this);
					
					if( this is VectorTextField )
					{
						tfBtn.addEventListener( MouseEvent.CLICK, selectFiles );
						if( pc )
						{
							pc.uiCmds.push( new UICmd( [Language.getKeyword("Select Files")], '', selectFiles));
						}
					}
					else
					{
						tfBtn.addEventListener( MouseEvent.CLICK, selectFile );
						if( pc ) {
							pc.uiCmds.push( new UICmd([Language.getKeyword("Select File")], '', selectFile));
						}
					}
				}
				if( pc )
				{
					pc.uiCmds.push( new UICmd( [Language.getKeyword("None")],'',selectNone) );
				}
				
				if( tp == "image" ) {
					fileFilterDescription = "Image Files";
					allowed_extensions  =  "*.gif;*.jpg;*.jpeg;*.jp2;*.j2k;*.png;*.svg;";
				}else if( tp == "video" ) {
					fileFilterDescription = "Video Files";
					allowed_extensions  =  "*.mp4;*.mov;*.ogg;*.webm;";
				}else if( tp == "audio" ) {
					fileFilterDescription = "Mp3 Files";
					allowed_extensions  =  "*.mp3;";
				}else if( tp == "pdf" ) {
					fileFilterDescription = "PDF Files";
					allowed_extensions  =  "*.pdf;";
				}else if( tp == "zip" ) {
					fileFilterDescription = "ZIP Files";
					allowed_extensions  =  "*.zip;";
				}else if( tp == "font" ) {
					fileFilterDescription = "Font Files";
					allowed_extensions  =  "*.ttf;*.woff;*.woff2;*.eot;";
				}
				if( args )
				{
					L = args.length;
					if( L > 0 ) www_folder = args[0];
					if( L > 1 ) rename_template = args[1];
					if( L > 2 ) fileFilterDescription = args[2];
					if( L > 3 ) allowed_extensions = args[3];
				}
				
				if( tp == "image" )
				{
					var m:Number = 4;
					var o:Object = styleSheet.getMultiStyle( [".media-container"] );
					if( o.marginLeft ) m = CssUtils.parse( o.marginLeft, this, "h" )
					
					mediaContainer = new Sprite();
					mediaContainer.addEventListener( MouseEvent.CLICK, largeImagePreview );
					mediaContainer.y = cssTop;
					mediaContainer.x = m;
					addChild(mediaContainer);
					
					if( value && value != "" && value.toLowerCase() != "none")
					{
						loadImage( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + value );
					}
				}
				else
				{
					// test if file exists
					if( ! disableFileSearch )
					{
						if( tp != "directory" && lastWebFileChecked != value )
						{
							if( CssUtils.trim(value) != "" && value.toLowerCase() != "none" )
							{
								var testFile:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + value );
								if( !testFile.exists )
								{
									if( value.substring(0,7) != "file://" )
									{
										lastWebFileChecked = value;
										CTTools.findWebFile( value, onFindFileComplete );
									}
								}
							}
						}
					}
				}
				
				setHeight( textField.height + 2);
				setWidth(getWidth());
				
			}
			else if( tp == "nodestyle" ) 
			{
				tfBtn = new Button([new IconFromFile(Options.iconDir + CTOptions.urlSeparator +"services.png"),Options.iconSize,Options.iconSize],btWidth,0,this,styleSheet,'','textbox-nodestyle-btn', false);
				textField.wordWrap = true;
				textField.autoSize = TextFieldAutoSize.LEFT;
				
				tfBtn.addEventListener( MouseEvent.CLICK, nodeStyleHandler );
				tfh = textField.height;
				textField.autoSize = TextFieldAutoSize.NONE;
				
				setHeight( tfh + 2 );
			}
			else if( tp == "styleclass" ) 
			{
				tfBtn = new Button([new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "modul.png"),Options.iconSize,Options.iconSize],btWidth,0,this,styleSheet,'','textbox-styleclass-btn', false);
				textField.wordWrap = true;
				textField.autoSize = TextFieldAutoSize.LEFT;
				tfBtn.addEventListener( MouseEvent.CLICK, styleClassHandler );
				tfh = textField.height;
				textField.autoSize = TextFieldAutoSize.NONE;
				
				setHeight( tfh + 2 );
			}
			else if ( tp == "date" )
			{
				if( args )
				{
					L = args.length;
					if( L > 0 ) dateFormat = args[0];
				}
				
				if(pc)
				{
					if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
					pc.uiCmds.push( new UICmd( [Language.getKeyword("Today")],'',setCurrentDate) );
				}
				if( !value )
				{
					setCurrentDate();
				}
				
				setHeight( textField.height + 2 );
			}
			else if ( tp == "boolean" )
			{
				if( args )
				{
					L = args.length;
					if( L > 0 ) boolYes = args[0];
					if( L > 1 ) boolNo = args[1];
				}
				
				var ico:Sprite = new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "toggle-off-btn.png", Options.btnSize, Options.btnSize );
				
				tfBtn = new Button([ico],0,0,this,styleSheet,'','textbox-boolean-btn', false);
				tfBtn.addEventListener( MouseEvent.CLICK, boolButtonHandler );
				
				if( boolValue || value == boolYes || value=="true" || CssUtils.stringToBool(value) )
				{
					boolValue = true;
				}
				
				setHeight( textField.height + 2 );
			}
			else if ( tp == "plugin" )
			{
				// Add Plugin to root template cmd.xml to load .swf plugin files
				// Plugin interface methods: init(container:InputTextBox):Boolean, getText():String, setText(String):void, setWidth(int):void, getHeight():int
				//
				//    		
				//
				// Example Audio WaveForm Generator
				// plugin displays ui on init with a file selector for audio files
				// on select file (or getText()), the plugin class generates a Bitmap with the waveform in the web-directories (min and raw)
				// 
				// Compile air swf with a class for the input plugin
				//
				// - Create SWF class wich simply embeds the WaveFormEx class.
				//
				// - Create the WaveFormEx class:
				// package plugins
				// {
				//  import ct.ctrl.InputTextBox;
				//
				//	public class WaveFormEx 
				//  {
				//		public function WaveForm() {}
				//
				//		public static function getMember ( pageItem:String, memeber:String ) :String { 
				//			return pageItems[ pageItem ][ member ];
				//		}
				//
				//		public static superType:String = "audio";
				//
				//		private var _appInst:Object; 
				//		private var _container:Sprite; 
				//		private var pageItems:Array = []; 
				//
				//		public function init( container:Object, app:Object, pageItemName:String ) :void { 
				//			// ... 
				//			// create plugin-ui inside InputTextBox (Sprite)
				//			//...
				//
				//			// Usage witch app-plugin communication
				//			// Store container and app
				//
				//			// get to Application instance (CTMain):
				//			_appInst = app.instance;
				//
				//			// get the input container (InputTextBox)
				//			_container = Sprite( container );
				//			
				//			// get CTTools class from app:
				//			var t:Object = app.getClass("ct.CTTools");
				//			trace( "Project Directory: " + t.projectDir);
				//
				//			// ...
				//		}
				//		
				//		public function getText() :String {
				//			// ... 
				//			// return path to image in webdir: images/wave.png (the html ouput of the plugin)
				//			// ...
				//		}
				//		public function setText(s:String) :void { 
				//			// ... 
				//			// set img path..
				// 			// build wave form bmp..
				//			// ...
				//		}
				//		public function setWidth ( int ) { 
				//			// set ui width
				//		}
				//		public function getHeight () :int { 
				//			// return height of the input component
				//			return 100;
				//		}
				//	} 
				// }
				//
				//
				// Embed plugin in a Theme:
				//
				// - Copy waveform.swf into theme/plugins folder
				//
				// - In theme config.xml add plugins folder to staticfolders:
				// <template.. staticfolders="plugins,pdfs".. />
				//
				// - In theme config file, cmd.xml, load the plugin:
				// <cmd name=="CTTools load-plugin app.contemple.WaveForm template:/plugins/waveform.swf"/>
				//
				// - In hteml template display the generated Bitmap:
				// <img src="{#wave:Plugin("contemple.WaveForm","plugins.WaveFormEx",256,4,'#567','#123') ='images/waveform-01.png'}
				//
				if( !args || args.length <= 1 )
				{
					Console.log("Error: Plugin Arguments Missing: Plugin( id, className, [superArgs..] )");
					return;
				}
				setTimeout( initPlugin, 0 );
			}
			else if( tp == "number" || tp == "integer" || tp == "screennumber" || tp == "screeninteger" )
			{
				if(pc)
				{
					if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
					pc.uiCmds.push(new UICmd(['#separator']));
				}
				if( args && args.length > 1)
				{
					tfSlider = new Slider(0, 0, this,styleSheet, '', 'textbox-slider', false);
					tfSlider.setScrollerHeight( int(textField.width / 10) );
					tfSlider.setHeight( textField.width - (8 * CssUtils.numericScale) );
					tfSlider.setWidth( tfSlider.getWidth() || int(8 * CssUtils.numericScale) );
					tfSlider.rotation = -90;
					tfSlider.x = 0;
					tfSlider.wheelScrollTarget = null;
					tfSlider.y = textField.height + int( 6 * CssUtils.numericScale );
					tfSlider.minValue = Number( args[0] );
					min = tfSlider.minValue;
					tfSlider.maxValue = Number( args[1] );
					max = tfSlider.maxValue;
					tfSlider.value = StringMath.forceNumber( value );
					tfSlider.addEventListener( "begin", sliderBegin );
					tfSlider.addEventListener( MouseEvent.MOUSE_UP, sliderUp );
					tfSlider.addEventListener( Event.CHANGE, sliderChange );
					if( args.length > 2 ) sliderGrid = Number( args[2] );
					var cdp:int = String( sliderGrid - int(sliderGrid) ).length - 1;
					if( cdp >= 0 ) { decPlaces = cdp; }
					if( args.length > 3 ) outsideRange = CssUtils.stringToBool( args[3] );
					if( args.length > 4 ) decPlaces = parseInt(args[4]);
					
					if(pc)
					{
						pc.uiCmds.push(new UICmd([Language.getKeyword("Minimum")],'',setMin));
						pc.uiCmds.push(new UICmd([Language.getKeyword("Maximum")],'',setMax));
					}
				}
				if ( tp == "screennumber" ||  tp == "screeninteger"  )
				{
					L = screenUnits.length;
					
					if(pc) pc.uiCmds.push( new UICmd(['#separator']) );
					
					for (i = 0; i < L; i++)
					{
						if (pc)
						{
							pc.uiCmds.push(new UICmd([Language.getKeyword("Convert to ") + " " + screenUnits[i].toUpperCase()], '', convertNumberTo, [screenUnits[i]] ));
						}
					}
				}
				
				if( tfSlider )
				{
					setHeight( textField.height + int(16 * CssUtils.numericScale) );
				}
				else
				{
					setHeight( textField.height + int(2 * CssUtils.numericScale) );
				}
				
			}
			else if( tp == "vector" )
			{
				if( args && args.length > 1 ) 
				{
					// Vector Arguments:
					// Number Length, String Type, String DefaultWrap, Char Separator, Boolean DynaLength, type_defalts..., val1, type_args1..., val2, type_args2...,
					// Examples:
					// 2, Number, "x|", ",", false, fixRatio, outsideRange, val1, min1, max1, grid1, wrap1, val2...
					// 1, File,'<img src="|"/>', ",", true, defaultWWWFolder, defaultrename, defaultDescr, defaultExtList, value1, [wwwfolder1, rename1, file-descr1, extlist1, value2...]
					// 0, String, '<p>|</p>','|', true, val1, wrap1, val2, wrap2...
					
					vectorContainer = new CssSprite(0,0,this,styleSheet,'div','','input-vector-container', false);
					vectorContainer.y = textField.y;

					L = parseInt( args[0] );
					
					var L2:int;
					
					var _tp:String = args[1];
					vectorType = _tp.toLowerCase();
					
					if( args.length > 2 ) vectorWrap = args[2] || "";
					if( args.length > 3 ) vectorSeparator = args[3] || ",";
					if( args.length > 4 ) vectorDynamic = typeof args[4] == "boolean" ? args[4] : CssUtils.stringToBool( args[4] );

					if( L <= 1 || vectorDynamic)
					{
						if( L == 0 ) L = 1;
						// dynamic length
						vectorPlusButton = new Button(["+"], Options.btnSize, 0, vectorContainer, styleSheet, '', 'input-vector-plus-button', false);
						vectorMinusButton = new Button(["-"], Options.btnSize, 0, vectorContainer, styleSheet, '', 'input-vector-minus-button', false);
						vectorPlusButton.x = cssSizeX - (Options.btnSize+2);
						vectorMinusButton.x = cssSizeX - ((Options.btnSize+2)*2);
						vectorPlusButton.addEventListener(MouseEvent.CLICK, vectorPlusClick);
						vectorMinusButton.addEventListener(MouseEvent.CLICK, vectorMinusClick);
					}

					var tf:VectorTextField;
					vectorTextFields = new Vector.<VectorTextField>();
					tfh = textField.height;					
					var vecArgs:Array;
					var vecObj:Object;
					var vecValue:String;
					var vecWrap:String;
					var valStart:int;
					var tmph:int;
					var splitValues:Array = value.split( vectorSeparator );
					var typeList:Array;
					
					if( vectorType == "directory" || vectorType == "file" || vectorType == "files" || vectorType == "image" || vectorType == "video" || vectorType == "audio" || vectorType == "pdf" || vectorType == "font" || vectorType == "zip" )
					{
						if( args.length > 5 ) defaultWWWFolder = args[5];
						if( args.length > 6 ) defaultRename = args[6];
						if( args.length > 7 ) defaultDescr = args[7];
						if( args.length > 8 ) defaultExtList = args[8];
						
						L2 = Math.max( L, splitValues.length );
						
						for(i=0; i<L2; i++)
						{
							vecArgs = [];
							valStart = 9 + i*6;
							
							if( args.length > valStart ) vecValue = args[ valStart ];
							else vecValue = "";
							
							if( splitValues.length > i ) vecValue = splitValues[i];
							
							if( args.length > valStart+1) 
							{
								vecArgs.push(args[valStart+1]);
								if( args.length > valStart+2) vecArgs.push(args[valStart+2]);
								if( args.length > valStart+3) vecArgs.push(args[valStart+3]);
								if( args.length > valStart+4) vecArgs.push(args[valStart+4]);
								if(args.length > valStart+5) vecWrap = args[valStart+5];
							}
							else
							{
								vecArgs.push( defaultWWWFolder, defaultRename, defaultDescr, defaultExtList );
								vecWrap = vectorWrap;
							}
							
							vecObj = {};
							CTTools.cloneTo( propObj, vecObj );
							tf = new VectorTextField( vectorType, vecArgs, vecObj, vecValue, cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
							
							
							tf.addEventListener( "heightChange", vectorImageHeightChange );
							
							tf.wrap = vecWrap;
							tf.rootVector = this;
							vectorTextFields.push ( tf );
						}
					}
					else if ( vectorType == "number" || vectorType == "integer" || vectorType == "screennumber" || vectorType == "screeninteger")
					{
						if( args.length > 5 ) vectorFixRatio = typeof args[5] == "boolean" ? args[5] : CssUtils.stringToBool( args[5] );
						if( args.length > 6 ) outsideRange = typeof args[6] == "boolean" ? args[6] : CssUtils.stringToBool( args[6] );
						
						L2 = Math.max( L, splitValues.length );
						
						for(i=0; i<L2; i++)
						{
							vecArgs = [];
							vecObj = {};
							valStart = 7 + i*5;

							if( args.length > valStart ) vecValue = args[ valStart ];
							if( splitValues.length > i ) vecValue = splitValues[i];
							if( args.length > valStart+1) vecArgs.push(Number(args[valStart+1]));
							if( args.length > valStart+2) vecArgs.push(Number(args[valStart+2]));
							if( args.length > valStart+3) vecArgs.push(Number(args[valStart+3]));
							if( args.length > valStart+4) vecWrap = args[valStart+4];

							tf = new VectorTextField( vectorType, vecArgs, vecObj, vecValue, cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
							tf.wrap = vecWrap;
							tf.rootVector = this;
							vectorTextFields.push( tf );
						}
					}
					else if ( vectorType == "itemlist" )
					{
						L2 = Math.max( L, splitValues.length );
						if( args.length > 5 ) field = args[5];
						if( args.length > 6 ) labelfield = args[6];
						if( args.length > 7 ) pre = args[7];
						if( args.length > 8 ) post = args[8];
						
						for(i=0; i<L2; i++)
						{
							vecArgs = [];
							vecObj = {};
							valStart = 9 + i*4;

							if( args.length > valStart ) 
							{
								vecValue = args[ valStart ];
								if( splitValues.length > i ) vecValue = splitValues[i];
								if( args.length > valStart+1) vecArgs.push(Number(args[valStart+1]));
								if( args.length > valStart+2) vecArgs.push(Number(args[valStart+2]));
								if( args.length > valStart+3) vecArgs.push(Number(args[valStart+3]));
								if( args.length > valStart+4) vecArgs.push(Number(args[valStart+4]));
							}
							else
							{
								vecArgs.push( field, labelfield, pre, post);
							}
							
							tf = new VectorTextField( vectorType, vecArgs, vecObj, vecValue, cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
							tf.wrap = vecWrap;
							tf.rootVector = this;
							vectorTextFields.push( tf );
						}
					}
					else if ( vectorType == "typed" )
					{
						if( args.length > 5 )
						{ 
							if( typeof args[5] == "string" )
							{
								if( args[5].charAt(0) == "*" )
								{
									typeList = String(Application.instance.strval(ta_str.substring(1),true)).split(",");
								}
								else
								{
									typeList = String(args[5]).split(",");
								}
							}
							else
							{
								typeList = args[5];
							}
						}
						
						if(typeList )
						{
							L2 = Math.max( L, splitValues.length );
							var tps:Array;
							var vtp:String;
							
							for(i=0; i<L2; i++)
							{
								vecArgs = typeList;
								vecObj = {};
								valStart = 6 + i*2;

								if( args.length > valStart ) vecValue = args[ valStart ];
								if( splitValues.length > i ) vecValue = splitValues[i];
								if( vecValue.indexOf(":"))
								{
									tps = vecValue.split(":");
									if( tps.length > 1 )
									{
										vtp = tps.shift();
										vecValue = tps.join(":");
									}									
								}
								else
								{
									vtp = "";
								}
								tf = new VectorTextField( vectorType, vecArgs, vecObj, vecValue, cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
								
								if( tf.tfPopup && tf.tfPopup.label ) tf.tfPopup.label = vtp;
								tf.wrap = vecWrap;
								tf.rootVector = this;
								vectorTextFields.push( tf );
							}
						}
					}
					else
					{
						L2 = Math.max( L, splitValues.length );
						
						if( args.length > 5 ) defaultWWWFolder = args[5];
						
						for(i=0; i<L2; i++)
						{
							vecArgs = [];
							vecObj = {};
							valStart = 5 + i*2;

							if( args.length > valStart )
							{
								vecValue = args[ valStart ];
								vecArgs.push( args[valStart] );
							};
							if( splitValues.length > i ) vecValue = splitValues[i];
							if( args.length > valStart+1)
							{
								vecWrap = args[valStart+1];
								vecArgs.push( args[valStart+1] );
								// only two args supported..
							}

							tf = new VectorTextField( vectorType, vecArgs, vecObj, vecValue, cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
							tf.wrap = vecWrap;
							tf.rootVector = this;
							
							vectorTextFields.push( tf );
						}
					}
					
					formatVector();
				}
				
				var vpmb:int = 0;
				if(vectorPlusButton && vectorMinusButton)
				{
					vpmb = Math.max(vectorPlusButton.cssSizeY, vectorMinusButton.cssSizeY)
				}
				setHeight( textField.height + 2 + vpmb );
			}
			else if( tp == "text" || tp == "code" )
			{
				textField.multiline = true;
				textField.wordWrap = true;
				
				rtItemList = new ItemList(0, 0, this, this.styleSheet, '', 'richtext-btn-list', false);
				
				btn = new Button([new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "undo.png",Options.iconSize,Options.iconSize)],0,0,rtItemList,this.styleSheet,'','richtext-btn richtext-btn-first',false);
				btn.options.originalLabel = ".Undo";
				btn.addEventListener(MouseEvent.MOUSE_DOWN, richtTextBtnHandler);
				rtItemList.addItem(btn, true);
				
				btn = new Button([new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "redo.png",Options.iconSize,Options.iconSize)],0,0,rtItemList,this.styleSheet,'','richtext-btn richtext-btn-last',false);
				btn.options.originalLabel = ".Redo";
				btn.addEventListener(MouseEvent.MOUSE_DOWN, richtTextBtnHandler);
				rtItemList.addItem(btn, true);
				
				rtItemList.format(true);
				historyPush( textField.text );
				textField.autoSize = TextFieldAutoSize.LEFT;
				textField.width = getWidth() - ( rtItemList.width + 4);
				
				tfh = textField.height;
				textField.autoSize = TextFieldAutoSize.NONE;
				
				setHeight( tfh + 2 );
				setWidth(getWidth());
				
			}
			else if ( tp == "color")
			{
				setHeight( textField.height + 2);
				colorClip = new Sprite();
				colorValue = value;
				
				var colorStyle:Object = styleSheet.getStyle(".textbox-color-clip");
				
				if( colorStyle )
				{
					if( colorStyle.marginRight )
					{
						colorOfs = CssUtils.parse( colorStyle.marginRight, this );
					}
					if( colorStyle.paddingRight )
					{
						colorOfs = Math.max( colorOfs, CssUtils.parse( colorStyle.paddingRight, this) );
					}
				}
				if(pc)
				{
					if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
					pc.uiCmds.push(new UICmd(['#separator']));
					pc.uiCmds.push(new UICmd([Language.getKeyword('Select Color')],'',onSelectColor,[null]));
					pc.uiCmds.push(new UICmd(['#separator']));
					pc.uiCmds.push(new UICmd([Language.getKeyword('Convert to') + ' RGB'],'',convertColorTo,['rgb']));
					pc.uiCmds.push(new UICmd([Language.getKeyword('Convert to') + ' RGBA'],'',convertColorTo,['rgba']));
					pc.uiCmds.push(new UICmd(['#separator']));
					pc.uiCmds.push(new UICmd([Language.getKeyword('Convert to') + ' HSL'],'',convertColorTo,['hsl']));
					pc.uiCmds.push(new UICmd([Language.getKeyword('Convert to') + ' HSLA'],'',convertColorTo,['hsla']));
					pc.uiCmds.push(new UICmd(['#separator']));
					pc.uiCmds.push(new UICmd([Language.getKeyword('Convert to') + ' HEX'],'',convertColorTo,['hex']));
				}
				drawCurrentColor();
				
				ColorPicker.testColor( this._color );
				
				if( propObj && propObj.defValue )
				{
					var clo:int = CssUtils.parse( propObj.defValue );
					ColorPicker.testColor( clo );
				}
				
				colorClip.addEventListener( MouseEvent.CLICK, onSelectColor);
				addChild( colorClip );
			}
			else if( tp == "richtext" )
			{
				var cssclasses:Array;
				if( CTTools.templateConstants && CTTools.templateConstants["richTextCssClasses"] != undefined )
				{
					if( args && args.length > 0 )
					{
						cssclasses = (args[0] + CTTools.templateConstants["richTextCssClasses"]).split(",");
					}
					else
					{
						cssclasses = CTTools.templateConstants["richTextCssClasses"].split(",");
					}
				}
				else
				{
					if( args && args.length > 0 )
					{
						cssclasses = (args[0] + CTOptions.richTextCssClasses.join(",")).split(",");
					}
					else
					{
						cssclasses = CTOptions.richTextCssClasses;
					}
				}
				
				richTextButtons = [ cssclasses, specialChars, ".Heading", ".List", ".Bold", ".Italic", ".Link", ".Undo", ".Redo" ];
				
				textField.multiline = true;
				textField.wordWrap = true;
				
				specialCharIcons = {
					name: new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "categorize.png", Options.iconSize, Options.iconSize )
				}
				
				for (var icname:String in specialChars )
				{
					if ( icname != "name" )
					{
						specialCharIcons[ icname ] = new IconFromHtml( '<p class="special-char-icon">' + specialChars[icname] + '</p>', styleSheet, "special-char-icon", Options.iconSize, Options.iconSize );
					}
				}
				richTextIcons =  [	richTextCssIcons, specialCharIcons,
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "kopfzeile.png",Options.iconSize, Options.iconSize), 
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "li.png",Options.iconSize, Options.iconSize), 
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "fett-gedruckt.png",Options.iconSize, Options.iconSize), 
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "kursiv.png",Options.iconSize, Options.iconSize),
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "link.png",Options.iconSize, Options.iconSize),
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "undo.png",Options.iconSize, Options.iconSize), 
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "redo.png",Options.iconSize, Options.iconSize)  ];
				
				rtItemList = new ItemList(0,0,this,this.styleSheet,'','richtext-btn-list', false);
				
				var btnpp:Popup;
				var s:int;
				var n:String;
				var ppi:PopupItem;
				var icons:Array;
				
				for( i=0; i < richTextButtons.length; i++)
				{
					if( richTextButtons[i] is Array )
					{
						if( richTextButtons[i][0].charAt(0) == "." )
						{
							icons = [];
						}
						else
						{
							icons = [ richTextButtons[i][0] ];
						}
						
						if( richTextIcons && richTextIcons.length > i )
						{
							if( richTextIcons[i] is Array && richTextIcons[i].length > 0 )
							{
								icons.push( richTextIcons[i][0] );
							}
						}						
						btnpp = new Popup( icons, 0,0,rtItemList, cssStyleSheet,'','richtext-popup' + (i==0?" richtext-popup-first" : (i==richTextButtons.length-1 ? " richtext-popup-last":"") ),false);
						btnpp.alignH = "left";
						btnpp.rootNode.alignH = "left";
						btnpp.textAlign = "left";
						btnpp.alignV = "auto";
						
						for(s=1; s < richTextButtons[i].length; s++)
						{
							btnpp.rootNode.addItem( [ ""+richTextButtons[i][s]], cssStyleSheet);
						}
						
						btnpp.addEventListener( Event.SELECT, richtTextPPHandler);
						rtItemList.addItem(btnpp,true);
					
					}
					else if( richTextButtons[i] is String )
					{
						
						if( richTextButtons[i].charAt(0) == "." )
						{
							icons = [];
						}
						else
						{
							icons = [ Language.getKeyword( richTextButtons[i] ) ];
						}
						
						if( richTextIcons && richTextIcons.length > i ) {
							icons.push( richTextIcons[i] );
						}
						
						btn = new Button(icons,0,0,rtItemList,this.styleSheet,'','richtext-btn'+ (i==0?" richtext-btn-first" : (i==richTextButtons.length-1?" richtext-btn-last":"")),false);
						btn.options.originalLabel = richTextButtons[i];
						btn.addEventListener(MouseEvent.MOUSE_DOWN, richtTextBtnHandler);
						rtItemList.addItem(btn, true);
					
					}
					else if ( richTextButtons[i] is Object )
					{
						if( richTextButtons[i].name.charAt(0) == "." )
						{
							icons = [];
						}
						else
						{
							icons = [richTextButtons[i].name];
						}
						
						if( richTextIcons && richTextIcons.length > i )
						{
							if( richTextIcons[i] is Object && richTextIcons[i]["name"] != undefined )
							{
								icons.push(  richTextIcons[i]["name"] );
							}
						}
						
						btnpp = new Popup( icons,0,0,rtItemList, cssStyleSheet,'','richtext-popup' + (i==0?" richtext-popup-first" : (i==richTextButtons.length-1 ? " richtext-popup-last":"") ),false);
						btnpp.alignH = "left";
						btnpp.rootNode.alignH = "left";
						btnpp.textAlign = "left";
						btnpp.alignV = "auto";
						
						for( n in richTextButtons[i] )
						{
							if( n != "name" )
							{
								icons = [];
								
								if( richTextIcons && richTextIcons.length > i )
								{
									if( richTextIcons[i] is Object && richTextIcons[i][n] != undefined )
									{
										icons.push( richTextIcons[i][n] );
									}
								}
								icons.push("" + n);
								
								ppi = btnpp.rootNode.addItem( icons, cssStyleSheet);
								ppi.options.overrideVal = richTextButtons[i][n];
							}
						}
						btnpp.addEventListener( Event.SELECT, richtTextPPHandler);
						rtItemList.addItem(btnpp,true);
					}
				}
				
				rtItemList.format(false);
				historyPush( textField.text );
				textField.autoSize = TextFieldAutoSize.LEFT;
				textField.width = getWidth() - ( rtItemList.width + 4);
				
				tfh = textField.height;
				textField.autoSize = TextFieldAutoSize.NONE;
				
				setHeight( tfh + 2 );
				setWidth(getWidth());
			}
			else if ( tp == "area" )
			{
				if( args )
				{
					L = args.length;
					
					// Inline Area:
					// {# myitems : Area(Area-Name, area-type, [offset], [limit], [subTemplateNameFilter]) }
					
					var areaObj:Object = {};
					CTTools.cloneTo( propObj, areaObj );
					
					if( updateItem )
					{
						CTTools.cloneTo( updateItem, areaObj );
					}
					try {
						areaObj["itemname"] = Application.instance.view.panel.src.editor.currentEditor.updateItem.name;
					}catch( e:Error ) {
						Console.log("Error: No AreaEditor..");
					}
					
					if( L > 0 ) areaName =  CTTools.webFileName( String(args[0]), areaObj );
					if( L > 1 ) areaType = String(args[1]);
					if( L > 2 ) areaOffset = parseInt( args[2] );
					if( L > 3 ) areaLimit = parseInt( args[3] );
					if( L > 4 ) areaSubTemplateFilter = String(args[4]);
					
					showAreaItems()
				}
			}
			else if( tp == "typed" )
			{
				if( args && args.length > 0 )
				{
					var types:Array;
					
					if(pc)
					{
						if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
						else pc.uiCmds.push(new UICmd(['#separator']));
						pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
						pc.uiCmds.push(new UICmd(['#separator']));
					}
					
					if( args[0] is String )
					{
						var s3:int = args[0].indexOf(":");
						if( s3 >= 1 )
						{
							types = [];
							var tmp:Array = args[0].split(":");
							if( CTTools.pageItems )
							{
								L = CTTools.pageItems.length;
								for( i=0; i < L; i++)
								{
									if( CTTools.pageItems[i].area == tmp[0] )
									{
										types.push( CTTools.pageItems[i][tmp[1]] );
									}
								}
							}
						
						}
						else
						{
							types = args; 
						}
					}
					else
					{
						types = args[0] is Array ? args[0] : args;
					}
					
					if( types )
					{
						
						tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize ), types[0] ], 0, textField.height - 1, this, styleSheet, '', 'textbox-typed', false);
						tfPopup.alignH = "right";
						tfPopup.textAlign = "right";
						tfPopup.alignV = "bottom";
						
						if( types.length > 0)
						{
							L = types.length;
							for(i=0; i < L; i++)
							{
								tfPopup.rootNode.addItem( [ "" + types[i] ], styleSheet);
								if(pc)
								{
									pc.uiCmds.push(new UICmd([types[i]],'',setTyped,[types[i]]));
								}
							}
						}
						
						tfPopup.addEventListener( Event.SELECT, ppTypedSelect );
						textField.width = textField.width - tfPopup.cssSizeX;
					}
				}
				setHeight( textField.height + 2 );
				
			}
			else if( tp == "list" )
			{
				if( args && args.length > 0 )
				{
					tfIcon = new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize );
					addChild( tfIcon );
					
					if (pc)
					{
						if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
						else pc.uiCmds.push(new UICmd(['#separator']));
						pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
						pc.uiCmds.push(new UICmd(['#separator']));
						
						if( args.length == 1 )
						{
							var spa:Array;
							if( args[0] is Array )
							{
								spa = args[0];
							}
							else
							{
								spa = args[0].split(",");
							}
							
							L = spa.length;
							
							for(i=0; i < L; i++)
							{
								if( spa[i] is Array ) {
									pc.uiCmds.push(new UICmd(spa[i],'',setVal,spa[i][1]));
								}else{
									ta_str = spa[i];
								
									if( ta_str.charAt(0) == "#" && ( ta_str != "#separator" ) )
									{
										if( CTTools.templateConstants && CTTools.templateConstants[ ta_str.substring(1) ] != undefined )
										{
											ta_arr = CTTools.templateConstants[ ta_str.substring(1) ].split(",");
											
										}
										if( !ta_arr ) {
											try {
												ta_str2 = String( Application.instance.strval( ta_str.substring(1), true ) );
												if( ta_str2 != "{*"+ta_str.substring(1)+"}" ) {
													ta_arr = ta_str2.split(",");
												}
											}catch(e:Error) {
												
											}
										}
										
										if( ta_arr )
										{
											for( ta_i=0; ta_i < ta_arr.length; ta_i++)
											{
												s2 = TemplateTools.obj2Text(ta_arr[ta_i], "#", propObj, false, false );
												pc.uiCmds.push(new UICmd([s2],'',setVal,[s2]))
											}
											
											continue;
										}
										else
										{
											Console.log("Identifier Not Found: " + ta_str);
										}
									}
									
									s2 = TemplateTools.obj2Text( ta_str, "#", propObj, false, false );
									
									pc.uiCmds.push(new UICmd([s2],'',setVal,[s2]));
								}
							}
						}
						else
						{
							L = args.length;
							for(i=0; i < L; i++)
							{
								if( args[i] is Array ) {
									pc.uiCmds.push(new UICmd([args[i]],'',setVal,[args[i]]));
									continue;
								}else{
									ta_str = args[i];
									
									if( ta_str.charAt(0) == "#" && ( ta_str != "#separator" ) )
									{
										if( CTTools.templateConstants && CTTools.templateConstants[ ta_str.substring(1) ] != undefined )
										{
											ta_arr = CTTools.templateConstants[ ta_str.substring(1) ].split(",");
											
										}
										if( !ta_arr ) {
											try {
												ta_str2 = String( Application.instance.strval( ta_str.substring(1), true ) );
												if( ta_str2 != "{*"+ta_str.substring(1)+"}" ) {
													ta_arr = ta_str2.split(",");
												}
											}catch(e:Error) {
												
											}
										}
										
										if( ta_arr )
										{
											for( ta_i=0; ta_i < ta_arr.length; ta_i++)
											{
												s2 = TemplateTools.obj2Text(ta_arr[ta_i], "#", propObj, false, false );
												pc.uiCmds.push(new UICmd([s2],'',setVal,[s2]));
												
											}
											
											continue;
										}
										else
										{
											Console.log("Identifier Not Found: " + ta_str);
										}
									}
								}
								s2 = TemplateTools.obj2Text( ta_str, "#", propObj, false, false );
								pc.uiCmds.push(new UICmd([s2],'',setVal,[s2]));
							}
								
						}
					}
					
					tfIcon.addEventListener( MouseEvent.CLICK, iconListSelect );
					textField.width = textField.width - tfIcon.width;
				}
				setHeight( textField.height + 2 );
			}
			else if( tp == "listappend" || tp == "listmultiple" )
			{
				if( args && args.length > 0 )
				{
					tfIcon = new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize );
					addChild( tfIcon );
					
					if (pc)
					{
						if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
						else pc.uiCmds.push(new UICmd(['#separator']));
						pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
						pc.uiCmds.push(new UICmd(['#separator']));
					
						listAppendSeparator = args[0];
						var ta_str2:String;
						
						if( args.length > 1) {
							L = args.length;
							
							for(i=1; i < L; i++)
							{
								ta_str = args[i];
								
								if( ta_str.charAt(0) == "#" && ( ta_str != "#separator" ) )
								{
									if( CTTools.templateConstants && CTTools.templateConstants[ ta_str.substring(1) ] != undefined )
									{
										ta_arr = CTTools.templateConstants[ ta_str.substring(1) ].split(",");
									}
									
									if( !ta_arr ) {
										try {
											ta_str2 = String( Application.instance.strval( ta_str.substring(1), true ) );
											if( ta_str2 != "{*"+ta_str.substring(1)+"}" )
											{
												ta_arr = ta_str2.split();
											}
										}catch(e:Error) {
											
										}
									}
									
									if( ta_arr )
									{
										for( ta_i=0; ta_i < ta_arr.length; ta_i++)
										{
											s2 = TemplateTools.obj2Text(ta_arr[ta_i], "#", propObj, false, false );
											pc.uiCmds.push(new UICmd([s2],'',setVal,[s2]));
										}
										continue;
									}
									else
									{
										Console.log("Identifier Not Found: " + ta_str);
									}
								}
								s2 = TemplateTools.obj2Text( ta_str, "#", propObj, false, false );
								// no var or constants found:
								pc.uiCmds.push(new UICmd([s2],'',setVal,[s2]));
							}
						}
						tfIcon.addEventListener( MouseEvent.CLICK, iconListSelect );
						textField.width = textField.width - tfIcon.width;
					}
				}
				setHeight( textField.height + 2 );
			}
			else if( tp == "pagelist" )
			{
				
				if ( pc )
				{
					tfIcon = new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize );
					addChild( tfIcon );
					
					var pages:Array = [];
					
					if( CTTools.pages && pc )
					{
						
						if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
						else pc.uiCmds.push(new UICmd(['#separator']));
						pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
						pc.uiCmds.push(new UICmd(['#separator']));
					
						L = CTTools.pages.length;
						
						if( args && args.length > 0)
						{
							var key:String;
							var val:String;
							if( args.length > 1 )
							{
								key = args[0].toLowerCase();
								val = args[1];
							}
							else
							{
								val = args[0];
								key = "parent";
							}
							
							for(i=0; i<L; i++)
							{
								// filter pages by key/val - args[0]/args[1]
								if( pages[i][key] == val )
								{
									pages.push( CTTools.pages[i].filename );
								}
							}
							if( pages.length > 0 )
							{
								if( args.length > 2 )
								{
									// filter again with args[2]/args[3]
									if( args.length > 3 )
									{
										key = args[2].toLowerCase();
										val = args[3];
									}
									else
									{
										val = args[2];
										key = "parent";
									}
									
									for(i=pages.length-1; i>=0; i--)
									{
										if( pages[i][key] != val )
										{
											pages.splice(i,1);
										}
									}
								}
							}
						}
						else
						{
							// show all pages
							for(i=0; i<L; i++) {
								pages.push( CTTools.pages[i].filename );
							}
						}
					}
					pages.sort();
					
					if( pages.length > 0)
					{
						L = pages.length;
						for(i=0; i < L; i++)
						{
							pc.uiCmds.push(new UICmd([pages[i]],'',setVal,[pages[i]]));
							
						}
					}
					
					tfIcon.addEventListener( MouseEvent.CLICK, iconListSelect );
					textField.width = textField.width - tfIcon.width;
				}
				setHeight( textField.height + 2 );
				
			}
			else if( tp == "arealist" )
			{
				if ( pc )
				{
					tfIcon = new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize );
					addChild( tfIcon );
					
					var areas:Array = [];
					if(pc)
					{
						if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
						else pc.uiCmds.push(new UICmd(['#separator']));
						pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
						pc.uiCmds.push(new UICmd(['#separator']));
					}
					
					if( CTTools.activeTemplate && CTTools.activeTemplate.areasByName )
					{
						for(var areaname:String in CTTools.activeTemplate.areasByName )
						{
							if( areas.indexOf( CTTools.activeTemplate.areasByName[areaname].name ) == -1 )
							{
								areas.push(CTTools.activeTemplate.areasByName[areaname].name);
							}
						}
					}
					areas.sort();
					
					if( areas.length > 1)
					{
						L = areas.length;
						for(i=0; i < L; i++)
						{
							pc.uiCmds.push(new UICmd([areas[i]],'',setVal,[areas[i]]));
						}
					}
					tfIcon.addEventListener( MouseEvent.CLICK, iconListSelect );
					textField.width = textField.width - tfIcon.width;
					
				}
				setHeight( textField.height + 2 );
			}
			else if( tp == "itemlist" )
			{
				
				// ItemList( area-name, [field], [pre], [post], [labelfield] )
				if( pc && args && args.length > 0)
				{
					tfIcon = new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize );
					addChild( tfIcon );
					
					var items:Array = [];
					var area:String = args[0];
					var pre:String = "";
					var post:String = "";
					var field:String = "name";
					var labelfield:String = "name";
					
					if( args.length > 1 ) field = args[1];
					if( args.length > 2 ) pre = args[2];
					if( args.length > 3 ) post = args[3];
					if( args.length > 4 ) labelfield = args[4];
					
					if( CTTools.pageItems )
					{
						if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
						else pc.uiCmds.push(new UICmd(['#separator']));
						pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
						pc.uiCmds.push(new UICmd(['#separator']));
						
						L = CTTools.pageItems.length;
						for( i=0; i < L; i++)
						{
							if( CTTools.pageItems[i].area == area )
							{
								pc.uiCmds.push(new UICmd([ CTTools.pageItems[i][labelfield] ],'',setVal,[  pre + CTTools.pageItems[i][field] + post ] ));
							}
						}
					}
					
					tfIcon.addEventListener( MouseEvent.CLICK, iconListSelect );
					textField.width = textField.width - tfIcon.width;
					
					setHeight( textField.height + 2 );
				}
			}
			else if ( tp == "itemlistappend" || tp == "itemlistmultiple" )
			{
				// ItemList( area-name, [field], [pre], [post], [labelfield] )
				if( pc && args && args.length > 1)
				{
					tfIcon = new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize );
					addChild( tfIcon );
					
					listAppendSeparator = args[0];
					
					var items1:Array = [];
					var area1:String = args[1];
					var pre1:String = "";
					var post1:String = "";
					var labelfield1:String = "name";
					var field1:String = "name";
					
					if( args.length > 2 ) field1 = args[2];
					if( args.length > 3 ) pre1 = args[3];
					if( args.length > 4 ) post1 = args[4];
					if( args.length > 5 ) labelfield1 = args[5];
					
					if( CTTools.pageItems )
					{
						if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
						else pc.uiCmds.push(new UICmd(['#separator']));
						pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
						pc.uiCmds.push(new UICmd(['#separator']));
						
						L = CTTools.pageItems.length;
						for( i=0; i < L; i++)
						{
							if( CTTools.pageItems[i].area == area1 )
							{
								pc.uiCmds.push(new UICmd([CTTools.pageItems[i][labelfield1]],'',setVal,[pre1 + CTTools.pageItems[i][field1] + post1]));
							}
						}
					}
					
					tfIcon.addEventListener( MouseEvent.CLICK, iconListSelect );
					textField.width = textField.width - tfIcon.width;
					setHeight( textField.height + 2 );
				}
			}
			else if( tp == "labellist" )
			{
				if( pc && args && args.length > 0 )
				{
					
					tfIcon = new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize );
					addChild( tfIcon );
					
					if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
					else pc.uiCmds.push(new UICmd(['#separator']));
					pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
					pc.uiCmds.push(new UICmd(['#separator']));
				
					if( args.length > 0)
					{
						L = args.length;
						var ppi2:PopupItem;
						for(i=0; i < L; i+=2)
						{
							s2 = TemplateTools.obj2Text( args[i], "#", propObj, false, false );
							pc.uiCmds.push(new UICmd([s2],'',setVal,[TemplateTools.obj2Text( args[i+1], "#", propObj, false, false )]));
						}
					}
					tfIcon.addEventListener( MouseEvent.CLICK, iconListSelect );
					textField.width = textField.width - tfIcon.width;
				}
				setHeight( textField.height + 2 );
			}
			else if( tp == "labellistmultiple"  || tp == "labellistappend" )
			{
				if( args && args.length > 0 ) {
					
					listAppendSeparator = args[0];
					
					if(!pc.uiCmds ) pc.uiCmds = new Vector.<UICmd>();
					else pc.uiCmds.push(new UICmd(['#separator']));
					pc.uiCmds.push(new UICmd([Language.getKeyword('None')],'',setVal,['']));
					pc.uiCmds.push(new UICmd(['#separator']));
				
					if( args.length > 0)
					{
						L = args.length;
						var ppi3:PopupItem;
						
						for(i=1; i < L; i+=2)
						{
							s2 = TemplateTools.obj2Text( args[i], "#", propObj, false, false );
							pc.uiCmds.push(new UICmd([s2],'',setVal,[TemplateTools.obj2Text( args[i+1], "#", propObj, false, false )]));
						}
					}
					
					tfIcon.addEventListener( MouseEvent.CLICK, iconListSelect );
					textField.width = textField.width - tfIcon.width;
				}
				setHeight( textField.height + 2 );
			}
			else if( tp == "name" )
			{
				if( value == "" )
				{
					value = getUniqueName();
				}
				setHeight( textField.height + 2);
			}
			else if(type=="vectorlink") 
			{
				if( args.length>1 && args[1].toLowerCase() == "none")
				{
					// hidden
					setHeight(1);
					visible = false;
				}
				else
				{
					var tptmp:String = _type;
					setType("vector");
					if( vectorPlusButton ) vectorPlusButton.visible = false;
					if( vectorMinusButton ) vectorMinusButton.visible = false;
					_type = tptmp;
				}
			}
			else if( type == "intern" || type == "hidden" )
			{
				textField.visible = false;
				setHeight(0);
			}
			else
			{
				// String
				setHeight( textField.height + 2);
			}
			
		}
		
		protected function formatVector () :void
		{
			if( vectorTextFields )
			{
				var yp:int = 0;
				var L:int = vectorTextFields.length;
				var tf:InputTextBox;
				
				for(var i:int=0; i<L; i++)
				{
					tf = vectorTextFields[i];
					tf.y = yp;
					yp += tf.cssSizeY;
				}
			}
			
			textField.height = yp;
			textField.alpha = 0;
		
			if( vectorPlusButton )
			{
				vectorPlusButton.y = yp + cssTop;
				vectorContainer.setChildIndex( vectorPlusButton, vectorContainer.numChildren-1);
			}

			if( vectorMinusButton )
			{
				vectorMinusButton.y = yp + cssTop;
				vectorContainer.setChildIndex( vectorMinusButton, vectorContainer.numChildren-2)
			}
		}
		
		public function vectorImageHeightChange ( e:Event ) :void
		{
			setTimeout( function(){
			formatVector();
			setHeight( vectorPlusButton.y + vectorPlusButton.cssSizeY) ;
			dispatchEvent( new Event("heightChange") );
			},0);
		}
		
		public function setCurrVector ( tf:InputTextBox ) :void
		{			
			if( vectorTextFields )
			{
				vectorCurrent = vectorTextFields.indexOf(tf);
			}
		}
		
		private function abortLongClick () :void
		{
			var pc:PropertyCtrl;
			
			if( parent && parent is PropertyCtrl )
			{
				var p:DisplayObjectContainer = parent;
				setTimeout( function() {
				PropertyCtrl( p ).abortLongClick = true;
				}, 0);
			}
		}
		
		public function vectorPlusClick ( e:MouseEvent ) :void
		{
			if( !TemplateEditor.clickScrolling )
			{
				abortLongClick();
				
				if( vectorTextFields && vectorContainer )
				{
					var vecObj:Object = {};
					
					CTTools.cloneTo( propObj, vecObj );
					var vecArgs:Array = [];
					
					if(vectorTextFields.length > 0)
					{
						var L:int=vectorTextFields[0].args.length;
						
						for(var i:int=0; i<L; i++)
						{
							// Not Dynmaic Type Vector
							vecArgs.push( vectorTextFields[0].args[i] );
						}
					}
					
					var tf:VectorTextField = new VectorTextField( vectorType, vecArgs, vecObj, '', cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
					
					tf.rootVector = this;
					if( vectorTextFields.length > 0)
					{
						tf.wrap = vectorTextFields[0].wrap;
					}
					var ev:InputEvent = new InputEvent( this, "add" );
					
					if( vectorCurrent == -1)
					{
						vectorTextFields.push( tf );
						ev.val = vectorTextFields.length;
					}
					else
					{
						vectorTextFields.splice( vectorCurrent, 0, tf );
						ev.val = vectorCurrent;
					}
					dispatchEvent( ev );
					
					setHeight( getHeight() + tf.cssSizeY );
					init();
					
					formatVector();
					
					textEnter();
					
					setTimeout( function () {
						dispatchEvent ( new Event("heightChange") );
						dispatchEvent( new Event("lengthChange") );
					}, 0);
				}
			}
			else
			{
				TemplateEditor.endClickScrolling();
			}
		}
		
		public function vectorMinusClick ( e:MouseEvent ) :void
		{
			if( !TemplateEditor.clickScrolling )
			{
				abortLongClick();
				
				if( vectorTextFields && vectorContainer )
				{
					var tf:VectorTextField;
					
					if( vectorCurrent == -1)
					{
						tf = vectorTextFields.pop();
					}
					else
					{
						tf = vectorTextFields[vectorCurrent];
						vectorTextFields.splice( vectorCurrent,1);
						var ev:InputEvent = new InputEvent( this, "clear" );
						ev.val = vectorCurrent;
						dispatchEvent( ev );
						vectorCurrent=-1;
					}
					
					setHeight( getHeight() - tf.cssSizeY );
					if(vectorContainer.contains( tf )) vectorContainer.removeChild(tf);
					init();
					
					formatVector();
					
					dispatchEvent ( new Event("heightChange") );
					dispatchEvent ( new Event("lengthChange") );
					
					textEnter();
				}
			}
			else
			{
				TemplateEditor.endClickScrolling();
			}
		}
		
		protected function richtTextPPHandler ( e:PopupEvent ) :void
		{
			var curr:PopupItem = e.selectedItem;
			abortLongClick();
			
			if( rtViewCode == true )
			{
				var beginid:int = textField.selectionBeginIndex;
				var endid:int = textField.selectionEndIndex;
				var tp:int;
				
				if( curr.options.overrideVal != undefined )
				{
					historyPush( value );
					
					var tmp:String = textField.text.substring(0, beginid) + curr.options.overrideVal + textField.text.substring( endid );
					value = tmp;
					tp = beginid + curr.options.overrideVal.length;
					textEnter();
					
					stage.focus = textField;
					textField.setSelection( tp, tp );
					
					return ;
				}
				else
				{
					var lb:String = curr.label;
					
					if( textField.text.charCodeAt( endid -1) <= 32 ) endid--;
					
					var i:int;
					var ti:int;
					var tm:String = textField.text;
					var ko:int = -1;
					var ke:int = -1;
					
					if( beginid == endid )
					{
						// Test if cursor is in Markup Code...
						if( beginid > 0 )
						{
							for( i = beginid; i >= 0; i--)
							{
								ti = tm.charCodeAt(i);
								if( ti == 91 ) { // [
									ke = i;
									break;
								}else if( ti == 93 ) {
									// not inside a block...
									ke = -1;
									break;
								}
							}
							if( ke >= 0 )
							{
								for( i=beginid; i<tm.length; i++ )
								{
									ti = tm.charCodeAt(i);
									if( ti == 93 ) { // ]
										ko = i+1;
										break;
									}
								}
							}
						}
						
						if( ke == -1 || ko == -1 )
						{
							// not in markup code..
							// add empty tag..
							historyPush( value );
								
							value = textField.text.substring(0, beginid) + '[' + rtNodeName + ' class="'+lb+'"][/' + rtNodeName + ']'+ textField.text.substring( endid );
							tp = beginid + 11 + rtNodeName.length + lb.length;
							textEnter();
							stage.focus = textField;
							// change cursor...
							textField.setSelection( tp, tp );
							
							return ;
						}
						else
						{
							// inside block..
							
							var te:int = tm.indexOf("class=", ke);
							
							if( te >= 0 && te < ko ) 
							{
								var ko2:int = tm.indexOf('"', te +7);
								
								if( ko2 >= 0 )
								{
									historyPush( value );
									
									value = textField.text.substring(0, ko2) + " " + lb + '"]' + textField.text.substring( ko );
									
									tp = ko2 + lb.length + 1;
									textEnter();
									stage.focus = textField;
									// change cursor...
									textField.setSelection( tp, tp );
									
									return;
								}
							}
						}
					}
					
					if( ke >= 0 && ko >= 0 )
					{
						beginid = ko;
						endid = ke;
					}
					
					historyPush( value );
					
					value = textField.text.substring(0, beginid) + '[' + rtNodeName + ' class="'+lb+'"]' + textField.text.substring( beginid, endid ) + "[/" + rtNodeName + "]" + textField.text.substring( endid );
					
					textEnter();
					tp = beginid + 11 + rtNodeName.length + lb.length + (endid - beginid) + 6;
					stage.focus = textField;
					
					// change cursor...
					textField.setSelection( tp, tp );
				}
			}
			
		
		}
		
		private function showSelectTextError () :void
		{
			var win2:Window = Window( Application.instance.window.InfoWindow( "SelectTextWindow", agf.ui.Language.getKeyword("Select Some Text Error"), Language.getKeyword("Select Some Text First"), {
				complete: function (b:Boolean=false) {},
				continueLabel:Language.getKeyword("OK"),
				allowCancel: false,
				autoWidth:false,
				autoHeight:true
			}, 'select-text-window') );
			Application.instance.windows.addChild( win2 );
		}
		
		protected function nodeStyleHandler (e:MouseEvent) :void
		{
			// Open Styles Editor...
			if( !TemplateEditor.clickScrolling )
			{
				
			}
		}
		
		protected function styleClassHandler (e:MouseEvent) :void
		{
			// Open Class Editor...
			if( !TemplateEditor.clickScrolling )
			{
				
			}
		}
		
		protected function richtTextBtnHandler (e:MouseEvent) :void
		{
			if( !TemplateEditor.clickScrolling )
			{
				var btn:Button = Button(e.currentTarget);
				var lb:String = btn.label;
				var beginid:int = textField.selectionBeginIndex;
				var endid:int = textField.selectionEndIndex;
				var tmp:String;
				var tp:int;
				var s:String;
				
				if(textField.text.charCodeAt( endid -1) <= 32) endid--;
				
				if( btn.options.originalLabel == "Code" )
				{
					rtViewCode = true;
					textField.visible = true;
					htmlTextField.visible = false;
					return;
				}
				else if( btn.options.originalLabel == "Live")
				{
					rtViewCode = false;
					textField.visible = false;
					htmlTextField.visible = true;
					return;
				}
				else if( btn.options.originalLabel == ".Undo")
				{
					
					if( history && history.length > 0 )
					{
						s = historyPop();
						futurePush( value );
						value = s;
						textEnter();
						return;
					}
				}
				else if( btn.options.originalLabel == ".Redo")
				{
					if( future && future.length > 0 )
					{
						s = futurePop();
						historyPush( value );
						value = s;
						textEnter();
						return;
					}
				}
				var nli:int;
				var nl:String;
				var nle:String;
				
				if( btn.options.originalLabel == ".Bold")
				{
					historyPush( value );
					value = textField.text.substring(0, beginid) + '**'+ (beginid >= endid ? "":textField.text.substring( beginid, endid )) + "**" + textField.text.substring( endid );
					tp = beginid + 2 + (endid > beginid ? (endid - beginid) : 0);
					textEnter();
					stage.focus = textField;
					textField.setSelection( tp, tp );
					
				}
				else if( btn.options.originalLabel == ".Italic")
				{
					historyPush( value );
					value = textField.text.substring(0, beginid) + '*'+( beginid >= endid?"":textField.text.substring( beginid, endid )) + "*" + textField.text.substring( endid );
					tp = beginid + 1 + (endid > beginid ? (endid - beginid) : 0);
					textEnter();
					stage.focus = textField;
					textField.setSelection( tp, tp );
					
				}
				else if( btn.options.originalLabel == ".Heading")
				{
					historyPush( value );
					nli = textField.text.charCodeAt(beginid-1);
					
					if( beginid == 0 || nli == 9 || nli == 10 || nli == 13 )
					{
						nl = "";
					}
					else
					{
						nl = "\n";
					}
					
					nli = textField.text.charCodeAt(endid);
					
					if( nli == 9 || nli == 10 || nli == 13 )
					{
						nle = "";
					}
					else
					{
						nle = "\n";
					}
					value = textField.text.substring(0, beginid) +  nl+ '# '+( beginid >= endid?"":textField.text.substring( beginid, endid )) + nle + textField.text.substring( endid );
					tp = beginid + 2 + nl.length + (endid > beginid ? (endid - beginid) + nle.length : 0);
					textEnter();
					stage.focus = textField;
					textField.setSelection( tp, tp );
					
				}
				else if( btn.options.originalLabel == ".List")
				{
					historyPush( value );
					nli = textField.text.charCodeAt(beginid-1);
					if( beginid == 0 || nli == 9 || nli == 10 || nli == 13 )
					{
						nl = "";
					}
					else
					{
						nl = "\n";
					}
					
					nli = textField.text.charCodeAt(endid);
					
					if( nli == 9 || nli == 10 || nli == 13 )
					{
						nle = "";
					}
					else
					{
						nle = "\n";
					}
					value = textField.text.substring(0, beginid) +  nl+ '- '+( beginid >= endid?"":textField.text.substring( beginid, endid )) + nle + textField.text.substring( endid );
					tp = beginid + 2 + nl.length + (endid > beginid ? (endid - beginid) + nle.length : 0);
					textEnter();
					stage.focus = textField;
					textField.setSelection( tp, tp );
					
				}
				else if( btn.options.originalLabel == ".Link") 
				{
					// Get Link Window
					var win:Window = Window( Application.instance.window.GetStringWindow( "LinkWindow", agf.ui.Language.getKeyword("CT-Get-Link"), Language.getKeyword("CT-Get-Link-MSG"), {
					complete: function (str:String) {
						historyPush( value );
						value = textField.text.substring(0, beginid) + '['+( beginid >= endid?"":textField.text.substring( beginid, endid )) +'](' + str + ")" + textField.text.substring( endid );
						tp = beginid + 4 + str.length + (endid > beginid ? (endid - beginid) : 0);
						textEnter();
						stage.focus = textField;
						textField.setSelection( tp, tp );
						
					},
					continueLabel:Language.getKeyword("Set Link"),
					allowCancel: true,
					autoWidth:false,
					autoHeight:true,
					cancelLabel: Language.getKeyword("Cancel")
					}, 'link-window') );
					
					Application.instance.windows.addChild( win );
					return;
				}
			}
		}
		
		protected function boolButtonDoubleClickHandler ( e:MouseEvent ) :void
		{
			if( !TemplateEditor.clickScrolling ) 
			{
				textField.removeEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				tfBtn.removeEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				
				textField.addEventListener( FocusEvent.FOCUS_OUT, onBoolDeactivate );
				
				textField.type = TextFieldType.INPUT;
				textField.setSelection( 0, textField.text.length );
				onActivate(null);
			}
			else
			{
				TemplateEditor.endClickScrolling();
			}
		}
		
		protected function boolButtonDoubleClickAbort () :void
		{
			if( !TemplateEditor.clickScrolling )
			{
				textField.removeEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				tfBtn.removeEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				
				boolValue = tmp_bool_value;
				textEnter();
			}
			else
			{
				TemplateEditor.endClickScrolling();
			}
		}
		
		protected function boolButtonHandler ( e:MouseEvent ) :void
		{
			if( !TemplateEditor.clickScrolling )
			{
				var v:String = value;
				
				if( v == boolNo)
				{
					tmp_bool_value = true;
				}
				else
				{
					tmp_bool_value = false;
				}
				
				textField.addEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				tfBtn.addEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				
				setTimeout( boolButtonDoubleClickAbort, 353 );
			}
			else
			{
				TemplateEditor.endClickScrolling();
			}
		}
		
		public function boolIcon (v:Boolean) :void
		{
			tfBtn.clips = [ new IconFromFile(  (v ? Options.iconDir + CTOptions.urlSeparator + "toggle-on-btn.png" : Options.iconDir + CTOptions.urlSeparator + "toggle-off-btn.png"), Options.btnSize, Options.btnSize) ];
			tfBtn.init();
		}
		
		public function set boolValue (v:Boolean) :void
		{
			_boolValue = v;
			boolIcon(v);
			value = _boolValue ? boolYes : boolNo;
		}
		
		public function get boolValue ():Boolean
		{
			return _boolValue;
		}
		
		public static var blocker:Sprite;
		
		private function blockHandler (e:MouseEvent) :void
		{
			if( colorPicker )
			{
				colorPicker.removeCP();
			}
		}
		
		protected function onSelectColor ( e:MouseEvent ) :void
		{
			var tc:CssSprite = Application.instance.topContent
			var panel:CssSprite = Application.instance.view.panel;
			if( tc )
			{
				var cp:ColorPicker = ColorPicker(tc.getChildByName("color_picker"));
				if( cp )
				{
					tc.removeChild(cp);
					textEnter();
					return;
				}
				var pw:int = panel.cssSizeX/*getWidth()*/ * TemplateTools.editor_w;
				
				if( HtmlEditor.isPreviewOpen && !CTOptions.previewAtBottom ) {
					pw = HtmlEditor.previewX;
				}
				
				var mmh:int = Application.instance.mainMenu.cssSizeY + 2;
				
				if( blocker == null ) blocker = new Sprite();
				blocker.graphics.clear();
				blocker.graphics.beginFill( 0x0,0);
				blocker.graphics.drawRect( 0,0, tc.getWidth(), tc.getHeight() );
				blocker.graphics.endFill();
				blocker.addEventListener( MouseEvent.MOUSE_DOWN, blockHandler );
				if( ! tc.contains( blocker) ) tc.addChild( blocker );
				
				// hardcode padding: 16px
				colorPicker = new ColorPicker( pw, (panel.cssSizeY/*getHeight()*/ * TemplateTools.editor_h) - mmh, tc, styleSheet, '', 'editor input-color-picker', false);
				
				colorPicker.name = "color_picker";
				colorPicker.setLabel( labelText );
				
				if( displayMode == "rgba" || displayMode == "hsla" )
				{
					colorPicker.color32 = _color;
				}
				else
				{
					colorPicker.color = _color;
				}
				
				colorPicker.x = 0;
				colorPicker.y = mmh;
				
				if( CTOptions.animateBackground )
				{
					HtmlEditor.dayColorClip( colorPicker.bgSprite );
					colorPicker.bgSprite.width  = pw + 16;
				}
				
				colorPicker.target = this;
				colorPicker.targetName = "setColorValue";
			}
		}
		
		public function onRemoveCP () :void
		{
			if( blocker )
			{
				var tc:CssSprite = Application.instance.topContent
				if( tc && tc.contains( blocker ) ) tc.removeChild( blocker );
			}
		}
		
		public function setColorValue ( c:uint ) :void
		{
			colorValue = c;
			drawCurrentColor();
			textEnter();
		}
			
		protected function sliderBegin ( e:Event ) :void
		{
			abortLongClick();
			
			if( _supertype == "screennumber" || _supertype == "screeninteger" )
			{
				var s:String = textField.text;
				var c:int=s.length;
				for(var i:int=c-1; i>=0; i--)
				{
					if( !isNaN(Number(s.charAt(i))) )
					{
						c = i;
						break;
					}
				}
				
				if( c != s.length )
				{
					var num:String = s.substring( 0, c );
					var unit:String = s.substring( c+1 );
					StringMath.distFormat = unit;
				}
			}
			activateValue = textField.text;
		}
		
		protected function sliderChange ( e:Event ) :void
		{
			if( TemplateEditor.clickScrolling )
			{
				TemplateEditor.abortClickScrolling();
			}
			
			if( tfSlider )
			{
				var gr:Number;
				if( _supertype == "screennumber" || _supertype == "screeninteger" )
				{
					if( sliderGrid != 0 )
					{
						gr = sliderGrid;
						textField.text = "" + (Math.round( (_type=="integer" ? Math.round( StringMath.forceNumber( String(tfSlider.value))) : StringMath.forceNumber( String(tfSlider.value) )) / gr ) * gr).toFixed(decPlaces) + StringMath.distFormat;
					}
					else
					{
						textField.text = "" + ( _type == "integer" ? Math.round( StringMath.forceNumber(String(tfSlider.value)) ) : StringMath.forceNumber(String(tfSlider.value)) ) + StringMath.distFormat;
					}
				}
				else
				{
					if( sliderGrid != 0 )
					{
						gr = sliderGrid;
						textField.text = "" + (Math.round( (_type=="integer" ? Math.round(tfSlider.value) : tfSlider.value) / gr ) * gr).toFixed(decPlaces);
					}
					else
					{
						textField.text = "" + ( _type == "integer" ? Math.round( tfSlider.value ) : tfSlider.value);
					}
				}
			}
		}
		
		protected function sliderUp ( e:MouseEvent ) :void
		{
			if( tfSlider )
			{
				sliderChange(null);
				textEnter(); 
			}
		}
		
		protected function ppListSelect ( e:PopupEvent ) :void
		{
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			value = lb;
			textEnter();
		}
		protected function iconListSelect ( e:MouseEvent ) :void
		{
			var pc:PropertyCtrl = PropertyCtrl( parent );
			
			if ( pc )
			{
				pc.abortLongClick = true;
				pc.showOptions();
			}
		}
		
		public function convertNumberTo ( lb:String ) :void
		{			
			var val:Number = StringMath.forceNumber( textField.text );
			var s:String = textField.text;
			var a:int;
			var ez:int = s.length;
			var num:String  = "";
			
			for(var i:int =0; i<s.length; i++)
			{
				// 0 - 9 || . 
				a = s.charCodeAt(i);
				
				if(a >= 40 && a <= 57 || a==69)
				{
					num += s.charAt(i);
				}
				else
				{
					ez = i;
					break;
				}
			}
			
			num = CssUtils.trim(num);
			var unit:String = CssUtils.trim( s.substring(ez) );
			
			if( unit == "%" && (lb == "vh" || lb == "vw") )
			{
				num = String( Number(num) );
			}
			else if( (unit == "vh" || unit == "vw") && lb == "%" ) 
			{
				num = String( Number(num) );
			}
			else if( unit == "px" && (lb == "rem" || lb == "em"))
			{
				num = String( Number(num)/16 );
			}
			else if( ( unit == "em" || unit == "rem" ) && lb == "px")
			{
				num = String( Number(num)*16 );
			}
			
			activateValue = "";
			
			value = "" + num + lb;
			
			if(tfSlider && !isNaN(Number(num)))
			{
				tfSlider.value = Number(num);
			}
			textEnter();
		}
		
		public function setTyped ( tp:String ) :void
		{
			tfPopup.label = tp;
			setWidth(getWidth());
			textEnter();
		}
		
		protected function ppTypedSelect ( e:PopupEvent ) :void
		{
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			
			tfPopup.label = lb;
			
			setWidth(getWidth());
			textEnter();
		}
		
		protected function ppLabelListSelect ( e:PopupEvent ) :void
		{
			var curr:PopupItem = e.selectedItem;
			
			if( Application.instance.shortcutMgr.shiftDown )
			{
				value += listAppendSeparator +  curr.options.labelValue;
			}
			else
			{
				value =  curr.options.labelValue;
			}
			textEnter();
		}
		
		protected function listAppend ( lb:String ) :void
		{
			if ( lb == "" )
			{
				value = "";
				return;
			}
			
			if( _supertype == "listmultiple" || _supertype == "labellistmultiple" || _supertype == "itemlistmultiple" )
			{
				if( Application.instance.shortcutMgr.shiftDown )
				{
					// force add
					value += listAppendSeparator + lb;
				}
				else
				{
					
					var v:String = value;
					var st:int = v.indexOf( lb );
						
					if( st >= 0 )
					{
						// remove
						value = CssUtils.trim( v.substring(0, st) + v.substring( st + lb.length ) );
						
						if( value == "" ) 
						{
							activateValue = " ";
						}
					}
					else
					{
						
						var id:int = args.indexOf( lb );
						var i:int;
						var s1:int = -1;
						var s2:int = args.indexOf( "#separator", id );
						
						if( s2 >= 0 )
						{
							s1 = args.lastIndexOf( "#separator", s2-1 );
						}
						else
						{
							s1 = args.lastIndexOf( "#separator", id-1 );
							if( s1 >= 0 )
							{
								s2 = args.length;
							}
						}
						
						if( s1 < 0 )
						{
							if ( s2 >= 0 )
							{
								// Group: 0 - s2
								s1 = 0;
							}
						}
						
						if( s1 >= 0 && s2 >= 0 ) 
						{
							// only one value from a group
							var values:Array = v.split(listAppendSeparator);
							var L:int = values.length;
							var aid:int;
							var spl:int=-1;
							
							for(i=L-1; i>=0; i--)
							{
								aid = args.indexOf( values[i] );
								
								if( aid > s1 && aid < s2 )
								{
									values.splice(i, 1);
									spl = i;
								}
								if( values[i] == "" ) values.splice(i,1);
							}
							if( spl == -1 ) values.push(lb);
							else values.splice(spl,0,lb);
							
							if( values.length == 0 )
							{
								activateValue = " ";
								value = "";
							}
							else if( values.length == 1 )
							{
								value = values[0];
							}
							else
							{
								value = values.join(listAppendSeparator);
							}
							
						}
						else
						{
							// no groups
							if( v == "" )
							{
								value = lb;
							}
							else
							{
								value += listAppendSeparator + lb;
							}
						}
					}
				}
			}
			else
			{
				value += listAppendSeparator + lb;
			}
			
			textEnter();
		}
		protected function ppListAppendSelect ( e:PopupEvent ) :void
		{
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			
			if( _supertype == "listmultiple" || _supertype == "labellistmultiple" || _supertype == "itemlistmultiple" )
			{
				if (  _type != "listmultiple" )
				{
					lb = curr.options.labelValue;
				}
			
				listAppend( lb );
			}
		}
		
		public static var heightDirty:Boolean = false;
		
		public override function setWidth ( w:int ) :void
		{
			super.setWidth(w -cssBoxX);
			
			if(rtItemList)
			{
				if( rtItemList.vert )
				{
					rtItemList.x = w - (rtItemList.width + rtItemList.cssBoxX + 8);
				}
				else
				{
					rtItemList.x = cssLeft;
					rtItemList.y = -rtItemList.height;
				}
				var H:int = textField.height;
				
				if( _supertype == "richtext" || _supertype == "text" || _supertype == "code" )
				{
					textField.autoSize = TextFieldAutoSize.LEFT;
				}
				
				textField.width = w - ( textField.x + rtItemList.width + 8 );
				
				if( _supertype == "richtext" || _supertype == "text" || _supertype == "code" )
				{
					H = textField.height;
					textField.autoSize = TextFieldAutoSize.NONE;
					setHeight( H + 8 );
					heightDirty = true;
					
					if ( htmlTextField )
					{
						htmlTextField.width = textField.width;
					}
				}
			}
			else
			{
				if( tfBtn )
				{
					textField.width = w - tfBtn.cssSizeX;
					tfBtn.x =  w - tfBtn.cssSizeX;
				}
				else if( tfPopup )
				{
					textField.width = w - tfPopup.cssSizeX
					tfPopup.x = w - tfPopup.cssSizeX;
				}
				else if( tfIcon )
				{
					textField.width = w - tfIcon.width
					tfIcon.x = w - (tfIcon.width + int(Options.iconSize * 0.5));
				}
				else if( colorClip )
				{
					textField.width = w-(colorClip.width );
					colorClip.x =  w - colorClip.width;
				}
				else
				{
					textField.width = w;
				}
				
				if( mediaContainer && mediaInfo && mediaInfo.length > 0 )
				{
					var fmt:TextFormat = mediaInfo.getTextFormat( 0, 1 );
					
					if( fmt && fmt.align == "right" )
					{
						mediaInfo.x = w - (mediaInfo.width + mediaContainer.x + 8 );
					}
				}
			}
			var i:int;
			var L:int;
			
			if( itemList )
			{
				if(itemList.items)
				{
					var ppw:int = 0;
					
					if( rtItemList )
					{
						ppw = 8 + Options.btnSize;
					}
					
					L = itemList.items.length;
					
					for( i=0; i < L; i++)
					{
						itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + cssBoxX + ppw + 2) );
					}
				}
				
				itemList.setWidth(0);
				itemList.init();
			}
			
			if( multiSelectMenu )
			{
				multiSelectMenu.setWidth( w - (multiSelectMenu.cssBoxX) );
			}
			
			if( vectorTextFields )
			{
				L = vectorTextFields.length;
				
				for( i=0; i<L; i++)
				{
					vectorTextFields[i].setWidth( w );
				}
				
				if( vectorPlusButton && vectorMinusButton )
				{
					vectorPlusButton.x = w - vectorPlusButton.cssSizeX-2;
					vectorMinusButton.x = vectorPlusButton.x - (vectorMinusButton.cssSizeX + 2);
				}
			}
			
			if( plugin )
			{
				plugin.setWidth( w );
			}
			
			if( tfSlider )
			{
				tfSlider.setHeight( w ); 
			}
		}
		
		public override function setHeight ( h:int ) :void
		{
			if( rtItemList )
			{
				if( h < rtItemList.height ) h = rtItemList.height;
			}
			super.setHeight( h );
			
			if(_supertype=="image")
			{
				if( mediaContainer )
				{
					mediaContainer.y = cssTop;
					textField.y = cssTop + mediaContainer.height + 2;
				}
				else
				{
					textField.y = cssTop;
				}
				
				if( mediaInfo && mediaInfo.length > 0 && tfBtn ) {
					mediaInfo.y = tfBtn.y + tfBtn.cssSizeY;
				}
			}
			else
			{
				textField.y = cssTop;
				textField.height = h;
			}
			
			if ( tfIcon )
			{
				tfIcon.y = int( (Options.btnSize - textField.height) * 0.5 );
			}
			
			if( htmlTextField ) 				
			{
				htmlTextField.height = textField.height;
			}
			
			var sld:int=2;
			
			if(tfSlider)
			{
				tfSlider.y = textField.height + textField.y + 5;
			}
		}
		
		public function get value () :String
		{
			return textField ? textField.text : "";
		}
		
		public function set value ( v:String ) :void
		{			
			textField.text = v || "";
			
			if ( _supertype == "boolean" && tfBtn)
			{
				boolIcon( v == boolYes || CssUtils.stringToBool(v) );
			}
			
			if( tfSlider )
			{
				if( _supertype == "number" ) 
					tfSlider.value = Number( v );
				else if( _supertype == "integer" ) 
					tfSlider.value = Math.round( Number(v) );
			}
		}
		
		private function textChange (e:Event) :void
		{
			if( _supertype == "richtext" || _supertype == "text" || _supertype == "code" )
			{
				historyPush( textField.text );
			}
		}
		private var colorOfs:int=0;
		
		private function drawCurrentColor () :void
		{
			if( colorClip ) 
			{
				// simulate padding-right:
				var ofs:int = colorOfs;
				colorClip.graphics.beginFill( 0, 0 );
				colorClip.graphics.drawRect(0, 0, Options.btnSize+ofs, cssSizeY - (4*CssUtils.numericScale) /* textField.height*/ );
				colorClip.graphics.endFill();
				
				colorClip.graphics.beginFill( this._color, 1 );
				colorClip.graphics.drawRect(0, 0, Options.btnSize, cssSizeY- (4*CssUtils.numericScale)/*textField.height */);
				colorClip.graphics.endFill();
			}
		}
		
		public function textEnter () :void
		{
			if( _type == "plugin" && superType != "" )
			{
				_type = superType;
				textEnter();
				return;
			}
			
			var v:String = value;
			if( trimValue ) v = CssUtils.trim(v);	
			if( trimQuotesValue ) v = CssUtils.trimQuotes(v);
			
			if( _type == "number" || _type=="screennumber" )
			{
				value = "" + StringMath.evaluate( v, decPlaces, _type == "screennumber" );
			}
			else if( _type == "integer" || _type=="screeninteger" )
			{
				value = "" + StringMath.evaluate( v, 1, _type == "screeninteger" );
			}
			else if( _type == "image" )
			{
				setTimeout( reloadImage, 250 );
			}
			else if( _type == "color" )
			{
				colorValue = v;
				drawCurrentColor();
			}
			else if( _type == "boolean" )
			{
				boolValue = v == boolYes || v == "1" || v.toLowerCase() == "true" ? true : false;
				textField.text = boolValue ? boolYes : boolNo;
			}
			else if( _type == "name" )
			{
				value = parseName(v);
			}
			else if( (_type == "vector" || _type == "vectorlink") && vectorTextFields)
			{
				if( vectorTextFields.length > 0 )
				{
					var str:String = "";
					var L:int = vectorTextFields.length;
					var vt:VectorTextField;
					
					for( var i:int = 0; i < L; i++)
					{
						vt = vectorTextFields[i];
						
						if( vt.type == "number" || vt.type=="screennumber" )
						{
							str += vectorSeparator + StringMath.evaluate( vt.value, 4, vt.type == "screennumber" );
						}
						else if( vt.type == "integer" || vt.type=="screeninteger" )
						{
							str += vectorSeparator + StringMath.evaluate( vt.value, 1, vt.type == "screeninteger" );
						}
						else if( vt.type == "typed" )
						{
							str += vectorSeparator + vt.tfPopup.label + ":" + vt.value;
						}
						else
						{
							str += vectorSeparator + vt.value;
						}
					}
					
					textField.text = str.substring(1);
					if( textField.text == vectorSeparator ) textField.text = "";
				}
				else
				{
					textField.text = "";
				}
			}
			
			if( value != activateValue )
			{
				if( _type == "plugin" )
				{
					plugin.setText( value );
				}
				dispatchEvent( new Event(ENTER, false, true) );
			}
		}
		
		public function set colorValue (t:*) :void
		{			
			if( t is String )
			{
				if( t.charAt(0) == "#" )
				{
					displayMode = "hex";
				}
				else if( t == "none" || t == "currentcolor" || t == "inherit"|| t.indexOf("gradient") >= 0  || t.indexOf("url(") >= 0 )
				{
					return;
				}
				else if( t.indexOf("rgba") >= 0  )
				{
					displayMode = "rgba";
				}
				else if( t.indexOf("rgb") >= 0  )
				{
					displayMode = "rgb";
				}
				else if( t.indexOf("hsla") >= 0  )
				{
					displayMode = "hsla";
				}
				else if( t.indexOf("hsl") >= 0  )
				{
					displayMode = "hsl";
				}
				else if( t.length > 2 && t.charAt(1) == "x" )
				{
					t = t.substring(1);
					displayMode = "hex";
				}
				_color = CssUtils.stringToColor(t);
			}
			else
			{
				_color = uint(t);
			}      
			
			var r:int = _color >> 16 & 255;
			var g:int = _color >> 8 & 255;
			var b:int = _color & 255;
			var a:int = 0;
			
			if(displayMode == "hex")
			{
				var r16:String = r.toString(16);
				var g16:String = g.toString(16);
				var b16:String = b.toString(16);
				
				if(r16.length == 1) r16 = "0" + r16;
				if(g16.length == 1) g16 = "0" + g16;
				if(b16.length == 1) b16 = "0" + b16;
			
				if( r16.charAt(0) == r16.charAt(1) &&  g16.charAt(0) == g16.charAt(1) &&  b16.charAt(0) == b16.charAt(1) ) {
					// Prefer short version
					value = "#" + r16.charAt(0).toUpperCase() + g16.charAt(0).toUpperCase() + b16.charAt(0).toUpperCase();
				}else{
					value = "#" + r16.toUpperCase() + g16.toUpperCase() + b16.toUpperCase();
				}
			}
			else if(displayMode == "hsla")
			{
				var hsb:Object = ColorUtils.RGBtoHSV( r, g, b );
				a = _color >> 24 & 255;
				value = "hsla(" + hsb.h + "," + hsb.s + "%," + hsb.v + "%," + (Math.round((a/255)*100)/100) + ")";
			}
			else if(displayMode == "hsl")
			{
				var hsb2:Object = ColorUtils.RGBtoHSV( r, g, b );
				value = "hsl(" + hsb2.h + "," + hsb2.s + "%," + hsb2.v + "%)";
			}
			else if( displayMode == "rgba" )
			{
				a = _color >> 24 & 255;
				value = "rgba(" + r+ "," + g + "," + b + "," + (Math.round((a/255)*100)/100)  + ")";
			}
			else
			{
				value = "rgb(" + r+ "," + g + "," + b + ")";
			}
		}
		
		public function get color () :int
		{
			return _color;
		}
		
		private function enterListener ( e:KeyboardEvent ) :void
		{
			if( !CTOptions.isMobile )
			{
				if ( e.charCode == 13 )
				{
					if( stage && stage.focus )
					{
						stage.focus = null; // call onDeactivate..
					}
				}
			}
		}
	
		protected function tfDown (event:MouseEvent) :void
		{
			setTimeout(TemplateEditor.abortClickScrolling, 0);
		}
		
		protected function onActivate (e:Event) :void
		{
			if( textField )
			{
				addEventListener( MouseEvent.MOUSE_DOWN, tfDown );
				
				if( _supertype == "screennumber" || _supertype == "screeninteger" )
				{
					var s:String = textField.text;
					var c:int=s.length;
					for(var i:int=c-1; i>=0; i--)
					{
						if( !isNaN(Number(s.charAt(i))) )
						{
							c = i;
							break;
						}
					}
					if( c != s.length )
					{
						var num:String = s.substring( 0, c );
						var unit:String = s.substring( c+1 );
						StringMath.distFormat = unit;
					}
				}
			
				fmt = styleSheet.getTextFormat( stylesArray, "active"  );
				activateValue = value;
				
				textField.setTextFormat( fmt );
				
				if( stage && _supertype != "richtext" &&  _supertype != "text" && _supertype != "code" )
				{
					stage.addEventListener( KeyboardEvent.KEY_DOWN, enterListener);
				}
				if(this is VectorTextField)
				{
					VectorTextField(this).rootVector.setCurrVector(this);
				}
				swapState( "active" );
			}
			setTimeout( TemplateEditor.abortClickScrolling, 0);
			
		}
		
		protected function onBoolDeactivate (e:Event) :void
		{
			textField.removeEventListener( FocusEvent.FOCUS_OUT, onBoolDeactivate );
			onDeactivate( null );
		}
		
		protected function onDeactivate (e:Event) :void 
		{
			textEnter();
			
			if( textField )
			{
				removeEventListener( MouseEvent.MOUSE_DOWN, tfDown );
				fmt = styleSheet.getTextFormat( stylesArray, "normal");
				textField.setTextFormat( fmt );
				if( stage )
				{
					if(_supertype != "richtext" && _supertype != "text" && _supertype != "code" )
					{
						stage.removeEventListener( KeyboardEvent.KEY_DOWN, enterListener);
					}
				}
				if( this is VectorTextField )
				{
					var vt:VectorTextField = VectorTextField(this);
					setTimeout( function () {
						vt.rootVector.vectorCurrent = -1;
					}, 125);
				}
				swapState( "normal" );
			}
		}
		
		private function selectDirectory (e:MouseEvent) :void
		{
			var directory:File;
			if( lastSelectedFiles[this.name] != null ) directory = new File( lastSelectedFiles[this.name] );
			else if( lastSelectedFiles["_lastdir"] != null ) directory = new File( lastSelectedFiles["_lastdir"] );
			else directory = File.documentsDirectory;
			
			try {	
				directory.browseForDirectory("Select Directory");
				directory.addEventListener(Event.SELECT, dirSelected);
			}catch (error:Error){
				
			}
		}
		
		private function dirSelected (event:Event) :void
		{
			var directory:File = event.target as File;
			lastSelectedFiles[this.name] = directory.url;
			lastSelectedFiles["_lastdir"] = directory.url;
			textField.text = directory.url;
			textEnter();
		}
		
		private function selectFile (e:MouseEvent=null) :void
		{
			if( ! TemplateEditor.clickScrolling )
			{
				// Get Files from User
				var docsDir:File;
				
				if( lastSelectedFiles[this.name] != null ) docsDir = new File( lastSelectedFiles[this.name] );
				else if( lastSelectedFiles["_lastdir"] != null ) docsDir = new File( lastSelectedFiles["_lastdir"] );
				else docsDir = File.documentsDirectory;
				
				var flt:FileFilter = null;
				if( allowed_extensions )
				{
					flt = new FileFilter( Language.getKeyword(fileFilterDescription), allowed_extensions );
				}
				else
				{
					flt = new FileFilter( Language.getKeyword(fileFilterDescription), "*.*");
				}
				
				try {
					docsDir.browseForOpen("Select File", [flt]);
					docsDir.addEventListener(Event.SELECT, fileSelected);
				}catch (error:Error){
					Console.log("Select File Error: " + error.message);
				}
			}
		}
		
		private function selectNone (e:MouseEvent=null) :void {
			value = "none";
		}
		
		private function selectFiles (e:MouseEvent=null) :void
		{
			if( ! TemplateEditor.clickScrolling )
			{
				var docsDir:File;
				if( lastSelectedFiles[this.name] != null ) docsDir = new File( lastSelectedFiles[this.name] );
				if( lastSelectedFiles["_lastdir"] != null ) docsDir = new File( lastSelectedFiles["_lastdir"] );
				else docsDir = File.documentsDirectory;
				
				var flt:FileFilter = null;
				if( allowed_extensions )
				{
					flt = new FileFilter( Language.getKeyword(fileFilterDescription), allowed_extensions );
				}
				else
				{
					flt = new FileFilter( Language.getKeyword(fileFilterDescription), "*.*");
				}
				
				try {
					docsDir.browseForOpenMultiple("Select Files", [flt]);
					docsDir.addEventListener(FileListEvent.SELECT_MULTIPLE, filesSelected);
				}catch (error:Error){
					Console.log("Select Files Error: " + error.message);
				}
			}
		}
		
		// File browser handler
		private function fileSelected (event:Event) :void
		{
			var str:String = File(event.target).url;
			
			textField.text = str;
			lastSelectedFiles[this.name] = str;
			lastSelectedFiles["_lastdir"] = lastSelectedFiles[this.name];
			
			activateValue = " ";
			textEnter();
		}
		
		// File browser handler
		private function filesSelected (event:FileListEvent) :void
		{
			var str:String = event.files[0].url;
			
			lastSelectedFiles[this.name] = event.files[0].parent.url;
			lastSelectedFiles["_lastdir"] = lastSelectedFiles[this.name];
			var i:uint;
			
			if( this is VectorTextField )
			{
				var vt:VectorTextField = VectorTextField(this);
				
				if( vt )
				{
					var vcurr:int = 0;
					
					for ( i = 0; i < vt.rootVector.vectorTextFields.length; i++ )
					{
						if ( vt.rootVector.vectorTextFields[i] == this )
						{
							vcurr = i;
							break;
						}
					}
					
					vt.rootVector.vectorTextFields[vcurr].textField.text = str;
					
					if ( event.files.length > 1 )
					{
						for (i = 1; i < event.files.length; i++)
						{
							if( vt.rootVector.vectorTextFields && vt.rootVector.vectorTextFields.length > i + vcurr )
							{
								vt.rootVector.vectorTextFields[i+vcurr].textField.text = event.files[i].url;
								vt.rootVector.vectorTextFields[i].reloadImage();
							}
						}
					}
					
					vt.rootVector.activateValue = " ";
					vt.rootVector.textEnter();
					setType( _type );
				}
			}
			else
			{
				if( event.files.length > 1 )
				{
					for (i = 1; i < event.files.length; i++)
					{
						str += "," + event.files[i].url;
					}
				}
				
				activateValue = " ";
				textField.text = str;
				textEnter();
			}
		}
		
		public function reloadImage () :void
		{
			if( _supertype == "image")
			{
				if( mediaContainer)
				{ 
					if( mediaInfo && mediaContainer.contains(mediaInfo) ) mediaContainer.removeChild( mediaInfo );
					if(contains(mediaContainer)) removeChild( mediaContainer );
					mediaContainer = null;
				}
				var v:String = textField.text;
				
				setHeight( textField.textHeight + 4);
				
				dispatchEvent( new Event("heightChange") );
				
				if( v != "" && v.toLowerCase() != "none")
				{
					mediaContainer = new Sprite();
					addChild(mediaContainer);
					loadImage( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + v );
				}
			}
		}
		
		private function initDragNDrop ( tgt:InteractiveObject ) :void
		{
			_tgt = tgt;
			_tgt.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,_onDragIn);
			_tgt.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT,_onDragOut);
			_tgt.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,_onDrop);
		}
 		
		public function _onDragIn(event:NativeDragEvent) :void
		{
			NativeDragManager.acceptDragDrop(_tgt);
			swapState("active");
		}
		
		public function _onDragOut(event:Event) :void
		{
			NativeDragManager.acceptDragDrop(_tgt);
			swapState("normal");
		}
		public function _onDrop(event:NativeDragEvent) :void
		{
			NativeDragManager.dropAction = NativeDragActions.COPY;
			var dropfiles:Array = event.clipboard.formats;
			var df:Array;
			for each (var tp:String in dropfiles)
			{
				if( tp == ClipboardFormats.FILE_LIST_FORMAT )
				{
					df = event.clipboard.getData(tp) as Array;
					var path:String;
					for(var i:int = 0; i < df.length; i++)
					{
						 textField.text = File(df[i]).url;
						 lastSelectedFiles[this.name] = File(df[i]).parent.url;
						 lastSelectedFiles["_lastdir"] = lastSelectedFiles[this.name];
						
						 if( _supertype == "image")
							{
							reloadImage();
						 }
						 textEnter();
						 return;
					 }
				 }
			}
		}
		
		protected override function showMultiSelectMenu () :void
		{
			super.showMultiSelectMenu();
			multiSelectMenu.y = -multiSelectMenu.cssSizeY;
		}
		
		public override function displayInsertForm ( tmpl:Template, isUpdateForm:Boolean = false, subform:Boolean = false, inlineArea:String = "", _areaItems:Array = null,
													cat:String="", ltscroll:Number=0, gotoDirection:int=1, forceLevel:Boolean = false) :void
		{
			try {
				if( Application.instance.view.panel.src.editor.currentEditor is ConstantsEditor )
				{
					Application.instance.view.panel.src.editor.currentEditor.displayInsertForm ( tmpl, isUpdateForm, true, areaName, areaItems, cat, ltscroll, gotoDirection, forceLevel );
				}
				else if( Application.instance.view.panel.src.editor.currentEditor is AreaEditor )
				{
					Application.instance.view.panel.src.editor.currentEditor.updateItem = updateItem;
					Application.instance.view.panel.src.editor.currentEditor.displayInsertForm ( tmpl, isUpdateForm, true, areaName, areaItems, cat, ltscroll, gotoDirection, forceLevel );
				}
			}catch(e:Error) {
				Console.log("Error NO-AreaEditor or ConstantsEditor: " + e );
			}
		}
		
		protected function ppNewAreaItem (e:PopupEvent) :void 
		{
			var curr:PopupItem = e.selectedItem;
			var rawName:String = curr.options.templateID;
			var T:Template = CTTools.findTemplate( rawName, "name" );
			
			if(T)
			{
				displayInsertForm( T, false, true, areaName, null, '', 0, 4 );
			}
			else
			{
				Console.log("No Template Found For: " + rawName);
			}
		}
		
		protected override function areaItemDown (e:MouseEvent) :void
		{
			_subform = true;
			_inlineArea = areaName;
			super.areaItemDown(e);
		}
		
		protected override function dragItemUp (e:MouseEvent) :void
		{
			super.dragItemUp(e);
		}
		
		public override function showAreaItems () :void
		{			
			if( CTTools.subTemplates )
			{
				// Inline Area for AreaProcessor
				if( !currentArea )
				{
					currentArea = new Area( 0,0,[],0, areaName );
				}
				if( rtItemList && contains( rtItemList )) removeChild( rtItemList );
				if( itemList && contains( itemList )) removeChild( itemList );
				
				rtItemList = new ItemList(0,0,this,this.styleSheet,'','richtext-btn-list', false);
				
				var pp:Popup = new Popup( [ new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "plus.png", Options.iconSize, Options.iconSize) ], btWidth, textField.height - 1, rtItemList, styleSheet, '', 'richtext-popup', false);
				pp.setHeight( Options.iconSize );
				
				
				var i:int;
				var k:int;
				var L2:int;
				var L:int = CTTools.subTemplates.length;
				var ppi:PopupItem;
				var nam:String;
				var id:String;
				var hash:Object = {};
				
				if( areaType == "all" )
				{
					// Show all subtemplates
					for(i=0; i<L; i++) 
					{
						T = CTTools.subTemplates[i];
						if ( T.hidden ) continue;
						if( areaSubTemplateFilter != "" )
						{
							if( T.name != areaSubTemplateFilter ) continue;
						}
						ppi = pp.rootNode.addItem( [ new IconFromFile( CTTools.parseFilePath( T.listicon ) || (Options.iconDir + CTOptions.urlSeparator + "create.png"), Options.iconSize, Options.iconSize),Language.getKeyword( T.name )], styleSheet);
						ppi.options.templateID = T.name;
					}
				}
				else
				{
					// currentTypes = currentArea.types.join(",");
					var types:Array = areaType.split(",");
					
					// Show subtemplates of type in types array of area
					for(i=0; i<L; i++)
					{
						T = CTTools.subTemplates[i];
						if( T.hidden ) continue;
						nam = T.name;
						id = T.relativePath + nam;
						
						if( types.indexOf( T.type ) >= 0 ) 
						{
							// Test multiple area types
							if( !hash[id] )
							{ 
								hash[id] = true;
								ppi = pp.rootNode.addItem( [ new IconFromFile( CTTools.parseFilePath( T.listicon ) || (Options.iconDir + CTOptions.urlSeparator + "create.png"), Options.iconSize, Options.iconSize),Language.getKeyword( T.name )], styleSheet);
								ppi.options.templateID = T.name;
							}
						}
						else
						{
							// Test multiple types of subtemplate (set in config.xml of subtemplate)
							L2 = T.types.length; 
							if( L2 > 1 )
							{
								for (k=1; k<L2; k++ )
								{
									if( types.indexOf(T.types[k] ) >= 0 )
									{
										if( !hash[ id ] )
										{ 
											hash[ id ] = true;
											ppi = pp.rootNode.addItem( [ new IconFromFile( CTTools.parseFilePath( T.listicon ) || (Options.iconDir + CTOptions.urlSeparator + "create.png"), Options.iconSize, Options.iconSize),Language.getKeyword( T.name )], styleSheet);
											ppi.options.templateID = T.name;
										}
										break;
									}
								}
							}
						}
					} // for subtemplates
				}
				
				pp.addEventListener( Event.SELECT, ppNewAreaItem );
				pp.alignV = "current";
				pp.alignH = "right";
				
				itemList = new ItemList(0, 0, this, styleSheet, '', 'area-container', false);
				itemList.margin = 1;
				
				L = CTTools.pageItems.length;
				
				var r:Object;
				areaItems = [];
				
				for(i=0; i<L; i++)
				{
					r = CTTools.pageItems[i];
					if( r && r.area && r.area == areaName ) areaItems.push(r);
				}
				areaItems.sortOn( "sortid", Array.NUMERIC );
				L = areaItems.length;
				
				var ico_col:int = Application.instance.mainMenu.iconColor;
				var created:Boolean;
				var labelText:String;
				var j:int;
				var jL:int;
				var listIcon:String;
				var T:Template;
				var icos:Array;
				var pf:ProjectFile;
				var pg:Button;
				
				for (i = 0; i < L; i++)
				{
					r = areaItems[i];
					
					if( areaSubTemplateFilter != "" && r.subtemplate != areaSubTemplateFilter ) continue;
					
					T = CTTools.findTemplate( r.subtemplate, "name" );
					created = false;
					listIcon = "";
					
					if( T )
					{
						labelText = TemplateTools.obj2Text(T.listlabel, "#", r, false, true);
								
						if( T.parselistlabel ) {
							labelText = TemplateTools.obj2Text(labelText, "#", r, true, false);
							labelText = HtmlParser.fromDBText( labelText );
						}
						
						if( T.listlabel )
						{
							if( T.listicon ) {
								listIcon = CTTools.parseFilePath( T.listicon );
								icos = [ new IconFromFile( listIcon, Options.iconSize, Options.iconSize), labelText ];
							}else{
								icos = [new IconMenu(ico_col, Options.iconSize, Options.iconSize), labelText];
							}
							
							/*if ( T.articlepage != "" )
							{
								if( r.inputname == undefined ) {
									r.inputname = r.name;
								}
								filename = CTTools.webFileName( T.articlename, r );
								
								pf = CTTools.findArticleProjectFile( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + filename, "path");
								
								if ( pf && pf.templateAreas && pf.templateAreas.length > 0 )
								{
									article_areas = new Popup( [new IconArrowDown(Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize)], 
															Options.btnSize, Options.btnSize, null, styleSheet, '', 'article-areas-popup', true );
									article_areas.alignH = "right";
									article_areas.textAlign = "right";
									
									jL = pf.templateAreas.length;
									
									for (j = 0; j < jL; j++ )
									{
										if ( CTTools.activeTemplate.areasByName[pf.templateAreas[j].name] == undefined) {
											ppi = article_areas.rootNode.addItem( [pf.templateAreas[j].name], styleSheet );
											ppi.options.area = pf.templateAreas[j];
										}
									}
									if( article_areas.rootNode.children && article_areas.rootNode.children.length > 0 ) {
										article_areas.addEventListener( PopupEvent.SELECT, gotoAreaPP );
										icos.push( article_areas );
									}
								}
							}else{
								if( T.numAreas > 0 ) {
									area_ico = new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "anmeldung-abgerundet.png", Options.iconSize, Options.iconSize);
									area_ico.addEventListener( MouseEvent.MOUSE_DOWN, gotoAreaHandler );
									icos.push( area_ico );
								}
							}*/
							
							pg = new Button(icos, 0, 0, itemList, styleSheet, '', 'page-item-btn', false);
							
							if( pg.contRight ) {
								pg.contRight.mouseEnabled = true;
								pg.contRight.mouseChildren = true;
							}
							created = true;
						}
					}
					
					if(!created) {
						pg = new Button([ "" + Language.getKeyword(r.subtemplate) + ": " + r.name, new IconMenu(ico_col, Options.iconSize, Options.iconSize) ], 0, 0, itemList, styleSheet, '', 'page-item-btn', false);
					}
					
					if( areaItems[i].visible == false ) {
						pg.alpha = 0.35;
					}
					
					pg.options.result = r;
					pg.name = r.name;
					pg.addEventListener( MouseEvent.MOUSE_DOWN, areaItemDown);
					itemList.addItem( pg, true);
				}
				
				itemList.x = cssLeft;
				itemList.format(false);
				itemList.init();
			}
			
			// Bugfix: remove all html comments from inline areas
			textField.text = CompactCode.removeHtmlComments( CTTools.getAreaText( areaName, areaOffset, areaLimit/*, areaSubTemplateFilter*/ ) );
			
			setWidth( cssSizeX );
			setHeight( itemList.height );
			
			dispatchEvent( new Event("heightChange") );
			textField.visible = false;
		}
		
	}
}