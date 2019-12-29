package agf.html
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	
	import agf.ui.Button;
	import agf.utils.StrVal;
	
	public class XmlUiRenderer extends XmlRenderer
	{
		public function XmlUiRenderer (w:Number=0, h:Number=0, body:CssSprite=null, style:CssStyleSheet=null) 
		{
			super(w,h,body,style);
			
			nodeTableOpen['_uibutton'] = ps_uibutton;
		}
		
		public function  ps_uibutton (nd:XML, n:int) :int 
		{
			var bt:Button = new Button( [StrVal.getval(nd.@label)], 100, 20, currentDiv, cssStyleSheet, StrVal.getval(nd.@id), StrVal.getval(nd.@['class']), false);
			
			if( nd.@onclick ) 
			{ 
				var click_handler:Object = StrVal.getval(nd.@onclick);
				if(typeof click_handler == "function") {
					bt.addEventListener(MouseEvent.CLICK, click_handler as Function);
				}
			}
			bt.x = currentDiv.cursorX;
			bt.y = currentDiv.cursorY;
			
			var st:Object = cssStyleSheet.getMultiStyle( bt.stylesArray );
			
			currentDiv.cursorX += bt.cssSizeX;
			
			if( st.display == "block" ) {
				currentDiv.cursorY += bt.cssSizeY;
			}
			
			return IGNORE_CHILDS;
		}
		
	}
}