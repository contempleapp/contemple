 package ct.ctrl
{
	import agf.Options;
	import agf.html.*;
	import agf.icons.IconArrowDown;
	import agf.icons.IconDot;
	import agf.icons.IconFromFile;
	import agf.tools.*;
	import ct.TemplateTools;
	import ct.ctrl.InputTextBox;
	import agf.ui.Popup;
	import agf.ui.PopupItem;
	import agf.ui.Button
	import agf.ui.Label;
	import agf.ui.Language;
	import agf.events.PopupEvent;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.utils.getTimer;
	import flash.geom.Point;
	import ct.TemplateEditor;
	import ct.CTOptions;
	import ct.HtmlEditor;
	import agf.Options;
	import flash.utils.setTimeout;
	
	/**
	* Contemple's InputTextBox with 
	* a label and optional popup for help and reset-to-default options.
	* Used in classes AreaEditor and ConstantEditor
	*
	* @param alabel translated label string
	* @param aname property name
	* @param atype the input type, see clss ctrl.InputTextBox
	* @param avalue type specific value as string
	* @param propObj Template Property (with argv, args, section...)
	* @param args: property arguments
	*/
	public class PropertyCtrl extends CssSprite
	{
		public function PropertyCtrl ( 	alabel:String= "", aname:String="", atype:String="", avalue:String="", propObj:Object=null, args:Array=null,
										w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style, "propctrl", cssId, cssClasses, noInit);
			create(alabel, aname, atype, avalue, propObj, args);
		}
		
		public static const ENTER:String = "ctrl_enter";
		
		protected var _type:String;
		public var _name:String;
		public var _propObj:Object;
		public var _args:Array;
		public var label:Label;
		public var showRevertToDefault:Boolean=false;
		public var textBox:InputTextBox;
		public var uiCmds:Vector.<UICmd>;
		private var clickTime:int;
		private var clickX:int;
		private var clickY:int;
		private var minMove:int=10;
		private var longClick:Boolean;
		public var abortLongClick:Boolean=false;
		
		public function get type () :String { return _type; }
		
		public override function setWidth (w:int) :void {
			super.setWidth(w);
			if( ! w ) w = 1;
			if( label ) label.setWidth( w );
			if( textBox ) textBox.setWidth( w );
		}
		
		public override function getHeight () :int {
			if( textBox ) {
				return int( Math.floor(textBox.y + textBox.cssSizeY) );
			}else{
				return super.getHeight();
			}
		}
		
		public function create (alabel:String= "", aname:String="", atype:String="", avalue:String="", propObj:Object=null, args:Array=null) :void
		{
			_type = atype;
			_name = aname;
			_propObj = propObj;
			_args = args;
			name = aname;
			
			label = new Label(0, 0, this, styleSheet, '', 'constant-prop-label', false);
			label.label = alabel + ":";
			label.init();
			
			label.addEventListener( MouseEvent.CLICK, selectTextOnLabel );
			addEventListener( MouseEvent.MOUSE_DOWN, labelDown );
			
			textBox = new InputTextBox( _type, _args, _propObj, avalue, cssWidth, 20, this, styleSheet, '', 'constant-prop-input', false );
			textBox.y = label.getHeight();
			textBox.labelText = alabel;
			textBox.addEventListener( ENTER, textBoxEnter );
			
			label.x = int(cssLeft);
			label.setWidth( getWidth() );
		}
		
		protected function labelFrame ( e:Event ) :void
		{
			if( abortLongClick ) {
				//longClick = false;
				labelUp();
				return;
			}
			
			if( !TemplateEditor.clickScrolling )
			{
				if(!longClick && getTimer() - clickTime > CTOptions.longClickTime )
				{
					if( Math.abs(mouseX-clickX) < minMove && Math.abs(mouseY-clickY) < minMove ) {
						longClick = true;
						showOptions();
						labelUp();
						TemplateEditor.endClickScrolling();
					}else{
						abortLongClick = true;
					}
				}
			}
		}
		
		protected function labelUp ( e:MouseEvent=null ) :void
		{
			if( stage ) stage.removeEventListener( MouseEvent.MOUSE_UP, labelUp );
			removeEventListener( Event.ENTER_FRAME, labelFrame );
		}
		
		protected function labelDown ( e:MouseEvent=null ) :void
		{
			if( stage )
			{
				longClick = abortLongClick = false;
				clickTime = getTimer();
				clickX = mouseX;
				clickY = mouseY;
				stage.addEventListener( MouseEvent.MOUSE_UP, labelUp );
				addEventListener( Event.ENTER_FRAME, labelFrame );
			}
		}
		
		protected function selectTextOnLabel ( e:MouseEvent=null ) :void
		{
			if( !TemplateEditor.clickScrolling ) {
				if( stage && textBox && textBox.textField ) {
					textBox.textField.setSelection( 0, textBox.textField.text.length);
					stage.focus = textBox.textField;
					setTimeout( function () {
					abortLongClick = true;
					}, 0);
				}
			}else{
				TemplateEditor.endClickScrolling();
			}
		}
		
		public function showOptions () :void
		{
			var menuHeight:int = Application.instance.mainMenu.cssSizeY;
			
			TemplateEditor.abortClickScrolling();
			
			var ctrlOptions:Popup = new Popup( null, 0, 0, this, styleSheet, '', 'input-help-button', false);
			
			var pm:Point = localToGlobal( new Point( mouseX, 0) );
			
			//ctrlOptions.x = pm.x;
			ctrlOptions.x = mouseX;
			
			var p:Point = ctrlOptions.globalToLocal( new Point( 0, menuHeight ) );
			ctrlOptions.y = menuHeight;//p.y;
			
			ctrlOptions.alignV = "center";
			ctrlOptions.alignH = "center";
			
			var pi:PopupItem;
			
			if ( showRevertToDefault ) {
				ctrlOptions.rootNode.addItem( [ Language.getKeyword("Revert to Default Value") ], styleSheet);
			}
			
			if ( Language.hasKeyword( _name.toLowerCase() + "-help") ) {
				ctrlOptions.rootNode.addItem( [ Language.getKeyword("Show Help") ], styleSheet);
			}
			
			if( uiCmds ) {
				for( var i:int=0; i < uiCmds.length; i++ ) {
					if( uiCmds[i] ) {
						pi = ctrlOptions.rootNode.addItem( uiCmds[i].label, styleSheet );
						pi.options.uicmd = uiCmds[i];
					}
				}
			}
			ctrlOptions.addEventListener( Event.SELECT, optionsSelect );
			ctrlOptions.open();
			
			var h:int = ctrlOptions.rootNode.container.height;
			var bw2:int = int(Options.btnSize * 0.5);
			
			var ny:int = Popup.topContainer.mouseY - (h + bw2);
			var ny2:int;
			
			if ( ny < menuHeight )
			{
				ny2 = Popup.topContainer.mouseY + (h + bw2);
				
				if ( ny2 + h < (Popup.topContainer.getHeight() - menuHeight) )
				{
					// position bottom
					ny = ny2 - h;
				}
				else
				{
					ny = menuHeight + 4;
					var w2:int = int(ctrlOptions.rootNode.container.width * 0.5);
					
					//if ( ctrlOptions.rootNode.container.x - (w2*2 + bw2) >= 0 ) {
					if ( ctrlOptions.rootNode.container.x /*- (w2*2 + bw2)*/ >= 0 ) {
						ctrlOptions.rootNode.container.x = pm.x - (w2*2 + bw2);
					}else{
						// position right
						if( pm.x + bw2 + ctrlOptions.rootNode.container.width < stage.stageWidth - HtmlEditor.previewX) {
							ctrlOptions.rootNode.container.x = pm.x + (bw2);
						}
					}
				}
			}
			
			if( ctrlOptions.rootNode.container.x < 0 ) {
				ctrlOptions.rootNode.container.x = 2;
			}
			ctrlOptions.rootNode.container.y = ny;
		}
		
		public function showHelp () :void
		{
			var txt:String = TemplateTools.obj2Text ( Language.getKeyword( _name.toLowerCase() + "-help" ), "#", null, false, false );
			Application.instance.window.InfoWindow ( "HelpWindow", "" + Language.getKeyword( _name.toLowerCase()), txt, {}, "" );
		}
		
		public function revertToDefault () :void
		{
			if( textBox && _propObj ) {
				textBox.value = _propObj.defValue;
				textBox.activateValue = "";
				textBox.textEnter();
			}
		}		
		protected function optionsSelect ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			if( lb == Language.getKeyword("Revert to Default Value" )  ) {
				revertToDefault();
			} else if( lb == Language.getKeyword("Show Help") ) {
				showHelp();
			}else{
				if( curr.options.uicmd ) {
					UICmd(curr.options.uicmd).run();
				}
			}
		}
		
		protected function textBoxEnter (e:Event) :void {
			dispatchEvent(e);
		}
	}
	
}
