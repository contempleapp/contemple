package  ct.ctrl
{
	import flash.events.MouseEvent;
	import agf.html.*;
	import agf.Options;
	import agf.ui.*;
	import agf.events.PopupEvent;
	import agf.icons.IconFromFile;
	import ct.AreaEditor;
	import ct.CTOptions;
	import ct.CTTools;
	
	public class MultiSelectMenu extends CssSprite
	{
		public function MultiSelectMenu (ed:AreaEditor, w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style, "multiselectmenu", cssId, cssClasses, noInit);
			editor = ed;
			create();
		}
		public var editor:AreaEditor;
		
		public var cancelBtn:Button;
		public var undoBtn:Button;
		public var deleteBtn:Button;
		public var cutBtn:Button;
		public var copyBtn:Button;
		public var pasteBtn:Button;
		
		public var moveToPP:Popup;
		
		public function create () :void
		{
			undoBtn = new Button( [new IconFromFile(Options.iconDir + "/reply-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'multisel-undo-button', false);
			undoBtn.addEventListener( MouseEvent.CLICK, undoClick );
			undoBtn.alpha = 0.35;
			
			cancelBtn = new Button( [new IconFromFile(Options.iconDir + "/close-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'multisel-cancel-button', false);
			cancelBtn.addEventListener( MouseEvent.CLICK, cancelClick );
			
			deleteBtn = new Button( [new IconFromFile(Options.iconDir + "/trash-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'multisel-delete-button', false);
			deleteBtn.addEventListener( MouseEvent.CLICK, deleteClick );
			
			/* // TODO: add cut, copy paste..
			cutBtn = new Button( [new IconFromFile(Options.iconDir + "/trash3-32.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'multisel-cut-button', false);
			cutBtn.addEventListener( MouseEvent.CLICK, cutClick );
			
			copyBtn = new Button( [new IconFromFile(Options.iconDir + "/trash3-32.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'multisel-copy-button', false);
			copyBtn.addEventListener( MouseEvent.CLICK, copyClick );
			
			pasteBtn = new Button( [new IconFromFile(Options.iconDir + "/trash3-32.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'multisel-paste-button', false);
			pasteBtn.addEventListener( MouseEvent.CLICK, pasteClick );
			
			
			moveToPP = new Popup( [ new IconFromFile(Options.iconDir + "/reply18.png", 18, 18 ) ], 0, 0, this, styleSheet, '', 'multisel-move-to-pp', false);
			moveToPP.addEventListener( PopupEvent.SELECT, moveToAreaSelect );
			
			if( CTTools.activeTemplate && CTTools.activeTemplate.areasByName ) {
				for(var nm:String in CTTools.activeTemplate.areasByName ) {
					moveToPP.rootNode.addItem( [ nm ], styleSheet );
				}
			}
			*/
		}
		
		public function getUndoEnabled () :Boolean {
			return undoBtn.alpha == 1;
		}
		
		public function enableUndo ( val:Boolean ) :void {
			if( val ) {
				undoBtn.alpha = 1;
			}else{
				undoBtn.alpha = 0.35;
			}
		}
		
		private function moveToAreaSelect (e:PopupEvent) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			
			if( editor ) {
			//	editor.multiSelMoveTo( lb );
			}
			
		}
		public function cancelClick (e:MouseEvent) :void {
			if( editor ) {
				editor.multiSelAbort();
			}
		}
		
		public function undoClick (e:MouseEvent) :void {
			if( editor ) {
				editor.multiSelUndo();
			}
		}
		
		public function deleteClick (e:MouseEvent) :void {
			if( editor ) {
				editor.multiSelDelete();
			}
		}
		
		public function cutClick (e:MouseEvent) :void {
			if( editor ) {
				// store items in 
				editor.multiSelDelete();
			}
		}
		public function copyClick (e:MouseEvent) :void {
			
		}
		
		public function pasteClick (e:MouseEvent) :void {
			
		}
		
		public override function setWidth (w:int) :void {
			super.setWidth(w);
				
			var ofs:int = cssPaddingRight + cssMarginRight;
			
			var mh:int = 0;
			if( cancelBtn ) {
				ofs += cancelBtn.cssSizeX + cancelBtn.cssMarginRight;
				if( cancelBtn.cssSizeY > mh ) mh = cancelBtn.cssSizeY;
				cancelBtn.x = w - ofs;
				cancelBtn.y = cssTop;
			}
			if( undoBtn ) {
				ofs += undoBtn.cssSizeX + undoBtn.cssMarginRight;
				if( undoBtn.cssSizeY > mh ) mh = undoBtn.cssSizeY;
				undoBtn.x = w - ofs;
				undoBtn.y = cssTop;
			}
			if( deleteBtn ) {
				ofs += deleteBtn.cssSizeX + deleteBtn.cssMarginRight;
				if( deleteBtn.cssSizeY > mh ) mh = deleteBtn.cssSizeY;
				deleteBtn.x = w - ofs;
				deleteBtn.y = cssTop;
			}
			if( cutBtn ) {
				ofs += cutBtn.cssSizeX + cutBtn.cssMarginRight;
				if( cutBtn.cssSizeY > mh ) mh = cutBtn.cssSizeY;
				cutBtn.x = w - ofs;
				cutBtn.y = cssTop;
			}
			if( copyBtn ) {
				ofs += copyBtn.cssSizeX + copyBtn.cssMarginRight;
				if( copyBtn.cssSizeY > mh ) mh = copyBtn.cssSizeY;
				copyBtn.x = w - ofs;
				copyBtn.y = cssTop;
			}
			if( pasteBtn ) {
				ofs += pasteBtn.cssSizeX + pasteBtn.cssMarginRight;
				if( pasteBtn.cssSizeY > mh ) mh = pasteBtn.cssSizeY;
				pasteBtn.x = w - ofs;
				pasteBtn.y = cssTop;
			}
			if( moveToPP ) {
				ofs += moveToPP.cssSizeX + moveToPP.cssMarginRight;
				if( moveToPP.cssSizeY > mh ) mh = moveToPP.cssSizeY;
				moveToPP.x = w - (ofs+moveToPP.cssMarginRight);
				moveToPP.y = cssTop;
			}
		}
		
		
		public override function getHeight () :int {
			return super.getHeight();
		}
	}
	
}
