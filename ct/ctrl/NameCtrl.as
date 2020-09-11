package ct.ctrl
{
	import agf.html.*;
	import agf.icons.IconArrowDown;
	import agf.icons.IconDot;
	import agf.icons.IconFromFile;
	import agf.Options;
	import agf.tools.*;
	import ct.CTOptions;
	import ct.TemplateTools;
	import ct.ctrl.InputTextBox;
	import agf.ui.Popup;
	import agf.ui.PopupItem;
	import agf.ui.Button;
	import agf.ui.Label;
	import agf.ui.Language;
	import agf.events.PopupEvent;
	import flash.events.MouseEvent;
	import flash.events.Event;
	
	public class NameCtrl extends PropertyCtrl
	{
		public function NameCtrl ( 	alabel:String= "", aname:String="", atype:String="", avalue:String="", propObj:Object=null, args:Array=null,
									w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false, visibleStatus:Boolean=true)
		{
			super( alabel,aname,atype,avalue,propObj,args,w,h,parentCS,style,cssId,cssClasses,noInit);
		}
		
		public var deleteButton:Button;
		private var deleteButtonVisible:Boolean=true;
		public var saveButton:Button;
		private var saveButtonVisible:Boolean=true;
		public var saveAndCloseButton:Button;
		private var saveAndCloseButtonVisible:Boolean=true;
		public var closeButton:Button;
		private var closeButtonVisible:Boolean=true;
		public var prevButton:Button;
		private var prevButtonVisible:Boolean=true;
		public var nextButton:Button;
		private var nextButtonVisible:Boolean=true;
		public var areaPopup:Popup;
		public var minSizePopup:Popup;
		
		public var visibleBtn:Button;
		
		private var _visibleStatus:Boolean=true;
		public function get visibleStatus () :Boolean { return _visibleStatus; }
		public function set visibleStatus (v:Boolean) :void {
			_visibleStatus = v;
			if( visibleBtn ) {
				visibleBtn.clips = [ new IconFromFile(  (v ? Options.iconDir + CTOptions.urlSeparator + "eye-btn.png" : Options.iconDir + CTOptions.urlSeparator + "hide-btn.png"), Options.btnSize, Options.btnSize) ];
			}
		}
		
		public function showSaveAndCloseButton (val:Boolean) :void {
			saveAndCloseButtonVisible = saveAndCloseButton.visible = val;
		}
		public function showSaveButton (val:Boolean) :void {
			saveButtonVisible = saveButton.visible = val;
		}
		public function showDeleteButton (val:Boolean) :void {
			deleteButtonVisible = deleteButton.visible = val;
		}
		public function showNextButton (val:Boolean) :void {
			nextButtonVisible = nextButton.visible = val;
		}
		public function showPrevButton (val:Boolean) :void {
			prevButtonVisible = prevButton.visible = val;
		}
		
		public override function create (alabel:String= "", aname:String="", atype:String="", avalue:String="", propObj:Object=null, args:Array=null) :void
		{
			_type = atype;
			_name = aname;
			_propObj = propObj;
			_args = args;
			name = aname;
			
			label = new Label(0, 0, this, styleSheet, '', 'name-label', false);
			label.label = "Test";
			label.init();
			
			textBox = new InputTextBox(_type, _args, _propObj, avalue, cssWidth, 0, this, styleSheet, '', 'constant-prop-input', false);
			textBox.addEventListener( ENTER, textBoxEnter );
			
			visibleBtn = new Button( [ new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "eye-btn.png",Options.btnSize, Options.btnSize) ], 0, 0, this, styleSheet, '', 'name-visible-button', false);
			visibleBtn.addEventListener( MouseEvent.CLICK, visibleClick );
			
			deleteButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "trash-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'name-delete-button', false);
			deleteButton.addEventListener( MouseEvent.CLICK, deleteClick );
		
			saveButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "save-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'name-save-button', false);
			saveButton.addEventListener( MouseEvent.CLICK, saveInlineClick );
			
			saveAndCloseButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "save-close-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'name-save-and-close-button', false);
			saveAndCloseButton.addEventListener( MouseEvent.CLICK, saveClick );
	 	
			prevButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "navi-left-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'name-prev-button', false);
			prevButton.addEventListener( MouseEvent.CLICK, prevClick );
			
			nextButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "navi-right-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'name-next-button', false);
			nextButton.addEventListener( MouseEvent.CLICK, nextClick );
			
			closeButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "close-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'name-close-button', false);
			closeButton.addEventListener( MouseEvent.CLICK, closeClick );
			
			areaPopup = new Popup( [ new IconArrowDown( Application.instance.mainMenu.iconColor) ], 0, 0, this, styleSheet, '', 'name-area-popup', false);
			areaPopup.alignH = "right";
			areaPopup.textAlign = "right";
			
			minSizePopup = new Popup( [ new IconFromFile(Options.iconDir + CTOptions.urlSeparator+"settings-btn.png", Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'min-size-popup', false);
			minSizePopup.visible = false;
			minSizePopup.alignH = "right";
			minSizePopup.textAlign = "right";
			
			minSizePopup.addEventListener( PopupEvent.SELECT, minSizeClick );
			
			setWidth( getWidth() );
			setHeight( Math.max( textBox.cssSizeY+textBox.cssMarginTop, visibleBtn.cssSizeY+visibleBtn.cssMarginTop) + Math.max( deleteButton.cssSizeY, closeButton.cssSizeY, nextButton.cssSizeY, prevButton.cssSizeY, saveButton.cssSizeY, saveAndCloseButton.cssSizeY) );
		
		}
		protected function closeClick (e:MouseEvent) :void {
			dispatchEvent( new Event("close") );
		}
		protected function nextClick (e:MouseEvent) :void {
			dispatchEvent( new Event("next") );
		}
		protected function prevClick (e:MouseEvent) :void {
			dispatchEvent( new Event("prev") );
		}
		
		protected function saveClick (e:MouseEvent) :void {
			dispatchEvent( new Event("save") );
		}
		protected function saveInlineClick (e:MouseEvent) :void {
			dispatchEvent( new Event("saveInline") );
		}
		protected function deleteClick (e:MouseEvent) :void {
			dispatchEvent( new Event("delete") );
		}
		protected function visibleClick (e:MouseEvent) :void {
			visibleStatus = !visibleStatus;
			if( textBox ) textBox.textEnter();
		}
		
		private function minSizeClick (e:PopupEvent) :void {
			var curr:PopupItem = e.selectedItem;
			if ( typeof(this[curr.options.action]) == "function" ) {
				this[curr.options.action]( null );
			}
		}
		
		public override function setWidth (w:int) :void
		{
			//  bug fix for input-height-change event from AreaEditor.displayInsertForm resize bug and name field
			// fix bug in itemList.format or AreaEditor? only appears with richtext in forms wich can dispatch height change ecents on resize
			if( w == 0 ) return;
			
			super.setWidth(w);
			
			closeButton.x = cssLeft - Math.ceil(5*CssUtils.numericScale);
			
			if( label ) {
				label.setWidth(0);
				label.init();
			}
			if( visibleBtn ) {
				if( textBox ) textBox.setWidth( w - visibleBtn.cssSizeX );
				visibleBtn.x = w - visibleBtn.cssSizeX;
			}
			var yofs:int = - Math.ceil(4*CssUtils.numericScale);
			var ofs:int = 0;
			var mh:int = 0;
			
			minSizePopup.rootNode.removeItems();
			
			var minSize:Boolean = false;
			var spc:Number = w - (label.getWidth() + label.x );
			var p1:Number = label.getWidth() + minSizePopup.cssSizeX + closeButton.cssSizeX;
			var ppi:PopupItem;
			
			if ( saveAndCloseButton && saveAndCloseButtonVisible )
			{
				if ( minSize || w - (ofs + saveAndCloseButton.cssSizeX) < p1 )
				{
					minSize = true;
					saveAndCloseButton.visible = false;
					
					ppi = minSizePopup.rootNode.addItem( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "save-close.png", Options.iconSize, Options.iconSize), "Save and Close"], styleSheet );
					ppi.options.action = "saveClick";
				}
				else
				{
					saveAndCloseButton.visible = true;
					ofs += saveAndCloseButton.cssSizeX;
					if ( saveAndCloseButton.cssSizeY > mh ) mh = saveAndCloseButton.cssSizeY;
					saveAndCloseButton.x = w - ofs;
					saveAndCloseButton.y = cssTop + yofs;
				}
			}
			
			if ( saveButton && saveButtonVisible )
			{
				if ( minSize || w - (ofs + saveButton.cssSizeX) < p1 )
				{
					minSize = true;
					saveButton.visible = false;
					
					ppi = minSizePopup.rootNode.addItem( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "save.png", Options.iconSize, Options.iconSize), "Save"], styleSheet );
					ppi.options.action = "saveInlineClick";
				}
				else
				{
					saveButton.visible = true;
					ofs += saveButton.cssSizeX;
					if( saveButton.cssSizeY > mh ) mh = saveButton.cssSizeY;
					saveButton.x = w - ofs;
					saveButton.y = cssTop + yofs;
				}
			}
			
			if ( deleteButton && deleteButtonVisible )
			{
				if ( minSize )
				{
					minSize = true;
					deleteButton.visible = false;
					
					ppi = minSizePopup.rootNode.addItem( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "trash.png", Options.iconSize, Options.iconSize), "Delete"], styleSheet );
					ppi.options.action = "deleteClick";
				}
				else
				{
					deleteButton.visible = true;
					ofs += deleteButton.cssSizeX;
					if( deleteButton.cssSizeY > mh ) mh = deleteButton.cssSizeY;
					deleteButton.x = w - ofs;
					deleteButton.y = cssTop + yofs;
				}
			}
			
			if ( nextButton && nextButtonVisible )
			{
				if ( minSize || w - (ofs + nextButton.cssSizeX) < p1 )
				{
					minSize = true;
					nextButton.visible = false;
					
					ppi = minSizePopup.rootNode.addItem( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "navi-right.png", Options.iconSize, Options.iconSize), "Goto Next"], styleSheet );
					ppi.options.action = "nextClick";
				}
				else
				{
					nextButton.visible = true;
					ofs += nextButton.cssSizeX;
					if( nextButton.cssSizeY > mh ) mh = nextButton.cssSizeY;
					nextButton.x = w - ofs;
					nextButton.y = cssTop + yofs;
				}
			}
			
			if ( prevButton && prevButtonVisible )
			{
				if ( minSize || w - (ofs + prevButton.cssSizeX) < p1 )
				{
					minSize = true;
					prevButton.visible = false;
					
					ppi = minSizePopup.rootNode.addItem( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "navi-left.png", Options.iconSize, Options.iconSize), "Goto Previous"], styleSheet );
					ppi.options.action = "prevClick";
				}
				else
				{
					prevButton.visible = true;
					ofs += prevButton.cssSizeX;
					if( prevButton.cssSizeY > mh ) mh = prevButton.cssSizeY;
					prevButton.x = w - ofs;
					prevButton.y = cssTop + yofs;
				}
			}
			
			if ( areaPopup )
			{
				if ( areaPopup.rootNode.children && areaPopup.rootNode.children.length > 0 ) {
					areaPopup.visible = true;
				}else{
					areaPopup.visible = false;
				}
				if( areaPopup.visible ) {
					ofs += areaPopup.cssSizeX;
					if( areaPopup.cssSizeY > mh ) mh = areaPopup.cssSizeY;
					areaPopup.x = w - ofs;
					areaPopup.y = cssTop + yofs;
				}
			}
			
			if ( minSize ) {
				minSizePopup.visible = true;
				ofs += minSizePopup.cssSizeX;
				minSizePopup.x = w - (ofs);
				minSizePopup.y = cssTop + yofs;
				if ( mh == 0 ) {
					mh = minSizePopup.cssSizeY;
				}
			}else{
				minSizePopup.visible = false;
			}
			
			if ( textBox )
			{
				textBox.y = mh + visibleBtn.cssMarginTop + cssTop;
			
				if ( visibleBtn )
				{
					visibleBtn.y = mh + cssTop + visibleBtn.cssMarginTop + (textBox.cssSizeY-visibleBtn.cssSizeY);
				}
			}
			
			if( label ) {
				label.x = int((w-(ofs+closeButton.cssSizeX)-label.getWidth())/2 + closeButton.x + closeButton.cssSizeX);
				label.y = int(closeButton.y + (closeButton.cssSizeY - label.getHeight())/2);
			}
		}
		
	}
}