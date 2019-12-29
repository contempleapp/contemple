package agf.utils 
{	
	public class StringMath 
	{	
		public function StringMath() {}
		
		/**
		* Calculate string expression: 
		*
		* var fp2:Number = Number ( StringMath.evaluate( "5+pi/2" ) );
		*
		*/
		
		public static function evaluate ( str:String, precision:int=-1, forceUnit:Boolean=false) :* {
			
			if( forceUnit ) forceDist = 1;
			else forceDist = 0;
			
			// Clear White spaces
			var s2:String="(";
			var i:int;
			var L:int = str.length;
			for(i=0; i < L; i++)  {
				if(str.charCodeAt(i) >= 33) s2 += str.charAt(i);
			}
			if( s2 == "(inherit" || s2 == "(none" || s2 == "(yes" || s2 == "(no" || s2 == "(true" || s2 == "(false" || s2 == "(void" || s2 == "(undefined" || s2=="(null") return str;
				
			var rVal:* = calcText(s2.toLowerCase()+")");
			
			
			if(decPlaces != -1){
				var tmp:Number = roundTo(rVal, decPlaces);
				rVal = tmp;
			}

			if(/*type == 2 &&*/ (distCalculated || forceDist)) {
				
				distCalculated = 0;
				var _l:int = distance.length;

				for(var j:int=_l-1; j>=0; j--) {
					if(forceDistance == distance[j][0]) {
						rVal /= distance[j][1];
						if( distFormat == "em" || distFormat == "rem" || distFormat == "px" || distFormat == "vw" || distFormat == "vh" || distFormat == "%") {
							rVal = String(rVal) + "" + distFormat;
						}else{
							rVal = String(rVal) + "" + forceDist;
						}
						break;
					}
				}
			}
			
			return rVal;
		}

		public static function getNumberAsString (val:Number) : String {
			var y:Number = Math.round(val*1000)/1000;
			return y.toString();
		}
		
		public static var constants:Object = { 
			c_pi : Math.PI,
			c_e :  Math.E,
			c_ln2 : Math.LN2,
			c_ln10 : Math.LN10,
			c_log : Math.log,
			c_log2e : Math.LOG2E,
			c_log10e: Math.LOG10E,
			c_sqrt1_2 : Math.SQRT1_2,
			c_sqrt2 : Math.SQRT2,
			c_piOver : 180*Math.PI,
			c_piUnder : Math.PI/180,
			c_width: 0,
			c_height: 0,
			c_value: 0
		};
					
		public static var funcs:Object = {
			rad : function(degree:*) :* {
				return Number(degree)*Math.PI/180;
			},
			deg : function(radian:*) :* {
				return Number(radian)/Math.PI*180;
			},
			dec : function(num:*) :* {
				return Number(num);
			},
			hex : function(num:*) :* {
				num = new Number(num);
				var rVal:String = String("0x"+ num.toString(16).toUpperCase());
				return rVal;
			},
			oct : function(num:*) :* {
				num = new Number(num);
				return num.toString(7);
			},
			bin : function(num:*) :* {
				num = new Number(num);
				return num.toString(2);
			},
			base : function(num:*, base:*) :* {
				num = new Number(num);
				return num.toString(base);
			}
		};
		
		public static var mathfuncs:Object = {
			abs : Math.abs,
			acos : Math.acos,
			asin : Math.asin,
			atan : Math.atan,
			atan2 : Math.atan2,
			ceil : Math.ceil,
			cos : Math.cos,
			exp : Math.exp,
			floor : Math.floor,
			max : Math.max,
			min : Math.min,
			pow : Math.pow,
			rand : Math.random,
			round : Math.round,
			sin : Math.sin,
			sqrt : Math.sqrt,
			tan : Math.tan,
			rad : funcs.rad,
			deg : funcs.deg,
			dec : funcs.dec,
			hex : funcs.hex,
			oct : funcs.oct,
			bin : funcs.bin,
			base : funcs.base
		};
		
		public static var distance:Array = [ ["um", 1/1000000],["mm", 1/1000],["cm", 1/100],["m", 1],["px",1],["%",1],["em", 1],["rem", 1],["vw", 1],["vh", 1],["%", 1],["km", 1000] ];
		
		
		public static var forceDistance:String = "m";
		
		public static var forceDist:int = 0;
		public static var distCalculated:int = 0;
		public static var distFormat:String = "px";
		public static var isHex:Boolean = false;
		public static var decPlaces:int = -1;
		public static var type:int = 0;
		
		
		
		public static function calcText (text:String, bTmp:*=null) :* {
			
			var _l:int = text.length;
			var i:int = 0;
			var c:String="";
			var c_1:String="";
			var _l2:int;
			var st:int;
			var st1:int;
			var st2:int;
			var kw:String;
			var txt:* = "";
			var isO:Boolean;
			var isM:Boolean;
			var typ:int;	//typ:: 0:Number, 1:Operator, 2: String
			var args:Array;
			var opened:int;
			var val:*; 
			var vNum:String = "";
			var m:int;
			isHex = false;
			
			// Alle Zeichen
			while( i < _l) {
				c_1 = c;
				c = text.charAt(i);
				
				if(c == "x" && c_1 == "0") isHex = true;
				
				isO = isOperator(c);
				isM = isMathable(c);
				
				if(!isO) {
					if(isM){
						// Number
						typ = 0;
					}else{
						// variable
						typ = 2;	
					}
				}else {
					// Operator
					typ = 1;
				}
				
				if(typ <= 1) {
					//Ziffer || Operator
					txt += c;
					if(typ == 0) vNum += c;
					else {
						vNum = "";
						isHex = false;
					}
				}else if(typ == 2){
					//String
					st1 = i;
					for( i+=1; i< _l; i++) {
						c = text.charAt(i);
						
						if(c == "(" ) {
							//function
							st2 = i;
							kw = text.substring(st1, st2);
							st = i;
							
							if(typeof(mathfuncs[kw]) != "function") {
								vNum = "";
								break;
							}
							args = [];
							
							opened = 1;
							for(i+=1; i<=_l; i++) {
								c = text.charAt(i);
								
								if( c == ",") {
									args.push( calcText("("+text.substring(st+1, i)+")") );
									st = i;
								}else if(c == "(") {
									opened++;	 
								}else if(c == ")") {
									opened--;
									if(opened == 0) {
										args.push( calcText("("+text.substring(st+1, i)+")") );
										vNum = "";
										isHex = false;
										break;
									}

								}
							}

							if(args.length == 0) {
								val = mathfuncs[kw]();
							}else if(args.length == 1) {
								val = mathfuncs[kw]( args[0] );
							}else if(args.length == 2) {
								val = mathfuncs[kw]( args[0], args[1] );
							}else{
								val = mathfuncs[kw]( args[0], args[1], args[2] );
							}
								

							if( val < 0 && txt.substring(txt.length-1) == "-") val = String("("+val+")");
							txt += val;
							
							vNum = "";
							isHex = false;
							break;
						}else{
							
							if(i >= _l-1 || isOperator(c)  ) {
								
								val = constants["c_" + text.substring(st1, i)];
								
								if(val != null) {
									
									if(val == constants.c_e ) {
										if(!isOperator(text.substr(st1-1, 1)) && text.substr(st1+1, 1) == "-" && isMathable(text.substr(st1-1, 1)) ) { 
											//e-
											for(; i<=_l; i++) if( isOperator(text.substr(i,1)) ) break;
											txt+= text.substring(st1, i);
											i--;
											vNum = "";
											isHex = false;
											break;
										}else{
											//const e
											txt += val;
											i--;
											vNum = "";
											isHex = false;
											break;
										}
									}else{
										txt += val;
										i--;
										vNum = "";
										isHex = false;
										break;
									}
								} else {
									//if(type == 2) {
										
										//if(isOperator(text.charAt(i+1)) || isOperator(text.charAt(i)) || i >= _l-1) {
											val = text.substring(st1, i);
											for(m=distance.length-1; m>=0; m--){
												if(val == distance[m][0] ) {
													_l2 = vNum.length;
													txt = txt.slice(0, -_l2)
													txt += String(Number(vNum) * distance[m][1]);
													distCalculated = 1;
													distFormat = val;
													vNum = "";
													isHex = false;
													break;
												}
											}

										//}//if operator
									//}
								}	//if val == number, string, new Number
								i--; 
								
								break;
							}// if l-1, operator
						}// if "("
					}// for( i++)
				}// if( typ <= 1)
				i++;
			}//while(i++)
			
			var erg:String = txt;
			var k:Array = splitBrackets(erg);
			
			//zahlen berechnen:
			if(k != null) {
				while(true) {
					var tmp:Array = splitBrackets(erg);
					if(tmp == null) {
						break;
					}
					erg = calcLastBracket(erg);	
				}
			}
			
			var rVal:* = calculate(erg);
			
			return rVal;
			
		}
		
		public static function splitBrackets (text:String) :Array {
			
			var k:Array = [];
			var _l:int = text.length;
			var t:int;
			//var st = 0;
			var kst:int = 0;
			var opened:int = 0;
			var hasBr:int = 0;
			
			for(var i:uint=0; i<_l; i++) {
				t = text.charCodeAt(i);
				
				if(t == 40 ) {	//"("
					opened++;
					hasBr = 1;
					if(opened == 1) {
						kst = i+1;
						if( kst > 1) k.push(text.substring(0, kst-1));
					}
				}else if(t == 41) {	//")"
					opened--;
					if(opened == 0){
						k.push(text.substring(kst, i));
						k.push(text.substring(i+1, text.length));
					}
				}
			}
			if(hasBr) {
				return k;
			}else{
				return null;
			}
		}
		public static function calcLastBracket (text:String) :String {
			var _l:int = text.length;
			var st:int = 0;
			var t:int;
			var innerste:String = "";
			var minus:int = 0;
			var opened:int = 0;
			var i:int = _l;
			
			while( ( --i ) >= 0) {
				if( text.charAt(i) == "(" ) opened++;	
			}	
			
			if(opened != 0) {
				for(i=0; i<_l; i++) {
					t = text.charCodeAt(i);
					if( t == 40 ) {	//"("
						st = i+1;
						opened--;
					}else if(t == 41 && opened == 0 ) {	// ")"
						innerste = text.substring(st, i);
						if( text.substring( st-2, st-1) == "-" && (isOperator( text.substring(st-3, st-2)) || st <= i) ) {
							minus = 1;
						}
						break;
					} 
				}
			}else{
				innerste = text;	
			}
			var zwischenErg:String = String( calculate(innerste) );
			
			if(!minus) {
				return text.substring(0, st - 1) + zwischenErg + text.slice(i + 1);
			}else if(minus && (zwischenErg.substring(0,2) == "--") ){
				return text.substring(0, st - 2)  + zwischenErg.substring(2) + text.slice(i + 1);
			}else if(minus && (zwischenErg.substring(0,1) == "-")){							 
				return text.substring(0, st - 2) + zwischenErg.substring(1) + text.slice(i + 1);
			}else if(minus) {
				return text.substring(0, st - 2) +"-"+ zwischenErg + text.slice(i + 1);		
			}
			return "";
		}
		
		public static function calculate (text:String) :* {
			
			if( isNaN(Number(text)) ) {
				var _l:int = text.length;

				if( text.charAt(0) == "-" && text.charAt(1) == "-") {
					text = text.substring(2, text.length );
				}else if ( text.charAt(0) == "+" ) {
					text = text.substring(1,text.length);	
				}
				var z:Array = [];
				var st:int =0;
				var i:int;
				var t:String;
				var erg:*;
				var o:int;
				var lastOp:int = 0;
				
				for(i=0; i<_l; i++) {

					//t = substring(text,i+1,1);
					o = text.charCodeAt(i);

					if( o==42 || o==47 || o==43 ) {	// "* / +"
						z.push(text.substring(st, i), /*o*/ text.charAt(i) );
						st = i+1;
						lastOp = i;
					}else if( o==45 ) {	// "-"
						if(i == (lastOp + 1) && (i > 1) ){
							lastOp = i;
							st = i;
						}else{
							if( i != 0) {
								z.push(text.substring(st, i), /*o*/ text.charAt(i) );
								st = i+1;
								lastOp = i;
							}
						}		 
					}else if( o==69 || o== 101) {
						t = text.charAt(i);
						if( !isOperator(t) && isMathable(t) && text.charAt(i+2) == "-" ) {
							for(i+=2; i<_l; i++) {
								if(isOperator(text.substring(i+1, 1))) {
									i--;
									break;
								}
							}
						}	
					}
				}

				z.push(text.substring(st, i));
								
				for(i=0; i<z.length; i++) {
					if(z[i] /*=== 42*/ == "*" ) {	// *                         
						erg = z[i-1] * z[i+1];
						z.splice(i, 2);
						z[i-1] = Number(erg);
						i -= 2;
					}else if(z[i] /*=== 47*/ == "/") {	//"/"
						erg = z[i-1] / z[i+1];
						z.splice(i, 2);
						z[i-1] = Number(erg);
						i -= 2;	
					}
				}
				erg = new Number(z[0]);
				_l = z.length;
				for(i=1; i<_l; i+=2) {	
					if(z[i] /* === 43 */ == "+" ) { //"+"
						erg += Number(z[i+1]);
					}else if(z[i] /*=== 45*/ == "-" ) { //"-"
						erg -= Number(z[i+1]);
					}
				}
				return erg;
			}else{
				return text;
			}
		}
		
		public static function isMathable (str:String) :Boolean {
			// 0 - 9 || . 
			var o:int = str.charCodeAt(0);
			if(o >= 40 && o <= 57 || o==69) return true;
			
			if(isHex == true) {	//  x || a - f
				if( o==120 || o>=97 && o<= 102) return true
			}
			
			return false;
		}
		
		public static function isOperator (str:String) :Boolean {
			var o:int = str.charCodeAt(0);
			if(o >= 40 && o <= 45 || o == 47) {
				return true;
			}else{
				return false;
			}
		}
		
		public static function forceNumber (str:String, dp:int=-1) :Number {
			
			var s2:* = Number(str);
			
			if( isNaN(s2) ) {
				s2 = "";
				var l:int = str.length;
				var c:String;
				var a:uint;
				var co:int = 0;
				var i:int = 0;//1;
				var min:Boolean = false;
				dp = dp==-1 ? 14 : dp;
				while(i <= l) {
					c = str.charAt(i);
					a = str.charCodeAt(i);
					
					if((a >= 48 && a <= 57) || (a == 45 && min==false)) {  // 45 -
						if(a==45) min = true;
						s2 += c;
						if(co) co++;
					}else if(!co) {
						if(a==46 || a == 44) {
							s2 += ".";// c; // , -> .
							co = 1;
					/*	}else if(a==44){
							s2 += ".";
							co = 1;*/
						}
					}
					if(co >= dp) break;
					i++;
				}
			}
			
			s2 = Number(s2);
			if(isNaN(s2)) s2 = 0;
			
			return s2;
			
		}
	
		
		public static function roundTo (numb:*, d:int=0) :Number {
			if(typeof(numb) != "number" ) {
				numb = Number(numb);
			}
			if(d > 0) {
				if(!isNaN(numb)){
					var m:Number = Math.pow(10, d);
					return Math.round(numb*m)/m;
				}
			}else{
				return Math.round(numb);	
			}
			return 0;
		}

	}
	
}
		