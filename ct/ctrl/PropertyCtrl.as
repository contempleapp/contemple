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
	import agf.ui.Button;
	import agf.ui.Label;
	import agf.ui.Language;
	import agf.events.PopupEvent;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import ct.TemplateEditor;
	import ct.CTOptions;
	
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
		public var textBox:InputTextBox;
		public var ctrlOptions:Popup;
		
		public function get type () :String { return _type; }
		
		public override function setWidth (w:int) :void {
			super.setWidth(w);
			if( w ) {
				//if( label ) label.setWidth( w - ( ctrlOptions ? ctrlOptions.cssSizeY + ctrlOptions.cssMarginX : 0) );
				if( textBox ) textBox.setWidth( w );
				if( ctrlOptions ) ctrlOptions.x = w - (ctrlOptions.cssSizeX + ctrlOptions.cssMarginRight);
			}
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
			label.addEventListener( MouseEvent.CLICK, selectTextOnLabel);
			
			textBox = new InputTextBox(_type, _args, _propObj, avalue, cssWidth, 20, this, styleSheet, '', 'constant-prop-input', false);
			textBox.y = label.getHeight();
			textBox.labelText = alabel;
			textBox.addEventListener( ENTER, textBoxEnter );
			
			ctrlOptions = new Popup( null, 0, 0, this, styleSheet, '', 'input-help-button', false);
			ctrlOptions.clips = [ new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "ellipse-small.png", Options.iconSize, int(Options.iconSize/2) ) ];
			ctrlOptions.init();
			
			ctrlOptions.x = cssRight - ctrlOptions.cssMarginRight;
			ctrlOptions.y = cssTop + ctrlOptions.cssMarginTop;
			
			ctrlOptions.alignH = "right";
			ctrlOptions.textAlign = "right";
			ctrlOptions.alignV = "bottom";
			ctrlOptions.addEventListener( Event.SELECT, optionsSelect );
			
			ctrlOptions.rootNode.addItem( [ Language.getKeyword("Revert to Default Value") ], styleSheet);
			
			label.x = cssLeft;
			label.setWidth( getWidth() - (ctrlOptions.cssSizeX + ctrlOptions.cssMarginX));
			
			if ( Language.hasKeyword(aname.toLowerCase() + "-help") ) {
				ctrlOptions.rootNode.addItem( [ Language.getKeyword("Show Help") ], styleSheet);
			}
		}
		
		protected function selectTextOnLabel ( e:MouseEvent ) :void {
			if( !TemplateEditor.clickScrolling ) {
				if( stage && textBox && textBox.textField ) {
					textBox.textField.setSelection( 0, textBox.textField.text.length);
					stage.focus = textBox.textField;
				}
			}else{
				TemplateEditor.endClickScrolling();
			}
		}
		
		protected function optionsSelect ( e:PopupEvent ) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			if( lb == Language.getKeyword("Revert to Default Value" )  ) {
				if( textBox && _propObj ) {
					textBox.value = _propObj.defValue;
					textBox.activateValue = "";
					textBox.textEnter();
				}
			} else if( lb == Language.getKeyword("Show Help") ) {
				var txt :String =  TemplateTools.obj2Text ( Language.getKeyword( _name.toLowerCase() + "-help" ), "#", null, false, false );
				Application.instance.window.InfoWindow ( "HelpWindow", "" + Language.getKeyword( _name.toLowerCase()), txt, {}, "" );
			}
		}
		
		protected function textBoxEnter (e:Event) :void {
			dispatchEvent(e);
		}
	}
	
}
