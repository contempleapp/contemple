package agf.html
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
		// [a href=google.de]Click Here[/a] -> <a href=google.de>Click Here</a>
		// [img src=bild.jpg width=550 height=335] -> <img src=src width=width height=height/>
		//
		// To add allowd tags, add the name af the tag prefixed with an underscore (_) to HtmlParser.allowedDBTags 
		//
		// A DEPRECATED HTML DB TEXT SYNTAX IS ALSO AVAILABLE IN RICHTEXT INPUTS, NESTED TAGS ARE NOT ALLOWED
		// #prop# --> Object Property Value
		// #name# --> DB-Item-Name
		// #L:English Label# --> German or English Text
		// #L:string text# --> German or English version of Text Of Item Name
		// #S:32:string text# --> German Tex... display only the first 32 characters in name (Start)
		// #E:32:string text# --> German Tex... display only the last 32 characters in name (End)
		// #C:css-cals:text# --> <span class="css-cols">text</span>
		// #B:Bold Text# --> <b>German Bold Text</b>
		// #I:Italic Text# --> <i>German Italic Text</i>
		// #A:url(url.com):Link Text# --> <a href=url>German Link Text</a>
		// #T:url(img-path.gif):css-classes# --> <div class=css-classes><img src=url/></div>
		// #P:url(img-path.gif):css-classes# <img src=url class=css-classes>
		// #at# --> @
		// #br# --> <br/> if isHtml or \n
		// #hr# --> <hr/>
		// #tab# --> return three "nbsp;" if isHtml is true, or three whitespaces
		// #quote# --> "
		// #squote# --> '
		// #app-name# --> CTOptions.appName
		// #app-verison# --> CTOptions.version
		// #template-name# --> Name or Root Template
		// #insert-template# --> Name of Sub Template while inserting or updating a subtemplate item
		// #insert-area# --> Name of the Area an item is inserted or updated
		// #insert-property# --> Name of Property that is inserted in Settings (ConstantsEditor)
		// ... 
		*/
		
		public static var allowedDBTags:Object = {
			_a:true,
			_abbr:true,
			_address:true,
			_area:true,
			_aside:true,
			_audio:true,
			_b:true,
			_bdi:true,
			_bdo:true,
			_blockqutoe:true,
			_br:true,
			_button:true,
			_canvas:true,
			_caption:true,
			_cite:true,
			_code:true,
			_col:true,
			_colgroup:true,
			_command:true,
			_data:true,
			_datalist:true,
			_del:true,
			_details:true,
			_div:true,
			_dd:true,
			_dfn:true,
			_dl:true,
			_dt:true,
			_em:true,
			_embed:true,
			_fieldset:true,
			_figure:true,
			_figcaption:true,
			_footer:true,
			_form:true,
			_header:true,
			_hr:true,
			_h1:true,
			_h2:true,
			_h3:true,
			_h4:true,
			_h5:true,
			_h6:true,
			_i:true,
			_iframe:true,
			_img:true,
			_input:true,
			_ins:true,
			_kbd:true,
			_keygen:true,
			_label:true,
			_li:true,
			_legend:true,
			_main:true,
			_map:true,
			_mark:true,
			_math:true,
			_menu:true,
			_meter:true,
			_object:true,
			_ol:true,
			_optgroup:true,
			_option:true,
			_output:true,
			_p:true,
			_param:true,
			_pre:true,
			_progress:true,
			_q:true,
			_nav:true,
			_ruby:true,
			_rp:true,
			_rt:true,
			_script:true,
			_section:true,
			_select:true,
			_s:true,
			_samp:true,
			_small:true,
			_source:true,
			_span:true,
			_strong:true,
			_sub:true,
			_sup:true,
			_summary:true,
			_svg:true,
			_table:true,
			_tbody:true,
			_td:true,
			_textarea:true,
			_thead:true,
			_tfoot:true,
			_th:true,
			_tr:true,
			_time:true,
			_track:true,
			_ul:true,
			_u:true ,
			_var:true,
			_video:true,
			_wbr:true
		};
		
		
		// transform #BR#, #AT#, #QUOTE# and #SQUOTE# in Strings
		public static function toInputText ( code:String ) :String
		{
			var rv:String = "";
			var L:int = code.length;
			var in35:Boolean = false;
			var cc:int;
			var cs:int;
			var tmp:String;
			var j:int;
			var writeChar:Boolean;
			
			for(var i:int=0; i<L; i++)
			{
				cc = code.charCodeAt(i);
				writeChar = true;
				
				if( cc == 35 ) {
					
					// #
					for( j = i+1; j<L; j++ ) {
						
						if( code.charCodeAt(j) == 35 )
						{
							tmp = code.substring( i, j+1 ).toLowerCase();
							
							if( tmp == "#br#" ) {
								rv += "\n";
								i=j;
								writeChar = false;
							}else if( tmp == "#at#" ) {
								rv += "@";
								i=j;
								writeChar = false;
								
							// TODO FIX " and ' errors in InputTextBox textEnter..
							
							}else if( tmp == "#quote#" ) {
								rv += '"';
								i=j;
								writeChar = false;
							}else if( tmp == "#squote#" ) {
								rv += "'";
								i=j;
								writeChar = false;
							/*}else if( tmp == "#lt#" ) {
								rv += '<';
								i=j;
								writeChar = false;
							}else if( tmp == "#gt#" ) {
								rv += '<';
								i=j;
								writeChar = false;*/
							}
							break;
						}
					}
				}
				
				if( writeChar ) {
					
					rv += String.fromCharCode( cc );
				}
			}
			return rv;
		}
		
		public static function toDBText ( code:String, transformNewline:Boolean=false, transformQuotes:Boolean=false ) :String
		{
			//47:/, 42:*, 34:", 39:', 91:[, 93:], 35:#, 38: &, 44:,, 46:., 58::, 59:;, 64:@, 123:{, 125:}, 60:<, 62:>,  8222: „, 8220: “,
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
										if( transformQuotes ) {
											astr += " " + aname + "='" + avalue + "'";
										}else{
											astr += " " + aname + '="' + avalue + '"';
										}
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
											if( transformQuotes ) {
												astr += " " + aname + "='" + avalue + "'";
											}else{
												astr += " " + aname + '="' + avalue + '"';
											}
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
											
											if( transformQuotes ) {
												avalue = "'"+CssUtils.trimQuotes( avalue )+"'";
											}
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
									
									if( transformQuotes ) {
										astr += " " + aname + "='" + avalue + "'";
									}else{
										astr += " " + aname + '="' + avalue + '"';
									}
									
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
										if( transformQuotes ) {
											astr += " " + aname + "='" + aname + "'";
										}else{
											astr += " " + aname + '="' + aname + '"';
										}
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
					else if( cc == 64 ) xml_str += "#AT#";
					else {
						if( transformNewline && (cc == 9 || cc == 10 || cc==13) ) {
							xml_str +="#BR#";
						}else if( transformQuotes && cc == 34) {
							xml_str += "#QUOTE#";
						}else if( transformQuotes && cc == 39) {
							xml_str += "#SQUOTE#";
						}else{
							xml_str += String.fromCharCode(cc);
						}
					}
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
