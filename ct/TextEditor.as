package ct
{
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
	import agf.events.PopupEvent;
	import net.anirudh.as3syntaxhighlight.CodePrettyPrint;
	
	/**
	* TextEditor and CodeView
	* TODO: 
	* - add scrollbars
	* - add goto menu for template objects, js-functions and css - classes
	* - add some code completion functionality also for fast mobile - editing
	* - fix bugs when changing file in the editor
	**/
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
                size = CssUtils.parse(styles.fontSize);
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
			displayFiles();
		}
		
        
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
		private var scrollbar:Slider;
		
		public function newSize(e: Event): void {
			if (tf && container) {
				var w:int = container.getWidth();
				var h:int = container.getHeight();
				
				var sbw:int = 0;
				if(scrollbar){
					scrollbar.setHeight( w );
					scrollbar.x = w - scrollbar.cssSizeX;
				}
				var ibh: Number = ib.getHeight();
				tf.width = w - (8 + sbw);
				tf.height = h - 8 - ibh;
				tf.x = 3;
				tf.y = 8 + ibh;
				ib.setWidth( w );
				displayFiles();
			}
		}
		
		private function textChanged (e:Event) :void
		{
			if( CTTools.showTemplate && CTTools.currFile != -1 && CTTools.procFiles && CTTools.procFiles.length > CTTools.currFile )
			{
				ProjectFile( CTTools.procFiles[CTTools.currFile] ).setTemplate( tf.text );
				scrollbar.maxValue = tf.numLines;
			}
		}

		private function create(): void {
			if (!tf){
				tf = new TextField();
				tf.addEventListener( Event.CHANGE, textChanged);
			}
			if (!contains(tf)) addChild(tf);
			
			if (!ib) ib = new ItemBar(0, 0, container, container.styleSheet, '', 'filebuttons', false);
			if (!contains(ib)) addChild(ib);
			
			if ( !scrollbar ) {
				scrollbar = new Slider(0, 0, container, container.styleSheet, '', 'text-scrollbar', false);
				scrollbar.minValue = 0;
				scrollbar.maxValue = tf.numLines;
				scrollbar.setScrollerHeight( 50 );
				scrollbar.setWidth( ScrollContainer.scrollbarWidth );
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
                size = CssUtils.parse(styles.fontSize);
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
			newSize(null);
		}
		
		private function updateText(): void {
			if( CTTools.procFiles )
			{
				var pf:ProjectFile = ProjectFile( CTTools.procFiles[CTTools.currFile] );
				tf.removeEventListener( Event.CHANGE, textChanged);
				if( pf )
				{
					if( CTTools.showTemplate )
					{
						tf.text = pf.getTemplate();
						tf.type = TextFieldType.INPUT;
						tf.styleSheet = null;
						tf.defaultTextFormat = fmt;
						tf.setTextFormat( fmt );
					}
					else
					{
						if( CTOptions.textEditorCodeColoring ) {
							var colText:String = codeFormat.prettyPrintOne( CTTools.showCompact ? pf.getCompact() : pf.getText(), pf.extension, true );
							tf.type = TextFieldType.DYNAMIC;
							tf.styleSheet = codeStyleSheet;
							tf.htmlText = "<body><textfield><p>"+colText+"</p></textfield></body>";
						}else{
							tf.text = CTTools.showCompact ? pf.getCompact() : pf.getText();
							tf.type = TextFieldType.DYNAMIC;
							tf.styleSheet = null;
							tf.defaultTextFormat = fmt;
							tf.setTextFormat(fmt);
						}
					}
				}else{
					tf.type = TextFieldType.DYNAMIC;
					tf.text = "";
					tf.styleSheet = null;
					tf.defaultTextFormat = fmt;
					tf.setTextFormat(fmt);
				}
				if( scrollbar ) {
					scrollbar.maxValue = tf.numLines;
				}
				tf.addEventListener( Event.CHANGE, textChanged);
			}
		}
		
		public function displayFiles () :void {
			if( pp ) {
				if( container.contains( pp ) ) container.removeChild(pp);
				pp = null;
			}
				
			if (CTTools.procFiles) {

				var files: Array = CTTools.procFiles;

				// Display last file
				if (CTTools.currFile == -1) {
					CTTools.currFile = 0;
				}
				
				ib.x = 0;
				ib.y = 0;

				ib.clearAllItems();
				
				var px:Number = offset_x;
				
				pp = new Popup( [ new agf.icons.IconMenu(0xEEEFFF,1,10, 10) ], 0, 0, container, ib.styleSheet, '', 'filepopup', false);
				pp.addEventListener( Event.SELECT, filePopupSelect );
				
				var pi:PopupItem;
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
					
					pp.setHeight( bt.getHeight() );
					pp.x = container.getWidth() - pp.getWidth();
					pp.y = ib.cssTop;
					pp.alignH = "right";
					pp.alignV = "bottom";
								
				}else{
					container.removeChild(pp);
				}
				
				if (tf && container) {
					var ibh: Number = ib.getHeight();
					tf.width = container.getWidth() - 8;
					tf.height = container.getHeight() - 8 - ibh;
					tf.x = 3;
					tf.y = 8 + ibh;
					ib.setWidth(container.getWidth());
				}

				updateText();
				ib.swapState("hover");
			}
		}
		
		private function filePopupSelect (e:PopupEvent) :void {
			
			setCurrentFile( e.currentPopup.rootNode.children.indexOf( e.selectedItem ) );
			
			if( CTTools.currFile >= 0 ) {
				
				var bt:Button = Button(ib.getChildByName( "" + CTTools.currFile) );
				
				if( CTTools.currFile == 0 ) offset_x = 0;
				else offset_x = - bt.x + bt.getWidth() + offset_x;
				
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