package agf.html
{
	import flash.display.*;
	import flash.text.*;
	
	public class XmlRenderer extends CssSprite
	{
		public function XmlRenderer(w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null) 
		{
			super(w,h,parentCS,style,"body",'','',false);
			
			if(parentCS) parentCS.addChild( this );
			
		}
		//public static var defStyle:String="body{}div{display:block;}br{display:block;}p{display:block;}h1{display:block;font-size:2em;}h2{display:block;font-size:1.5em;}table{display:table;}tr{display:table-row;}td{display:table-column;}span{display:inline;}a{display:inline;}b{display:inline;font-weight:bold;}";
		
		public static const PROCESS_CHILDS:int = 1;
		public static const IGNORE_CHILDS:int = 0;
		
		protected var currentDiv:CssSprite;
		protected var upNodes:Array;
		
		public function clearRender () :void {
			for( var i:int = numChildren-1; i>=0; i--) {
				removeChild(getChildAt(i));
			}
			bgSprite.graphics.clear();
			
		}
		public function render (xml:XML) :void 
		{
			cursorX = cssLeft;
			cursorY = cssTop;
			var i:int;
			var L:int;
			
			// add style tags
			var styles:XMLList = xml.style;
			
			L = styles.length();
			if(L > 0) 
			{
				var tmp:String = "";
				
				for(i=0; i<L; i++)
				{
					tmp += styles[i];
				}
				var ovStyle:String = cssStyleSheet.toString() + tmp;
				cssStyleSheet = new CssStyleSheet( ovStyle );
			}
			
			// load styles and images...
			var link:XMLList = xml.link;
			var img:XMLList = xml.image;
			
			// Render Document Tree...
			var c:XMLList = xml.children();
			L = c.length();
			
			for(i=0; i<L; i++) {
				if(c[i].nodeKind() == "element") {
					currentDiv = this;
					upNodes = [this];
					renderNode( c[i], i );
				}
			}
			// update body height
			//var h:Number = height;
			if( height > cssHeight ) cssHeight = height;
			swapState("normal");
		}
		
		private function renderNode (nd:XML, n:int) :void 
		{
			var rv:int;
			var name:String = "_" + nd.name();
			
			if( nodeTableOpen[name] ) rv = nodeTableOpen[name](nd, n);
			else rv = nodeTableOpen.defaultNode(nd, n);
			
			if(rv == IGNORE_CHILDS) return;
			
			var c:XMLList = nd.children();
			var L:int = c.length();
			
			for(var i:int=0; i < L; i++)
			{
				if( c[i].nodeKind() == "element" && c[i].length() > 0 )
				{
					renderNode( c[i], i );
				}
				else if( c[i].nodeKind() == "text")
				{
					nodeTableOpen.textNode( c[i].toString(), i );
				}
			}
			
			if( nodeTableClose[name] ) nodeTableClose[name](nd, n);
		}
		
		private function createDiv (div:CssSprite, nd:XML) :CssSprite
		{
			div.nodeName = nd.name().toString().toLowerCase();
			if( nd.@id ) div.nodeId = nd.@id.toString();
			if( nd.attribute("class") ) div.nodeClass = nd.attribute("class");
			
			div.init();
			
			var st:Object = cssStyleSheet.getMultiStyle( div.stylesArray );
			div.cssStates.multiStyle = st;
			div.cursorX = div.cssLeft;
			div.cursorY = div.cssTop;
			
			return div;
		}
		
		/*   - div:first-child 
		///    - div:first-child
		///    - div
		///    - div:last-child
		///  - div
		///  - div
		///    - div:first-child
		///    - div
		///    - div:last-child
		///  - div:last-child
		*/
		private function ps_div (nd:XML, n:int) :int 
		{
			var div:CssSprite;
			
			div = createDiv(new CssSprite(0, 0, currentDiv, cssStyleSheet, '', '', '', true), nd);
			var st:Object = div.cssStates.multiStyle;
						
			if( st.display == "block" ) {
				div.cssWidth = currentDiv.cssWidth - (CssRenderer.co.paddingLeft+CssRenderer.co.borderLeftWidth + CssRenderer.co.paddingRight+CssRenderer.co.borderRightWidth);
				currentDiv.cursorY += currentDiv.maxLineHeight;
				currentDiv.cursorX = currentDiv.cssLeft;
				currentDiv.maxLineHeight = 0;
			}
			else if(st.display == "table" || st.display == "inline-table") 
			{
				currentDiv.removeChild(div);
				
				div = createDiv( new Table(0, 0, currentDiv, cssStyleSheet, true), nd );
				div.cssStates.currRow=-1;
				
				if(st.display != "inline-table")
				{
					div.cssWidth = currentDiv.cssWidth - (CssRenderer.co.paddingLeft+CssRenderer.co.borderLeftWidth + CssRenderer.co.paddingRight+CssRenderer.co.borderRightWidth);
					currentDiv.cursorY += currentDiv.maxLineHeight;
					currentDiv.cursorX = currentDiv.cssLeft;
					currentDiv.maxLineHeight = 0;
				}
				
			}else if(st.display == "table-row") {
				if(currentDiv is Table) {
					currentDiv.cssStates.currRow++;
					currentDiv.removeChild(div);
				}
			}else if(st.display == "table-column") {
				if(currentDiv is Table) {
					currentDiv.removeChild(div);
					var t:Table = Table(currentDiv);
					var cs:int = 1;
					var rs:int = 1;
					if( nd.@colspan ) cs = CssUtils.parse( nd.@colspan );
					if( nd.@rowspan ) rs = CssUtils.parse( nd.@rowspan );
					var cell:TableCell = t.addItem(null, t.cssStates.currRow, -1, cs, rs, true);
					div = createDiv(cell, nd);
				}
			}
			
			if(!(div is TableCell)) { 
				div.x = currentDiv.cursorX;
				div.y = currentDiv.cursorY;
			}
			
			if(st.display != "table-row") {
				upNodes.push(div);
				currentDiv = div;
			}
			
			return PROCESS_CHILDS;
		}
		
		private function  ps_divClose (nd:XML, n:int) :void 
		{
			var st:Object = currentDiv.cssStates.multiStyle;
			
			if(st) 
			{
				var div:CssSprite = CssSprite( upNodes.pop() );
				
				if(st.display == "table" || st.display == "inline-table") Table(div).format();
				
				div.swapState("normal");
				
				currentDiv = upNodes[upNodes.length-1];
				
				if( st.display == "block" || st.display == "table") 
				{
					currentDiv.cursorX = currentDiv.cssLeft;
					currentDiv.cursorY += div.cssSizeY;
					currentDiv.maxLineHeight = 0;
					
				}
				else if(st.display == "inline-block" || st.display == "inline" || st.display == "inline-table") 
				{
					if(div.cssSizeY > currentDiv.maxLineHeight) currentDiv.maxLineHeight = div.cssSizeY;
					
					currentDiv.cursorX += div.cssSizeX;
					
					if(currentDiv.cursorX >= currentDiv.cssWidth) {
						currentDiv.cursorY += currentDiv.maxLineHeight;
						currentDiv.cursorX = currentDiv.cssLeft;
						currentDiv.maxLineHeight = 0;
					}
				}
			}
		}
		private function  ps_br (nd:XML, n:int) :void 
		{
			ps_divClose(nd,n);
			ps_div(nd,n);
		}
		private function ps_textNode (s:String, n:int) :void 
		{
			var u:String="";
			for(var i:int=0; i<upNodes.length; i++) u += "<" + upNodes[i].nodeName +" " + upNodes[i].nodeOpen + ">";
			u += s;
			for(i=upNodes.length-1; i>=0; i--) u += "</" + upNodes[i].nodeName + ">";
			
			var tf:TextField = new TextField();
			tf.styleSheet = cssStyleSheet;			
			tf.htmlText = u;
			tf.autoSize = TextFieldAutoSize.LEFT;
			//tf.selectable = false;
			
			tf.x = currentDiv.cssLeft;
			tf.y = currentDiv.cssTop;
			
			currentDiv.addChild(tf);
		}
		
		protected function ps_process (nd:XML, n:int) :int { return PROCESS_CHILDS; }
		protected function ps_ignore (nd:XML, n:int) :int { return IGNORE_CHILDS; }
		protected function ps_title (nd:XML, n:int) :int { return IGNORE_CHILDS; }
		
		public var nodeTableOpen:Object = {
			
			_body: ps_process,
			_div: ps_div,
			_br: ps_br,
			_p: ps_div,
			_span: ps_div,
			_a: ps_div,
			_table: ps_div,
			_tr: ps_div,
			_td: ps_div,
			
			textNode: ps_textNode,
			_title: ps_title,
			
			_style: ps_ignore,
			_link: ps_ignore,
			_script: ps_ignore,
			_meta: ps_ignore,
			
			defaultNode: ps_process
		}
		
		public var nodeTableClose:Object = {
			_div: ps_divClose,
			_p: ps_divClose,
			_span: ps_divClose,
			_a: ps_divClose,
			_table: ps_divClose,
			_td: ps_divClose
		}
			
	}
}