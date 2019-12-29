package agf.html
{	
	import flash.display.*;
	import flash.text.StyleSheet;
	import flash.utils.*;
	import flash.system.*;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	public class CssStyleSheet extends StyleSheet
	{
		public function CssStyleSheet (c:String = "") { if(c) parseCSS(c); }
		
		// Only use fontSizeScale if Air SDK < 20 for fixing Screen DPI on mobile
		public static var fontSizeScale:Number = 1;
		public static var scaleFonts:Boolean = true;
		
		private var styles:Object;
		private var mediaStyles:Object;
		private var parsedMedia:Array;
		private var imports:int;
		private var _media:String = "all";
		
		public var cssFilePath:String="";
		
		public function get media () :String {	return _media; }
		public function set media (m:String) :void { 
			compileMedia( m.toLowerCase() );
		}
		
		public static var defStyle:String="body{}div,header,nav,footer,br,p,h1,h2,h3,h4,h5,h6,h7,canvas,center{display:block;}a,abbr,address,article,aside,b,base,bdi,bdo,blockquote,br,button,caption,cite,code,data,datalist,dd,del,dfn,dl,tt,em,embed,fieldset,figcaption,figure,form,hr,i,img,iframe,input,ins,kbd,keygen,label,legend,li,map,mark,object,ol,optgroup,option,output,param,pre,progress,q,rb,rp,rt,rtc,s,samp,section,select,small,source,span,strong,sub,sup,template,textarea,time,track,u,ul,var,video{display:inline;}center{text-align:center;}h1{font-size:2em;}h2{font-size:1.5em;}table{display:table;}tr{display:table-row;}td{display:table-column;}b,strong{font-weight:bold;}i{font-style:italic;}";
		
		public override function parseCSS (cssText:String) :void
		{
			mediaStyles = {};
			parsedMedia = ["all"];
			mediaStyles["all"] = "";
			compileCSS(defStyle + cssText);
		}
				
		public function compileCSS (cssText:String) :void 
		{
			var pattern:RegExp = /\t/g;
			
			// replace tabs with whitespaces
			cssText = cssText.replace(pattern, " ");
			
			var L:int = cssText.length;
			var i:int;
			var cc:int=0;
			var cc_m1:int;
			var ca:String="";
			var currentMedia:String = "all";
			var brackOpen:int=0;
			var inMedia:Boolean=false;
			var inBracket:Boolean=false;
			var inValue:Boolean=false;
			var ic:int;
			var j:int;
			var k:int;
			var m:int;
			var n:int;
			var writeChar:Boolean=true;
			var tmp:int;
			
			for(i = 0; i < L; i++)
			{
				cc_m1 = cc;
				cc = cssText.charCodeAt(i);
				
				if(cc < 32 ) {
					continue;
				}
				else if(cc == 32) // space
				{
					if(inValue==false && inBracket==true) {
						continue;	
					}else{ // if(inBracket==false) {
						if(cc_m1 <= 32) {
							continue;
						}
					}
					ic = mediaStyles[currentMedia].charCodeAt( mediaStyles[currentMedia].length-1 );
					if(ic <= 32) continue;
					if(ic == 58) continue; // :
				}
				
				// clear /++/ comments
				if(cc == 47) { // 42="*", 47="/"
					if(cssText.charCodeAt(i+1) == 42) {
						// open comment
						tmp = cssText.indexOf("*/", i);
						// move file pointer forward
						i = tmp+1;
						// set previous character for correct white-clearing
						cc = cc_m1;
						if(i == -1) {
							// Exit-No End Comment Found
							break;
						}
						continue;
					}
				}
				if( cc == 34 ) { // " or '
					
					for(k=i; k < L; k++) 
					{
						mediaStyles[currentMedia] += cssText.charAt(k);
						
						if( cssText.charCodeAt( k ) == 34 ) {
							
							break;
						}
						
						
					}
					i = k;
					continue;
				}
				
				ca = cssText.charAt(i);
				writeChar = true;
				
					switch( cc ) {
						
						case 123: //"{"
							if(!inValue) {
								inBracket = true;
								brackOpen++;
								// Clear last whitespace in selektor
								if(mediaStyles[currentMedia].charCodeAt( mediaStyles[currentMedia].length-1 ) <= 32) {
									mediaStyles[currentMedia] = mediaStyles[currentMedia].slice(0, mediaStyles[currentMedia].length-1);
								}
								cc_m1=0;
							}
							break;
						case 125: //"}"
							if(!inValue) {
								inBracket = false;
								inValue = false;
								brackOpen--;
								if(brackOpen==0 && inMedia==true) {
									// Write Last Media Char to correct media
									writeChar = false;
									inMedia = false;
									currentMedia = "all";
									cc_m1 = 0;
								}
								//skip white chars
								for(j = i+1; j<L; j++) {
									k = cssText.charCodeAt(j);
									if(k > 32) {
										i = j - 1;
										break;
									}
								}
							}
							break;
						/*case 35:  //"#"
							break;
						case 46:  //"."
							break;
						case 44:  //","
							break;
						case 42:  //"*"
							break;
						case 91:  //"["
							break;
						case 93:  //"]"
							break;
						case 40:  //"("
							break;
						case 41:  //")"
							break;*/
						case 58:  //":"
							if(inBracket) inValue = true;
							break;
						case 59:  //";"
							
							if(inBracket) inValue = false;
							break;
						case 64:  //"@"
							// parse media style
							writeChar = false;
							var mdstr:String = cssText.substring(i+1, i+6);
							if(mdstr.toLowerCase() == "media") 
							{
								mdstr = "";
								m = i+7;
								
								for(j=m; j<L; j++)
								{
									k = cssText.charCodeAt(j);
									if(k<=32) {
										if(mdstr=="") {
											m = j+1;
											continue;
										}else{
											// found media name:
											mdstr = cssText.substring(m, j);
											i = cssText.indexOf("{", j);
											i++;
											cc_m1 = 0;
											// skip white chars
											for(k=i; k<L; k++) {
												if(cssText.charCodeAt(k)>32) {
													i = k-1;
													break;
												}
											}
											brackOpen++;
											break;
										}
											
									}else if(k == 123) {
										mdstr = cssText.substring(m, j);
										i = j+1;
										cc_m1 = 0;
										// skip white chars
										for(k=i; k<L; k++) {
											if(cssText.charCodeAt(k)>32) {
												i = k-1;
												break;
											}
										}
										brackOpen++;
										break;
									}else{
										mdstr = "v";
									}
								}
								
								if(mediaStyles[mdstr] == null) {
									parsedMedia.push(mdstr);
									mediaStyles[mdstr] = "";
									cc_m1 = 0;
								}else{
									cc_m1 = 0;
								}
								
								currentMedia = mdstr;
								inMedia = true;
							}
							
							break;	// end switch statement
					}

				if(writeChar) 
					mediaStyles[currentMedia] += ca;
				
			} // for chars
			
			compileMedia(_media);
		}
			
		private function compileMedia ( m:String ) :void {
			
			// Clear all style sheets:
			
			this.clear();
			this.styles = {};
			
			this._media = m;
			
			var allcss:String = String(this);
			if(allcss == "") return;
			
			var L:int = allcss.length;
			var cc:int;
			var cr:String;
			var tmp:String="";
			var st:int=0;
			var stOpen:int;
			var stClose:int;
			var name:String;
			var val:String;
			var block:String;
			var blockname:String;
			var vals:Array;
			var keyval:Array;
			var j:int;
			var k:int;
			var searchOpen:Boolean = true;
			
			for(var i=0; i<L; i++) {
				cc = allcss.charCodeAt( i );
				
				if( cc <= 32 ) continue;
				if( cc == 34 ) 
				{
					for(k=i+1; k<L; k++) 
					{
						if( allcss.charCodeAt( k ) == 34 ) {
							i = k;
							break;
						}
					}
					continue;
				}
				if( searchOpen ) {
					if( cc == 123 ) { // "{"
						stOpen = i;
						searchOpen = false;
					}
				}else{
					if( cc == 125 ) 
					{
						stClose = i;
						
						blockname = allcss.substring( st, stOpen );
						block = allcss.substring( stOpen+1, stClose );
						
						vals = block.split(";");
						
						for(j=0; j<vals.length; j++)
						{
							keyval = vals[j].split(":");
							
							if(keyval[0])
							{
								addStyle( blockname, keyval[0], CssUtils.trimQuotes(keyval[1]) );
							}
						}
						st = i + 1;
						searchOpen = true;
					}
				}
			}
		}
		
		public function addStyle (block:String, name:String, value:String="") :void {
			if(name) {
				
				var i:int;
				
				if( block.indexOf(",") >= 0 ) {
					var blocks:Array = block.split(",");
					for(i=0; i < blocks.length; i++) {
						addStyle( CssUtils.trim(blocks[i]), name, value );
					}
					return;
				}
				
				if(styles[block] == null) {
					styles[block] = [];
				}
			
				if(name.indexOf("-") >= 0)
				{
					// Convert css name to javascript name
					var sp:Array = name.split("-");
					name = sp[0];
					for(i = 1; i < sp.length; i++) name += sp[i].charAt(0).toUpperCase() + sp[i].substring(1);
				}
				
				if( scaleFonts) { 
					if(name == "fontSize")	{
						value = ( parseInt( value.substring(0, value.length-2) ) * fontSizeScale ) + "px";
					}
				}
				
				styles[block].push(name, value);
				
				var o:Object = super.getStyle( block );
				o[name] = value;
				
				super.setStyle(block, o);
			}
		}
		
		public override function setStyle (styleName:String, styleObject:Object) :void {
			for( var name:String in styleObject ) {
				addStyle( styleName, name, styleObject[name] );
			}
		}
		
		//
		// getStyleArray( "*", "html", "body", "div#main.div1") : ["color","#123456", "fontSize", "12px", "border", "none"];
		//
		public function getStyleArray ( ...s:Array ) :Array
		{
			var ag:Array;
			if(s[0] is Array) {
				ag = s[0];
			}else{
				ag = s;
			}
			
			var rv:Array = [];
			var styl:Array;
			var j:int;
			var jL:int;
			
			for(var i:int=0; i<ag.length; i++) 
			{
				styl = this.styles[ag[i]];
				
				if(styl != null) {
					jL = styl.length;
					for(j=0; j<jL; j+=2) {
						rv.push( [styl[j], styl[j+1]] );
					}		
				}
			}
			
			return rv;
		}
		
		//
		// getMultiStyle( "*", "body", "div", ".wrap" ) : { color:"#123456", fontSize: "12px", border: "none" }
		//
		public function getMultiStyle( ...s:Array ) :Object 
		{
			var ag:Array;
			if(s[0] is Array) {
				ag = s[0];
			}else{
				ag = s;
			}
			
			var rv:Object = {};
			var styl:Array;
			var j:int;
			var jL:int;
			
			for(var i:int=0; i<ag.length; i++) 
			{
				styl = this.styles[ag[i]];
				
				if(styl != null) {
					jL = styl.length;
					for(j=0; j<jL; j+=2) {
						rv[styl[j]] = styl[j+1];
					}		
				}
			}
			
			return rv;
		}
		
		public function getTextFormat ( styleArray:Array, state:String="normal" ) :TextFormat
		{
			var sta:Array;
			
			if( state != "normal") {
				sta = [];
				var L:int = styleArray.length;
				
				for(var i:int=0; i<L; i++) {
					sta.push( styleArray[i], styleArray[i] + ":" + state);
				}
				
			}
			else
			{
				sta = styleArray;
			}
			
			var st:Object = getMultiStyle( sta );
			
			var fmt:TextFormat = new TextFormat();
			
			if( st.fontFamily ) fmt.font = CssUtils.parseFontFamily( st.fontFamily );
			if( st.fontSize ) fmt.size = CssUtils.parse( st.fontSize );
			if( st.color ) fmt.color = CssUtils.parse( st.color );
			if( (st.fontWeight && st.fontWeight == "bold") || st.fontWeight >= 500 ) fmt.bold = true;
			if( st.fontStyle && st.fontStyle == "italic" ) fmt.italic = true;
			if( st.textDecoration && st.textDecoration == "underline" ) fmt.underline = true;
			if ( st.textAlign ) {
				if( st.textAlign == "center") {
					fmt.align = TextFormatAlign.CENTER;
				}else if ( st.textAlign == "right") {
					fmt.align = TextFormatAlign.RIGHT;
				}
			}
			
			return fmt;
		}
		
		//
		// getStyle ( "div#id1.class1" ) : { color:"#123456", fontSize: "12px", border: "none" }
		// 
		public override function getStyle( s:String ) :Object 
		{
			var rv:Object = {};
			var styl:Array;
			var j:int;
			var jL:int;
			
			styl = this.styles[s];
			
			if(styl != null) {
				jL = styl.length;
				for(j=0; j<jL; j+=2) {
					rv[styl[j]] = styl[j+1];
				}		
			}
			
			return rv;
		}
		
		public override function toString () :String 
		{
			var allcss:String = mediaStyles["all"];
			
			if( _media != "all" ) 
			{
				if( mediaStyles[_media] )
				{
					allcss += mediaStyles[_media];
				}
			}
			
			return allcss;
		}
		
		
	}
}