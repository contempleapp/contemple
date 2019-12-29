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
		public var saveButton:Button;
		public var saveAndCloseButton:Button;
		public var closeButton:Button;
		
		public var visibleBtn:Button;
		
		private var _visibleStatus:Boolean=true;
		public function get visibleStatus () :Boolean { return _visibleStatus; }
		public function set visibleStatus (v:Boolean) :void {
			_visibleStatus = v;
			if( visibleBtn ) {
				visibleBtn.clips = [ new IconFromFile(  (v ? Options.iconDir + CTOptions.urlSeparator + "eye-btn.png" : Options.iconDir + CTOptions.urlSeparator + "hide-btn.png"), Options.btnSize, Options.btnSize) ];
			}
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
	 	
			closeButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "close-btn.png",Options.btnSize,Options.btnSize) ], 0, 0, this, styleSheet, '', 'name-close-button', false);
			closeButton.addEventListener( MouseEvent.CLICK, closeClick );
			
			setWidth( getWidth() );
			setHeight( Math.max( textBox.cssSizeY, visibleBtn.cssSizeY) + Math.max( deleteButton.cssSizeY, closeButton.cssSizeY, saveButton.cssSizeY, saveAndCloseButton.cssSizeY) );
			
		}
		protected function closeClick (e:MouseEvent) :void {
			dispatchEvent( new Event("close") );
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
		
		public override function setHeight (h:int) :void {
			super.setHeight(h);
			if( textBox ) {
				textBox.y = h - textBox.cssSizeY + textBox.cssMarginBottom;
			}
		}
		
		public override function setWidth (w:int) :void {
			//  bug fix for input-height-change event from AreaEditor.displayInsertForm resize bug and name field
			// fix bug in itemList.format or AreaEditor? only appears with richtext in forms wich can dispatch height change ecents on resize
			if( w == 0 ) return;
			
			super.setWidth(w);
			
			if( visibleBtn ) {
				if( textBox ) textBox.setWidth( w );
				visibleBtn.x = w - visibleBtn.cssSizeX;
			}
			var yofs:int = -4;
			
			var ofs:int = 0;
			var mh:int = 0;
			
			if( saveAndCloseButton && saveAndCloseButton.visible ) {
				ofs += saveAndCloseButton.cssSizeX;
				if( saveAndCloseButton.cssSizeY > mh ) mh = saveAndCloseButton.cssSizeY;
				saveAndCloseButton.x = w - ofs;
				saveAndCloseButton.y = cssTop + yofs;
			}
			if( saveButton && saveButton.visible ) {
				ofs += saveButton.cssSizeX;
				if( saveButton.cssSizeY > mh ) mh = saveButton.cssSizeY;
				saveButton.x = w - ofs;
				saveButton.y = cssTop + yofs;
			}
			if( deleteButton && deleteButton.visible ) {
				ofs += deleteButton.cssSizeX;
				if( deleteButton.cssSizeY > mh ) mh = deleteButton.cssSizeY;
				deleteButton.x = w - ofs;
				deleteButton.y = cssTop + yofs;
			}
			if( closeButton && closeButton.visible ) {
				ofs += closeButton.cssSizeX;
				if( closeButton.cssSizeY > mh ) mh = closeButton.cssSizeY;
				closeButton.x = w - ofs;
				closeButton.y = cssTop + yofs;
			}
			if( label ) { 
				label.setWidth( w - ofs );
			}
			
			if( textBox ) textBox.y = mh + cssTop;
			if( visibleBtn ) visibleBtn.y = mh + cssTop -3;
			
		}
		
	}
}