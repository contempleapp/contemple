package ct.ctrl
{
	
	import agf.html.*;
	import ct.ctrl.InputTextBox;
	import agf.ui.Button;
	import agf.ui.Label;
	import flash.events.Event;
	import flash.events.MediaEvent;
	import flash.events.MouseEvent;
	import agf.tools.Application;
	import agf.tools.Console;
	import ct.CTTools;
	import ct.PageEditor;
	
	public class PageCtrl extends CssSprite
	{
		public function PageCtrl ( 	aname:String= "", atitle:String="", atype:String="", atemplate:String="", acrdate:String="", uid:int=0,
										w:Number=0, h:Number=0, 
										parentCS:CssSprite=null, style:CssStyleSheet=null,
										cssId:String='', cssClasses:String='',
										noInit:Boolean=false)
		{
			super(w, h, parentCS, style, "propctrl", cssId, cssClasses, noInit);
			create(aname, atitle, atype, atemplate, acrdate, uid);
		}
		
		private var _uid:int;
		private var _crdate:String;
		private var _template:String;
		private var _title:String;
		private var _type:String;
		public var _name:String;
		public var label:Label;
		
		public function get type () :String { return _type; }
		
		public override function setWidth (w:int) :void {
			super.setWidth(w);
			if( w ) {
				if( label ) {
					label.setWidth( w-cssBoxX );
				}
			}
		}
		
		public function create (aname:String= "", atitle:String="", atype:String="", atemplate:String="", acrdate:String="", uid:int=0) :void
		{
			_uid = uid;
			_title = atitle;
			_type = atype;
			_template = atemplate;
			_crdate = acrdate;
			_name = aname;
			name = aname;
			
			label = new Label(0, 0, this, styleSheet, '', 'showpage-label', false);
			label.label = aname;
		}
		
	}
}