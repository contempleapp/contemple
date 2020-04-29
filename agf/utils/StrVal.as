package agf.utils 
{
	import flash.display.MovieClip;
	import flash.utils.getDefinitionByName;
	
	import flash.system.ApplicationDomain;
	import flash.utils.getDefinitionByName;
	import flash.xml.XMLDocument;
	import flash.xml.XMLNode;
	
	public class StrVal 
	{
		public static var swfRoot:MovieClip;
		
		public static function strvalNone (val:String="") :* 
		{
			return val;
		}
		
		public static function strval (val:String="") :* 
		{
			if(val != "" && val.charCodeAt(0) == 123) 
			{
				// Evaluate Attribute in curly brackets
				var c2:String = val.charAt(1);
				var c:String = val.substring(2, val.length-1);
				
				if( c.indexOf( "+" ) != -1 ) {
					var pa:Array = c.split("+");
					
					var rString:String = "";
					if(pa.length > 0) {
						pa[0] = c2 + pa[0];
						for(var k:int=0; k<pa.length; k++) {
							rString += strval( "{"+pa[k]+"}" );
						}
					}
					return rString;
				}
				
				var p:int;
				var i:uint;
				var a:Array;
				var t:*;
				
				if(c2 == "*") {
					// Express path relative to root swf target"
					p = c.indexOf(".");
					
					var r:*;
					if(p == -1) {
						
						if(c=="") return swfRoot;
						try{
							if(swfRoot[c] == null) {
								r = flash.utils.getDefinitionByName( c );
								if( r != null ) {
									return r;
								}								
							}else{
								return swfRoot[c];
							}
						}catch(e:Error) {
								// trace("StrVal.strval: Target not found: " + c);
						}
						
					}else{
						
						if(ApplicationDomain.currentDomain.hasDefinition(c) ) {
							return ApplicationDomain.currentDomain.getDefinition(c);
						}else{
							
							a = c.split(".");
							var cl:String = a[0];
							
							for(var step:int=1; step<a.length-1; step++) {
								cl += "." + a[step];
							}
							
							if(ApplicationDomain.currentDomain.hasDefinition(cl) ) {
								return ApplicationDomain.currentDomain.getDefinition(cl)[a[a.length-1]];
							}else{
								if(swfRoot[a[0]] != null) {
									t = swfRoot;
									for(i=0; i<a.length; i++) {
										if(t[a[i]] == null) {
											return null;
										}else{
											t = t[a[i]];
										}
									}
									return t;
								}else{
									
									var val:String = a.pop();
									var path:String = a.join(".");
									
									try {
										r = flash.utils.getDefinitionByName( path+"."+val );
									}catch(e:Error) {
										r = null;
									}
									
									if(r==null) {
										try {
											r = flash.utils.getDefinitionByName( path );
										}catch(e:Error) {
											r = null;
											var st:int=-1;
											var dobj:*;
											var res:*;
											var dstr:String = a[0] + "." + a[1];
											for(var li:int=2; li<a.length; li++) {
												try {
													dobj = getDefinitionByName( dstr );
													break;
													
												}catch(e:Error) {
												}
												
												dstr += "." + a[li];
											}
											
											if(dobj != null) {
												// run from dobj;
												t = dobj;
												
												for(i=li; i<a.length; i++) 
												{
													if(t[a[i]] == null) {
														return null;
													}else{
														t = t[a[i]];
													}
												}
												return t[val];
											}
										}
										if(r == null) return null;
										if( r[val] != null ) {
											return r[val];
										}else{
											return null;
										}
									}else{
										return r;
									}
								}
							}
						}
					}
				}
				else{
					return val.substring(1, val.length-1);
				}
			}

			return val;
		}
		
		public static var getval:Function = strval;
		
	}
	
}