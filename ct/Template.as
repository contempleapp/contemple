package ct
{
	import agf.db.DBAL;
	import agf.html.CssUtils;
	import agf.utils.ColorUtils;
	import agf.utils.NumberUtils;
	import agf.utils.StringMath;
	import agf.tools.Application;
	import agf.Main;
	import agf.io.Resource;
	import agf.io.ResourceMgr;
	import agf.html.HtmlParser;
	import agf.tools.Console;
	import agf.utils.NumberUtils;
	import agf.utils.StringUtils;
	import ct.ctrl.InputTextBox;
	
	import flash.filesystem.File;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	public class Template
	{
		public function Template ( __type:String ) {
			type = __type;
		}
		
		public var sqlUid:int=0;
		public var genericPath:String="";         // The original template directory during installation or the /tmpl dir (read-only)
		public var relativePath:String = "tmpl";  // Relative path in the project directory, for root templates is "tmpl", for subtemplates "tmpl/a-subtemplate
		public var indexFile:String = "";         //"index.html"  // Index filename [ProjectDir]/[RelativePath]/[indexFile]
		public var indexStr:String="";               // index file string
		public var name:String="";                   // unique template name! Set any name in language help.xml file and use com.company.subtemplate-name
		public var version:String = "0.0.0";      // template version
		public var sortareas:String = "name";     // the string "name" or "priority" for sorting in editor
		public var sortproperties:String = "name";// the string "name" or "priority" for sorting in editor
		public var files:String="";                  // Template text files (only html, js css with template objects etc..)
		public var pagetemplates:String="";       // Template text files (only html)
		public var homeAreaName:String="";        // Name of area to display first
		public var imgdir:String="";              // Images Directory for MediaEdotor Images Add File
		public var articlepage:String="";         // page-template, optional page for the item
		public var articlename:String="";         // articlepage-name
		public var staticfiles:String="";        // Any additional files in the /raw and /min folders
		public var folders:String="";            // static folders in /raw and /min folders (duplicate)
		public var templatefolders:String="";    // static folder in /tmpl dir
		public var help:String="";               // name of the hep file in the template directory
		public var dbcmds:String="";             // name of the command-xml file for root templates only
		public var tables:String="";             // DB Table name
		public var fields:String="";             // DB Field names, comma separated
		
		public var defaultcontent:String="";  // XML File with default content wich can be installed as an option with the Theme. To generate the XML File, Run the following Command in Contemple: 'TemplateTools export-all' and copy the XML from the Console (MainMenu / Developer / Process Command )
		
		public var nolocation:Boolean = false;// Insert Html Anker Tags
		
		public var parselistlabel:Boolean = false;
		public var listlabel:String = "";   // Item Label of a Subtemplate in the Area Item List. Keywords with db-fields: #NAME# #SUBTEMPLATE# #SORTID# #AREA# etc can be used inside the String
		public var listicon:String = "";	// Icon of a Subtemplate in the Area Item List. for default icons use: ico:/falcon.png, or from the template directory: template:/st/icons/my-falcon.png
		public var hidden:Boolean = false;
	
		// dynamic objects filled with template data
		public var areasByName:Object = {};
		public var propertiesByName:Object = {}; // name:object
		public var filesByName:Object = {};      // name:urlstring
		
		public var jsfiles:Vector.<EmbedFile>;   // collect embed files of sub templates 
		public var cssfiles:Vector.<EmbedFile>;  // collect embed files of sub templates
		
		public var dbProps:Object = {};          // {name,uid,type,value}
		public var update:String="";
		
		internal static var randoms:Object = {};
		
		internal var stPageAreas:Object = {};
		
		
		private var _hiddenareas:String = "";
		public var hiddenAreasLookup:Object = {}; // read only
		public function get hiddenareas () :String {
			return _hiddenareas;
		}
		public function set hiddenareas (list:String) :void {
			_hiddenareas = list;
			var a:Array = list.split(",");
			hiddenAreasLookup = {};
			var L:int = a.length;
			for(var i:int=0; i<L; i++)
			{
				hiddenAreasLookup[a[i]] = true;
			}
		}
		
		private var _nolocareas:String;			 // comma separated list; exclude files from minify
		public var nolocAreasLookup:Object = {}; // read only
		public function get nolocareas () :String {
			return _nolocareas;
		}
		public function set nolocareas (list:String) :void {
			_nolocareas = list;
			var a:Array = list.split(",");
			nolocAreasLookup = {};
			var L:int = a.length;
			for(var i:int=0; i<L; i++)
			{
				nolocAreasLookup[a[i]] = true;
			}
		}
		
		private var _nocompress:String;			// comma separated list; exclude files from minify
		public var noCompressLookup:Object={};  // read only
		public function get nocompress () :String {
			return _nocompress;
		}
		public function set nocompress (list:String) :void {
			_nocompress = list;
			var a:Array = list.split(",");
			noCompressLookup = {};
			var L:int = a.length;
			for(var i:int=0; i<L; i++)
			{
				noCompressLookup[a[i]] = true;
			}
		}
		
		private var _type:String;
		private var _types:Vector.<String>;
		
		public function get numAreas () :int {
			var k:int=0;
			if( areasByName ) {
				for(var n:String in areasByName ) {
					k++;
				}
			}
			return k;
		}
		
		// Set single or multiple types
		public function set type ( t:String ) :void {
			var c:int = t.indexOf(",");
			if(c >= 0) {
				// got comma separated list of types
				setTypes ( t );
			}else{
				// Set first type only, leaving old types in typeList
				_type = t;
				if(!_types) _types = new Vector.<String>();
				_types[0] = t;
			}
		}
		public function get type() :String {
			return _type; // return first type
		}
		
		// Set comma separated string
		public function setTypes ( t:String ) :void {
			var cts:Array = t.split(",");
			var L:int = cts.length;
			_types = new Vector.<String>();
			if( L > 0 ) {
				for( var i:int=0; i<L; i++) {
					_types[i] = CssUtils.trim( cts[i] );
				}
				// Set first type
				_type = _types[0];
			}else{
				_types[0] = t;
				_type = t;
			}
		}
		
		public function get types () :Vector.<String> {
			return _types; // return type list
		}
		
		public static var richTextProps:Object = {};
		public static var prios:Object = { _: 100 };
		public static var preText:String="";
		
		public static function resetPrios () :void {
			prios = { _: 100 };
			// randoms = {};
		}
		public static function preproc (s:String, itemName:String="", pageName:String="") :String
		{
			// Definition starts with the string "#def:" and ends with the string "#def;"
			// Inside the def block Template Properties can be defined, ordered and categorized
			// first line = #def:
			// last line = #def;
			
			var L:int = s.length;
			var c:int;
			var i:int;
			var k:int;
			var tmp:String;
			var inHtmlComment:Boolean=false;
			
			c = s.indexOf("#def:");
			
			if( c >= 0 ) {
				i = c + 6;
			}else{
				return s;
			}
			
			// Preprocessor options:
			// #scope: target; 
			// #scope: global;
			// #scope; // set to global..
			// #def;   // end of definitions..
			//
			// Input:
			//   varname:type(arguments..)=value;
			// Outputs:                  ^
			//    {#scopetarget.10.varname:type(arguments..)=value}
			
			// ignore whitespace after #def:
			for(; i<L; i++ ) if( s.charCodeAt(i) > 32 ) break;
			
			var scope:String=""; // global
			tmp = s.substring(0,c);
			
			if( tmp.indexOf("<!--") >= 0 ) inHtmlComment = true;
			
			var rv:String = "";
			
			if ( ! inHtmlComment ) rv = "<!-- ";
			
			rv += "\n" + tmp;
			
			var t:int;
			var tmp2:String;
			var done:Boolean=false;
			var cursor:int = i;
			var prioStart:int=100;
			var prioInc:int=10;
			
			for(; i<L; i++) 
			{
				c = s.charCodeAt(i);
				
				if( c <= 32 ) continue; // ignore whitespace
				
				if( c == 34 || c == 39 ) { // ignore in strings..
					for(++i; i<L; i++) if( s.charCodeAt(i) == c ) break;
					// ignore whitespace after "
					for( ++i; i<L; i++ ) if( s.charCodeAt(i) > 32 ) break;
					i--;
					continue;
				}
				
				if( c == 35 ) { // #
					// test for scope or def instructions
					
					k = i+1;
					t = -1;
					
					for(; i<L; i++)
					{
						c = s.charCodeAt(i);
						if( c == 58 ) { // :
							t = i;
						}else if( c == 59 ) { //;
							if( t == -1 ) { // #instr; 
								tmp  = s.substring( k, i );
								tmp2 = "";
							}else{ // #instr:value; 
								tmp  = s.substring( k, t );
								tmp2 = s.substring( t+1, i );
							}
							
							if( tmp == "scope" ) {
								if( tmp2 == "global" ) tmp2 = "";
								scope = tmp2;
								if( prios["_"+scope] == undefined ) prios["_"+scope] = prioStart;
							}else if( tmp == "def" ) {
								// End Of Definitions..
								done = true;
							}
							
							// ignore whitespace after ;
							for( ++i; i<L; i++ ) if( s.charCodeAt(i) > 32 ) break;
							
							cursor = i;
							i--;
							break;
						}
					}
					
					if( done ) {
						if( !inHtmlComment ) {
							rv += "\n -->\n";
						}
						
						rv += s.substring( i );
						break;
					}
					
				}else if( c == 59 ) { // ;
					
					rv += "{#"+scope+ (scope == "" ? "":".") +  prios["_"+scope] + "." + s.substring( cursor, i )+ "}\n";
					preText = "";
					
					prios["_"+scope] += prioInc;
					
					// ignore whitespace after ;
					for( ++i; i<L; i++ ) { 
						if( s.charCodeAt(i) > 32 ) {
							break;
						}
					}
					cursor = i;
					i--;
					continue;
				}
			}
			
			return rv;
		}
		
		public static function parseFile (pf:ProjectFile, template:Template=null, pageItemName:String="", pageName:String="") :void
		{
			// Parse pf.template and store into pf.templateStruct, Areas and Properties
			pf.splits = false;
			pf.hasRandoms = false;
			pf.splitPath = "";
			
			var tmpl_struct:Array = [""];
			var areas:Vector.<Area> = new Vector.<Area>();
			 
			var areasByName:Object;
			var filesByName:Object;
			var propertiesByName:Object;
			var rm:ResourceMgr = ResourceMgr.getInstance();
			
			if(!template) {
				areasByName = { };
				propertiesByName = { };
				filesByName = { };
			}else{
				areasByName = template.areasByName;
				propertiesByName = template.propertiesByName;
				filesByName = template.filesByName;
			}
			var properties:Array = [];
			var tmpl:String = pf.getTemplate();
			
			tmpl = preproc(tmpl, pageItemName, pageName); 
			
			var isArea:Boolean;
			var nam:String;
			var sid:int=0;
			var L:int = tmpl.length;
			var L2:int;
			var namL:int;
			var j:int;
			var g:int;
			var gL:int;
			var cc:int;
			var cc2:int;
			var st:int;
			var en:int;
			var dp:int;
			var dp2:int;
			var dp3:int;
			var dp4:int;
			var dp5:int;
			var dp6:int;
			var bropen:int;
			var defType:String;
			var defValue:String;
			var tpy:String;
			var tpi:int;
			var argv:String;
			var _argv:String;
			var args:Array;
			var argName:String;
			var argValue:*;
			var stringArg:Boolean;
			var parseValue:Boolean;
			var writeChar:Boolean;
			var tps:Array;
			var tpsv:Vector.<String>;
			var k:int;
			var sections:Array;
			var sec:Array;
			var prios:Array;
			var prio:int;
			var eqs:Boolean;
			var tpe:String;
			var inSplit:Boolean = false;
			var splitsOpen:int;
			var splitPath:String="";
			var opfound:int;
			var split_operator:String;
			var split_value:String;
			var split_valueProp:*;
			var split_value_lc:String;
			var split_name:String;
			var splitCode:Boolean = false; // true if split parsed succesfully, otherwise the split code is interpreted as an area with a name like #special-area ({###special-area})
			var writeSplit:Boolean = true; // true in root scope ( or by condition in split scopes
			var spcc:int;
			var splitCondition:Boolean;
			var splitProp:*;
			var splitConditions:Vector.<Boolean>;  // Uplevel condition storage for resetting writeSplit after a subsplit
			var noType:Boolean = false;
			var procVal:String;
			var vecL:int;
			var vecType:String;
			var vecValues:Array;
			var vecArgs:Array;
			var vecWrap:Array;
			var vecWrapPre:String;
			var vecWrapPost:String;
			var vi:int;
			var viStart:int;
			var wrapSplit:Array;
			var defWrapPre:String;
			var defWrapPost:String;
			var defaultWWWFolder:String;
			var defaultRename:String;
			var defaultDescr:String;
			var defaultExtList:String;
			var vecProcVal:String;
			var vecValue:String;
			var brSplit:Array;
			var hasBr:Boolean;
			var t2tobj:Object;
			var t2tres:Resource;
			var t2tstr:String;
			var t2tnum:Number;
			var t2tpth:String;
			var t2ttmp:String;
			var atc:int;
			var atstr:String;
			var color:Object = {};
			var bmp:Bitmap;
			
			var re:RegExp = /#br#/gi;
			var area_args:String;
			var include_file:String;
			var bfound:Boolean=false;
			var smm:Boolean=false;
			var pftxt:ProjectFile;
			var filepath:String;
			var tmpdbprops:Object;
			var pftmp:ProjectFile = new ProjectFile("tmp");
			var file:File;
			var fileName:String;
			var stpg:Boolean;
			
			for(var i:int=0; i<L; i++) {
				
				cc = tmpl.charCodeAt( i );
				writeChar = true;
				
				switch( cc ) {
					case 123: // {
						
						if(  tmpl.charCodeAt( i+1 ) == 35 ) { // {# parse template key {# Property}, {## Area} and {### Split} codes
							
							if(i >= L-3) continue; // end of file error
							
							if( tmpl.charCodeAt( i+2 ) == 35 ) {
								// double ##
								st = i+3;
								isArea = true;
							}else{
								st = i+2;
								isArea = false;
								noType = false;
								defType = "";
								defValue = "";
								argv = "";
								args = null;
							}
							
							en = -1;
							// Found a template object...
							// search end key '}'
							bropen = 0;
							
							for(j=st; j<L; j++) {
								cc = tmpl.charCodeAt(j);
								// Ignore String values...
								if(cc == 34 || cc == 39) {
									for(;j<L; j++) if( tmpl.charCodeAt(j) == cc ) break;
								}else if( cc == 123 ) {
									bropen++;
								}
								else if( cc == 125 ) {
									// Found closing bracket : }
									if (bropen <= 0) {
										en = j;
										break;
									}
									else bropen--;
								}
							}
							
							if( en >= 0 )
							{
								nam = tmpl.substring( st, en );								
								
								if( isArea )
								{
									splitCode = false;
									
									if( nam.charCodeAt(0) == 35) // {### 
									{
										splitCode = true;
										
										if ( inSplit ) // End split or sub split opens...
										{
											// test if it is an end split: {###}
											if ( nam == "#" )
											{
												// end split
												
												if ( splitsOpen <= 1 ) {
													inSplit = false;
													// Root split closes
													inSplit = false;
													writeSplit = true;
												}else {
													writeSplit = splitConditions.pop();
													splitsOpen--;
												}
												
												// Ignore split end code:
												i = en;
												continue;
											}else {
												// another split opening
												splitsOpen++;
											}
										}else {
											if ( nam == "#" ) {
												// Ignore end codes in root scope
												if( CTOptions.debugOutput ) Console.log("Ignoring Unexpected End-Split Code In Root Scope At Position "+i );
												i = en;
												continue;
											}
											
											// a split in root scope opens
											splitConditions = new Vector.<Boolean>();
											splitsOpen = 1;
											inSplit = true;
										}
											
										// Test condition of the split or sub split and add or ignore the content to the sruct...
										// If condition is true.. add the split text to the tmeplate struct, and test sup split conditions to set local writeSplit var
										// If condition is false.. ignore the block until the end code of this split is found..
										
										// Extract name, operator and value from split object
										namL = nam.length;
										opfound = -1;
										
										split_operator = "";
										split_name = "";
										split_value = "";
										
										for (k = 1; k < namL; k++) {
											spcc = nam.charCodeAt(k);
											if ( spcc == 33 || spcc == 60 || spcc == 61 || spcc == 62 ) { // ! < = >
												opfound = k;
												split_name = CssUtils.trim(nam.substring(1, k));
												
												split_operator = nam.charAt(k);
												spcc = nam.charCodeAt(k + 1);
												if ( spcc == 33 || spcc == 60 || spcc == 61 || spcc == 62 ) { // ! < = >
													k++;
													split_operator += nam.charAt(k); // found two char operator: >= == <= !=
													if( nam.length >= k+2) {
														spcc = nam.charCodeAt(k + 1);
														if ( spcc == 33 || spcc == 60 || spcc == 61 || spcc == 62 ) { 
															k++;
															split_operator += nam.charAt(k); // found three char operator: >== === <== !==
														}
													}
												}
												
												split_value = CssUtils.trimQuotes( CssUtils.trim(nam.substring( k + 1 )) );
												
												split_value_lc = split_value.toLowerCase();
												
												if ( split_value_lc == "true") {
													split_valueProp = true;
												}else if ( split_value_lc == "false") {
													split_valueProp = false;
												}else if ( split_value_lc == "null") {
													split_valueProp = null;
												}else if ( split_value_lc == "undefined") {
													split_valueProp = undefined;
												}else if ( !isNaN( Number(split_value)) ) {
													split_valueProp = Number(split_value);
												}else {
													if ( split_value.charAt(0) == "*") {
														splitProp = Main( Application.instance ).strval( "{"+split_name+"}", false );
													}else{
														split_valueProp = split_value;
													}
												}
												
												splitCondition = false;
												splitProp = null;
											
												// Search the [name] in dpProps,
												if ( template && template.dbProps && template.dbProps[split_name] != undefined ) {
													splitProp = typeof template.dbProps[split_name] == "object" ? template.dbProps[split_name].value : template.dbProps[split_name];// template.dbProps[split_name].value;
												}else {
													// Search in properties for default value:
													gL = properties.length;
													for (g = 0; g < gL; g++) {
														if ( properties[g].name == split_name ) {
															splitProp = properties[g].defValue;
															break;
														}
													}
													if ( ! splitProp && pf.templateProperties) {
														//search in pf.templateProperties
														gL = pf.templateProperties.length;
														for (g = 0; g < gL; g++) {
															if ( pf.templateProperties[g].name == split_name ) {
																splitProp = pf.templateProperties[g].defValue;
															}
														}
													}
													
													if ( !splitProp ) {
														// Evaluate with strval
														splitProp = Main( Application.instance ).strval( split_name, true ); // EG: ###ct.CTTools.a_value == true
													}
												}
												
												if ( split_operator == "=" || split_operator == "==" ) {
													splitCondition = splitProp == split_valueProp;
												}else if ( split_operator == ">" ) {
													splitCondition = splitProp > split_valueProp;
												}else if ( split_operator == "<" ) {
													splitCondition = splitProp < split_valueProp;
												}else if ( split_operator == "<=" ) {
													splitCondition = splitProp <= split_valueProp;
												}else if ( split_operator == ">=" ) {
													splitCondition = splitProp >= split_valueProp;
												}else if ( split_operator == "!=" ) {
													splitCondition = splitProp != split_valueProp;
												}else if ( split_operator == "!==" ) {
													splitCondition = splitProp !== split_valueProp;
												}else if ( split_operator == "===" ) {
													splitCondition = splitProp === split_valueProp;
												}
												
												if ( splitCondition ) {
													// Continue
													writeSplit = true;
													splitConditions.push( true );
													pf.splits = true;
													pf.splitPath += "/"+split_name + ":" + split_value; // /layout:Full Size/subprop:0...
												}else {
													writeSplit = false;
													splitConditions.push( false );
													pf.splits = true;
													// Ignore Block
												}
												i = en;
												continue;
											}
										}
									}// if 3 ### (Split)  
									
									//else // NO SPLIT
									if( !splitCode ) {
										sid++;
										tmpl_struct[sid] = "";
										tpi = nam.lastIndexOf(":");
										tpy = "";
										
										if( tpi > 0 ) {
											tpy = CssUtils.trim( nam.substring( tpi + 1) );
											nam = nam.substring( 0, tpi );
										}
										
										// area agrs:
										tpi = nam.indexOf( "(" );
										args = [];
										argv = "";
										
										if( tpi >= 0 )
										{
											// Area Arguments...  bool, number, "string", {object}, [array]
											dp = nam.lastIndexOf( ")" );
											
											if( dp > tpi )
											{
												argv = nam.substring( tpi+1, dp );
												nam = CssUtils.trim( nam.substring( 0, tpi ) );
												
												L2 = argv.length;
												dp5 = 0;
												stringArg = false;
												
												for( j=0; j<L2; j++)
												{
													cc2 = argv.charCodeAt(j);
													if( cc2 == 34 || cc2 == 39 ) {
														// string
														
														stringArg = true;
														for( j++; j<L2; j++) {
															if( argv.charCodeAt(j) == cc2 ) {
																parseValue = true;
																break;
															}
														}
														if( j >= L2-1) {
															parseValue = true;
															j = L2;
														}
													}
													else if( cc2 == 123 ) { // {
														for( j++; j<L2; j++) {
															if( argv.charCodeAt(j) == 125 ) {
																parseValue = true;
																break;
															}
														}
														if( j >= L2-1) {
															parseValue = true;
															j = L2;
														}
													}
													else if( cc2 == 91 ) { // {
														for( j++; j<L2; j++) {
															if( argv.charCodeAt(j) == 93 ) {
																parseValue = true;
																break;
															}
														}
														if( j >= L2-1) {
															parseValue = true;
															j = L2;
														}
													}
													else if( cc2 == 44 ) { // ,
														parseValue = true;
														stringArg = false;
													}else{
														if( j >= L2-1) {
															parseValue = true;
															j = L2;
														}
													}
													if( parseValue ) {
														argName = argv.substring( dp5, j );
														
														argName = (argName == " " || argName == "' " || argName == '" ') ? "' '" : CssUtils.trim( argName );
														
														if( argName.charCodeAt(0) == 34 || argName.charCodeAt(0) == 39 ) {
															// String Value
															stringArg = true;
														}
														
														argName = CssUtils.trimQuotes( argName );
														
														if(argName == '"' || argName == "'" ) {
															argName = "";
															j++;
														}
														dp6 = argName.charCodeAt(0);
														
														if( dp6 == 42 ) { // * AS3-Reference
															if( !stringArg && argName.charAt(1) != "." )
															argValue = Application.instance.strval( "{" + argName + "}", false);
															else argValue = argName;
														}else if( dp6 == 91 ) { // List [
															argValue = CTOptions.JSONArgs ? JSON.parse(argName) : argName;
														}else if( dp6 == 123 ) { // Object [
															argValue = CTOptions.JSONArgs ? JSON.parse(argName) : argName;
														}else{ // Number
															if(!stringArg && argName && !isNaN(Number(argName))) 
																argValue = Number( argName );
															else 
																argValue = argName;
														}
														args.push( argValue );
														
														argName = "";
														stringArg = false;
														parseValue = false;
														dp5 = j+1;
														
														if(argv.charCodeAt(j) == 34 || argv.charCodeAt(j) == 39) {
															j++;
															dp5++;
														}
													}
												}
											}
										}
										
										// multiple area types:
										tpi = tpy.indexOf(",");
										if( tpi >= 0) {
											tps = tpy.split(",");
											tpsv = new Vector.<String>();
											for(k=0; k<tps.length; k++) {
												tpsv.push( CssUtils.trim( tps[k] ) );
											}
											tpy = tpsv[0];
										}else{
											tpsv = new Vector.<String>();
											tpsv[0] = CssUtils.trim(tpy);
										}
									
										sections = null;
										prio = 0;
										
										if( nam.indexOf(".") >= 0 ) {
											sections = nam.split(".");
											namL = sections.length;
											nam = sections[sections.length-1];
											sections.splice( sections.length-1, 1);
											if( sections.length > 0 && !isNaN(Number(sections[sections.length-1])) ) {
												prio = parseInt( sections[sections.length-1] );
												sections.splice( sections.length-1, 1 );
											}
										}
										stpg = false;
										
										if ( template && template.type != "root" )
										{
											if ( nam == "root" )
											{
												nam = tpsv.join(".");
												
												if ( CTTools.activeTemplate && CTTools.activeTemplate.areasByName[nam] != undefined ) {
													areasByName[nam] = areas[ areas.push( CTTools.activeTemplate.areasByName[nam] ) - 1];
													i = en;
													continue;
												}
											}
											else if ( nam == "this" )
											{
												nam = tpsv.join(".");
												stpg = true;
											}
											else
											{
												tpi = nam.indexOf(":");
												t2tstr = "";
												
												if ( tpi >= 0 ) {
													t2tstr = nam.substring(0, tpi).toLowerCase();
													nam = nam.substring(tpi + 1);
												}
												
												if ( t2tstr == "root" ) {
													if ( CTTools.activeTemplate && CTTools.activeTemplate.areasByName[nam] != undefined ) {
														areasByName[nam] = areas[ areas.push( CTTools.activeTemplate.areasByName[nam] ) - 1];
														i = en;
														continue;
													}
												}else if ( t2tstr == "this" ) {
													
												}else{
													if( sections ) {
														sections.splice(0,0,nam);
													}else{
														sections = [nam];
													}
													nam = pageItemName;
												}
											}
										}
										
										if ( areasByName[nam] ) {
											areas.push( areasByName[nam] );
										}else{
											areasByName[nam] = areas[ areas.push(new Area(st, en, sections, prio, nam, tpy, tpsv, args, argv)) - 1];
											if( sections && sections.length > 0 ) {
												areasByName[sections.join(".") + "." + nam] = areasByName[nam];
											}
										}
										
										if ( stpg ) {
											template.stPageAreas[nam] = areasByName[nam];
										}
										
										if( CTOptions.insertAreaLocation ) 											
										{
											if(!template || ( template.nolocareas != "true" && !template.nolocAreasLookup[nam]) ) {
												if( nam != "SCRIPT" && nam != "SCRIPT-BEGIN" && nam != "SCRIPT-END" && nam != "SCRIPT-OBJECT" && nam != "STYLE" && nam != "STYLE-BEGIN" && nam != "STYLE-END" && nam != "STYLE-OBJECT") {
													tmpl_struct[ sid > 0 ? sid - 1 : sid] += CTOptions.insertAreaPre + nam + CTOptions.insertAreaPost;
												}
											}
										}
									}
								}
								else
								{
									if ( !writeSplit ) {
										i = en;
										continue;
									}
									// Template Property:
									// Template Properties are constants in root templates that can be overiden by the database
									// In subtemplates, Template Properties are the database fields
									// the subtemplate-index file have the fields and tables attributes set up for sql querys and create the tables in the db.sql file
									// The sql field names and the corresponding property names have to be the same with case sensitivity
									//
									//
									// Overwiew:
									// 
									// X:Type(type-arguments)=Default-Value
									// 
									// X:Type("string", string)=type-value
									//
									// Example in css style use
									//
									//  {#OPACITY:Number(0.01,1,0.01)=0.5}
									//  {#FONT-SIZE:ScreenNumber=1.2em}
									//
									// Example in subtemplate-index.html use
									// {#db_field:RichText("","<p>|</p>")="Default text.."}
									// 
									//
									// Template Property Type Variables..
									// Type specific values can be used on some Template Properties
									// Eg. image.width etc:
									//
									// Define an image:
									//
									// {#my-image:Image("img","my-img-new.#EXTENSION#","Images for my-image","*.PNG;*.GIF;")="img/my-img.png"}
									//
									// Then its possible to get the width of the image using the @ character
									//
									// {#my-image@width}
									//
									// TODO
									// Add mor property type variables
									//
									
									atc = nam.indexOf("@");
									atstr = "";
									
									if( atc >= 1 ) {
										atstr = nam.substring( atc + 1 );
										nam = nam.substring( 0, atc );
									}
									
									nam.replace("#at#", "@");
									
									dp = nam.indexOf(":");
									namL = nam.length;
									args = null;
									argv = "";
									defType = "";
									defValue = "";
									
									if ( dp >= 0 )
									{
										// Search for =, ignore in strings
										dp2 = -1;
										eqs = false;
										for( j=dp+1; j<namL; j++) {
											cc = nam.charCodeAt(j);
											// Ignore String values...
											if(cc == 34 || cc == 39) {
												for(j++;j<namL; j++) if( nam.charCodeAt(j) == cc ) break;
											}
											else if( cc == 61) { // =
												dp2 = j;
												eqs = true;
												break;
											}else if( j >= namL-1 ) {
												dp2 = j;
												eqs = false;
												break;
											}
										}
										if ( !eqs ) {
											dp2 = namL;
										}
										if(dp2 >= 0) {
											if( dp < dp2 )
											{
												defType = CssUtils.trim( nam.substring( dp+1, dp2 ) ); // : bis = 
												defValue = dp2 < namL-1 ?  CssUtils.trim(nam.substring( dp2+1 )) : "";  // = bis ende
												nam = CssUtils.trim( nam.substring( 0, dp ) ); // 0 bis :
											}
										}
									}
									
									if ( defType ) 
									{
										dp3 = defType.indexOf("(");
										if ( dp3 >= 0 ) 
										{
											// Arguments: ()
											dp4 = defType.lastIndexOf(")");
											if ( dp4 >= 0 && dp4 > dp3 ) 
											{
												argv = CssUtils.trim(defType.substring( dp3+1, dp4 ));
												args = [];
												defType = CssUtils.trim(defType.substring(0, dp3)); // Trim Type
												
												L2 = argv.length;
												dp5 = 0;
												stringArg = false;
												
												for( j=0; j<L2; j++)
												{
													cc2 = argv.charCodeAt(j);
													if( cc2 == 34 || cc2 == 39 ) {
														// string
														stringArg = true;
														for( j++; j<L2; j++) {
															if( argv.charCodeAt(j) == cc2 ) {
																parseValue = true;
																break;
															}
														}
														if( j >= L2-1) {
															parseValue = true;
															j = L2;
														}
													}
													else if( cc2 == 123 ) { // {
														for( j++; j<L2; j++) {
															if( argv.charCodeAt(j) == 125 ) {
																parseValue = true;
																break;
															}
														}
														if( j >= L2-1) {
															parseValue = true;
															j = L2;
														}
													}
													else if( cc2 == 91 ) { // {
														for( j++; j<L2; j++) {
															if( argv.charCodeAt(j) == 93 ) {
																parseValue = true;
																break;
															}
														}
														if( j >= L2-1) {
															parseValue = true;
															j = L2;
														}
													}
													else if( cc2 == 44 ) { // ,
														parseValue = true;
														stringArg = false;
													}else{
														if( j >= L2-1) {
															parseValue = true;
															j = L2;
														}
													}
													if( parseValue ) {
														argName = argv.substring( dp5, j);
														
														argName = (argName == " " || argName == "' " || argName == '" ') ? "' '" : CssUtils.trim( argName );
														
														if( argName.charCodeAt(0) == 34 || argName.charCodeAt(0) == 39 ) {
															// String Value
															stringArg = true;
														}
														
														argName = CssUtils.trimQuotes( argName );
														
														if(argName == '"' || argName == "'" ) {
															argName = "";
															j++;
														}
														dp6 = argName.charCodeAt(0);
														
														if( dp6 == 42 ) { // * AS3-Reference
															if( !stringArg && argName.charAt(1) != "." )
															argValue = Application.instance.strval( "{" + argName + "}", false);
															else argValue = argName;
														}else if( dp6 == 91 ) { // List [
															argValue = CTOptions.JSONArgs ? JSON.parse(argName) : argName;
														}else if( dp6 == 123 ) { // Object [
															argValue = CTOptions.JSONArgs ? JSON.parse(argName) : argName;
														}else{ // Number
															if(!stringArg && argName && !isNaN(Number(argName))) 
																argValue = Number( argName );
															else 
																argValue = argName;
														}
														args.push( argValue );
														argName = "";
														stringArg = false;
														parseValue = false;
														dp5 = j+1;
														if(argv.charCodeAt(j) == 34 || argv.charCodeAt(j) == 39) {
															j++;
															dp5++;
														}
													}
												}
											}
										} // If has arguments ()
									} // if defType
									else {
										noType = true;
									}
									
									sections = null;
									prio = 0;
									
									if( nam.indexOf(".") >= 0 ) {
										sections = nam.split(".");
										namL = sections.length;
										nam = sections[sections.length-1];
										sections.splice( sections.length-1, 1);
										
										// remove last section if its a number
										if( sections.length > 0 && !isNaN(Number(sections[sections.length-1])) ) {
											prio = parseInt( sections[sections.length-1] );
											sections.splice( sections.length-1, 1 );
										}
									}
									
									if( defType == "random" ) {
										if( args && args.length > 1 ) {
											
											if( args[0] == "" || isNaN( Number( args[0] )) )
											{
												// hexadecimal with random length and fixed by name-id until next app-start:{#my-rnd:random('pre-text',4)}
												if( randoms[nam] == undefined) {
													randoms[nam] = InputTextBox.getUniqueName( args[0], Number(args[1]) );
												}
												tmpl_struct[sid] += randoms[nam];
											}else{
												// get integer random value: min, max: {#my-rnd:random(0,1,0.01)} -> returns a value between 0 and 1
												t2tnum = Number(args[0]);
												t2tnum = Math.random() * (Number(args[1]) - t2tnum) + t2tnum;
												tmpl_struct[sid] += args.length > 2 ? ( Math.round( t2tnum / Number(args[2]) ) * Number(args[2])) : t2tnum;
												pf.hasRandoms = true;
											}
										}
										else
										{
											tmpl_struct[sid] += InputTextBox.getUniqueName( "", args && args.length > 0 ? Number(args[0]) : 2 );
											pf.hasRandoms = true;
										}
										
										i = en;
										continue;
									}
									else if( defType == "include" )
									{
										// include text file relative to project-dir with root template file or page
										
										if( args.length > 1 )
										{
											// include template file
											filepath = CTTools.projectDir + CTOptions.urlSeparator + args[0];
											pftxt = ProjectFile( CTTools.procFiles[ CTTools.projFileBy( filepath, "path") ]);
											if( pftxt )
											{
												pftmp.setUrl( pftxt.path );
												pftmp.templateId = CTTools.activeTemplate.name;
												pftmp.setTemplate( pftxt.template, pageItemName );
												tmpl_struct[sid] += pftmp.getText();
											}
											else
											{
												Console.log("Error: Include File " + filepath + " Not Found");
											}
											
										}else{
											// static include file
											include_file = CTTools.readTextFile( new File(CTTools.projectDir).resolvePath(args[0]).url );
											tmpl_struct[sid] += include_file;
										}
										i = en;
										continue;
									}
									
									if( nam == "field" ) {
										if( template && template.dbProps && template.dbProps[defType] != undefined ) {
											// access field in subtemplate from DB: {#field:name}
											tmpl_struct[sid] += template.dbProps[defType];
											i = en;
											continue;
										}
									}else if( nam == "root" ) {
										if ( CTTools.activeTemplate) {
											
											// access root template property from sub template: {#root:page-title}
											if( CTTools.activeTemplate.dbProps && CTTools.activeTemplate.dbProps[defType] != undefined ) 
											{
												tmpl_struct[sid] += CTTools.activeTemplate.dbProps[defType].value;
											}
											else if( CTTools.activeTemplate.propertiesByName && CTTools.activeTemplate.propertiesByName[ defType ] != undefined ) 
											{
												
												// Get default value
												tmpl_struct[sid] += CTTools.activeTemplate.propertiesByName[ defType ].defValue;
											}
											
											i = en;
											continue;
										}
									}
									else if( nam == "get-date" )
									{
										if( defType == "year" ) {
											tmpl_struct[sid] += new Date().fullYear;
											i = en;
											continue;
										}else if( defType == "month" ) {
											tmpl_struct[sid] += new Date().month+1;
											i = en;
											continue;
										}else if( defType == "date" ) {
											tmpl_struct[sid] += new Date().date;
											i = en;
											continue;
										}
									}else if( nam == "page#" ) {
										tmpl_struct[sid] += pageName;
										i = en;
										continue;
									}
									
									bfound = false;
									smm = false;
									if( sections && sections.length > 0 && propertiesByName[sections + "." +nam] )
									{
										defValue = propertiesByName[sections + "." +nam].defValue;
										defType = propertiesByName[sections + "." +nam].defType;
										argv = propertiesByName[sections + "." +nam].argv;
										args = propertiesByName[sections + "." +nam].args;
										properties.push( propertiesByName[sections + "." +nam] );
										bfound = true;
									}
									else if ( propertiesByName[nam]  )
									{
										if( propertiesByName[nam].sections && sections )
										{
											// test if section matches
											if( propertiesByName[nam].sections == sections ) {
												smm = false;
											}else{
												smm = true;
											}
										}
										
										if( !smm ) {
											defValue = propertiesByName[nam].defValue;
											defType = propertiesByName[nam].defType;
											argv = propertiesByName[nam].argv;
											args = propertiesByName[nam].args;
											properties.push( propertiesByName[nam] );
											bfound = true;
										}
									}
									
									if( atc >= 1 )
									{
										// access type specific object properties (width,height,size..): {#a-img@width}
										
										tpy = atstr;
										
										if ( propertiesByName && propertiesByName[nam] != undefined )
										{
											defType = propertiesByName[nam].defType.toLowerCase();
											t2tstr = "";
											
											if ( defType == "image" )
											{
												t2tpth = "";
												
												if ( pageItemName == "" ) 
												{
													if ( template && typeof( template.dbProps[nam] ) != "undefined" && template.dbProps[nam].value && template.dbProps[nam].value != "none" ) {
														t2tpth = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + template.dbProps[nam].value;
													}else if ( typeof( propertiesByName[nam] ) != "undefined" && propertiesByName[nam].defValue && propertiesByName[nam].defValue != "none" ) {
														t2tpth = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + propertiesByName[nam].defValue;
													}else{
														if ( CTOptions.debugOutput ) Console.log( "Error: Image Property Not Found: " + nam + " Path: " + t2tpth + ", tpy: " + tpy +", pi: " + pageItemName + ", p: " + pageName);
													}
												}
												else
												{
													if( CTTools.pageItemTable && 
														CTTools.pageItemTable[ pageItemName ] && 
														CTTools.pageItemTable[ pageItemName ][ nam ] && 
														CTTools.pageItemTable[ pageItemName ][ nam ] != "none" )
													{
														t2tpth = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + CTTools.pageItemTable[ pageItemName ][ nam ];
													}
												}
												
												if(t2tpth &&  t2tpth != "" ) 
												{
													
													t2tres = rm.getResource( t2tpth );
												
													if( t2tres ) {
														// file already loaded
														// try bitmap property
														
														try {
															
															bmp = Bitmap(t2tres.obj);
															
															if( bmp )
															{
																if( tpy.substring(0,4) == "calc" )
																{
																	StringMath.constants.c_width = bmp.width;
																	StringMath.constants.c_height = bmp.height;
																	
																	t2tstr = "" + StringMath.evaluate( tpy.substring(4) );
																}
																else
																{
																	t2tstr = String( bmp.bitmapData[ tpy ] );
																}
															}else{
																if(t2tres.loaded == 1 )
																{
																	// image load error
																	rm.clearResourceCache( t2tpth );
																}
															}
															
														}catch(e:Error) {
															if( CTOptions.debugOutput ) Console.log( e.toString() );
															// try file property
															try {
																t2tstr = String( (new File(t2tpth))[ tpy ] );
															}catch(e:Error) {
																if( CTOptions.debugOutput ) Console.log( e.toString() );
															}
															
														}
													}else{
														// TODO: requires re-parse later..
														
														rm.loadResource( t2tpth, null, false );
													}
												}
											}
											
											else if ( defType == "plugin" )
											{
												// string properties: length, toUpperCase..
												try {
													if ( pageItemName != "" ) 
													{
														if( args && args.length > 1 ) {
															
															t2tstr = Main( Application.instance ).findPluginClass( args[0], args[1] ).getMember( pageItemName, tpy );
														}
													}
												}catch(e:Error) {
													if( CTOptions.debugOutput ) Console.log( e.toString() );
												}
											}
											else if ( defType == "number" || defType == "integer" || defType == "screennumber" || defType == "screeninteger" )
											{
												// number properties: number, integer, 
												try {
													t2ttmp = tpy.substring(0, 4);
													
													if ( pageItemName == "" ) 
													{
														if ( template && typeof( template.dbProps[nam] ) != "undefined" ) 
														{
															if ( tpy == "number" ) {
																t2tstr = "" + parseFloat( template.dbProps[nam]["value"] );
															}else if ( tpy == "integer" ) {
																t2tstr = "" + parseInt( template.dbProps[nam]["value"] );
															}else if( tpy == "unit" ) {
																t2tstr = "" + NumberUtils.getUnit( template.dbProps[nam]["value"] );
															}else if( tpy == "negativ" ) {
																t2tstr = "" + (-parseFloat( template.dbProps[nam]["value"] ));
															}else if( tpy == "invert" ) {
																t2tstr = "" + ( ( propertiesByName[nam].args && propertiesByName[nam].args.length > 2 ? Number(propertiesByName[nam].args[1]) : 1) - parseFloat(template.dbProps[nam]["value"]) );
															}else if ( t2ttmp == "mul " ) {
																t2tstr = "" + ( parseFloat( template.dbProps[nam]["value"] ) * parseFloat( tpy.substring(4) ));
															}else if ( t2ttmp == "div " ) {
																t2tstr = "" + ( parseFloat( template.dbProps[nam]["value"] ) / parseFloat( tpy.substring(4) ));
															}else if ( t2ttmp == "add " ) {
																t2tstr = "" + ( parseFloat( template.dbProps[nam]["value"] ) + parseFloat( tpy.substring(4) ));
															}else if ( t2ttmp == "sub " ) {
																t2tstr = "" + ( parseFloat( template.dbProps[nam]["value"] ) - parseFloat( tpy.substring(4) ));
															}else if( t2ttmp == "calc" ) {
																StringMath.constants.c_value = parseFloat( template.dbProps[nam]["value"] );
																t2tstr = "" + StringMath.evaluate( tpy.substring(4) );
															}else{
																t2tstr = template.dbProps[nam]["value"][tpy];
															}
														}
														else if ( typeof( propertiesByName[nam] ) != "undefined" )
														{
															if ( tpy == "number" ) {
																t2tstr = "" + parseFloat( propertiesByName[nam].defValue );
															}else if ( tpy == "integer" ) {
																t2tstr = "" + parseInt( propertiesByName[nam].defValue );
															}else if( tpy == "unit" ) {
																t2tstr = "" + NumberUtils.getUnit( propertiesByName[nam].defValue );
															}else if( tpy == "negativ" ) {
																t2tstr = "" + (-parseFloat( propertiesByName[nam].defValue ));
															}else if( tpy == "invert" ) {
																t2tstr = "" + ( ( propertiesByName[nam].args && propertiesByName[nam].args.length > 2 ? Number(propertiesByName[nam].args[1]) : 1) - parseFloat(propertiesByName[nam].defValue) );
															}else if ( t2ttmp == "mul " ) {
																t2tstr = "" + ( parseFloat( propertiesByName[nam].defValue ) * parseFloat( tpy.substring(4) ));
															}else if ( t2ttmp == "div " ) {
																t2tstr = "" + ( parseFloat( propertiesByName[nam].defValue ) / parseFloat( tpy.substring(4) ));
															}else if ( t2ttmp == "add " ) {
																t2tstr = "" + ( parseFloat( propertiesByName[nam].defValue ) + parseFloat( tpy.substring(4) ));
															}else if ( t2ttmp == "sub " ) {
																t2tstr = "" + ( parseFloat(  propertiesByName[nam].defValue ) - parseFloat( tpy.substring(4) ));
															}else if( t2ttmp == "calc" ) {
																StringMath.constants.c_value = parseFloat(  propertiesByName[nam].defValue );
																t2tstr = "" + StringMath.evaluate( tpy.substring(4) );
															}else{
																t2tstr = propertiesByName[nam].defValue[tpy];
															}
														}
														else
														{
															if (CTOptions.debugOutput) Console.log("Error: Number Property Not Found: " + nam + ":" + tpy );
														}
													}
													
													else{
														if ( tpy == "number" ) {
															t2tstr = "" + parseFloat( CTTools.pageItemTable[ pageItemName ]["value"] );
														}else if ( tpy == "integer" ) {
															t2tstr = "" + parseInt( CTTools.pageItemTable[ pageItemName ]["value"] );
														}else if( tpy == "unit" ) {
															t2tstr = "" + NumberUtils.getUnit( CTTools.pageItemTable[ pageItemName ]["value"]  );
														}else if( tpy == "negativ" ) {
															t2tstr = "" + (-parseFloat( CTTools.pageItemTable[ pageItemName ]["value"] ));
														}else if( tpy == "invert" ) {
															t2tstr = "" + ( ( propertiesByName[nam].args && propertiesByName[nam].args.length > 2 ? Number(propertiesByName[nam].args[1]) : 1) - parseFloat( CTTools.pageItemTable[ pageItemName ]["value"] ) );
														}else if ( t2ttmp == "mul " ) {
															t2tstr = "" + ( parseFloat( CTTools.pageItemTable[ pageItemName ]["value"] ) * parseFloat( tpy.substring(4) ));
														}else if ( t2ttmp == "div " ) {
															t2tstr = "" + ( parseFloat( CTTools.pageItemTable[ pageItemName ]["value"] ) / parseFloat( tpy.substring(4) ));
														}else if ( t2ttmp == "add " ) {
															t2tstr = "" + ( parseFloat( CTTools.pageItemTable[ pageItemName ]["value"] ) + parseFloat( tpy.substring(4) ));
														}else if ( t2ttmp == "sub " ) {
															t2tstr = "" + ( parseFloat( CTTools.pageItemTable[ pageItemName ]["value"] ) - parseFloat( tpy.substring(4) ));
														}else if( t2ttmp == "calc" ) {
																StringMath.constants.c_value = parseFloat( CTTools.pageItemTable[ pageItemName ]["value"] );
																t2tstr = "" + StringMath.evaluate( tpy.substring(4) );
														}else{
															t2tstr = CTTools.pageItemTable[ pageItemName ]["value"][ tpy ];
														}
													}
													
												}catch(e:Error) {
													if( CTOptions.debugOutput ) Console.log( e.toString() );
												}
											}
											else if ( defType == "color" )
											{
												
												try {
													
													if ( pageItemName == "" ) 
													{
														if ( template && typeof( template.dbProps[nam] ) != "undefined" ) 
														{
															ColorUtils.getRGBComponents( CssUtils.stringToColor(template.dbProps[nam]["value"]), color);
															
															if ( tpy == "red" ) {
																t2tstr = "" + color.r;
															}else if ( tpy == "green" ) {
																t2tstr = "" + color.g;
															}else if ( tpy == "blue" ) {
																t2tstr = "" + color.b;
															}else if ( tpy == "invert" ) {
																t2tstr = "#" + ColorUtils.colorToString( ColorUtils.combineRGB( 255-color.r, 255-color.g, 255-color.b ), true);
															}else if ( tpy == "sat" ) {
																t2tnum = int( (color.r + color.g + color.b) / 3);
																t2tstr = "#" + ColorUtils.colorToString( ColorUtils.combineRGB( t2tnum, t2tnum, t2tnum ), true);
															}else{
																t2ttmp = tpy.substring(0, 4);
																if ( t2ttmp == "mul " ) {
																	t2tstr = "#" +  ColorUtils.colorToString( ColorUtils.lightness( color, parseFloat( tpy.substring(4) )));
																}else if ( t2ttmp == "sat " ) {
																	t2tstr = "#" +  ColorUtils.colorToString( ColorUtils.saturation( color, parseFloat( tpy.substring(4) )));
																}
															}
														}
														else if ( typeof( propertiesByName[nam] ) != "undefined" )
														{
															ColorUtils.getRGBComponents( CssUtils.stringToColor(propertiesByName[nam].defValue), color);
															
															if ( tpy == "red" ) {
																t2tstr = "" + color.r;
															}else if ( tpy == "green" ) {
																t2tstr = "" + color.g;
															}else if ( tpy == "blue" ) {
																t2tstr = "" + color.b;
															}else if ( tpy == "invert" ) {
																t2tstr = "#" + ColorUtils.colorToString( ColorUtils.combineRGB( 255-color.r, 255-color.g, 255-color.b ), true);
															}else if ( tpy == "sat" ) {
																t2tnum = int( (color.r + color.g + color.b) / 3);
																t2tstr = "#" + ColorUtils.colorToString( ColorUtils.combineRGB( t2tnum, t2tnum, t2tnum ), true);
															}else{
																t2ttmp = tpy.substring(0, 4);
																if ( t2ttmp == "mul " ) {
																	t2tstr = "#" +  ColorUtils.colorToString( ColorUtils.lightness( color, parseFloat( tpy.substring(4) )));
																}else if ( t2ttmp == "sat " ) {
																	t2tstr = "#" +  ColorUtils.colorToString( ColorUtils.saturation( color, parseFloat( tpy.substring(4) )));
																}
															}
														}
														else
														{
															if (CTOptions.debugOutput) Console.log("Error: Number Property Not Found: " + nam + ":" + tpy );
														}
													}
													else
													{
														ColorUtils.getRGBComponents( CssUtils.stringToColor( CTTools.pageItemTable[ pageItemName ]["value"] ), color);
														
														if ( tpy == "red" ) {
															t2tstr = "" + color.r;
														}else if ( tpy == "green" ) {
															t2tstr = "" + color.g;
														}else if ( tpy == "blue" ) {
															t2tstr = "" + color.b;
														}else if ( tpy == "invert" ) {
															t2tstr = "#" + ColorUtils.colorToString( ColorUtils.combineRGB( 255-color.r, 255-color.g, 255-color.b ), true) ;
														}else if ( tpy == "sat" ) {
															t2tnum = int( (color.r + color.g + color.b) / 3);
															t2tstr = "#" + ColorUtils.colorToString( ColorUtils.combineRGB( t2tnum, t2tnum, t2tnum ), true);
														}else{
															t2ttmp = tpy.substring(0, 4);
															if ( t2ttmp == "mul " ) {
																t2tstr = "#" +  ColorUtils.colorToString( ColorUtils.lightness( color, parseFloat( tpy.substring(4) )));
															}else if ( t2ttmp == "sat " ) {
																t2tstr = "#" +  ColorUtils.colorToString( ColorUtils.saturation( color, parseFloat( tpy.substring(4) )));
															}
														}
													}
												}catch(e:Error) {
													if( CTOptions.debugOutput ) Console.log( e.toString() );
												}
												
											}
											/*else if( defType == "video" ) {
												
											
											}else if( defType == "audio" ) {
												
											
											}else if( defType == "file" || defType == "pdf" ) {
												
											}*/
											else if ( defType == "string" || defType == "text" || defType == "code" ||  defType == "richtext" )
											{
												// string properties: length, toUpperCase..
												try {
													if ( pageItemName == "" ) 
													{
														if ( template && typeof( template.dbProps[nam] ) != "undefined" ) 
														{
															t2tstr = /*typeof(template.dbProps[nam]) == "object" ?*/ template.dbProps[nam]["value"][tpy] /*: template.dbProps[nam][tpy]*/;
														}
														else if ( typeof( propertiesByName[nam] ) != "undefined" )
														{
															t2tstr = propertiesByName[nam].defValue[tpy];
														}
														else
														{
															if (CTOptions.debugOutput) Console.log("Error: String Property Not Found: " + nam + ":" + tpy );
														}
													}
													else
													{
														t2tstr = CTTools.pageItemTable[ pageItemName ]["value"][ tpy ];
													}
												}catch(e:Error) {
													if( CTOptions.debugOutput ) Console.log( e.toString() );
												}
											}
											if( t2tstr ) {
												tmpl_struct[sid] += t2tstr;
											}
										}
										i = en;
										continue;
										
									}
									
									if( !bfound ) {
										if( noType && !smm ) {
											if( CTOptions.debugOutput && !(pageItemName != "" && pageName != "") ) { // exclude wrong logs in article pages..
												Console.log("WARNING: '" + nam + "' Property In " + (template ? template.name : "") + CTOptions.urlSeparator + pf.filename + " Template Has No Type");
											}
											i = en;
											continue;
										}
										
										propertiesByName[nam] = properties[ properties.push( {st:st, en:en, name:nam, sections:sections, priority:prio, defType:defType, defValue:CssUtils.trimQuotes(defValue), argv:argv, args:args} ) - 1 ];
										
										tpe = defType.toLowerCase();
										
										if( sections && sections.length > 0 ) {
											propertiesByName[ sections.join(".") + "." + nam ] = propertiesByName[nam];
										}
									}else{
									
										tpe = defType.toLowerCase();
									}
									if( tpe == "vectorlink" )
									{
										// VectorLink ( 'Vector-TmplObj-Name', Type:String || None, wrap, separator, wrap0... )
										// None: -,,- wrap0, wrap2...
										
										if( template && args && args.length > 2 )
										{
											// get reference vector list
											vecProcVal = template.dbProps[args[0]].value;
											
											if( vecProcVal )
											{
												vecValues = vecProcVal.split( args.length > 3 ? args[3] : "," ); // split by separator
												vecL = vecValues.length;
												
												vecType = args[1].toLowerCase();
												vecProcVal = "";
											
												t2tobj = {};
												t2tobj.length = vecL;
												t2tobj.name = nam;
												t2tobj.vectorname = args[0];
												t2tobj.type = vecType;
												
												t2tobj.vectorindex = -1;
												
												if( vecType == "none") {
													
													for( vi=0; vi < vecL; vi++ ) {
														viStart = 4 + vi;
														t2tobj.vectorindex = vi;
														vecValue = vecValues[vi];
														
														if(args.length > viStart) {
															
															vecWrap = TemplateTools.obj2Text ( args[viStart], "#", t2tobj, true, false ).split("|");
															
															if( vecWrap.length > 1 ) {
																vecWrapPre =  vecWrap[0];
																vecWrapPost = vecWrap[1];
																
															}else{
																if( vecWrap.length > 0 ) {
																	vecWrapPre = vecWrap[0];
																	vecWrapPost = "";
																}
															}
														}else{
															vecWrap = TemplateTools.obj2Text(args[2], "#", t2tobj, true, false).split("|");
															
															vecWrapPre =  vecWrap[0];
															vecWrapPost = vecWrap[1];
														}
														vecProcVal += vecWrapPre + vecWrapPost;
													}
												}
												tmpl_struct[sid] += vecProcVal;
											}
										}
									}
									
									if( sections && sections.length > 0 )
									{
										t2tstr = sections.join(".") + "." + nam;
									}
									else
									{
										t2tstr = "";
									}
									
									// Add T-Property value to the current struct
									if( template && template.dbProps && ( (!t2tstr && template.dbProps[nam] != undefined) || (t2tstr && template.dbProps[ t2tstr ] != undefined)) ) {
										//
										// Replace Key with DB setting
										//
										// Parse sql-friendly richtext (#div:class:textnode# #B:BOLD-TEXT# #A:url:label# #I:ITALIC-TEXT#...)
										// Parse Vector wraps
										//
										if( t2tstr && template.dbProps[ t2tstr ] != undefined )
										{
											procVal = typeof template.dbProps[t2tstr] == "object" ? template.dbProps[t2tstr].value : template.dbProps[t2tstr];
										}
										else
										{
											procVal = typeof template.dbProps[nam] == "object" ? template.dbProps[nam].value : template.dbProps[nam];
										}
										
										if( tpe == "file" )
										{
											filesByName[ nam ] = procVal;
										}
										else if ( tpe == "number" || tpe == "integer" || tpe == "screennumber" || tpe == "screeninteger" )
										{
											if( t2tstr ) {
												StringMath.constants["c_"+t2tstr] = parseFloat( procVal );
											}else{
												StringMath.constants["c_"+nam] = parseFloat( procVal );
											}
										}
										else if( tpe == "text" || tpe == "richtext" )
										{
											hasBr = procVal.toLowerCase().indexOf("#br#") >= 0;
											
											procVal = TemplateTools.obj2Text( procVal, '#', template.dbProps, true, false );
											procVal = HtmlParser.fromDBText( procVal );
											
											if( args && args.length > 1 ) 
											{
												// Split <BR/> and apply line wraps
												
												wrapSplit = args[1].split("|");
												
												if( wrapSplit.length > 1 )
												{
													defWrapPre =  TemplateTools.obj2Text( wrapSplit[0], '#', template.dbProps, true, false );
													defWrapPost = TemplateTools.obj2Text( wrapSplit[1], '#', template.dbProps, true, false );
													
													if( hasBr ) {
														brSplit = procVal.split("<br/>");
													}else{
														brSplit = procVal.split("\n");
													}
													vecL = brSplit.length;
													if( vecL > 0 ) {
														vecValue = "";
														for( vi = 0; vi < vecL; vi++) {
															
															if( brSplit[vi] == "" || StringUtils.isWhite( brSplit[vi] )  ) {
																vecValue += defWrapPre +"&nbsp;" + defWrapPost;
															}else{
																vecValue += defWrapPre + brSplit[vi] + defWrapPost;
															}
															
														}
														procVal = vecValue;
													}	
												}
											}
										}
										else if( tpe == "vector" )
										{
											// Len, Type, defaultWrap, separator, dynaLength, type_defaults..., value1, arg1...
											// Type = File : -,-  file_value1, file_www-folder1, file
											
											if( args && args.length > 4 )
											{
												if(isNaN(Number(args[0]))) {
													vecL = 0;
													Console.log("Error: First Vector Argument Is Not A Number (len, type, wrap, separator, dynaLen, type_arguments.., default_values..): " + args );
												}else{
													vecL = int(args[0]);
												}
												
												vecType = args[1].toLowerCase();
												wrapSplit = args[2].split("|");
												
												if( wrapSplit.length > 1 ) {
													defWrapPre = wrapSplit[0];
													defWrapPost = wrapSplit[1];
												}
												
												vecValues = procVal.split( args[3] ); // split by separator
												vecL = Math.max( vecL, vecValues.length );
												vecProcVal = "";
																								
												if( vecType == "file" || vecType == "image" || vecType == "video" || vecType == "audio" || vecType == "pdf" )
												{
													if( args.length > 5 ) defaultWWWFolder = args[5];
													if( args.length > 6 ) defaultRename = args[6];
													if( args.length > 7 ) defaultDescr = args[7];
													if( args.length > 8 ) defaultExtList = args[8];
													
													for( vi=0; vi < vecL; vi++ )
													{
														vecArgs = [];
														viStart = 9 + vi*6;
														template.dbProps["vectorindex"] = vi;
														
														if( args.length > viStart )
															vecValue = args[ viStart ];
														
														if( vecValues.length > vi ) 
															vecValue = vecValues[vi];
														
														if( args.length > viStart+1)
														{
															vecArgs.push(args[viStart+1]);
															
															if( args.length > viStart+2) {
																vecArgs.push(args[viStart+2]);
															}
															if( args.length > viStart+3) {
																vecArgs.push(args[viStart+3]);
															}
															if( args.length > viStart+4) {
																vecArgs.push(args[viStart+4]);
															}
															if(args.length > viStart+5) {
																
																
																vecWrap = args[viStart+5].split("|");
																if( vecWrap.length > 1 ) {
																	vecWrapPre = TemplateTools.obj2Text( vecWrap[0], "#", template.dbProps, true, false );
																	vecWrapPost = TemplateTools.obj2Text( vecWrap[1], "#", template.dbProps, true, false );
																	
																}else{
																	if( vecWrap.length > 0 ) {
																		vecWrapPre = TemplateTools.obj2Text( vecWrap[0], "#", template.dbProps, true, false );
																		vecWrapPost = "";
																	}else{
																		vecWrapPre = TemplateTools.obj2Text( defWrapPre, "#", template.dbProps, true, false );
																		vecWrapPost = TemplateTools.obj2Text( defWrapPost, "#", template.dbProps, true, false );
																	}
																}
															}else{
																vecWrapPre = TemplateTools.obj2Text( defWrapPre, "#", template.dbProps, true, false );
																vecWrapPost = TemplateTools.obj2Text( defWrapPost, "#", template.dbProps, true, false );
															}
														}else{
															vecWrapPre = TemplateTools.obj2Text( defWrapPre, "#", template.dbProps, true, false );
															vecWrapPost = TemplateTools.obj2Text( defWrapPost, "#", template.dbProps, true, false );
														}
														
														vecProcVal += vecWrapPre + vecValue + vecWrapPost;
													}
												
												}else if( vecType == "number" || vecType == "integer" || vecType == "screennumber" || vecType == "screeninteger" ) {
													vecProcVal = procVal; // TODO...
												}else{
													// String or Text
													for( vi=0; vi < vecL; vi++ )
													{
														vecArgs = [];
														viStart = 5 + vi*2;
														template.dbProps["vectorindex"] = vi;
														
														if( args.length > viStart )
															vecValue = args[ viStart ];
														
														if( vecValues.length > vi ) 
															vecValue = vecValues[vi];
														
														vecValue = TemplateTools.obj2Text( vecValue, '#', /*richTextProps*/template.dbProps, true, false );
														
														template.dbProps["vectorvalue"] = vecValue;
														
														if( vecType == "typed" ) {
															
															tps = vecValue.split(":");
															if( tps ) {
																if( tps.length > 1) {
																	template.dbProps['typename'] = tps.shift();
																	vecValue = tps.join(":");
																	template.dbProps["vectorvalue"] = vecValue;
																}
															}
														}
														if(args.length > viStart+1) {
															
															vecWrap = args[viStart+1].split("|");
															if( vecWrap.length > 1 ) {
																vecWrapPre = TemplateTools.obj2Text( vecWrap[0], "#", template.dbProps, true, false );
																vecWrapPost =  TemplateTools.obj2Text( vecWrap[1], "#", template.dbProps, true, false );
																
															}else{
																if( vecWrap.length > 0 ) {
																	vecWrapPre = TemplateTools.obj2Text( vecWrap[0], "#", template.dbProps, true, false );
																	vecWrapPost = "";
																}else{
																	vecWrapPre = TemplateTools.obj2Text( defWrapPre, "#", template.dbProps, true, false );
																	vecWrapPost = TemplateTools.obj2Text( defWrapPost, "#", template.dbProps, true, false );
																}
															}
														}else{
															vecWrapPre = TemplateTools.obj2Text( defWrapPre, "#", template.dbProps, true, false );
															vecWrapPost = TemplateTools.obj2Text( defWrapPost, "#", template.dbProps, true, false );
														}
														
														vecProcVal += vecWrapPre + vecValue + vecWrapPost;
													}
												}
												
												procVal = vecProcVal;
											}
										}
										
										tmpl_struct[sid] += procVal;
										
									}else{
										// Replace Key with Template setting
										if( tpe == "text" || tpe == "richtext" || tpe == "line" ) {
											tmpl_struct[sid] += HtmlParser.fromDBText( TemplateTools.obj2Text( propertiesByName[nam].defValue.replace(re, "<br/>"), '#',null,true,false) );
											
										}else{
											tmpl_struct[sid] += defValue.replace(re, "<br/>");
										}
									}
								}
								
								i = en;
								writeChar = false;
							} // if en > 0
						}
						
						break;
					
					case 125: // }
						break;
				}// switch
				
				if(writeChar && writeSplit)
					tmpl_struct[sid] += String.fromCharCode( cc );
				
			}// for char codes
			
			pf.templateStruct = tmpl_struct;
			pf.templateAreas = areas;
			pf.templateProperties = properties;
		}
		
		public static function transformRichText ( procVal:String, args:Array, template:Template ) :String
		{
			var hasBr:Boolean = procVal.toLowerCase().indexOf("#br#") >= 0;
			
			var wrapSplit:Array;
			var defWrapPre:String;
			var defWrapPost:String;
			var vecL:int;
			var vecValue:String;
			var brSplit:Array;
			var i:int;
			var vi:int;
			
			procVal = TemplateTools.obj2Text( procVal, '#', template.dbProps, true, false );
			procVal = HtmlParser.fromDBText( procVal );
			
			if( args && args.length > 1 ) 
			{
				// Split <BR/> and apply line wraps
				
				wrapSplit = args[1].split("|");
				
				if( wrapSplit.length > 1 )
				{
					defWrapPre =  TemplateTools.obj2Text( wrapSplit[0], '#', template.dbProps, true, false );
					defWrapPost = TemplateTools.obj2Text( wrapSplit[1], '#', template.dbProps, true, false );
					
					if( hasBr ) {
						brSplit = procVal.split("<br/>");
					}else{
						brSplit = procVal.split("\n");
					}
					vecL = brSplit.length;
					if( vecL > 0 ) {
						vecValue = "";
						for( vi = 0; vi < vecL; vi++) {
							
							if( brSplit[vi] == "" || StringUtils.isWhite( brSplit[vi] )  ) {
								vecValue += defWrapPre +"&nbsp;" + defWrapPost;
							}else{
								vecValue += defWrapPre + brSplit[vi] + defWrapPost;
							}
							
						}
						procVal = vecValue;
					}	
				}
			}
			return procVal;
		}
	}
}
