package agf.ui
{
	import flash.text.*;
	import flash.events.*;
	import agf.html.*;
	import agf.ui.*;
	
	public class SearchBox extends CssSprite
	{
		public function SearchBox(	w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, 
									cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style, "searchbox", cssId, cssClasses, false);
			create(w, h);
		}
		
		private var label:Label;
		private var searchButton:Button;
		private var cancelButton:Button;
		
		public function create (w:int, h:int) :void
		{
			if(label && contains(label)) removeChild( label );
			if(searchButton && contains(searchButton)) removeChild( searchButton );
			if(cancelButton && contains(cancelButton)) removeChild( cancelButton );
			
			label = new Label(0, 0, this, styleSheet, '', 'searchbox-textfield', false);
			label.label = "";
			
			searchButton = new Button( [Language.getKeyword( "Search" )], 0, 0, this, styleSheet, '', 'searchbox-ok-button',false);
			cancelButton = new Button( [Language.getKeyword( "Cancel Search" )], 0, 0, this, styleSheet, '', 'searchbox-cancel-button',false);
			setWidth( w );
			setHeight( h );
		}
		
		public override function setWidth (w:int) :void
		{
			super.setWidth( w );
			
			if( label && searchButton && cancelButton )
			{
				var sb:Button = searchButton;
				var cb:Button = cancelButton;
				
				label.x = Math.floor( cssLeft + label.cssMarginLeft );
				label.setWidth( w - ( label.cssMarginX + sb.cssSizeX + Math.max( sb.cssMarginRight, cb.cssMarginLeft) + cb.cssSizeX + Math.max(label.cssMarginRight, sb.cssMarginLeft) + Math.max(cssMarginRight, cb.cssMarginRight) ) );
				
				sb.x = Math.floor( label.x + label.cssSizeX + Math.max( label.cssMarginRight, sb.cssMarginLeft ) );
				cb.x = Math.floor( sb.x + sb.cssSizeX + Math.max( sb.cssMarginRight, cb.cssMarginLeft ) );
			}
		}
			
		public override function setHeight (h:int) :void
		{
			super.setHeight( h );
			
			if( label && searchButton && cancelButton ) {
				var sb:Button = searchButton;
				var cb:Button = cancelButton;
				label.y = Math.floor( (h - label.cssSizeY) * .5 );
				sb.x = Math.floor( (h - sb.cssSizeY) * .5 );
				cb.x = Math.floor( (h - cb.cssSizeY) * .5 );
			}
		}
		
	}
}
