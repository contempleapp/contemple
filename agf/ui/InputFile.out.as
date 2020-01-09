package agf.ui
{
	import flash.display.*;
	import flash.events.*;
	import flash.utils.setTimeout;
	
	import agf.icons.IconArrowDown;
	import agf.events.PopupEvent;
	import agf.html.*;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	public dynamic class InputFile extends CssSprite
	{
		// type can be file or directory
		public function InputFile ( type:String="text", w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false)
		{
			super(w, h, parentCS, css, "textbox", cssId, cssClasses, true);
			autoSwapState = "";
			if(!noInit) init();
			create();
			setType(type);
		}
		
		public var textField:TextField;
		private var fmt:TextFormat;
		
		public function create () :void {
			if( textField ) {
				if( contains( textField ) ) removeChild( textField);
				textField = null;
			}
			textField = new TextField();
			textField.type = TextFieldType.INPUT;
			textField.height = getHeight();
			textField.width = getWidth();
			textField.x = cssLeft;
			textField.y = cssTop;
			//textField.text = "I";
			textField.addEventListener( FocusEvent.FOCUS_IN, onActivate);
			textField.addEventListener( FocusEvent.FOCUS_OUT, onDeactivate );
			textField.addEventListener( Event.CHANGE, textChange );
			
			addChild( textField );
			fmt = styleSheet.getTextFormat( stylesArray, "normal" );
			//textField.setTextFormat( fmt );
			//textField.text = "";
		}
		private var _type:String;
		
		public var tfBtn:Button;
		public var min:Number = Number.MIN_VALUE;
		public var max:Number = Number.MAX_VALUE;
		
		public function setType (type:String="text") :void {
			_type = type;
			
			if( type == "font" ) {
				if( tfBtn ) {
					if( contains(tfBtn)) removeChild( tfBtn );
				}
				tfBtn = new Button(["Sel."],0,0,this,styleSheet,'','textbox-button', false);
				textField.width = textField.width - tfBtn.cssSizeX;
				tfBtn.x = textField.width;
				
				if( type == "file" ) {
					
					tfBtn.addEventListener( MouseEvent.CLICK, selectFile );
					
				}else{
					// Directory
					tfBtn.addEventListener( MouseEvent.CLICK, selectDirectory );
					
				}
			}
			
		}
		
		private function selectFile (e:MouseEvent) :void {
			trace("Select File");
			
		}
		
		private function selectDirectory (e:MouseEvent) :void {
			trace("Select Directory");
			var directory:File;
			
			if( projectDir ) directory = new File(projectDir);
			else directory = File.documentsDirectory;
			
			try {
				directory.browseForDirectory("Open Project");
				directory.addEventListener(Event.SELECT, dirForOpenSelected);
			}catch (error:Error){
				//trace("Failed:", error.message);
			}
		}
		
		private static function dirForOpenSelected (event:Event) :void {
			var directory:File = event.target as File;
			projectDir = directory.nativePath;
			open();
		}
		
		public override function setWidth ( w:int ) :void {
			super.setWidth(w);
			if( tfBtn ) {
				textField.width = w-tfBtn.cssSizeX;
				tfBtn.x = textField.width;
			}else{
				textField.width = w;
			}
		}
		public override function setHeight ( h:int ) :void {
			super.setHeight(h);
			textField.height = h;
			if(tfBtn) {
				tfBtn.setHeight(h);
			}
		}
		
		public function get value () :String { return textField ? "" : textField.text; }
		private function textChange ( e:Event) :void {
			textField.setTextFormat( fmt );
		}
		
		private function onActivate (e:Event) :void {
			if( textField ) {
				fmt = styleSheet.getTextFormat( stylesArray, "active"  );
				textField.setTextFormat( fmt );
				swapState( "active" );
			}
		}
		private function onDeactivate (e:Event) :void {
			if( textField ) {
				fmt = styleSheet.getTextFormat( stylesArray, "normal");
				textField.setTextFormat( fmt );
				swapState( "normal" );
			}
		}
		public function set value ( v:String ) :void {
			textField.text = v;
		}
		
	}
}