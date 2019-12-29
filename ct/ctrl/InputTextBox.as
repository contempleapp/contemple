package ct.ctrl
{
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.external.ExtensionContext;
	import flash.net.FileFilter;
	import flash.utils.setTimeout;
	
	import agf.icons.IconArrowDown;
	import agf.icons.IconData;
	import agf.icons.IconBoolean;
	import agf.icons.IconFromFile;
	import agf.icons.IconFromHtml;
	import agf.icons.IconEmpty;
	import agf.tools.Application;
	import agf.events.PopupEvent;
	import agf.ui.*;
	import agf.Options;
	import agf.html.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.*;
	import agf.utils.StringMath;
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
	import ct.ctrl.VectorTextField;
	import agf.tools.Console;
	import ct.TemplateTools;
	import ct.CTTools;
	import ct.HtmlEditor;
	import ct.TemplateEditor;
	import flash.net.FileFilter;
	import agf.events.CssEvent;
	import flash.ui.Mouse;
	import ct.CTOptions;
	import agf.io.Resource;
	
	public class InputTextBox extends CssSprite
	{
		
		// TODO:
		// Input Types: TextStyle, BackgroundStyle, ContainerStyle -> generates css for margin, border, padding, background, color, font-properties etc
		// type can be intern, hiddem, name, string, code, richtext, number, integer, screennumber, screeninteger, boolean, color, list, listappend, listmultiple, labellist, arealist, pagelist, nodestyle, styleclass, vector<T>, vectorlink, file, files, image, audio, video, pdf, or directory
		public function InputTextBox ( __type:String="line", type_args:Array=null, prop_obj:Object=null, avalue:String="", w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false)
		{
			super(w, h, parentCS, css, "textbox", cssId, cssClasses, true);
			
			if(!noInit) init();
			
			autoSwapState = "";
			args = type_args;
			propObj = prop_obj;
			textField = new TextField();
			create();
			value = avalue ;
			
			var cssclasses:Array;
			if( CTTools.templateConstants && CTTools.templateConstants["richTextCssClasses"] != undefined ) {
				if( args && args.length > 0 ) {
					cssclasses = (args[0] + CTTools.templateConstants["richTextCssClasses"]).split(",");
				}else{
					cssclasses = CTTools.templateConstants["richTextCssClasses"].split(",");
				}
			}else{
				if( args && args.length > 0 ) {
					cssclasses = (args[0] + CTOptions.richTextCssClasses.join(",")).split(",");
				}else{
					cssclasses = CTOptions.richTextCssClasses;
				}
			}
			
			richTextButtons = [ cssclasses, specialChars, ".Heading", ".List", ".Bold", ".Italic", ".Link", ".Undo", ".Redo" ]
			setType(__type);
		}
		
		public static const ENTER:String = "ctrl_enter";
		
		// For name types
		public static var uniqueNameLen:int = 2;
		public static function getUniqueName (prefix:String="Item_", len:int=0) :String {
			var rndstr:String = "";
			if( len < 1 ) len = uniqueNameLen;
			for(var i:int=0; i<len; i++) {
				rndstr += "" + int(Math.random() * 9999).toString(16).toUpperCase();
			}
			return prefix + rndstr;
		}
		
		public var trimValue:Boolean = true;
		public var trimQuotesValue:Boolean = true;
		
		public var textField:TextField;
		public var htmlTextField:TextField;
		public var rtViewCode:Boolean=true;
		
		private var fmt:TextFormat;
		
		// For color Type
		private var displayMode:String="hex"; // rgb or hex
		
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
		public var rename_template:String="";    // "uploaded-file-#NAME#-#UID#-#YEAR#-#MONTH#-#DAY#-#HOUR#-#MINUTE#-#SECOND#.#EXTENSION#";
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
		
		public var btWidth:int = 0;
		
		public var wrapBegin:String="";
		public var wrapEnd:String="";
		
		public var lineWrapBegin:String="";
		public var lineWrapEnd:String="";
		
		// Für help text-anzeige
		public var helpIcon:Button;
		
		public var history:Vector.<String> = new Vector.<String>();
		public var future:Vector.<String> = new Vector.<String>();
		
		private var activateValue:String="";
		
		private static var tmp_bool_value:Boolean=false;
		
		private var _color:uint=0;
		// FILE, IMAGE, VIDEO
		private var _dir:String="";
		private var _file:String="";
		
		
		public function historyPop () :String {
			var s:String = history.pop();
			toggleUndoButtons();
			return s;
		}
		
		public function historyPush ( v:String ) :void {
			history.push( v );
			toggleUndoButtons();
		}
		
		public function futurePop () :String {
			var s:String = future.pop();
			toggleUndoButtons();
			return s;
		}
		
		public function futurePush ( v:String ) :void {
			future.push( v );
			toggleUndoButtons();
		}
		private function toggleUndoButtons () :void {
			
			if( itemList )
			{
				// Show Undo/Redo Button
				
				for( var i:int = 0; i< itemList.items.length; i++ )
				{
					if ( itemList.items[i].options.originalLabel == ".Undo" )
					{
						if( history.length > 0 ) {
							itemList.items[i].alpha = 1;
						}else{
							itemList.items[i].alpha = .1;
						}
						
					}
					else if ( itemList.items[i].options.originalLabel == ".Redo" )
					{
						if( future.length > 0 ) {
							itemList.items[i].alpha = 1;
						}else{
							itemList.items[i].alpha = .1;
						}
					}
				}
			}
		}
		public var specialCharIcons: Object = {
			name: new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "zehn-schluessel.png", 12, 12 ),
			whitespace: new IconEmpty(12, 12),
			alpha: new IconFromHtml( "&#945;", null, "", 12, 12 ),
			beta: new IconFromHtml( "&#946;", null, "", 12, 12 ),
			copyright: new IconFromHtml( "&#169;", null, "", 12, 12 ),
			delta: new IconFromHtml( "&#948;", null, "", 12, 12 ),
			gamma: new IconFromHtml( "&#947;", null, "", 12, 12 ),
			micro: new IconFromHtml( "&#181;", null, "", 12, 12 ),
			promil: new IconFromHtml( "&#8240;", null, "", 12, 12 ),
			omega: new IconFromHtml( "&#937;", null, "", 12, 12 ),
			pi: new IconFromHtml( "&#960;", null, "", 12, 12 ),
			quote: new IconFromHtml( "&#34;", null, "", 12, 12 ),
			radic: new IconFromHtml( "&8730;", null, "", 12, 12 ),
			theta: new IconFromHtml( "&952;", null, "", 12, 12 ),
			delta: new IconFromHtml( "&#914;", null, "", 12, 12 ),
			lambda: new IconFromHtml( "&#916;", null, "", 12, 12 ),
			sigma: new IconFromHtml( "&#931;", null, "", 12, 12 ),
			ypsilon: new IconFromHtml( "&#933;", null, "", 12, 12 ),
			xi: new IconFromHtml( "&#926;", null, "", 12, 12 )
		};
		
		public static var specialChars:Object = {
			name:".Special Chars",
			whitespace: "&nbsp;",
			alpha: "&#945;",
			beta: "&#946;",
			copyright: "&#169;",
			delta: "&#948;",
			gamma: "&#947;",
			micro:"&#181;",
			promil:"&#8240;",
			omega:"&#937;",
			pi:"&#960;",
			quote:"&#34;",
			radic: "&#8730;",
			theta: "&#952;",
			delta:"&#914;",
			lambda:"&#916;",
			sigma:" &#931;",
			ypsilon: "&#933;",
			xi:"&#926;"
		}
		
		public var richTextCssIcons: Array = [new IconArrowDown(0xFFFFFF,Options.iconSize,Options.iconSize)];
		
		public var itemList:ItemList;
		
		public var richTextButtons:Array;
		public var richTextIcons:Array;
		private var colorPicker:ColorPicker;
		
		private var listAppendSeparator:String=" ";
		
		private var mediaInfo:TextField;
		private var mediaContainer:Sprite;
		private var mediaWidth:int=160;
		private var mediaHeight:int=80;
		
		public function get type () :String {
			return _type;
		}
		
		public function create () :void   {
			fmt = styleSheet.getTextFormat( stylesArray, "normal" );
			setupTextField( textField, textChange, onActivate, onDeactivate);
		}
		// allow only 0-9, a-s, A-Z and the _-$:@ specialChars
		// If string is empty, returns getUniqueName()
		// n: a trimmed string (with only single white-spaces
		private function parseName (n:String) :String {
			if( !n || n == " " ) return getUniqueName();
			var L:int = n.length;
			var i:int;
			var cc:int
			var o:String="";
			for( i=0; i<L; i++) {
				cc = n.charCodeAt(i);
				if( cc <= 32 ) {
					o += "-";
				}else if( (cc >= 48 && cc <= 57) || (cc >= 97 && cc <= 122) || (cc >= 65 && cc <= 90) || cc == 95 || cc == 36 || cc == 45 ||cc == 58 || cc == 64 ) {
					o += String.fromCharCode(cc);
				}
			}
			
			cc = o.charCodeAt(0);
			if( cc >= 48 && cc <= 57)  {
				o = "_" + o;
			}
			
			if( cc == 45 ) {
				// Search for "-----..."
				var allcc:Boolean=true;
				L = o.length;
				for( i=0; i<L; i++) {
					if( o.charCodeAt(i) != 45 ) {
						allcc = false;
						break;
					}
				}
				if( allcc ) return getUniqueName();
			}
			
			if( !o || o == " ") return getUniqueName();
			return o;
		}
		
		private function setupTextField (tf:TextField, _onChange:Function=null, _onActivate:Function=null, _onDeactivate:Function=null) :void {			
			tf.type = TextFieldType.INPUT;
			tf.multiline = false;
			tf.defaultTextFormat = fmt;
			tf.setTextFormat( fmt );
			tf.embedFonts = Options.embedFonts;
			tf.antiAliasType = Options.antiAliasType;
			//tf.height = getHeight();
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
			addChild(tf);
		}
		
		private function onImageLoaded ( _res:Resource ) :void
		{
			var sp:DisplayObject = DisplayObject(_res.obj);
			
			if(sp)
			{
				var stylchain:Array = [".media-info"];
				var fmt:TextFormat = styleSheet.getTextFormat( stylchain, "normal" );
				
				if( mediaInfo == null ) {
					mediaInfo = new TextField();
					mediaInfo.multiline = true;
					mediaInfo.autoSize = TextFieldAutoSize.LEFT;
					mediaInfo.defaultTextFormat = fmt;
					mediaInfo.height = mediaHeight-4;
				}
				
				var f:File = new File( _res.url );
				mediaInfo.text =  Math.round(f.size /1000) + " kb" + " \n" + int(sp.width) + " x " + int(sp.height) + " px \n" + f.extension.toUpperCase();
				
				var bmd:BitmapData = new BitmapData(mediaWidth, mediaHeight, true, 0x00999999);
				var bmp:Bitmap = new Bitmap(bmd);
			
				var dw:Number = mediaWidth/sp.width;
				var dh:Number = mediaHeight/sp.height;
				var scl:Number = Math.min( dw, dh);
				
				if( scl < 1 ) {
					sp.scaleX = sp.scaleY = scl;
				}
				bmd.draw( sp, sp.transform.matrix );
				var m:Number = 0;
				var o:Object = styleSheet.getMultiStyle( stylchain );
				if( o.marginLeft ) m = CssUtils.parse( o.marginLeft, this, "h" );
				
				if( fmt.align == "right" ) {
					mediaInfo.x = getWidth() - mediaInfo.width;
				}else{	
					mediaInfo.x = sp.width + m;
					mediaInfo.y = 4;
				}
				
				mediaContainer.addChild( bmp );
				mediaContainer.addChild( mediaInfo );
				setHeight( textField.height );
			}
		}
		
		private function largeImagePreview (e:MouseEvent = null) :void {
			if( HtmlEditor.isPreviewOpen ) {
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
		
		private function loadImage (path:String) :void
		{
			Application.instance.resourceMgr.clearResourceCache( path, true );
			Application.instance.resourceMgr.loadResource( path, onImageLoaded, false );
		}
		
		private function loadVideo (path:String) :void {
			var sp:Video = new Video ( mediaWidth, mediaHeight );
			
			// TODO: display video player
			mediaContainer.addChild( sp );
				
			setHeight( textField.height );	
		}
		
		//      ..........
		//     : set type :
		//      ..........
		//
		public function setType (tp:String="text") :void {
			_type = tp;
			
			var i:int;
			var L:int;
			var tfh:int;
			var ta_str:String;
			var ta_arr:Array;
			var ta_i:int;
			var btn:Button;
			
			if( mediaContainer && contains(mediaContainer)) removeChild( mediaContainer );
			
			if( tfBtn && contains(tfBtn)) removeChild( tfBtn );
			tfBtn = null;
			if( tfPopup && contains(tfPopup)) removeChild( tfPopup );
			tfPopup = null;
			if( tfSlider && contains(tfSlider)) removeChild( tfSlider );
			tfSlider = null;
			if( colorClip && contains(colorClip)) removeChild( colorClip );
			colorClip = null;
			if( colorPicker && contains(colorPicker)) removeChild( colorPicker );
			colorPicker = null;
			if( htmlTextField && contains( htmlTextField ) ) removeChild( htmlTextField );
			htmlTextField = null;
			
			if( vectorTextFields ) {
				L = vectorTextFields.length;
				for(i=0; i<L; i++) {
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

			if( tp == "directory" || tp == "file" || tp == "files" || tp == "image" || tp=="video" || tp=="audio" || tp=="pdf" )
			{
				var icoPath:String;
				if( tp == "image" ) {
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-image.png";
				}else if( tp == "video" ) {
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-video.png";
				}else if( tp == "audio" ) {
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-audio.png";
				}else{
					icoPath = Options.iconDir + CTOptions.urlSeparator + "file-text.png";
				}
				tfBtn = new Button([ new IconFromFile( icoPath,Options.iconSize,Options.iconSize ) ],btWidth,0,this,styleSheet,'','textbox-button', false);
				tfBtn.textAlign = "center";
				textField.width = textField.width - tfBtn.cssSizeX;
				tfBtn.x = textField.width - 1;
				tfBtn.y = 1;
				
				initDragNDrop(this);
				
				if( tp == "directory" ) {
					tfBtn.addEventListener( MouseEvent.CLICK, selectDirectory );
				}else{
					tfBtn.addEventListener( MouseEvent.CLICK, selectFiles );
				}
				
				if( tp == "image" ) {
					fileFilterDescription = "Image Files";
					allowed_extensions  =  "*.gif;*.jpg;*.png;";
				}else if( tp == "video" ) {
					fileFilterDescription = "Video Files";
					allowed_extensions  =  "*.mp4;*.mov;";
				}else if( tp == "audio" ) {
					fileFilterDescription = "Mp3 Files";
					allowed_extensions  =  "*.mp3;";
				}else if( tp == "pdf" ) {
					fileFilterDescription = "PDF Files";
					allowed_extensions  =  "*.pdf;";
				}
				if( args ) {
					L = args.length;
					if( L > 0 ) www_folder = args[0];
					if( L > 1 ) rename_template = args[1];
					if( L > 2 ) fileFilterDescription = args[2];
					if( L > 3 ) allowed_extensions = args[3];
				}
				
				if( tp == "image" /*|| tp == "video"*/ ) {
					var m:Number = 3;
					var o:Object = styleSheet.getMultiStyle( [".media-container"] );
					if( o.marginLeft ) m = CssUtils.parse( o.marginLeft, this, "h" )
					
					mediaContainer = new Sprite();
					mediaContainer.addEventListener( MouseEvent.CLICK, largeImagePreview );
					mediaContainer.y = textField.height + 5;
					mediaContainer.x = m;
					addChild(mediaContainer);
					
					if( value && value != "" && value.toLowerCase() != "none") {
						if( tp == "image") {
							loadImage( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + value );
						//}else if( tp == "video" ) {
						//	loadVideo( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + value );
						}
					}
				}
				setHeight( textField.height + 2);
				
			}
			else if( tp == "nodestyle" ) 
			{
				tfBtn = new Button([new IconFromFile(Options.iconDir + CTOptions.urlSeparator +"services.png"),Options.iconSize,Options.iconSize],btWidth,0,this,styleSheet,'','textbox-nodestyle-btn', false);
				textField.width = textField.width - (tfBtn.cssSizeX + cssBoxX);
				textField.wordWrap = true;
				textField.autoSize = TextFieldAutoSize.LEFT;
				
				tfBtn.x = textField.width - 1;
				tfBtn.y = 1;
				tfBtn.addEventListener( MouseEvent.CLICK, nodeStyleHandler );
				tfh = textField.height;
				textField.autoSize = TextFieldAutoSize.NONE;
				
				setHeight( tfh + 2 );
			}
			else if( tp == "styleclass" ) 
			{
				tfBtn = new Button([new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "modul.png"),Options.iconSize,Options.iconSize],btWidth,0,this,styleSheet,'','textbox-styleclass-btn', false);
				textField.width = textField.width - (tfBtn.cssSizeX + cssBoxX);
				textField.wordWrap = true;
				textField.autoSize = TextFieldAutoSize.LEFT;
				
				tfBtn.x = textField.width - 1;
				tfBtn.y = 1;
				tfBtn.addEventListener( MouseEvent.CLICK, styleClassHandler );
				tfh = textField.height;
				textField.autoSize = TextFieldAutoSize.NONE;
				
				setHeight( tfh + 2 );
			}
			else if ( tp == "boolean" )
			{
				if( args ) {
					L = args.length;
					if( L > 0 ) boolYes = args[0];
					if( L > 1 ) boolNo = args[1];
				}
				
				var ico:Sprite = new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "toggle-off-btn.png", Options.btnSize*1.25, Options.btnSize );
				
				tfBtn = new Button([ico],0,0,this,styleSheet,'','textbox-boolean-btn', false);
				textField.width = textField.width - (tfBtn.cssSizeX+cssBoxX);
				
				tfBtn.x = textField.width - 1;
				tfBtn.y = -3;
				tfBtn.addEventListener( MouseEvent.CLICK, boolButtonHandler );
				
				if( boolValue || value == boolYes || value=="true" || CssUtils.stringToBool(value) ) {
					boolValue = true;
				}
				
				setHeight( textField.height + 2 );
			}
			else if( tp == "number" || tp == "integer" || tp == "screennumber" || tp == "screeninteger" )
			{
				if( args && args.length > 1) {
					tfSlider = new Slider(0, 0, this,styleSheet, '', 'textbox-slider', false);
					tfSlider.setScrollerHeight( int(textField.width / 10) );
					tfSlider.setHeight( textField.width-4 );
					tfSlider.setWidth( tfSlider.getWidth() || 8 );
					tfSlider.rotation = -90;
					tfSlider.x = 0;
					tfSlider.wheelScrollTarget = null;
					tfSlider.y = textField.height+6;
					tfSlider.minValue = Number( args[0] );
					tfSlider.maxValue = Number( args[1] );
					tfSlider.value = StringMath.forceNumber( value );
					tfSlider.addEventListener( "begin", sliderBegin );
					tfSlider.addEventListener( MouseEvent.MOUSE_UP, sliderUp );
					tfSlider.addEventListener( Event.CHANGE, sliderChange );
					if( args.length > 2 ) sliderGrid = Number( args[2] );
					var cdp:int = String( sliderGrid - int(sliderGrid) ).length - 1;
					if( cdp >= 0 ) { decPlaces = cdp; }
					if( args.length > 3 ) outsideRange = CssUtils.stringToBool( args[3] );
					if( args.length > 4 ) decPlaces = parseInt(args[4]);
				}
				if( tp == "screennumber" || tp == "screeninteger"  ) {
					
					tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
					tfPopup.alignH = "right";
					tfPopup.textAlign = "right";
					tfPopup.alignV = "bottom";
					
					L = screenUnits.length;
					for(i=0; i < L; i++) {
						tfPopup.rootNode.addItem( [ "" + screenUnits[i] ], styleSheet);
					}
					
					tfPopup.addEventListener( Event.SELECT, ppScreenNumberSelect );
					textField.width = textField.width - (tfPopup.cssSizeX+cssBoxX);
					tfPopup.x = textField.width - 1;
					tfPopup.y = 1;
					tfPopup.contLeft.x = tfPopup.cssLeft + 3;
				}
				
				if( tfSlider ) {
					setHeight( textField.height + 12 );
				}else{
					setHeight( textField.height + 2 );
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

					if( L <= 1 || vectorDynamic) {
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
					
					if( vectorType == "directory" || vectorType == "file" || vectorType == "image" || vectorType == "video" || vectorType == "audio" || vectorType == "pdf")
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
							
							if( args.length > valStart+1) {
								vecArgs.push(args[valStart+1]);
								if( args.length > valStart+2) vecArgs.push(args[valStart+2]);
								if( args.length > valStart+3) vecArgs.push(args[valStart+3]);
								if( args.length > valStart+4) vecArgs.push(args[valStart+4]);
								if(args.length > valStart+5) vecWrap = args[valStart+5];
							}else{
								vecArgs.push( defaultWWWFolder, defaultRename, defaultDescr, defaultExtList );
								vecWrap = vectorWrap;
							}
							
							vecObj = {};
							CTTools.cloneTo( propObj, vecObj );
							tf = new VectorTextField( vectorType, vecArgs, vecObj, vecValue, cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
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
						
						for(i=0; i<L2; i++) {
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
					else if ( vectorType == "typed" )
					{
						if( args.length > 5 ) typeList = typeof args[5] == "string" ? String(args[5]).split(",") : args[5];
						if(typeList ) {
							L2 = Math.max( L, splitValues.length );
							
							for(i=0; i<L2; i++) {
								vecArgs = typeList;
								vecObj = {};
								valStart = 6 + i*2;

								if( args.length > valStart ) vecValue = args[ valStart ];
								if( splitValues.length > i ) vecValue = splitValues[i];
								
								tf = new VectorTextField( vectorType, vecArgs, vecObj, vecValue, cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
								tf.wrap = vecWrap;
								tf.rootVector = this;
								vectorTextFields.push( tf );
							}
						}
					}
					else
					{
						L2 = Math.max( L, splitValues.length );
						
						for(i=0; i<L2; i++) {
							vecArgs = [];
							vecObj = {};
							valStart = 5 + i*2;

							if( args.length > valStart ) vecValue = args[ valStart ];
							if( splitValues.length > i ) vecValue = splitValues[i];
							if( args.length > valStart+1) vecWrap = args[valStart+1];

							tf = new VectorTextField( vectorType, vecArgs, vecObj, vecValue, cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
							tf.wrap = vecWrap;
							tf.rootVector = this;
							
							vectorTextFields.push( tf );
						}
					}
					
					formatVector();
				}
				
				var vpmb:int = 0;
				if(vectorPlusButton && vectorMinusButton) {
					vpmb = Math.max(vectorPlusButton.cssSizeY, vectorMinusButton.cssSizeY)
				}
				setHeight( textField.height + 2 + vpmb );
			}else if( tp == "text" || tp == "code" ) {
				textField.multiline = true;
				textField.wordWrap = true;
				
				itemList = new ItemList(0, 0, this, this.styleSheet, '', 'richtext-btn-list', false);
				
				btn = new Button([new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "reply.png",Options.iconSize,Options.iconSize)],0,0,itemList,this.styleSheet,'','richtext-btn richtext-btn-first',false);
				btn.options.originalLabel = ".Undo";
				btn.addEventListener(MouseEvent.MOUSE_DOWN, richtTextBtnHandler);
				itemList.addItem(btn, true);
				
				btn = new Button([new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "forward.png",Options.iconSize,Options.iconSize)],0,0,itemList,this.styleSheet,'','richtext-btn richtext-btn-last',false);
				btn.options.originalLabel = ".Redo";
				btn.addEventListener(MouseEvent.MOUSE_DOWN, richtTextBtnHandler);
				itemList.addItem(btn, true);
				
				itemList.format(true);
				historyPush( textField.text );
				textField.autoSize = TextFieldAutoSize.LEFT;
				textField.width = getWidth() - ( itemList.width + 4);
				
				tfh = textField.height;
				textField.autoSize = TextFieldAutoSize.NONE;
				
				setHeight( tfh + 2 );
				setWidth(getWidth());
				
			}else if( tp == "color") {
				setHeight( textField.height + 2);
				colorClip = new Sprite();
				colorValue = value;
				
				var colorStyle:Object = styleSheet.getStyle(".textbox-color-clip");
				
				if( colorStyle ) {
					if( colorStyle.marginRight ) {
						colorOfs = CssUtils.parse( colorStyle.marginRight, this );
					}
					if( colorStyle.paddingRight ) {
						colorOfs = Math.max( colorOfs, CssUtils.parse( colorStyle.paddingRight, this) );
					}
				}
				
				drawCurrentColor();
				
				ColorPicker.testColor( this._color );
				
				if( propObj && propObj.defValue ) {
					var cl:int = CssUtils.parse( propObj.defValue);
					ColorPicker.testColor( cl );
				}
				colorClip.addEventListener( MouseEvent.CLICK, onSelectColor);
				addChild( colorClip );
			}
			else if( tp == "richtext" )
			{
				textField.multiline = true;
				textField.wordWrap = true;
				
				specialCharIcons = {
					name: new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "zehn-schluessel.png", Options.iconSize, Options.iconSize ),
					whitespace: new IconEmpty(12, 12),
					alpha: new IconFromHtml( '<p class="special-char-icon">&#945;</p>', styleSheet, "", 12, 12 ),
					beta: new IconFromHtml( '<p class="special-char-icon">&#946;</p>', styleSheet, "", 12, 12 ),
					copyright: new IconFromHtml('<p class="special-char-icon">&#169;</p>', styleSheet, "", 12, 12 ),
					delta: new IconFromHtml('<p class="special-char-icon">&#948;</p>', styleSheet, "", 12, 12 ),
					gamma: new IconFromHtml( '<p class="special-char-icon">&#947;</p>', styleSheet, "", 12, 12 ),
					micro: new IconFromHtml( '<p class="special-char-icon">&#181;</p>', styleSheet, "", 12, 12 ),
					promil: new IconFromHtml( '<p class="special-char-icon">&#8240;</p>', styleSheet, "", 12, 12 ),
					omega: new IconFromHtml( '<p class="special-char-icon">&#937;</p>', styleSheet, "", 12, 12 ),
					pi: new IconFromHtml( '<p class="special-char-icon">&#960;</p>', styleSheet, "", 12, 12 ),
					quote: new IconFromHtml( '<p class="special-char-icon">&#34;</p>', styleSheet, "", 12, 12 ),
					radic: new IconFromHtml( '<p class="special-char-icon">&#8730;</p>', styleSheet, "", 12, 12 ),
					theta: new IconFromHtml( '<p class="special-char-icon">&#952;</p>', styleSheet, "", 12, 12 ),
					delta: new IconFromHtml( '<p class="special-char-icon">&#914;</p>', styleSheet, "", 12, 12 ),
					lambda: new IconFromHtml( '<p class="special-char-icon">&#916;</p>', styleSheet, "", 12, 12 ),
					sigma: new IconFromHtml( '<p class="special-char-icon">&#931;</p>', styleSheet, "", 12, 12 ),
					ypsilon: new IconFromHtml( '<p class="special-char-icon">&#933;</p>', styleSheet, "", 12, 12 ),
					xi: new IconFromHtml( '<p class="special-char-icon">&#926;</p>', styleSheet, "", 12, 12 )
				};
				richTextIcons =  [	richTextCssIcons, specialCharIcons,
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "kopfzeile.png",Options.iconSize,Options.iconSize), 
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "li.png",Options.iconSize,Options.iconSize), 
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "fett-gedruckt.png",Options.iconSize,Options.iconSize), 
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "kursiv.png",Options.iconSize,Options.iconSize),
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "link.png",Options.iconSize,Options.iconSize),
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "reply.png",Options.iconSize,Options.iconSize), 
									new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "forward.png",Options.iconSize,Options.iconSize)  ];
				
				itemList = new ItemList(0,0,this,this.styleSheet,'','richtext-btn-list', false);
				
				var btnpp:Popup;
				var s:int;
				var n:String;
				var ppi:PopupItem;
				var icons:Array;
				
				for( i=0; i < richTextButtons.length; i++) {
					if( richTextButtons[i] is Array ) {
						if( richTextButtons[i][0].charAt(0) == "." ) {
							icons = [];
						}else{
							icons = [ richTextButtons[i][0] ];
						}
						
						if( richTextIcons && richTextIcons.length > i )
						{
							if( richTextIcons[i] is Array && richTextIcons[i].length > 0 ) {
								icons.push( richTextIcons[i][0] );
							}
						}						
						btnpp = new Popup( icons, 0,0,itemList, cssStyleSheet,'','richtext-popup' + (i==0?" richtext-popup-first" : (i==richTextButtons.length-1 ? " richtext-popup-last":"") ),false);
						btnpp.alignH = "right";
						btnpp.textAlign = "right";
						btnpp.alignV = "current";//"bottom";
						
						for(s=1; s < richTextButtons[i].length; s++) {
							btnpp.rootNode.addItem( [ ""+richTextButtons[i][s]], cssStyleSheet);
						}
						btnpp.addEventListener( Event.SELECT, richtTextPPHandler);
						itemList.addItem(btnpp,true);
					
					}else if( richTextButtons[i] is String ){
						if( richTextButtons[i].charAt(0) == "." ) {
							icons = [];
						}else{
							icons = [ Language.getKeyword( richTextButtons[i] ) ];
						}
						if( richTextIcons && richTextIcons.length > i ) {
							icons.push( richTextIcons[i] );
						}		
						btn = new Button(icons,0,0,itemList,this.styleSheet,'','richtext-btn'+ (i==0?" richtext-btn-first" : (i==richTextButtons.length-1?" richtext-btn-last":"")),false);
						
						btn.options.originalLabel = richTextButtons[i];
						
						btn.addEventListener(MouseEvent.MOUSE_DOWN, richtTextBtnHandler);
						itemList.addItem(btn, true);
					
					}else if( richTextButtons[i] is Object ) {
						if( richTextButtons[i].name.charAt(0) == "." ) {
							icons = [];
						}else{
							icons = [richTextButtons[i].name];
						}
						if( richTextIcons && richTextIcons.length > i ) {
							if( richTextIcons[i] is Object && richTextIcons[i]["name"] != undefined ) {
								icons.push(  richTextIcons[i]["name"] );
							}
						}
						btnpp = new Popup( icons,0,0,itemList, cssStyleSheet,'','richtext-popup' + (i==0?" richtext-popup-first" : (i==richTextButtons.length-1 ? " richtext-popup-last":"") ),false);
						btnpp.alignH = "right";
						btnpp.textAlign = "right";
						btnpp.alignV = "current";
						
						for( n in richTextButtons[i] ) {
							if( n != "name" ) {
								icons = [""+n];
								if( richTextIcons && richTextIcons.length > i ) {
									if( richTextIcons[i] is Object && richTextIcons[i][n] != undefined ) {
										icons.push( richTextIcons[i][n] );
									}
								}
								ppi = btnpp.rootNode.addItem( icons, cssStyleSheet);
								ppi.options.overrideVal = richTextButtons[i][n];
							}
						}
						btnpp.addEventListener( Event.SELECT, richtTextPPHandler);
						itemList.addItem(btnpp,true);
					}
				}
				
				itemList.format(true);
				historyPush( textField.text );
				textField.autoSize = TextFieldAutoSize.LEFT;
				textField.width = getWidth() - ( itemList.width + 4);
				
				tfh = textField.height;
				textField.autoSize = TextFieldAutoSize.NONE;
				
				setHeight( tfh + 2 );
				setWidth(getWidth());
			}
			else if( tp == "typed" ) {
				if( args && args.length > 0 )
				{
					var types:Array = args[0] is Array ? args[0] : args;
					if( types ) {
						
						tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ), types[0] ], 0, textField.height - 1, this, styleSheet, '', 'textbox-typed', false);
						tfPopup.alignH = "right";
						tfPopup.textAlign = "right";
						tfPopup.alignV = "bottom";
						
						if( types.length > 0) {
							L = types.length;
							for(i=0; i < L; i++) {
								tfPopup.rootNode.addItem( [ "" + types[i] ], styleSheet);
							}
						}
						tfPopup.addEventListener( Event.SELECT, ppTypedSelect );
						textField.width = textField.width - tfPopup.cssSizeX;
						tfPopup.x = textField.width - 1;
						tfPopup.y = 1;
						tfPopup.contLeft.x = tfPopup.cssLeft + 3;
					}
				}
				setHeight( textField.height + 2 );
				
			}else if( tp == "list" ) {
				if( args && args.length > 0 )
				{
					tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
					tfPopup.alignH = "right";
					tfPopup.textAlign = "right";
					tfPopup.alignV = "current";
					
					if( args.length > 0) {
						L = args.length;
						for(i=0; i < L; i++)
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
										tfPopup.rootNode.addItem( [ "" + TemplateTools.obj2Text(ta_arr[ta_i], "#", propObj, false, false ) ], styleSheet);
									}
									
									continue;
								}else{
									Console.log("Identifier not found: " + ta_str);
								}
							}
							
							// no var or constants found:
							tfPopup.rootNode.addItem( [ "" + TemplateTools.obj2Text( ta_str, "#", propObj, false, false ) ], styleSheet);
						}
					}
					tfPopup.addEventListener( Event.SELECT, ppListSelect );
					textField.width = textField.width - tfPopup.cssSizeX;
					tfPopup.x = textField.width - 1;
					tfPopup.y = 1;
					tfPopup.contLeft.x = tfPopup.cssLeft + 3;
				}
				setHeight( textField.height + 2 );
			}else if( tp == "listappend" || tp == "listmultiple" ) {
				if( args && args.length > 0 )
				{
					tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
					tfPopup.alignH = "right";
					tfPopup.textAlign = "right";
					tfPopup.alignV = "current";
					
					listAppendSeparator = args[0];
					var ta_str2:String;
					
					if( args.length > 1) {
						L = args.length;
						for(i=1; i < L; i++) {
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
											ta_arr = ta_str2.split();
										}
									}catch(e:Error) {
										
									}
								}
								
								if( ta_arr )
								{
									for( ta_i=0; ta_i < ta_arr.length; ta_i++)
									{
										tfPopup.rootNode.addItem( [ "" + TemplateTools.obj2Text(ta_arr[ta_i], "#", propObj, false, false ) ], styleSheet);
									}
									
									continue;
								}else{
									Console.log("Identifier not found: " + ta_str);
								}
							}
							
							// no var or constants found:
							tfPopup.rootNode.addItem( [ "" + TemplateTools.obj2Text( ta_str, "#", propObj, false, false ) ], styleSheet);
						}
					}
					tfPopup.addEventListener( Event.SELECT, ppListAppendSelect );
					textField.width = textField.width - tfPopup.cssSizeX;
					tfPopup.x = textField.width - 1;
					tfPopup.y = 1;
					tfPopup.contLeft.x = tfPopup.cssLeft + 3;
				}
				setHeight( textField.height + 2 );
			}else if( tp == "pagelist" ) {
				
				tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
				tfPopup.alignH = "right";
				tfPopup.textAlign = "right";
				tfPopup.alignV = "current";
				var pages:Array = [];
				
				if( CTTools.pages )
				{
					L = CTTools.pages.length;
					
					if( args && args.length > 0)
					{
						var key:String;
						var val:String;
						if( args.length > 1 ) {
							key = args[0].toLowerCase();
							val = args[1];
						}else{
							val = args[0];
							key = "parent";
						}
						
						for(i=0; i<L; i++) {
							// filter pages by key/val - args[0]/args[1]
							if( pages[i][key] == val ) {
								pages.push( CTTools.pages[i].name );
							}
						}
						if( pages.length > 0 )
						{
							if( args.length > 2 ) {
								// filter again with args[2]/args[3]
								if( args.length > 3 ) {
									key = args[2].toLowerCase();
									val = args[3];
								}else{
									val = args[2];
									key = "parent";
								}
								for(i=pages.length-1; i>=0; i--) {
									if( pages[i][key] != val ) {
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
							pages.push( CTTools.pages[i].name );
						}
					}
				}
				pages.sort();
				
				if( pages.length > 0) {
					L = pages.length;
					for(i=0; i < L; i++) {
						tfPopup.rootNode.addItem( [ "" + pages[i] ], styleSheet);
					}
				}
				tfPopup.addEventListener( Event.SELECT, ppListSelect );
				textField.width = textField.width - tfPopup.cssSizeX;
				tfPopup.x = textField.width - 1;
				tfPopup.y = 1;
				tfPopup.contLeft.x = tfPopup.cssLeft + 3;
				setHeight( textField.height + 2 );
				
			}else if( tp == "arealist" ) {
				
				tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
				tfPopup.alignH = "right";
				tfPopup.textAlign = "right";
				tfPopup.alignV = "current";
				var areas:Array = [];
				
				if( CTTools.activeTemplate && CTTools.activeTemplate.areasByName ) {
					for(var areaname:String in CTTools.activeTemplate.areasByName ) {
						areas.push(CTTools.activeTemplate.areasByName[areaname].name);
					}
				}
				areas.sort();
				
				if( areas.length > 1) {
					L = areas.length;
					for(i=0; i < L; i++) {
						tfPopup.rootNode.addItem( [ "" + areas[i] ], styleSheet);
					}
				}
				tfPopup.addEventListener( Event.SELECT, ppListSelect );
				textField.width = textField.width - tfPopup.cssSizeX;
				tfPopup.x = textField.width - 1;
				tfPopup.y = 1;
				tfPopup.contLeft.x = tfPopup.cssLeft + 3;
				setHeight( textField.height + 2 );
				
			}else if( tp == "itemlist" ) {
				
				// ItemList( area-name, [field], [pre], [post] )
				if( args && args.length > 0)
				{
					tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
					tfPopup.alignH = "right";
					tfPopup.textAlign = "right";
					tfPopup.alignV = "current";
					
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
					
					if( CTTools.pageItems ) {
						L = CTTools.pageItems.length;
						for( i=0; i < L; i++) {
							if( CTTools.pageItems[i].area == area ) {
								ppi = tfPopup.rootNode.addItem( [ "" + CTTools.pageItems[i][labelfield]], styleSheet);
								ppi.options.labelValue = pre + CTTools.pageItems[i][field] + post;
							}
						}
					}
					
					tfPopup.addEventListener( Event.SELECT, ppLabelListSelect );
					textField.width = textField.width - tfPopup.cssSizeX;
					tfPopup.x = textField.width - 1;
					tfPopup.y = 1;
					tfPopup.contLeft.x = tfPopup.cssLeft + 3;
					setHeight( textField.height + 2 );
				}
			}else if( tp == "itemlistappend" || tp == "itemlistmultiple" ) {
				
				// ItemList( area-name, [field], [pre], [post] )
				if( args && args.length > 1)
				{
					tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
					tfPopup.alignH = "right";
					tfPopup.textAlign = "right";
					tfPopup.alignV = "current";

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
					
					if( CTTools.pageItems ) {
						L = CTTools.pageItems.length;
						for( i=0; i < L; i++) {
							if( CTTools.pageItems[i].area == area1 ) {
								ppi = tfPopup.rootNode.addItem( [ "" + CTTools.pageItems[i][labelfield1]], styleSheet);
								ppi.options.labelValue = pre1 + CTTools.pageItems[i][field1] + post1;
							}
						}
					}
					
					tfPopup.addEventListener( Event.SELECT, ppLabelListAppendSelect );
					textField.width = textField.width - tfPopup.cssSizeX;
					tfPopup.x = textField.width - 1;
					tfPopup.y = 1;
					tfPopup.contLeft.x = tfPopup.cssLeft + 3;
					setHeight( textField.height + 2 );
					
				}
			}else if( tp == "labellist" ) {
				if( args && args.length > 0 ) {
					tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
					tfPopup.alignH = "right";
					tfPopup.textAlign = "right";
					tfPopup.alignV = "current";
					if( args.length > 0) {
						L = args.length;
						var ppi2:PopupItem;
						for(i=0; i < L; i+=2) {
							ppi2 = tfPopup.rootNode.addItem( [ "" + TemplateTools.obj2Text( args[i], "#", propObj, false, false ) ], styleSheet);
							ppi2.options.labelValue = TemplateTools.obj2Text( args[i+1], "#", propObj, false, false );
						}
					}
					tfPopup.addEventListener( Event.SELECT, ppLabelListSelect );
					textField.width = textField.width - tfPopup.cssSizeX;
					tfPopup.x = textField.width - 1;
					tfPopup.y = 1;
					tfPopup.contLeft.x = tfPopup.cssLeft + 3;
				}
				setHeight( textField.height + 2 );
			}else if( tp == "labellistmultiple"  || tp == "labellistappend" ) {
				if( args && args.length > 0 ) {
					tfPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor ) ], btWidth, textField.height - 1, this, styleSheet, '', 'textbox-popup', false);
					tfPopup.alignH = "right";
					tfPopup.textAlign = "right";
					tfPopup.alignV = "current";
					
					listAppendSeparator = args[0];
					
					if( args.length > 0) {
						L = args.length;
						var ppi3:PopupItem;
						for(i=1; i < L; i+=2) {
							ppi3 = tfPopup.rootNode.addItem( [ "" + TemplateTools.obj2Text( args[i], "#", propObj, false, false )  ], styleSheet);
							ppi3.options.labelValue = TemplateTools.obj2Text( args[i+1], "#", propObj, false, false );
						}
					}
					tfPopup.addEventListener( Event.SELECT, ppLabelListAppendSelect );
					textField.width = textField.width - tfPopup.cssSizeX;
					tfPopup.x = textField.width - 1;
					tfPopup.y = 1;
					tfPopup.contLeft.x = tfPopup.cssLeft + 3;
				}
				setHeight( textField.height + 2 );
			}else if( tp == "name" ) {
				if( value == "" ) {
					value = getUniqueName();
				}
				setHeight( textField.height + 2);
			}
			else if(type=="vectorlink") 
			{
				if( args.length>1 && args[1].toLowerCase() == "none") {
					// hidden
					setHeight(1);
					visible = false;
				}else{
					var tptmp:String = _type;
					setType("vector");
					if( vectorPlusButton ) vectorPlusButton.visible = false;
					if( vectorMinusButton ) vectorMinusButton.visible = false;
					_type = tptmp;
				}
			}else{
				// String
				setHeight( textField.height + 2);
			}
			
			if( type == "intern" || type == "hidden" ) {
				textField.visible = false;
				setHeight(0);
			}
		}
		
		protected function formatVector () :void
		{
			if( vectorTextFields ) {
				var yp:int = 0;
				var L:int = vectorTextFields.length;
				var tf:InputTextBox;
				
				for(var i:int=0; i<L; i++) {
					tf = vectorTextFields[i];
					tf.y = yp;
					yp += tf.cssSizeY;
				}
			}
			textField.height = yp;
			textField.alpha = 0;
		
			if( vectorPlusButton ) {
				vectorPlusButton.y = yp + cssTop;
				vectorContainer.setChildIndex( vectorPlusButton, vectorContainer.numChildren-1);
			}

			if( vectorMinusButton ){
				vectorMinusButton.y = yp + cssTop;
				vectorContainer.setChildIndex( vectorMinusButton, vectorContainer.numChildren-2)
			}
		}
		
		public static var rtNodeName:String = "span";
		
		protected function richtTextPPHandler ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			
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
					
					if( beginid == endid ) {
						// Test if cursor is in Markup Code...
						if( beginid > 0 ) {
							for( i = beginid; i >= 0; i--) {
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
							if( ke >= 0 ) {
								for( i=beginid; i<tm.length; i++ ) {
									ti = tm.charCodeAt(i);
									if( ti == 93 ) { // ]
										ko = i+1;
										break;
									}
								}
							}
						}
						if( ke == -1 || ko == -1 ) {
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
						}else{
							// inside block..
							
							var te:int = tm.indexOf("class=", ke);
							
							if( te >= 0 && te < ko ) 
							{
								var ko2:int = tm.indexOf('"', te +7);
								
								if( ko2 >= 0 ) {
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
					
					if( ke >= 0 && ko >= 0 ) {
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
		
		private function showSelectTextError () :void {
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
			if( !TemplateEditor.clickScrolling ) {
				
			}
		}
		
		protected function styleClassHandler (e:MouseEvent) :void
		{
			// Open Class Editor...
			if( !TemplateEditor.clickScrolling ) {
				
			}
		}
		
		protected function richtTextBtnHandler (e:MouseEvent) :void {
			if( !TemplateEditor.clickScrolling ) {
				var btn:Button = Button(e.currentTarget);
				var lb:String = btn.label;
				var beginid:int = textField.selectionBeginIndex;
				var endid:int = textField.selectionEndIndex;
				var tmp:String;
				var tp:int;
				var s:String;
				if(textField.text.charCodeAt( endid -1) <= 32) endid--;
				
				if( btn.options.originalLabel == "Code" ) {
					rtViewCode = true;
					textField.visible = true;
					htmlTextField.visible = false;
					return;
				}else if( btn.options.originalLabel == "Live") {
					rtViewCode = false;
					textField.visible = false;
					htmlTextField.visible = true;
					return;
				}else if( btn.options.originalLabel == ".Undo") {
					
					if( history && history.length > 0 ) {
						s = historyPop();
						futurePush( value );
						value = s;
						textEnter();
						return;
					}
				}else if( btn.options.originalLabel == ".Redo") {
					if( future && future.length > 0 ) {
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
				
				if( btn.options.originalLabel == ".Bold") {
					historyPush( value );
					value = textField.text.substring(0, beginid) + '**'+ (beginid >= endid ? "":textField.text.substring( beginid, endid )) + "**" + textField.text.substring( endid );
					textEnter();
					tp = beginid + 2+ (endid > beginid ? (endid - beginid) : 0);
					stage.focus = textField;
					textField.setSelection( tp, tp );
				}else if( btn.options.originalLabel == ".Italic") {
					historyPush( value );
					value = textField.text.substring(0, beginid) + '*'+( beginid >= endid?"":textField.text.substring( beginid, endid )) + "*" + textField.text.substring( endid );
					tp = beginid + 1 + (endid > beginid ? (endid - beginid) : 0);
					stage.focus = textField;
					textField.setSelection( tp, tp );
				}else if( btn.options.originalLabel == ".Heading") {
					historyPush( value );
					nli = textField.text.charCodeAt(beginid-1);
					if( nli == 9 || nli == 10 ||nli == 13 ) {
						nl = "";
					}else{
						nl = "\n";
					}
					nli = textField.text.charCodeAt(endid+1);
					if( nli == 9 || nli == 10 || nli == 13 ) {
						nle = "";
					}else{
						nle = "\n";
					}
					value = textField.text.substring(0, beginid) +  nl+ '# '+( beginid >= endid?"":textField.text.substring( beginid, endid )) + nle + textField.text.substring( endid );
					tp = beginid + 1 + (endid > beginid ? (endid - beginid) : 0);
					stage.focus = textField;
					textField.setSelection( tp, tp );
				}else if( btn.options.originalLabel == ".List") {
					historyPush( value );
					nli = textField.text.charCodeAt(beginid-1);
					if( nli == 9 || nli == 10 || nli == 13 ) {
						nl = "";
					}else{
						nl = "\n";
					}
					nli = textField.text.charCodeAt(endid+1);
					if( nli == 9 || nli == 10 || nli == 13 ) {
						nle = "";
					}else{
						nle = "\n";
					}
					value = textField.text.substring(0, beginid) +  nl+ '- '+( beginid >= endid?"":textField.text.substring( beginid, endid )) + nle + textField.text.substring( endid );
					tp = beginid + 1 + (endid > beginid ? (endid - beginid) : 0);
					stage.focus = textField;
					textField.setSelection( tp, tp );
				}else if( btn.options.originalLabel == ".Paragraph") {
					historyPush( value );
					value = textField.text.substring(0, beginid) + '[p]'+( beginid >= endid?"":textField.text.substring( beginid, endid )) + "[/p]" + textField.text.substring( endid );
					tp = beginid + 3 + (endid > beginid ? (endid - beginid) : 0);
					stage.focus = textField;
					textField.setSelection( tp, tp );
				}else if( btn.options.originalLabel == ".Left") {
					historyPush( value );
					value = textField.text.substring(0, beginid) + '[div class="text-left"]'+( beginid >= endid?"":textField.text.substring( beginid, endid )) + "[/div]" + textField.text.substring( endid );
					tp = beginid + 23 + (endid > beginid ? (endid - beginid) : 0);
					stage.focus = textField;
					textField.setSelection( tp, tp );
				}else if( btn.options.originalLabel == ".Center") {
					historyPush( value );
					value = textField.text.substring(0, beginid) + '[div class="text-center"]'+( beginid >= endid?"":textField.text.substring( beginid, endid )) + "[/div]" + textField.text.substring( endid );
					tp = beginid + 25 + (endid > beginid ? (endid - beginid) : 0);
					stage.focus = textField;
					textField.setSelection( tp, tp );
				}else if( btn.options.originalLabel == ".Right") {
					historyPush( value );
					value = textField.text.substring(0, beginid) + '[div class="text-right"]'+( beginid >= endid?"":textField.text.substring( beginid, endid )) + "[/div]" + textField.text.substring( endid );
					tp = beginid + 234+ (endid > beginid ? (endid - beginid) : 0);
					stage.focus = textField;
					textField.setSelection( tp, tp );
				}else if( btn.options.originalLabel == ".Link") {
					// Get Link Window
					var win:Window = Window( Application.instance.window.GetStringWindow( "LinkWindow", agf.ui.Language.getKeyword("CT-Get-Link"), Language.getKeyword("CT-Get-Link-MSG"), {
					complete: function (str:String) {
						historyPush( value );
						value = textField.text.substring(0, beginid) + '[a href="'+str+'"]'+( beginid >= endid?"":textField.text.substring( beginid, endid )) + "[/a]" + textField.text.substring( endid );
						tp = beginid + 11 + str.length + (endid > beginid ? (endid - beginid) : 0);
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
			if( !TemplateEditor.clickScrolling ) {
				textField.removeEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				tfBtn.removeEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				
				textField.addEventListener( FocusEvent.FOCUS_OUT, onBoolDeactivate );
				
				textField.type = TextFieldType.INPUT;
				textField.setSelection( 0, textField.text.length );
				onActivate(null);
			}else{
				TemplateEditor.endClickScrolling();
			}
		}
		
		protected function boolButtonDoubleClickAbort () :void
		{
			if( !TemplateEditor.clickScrolling ) {
					textField.removeEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
					tfBtn.removeEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
					
					boolValue = tmp_bool_value;
					textEnter();
			}else{
				TemplateEditor.endClickScrolling();
			}
		}
		
		protected function boolButtonHandler ( e:MouseEvent ) :void
		{
			if( !TemplateEditor.clickScrolling ) {
				var v:String = value;
				
				if( v == boolNo) {
					tmp_bool_value = true;
				}else{
					tmp_bool_value = false;
				}
				
				textField.addEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				tfBtn.addEventListener( MouseEvent.MOUSE_DOWN, boolButtonDoubleClickHandler );
				
				setTimeout( boolButtonDoubleClickAbort, 353 );
			}else{
				TemplateEditor.endClickScrolling();
			}
		}
		public function boolIcon (v:Boolean) :void {
			tfBtn.clips = [ new IconFromFile(  (v ? Options.iconDir + CTOptions.urlSeparator + "toggle-on-btn.png" : Options.iconDir + CTOptions.urlSeparator + "toggle-off-btn.png"), Options.btnSize*1.25, Options.btnSize) ];
			tfBtn.init();
		}
		
		public function set boolValue (v:Boolean) :void {
			_boolValue = v;
			boolIcon(v);
			value = _boolValue ? boolYes : boolNo;
		}
		
		public function get boolValue ():Boolean {
			return _boolValue;
		}
		
		protected function onSelectColor ( e:MouseEvent ) :void {
			var tc:CssSprite = Application.instance.topContent
			var panel:CssSprite = Application.instance.view.panel;

			var cp:ColorPicker = ColorPicker(tc.getChildByName("color_picker"));
			if( cp ) {
				tc.removeChild(cp);
				textEnter();
				return;
			}
			var pw:int = panel.getWidth() * TemplateTools.editor_w;
			
			if( HtmlEditor.isPreviewOpen ) {
				pw = HtmlEditor.previewX;
			}
			
			colorPicker = new ColorPicker( pw, panel.getHeight(), tc, styleSheet, '', 'editor input-color-picker', false);
			colorPicker.name = "color_picker";
			colorPicker.setLabel( labelText );
			
			colorPicker.color = _color;
			colorPicker.x = 0;
			colorPicker.y = 0;
			
			if( CTOptions.animateBackground ) {
				HtmlEditor.dayColorClip( colorPicker.bgSprite );
			}
			
			if( colorPicker.y + colorPicker.cssSizeY > tc.getHeight() ) colorPicker.y = tc.getHeight() - colorPicker.cssSizeY;
			if( colorPicker.y < 0 ) colorPicker.y = 0;
			
			colorPicker.target = this;
			colorPicker.targetName = "setColorValue";
		}
		
		public function setColorValue ( c:uint ) :void {
			colorValue = c;
			drawCurrentColor();
			textEnter();
		}
			
		protected function sliderBegin ( e:Event ) :void {
			if( _type == "screennumber" || _type == "screeninteger" )
			{
				var s:String = textField.text;
				var c:int=s.length;
				for(var i:int=c-1; i>=0; i--) {
					if( !isNaN(Number(s.charAt(i))) ) {
						c = i;
						break;
					}
				}
				if( c != s.length ) {
					var num:String = s.substring( 0, c );
					var unit:String = s.substring( c+1 );
					StringMath.distFormat = unit;
				}
			}
		}
		
		protected function sliderChange ( e:Event ) :void {
			if( TemplateEditor.clickScrolling ) {
				TemplateEditor.abortClickScrolling();
			}
			if( tfSlider ) {
				var gr:Number;
				if( _type == "screennumber" || _type == "screeninteger" ) {
					if( sliderGrid != 0 ) {
						gr = sliderGrid;
						textField.text = "" + (Math.round( (_type=="integer" ? Math.round( StringMath.forceNumber( String(tfSlider.value))) : StringMath.forceNumber( String(tfSlider.value) )) / gr ) * gr).toFixed(decPlaces) + StringMath.distFormat;
					}else{
						textField.text = "" + ( _type == "integer" ? Math.round( StringMath.forceNumber(String(tfSlider.value)) ) : StringMath.forceNumber(String(tfSlider.value)) ) + StringMath.distFormat;
					}
				}else{
					if( sliderGrid != 0 ) {
						gr = sliderGrid;
						textField.text = "" + (Math.round( (_type=="integer" ? Math.round(tfSlider.value) : tfSlider.value) / gr ) * gr).toFixed(decPlaces);
					}else{
						textField.text = "" + ( _type == "integer" ? Math.round( tfSlider.value ) : tfSlider.value);
					}
				}
			}
		}

		public function vectorPlusClick ( e:MouseEvent ) :void {
			if( !TemplateEditor.clickScrolling ) {
				if( vectorTextFields && vectorContainer )
				{
					var vecObj:Object = {};
					
					CTTools.cloneTo( propObj, vecObj );
					var vecArgs:Array = [];
					if(vectorTextFields.length > 0) {
						var L:int=vectorTextFields[0].args.length;
						for(var i:int=0; i<L; i++) {
							// Not Dynmaic Type Vector
							vecArgs.push( vectorTextFields[0].args[i] );
						}
					}
					
					var tf:VectorTextField = new VectorTextField( vectorType, vecArgs, vecObj, '', cssWidth, cssHeight, vectorContainer, styleSheet, '', nodeClass, false );
					var yp:int = 0;
					tf.rootVector = this;
					if( vectorTextFields.length > 0) {
						tf.wrap = vectorTextFields[0].wrap;
						yp = vectorTextFields[ vectorTextFields.length - 1 ].y + vectorTextFields[ vectorTextFields.length-1].height;
					}
					var ev:InputEvent = new InputEvent( this, "add" );
					
					if( vectorCurrent == -1) {
						vectorTextFields.push( tf );
						ev.val = vectorTextFields.length;
					}else{
						vectorTextFields.splice( vectorCurrent, 0, tf );
						ev.val = vectorCurrent;
					}
					dispatchEvent( ev );
					
					tf.y = yp
					yp += tf.cssSizeY;

					setHeight( getHeight() + tf.cssSizeY );
					init();
					
					formatVector();
					dispatchEvent ( new Event("heightChange") );
					dispatchEvent( new Event("lengthChange") );
					textEnter();
				}
			}else{
				TemplateEditor.endClickScrolling();
			}
		}
		
		public function vectorMinusClick ( e:MouseEvent ) :void {
			if( !TemplateEditor.clickScrolling ) {
				if( vectorTextFields && vectorContainer )
				{
					var tf:VectorTextField;
					
					if( vectorCurrent == -1) {
						tf = vectorTextFields.pop();
					}else{
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
			}else{
				TemplateEditor.endClickScrolling();
			}
		}
		
		protected function sliderUp ( e:MouseEvent ) :void {
			if( tfSlider ) {
				sliderChange(null);
				textEnter();
			}
		}
		
		protected function ppListSelect ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			value = lb;
			textEnter();
		}
		
		protected function ppListAppendSelect ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			if( _type == "listmultiple" ) {
				if( Application.instance.shortcutMgr.shiftDown ) {
					value += listAppendSeparator + lb;
				}else{
					value = lb;
				}
			}else{
				value += listAppendSeparator + lb;
			}
			textEnter();
		}
		
		protected function ppScreenNumberSelect ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			
			var val:Number = StringMath.forceNumber( textField.text );
			var s:String = textField.text;
			var a:int;
			var ez:int = s.length;
			var num:String  = "";
			for(var i:int =0; i<s.length; i++) {
				// 0 - 9 || . 
				a = s.charCodeAt(i);
				if(a >= 40 && a <= 57 || a==69) {
					num += s.charAt(i);
				}else{
					ez = i;
					break;
				}
			}
			num = CssUtils.trim(num);
			var unit:String = CssUtils.trim( s.substring(ez) );
			
			if( unit == "%" && (lb == "vh" || lb == "vw") ) {
				num = String( Number(num)/*/100*/ );
			}else if( (unit == "vh" || unit == "vw") && lb == "%" ) {
				num = String( Number(num)/* *100*/ );
			}else if( unit == "px" && (lb == "rem" || lb == "em")) {
				num = String( Number(num)/16 );
			}else if( ( unit == "em" || unit == "rem" ) && lb == "px") {
				num = String( Number(num)*16 );
			}
			
			value = "" + num + lb;
			
			if(!isNaN(Number(num))) {
				tfSlider.value = Number(num);
			}
			// split text .. change unit..
		}
		
		
		protected function ppTypedSelect ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			
			tfPopup.label = lb;
			
			setWidth(getWidth());
			textEnter();
		}
		
		protected function ppLabelListSelect ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			value = curr.options.labelValue;
			textEnter();
		}
		protected function ppLabelListAppendSelect ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			
			if( _type == "labellistmultiple" || _type == "itemlistmultiple") {
				if( Application.instance.shortcutMgr.shiftDown ) {
					value += listAppendSeparator +  curr.options.labelValue;
				}else{
					value =  curr.options.labelValue;
				}
			}else{
				value += listAppendSeparator +  curr.options.labelValue;
			}
			textEnter();
		}
		public override function setWidth ( w:int ) :void {
			super.setWidth(w-cssBoxX);
			
			if(itemList) {
				itemList.x = w - (itemList.width) + 1;
				var H:int = textField.height;
				
				if( _type == "richtext" || _type == "text" || _type == "code" ) {
					textField.autoSize = TextFieldAutoSize.LEFT;
				}
				
				textField.width = w - ( textField.x + itemList.width + 8 );
				
				if( _type == "richtext" || _type == "text" || _type == "code" )
				{
					textField.autoSize = TextFieldAutoSize.NONE;
				
					if( textField.height !=  H )  {
						// autosize changed height..
						
						var m:TextLineMetrics = textField.getLineMetrics(0);
						
						setHeight( getHeight() + (textField.height-H) + m.ascent + m.descent + m.leading );
						dispatchEvent ( new Event("heightChange") );
					}
					if( htmlTextField ) {
						htmlTextField.width = textField.width;
					}
				}
				
			}else{
				if( tfBtn ) {
					textField.width = w-(tfBtn.cssSizeX+textField.x);
					tfBtn.x = textField.width + textField.x;
				}else if( tfPopup ) {
					textField.width = w-(tfPopup.cssSizeX+textField.x);
					tfPopup.x = textField.width + textField.x;
				}else if( colorClip ) {
					textField.width = w-(colorClip.width+textField.x);
					colorClip.x = textField.width + textField.x;
				}else{
					textField.width = w;
				}
				
				if( mediaInfo && mediaInfo.length > 0 ) {
					var fmt:TextFormat = mediaInfo.getTextFormat( 0, 1 );
					if( fmt && fmt.align == "right" ) {
						mediaInfo.x = getWidth() - mediaInfo.width;
					}
				}
			}
			if( vectorTextFields ) {
				var L:int = vectorTextFields.length;
				for(var i:int=0; i<L; i++) {
					vectorTextFields[i].setWidth( w );
				}
				if( vectorPlusButton && vectorMinusButton ) {
					vectorPlusButton.x = w - vectorPlusButton.cssSizeX-2;
					vectorMinusButton.x = vectorPlusButton.x - (2+vectorMinusButton.cssSizeX);
				}
			}
			if( tfSlider ) {
				tfSlider.setHeight( w ); 
			}
		}
		public override function setHeight ( h:int ) :void
		{
			if( itemList ) {
				if( h < itemList.height ) h = itemList.height;
			}
			
			if(_type=="image"||_type=="video") super.setHeight(h+mediaHeight);
			else super.setHeight(h);
			
			textField.height = h;
			var sld:int=2;
			if(tfSlider) {
				sld = tfSlider.getWidth();
				tfSlider.y = textField.height + int(sld / 2) + 1;
			}
			if(tfBtn) tfBtn.setHeight(h + cssBoxY - (sld));
			if(tfPopup) tfPopup.setHeight(h + cssBoxY - (sld));
			if( htmlTextField ) {
				htmlTextField.height = textField.height;
			}
		}
		
		public function get value () :String {
			return textField ? textField.text : "";
		}
		
		public function set value ( v:String ) :void {
			
			textField.text = v;
			
			if ( _type == "boolean" && tfBtn) {
				boolIcon( v == boolYes || CssUtils.stringToBool(v) );
			}
			
			if( tfSlider ) {
				if( _type == "number" ) 
					tfSlider.value = Number( v );
				else if( _type == "integer" ) 
					tfSlider.value = Math.round( Number(v) );
			}
		}
		
		private function textChange (e:Event) :void {
			if( _type == "richtext" || _type == "text" || _type == "code" ) {
				historyPush( textField.text );
			}
		}
		private var colorOfs:int=0;
		
		private function drawCurrentColor () :void {
			if( colorClip ) 
			{
				var ofs:int = colorOfs;
				
				colorClip.graphics.beginFill( 0, 0 );
				colorClip.graphics.drawRect(0, 2, Options.btnSize+ofs, textField.height );
				colorClip.graphics.endFill();
				
				colorClip.graphics.beginFill( this._color, 1 );
				colorClip.graphics.drawRect(0, 2, Options.btnSize, textField.height );
				colorClip.graphics.endFill();
			}
		}
		public function textEnter () :void
		{
			var v:String = value;
			if( trimValue ) v = CssUtils.trim(v);	
			if( trimQuotesValue ) v = CssUtils.trimQuotes(v);
			
			if( _type == "number" || _type=="screennumber" ){
				value = "" + StringMath.evaluate( v, decPlaces, _type == "screennumber" );
			}else if( _type == "integer" || _type=="screeninteger" ){
				value = "" + StringMath.evaluate( v, 1, _type == "screeninteger" );
			}else if( _type == "color" ){
				colorValue = v;
				drawCurrentColor();
			}else if( _type == "boolean" ){
				boolValue = v == boolYes || v == "1" || v.toLowerCase() == "true" ? true : false;
				textField.text = boolValue ? boolYes : boolNo;
			}else if( _type == "name" ){
				value = parseName(v);
			}else if( (_type == "vector" || _type == "vectorlink") && vectorTextFields && vectorTextFields.length > 0) {
				var str:String = "";
				var L:int = vectorTextFields.length;
				var vt:VectorTextField;
				for( var i:int = 0; i < L; i++) {
					vt = vectorTextFields[i];
					if( vt.type == "number" || vt.type=="screennumber" ){
						str += vectorSeparator + StringMath.evaluate( vt.value, 4, vt.type == "screennumber" );
					}else if( vt.type == "integer" || vt.type=="screeninteger" ){
						str += vectorSeparator + StringMath.evaluate( vt.value, 1, vt.type == "screeninteger" );
					}else{
						str += vectorSeparator + vt.value;
					}
				}
				
				textField.text = str.substring(1);
			}
			
			if( value != activateValue )
			{
				dispatchEvent( new Event(ENTER, false, true) );
			}
		}
		
		public function set colorValue (t:*) :void {
			
			if( t is String ) {
				if( String(t).charAt(1) == "x" || String(t).charAt(0) == "#" ) {
					displayMode = "hex";
				}else if( t.indexOf("gradient") >= 0 || t.indexOf("url(") >= 0 || t == "none" ) {
					return;
				}else if( isNaN(Number(t) ) ) {
					displayMode = "rgb";
				}
				
				_color = CssUtils.stringToColor(t);
			}else{
				_color = uint(t);
			}
			
			var r:int = _color >> 16 & 255;
			var g:int = _color >> 8 & 255;
			var b:int = _color & 255;
			
			if(displayMode == "hex") {
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
			}else{
				value = "rgb(" + r+ "," + g + "," + b + ")";
			}
		}
		
		public function get color () :int {
			return _color;
		}
		
		private function enterListener ( e:KeyboardEvent ) :void {
			if ( e.charCode == 13 ) {
  				if( stage && stage.focus ) {
					stage.focus = null; // call onDeactivate..
				}
			}
		}
		
		protected function onActivate (e:Event) :void {
			if( textField )
			{
				fmt = styleSheet.getTextFormat( stylesArray, "active"  );
				activateValue = value;
				
				textField.setTextFormat( fmt );
				
				if( stage && _type != "richtext" &&  _type != "text" && _type != "code" ) {
					stage.addEventListener( KeyboardEvent.KEY_DOWN, enterListener);
				}
				if(this is VectorTextField) {
					VectorTextField(this).rootVector.setCurrVector(this);
				}
				swapState( "active" );
			}
			setTimeout( TemplateEditor.abortClickScrolling, 0);
		}
		
		public function setCurrVector( tf:InputTextBox ) :void {
			if( vectorTextFields ) {
				var id:int = vectorTextFields.indexOf(tf);
				if(id>=0) {
					vectorCurrent = id;
				}
				if(this is VectorTextField) {
					VectorTextField(this).rootVector.vectorCurrent = -1;
				}
			}
		}
		
		protected function onBoolDeactivate (e:Event) :void {
			textField.removeEventListener( FocusEvent.FOCUS_OUT, onBoolDeactivate );
			onDeactivate( null );
		}
		
		protected function onDeactivate (e:Event) :void 
		{
			textEnter();
			
			if( textField ) {
				fmt = styleSheet.getTextFormat( stylesArray, "normal");
				textField.setTextFormat( fmt );
				if( stage ) {
					if(_type != "richtext" && _type != "text" && _type != "code" ) {
						stage.removeEventListener( KeyboardEvent.KEY_DOWN, enterListener);
					}
				}
				swapState( "normal" );
			}
		}
		
		private function selectDirectory (e:MouseEvent) :void{
			var directory:File;
			if( lastSelectedFiles[this.name] != null ) directory = new File( lastSelectedFiles[this.name] );
			else if( lastSelectedFiles["_lastdir"] != null ) directory = new File( lastSelectedFiles["_lastdir"] );
			else directory = File.documentsDirectory;
			
			try {	
				directory.browseForDirectory("Select Directory");
				directory.addEventListener(Event.SELECT, dirSelected);
			}catch (error:Error){
				//trace("Failed:", error.message);
			}
		}
		private function dirSelected (event:Event) :void {
			var directory:File = event.target as File;
			lastSelectedFiles[this.name] = directory.url;
			lastSelectedFiles["_lastdir"] = directory.url;
			textField.text = directory.url;
			textEnter();
		}
		
		private function selectFile (e:MouseEvent) :void {
			// Get Files from User
			var docsDir:File;
			
			if( lastSelectedFiles[this.name] != null ) docsDir = new File( lastSelectedFiles[this.name] );
			else if( lastSelectedFiles["_lastdir"] != null ) docsDir = new File( lastSelectedFiles["_lastdir"] );
			else docsDir = File.documentsDirectory;
			
			var flt:FileFilter = null;
			if( allowed_extensions ) {
				flt = new FileFilter( Language.getKeyword(fileFilterDescription), allowed_extensions );
			}else{
				flt = new FileFilter( Language.getKeyword(fileFilterDescription), "*.*");
			}
			try {
				docsDir.browseForOpen("Select File", [flt]);
				docsDir.addEventListener(FileListEvent.SELECT_MULTIPLE, fileSelected);
			}catch (error:Error){
				Console.log("Select file error: " + error.message);
			}
		}
		private function selectFiles (e:MouseEvent) :void {
			var docsDir:File;
			if( lastSelectedFiles[this.name] != null ) docsDir = new File( lastSelectedFiles[this.name] );
			if( lastSelectedFiles["_lastdir"] != null ) docsDir = new File( lastSelectedFiles["_lastdir"] );
			else docsDir = File.documentsDirectory;
			
			var flt:FileFilter = null;
			if( allowed_extensions ) {
				flt = new FileFilter( Language.getKeyword(fileFilterDescription), allowed_extensions );
			}else{
				flt = new FileFilter( Language.getKeyword(fileFilterDescription), "*.*");
			}
			try {
				docsDir.browseForOpenMultiple("Select Files", [flt]);
				docsDir.addEventListener(FileListEvent.SELECT_MULTIPLE, filesSelected);
			}catch (error:Error){
				Console.log("Select files error: " + error.message);
			}
		}
		
		// File browser handler
		private function fileSelected (event:FileListEvent) :void {
			textField.text = event.files[0].url;
			lastSelectedFiles[this.name] = event.files[0].parent.url;
			lastSelectedFiles["_lastdir"] = lastSelectedFiles[this.name];
			
			textEnter();
			
			if( _type == "image") {
				reloadImage();
			}
			
		}
		
		// File browser handler
		private function filesSelected (event:FileListEvent) :void {
			var str:String = event.files[0].url;
			
			lastSelectedFiles[this.name] = event.files[0].parent.url;
			lastSelectedFiles["_lastdir"] = lastSelectedFiles[this.name];
			
			if( event.files.length > 1 ) {
				for (var i:uint = 1; i < event.files.length; i++) {
					str += "," + event.files[i].url;
				}
			}
			
			textField.text = str;
			if( _type == "image") {
				reloadImage();
			}
			textEnter();
		}
		public function reloadImage () :void {
			if( _type == "image") {	
				if( mediaContainer && contains(mediaContainer)) removeChild( mediaContainer );
				
				var v:String = textField.text;
				
				if( v != "" && v.toLowerCase() != "none") {
					mediaContainer = new Sprite();
					mediaContainer.y = textField.height + 5;
					mediaContainer.x = 3;
					addChild(mediaContainer);
					
					loadImage( v );
				}
			}
		}
		private function initDragNDrop ( tgt:InteractiveObject ) :void {
			_tgt = tgt;
			_tgt.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,_onDragIn);
			_tgt.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT,_onDragOut);
			_tgt.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,_onDrop);
		}
 		
		public function _onDragIn(event:NativeDragEvent) :void {
			NativeDragManager.acceptDragDrop(_tgt);
			swapState("active");
		}
		
		public function _onDragOut(event:Event) :void {
			NativeDragManager.acceptDragDrop(_tgt);
			swapState("normal");
		}
		public function _onDrop(event:NativeDragEvent) :void {
			NativeDragManager.dropAction = NativeDragActions.COPY;
			var dropfiles:Array = event.clipboard.formats;
			var df:Array;
			for each (var tp:String in dropfiles) {
				if( tp == ClipboardFormats.FILE_LIST_FORMAT ) {
					 df = event.clipboard.getData(tp) as Array;
					 var path:String;
					 for(var i:int = 0; i < df.length; i++) {
						 textField.text = File(df[i]).url;
						 lastSelectedFiles[this.name] = File(df[i]).parent.url;
						 lastSelectedFiles["_lastdir"] = lastSelectedFiles[this.name];
						
						 if( _type == "image") {
							reloadImage();
						 }
						  textEnter();
						 return;
					 }
				 }
			}
		}
		
	}
}