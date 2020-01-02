﻿package agf.html
{
	import flash.xml.*;
	import agf.tools.Console;
	
	/**
	* HtmlParser helps with String Parsing
	* 
	* - Convert Html5 to XML strict 
	* - Convert XML to DB-Text with [/] replaced
	* - Convert DB-Text to XML Strict
	**/
	public class HtmlParser
	{
		public static var cssFiles:Array;
		public static var scriptFiles:Array;
		
		/*
		// HTML SYNTAX FOR DB TEXT FOR RICHTEXT INPUTS
		// Parse rich text from text in db to valid html5
		// [tag arg1=""..]content[/tag] and single tags [tag arg1=""..]
		// [br] -> <br/>
		// [b]Fetter Text(Bold Text)[/b] -> <b>Fetter Text(Bold Text)</b>
		// [i]Kursiver Text(Italic Text)[/i] -> <i>Kursiver Text(Italic Text)</i>
		// [a href=google.de]Click Here[/a] -> <a href=url>Click Here</a:
		// [img src=bild.jpg width=550 height=335] -> <img src=src width=width height=height/>
		//
		// To add allowd tags, add the name aof the tag prefixed with an underscore (_) to HtmlParser.allowedDBTags 
		//
		// A DEPRECATED HTML DB TEXT SYNTAX IS ALSO AVAILABLE IN RICHTEXT INPUTS, NESTED TAGS ARE NOT ALLOWED: #A:url(c.com):link #B:text#/B#/A
		// #prop# --> Object Property Value
		// #name# --> DB-Item-Name
		// #L:English Label# --> German or English Text
		// #L:name# --> German or English version of Text Of Item Name
		// #S:32:name# --> German Tex... display only the first 32 characters in name (Start)
		// #E:32:name# --> German Tex... display only the last 32 characters in name (End)
		// #C:css-calss:text#
		// #B:Bold Text# --> <b>German Bold Text</b>
		// #I:Italic Text# --> <i>German Italic Text</i>
		// #A:url(url.com):Link Text# --> <a href=url>German Link Text</a>
		// #T:url(img-path.gif):css-classes# --> <div class=css-classes><img src=url/></div>
		// #P:url(img-path.gif):css-classes# <img src=url class=css-classes>
		// #br# --> <br/> if isHtml or \n
		// #hr# --> <hr/>
		// #tab# --> return three "nbsp;" if isHtml is true, or three whitespaces
		// #app-name# --> CTOptions.appName
		// #app-verison# --> CTOptions.version
		// #template-name# --> Name or Root Template
		// #insert-template# --> Name of Sub Template while inserting or updating a subtemplate item
		// #insert-area# --> Name of the Area an item is inserted or updated
		// #insert-property# --> Name of Property that is inserted in Settings (ConstantsEditor)
		// ... 
		*/
		
		public static var allowedDBTags:Object = {
			_a:true, _b:true, _br:true, _div:true, _hr:true, _i:true, _img:true, _p:true, _h1:true, _h2:true, _h3:true, _h4:true, _h5:true, _h6:true, _h7:true, _span:true, _u:true 
		};
		
		public static function toDBText ( code:String ) :String
		{
			//47:/, 42:*, 34:", 91:[, 93:], 35:#, 38: &, 44:,, 46:., 58::, 59:;, 64:@, 123:{, 125:}, 60:<, 62:>,  8222: „, 8220: “,
			var xml_str:String = "";
			var cc:int;
			var nam:String;
			var namlc:String;
			var aname:String;
			var avalue:String;
			var astr:String;
			var ast:int;
			var aen:int;
			var st:int;
			var en:int;
			var en2:int;
			var j:int;
			var k:int;
			var L:int = code.length;
			var cc1:int;
			var cc2:int;
			var lc:int = L-1;
			var qval:Boolean;
			var qvalcc:int;
			var ag:Object;
			var writeChar:Boolean;
			
			for(var i:int=0; i<L; i++)
			{
				cc = code.charCodeAt(i);
				writeChar = true;
				
				if ( cc == 60 ) // <
				{
					if(L < i+2) break; // end of file error
					
					cc1 = code.charCodeAt( i+1 );
					
					if( cc1 == 33 ) { // ! <! processing instruction
						// search instruction end char >
						for(j=i+2; j < L; j++) {
							cc = code.charCodeAt(j);
							if( cc == 62 ) {
								break;
							}
						}
						i = j;
						writeChar = false;
					
					}
				//	else if( cc1 == 47 ) // tag-close
					else
					{ // tag-open
						st = i+1;
						en = i+2;
						
						// search next whitspace || >
						for(j=i; j<L; j++) {
							cc2 = code.charCodeAt( j );
							if( cc2 <= 32 || cc2 == 62) {
								en = j;
								break;
							}
						}
						nam = code.substring( st, en );
						namlc = nam.toLowerCase();
						
						// skip nodes..
						if( nam.charCodeAt(0) == 47 ) {
							if( allowedDBTags["_"+nam.substring(1)] != true ) {
								if( cc2 != 62 ) {
									for( j=en+2; j<L; j++ ) {
										cc2 = code.charCodeAt( j );
										if( cc2 == 62 ) { // >
											i = j;
											writeChar = false;
											break;
										}
									}
								}else{
									i = j;
									writeChar = false;
								}
							}
						}else{
							if( allowedDBTags["_"+nam] != true ) {
								
								if( cc2 != 62 ) {
									for( j=en+2; j<L; j++ ) {
										cc2 = code.charCodeAt( j );
										if( cc2 == 62 ) { // >
											i = j;
											writeChar = false;
											break;
										}
									}
								}else{
									i = j;
									writeChar = false;
								}
								
							}
						}
						
						if( cc2 != 62 && writeChar )
						{
							en2 = en;
							aname = "";
							avalue = "";
							ast = -1;
							astr = "";
							qval = false;
							qvalcc = 0;
							ag = {};
							
							// search node arguments
							for( j=en+2; j<L; j++ )
							{
								cc2 = code.charCodeAt( j );
								
								if( cc2 == 62 ) // > node end
								{
									if(!qval && ast != -1 && aname) {
										aen = j;
										avalue = code.substring( ast, aen );
										astr += " " + aname + '="' + avalue + '"';
										ast = -1;
										ag[aname] = avalue;
									}
									if( voidElements[namlc] ) {
										xml_str += "[" + nam + astr+"/]";
									}else{
										xml_str += "[" + nam + astr+"]";
									}
									i = j;
									writeChar = false;
									//processNodeArgument( namlc, ag );
									break;
								}
								else if( cc2 == 47 ) // '/'
								{
									if( code.charCodeAt(j+1) == 62 ) { // >
										// XML Strict Single Node
										if(!qval && ast != -1 && aname) {
											aen = j;
											avalue = code.substring( ast, aen );
											astr += " " + aname + '="' + avalue + '"';
											ast = -1;
											ag[aname] = avalue;
										}
										xml_str += "[" + nam + astr+"/]";
										i = j+1;
										writeChar = false;
									//	processNodeArgument( namlc, ag );
										break;
									}
								}
								else if( ast == -1 && cc2 == 61 ) // =
								{ 
									// argument name:
									aname = code.substring( en2+1, j );
									ast = j+1;
								}
								else if( ast != -1 && (cc2 == 34 || cc2 == 39 ) ) // "' 
								{
									if( qval ) {
										if( cc2 == qvalcc ) {
											aen = j+1;
											avalue = code.substring( ast, aen );
											astr += " " + aname + "=" + avalue;
											qval = false;
											qvalcc = 0;
											ast = -1;
											ag[aname] = CssUtils.trimQuotes( avalue );
											aname = "";
											avalue = "";
											en2 = aen;
										}
									}else{
										// Value in quotes
										qval = true;
										qvalcc = cc2;
									}
								}else if( ast != -1 && cc2 <= 32 && !qval ){
									// argument value
									aen = j;
									avalue = code.substring( ast, aen );
									if( !avalue || avalue == "" || avalue == " " ) avalue = aname;
									astr += " " + aname + '="' + avalue + '"';
									ast = -1;
									ag[aname] = avalue;
									aname = "";
									avalue = "";
									en2 = aen;
								}else if( !qval && !aname && cc2 <= 32 ) {
									aname = code.substring( en2+1, j );
									if(aname && aname != " "){
										// no value argument
										aen = j;
										astr += " " + aname + '="' + aname + '"';
										ast = -1;
										ag[aname] = aname;
										aname = "";
										avalue = "";
										en2 = aen;
									}
								}
							}// run through args per char
						} // if cc == 62 >
					} // if cc1 != '!' AND cc1 != '/'
				} // if cc == 60 // <
				
				if( writeChar ) {
					if( cc == 60 ) xml_str += "[";
					else if( cc == 62 ) xml_str += "]";
					else xml_str += String.fromCharCode(cc);
				}
			}// for char codes
			return xml_str;
		}
		
		
		public static function fromDBText ( code:String /*, compact:Boolean=true, ignoreProcInstr:Boolean=false*/ ) :String
		{
			//47:/, 42:*, 34:", 91:[, 93:], 35:#, 44:,, 46:., 58::, 59:;, 64:@, 123:{, 125:}, 60:<, 62:>,
			
			var xml_str:String = "";
			var cc:int;
			var nam:String;
			var namlc:String;
			var aname:String;
			var avalue:String;
			var astr:String;
			var ast:int;
			var aen:int;
			var st:int;
			var en:int;
			var en2:int;
			var j:int;
			var k:int;
			var L:int = code.length;
			var cc1:int;
			var cc2:int;
			var lc:int = L-1;
			var qval:Boolean;
			var qvalcc:int;
			var ag:Object;
			var writeChar:Boolean;
			
			for(var i:int=0; i<L; i++)
			{
				cc = code.charCodeAt(i);
				writeChar = true;
				
				if ( cc == /*60*/ 91 ) // <
				{
					if(L < i+2) break; // end of file error
					
					cc1 = code.charCodeAt( i+1 );
					
					if( cc1 == 33 ) { // ! <! processing instruction
						// search instruction end char >
						for(j=i+2; j < L; j++) {
							cc = code.charCodeAt(j);
							if( cc == /*62*/93 ) {
								break;
							}
						}
						i = j;
						writeChar = false;
					
					}
				//	else if( cc1 == 47 ) // tag-close
					else
					{ // tag-open
						st = i+1;
						en = i+2;
						
						// search next whitspace || >
						for(j=i; j<L; j++) {
							cc2 = code.charCodeAt( j );
							if( cc2 <= 32 || cc2 == /*62*/ 93) {
								en = j;
								break;
							}
						}
						nam = code.substring( st, en );
						namlc = nam.toLowerCase();
						
						// skip nodes..
						if( nam.charCodeAt(0) == 47 ) {
							if( allowedDBTags["_"+nam.substring(1)] != true ) {
								if( cc2 != /*62*/ 93 ) {
									for( j=en+2; j<L; j++ ) {
										cc2 = code.charCodeAt( j );
										if( cc2 == /*62*/ 93 ) { // >
											i = j;
											writeChar = false;
											break;
										}
									}
								}else{
									i = j;
									writeChar = false;
								}
							}
						}else{
							if( allowedDBTags["_"+nam] != true ) {
								
								if( cc2 != /*62*/ 93 ) {
									for( j=en+2; j<L; j++ ) {
										cc2 = code.charCodeAt( j );
										if( cc2 == /*62*/ 93 ) { // >
											i = j;
											writeChar = false;
											break;
										}
									}
								}else{
									i = j;
									writeChar = false;
								}
								
							}
						}
						
						if( cc2 != /*62*/ 93 && writeChar )
						{
							en2 = en;
							aname = "";
							avalue = "";
							ast = -1;
							astr = "";
							qval = false;
							qvalcc = 0;
							ag = {};
							
							// search node arguments
							for( j=en+2; j<L; j++ )
							{
								cc2 = code.charCodeAt( j );
								
								if( cc2 == /*62*/ 93 ) // > node end
								{
									if(!qval && ast != -1 && aname) {
										aen = j;
										avalue = code.substring( ast, aen );
										astr += " " + aname + '="' + avalue + '"';
										ast = -1;
										ag[aname] = avalue;
									}
									if( voidElements[namlc] ) {
										xml_str += "<" + nam + astr+"/>";
									}else{
										xml_str += "<" + nam + astr+">";
									}
									i = j;
									writeChar = false;
									//processNodeArgument( namlc, ag );
									break;
								}
								else if( cc2 == 47 ) // '/'
								{
									if( code.charCodeAt(j+1) == /*62*/ 93 ) { // >
										// XML Strict Single Node
										if(!qval && ast != -1 && aname) {
											aen = j;
											avalue = code.substring( ast, aen );
											astr += " " + aname + '="' + avalue + '"';
											ast = -1;
											ag[aname] = avalue;
										}
										xml_str += "<" + nam + astr+"/>";
										i = j+1;
										writeChar = false;
									//	processNodeArgument( namlc, ag );
										break;
									}
								}
								else if( ast == -1 && cc2 == 61 ) // =
								{ 
									// argument name:
									aname = code.substring( en2+1, j );
									ast = j+1;
								}
								else if( ast != -1 && (cc2 == 34 || cc2 == 39 ) ) // "' 
								{
									if( qval ) {
										if( cc2 == qvalcc ) {
											aen = j+1;
											avalue = code.substring( ast, aen );
											astr += " " + aname + "=" + avalue;
											qval = false;
											qvalcc = 0;
											ast = -1;
											ag[aname] = CssUtils.trimQuotes( avalue );
											aname = "";
											avalue = "";
											en2 = aen;
										}
									}else{
										// Value in quotes
										qval = true;
										qvalcc = cc2;
									}
								}else if( ast != -1 && cc2 <= 32 && !qval ){
									// argument value
									aen = j;
									avalue = code.substring( ast, aen );
									if( !avalue || avalue == "" || avalue == " " ) avalue = aname;
									astr += " " + aname + '="' + avalue + '"';
									ast = -1;
									ag[aname] = avalue;
									aname = "";
									avalue = "";
									en2 = aen;
								}else if( !qval && !aname && cc2 <= 32 ) {
									aname = code.substring( en2+1, j );
									if(aname && aname != " "){
										// no value argument
										aen = j;
										astr += " " + aname + '="' + aname + '"';
										ast = -1;
										ag[aname] = aname;
										aname = "";
										avalue = "";
										en2 = aen;
									}
								}
							}// run through args per char
						} // if cc == 62 >
					} // if cc1 != '!' AND cc1 != '/'
				} // if cc == 60 // <
				
				if( writeChar ) {
					if( cc == 91 ) xml_str += "<";
					else if( cc == 93 ) xml_str += ">";
					else xml_str += String.fromCharCode(cc);
				}
			}// for char codes
			return xml_str;
		}
		
		
		/**
		* Translate Html5 Text to Xml Text
		* TODO Test whitespace after equal (=)
		*
		* @param str a valid HTML5 string
		* @param compact remove whitespace and comments
		* @param ignoreProcInstr leave processing instructions in comments
		* @return a xhtml strict formated xml string
		*/
		public static function toXml ( str:String, compact:Boolean=true, ignoreProcInstr:Boolean=false) :String
		{
			cssFiles = [];
			scriptFiles = [];
			
			var code:String;
			if( compact) {
				code = CompactCode.compactHtml(str);
			}else{
				code = str;
			}
			
			var xml_str:String = "";
			var cc:int;
			var nam:String;
			var namlc:String;
			var aname:String;
			var avalue:String;
			var astr:String;
			var ast:int;
			var aen:int;
			var st:int;
			var en:int;
			var en2:int;
			var j:int;
			var k:int;
			var L:int = code.length;
			var cc1:int;
			var cc2:int;
			var lc:int = L-1;
			var qval:Boolean;
			var qvalcc:int;
			var ag:Object;
			var writeChar:Boolean;
			
			for(var i:int=0; i<L; i++)
			{
				cc = code.charCodeAt(i);
				writeChar = true;
				
				if ( cc == 60 ) // <
				{
					if(L < i+2) break; // end of file error
					
					cc1 = code.charCodeAt( i+1 );
					
					if( cc1 == 33 ) { // ! <! processing instruction
						if( ignoreProcInstr ) {
							// search instruction end char >
							for(j=i+2; j < L; j++) {
								cc = code.charCodeAt(j);
								if( cc == 62 ) {
									break;
								}
							}
							i = j;
							writeChar = false;
						}else{
							// search instruction end char >
							// copy instruction to xml
							for(j=i; j<L; j++) {
								cc = code.charCodeAt(j);
								xml_str += String.fromCharCode(cc);
								if( cc == 62 ) {
									break;
								}
							}
							i = j;
							writeChar = false;
						}
					}
					else
					{ // tag-open
						st = i+1;
						en = i+2;
						
						// search next whitspace || >
						for(j=i; j<L; j++) {
							cc2 = code.charCodeAt( j );
							if( cc2 <= 32 || cc2 == 62) {
								en = j;
								break;
							}
						}
						nam = code.substring( st, en );
						namlc = nam.toLowerCase();
						
						if( cc2 != 62 )
						{
							en2 = en;
							aname = "";
							avalue = "";
							ast = -1;
							astr = "";
							qval = false;
							qvalcc = 0;
							ag = {};
							
							// search node arguments
							for( j=en+2; j<L; j++ )
							{
								cc2 = code.charCodeAt( j );
								
								if( cc2 == 62 ) // > node end
								{
									if(!qval && ast != -1 && aname) {
										aen = j;
										avalue = code.substring( ast, aen );
										astr += " " + aname + '="' + avalue + '"';
										ast = -1;
										ag[aname] = avalue;
									}
									if( voidElements[namlc] ) {
										xml_str += "<" + nam + astr+"/>";
									}else{
										xml_str += "<" + nam + astr+">";
									}
									i = j;
									writeChar = false;
									processNodeArgument( namlc, ag );
									break;
								}
								else if( cc2 == 47 ) // '/'
								{
									if( code.charCodeAt(j+1) == 62 ) { // >
										// XML Strict Single Node
										if(!qval && ast != -1 && aname) {
											aen = j;
											avalue = code.substring( ast, aen );
											astr += " " + aname + '="' + avalue + '"';
											ast = -1;
											ag[aname] = avalue;
										}
										xml_str += "<" + nam + astr+"/>";
										i = j+1;
										writeChar = false;
										processNodeArgument( namlc, ag );
										break;
									}
								}
								else if( ast == -1 && cc2 == 61 ) // =
								{ 
									// argument name:
									aname = code.substring( en2+1, j );
									ast = j+1;
								}
								else if( ast != -1 && (cc2 == 34 || cc2 == 39 ) ) // "' 
								{
									if( qval ) {
										if( cc2 == qvalcc ) {
											aen = j+1;
											avalue = code.substring( ast, aen );
											astr += " " + aname + "=" + avalue;
											qval = false;
											qvalcc = 0;
											ast = -1;
											ag[aname] = CssUtils.trimQuotes( avalue );
											aname = "";
											avalue = "";
											en2 = aen;
										}
									}else{
										// Value in quotes
										qval = true;
										qvalcc = cc2;
									}
								}else if( ast != -1 && cc2 <= 32 && !qval ){
									// argument value
									aen = j;
									avalue = code.substring( ast, aen );
									if( !avalue || avalue == "" || avalue == " " ) avalue = aname;
									astr += " " + aname + '="' + avalue + '"';
									ast = -1;
									ag[aname] = avalue;
									aname = "";
									avalue = "";
									en2 = aen;
								}else if( !qval && !aname && cc2 <= 32 ) {
									aname = code.substring( en2+1, j );
									if(aname && aname != " "){
										// no value argument
										aen = j;
										astr += " " + aname + '="' + aname + '"';
										ast = -1;
										ag[aname] = aname;
										aname = "";
										avalue = "";
										en2 = aen;
									}
								}
							}// run through args per char
						} // if cc == 62 >
					} // if cc1 != '!' AND cc1 != '/'
				} // if cc == 60 // <
				
				if( writeChar ) xml_str += String.fromCharCode(cc);
			}// for char codes
			return xml_str;
		}
		
		// TODO add all html single-only tags (br, img etvc.) to voidElements
		public static var voidElements:Object = {
			br: true,
			hr:true,
			input:true,
			button:true,
			img: true,
			meta: true,
			link:true,
			path:true
		}
		
		public static function processNodeArgument ( nam:String, args:Object ) :void {
			if( nam == "link" ) {
				if( args.rel == "stylesheet" && args.href ) {
					cssFiles.push( args.href );
				}
			}else if( nam == "script" ) {
				if( args.src ) {
					scriptFiles.push(args.src);
				}else{
					// inline script
				}
			}
		}
		
	}
}