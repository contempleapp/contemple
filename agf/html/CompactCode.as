package agf.html
{
	
	public class CompactCode
	{
		// Function table
		public static var options:Object = new Object();
		
		private static var code:String;
		private static var output:String;
		private static var L:int;
		
		public static function compact ( _code:String ) :String
		{
			inlineScript = false;
			
			setup();
			
			updateCode( _code );
			
			// Remove multi comments
			if(trimMultiComment) updateCode( removeMultiComments() );
			
			// Remove single comments
			if(trimSingleComment) updateCode( removeSingleComments() );
			
			// trim all Whitespace except in strings
			if(trimWhite) updateCode( removeWhitespace() );
			
			return code;
		}
		
		
		public static function compactWithInline ( _code:String ) :String
		{
			// TODO..
			// Currently inline js and css in html files should be avoided or minified manually
			
			inlineScript = true;
			
			
			var os:String;
			var os2:String;
			var cs:String;
			var t2:int;
			var L2:int;
			var j:int;
			
			for( var i:int=1; i<inlineScriptOP.length; i+=2 )
			{
				os = inlineScriptOP[i-1];
				cs = inlineScriptOP[i];
				t2 = os.indexOf("..");
				
				if( t2 >= 0 ) {
					os2 = os.substring(t2+2);
					os = os.substring(0, t2);
				}else{
					os2 = "";
				}
				
				// os: <script, os2: >, cs: </script>
				
				//for( j=0; j<L2; j++ ) {
					
				//}
			}
			
			return code;
		}
		
		private static function updateCode ( _code:String ) :void{
			code = _code;
			L = _code.length;
		}
		
		private static function nextNL (from:int) :int {
			for(var i:int=from; i<L; i++) {
				if( code.charCodeAt(i) == 13 || code.charAt(i) === "\n" || code.charAt(i) === "\r" ) return i;
			}
			return L;
		}
		
		private static function nextCommentEnd (from:int) :int {
			var i:int;
			if( mcc == 1 ) {
				for(i = from; i<L-1; i++) {
					if( code.charCodeAt( i ) == mcc1 ) return i;
				}
			}else if(mcc == 2) {	
				for(i = from; i<L-1; i++) 
				{
					if( code.charCodeAt( i ) == mcc1 && code.charCodeAt( i+1 ) == mcc2 ) return i+1;
				}
			}else{
				var s:int = code.indexOf( multiClose, from );
				if( s >= 0 ) return s + mcc-1;
			}	
			return L;
		}
		
		private static function removeMultiComments () :String
		{
			var cc:int;
			var k:int;
			var j:int;
			var rstr:String = "";
			var s:int;
			var fd:Boolean=false;
			var strst:int;
			
			for(var i:int=0; i<L; i++)
			{				
				cc = code.charCodeAt(i);
				
				if( cc  == 34 || cc == 39 ) {
					// Ignore String values...
					strst = i;
					for(i++; i<L; i++) {
						if( code.charCodeAt(i) == cc ) {
							rstr += code.substring( strst, i+1 );
							break;
						}
					}
					continue;
				}
				
				if( cc == mco1 ) // Multi Comment Key First Char
				{
					if( mco >= 2 ) 
					{
						// Search for two char comment: /* */ etc
						// second key:
						if(L > i + 1 && code.charCodeAt( i + 1 ) === mco2 ) {
							
							if( mco == 2 ) { // 2char operator
								sc_start = i;
								sc_end = nextCommentEnd( i + 2 );
								i = sc_end;
								continue;
							}
							else
							{
								fd = true;
								
								// PARSE Longer Comment keywords than two characters: <!-- --> etc
								for( s = 2; s < mco; s++) 
								{
									if( !(L > i + s + 1 && code.charAt( i+s ) === multiOpen.charAt(s)) ) 
									{
										fd = false;
										break;
									}
								}
								
								if(fd) {
									// Ignore chars in multiOpenFollowAbort
									if ( multiOpenFollowAbort.indexOf( code.charAt(i+mco) ) >= 0 ) {
										// For <!--[IE... comments or <!--// var script = ...
									}else{
										// Found multi char comment open..
										sc_start = i;
										sc_end = nextCommentEnd( i + 2 );
										i = sc_end;
										continue;
									}
								}
							}
						}
					}
					else
					{
						// Found single char multi comment (#)
						sc_start = i;
						sc_end = nextCommentEnd( i + 1 );
						i = sc_end;
						continue;
					}
				}
				
				// writechar
				rstr += String.fromCharCode( cc );
			}
			
			return rstr;
		}
		
		private static function removeSingleComments () :String
		{
			var cc:int;
			var k:int;
			var j:int;
			var rstr:String = "";
			var strst:int;
			for(var i:int=0; i<L; i++)
			{				
				cc = code.charCodeAt(i);
				
				if( cc  == 34 || cc == 39 ) {
					// Ignore String values...
					strst = i;
					for(i++; i<L; i++) {
						if( code.charCodeAt(i) == cc ) {
							//i++;
							rstr += code.substring( strst, i+1 );
				
							break;
						}
					}
					continue;
				}
				
				if( cc == sc1 ) { // Single Comment First Char
					
					if( sc >= 2 ) 
					{
						// second key:
						if( L > i + 2 && code.charCodeAt( i + 1 ) === sc2 )
						{
							sc_start = i;
							sc_end = nextNL( i + 2 );
							i = sc_end;
							continue;
						}
					}
					else
					{
						// Found Single Char comment (#)
						sc_start = i;
						sc_end = nextNL( i + 1 );
						i = sc_end;
						continue;
					}
					
				}
				
				// writechar
				rstr += String.fromCharCode( cc );
				
			}
			
			return rstr;
		}
		
		public static function removeWhitespace () :String {
			var str:String = "";
			var i:int;
			var k:int;
			var cc:int;
			var ccm1:int=0;
			var cc2:int;
			var ltc:int;
			var search_char:int;
			
			for(i=0; i<L; i++)
			{
				cc = code.charCodeAt(i);
				
				if(cc == 34 || cc == 39) 
				{
					search_char = cc;
					str += code.charAt( i );
					
					for(k=i+1; k < L; k++)
					{
						str += code.charAt( k );
						
						if( code.charCodeAt(k) == search_char ) {
							// string end
							i = k+1;
							ccm1 = search_char;
							cc = code.charCodeAt(i);
							break;
						}
					}
				}
				
				if( cc == 9 || cc == 10 || cc == 13 ) continue;
				
				if( cc > 32) {
					
					str += code.charAt(i);
						
				}else if( ccm1 > 32 ) {
					if( !compactOperator || (ccm1 != 59 && ccm1 != 125 && ccm1 != 123 && ccm1 != 41 && ccm1 != 40 && 
						ccm1 != 44 && ccm1 != 61 && ccm1 != 58 && ccm1 != 42 && ccm1 != 47 && ccm1 != 43 && ccm1 != 45 && ccm1 != 60 && ccm1 != 62) ) { 
							if( i < L-1 )
							{
								cc2 = code.charCodeAt( i + 1);
								
if(!compactOperator || (cc2 != 59 && cc2 != 125 && cc2 != 123 && cc2 != 44 && cc2 != 61 && cc2 != 58 && cc2 != 42 && cc2 != 47 && cc2 != 43 && cc2 != 45 && cc2 != 60 && cc2 != 62) ) {
								
									str += code.charAt(i);
								}
							}else{
							
								str += code.charAt(i);
							}
					}
				}
				
				ccm1 = cc;
			}
			return str;
		}

		public static function trim (e:String) :String {
			var str:String = "";
			var i:int;
			var igstart:int=0;
			for(i=0; i<e.length; i++) {
				if(e.charCodeAt(i) > 32) {
					igstart = i;	
					break;	
				}
			}
			if(igstart > 0) e = e.substring(igstart, e.length);
			str = e.charCodeAt(e.length-1) <= 32 ? "" : e.charAt(e.length-1);
			for(i=e.length-2; i>=0; i--) {
				if(e.charCodeAt(i) > 32 || e.charCodeAt(i+1) > 32) {
					str = e.charAt(i) + str;
				}
			}
			return str;
		}
		
		private static function setup () :void {
			sc = singleComment.length;
			if( sc == 0 ) {
				trimSingleComment = false;
			}else{
				sc1 = singleComment.charCodeAt(0);
				if( sc >= 2) sc2 = singleComment.charCodeAt(1);
			}
			mco = multiOpen.length;
			if( mco == 0 ) {
				trimMultiComment = false;
			} else {
				mco1 = multiOpen.charCodeAt(0);
				if( mco >= 2) mco2 = multiOpen.charCodeAt(1);
			}
			
			mcc = multiClose.length;
			if( mcc == 0 ) {
				trimMultiComment = false;
			}else{
				mcc1 = multiClose.charCodeAt(0);
				if( mcc >= 2) mcc2 = multiClose.charCodeAt(1);
			}
		}
		
		// c, java, ecma etc
		public static function compactScript (scr:String) :String {
			trimWhite = true;
			compactOperator = true;
			leaveWhiteAroundBrackets = false;
			trimSingleComment = true;
			trimMultiComment = true;
			singleComment = "//";
			multiOpenFollowAbort = "";
			multiOpen = "/*";
			multiClose = "*/";
			return compact(scr);
		}
		// Css Files
		public static function compactStyle (style:String) :String {
			trimWhite = true;
			trimSingleComment = false;
			trimMultiComment = true;
			compactOperator = true;
			leaveWhiteAroundBrackets = true;
			singleComment = "";
			multiOpenFollowAbort = "";
			multiOpen = "/*";
			multiClose = "*/";
			return compact(style);
		}
		public static function compactSql (sql:String) :String {
			trimWhite = true;
			trimSingleComment = true;
			trimMultiComment = true;
			compactOperator = false;
			leaveWhiteAroundBrackets = true;
			singleComment = "#";
			multiOpenFollowAbort = "";
			multiOpen = "/*";
			multiClose = "*/";
			return compact(sql);
		}
		// Html, Xml
		public static function compactHtml (htm:String) :String {
			// TODO: support inline scripts in html files etc. inlineScript = true;
			trimWhite = true;
			trimSingleComment = false;
			trimMultiComment = true;
			compactOperator = false; // leave white around ",= etc
			leaveWhiteAroundBrackets = false;
			multiOpenFollowAbort = "<>[/";
			multiOpen = "<!--";
			multiClose = "-->";
			
			return compact(htm);
		}
		public static function removeHtmlComments (htm:String) :String {
			// TODO: support inline scripts in html files etc. inlineScript = true;
			trimWhite = false;
			trimSingleComment = false;
			trimMultiComment = true;
			compactOperator = false; // leave white around ",= etc
			leaveWhiteAroundBrackets = true;
			multiOpenFollowAbort = "";// "<>[/";
			multiOpen = "<!--";
			multiClose = "-->";
			
			return compact(htm);
		}
		private static var inlineScript:Boolean=false;
		private static var inlineStyle:Boolean=false;
		public static var inlineScriptOP:Array = ["<script..>","</script>","<?php "," ?>", "<? ", " ?>", "<% ", " %>"];
		public static var inlineStyleOP:Array = ["<style","</style>"];
		
		public static var trimWhite:Boolean = true;
		public static var trimSingleComment:Boolean = true;
		public static var trimMultiComment:Boolean = true;
		
		// Comment Setup
		public static var leaveWhiteAroundBrackets:Boolean = false;
		public static var compactOperator:Boolean = true;
		
		public static var singleComment:String = "//";
		public static var multiOpen:String     = "/*";
		public static var multiClose:String    = "*/";
		public static var multiOpenFollowAbort:String    = "";
		
		private static var sc:int;
		private static var sc1:int;
		private static var sc2:int;
		
		private static var mco:int;
		private static var mco1:int;
		private static var mco2:int;
		private static var mcc:int;
		private static var mcc1:int;
		private static var mcc2:int;
		
		private static var sc_start:int;
		private static var sc_end:int;
	}
	
}
