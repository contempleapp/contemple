package agf.ui.ctrl 
{
	import flash.text.TextField;
	import agf.ui.Slider;
	
	public class VectorTextField {

		public function VectorTextField() {
			textField = new TextField();
		}
		
		public var textField:TextField;
		public var type:String="";
		public var wrap:String="";
		public var minValue:Number=0;
		public var maxValue:Number=Number.MAX_VALUE;
		public var tfSlider:Slider;
		
	}
	
}
