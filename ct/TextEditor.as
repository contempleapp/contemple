 package ct
{
	import agf.utils.StringMath;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.events.MouseEvent;
	import flash.utils.getTimer;
	import flash.geom.Rectangle;
	import agf.Main;
	import agf.Options;
	import agf.ui.*;
	import agf.html.*;
	import agf.tools.*;
	import agf.icons.IconWindowDrag;
	import agf.icons.IconWindowClose;
	import agf.icons.IconFromFile;
	import agf.events.PopupEvent;
	import net.anirudh.as3syntaxhighlight.CodePrettyPrint;
	
	public class TextEditor extends Sprite
    {
		public function TextEditor()
		{
			codeFormat = new CodePrettyPrint();
			codeStyleSheet = new StyleSheet();
            
            var styles:Object = Application.instance.config.getMultiStyle( [".textview"] );
            var fnt:String;
            var size:uint;
            
            if( styles.fontFamily ) {
                fnt = CssUtils.parseFontFamily( styles.fontFamily );
            }else{
                fnt = Console.DEFAULT_FONT;
            }
			
            if( styles.fontSize ) {
                size = parseInt(styles.fontSize);
            }else{
                size = Console.DEFAULT_TEXT_SIZE;
            }
			
            if( CTOptions.debugOutput ) Console.log("Editor View Font: " + fnt);
            
			codeStyleSheet.parseCSS( ' p,span { font-family:"'+fnt+'"; font-size:'+size+'px; } ' + CTOptions.codeColorStyle );
			
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			
			try {
				Panel( container ).viewType = "TextView";
			}catch(e:Error) {
				var err:String;
			}
			
			create();
			
			if( CTOptions.isMobile && CTOptions.softKeyboard ) {
				tf.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_ACTIVATE, CTTools.softKeyboardChange );
				tf.addEventListener( SoftKeyboardEvent.SOFT_KEYBOARD_DEACTIVATE, CTTools.softKeyboardChange );
			}
			
			displayFiles();
		}
		private var tmpH:Number=0;
		
		public var container: Panel;
		public var ib: ItemBar;
		public var tf: TextField;
		public var fmt: TextFormat;
		
		private var offset_x:Number = 0;
		private var dragging: Boolean = false;
		private var dragObj: Button;
		private var oldIndex: int = -1;
		private var newIndex: int = -1;
		private var startClickTime: uint = 0;
		private var startDragAfter: uint = 750;
		private var codeStyleSheet:StyleSheet;
		private var codeFormat:CodePrettyPrint;
		private var pp:Popup;
		private var optionsPopup:Popup;
		private var undoButton:Button;
		private var redoButton:Button;
		
		private var scrollbar:Slider;
		
		public var history:Vector.<Object> = new Vector.<Object>();
		public var future:Vector.<Object> = new Vector.<Object>();
		
		private var typeTimer:uint = 0;
		private var lastUndo:uint = 0;
		private var releaseTime:int = 1750; // max time between two keypress to store history
		
		public function historyPop () :Object {
			var obj:Object = history.pop();
			return obj;
		}
		public function historyPush ( v:String, file:int=-1 ) :void {
			history.push( {file:file == -1 ? CTTools.currFile : file, val:v} );
			if ( history.length > CTOptions.textEditorUndos ) history.shift();
		}
		public function futurePop () :Object {
			var obj:Object = future.pop();
			return obj;
		}
		public function futurePush ( v:String, file:int=-1 ) :void {
			future.push( {file:file ==-1?CTTools.currFile:file, val:v} );
		}
		
		public function newSize(e: Event): void {
			if (tf && container) {
				var w:int = container.getWidth();
				var h:int = container.getHeight();
				var ibh: Number = ib.getHeight();
				var sbw:int = 0;
				
				if(scrollbar) {
					
					scrollbar.setHeight( h - (ibh + 8) );
					sbw = scrollbar.cssSizeX + scrollbar.cssBoxX;
					scrollbar.x = w - (sbw + 4);
					scrollbar.y = ibh + 4;
					setScrollButtonHeight();
					
					if( scrollbar.value != tf.scrollV ) scrollbar.value = tf.scrollV;
				}
					
				tf.width = w - (8 + sbw);
				tf.height = h - (8 + ibh);
				tf.x = 3;
				tf.y = 8 + ibh;
				ib.setWidth( w );
				
				container.setChildIndex( scrollbar, container.numChildren-1 );
				
				displayFiles();
			}
		}
		
		private function setScrollButtonHeight () :int
		{
			var mss:int = 50;
			if( ib && container && tf && scrollbar )
			{
				if( tf.maxScrollV <= 1 ) {
					scrollbar.visible = false;
				}else{
					scrollbar.visible = true;
					
					scrollbar.minValue = 1;
					scrollbar.maxValue = tf.maxScrollV;
					
					var h:int = container.getHeight();
					var ibh: Number = ib.getHeight();
					
					if( tf.maxScrollV < h - (ibh + mss) ) {
						mss = h-(ibh + tf.maxScrollV);
					}
					mss = int(mss/1.62);
					scrollbar.setScrollerHeight( mss );
				}
			}
			return mss;
		}
		
		private function textEnterFrame (e:Event) :void
		{
			if ( lastUndo != typeTimer )
			{
				var time:int = getTimer();
				
				if( time - typeTimer > releaseTime ) {
					historyPush( tf.text );
					lastUndo = typeTimer;
				}
			}
			if ( textActive ) {
				cursor1 = tf.selectionBeginIndex;
				cursor2 = tf.selectionEndIndex;
			}
		}
		
		private function sbHChange (e:Event) :void {
			tf.scrollV = scrollbar.value;
		}
		
		private function textScrolled (e:Event) :void {
			if( scrollbar ) {
				scrollbar.value = tf.scrollV;
			}
		}
		
		private function textChanged (e:Event) :void
		{
			if( CTTools.showTemplate && CTTools.currFile != -1 && CTTools.procFiles && CTTools.procFiles.length > CTTools.currFile )
			{	
				typeTimer = getTimer();
				ProjectFile( CTTools.procFiles[CTTools.currFile] ).setTemplate( tf.text );
				scrollbar.maxValue = tf.maxScrollV;
			}
		}

		private function create () :void
		{
			if (!tf){
				tf = new TextField();
				tf.addEventListener( Event.CHANGE, textChanged);
			}
			if (!contains(tf)) addChild(tf);
			
			if (!ib) ib = new ItemBar(0, 0, container, container.styleSheet, '', 'filebuttons', false);
			if (!contains(ib)) addChild(ib);
			
			if ( !scrollbar ) {
				scrollbar = new Slider(0, 0, container, container.styleSheet, '', 'code-scrollbar', false);
				scrollbar.friction = 2.5;
				scrollbar.addEventListener( Event.CHANGE, sbHChange );
				scrollbar.setWidth( Math.ceil(Options.btnSize / 2) );
			}
			
			ib.margin = 0;
            tf.embedFonts = Options.embedFonts;
            tf.antiAliasType = Options.antiAliasType;
			
            var styles:Object = container.styleSheet.getMultiStyle( [".texteditor"] );
            var fnt:String;
            var color:uint;
            var size:uint;
            
            if( styles.fontFamily ) {
                fnt = CssUtils.parseFontFamily( styles.fontFamily );
            }else{
                fnt = Console.DEFAULT_FONT;
            }
            
            if( styles.color ) {
                color = CssUtils.parse(styles.color);
            }else{
                color = Console.DEFAULT_TEXT_COLOR;
            }
            
            if( styles.fontSize ) {
                size = parseInt(styles.fontSize);
            }else{
                size = Console.DEFAULT_TEXT_SIZE;
            }
            
			if (!fmt) {
                fmt = new TextFormat(fnt, size, color); 
            }else{
                fmt.font = fnt;
                fmt.size = size;
                fmt.color = color;
            }
			
			fmt.leading = 1;
            
            if( styles.fontWeight && styles.fontWeight == "bold" ) {
                fmt.bold = true;
            }
			
			tf.multiline = true;
			tf.background = true;
            
            if( styles.backgroundColor ) {
                tf.backgroundColor = CssUtils.parse( styles.backgroundColor );
            }else{
                tf.backgroundColor = 0xFFFFFF;
            }
            
			tf.selectable = true;
			tf.wordWrap = true;
			tf.type = TextFieldType.INPUT;
			tf.text = "";
			tf.setTextFormat(fmt);
			
			container.setChildIndex( scrollbar, container.numChildren-1 );
			
			newSize(null);
		}
		
		private var textActive:Boolean = false;
		protected function onDeactivate (e:Event) :void 
		{
			textActive = false;
		}
		
		protected function onActivate (e:Event) :void {
			textActive = true;
		}
		
		private var cursor1:int = -1;
		private var cursor2:int = -1;
		
		private function updateText(): void
		{
			if( CTTools.procFiles )
			{
				var pf:ProjectFile = ProjectFile( CTTools.procFiles[CTTools.currFile] );
				tf.removeEventListener( Event.CHANGE, textChanged);
				tf.removeEventListener( Event.ENTER_FRAME, textEnterFrame);
				optionsPopup.visible = undoButton.visible = redoButton.visible = false;
				
				textActive = false;
				
				if( pf )
				{
					if( CTTools.showTemplate )
					{
						tf.text = "";
						tf.type = TextFieldType.INPUT;
						tf.styleSheet = null;
						tf.defaultTextFormat = fmt;
						tf.text = pf.getTemplate();
						lastUndo = typeTimer = 0;
						
						if ( history && !(history.length > 0 && history[ history.length - 1 ] == tf.text) ) {
							lastUndo = typeTimer;
							historyPush( tf.text );
						}
						
						tf.addEventListener( Event.ENTER_FRAME, textEnterFrame);
						tf.addEventListener( FocusEvent.FOCUS_IN, onActivate);
						tf.addEventListener( FocusEvent.FOCUS_OUT, onDeactivate );
						optionsPopup.visible = undoButton.visible = redoButton.visible = true;
					}
					else
					{
						if( CTOptions.textEditorCodeColoring ) {
							var colText:String = codeFormat.prettyPrintOne( CTTools.showCompact ? pf.getCompact() : pf.getText(), pf.extension, true );
							tf.type = TextFieldType.DYNAMIC;
							tf.styleSheet = codeStyleSheet;
							tf.htmlText = "<body><textfield><p>"+colText+"</p></textfield></body>";
						}else{
							tf.text = "";
							tf.type = TextFieldType.DYNAMIC;
							tf.styleSheet = null;
							tf.defaultTextFormat = fmt;
							tf.text = CTTools.showCompact ? pf.getCompact() : pf.getText();
						}
					}
				}else{
					tf.type = TextFieldType.DYNAMIC;
					tf.text = "";
					tf.styleSheet = null;
					tf.defaultTextFormat = fmt;
					tf.text = "";
				}
				
				tf.addEventListener( Event.CHANGE, textChanged );
				tf.addEventListener( Event.SCROLL, textScrolled );
				
				setScrollButtonHeight();	
			}
		}
		
		public function displayFiles () :void
		{
			if( pp ) {
				if( container.contains( pp ) ) container.removeChild(pp);
				pp = null;
			}
			if( optionsPopup ) {
				if( container.contains( optionsPopup ) ) container.removeChild(optionsPopup);
				optionsPopup = null;
			}
			
			if ( undoButton ) {
				if( container.contains( undoButton ) ) container.removeChild(undoButton);
				undoButton = null;
			}
			if ( redoButton ) {
				if( container.contains( redoButton ) ) container.removeChild(redoButton);
				redoButton = null;
			}
			
			if (CTTools.procFiles) {

				var files: Array = CTTools.procFiles;

				// Display first file
				if (CTTools.currFile == -1) CTTools.currFile = 0;
				
				ib.x = 0;
				ib.y = 0;
				ib.clearAllItems();
				
				var px:Number = offset_x;
				
				undoButton = new Button([ new IconFromFile(Options.iconDir+CTOptions.urlSeparator+"reply.png",Options.iconSize,Options.iconSize) ], 0, 0, container, ib.styleSheet, '', 'file-undo-button', false);
				undoButton.addEventListener( MouseEvent.CLICK, undoClick );
				
				redoButton = new Button([ new IconFromFile(Options.iconDir+CTOptions.urlSeparator+"forward.png",Options.iconSize,Options.iconSize) ], 0, 0, container, ib.styleSheet, '', 'file-undo-button', false);
				redoButton.addEventListener( MouseEvent.CLICK, redoClick );
				
				var pi:PopupItem;
				optionsPopup = new Popup( [ new IconFromFile(Options.iconDir+CTOptions.urlSeparator+"create.png",Options.iconSize,Options.iconSize) ], 0, 0, container, ib.styleSheet, '', 'fileoptions', false);
				optionsPopup.addEventListener( Event.SELECT, fileOptionsSelect );
				pi = optionsPopup.rootNode.addItem( ["Content Area"], container.styleSheet);
				pi.options.value = '{##AreaName("ico:/ufo.png"):content}';
				pi = optionsPopup.rootNode.addItem( ["Linked Area"], container.styleSheet);
				pi.options.value = '{##LinkAreaName("ico:/services.png","",0,3,"Another-Area","SubTemplate1","LinkSubtemplate1"):content}';
				pi = optionsPopup.rootNode.addItem( ["Subtemplate Area"], container.styleSheet);
				pi.options.value = '{#MyArea:Area("#itemname#","content")}';
				pi = optionsPopup.rootNode.addItem( ["#separator"], container.styleSheet);
				pi = optionsPopup.rootNode.addItem( ["Label"], container.styleSheet);
				pi.options.value = '{#MyLabel:Label("text")}';
				pi = optionsPopup.rootNode.addItem( ["Section"], container.styleSheet);
				pi.options.value = '{#MySection:Section("text")}';
				pi = optionsPopup.rootNode.addItem( ["Folder"], container.styleSheet);
				pi.options.value = '{#MyFolder:Folder}';
				pi = optionsPopup.rootNode.addItem( ["Tab"], container.styleSheet);
				pi.options.value = '{#MyTab:Tab}';
				pi = optionsPopup.rootNode.addItem( ["#separator"], container.styleSheet);
				pi = optionsPopup.rootNode.addItem( ["AreaList"], container.styleSheet);
				pi.options.value = '{#MyAreas:AreaList}';
				pi = optionsPopup.rootNode.addItem( ["Audio"], container.styleSheet);
				pi.options.value = '{#MyAudio:Audio("directory","mp3-#INPUTNAME#.#EXTENSION#","MP3 Files:","*.MP3;")}';
				pi = optionsPopup.rootNode.addItem( ["Color"], container.styleSheet);
				pi.options.value = '{#MyColor:Color="#07F"}';
				pi = optionsPopup.rootNode.addItem( ["File"], container.styleSheet);
				pi.options.value = '{#MyFile:File("directory","file-#INPUTNAME#.#EXTENSION#","Files:","*.FF1;*.FF2;")}';
				pi = optionsPopup.rootNode.addItem( ["Image"], container.styleSheet);
				pi.options.value = '{#MyImage:Image("directory","img-#INPUTNAME#.#EXTENSION#","Image Files:","*.PNG;*.JPG;*.GIF;")}';
				pi = optionsPopup.rootNode.addItem( ["Integer"], container.styleSheet);
				pi.options.value = '{#MyInt:Integer(0,100,1)=100}';
				pi = optionsPopup.rootNode.addItem( ["Number"], container.styleSheet);
				pi.options.value = '{#MyNumber:Number(0,1,0.1)=1}';
				pi = optionsPopup.rootNode.addItem( ["Plugin"], container.styleSheet);
				pi.options.value = '{#MyPlugin:Plugin("Plugin-ID",plugin-arguments...)="default-value"}';
				pi = optionsPopup.rootNode.addItem( ["ScreenInteger"], container.styleSheet);
				pi.options.value = '{#MyScreenInt:ScreenInteger(0,100,1)="100px"}';
				pi = optionsPopup.rootNode.addItem( ["ScreenNumber"], container.styleSheet);
				pi.options.value = '{#MyScreenNumber:ScreenNumber(0,1,0.1)="1em"}';
				pi = optionsPopup.rootNode.addItem( ["Number Vector"], container.styleSheet);
				pi.options.value = '{#MyVector:Vector(0,Number,"#vectorvalue#,",",",true)="1,2,3"}';
				pi = optionsPopup.rootNode.addItem( ["String Vector"], container.styleSheet);
				pi.options.value = '{#MyVector:Vector(0,String,"<p>|</p>",",",true)="a,b"}';
				pi = optionsPopup.rootNode.addItem( ["Video"], container.styleSheet);
				pi.options.value = '{#MyVideo:Video("directory","video-#INPUTNAME#.#EXTENSION#","Video Files:","*.MP4;")}';
				
				pi = optionsPopup.rootNode.addItem( ["#separator"], container.styleSheet);
				pi = optionsPopup.rootNode.addItem( ["Random"], container.styleSheet);
				pi.options.value = '{#r:random(2)}';
				
				pp = new Popup( [ new agf.icons.IconMenu(0xEEEFFF,1,10, 10) ], 0, 0, container, ib.styleSheet, '', 'filepopup', false);
				pp.addEventListener( Event.SELECT, filePopupSelect );
				
				var pf:ProjectFile;
				var btarr:Array;
				var fileIcon:Boolean = false;
				var iconClose:Boolean = true;
				
				if( CTOptions.textEditorAllowClose || CTOptions.textEditorAllowDrag ) {
					fileIcon = true;
					if( !CTOptions.textEditorAllowClose ) iconClose = false;
				}
				
				if (files && files.length)
				{
					var bt: Button;
					
					for (var i: int = 0; i < files.length; i++)
					{
						pf = ProjectFile( files[i] );
						
						pi = pp.rootNode.addItem( [pf.filename], pp.styleSheet );
						pi.nodeClass = "filepopupitem";
						
						if(CTTools.showTemplate && fileIcon ) {
							btarr = [ (iconClose ? new IconWindowClose(0x333333, 1, 6, 6) : new IconWindowDrag(0x333333, 1, 6, 6)), pf.filename];
						}else{
							btarr = [pf.filename];
						}
						bt = new Button(btarr, 0, 0, ib, ib.styleSheet, '', 'filebutton', false);
						bt.y = ib.cssTop;
						bt.margin = 3;
						
						bt.name = "" + i;
						bt.addEventListener(MouseEvent.CLICK, fileButtonClick);
						if( CTTools.showTemplate && fileIcon ) {
							bt.contLeft.mouseEnabled = bt.contLeft.mouseChildren = true;
							bt.contLeft.addEventListener(MouseEvent.MOUSE_OVER, fileCloseOver);
							bt.contLeft.addEventListener(MouseEvent.MOUSE_OUT, fileCloseOut);
							bt.contLeft.addEventListener(MouseEvent.MOUSE_DOWN, fileCloseDown);
						}
						bt.autoSwapState = "";
						
						if (i == CTTools.currFile) {
							bt.swapState("active");
						} else {
							bt.swapState("normal");
						}
					
						ib.addItem(bt, true);
						
						bt.x = px;
						px += Math.ceil( bt.width );
						
					} // for files
					
					optionsPopup.setHeight( bt.getHeight() );
					optionsPopup.x =  container.getWidth() - (optionsPopup.cssSizeX + pp.cssSizeX + undoButton.cssSizeX + redoButton.cssSizeX - 33);
					optionsPopup.y = ib.cssTop;
					optionsPopup.textAlign = "right";
					optionsPopup.alignH = "right";
					optionsPopup.alignV = "bottom";
					
					undoButton.setHeight( bt.getHeight() );
					undoButton.x = container.getWidth() - (optionsPopup.cssSizeX + pp.cssSizeX + redoButton.cssSizeX - 22);
					undoButton.y = ib.cssTop;
					
					redoButton.setHeight( bt.getHeight() );
					redoButton.x = container.getWidth() - (optionsPopup.cssSizeX + pp.cssSizeX - 11);
					redoButton.y = ib.cssTop;
					
					pp.setHeight( bt.getHeight() );
					pp.x = container.getWidth() - pp.cssSizeX;
					pp.y = ib.cssTop;
					pp.textAlign = "right";
					pp.alignH = "right";
					pp.alignV = "bottom";
					
				}else{
					container.removeChild(pp);
				}
				
				if (tf && container) {
					var ibh: Number = ib.getHeight();
					tf.width = container.getWidth() - 8;
					tf.height = container.getHeight() - (8 + ibh);
					tf.x = 3;
					tf.y = 8 + ibh;
					ib.setWidth(container.getWidth());
				}

				updateText();
				ib.swapState("hover");
			}
		}
		
		private function undoClick (e:MouseEvent) :void {
			undoAction();
		}
		
		private function redoClick (e:MouseEvent) :void {
			redoAction();
		}
		
		private function undoAction () :void {
			var obj:Object = historyPop();
			
			if ( obj && obj.file >= 0 )
			{
				var obj2:Object = historyPop();
				if ( !obj2 ) {
					// first
					if ( obj.file < CTTools.procFiles.length ) {
						CTTools.procFiles[ obj.file ].setTemplate( obj.val );
					}
					setCurrentFile( obj.file );
				}
				else
				{
					futurePush( obj.val, obj.file );
					if ( obj2.file < CTTools.procFiles.length ) {
						CTTools.procFiles[ obj2.file ].setTemplate( obj2.val );
					}
					setCurrentFile( obj2.file );
				}
			}
				
		}
		
		private function redoAction () :void {
			var obj:Object = futurePop();
			
			if ( obj && obj.file >= 0 )
			{
				var obj2:Object = futurePop();
				
				if ( !obj2 )
				{
					// first
					if ( obj.file < CTTools.procFiles.length ) {
						CTTools.procFiles[ obj.file ].setTemplate( obj.val );
					}
					setCurrentFile( obj.file );
				}
				else
				{
					historyPush( obj.val, obj.file );
					
					if ( obj2.file < CTTools.procFiles.length ) {
						CTTools.procFiles[ obj2.file ].setTemplate( obj2.val );
					}
					setCurrentFile( obj2.file );
				}
			}
				
		}
		
		private function fileOptionsSelect (e:PopupEvent) :void
		{	
			if ( CTTools.showTemplate && CTTools.currFile != -1 && CTTools.procFiles && CTTools.procFiles.length > CTTools.currFile )
			{
				var val:String = e.selectedItem.options.value;
				
				var ds:int = tf.text.lastIndexOf("#def:", cursor1);
				
				if ( ds >= 0 )
				{
					var de:int = tf.text.indexOf("#def;", ds);
					if ( de >= 0 && de > cursor1 )
					{
						val = val.substring(2, val.length - 1) + ";\n";
					}
				}
				var s:String =  tf.text.substring(0, cursor1) + val + tf.text.substring(cursor1);
				
				historyPush( tf.text );
				tf.text = s;
				ProjectFile( CTTools.procFiles[CTTools.currFile] ).setTemplate( s );
			}
		}
		
		private function filePopupSelect (e:PopupEvent) :void {
			
			setCurrentFile( e.currentPopup.rootNode.children.indexOf( e.selectedItem ) );
			
			if( CTTools.currFile >= 0 ) {
				
				var bt:Button = Button(ib.getChildByName( "" + CTTools.currFile) );
				if( bt ) {
					if( CTTools.currFile == 0 ) offset_x = 0;
					else offset_x = - bt.x + bt.getWidth() + offset_x;
				}
				displayFiles();
			}
		}
		
		private function fileCloseDown(e: MouseEvent): void
		{
			dragging = false;
			dragObj = Button(Sprite(e.currentTarget).parent);
			startClickTime = getTimer();
			stage.addEventListener(MouseEvent.MOUSE_MOVE, fileCloseStageMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, fileCloseStageUp);
		}
		
		private function fileCloseStageMove (e: MouseEvent): void {
			if (!dragging) {
				if ( getTimer() - startClickTime > startDragAfter ) {
					// Initialize Drag
					dragging = true;
					dragObj.swapState("normal");
					dragObj.alpha = 0.5;
					newIndex = -1;
					oldIndex = ib.removeItem(dragObj, true);
					Main(Application.instance).topContent.addChild(dragObj);
				}
			}
			else
			{
				dragObj.x = Main(Application.instance).topContent.mouseX;
				dragObj.y = Main(Application.instance).topContent.mouseY;
				var L: int = ib.numItems;
				var i:int;
				for (i = 0; i < L; i++) {
					Button( ib.getItemAt( i ) ).alpha = 1;
				}
				newIndex = -1;
				for (i = 0; i < L; i++) {

					if (dragObj.hitTestObject(ib.getItemAt(i)))
					{
						Button( ib.getItemAt( i ) ).alpha = 0.5;
						newIndex = i;
						break;
					}
				}
			}
		}

		private function fileCloseStageUp(e: MouseEvent): void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, fileCloseStageMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, fileCloseStageUp);
			
			if( !dragging ) {
				if( CTOptions.textEditorAllowClose ) { 
					CTTools.deleteFileAt(uint(Number(dragObj.name)));
				}
				e.stopPropagation();
			}
			else
			{
				dragObj.alpha = 1;
				dragging = false;
				
				var tc: Sprite = Sprite(Main(Application.instance).topContent);
				if (tc.contains(dragObj)) tc.removeChild(dragObj);

				CTTools.reorder(oldIndex, newIndex);

				displayFiles();

				oldIndex = -1;
				newIndex = -1;
				dragObj = null;
			}
		}

		private function fileCloseOver(e: MouseEvent): void {
			Sprite(e.currentTarget).alpha = .7;
		}
		private function fileCloseOut(e: MouseEvent): void {
			Sprite(e.currentTarget).alpha = 1;
		}

		private function fileCloseClick(e: MouseEvent): void {
			if( CTOptions.textEditorAllowClose ) {
				CTTools.deleteFileAt(uint(Number(dragObj.name)));
			}
			e.stopPropagation();
		}
		
		public function setCurrentFile ( id:int ) :void {
		
			if( CTTools.procFiles )
			{
				if( id >= 0 && id < CTTools.procFiles.length)
				{
					var cb: Button = Button(ib.getChildByName("" + CTTools.currFile));
					
					if (cb) {
						cb.swapState("normal");
						cb.autoSwapState = "all";
					}
					CTTools.currFile = id;

					cb = Button(ib.getChildByName("" + CTTools.currFile));
					if (cb) {
						cb.swapState("active");
						cb.autoSwapState = "";
					}
					updateText();
				}
			}
		}
			
		private function fileButtonClick(e: MouseEvent): void {
			setCurrentFile( int(e.currentTarget.name) ); 
		}
	}

}