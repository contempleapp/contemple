package ct.ctrl 
{
	import flash.text.TextField;
	import agf.ui.*;
	import agf.html.*;
	
	public class VectorTextField extends InputTextBox
	{

		public function VectorTextField(type:String="line", type_args:Array=null, prop_obj:Object=null, avalue:String="", w:Number=0, h:Number=0, parentCS:CssSprite=null, css:CssStyleSheet=null,cssId:String='', cssClasses:String='', noInit:Boolean=false)
		{
			super(type, type_args, prop_obj, avalue, w, h, parentCS,css,cssId,cssClasses,noInit);
			vectorType = "vec-component";
		}
		public var wrap:String;
		public var rootVector:InputTextBox;
		
		public override function textEnter () :void {
			super.textEnter();
			rootVector.textEnter();
		}
	}
	
}
