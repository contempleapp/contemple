package agf.ui
{
	import flash.text.*;
	import flash.events.*;
	import agf.html.*;
	import agf.ui.*;
	import agf.Options;
	import agf.icons.IconFromFile;
	
	public class SearchBox extends CssSprite
	{
		public function SearchBox(	w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, 
									cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style, "searchbox", cssId, cssClasses, false);
			create(w, h);
		}
		
		private var tf:InputTextField;
		private var searchButton:Button;
		private var cancelButton:Button;
		
		public function create (w:int, h:int) :void
		{
			if(tf && contains(tf)) removeChild( tf );
			if(searchButton && contains(searchButton)) removeChild( searchButton );
			if(cancelButton && contains(cancelButton)) removeChild( cancelButton );
			
			tf = new InputTextField(w, 0, this, styleSheet, '', 'searchbox-textfield', false);
			tf.text = "Search...";
			tf.init();
			
			searchButton = new Button( [ new IconFromFile( Options.iconDir + "/search-btn.png", Options.btnSize, Options.btnSize)], 0, 0, this, styleSheet, '', 'searchbox-button',false);
			/* cancelButton = new Button( [ Language.getKeyword( "Cancel Search" )], 0, 0, this, styleSheet, '', 'searchbox-cancel-button',false); */
			
			setWidth( w );
			setHeight( h );
		}
		
		public override function setWidth (w:int) :void
		{
			super.setWidth( w );
			
			if( tf && searchButton )
			{
				var sb:Button = searchButton;
				
				tf.x = Math.floor( cssLeft + tf.cssMarginLeft );
				tf.setWidth( w - ( tf.cssMarginX + sb.cssSizeX + sb.cssMarginRight + Math.max(tf.cssMarginRight, sb.cssMarginLeft) + cssMarginRight ) );
				
				sb.x = Math.floor( tf.x + tf.cssSizeX + Math.max( tf.cssMarginRight, sb.cssMarginLeft ) );
			}
		}
			
		public override function setHeight (h:int) :void
		{
			super.setHeight( h );
			
			if( tf && searchButton ) {
				var sb:Button = searchButton;
				//var cb:Button = cancelButton;
				tf.y = cssTop;
				tf.setHeight( h - tf.cssBoxY);
				sb.y = cssTop;
				//cb.x = Math.floor( (h - cb.cssSizeY) * .5 );
			}
		}
		
	}
}
