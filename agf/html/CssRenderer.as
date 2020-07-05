package agf.html
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.Capabilities;
	import flash.system.System;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import agf.io.Resource;
	
	public class CssRenderer
	{
		/*
		* last rendered css object properties
		*/
		public static var co:CssObject = new CssObject();
		public static var cssFilePath:String = "";
		private static var targetClips:Object = {};
		
		/**
		* Sprites, Images, MovieClip References wich are referenced in css files are stored here
		*/
		public static var clips:Object = {};
		
		/**
		* Render a css sprite
		* @parameter style A 2D Array with strings, style names followed by the syle value: [ ["fontFamily", "Arial"], ["backgroundColor", "#775533"], ["color", "#335577"], ["border", "2px solid #990000"] ... ]
		* @parameter target The css sprite to render
		* @parameter parent The parent sprite used for rendering percent values
		* @parameter w width of the sprite
		* @parameter h height of the sprite
		* @parameter ignoreSize if true, the width and height properties of the style sheet is ignored
		*/
		public static function drawBox (sta:Array, target:CssSprite, parent:CssSprite, w:Number=0, h:Number=0, ignoreSize:Boolean=false) :void 
		{
			
			co.makeDefaults();
			
			var bgSprite:Sprite = target.bgSprite;			
			bgSprite.graphics.clear();
			
			var i:int;
			var stL:int = sta.length;
			
			var st:*;
			var cmd:Array;
			var st2:String;
			var st3:*;
			var o:int;
			var c:int;
			var k:int;
			var name:String;
			var kwc:String;
			var end:int;
			var path:String="";
			
			if(w==0) w = target.getWidth() || 0;
			if(h==0) h = target.getHeight() || 0;
			
			var clipPath:String="";
			var gradient:String="";
			
			// copy required properties to dynamic CssObject - co
			for(k=0; k < stL/* stylesRev.length*/; k++) 
			{
				name = sta[k][0];
				st = sta[k][1];
				
				switch ( name ) 
				{
					case "alpha":
					case "opacity":
						target.alpha = CssUtils.parse(st, parent, "h");
						// break; //Store opacity in co !!  use background alpha also ---v^v^v---v^v^v---v^v^v---v^v^v---v^v^v/\___/\___/\___|O-O||O-O||O-O||O-O||O-O||O-O|___/\___/\___/\v^v^v---v^v^v---v^v^v---v^v^v---v^v^v---
					case "overflow":
						
					case "backgroundAlpha":
					case "backgroundRepeat":
					case "backgroundSize":
					case "borderTopWidth":
					case "borderRightWidth":
					case "borderBottomWidth":
					case "borderLeftWidth":
					case "borderTopColor":
					case "borderRightColor":
					case "borderBottomColor":
					case "borderLeftColor":
					case "borderTopAlpha": 
					case "borderRightAlpha":
					case "borderBottomAlpha":
					case "borderLeftAlpha":
					case "borderTopLeftRadius":
					case "borderTopRightRadius":
					case "borderBottomLeftRadius":
					case "borderBottomRightRadius":	
					case "paddingLeft":
					case "paddingRight":
					case "marginLeft":
					case "marginRight":
					case "color":
					case "textAlign":
						co[name] = CssUtils.parse(st, parent, "h");
						break;
					case "paddingTop":
					case "paddingBottom":
					case "verticalAlign":
					case "marginTop":
					case "marginBottom":
						co[name] = CssUtils.parse(st, parent, "v");
						break;
					case "borderColor":
					case "borderAlpha":
						st2 = name.substring(6,name.length);
						co["borderLeft"+st2] = co["borderTop"+st2] = co["borderRight"+st2] = co["borderBottom"+st2] = CssUtils.parse(st, parent, "h");
						break;
					case "border":
						cmd = st.split(" ");
						for(i=0; i<cmd.length; i++) {
							st2 = cmd[i];
							if(st2 == "none" ) {
								co.borderLeftWidth = co.borderTopWidth = co.borderRightWidth = co.borderBottomWidth = 0;
								break;
							}
							st3 = CssUtils.parse(st2, parent);
							if(st3 is Number) {
								if( CssUtils.isColor(st2) ) {
									co.borderLeftColor = co.borderTopColor = co.borderRightColor = co.borderBottomColor = st3;
								}else{
									co.borderLeftWidth = co.borderTopWidth = co.borderRightWidth = co.borderBottomWidth = st3;
								}
							}
						}
						break;
					case "borderRadius":
						st = CssUtils.parse(st, parent, "v");
						if(typeof(st) == "number") 
						{
							co.borderTopLeftRadius = co.borderTopRightRadius = co.borderBottomLeftRadius = co.borderBottomRightRadius = CssUtils.parse(st, parent, "h");
						}
						else
						{
							if(st!="none") {
								cmd = st.split(" ");
								if(cmd.length == 2) {
									co.borderTopLeftRadius = co.borderBottomRightRadius = CssUtils.parse(cmd[0],parent); 
									co.borderTopRightRadius = co.borderBottomLeftRadius = CssUtils.parse(cmd[1],parent);
								}else if(cmd.length == 3) {
									co.borderTopLeftRadius = CssUtils.parse(cmd[0],parent); 
									co.borderTopRightRadius = co.borderBottomLeftRadius = CssUtils.parse(cmd[1],parent);
									co.borderBottomRightRadius = CssUtils.parse(cmd[1],parent);
								}else{
									co.borderTopLeftRadius = CssUtils.parse(cmd[0],parent); 
									co.borderTopRightRadius = CssUtils.parse(cmd[1],parent);
									co.borderBottomLeftRadius = CssUtils.parse(cmd[2],parent);
									co.borderBottomRightRadius = CssUtils.parse(cmd[3],parent);
								}
							}
						}
						break;
					case "padding":
						st = CssUtils.parse(st, parent, "v");
						if( typeof st == "string" && st.indexOf( " " ) >= 0 )
						{
							var padgs:Array = st.split(" ");
							
							if( padgs.length == 2 ) {
								co.paddingTop = co.paddingBottom = CssUtils.parse( padgs[0], parent, "v" ) ;
								co.paddingLeft = co.paddingRight =  CssUtils.parse( padgs[1], parent, "h" );
							}else if( padgs.length == 3 ) {
								co.paddingTop = CssUtils.parse( padgs[0], parent, "v" );
								co.paddingLeft = co.paddingRight = CssUtils.parse( padgs[1], parent, "h" );
								co.paddingBottom = CssUtils.parse( padgs[2], parent, "v" ) ;
							}else if( padgs.length == 4 ) {
								co.paddingTop = CssUtils.parse( padgs[0], parent, "v" );
								co.paddingRight = CssUtils.parse( padgs[1], parent, "h" );
								co.paddingBottom = CssUtils.parse( padgs[2], parent, "v" );
								co.paddingLeft = CssUtils.parse( padgs[3], parent, "h" );
							}
						}
						else
						{
							co.paddingLeft = co.paddingRight = co.paddingTop = co.paddingBottom = CssUtils.parse(st, parent, "h");
						}
						break;
					case "margin":
						st = CssUtils.parse(st, parent, "v");
						if( typeof st == "string" && st.indexOf( " " ) >= 0 )
						{
							var margs:Array = st.split(" ");
							
							if( margs.length == 2 ) {
								co.marginTop = co.marginBottom = CssUtils.parse( margs[0], parent, "v" ) ;
								co.marginLeft = co.marginRight =  CssUtils.parse( margs[1], parent, "h" );
							}else if( margs.length == 3 ) {
								co.marginTop = CssUtils.parse( margs[0], parent, "v" );
								co.marginLeft = co.marginRight = CssUtils.parse( margs[1], parent, "h" );
								co.marginBottom = CssUtils.parse( margs[2], parent, "v" ) ;
							}else if( margs.length == 4 ) {
								co.marginTop = CssUtils.parse( margs[0], parent, "v" );
								co.marginRight = CssUtils.parse( margs[1], parent, "h" );
								co.marginBottom = CssUtils.parse( margs[2], parent, "v" );
								co.marginLeft = CssUtils.parse( margs[3], parent, "h" );
							}
						}
						else
						{
							co.marginLeft = co.marginRight = co.marginTop = co.marginBottom = CssUtils.parse(st, parent, "h");
						}
						break;
					case "borderTop":
					case "borderRight":
					case "borderBottom":
					case "borderLeft":
						if( typeof(st) == "string" ) {
							if(st == "none") {
								co[name+"Width"] = 0;
							}else{
								cmd = st.split(" ");
								for(i=0; i<cmd.length; i++) {
									st2 = cmd[i];
									st3 = CssUtils.parse(st2, parent);
									if(st3 is Number) {
										if( CssUtils.isColor(st2) ) {
											co[name+"Color"] = st3;
										}else{
											co[name+"Width"] = st3;
										}
									}
								}
							}
						}
						break;
						
						
						
						
						
						
					case "width":
						if( ! ignoreSize) {
							if( st != "auto" ) w = CssUtils.parse(st, parent, "h");
						}
						break;
					case "height":
						if(!ignoreSize) {
							if( st != "auto" )	h = CssUtils.parse(st, parent, "v");
						}
						break;
					case "minWidth":
					case "maxWidth":
						co[name] = CssUtils.parse(st, parent, "h");
						break;
					case "minHeight":
					case "maxHeight":
						co[name] = CssUtils.parse(st, parent, "v");
						break;
					
					
					
					
					
					
					
					case "background":
					case "backgroundImage":
						st = CssUtils.parse(st, parent, "h");
						if(st == "none") {
							co.bgSolid = false;
							co.backgroundImage = false;
							clipPath = "";
						}
						
						else if( isNaN(Number(st)) )
						{
							var cc:int;
							var icmd:String="";
							cmd = [];
							var eid:int;
							for(var ci:int=0; ci<st.length; ci++) 
							{
								cc  =  st.charCodeAt(ci);
								
								if(cc <= 32) {
									// next command
									if(icmd != "") {
										cmd.push(icmd);
										icmd = "";
									}
								}
								else if(cc == 40 ) { // (
									eid = st.indexOf(")", ci);
									icmd += st.substring( ci, eid+1 );
									if(icmd != "") {
										cmd.push(icmd);
										icmd = "";
										ci = eid+1;
									}
								}else{
									icmd += st.charAt(ci);
								}
							}
							
							for(i=0; i<cmd.length; i++) {
								st2 = cmd[i];
								
								if(st2 == "repeat"  || st2 == "repeat-x" || st2 == "repeat-y") {
									co.backgroundRepeat = st2;
								}else if(st2 == "top" || st2 == "middle" || st2 == "bottom") {
									co.bgImagePositionY = st2;
								}else if(st2 == "left" || st2 == "center" || st2 == "right") {
									co.bgImagePositionX = st2;
								}
								else
								{
									path = "";
									
									for(var kw:int=0; kw<st2.length; kw++) 
									{
										kwc = st2.charAt(kw);
										
										if(kwc == "\"") {
											end = st2.indexOf("\"",kw+1);
											clipPath = st2.substring( kw+1, end);
											co.backgroundImage = true;
											co.bgGradient = false;
											co.bgSolid = false;
											break;
										}
										else if(kwc=="'") 
										{
											end = st2.indexOf("'",kw+1);
											clipPath = st2.substring( kw+1, end);
											co.backgroundImage = true;
											break;
										}
										else if(kwc == "(") 
										{
											var act:String = st2.substring(0, kw).toLowerCase();
											
											end = st2.indexOf(")",kw+1);
											
											if( act == "linear-gradient" || act == "-webkit-linear-gradient" ) 
											{
												if(end != -1) 
												{
													gradient = st2.substring(kw+1,end);
													co.bgGradient = true;
													co.bgSolid = false;
													co.backgroundImage = false;
												}
											}
											else if(act == "url") 
											{
												if(end != -1) 
												{
													clipPath = st2.substring(kw+1,end);
													co.backgroundImage = true;
													co.bgGradient = false;
													co.bgSolid = false;
												}
											}
										}
									}
								}
							}
						}else{
							co.bgSolid = true;
							co.backgroundColor = CssUtils.parse(st, parent, "h");
							clipPath = "";
							break;
						}
						break;
					case "backgroundPosition": 
					case "backgroundPositionX": 
					case "backgroundPositionY": 
						cmd = st.split(" ");
						for(i=0; i<cmd.length; i++) {
							st2 = cmd[i];
							if(st2 == "top" || st2 == "middle" || st2 == "bottom") {
								co.bgImagePositionY = st2;
							}else if(st2 == "left" || st2 == "center" || st2 == "right") {
								co.bgImagePositionX = st2;
							}
						}
						break;
					case "backgroundColor": 
						co.bgSolid = true;
						co.backgroundColor = CssUtils.parse(st, parent, "h");
						break;
					
					
					default:
						break;
					
				}
			}
			
			if(w < co.minWidth) w = co.minWidth;
			if(h < co.minHeight) h = co.minHeight;
			
			if(co.maxWidth > 0 && w > co.maxWidth) w = co.maxWidth;
			if(co.maxHeight > 0 && h > co.maxHeight) h = co.maxHeight;
			
			co.width = w;
			co.height = h;
			
			target.textAlign = co.textAlign;
			target.verticalAlign = co.verticalAlign;
			
			// 1------2
			// |      |
			// 4------3
			var p1x:Number = 0;
			var p1y:Number = 0;
			var p2x:Number = co.width + co.paddingRight + co.borderRightWidth  + co.paddingLeft  +  co.borderLeftWidth;
			var p2y:Number = 0;
			var p3x:Number = p2x;
			var p3y:Number = co.height + co.paddingBottom + co.borderBottomWidth  +  co.paddingTop + co.borderTopWidth;
			var p4x:Number = 0;
			var p4y:Number = p3y;
			
			var p5x:Number = co.borderLeftWidth;
			var p5y:Number = co.borderTopWidth;
			var p6x:Number = p2x - co.borderRightWidth;
			var p6y:Number = p5y;
			var p7x:Number = p6x;
			var p7y:Number = p3y-co.borderBottomWidth;
			var p8x:Number = p5x;
			var p8y:Number = p7y;
			
			target._cssLeft = co.borderLeftWidth + co.paddingLeft;
			target._cssTop = co.borderTopWidth + co.paddingTop;
			target._cssRight = target._cssLeft + co.width;
			target._cssBottom = target._cssTop + co.height;
			
			target._cssSizeX = p3x;
			target._cssSizeY = p3y;
			
			target._cssBorderLeft = co.borderLeftWidth;
			target._cssBorderRight = co.borderRightWidth;
			target._cssBorderTop = co.borderTopWidth;
			target._cssBorderBottom = co.borderBottomWidth;
			
			target._cssBorderTopLeftRadius = co.borderTopLeftRadius;
			target._cssBorderTopRightRadius = co.borderTopRightRadius;
			target._cssBorderBottomLeftRadius = co.borderBottomLeftRadius;
			target._cssBorderBottomRightRadius = co.borderBottomRightRadius;
			
			target._cssPaddingLeft = co.paddingLeft;
			target._cssPaddingRight = co.paddingRight;
			target._cssPaddingTop = co.paddingTop;
			target._cssPaddingBottom = co.paddingBottom;
			
			target._cssMarginLeft = co.marginLeft;
			target._cssMarginRight = co.marginRight;
			target._cssMarginTop = co.marginTop;
			target._cssMarginBottom = co.marginBottom;
			
			target._cssColor = co.color;
			target._cssBackgroundColor = co.backgroundColor;
			
			co.w = p3x;
			co.h = p3y;
			
			bgSprite.graphics.clear();
			bgSprite.graphics.lineStyle( undefined,0,1 );
			bgSprite.graphics.beginFill( 0,0 );
			bgSprite.graphics.drawRect( p5x,p5y,p7x-p5x,p7y-p5y );
			bgSprite.graphics.endFill();
			
			if(co.bgSolid)
			{
				bgSprite.graphics.lineStyle( undefined, 0, 1 );
				bgSprite.graphics.beginFill( co.backgroundColor, co.backgroundAlpha );
				drawBorderRect ( co, bgSprite, p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y );				
				bgSprite.graphics.endFill();
			}
			else if(co.bgGradient && gradient != "")
			{
				drawGradient(gradient, target, co, p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y);
			}
			else if( co.backgroundImage && clipPath != "") 
			{
				loadClip( clipPath, target, p1x, p1y, p2x, p2y, p3x, p3y, p4x, p4y );
			}
			
			if ( co.borderBottomLeftRadius == 0 && co.borderTopLeftRadius == 0 && co.borderBottomRightRadius == 0 && co.borderTopRightRadius == 0 )
			{
				if (co.borderLeftWidth > 0) drawQuadPoly(bgSprite, co.borderLeftColor, 0, undefined, p1x, p1y, p5x, p5y, p8x, p8y, p4x, p4y, co.borderLeftAlpha);
				
				if (co.borderTopWidth > 0) drawQuadPoly(bgSprite, co.borderTopColor, 0, undefined, p1x, p1y, p2x, p2y, p6x, p6y, p5x, p5y, co.borderTopAlpha);
				
				if (co.borderRightWidth > 0) drawQuadPoly(bgSprite, co.borderRightColor, 0, undefined, p6x, p6y, p2x, p2y, p3x, p3y, p7x, p7y, co.borderRightAlpha);
				
				if(co.borderBottomWidth > 0) drawQuadPoly(bgSprite, co.borderBottomColor, 0, undefined, p8x,p8y, p7x,p7y, p3x,p3y, p4x,p4y, co.borderBottomAlpha);
			}
			else
			{
				var ct:Number;
				
				if( co.borderTopWidth > 0 ) {
					
					bgSprite.graphics.lineStyle( co.borderTopWidth, co.borderTopColor, co.borderTopAlpha);
					ct = co.borderTopWidth / 2;
					
					if( co.borderTopLeftRadius > 0 ) {
						bgSprite.graphics.moveTo( p1x + ct, p1y + co.borderTopLeftRadius );
						bgSprite.graphics.curveTo( p1x + ct, p1y + ct, p1x + co.borderTopLeftRadius, p1y + ct );
					}else{
						bgSprite.graphics.moveTo( p1x + ct, p1y + ct);
					}
					
					if( co.borderTopRightRadius > 0 ) {
						bgSprite.graphics.lineTo( p2x - co.borderTopRightRadius, p2y + ct );
					}else{
						bgSprite.graphics.lineTo( p2x - ct, p2y + ct );
					}
					
				}
				
				if( co.borderRightWidth > 0 )
				{					
					bgSprite.graphics.lineStyle( co.borderRightWidth, co.borderRightColor, co.borderRightAlpha);
					ct = co.borderRightWidth / 2;
					
					if( co.borderTopRightRadius > 0 ) {
						bgSprite.graphics.moveTo( p2x - co.borderTopRightRadius, p2y + ct );
						bgSprite.graphics.curveTo( p2x - ct, p2y + ct, p2x - ct, p2y + co.borderTopRightRadius );
					}else{
						bgSprite.graphics.moveTo( p2x - ct, p2y + ct );
					}
					
					if( co.borderBottomRightRadius > 0 ) {
						bgSprite.graphics.lineTo( p3x - ct, p3y - co.borderBottomRightRadius );
					}else{
						bgSprite.graphics.lineTo( p3x - ct, p3y - ct );
					}
				}
				
				if( co.borderBottomWidth > 0 )
				{					
					bgSprite.graphics.lineStyle( co.borderBottomWidth, co.borderBottomColor, co.borderBottomAlpha);
					ct = co.borderBottomWidth / 2;
					
					if( co.borderBottomRightRadius > 0 ) {
						bgSprite.graphics.moveTo(  p3x - ct, p3y - co.borderBottomRightRadius  );
						bgSprite.graphics.curveTo( p3x - ct, p3y - ct,  p3x - co.borderBottomRightRadius, p3y - ct );
					}else{
						bgSprite.graphics.moveTo( p3x - ct, p3y - ct );
					}
					
					if( co.borderBottomLeftRadius > 0 ) {
						bgSprite.graphics.lineTo( p4x + co.borderBottomLeftRadius, p4y - ct );
					}else{
						bgSprite.graphics.lineTo( p4x + ct, p4y - ct );
					}
				}
				
				if( co.borderLeftWidth > 0 )
				{					
					bgSprite.graphics.lineStyle( co.borderBottomWidth, co.borderBottomColor, co.borderBottomAlpha);
					ct = co.borderBottomWidth / 2;
					
					if( co.borderBottomLeftRadius > 0 ) {
						bgSprite.graphics.moveTo( p4x + co.borderBottomLeftRadius, p4y - ct  );
						bgSprite.graphics.curveTo( p4x + ct, p4y - ct,  p4x + ct, p4y - co.borderBottomLeftRadius );
					}else{
						bgSprite.graphics.moveTo( p4x + ct, p4y - ct );
					}
					
					if( co.borderTopLeftRadius > 0 ) {
						bgSprite.graphics.lineTo( p1x + ct, p1y + co.borderTopLeftRadius );
					}else{
						bgSprite.graphics.lineTo( p1x + ct, p1y + ct );
					}
				}
			}
			
			if(co.overflow != "visible") {
				target.scrollRect = new Rectangle(0,0,p3x,p3y);
			}
		}
		
		public static function drawBorderRect (co:Object, bgSprite:Sprite, p5x:Number, p5y:Number, p6x:Number, p6y:Number, p7x:Number, p7y:Number, p8x:Number, p8y:Number, ignoreTL:Boolean=false, ignoreTR:Boolean=false, ignoreBL:Boolean=false, ignoreBR:Boolean=false) :void {
			if( co.borderTopLeftRadius > 0 && !ignoreTL) {
				bgSprite.graphics.moveTo( p5x, p5y + co.borderTopLeftRadius );
				bgSprite.graphics.curveTo( p5x, p5y, p5x + co.borderTopLeftRadius, p5y );
			}else{
				bgSprite.graphics.moveTo( p5x, p5y );
			}
			
			if( co.borderTopRightRadius > 0 && !ignoreTR) {
				bgSprite.graphics.lineTo( p6x - co.borderTopRightRadius, p6y );
				bgSprite.graphics.curveTo( p6x, p6y, p6x, p6y + co.borderTopRightRadius );
			}else{
				bgSprite.graphics.lineTo( p6x, p6y );
			}
			
			if( co.borderBottomRightRadius > 0 && !ignoreBR) {
				bgSprite.graphics.lineTo( p7x, p7y - co.borderBottomRightRadius );
				bgSprite.graphics.curveTo( p7x, p7y, p7x - co.borderBottomRightRadius, p7y );
			}else{
				bgSprite.graphics.lineTo( p7x, p7y );
			}
			
			if( co.borderBottomLeftRadius > 0 && ! ignoreBL) {
				bgSprite.graphics.lineTo( p8x + co.borderBottomLeftRadius, p8y );
				bgSprite.graphics.curveTo( p8x, p8y, p8x, p8y - co.borderBottomLeftRadius );
			}else{
				bgSprite.graphics.lineTo( p8x, p8y );
			}
		}
		
		public static function drawGradient (gradient:String, target:CssSprite, cssObj:CssObject, p5x:Number, p5y:Number, p6x:Number, p6y:Number, p7x:Number, p7y:Number, p8x:Number, p8y:Number) :void {
			var chunks:Array = gradient.split(",");
			var dir:String = chunks.shift();
			var col:Array = [];
			var alp:Array = [];
			var pos:Array = [];
			var ichunk:Array;
			
			for(var i:int=0; i<chunks.length; i++) {
				ichunk = CssUtils.trim( chunks[i]).split(" ");
				col.push ( CssUtils.parse( ichunk[0], target) );
				alp.push( ichunk.length > 2 ? CssUtils.parse(ichunk[2],target) : 255 );
				pos.push( Number(ichunk[1].substring(0,ichunk[1].length-1))*2.55 );
			}
			var mtx:Matrix = new Matrix();
			var rot:Number = 0;
			if(dir == "top") rot = -Math.PI/2;
			else if(dir == "-45deg") rot = -Math.PI/4;
			else if(dir == "45deg") rot = Math.PI/4;
			else if(!isNaN(Number(dir))) rot = Number(dir)*Math.PI/180;
			mtx.createGradientBox(cssObj.w-cssObj.borderLeftWidth-cssObj.borderRightWidth, cssObj.h-cssObj.borderTopWidth-cssObj.borderBottomWidth, rot, cssObj.borderLeftWidth, cssObj.borderTopWidth);
			target.bgSprite.graphics.beginGradientFill(GradientType.LINEAR, col, alp, pos, mtx);			
			drawBorderRect( cssObj, target.bgSprite, p5x, p5y, p6x, p6y, p7x, p7y, p8x, p8y);
			target.bgSprite.graphics.endFill();
			if( cssObj.backgroundAlpha < 1 ) target.bgSprite.alpha = cssObj.backgroundAlpha;
		}
		
		public static function placeClip (clip:DisplayObject, target:CssSprite, cssObj:CssObject, p5x:Number, p5y:Number, p6x:Number, p6y:Number, p7x:Number, p7y:Number, p8x:Number, p8y:Number) :void 
		{
			if(target) 
			{
				if(clip is Bitmap) {
					clip = new Bitmap(Bitmap(clip).bitmapData.clone());
				}else{
					var def:Object;
					try{
						def = getDefinitionByName( getQualifiedClassName(clip) );
						clip = new def();
					}catch(e:Error){
						def=null;
					}
				}
				
				if(clip is DisplayObject)
				{
					var tmp:Sprite = target.bgSprite;
					
					if(cssObj.width > 0 && cssObj.height > 0) {
						
						var mt:Matrix = new Matrix();
						
						if( cssObj.backgroundSize == "contain" ) {
							mt.scale( cssObj.width/ clip.width, cssObj.height/clip.height  );
						//}else if( cssObj.backgroundSize == "cover" ) {
						}
						
						if(clip is Bitmap) 
						{
							tmp.graphics.beginBitmapFill(Bitmap(clip).bitmapData, mt );
							
							if(cssObj.backgroundRepeat == "repeat") {
								drawBorderRect( cssObj, tmp, p5x, p5y, p6x, p6y, p7x, p7y, p8x, p8y);
							}else if(cssObj.backgroundRepeat == "repeat-x") {
								drawBorderRect( cssObj, tmp, p5x, p5y, p6x, p6y, p7x, Math.min( clip.height, p7y), p8x, Math.min(clip.height, p8y), false, false, true, true);
							}else if(cssObj.backgroundRepeat == "repeat-y") {
								drawBorderRect( cssObj, tmp, p5x, p5y, Math.min(clip.width, p6x), p6y, Math.min(clip.width, p7x), p7y, p8x, p8y, false, true, false, true);
							}else if(cssObj.backgroundRepeat == "no-repeat") {
								drawBorderRect( cssObj, tmp, p5x, p5y, Math.min(clip.width, p6x), p6y, Math.min(clip.width, p7x), Math.min( clip.height, p7y), p8x, Math.min(clip.height, p8y), false, p6x > clip.width, p7y > clip.height, p6x > clip.width || p7y > clip.height);
							}
							tmp.graphics.endFill();
						}
					}
					tmp.alpha = cssObj.backgroundAlpha;
				} // if displayobject clip
			} // if target
		}
		
		private static function clearSprite (target:DisplayObjectContainer) :void {
			if(target.numChildren > 0) for(var i:int=target.numChildren-1; i>=0; i--) target.removeChildAt(i);
		}
		
		public static function loadClip (path:String, target:CssSprite, p5x:Number, p5y:Number, p6x:Number, p6y:Number, p7x:Number, p7y:Number, p8x:Number, p8y:Number) :void
		{
			if( clips[path] is DisplayObject ) 
			{
				// File already finished loading
				placeClip( DisplayObject(clips[path]), target, co, p5x, p5y, p6x, p6y, p7x, p7y, p8x, p8y);
				target.onLoaded();
			}
			else
			{
				if(clips[path] == null) 
				{
					clips[path] = -1;
					var r:Resource = new Resource();
					r.udfData.co = co.clone();
					r.udfData.clipTarget = target;
					r.udfData.path = path;
					r.udfData.p5x = p5x;
					r.udfData.p5y = p5y;
					r.udfData.p6x = p6x;
					r.udfData.p6y = p6y;
					r.udfData.p7x = p7x;
					r.udfData.p7y = p7y;
					r.udfData.p8x = p8x;
					r.udfData.p8y = p8y;
					
					// test if path is absolute...
					if(isAbsolutePath(path))
						r.load(path, false, clipLoaded);
					else
						r.load(cssFilePath + path, false, clipLoaded);
				}
				else
				{
					// File currently loading
					if(targetClips[path]==null) targetClips[path] = [];
					targetClips[path].push( { cssSprite: target, co: co.clone(), p5x:p5x, p5y:p5y, p6x:p6x, p6y:p6y, p7x:p7x, p7y:p7y, p8x:p8x, p8y:p8y } );
				}
			}
		}
		
		public static function isAbsolutePath (path) :Boolean {
			var t = path.substring(0,7);
			return t == "http://" || t == "https:/" || t == "file://";
		}
		
		public static function clipLoaded(e:Event, res:Resource) :void 
		{
			if( !res.loaded || !res.obj ) return;
			
			var clip:DisplayObject = DisplayObject(res.obj);
			if( ! clip ) return;
			
			clips[ res.udfData.path ] = clip;
			
			placeClip( clip, res.udfData.clipTarget, CssObject(res.udfData.co), res.udfData.p5x, res.udfData.p5y, res.udfData.p6x, res.udfData.p6y, res.udfData.p7x, res.udfData.p7y, res.udfData.p8x, res.udfData.p8y );
			
			if(targetClips[res.url]) {
				var r:Array = targetClips[res.url];
				var o:Object;
				
				for(var i:int =0 ; i<r.length; i++) {
					o = r[i];
					placeClip(clip, CssSprite(o.cssSprite), CssObject(o.co), o.p5x, o.p5y, o.p6x, o.p6y, o.p7x, o.p7y, o.p8x, o.p8y ); 
				}
				targetClips[res.url] = null;
			}
			
			res.udfData.clipTarget.onLoaded();
		}
		
		public static function drawQuadPoly (sp:Sprite, col:uint, lineCol:*, lineStyl:*, 
											 x1:Number, y1:Number, 
											 x2:Number, y2:Number, 
											 x3:Number, y3:Number, 
											 x4:Number, y4:Number, 
											 alpha:Number=1) :void 
		{
			var mc:Graphics = sp.graphics;
			mc.lineStyle(lineStyl, lineCol, alpha);
			mc.beginFill(col, alpha);
			mc.moveTo(x1, y1);
			mc.lineTo(x2, y2);
			mc.lineTo(x3, y3);
			mc.lineTo(x4, y4);
			mc.endFill();
		}
			
	}
}