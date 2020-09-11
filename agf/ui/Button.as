package agf.ui
{
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.text.*;
	
	import agf.html.CssRenderer;
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.html.CssUtils;
	
	
	public class Button extends CssSprite
	{
		public function Button(icons:Array, w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false)
		{
			super(w, h, parentCS, style, "button", cssId, cssClasses, true);
			
			_label = new Label(0, 0, this, cssStyleSheet);
			_label.mouseEnabled = false;
			_label.mouseChildren = false;
			clips = icons;
			if(!noInit) init();
		}
		
		public var iconTop:Sprite;
		public var iconBottom:Sprite;
		public var iconTopAlign:String="left"; // left,center,right,label,icon-left,icon-right,icon-left-2,..icon-right-N
		public var iconBottomAlign:String = "left";
		
		public var margin:Number = 7;
		public var clipSpacing:Number=4;
		
		public var contLeft:CssSprite; // [ic_l,ic_l,..,label]
		public var contRight:CssSprite;
		
		protected var _hasLabel:Boolean = false;
		protected var _labelIndex:int = -1;
		protected var _hasLeftClips:Boolean = false;
		protected var _hasRightClips:Boolean = false;
		
		public function get hasLabel () :Boolean { return _hasLabel; }
		public function get hasLeftClips () :Boolean { return _hasLeftClips; }
		public function get hasRightClips () :Boolean { return _hasRightClips; }
		
		protected var _clips:Array;
		public function get clips () :Array { return _clips; }
		
		private var _labelText:String="";
		protected var _label:Label;
		
		public function get label () :String {	return _labelText; }
		public function set label (v:String) :void {   _labelText = v;	init();	}
		
		public var autoHideLabel:Boolean = false;
		
		public function get labelSprite () :Label { return _label; }
		
		// [ic_l,ic_l,..,label,ic_r,ic_r..,[ic_top,ic_bottom],[ic_top_align,ic_bottom_align]]
		public function set clips (v:Array) :void
		{	
			removeClips();
			_clips = v;
			
			if( _clips ) {
				var L:int = _clips.length;
				
				if( L > 0 )
				{
					_labelIndex = -1;
					
					var cp:DisplayObjectContainer;
					var lc:DisplayObjectContainer;
					var iconTBFound:Boolean=false;
					
					for(var i:int=0; i < _clips.length; i++) 
					{
						if(_clips[i]) {
							if( _clips[i] is DisplayObjectContainer )
							{
								cp = DisplayObjectContainer( _clips[i] );
								
								if( _labelIndex == -1 ){
									_hasLeftClips = true;
									if( !contLeft ) contLeft = new CssSprite(0,0,this,cssStyleSheet);
									contLeft.mouseEnabled = false;
									contLeft.mouseChildren = false;
									contLeft.addChild(cp);
								}else{
									_hasRightClips = true;
									if( !contRight ) contRight = new CssSprite(0,0,this,cssStyleSheet);
									contRight.mouseEnabled = false;
									contRight.mouseChildren = false;
									contRight.addChild(cp);
								}
								
								if( !lc ) cp.x = clipSpacing;
								else cp.x = int(lc.x + lc.width + clipSpacing);
								lc = cp;
							}
							else if( typeof _clips[i] == "string" )
							{
								if( !_hasLabel )
								{
									_hasLabel = true;
									_labelText = _clips[i];
									_labelIndex = i;
								}else{
									
									// Create new Label in contLR (to support raw-string-icon)
									
								}
								lc = null;
							}
							else if( clips[i] is Array )
							{
								if( iconTBFound ) {
									if( clips[i].length > 0 ) {
										iconTopAlign = clips[i][0];
									}
									if( clips[i].length > 1 ) {
										iconBottomAlign = clips[i][1];
									}
									
								}else{
									if( clips[i].length > 0 ) {
										iconTop = Sprite(clips[i][0]);
									}
									if( clips[i].length > 1 ) {
										iconBottom = Sprite(clips[i][1]);
									}
									iconTBFound = true;
								}
							}
						}
					}
				}
			}
		}
		private function removeClips () :void 
		{
			if(contLeft && contains(contLeft)) {
				removeChild(contLeft);
				contLeft = null;
			}
			if(contRight && contains(contRight)) {
				removeChild(contRight);
				contRight = null;
			}
			if( iconTop && contains(iconTop) ) {
				removeChild( iconTop );
				iconTop = null;
			}
			if( iconBottom && contains(iconBottom) ) {
				removeChild( iconBottom );
				iconBottom = null;
			}
			_clips = null;
			_hasLeftClips = false;
			_hasRightClips = false;
			_hasLabel = false;
		}
		
		public override function init (dontDraw:Boolean=false) :void
		{
			super.init(dontDraw);
			if(!dontDraw) swapState( state );
		}
		
		public override function setHeight ( h:int ) :void {
			if(_label) _label.y = int(cssTop);
			cssHeight=0;
			super.setHeight( h-cssBoxY );
			
			init();
		}
		
		public override function setWidth ( w:int ) :void
		{			
			super.setWidth( w);
			
			var l:int = cssLeft;
			var r:int = cssRight;
			
			if( contLeft ) {
				l += contLeft.width + margin;
			}
			
			if( contRight ) {
				r -= contRight.width;
				contRight.x = r;
			}
			if( _label ) {
				
				if( contRight ) {
					_label.setWidth( r - _label.x );
				}else{
					_label.setWidth( cssRight - _label.x );
				}
				
				if( autoHideLabel && _label && _label.textField ) {
					if( _label.textField.textWidth > r - _label.x ) {
						if( _label.visible == true ) {
							_label.visible = false;
						}
						if( contLeft ) {
							//center icon..
							contLeft.x = int( cssLeft + Math.floor( (w - contLeft.width)*.5 ) );
						}
						
					}else {
						if( _label.visible == false ) {
							// show label
							_label.visible = true;
						}
					}
				}
				
				if( textAlign == "center" ) {
					_label.x = Math.round( l + ((r-l) - _label.width)/2 );
				}else if( textAlign == "left" ) {
					_label.x = Math.round(l);
				}else if( textAlign == "right" ) {
					_label.x = Math.round( r - _label.width );
				}
			}
			posIconTB();
			init();
		}
		private function posIconTB () :void {
			
			if( iconTop ) {
				if( iconTopAlign == "left" ) {
					iconTop.x = Math.round(cssLeft);
				}
				else if( iconTopAlign == "center" ) {
					iconTop.x = Math.round((cssRight-cssLeft)/2 - iconTop.width/2 );
				}
				else if( iconTopAlign == "right" ) {
					iconTop.x = Math.round(cssRight-iconTop.width);
				}
				else if( iconTopAlign == "label" ) {
					iconTop.x = _label ? int(_label.x) : Math.round(cssLeft);
				}
			}
			
			if( iconBottom ) {
				if( iconBottomAlign == "left" ) {
					iconBottom.x = Math.round(cssLeft);
				}
				else if( iconBottomAlign == "center" ) {
					iconBottom.x = Math.round((cssRight-cssLeft)/2 - iconBottom.width/2 );
				}
				else if( iconBottomAlign == "right" ) {
					iconBottom.x = Math.round(cssRight-iconBottom.width);
				}
				else if( iconBottomAlign == "label" ) {
					iconBottom.x = _label ? int(_label.x) : Math.round(cssLeft);
				}
			}
		}
		public override function swapState ( state:String = "normal" ) :void 
		{
			var i:int;
			
			if(_label && _hasLabel) 
			{
				// Redraw font-styles for the label with inline StyleSheet only for the textfield
				if(state == "normal") {
					_label.textField.styleSheet = cssStyleSheet;
				}else{
					// TODO: search contLR for labels to support raw-string-icons and hover active etc
					var st:Object = {};
					var cs:Array;
					var arr:Array = [];
					
					if( stylesArray ) {
						for(i=0; i< stylesArray.length; i++) {
							arr.push( stylesArray[i], stylesArray[i]+":"+state);
						}
					}
					cs = cssStyleSheet.getStyleArray(arr);
					var tmp:StyleSheet = new StyleSheet();
					if(cs.length > 0) {
						for(i=0; i < cs.length; i++) {
							st[cs[i][0]] = cs[i][1];
						}
					}
					
					tmp.setStyle( "label", st );
					tmp.setStyle( "textfield", st );
					tmp.setStyle( "p."+nodeClass, st );
					tmp.setStyle( "."+nodeClass, st );
					tmp.setStyle( nodeName, st );
					
					_label.textField.styleSheet = tmp;
				}
			}
			
			var cntW:Number = 0;
			var cntH:Number = 0;
			var tmpH:Number;
			
			// Align to minimum width
			if( _hasLeftClips ) {
				contLeft.x = int(cssLeft);
				cntW += contLeft.width;
				cntH = contLeft.height;
			}
			
			if ( _hasLabel && _labelText ){
				
				_label.textField.htmlText = buildHtmlText( _labelText );
				cntW += _label.width;
				tmpH = _label.height;
				if( tmpH > cntH ) cntH = tmpH;
				if(_hasLeftClips) _label.x = int(cssLeft + contLeft.width + margin);
				else _label.x = int(cssLeft);
			}
			
			if( _hasRightClips ) {
				cntW += contRight.width;
				tmpH = contRight.height;
				if( tmpH > cntH ) cntH = tmpH;
				if(_hasLeftClips) contRight.x = int(cssLeft + contLeft.width + margin);
				else contRight.x = int(cssLeft);
				if(_hasLabel) contRight.x += int(_label.width + margin);
			}
			
			// re-align
			if( iconTop ) {
				cntH += iconTop.height;
			}
			if( iconBottom ) {
				cntH += iconBottom.height;
			}
			
			super.swapState(state);
			var L:int;
			var d:DisplayObject;
			var hgt:Number = cssSizeY;
			
			if(_hasLeftClips) {
				contLeft.x = int(cssLeft);
				contLeft.y = 0;
				L = contLeft.numChildren;
				if( verticalAlign == "middle" || verticalAlign == "bottom" ) {
					for(i=0; i < L; i++) {
						d = contLeft.getChildAt(i);
						d.y = int( (verticalAlign == "middle" ? (hgt/2 - d.height/2) : (hgt - d.height)) );
					}
				}else{
					for(i=0; i < L; i++) {
						contLeft.getChildAt(i).y = int( cssTop );
					}
				}
			}
			if(_hasLabel) 
			{
				if(_hasLeftClips) _label.x = cssLeft + contLeft.width + margin;
				else _label.x = int(cssLeft);
				
				if( verticalAlign == "middle" || verticalAlign == "bottom" ) {
					_label.y = int( ( verticalAlign == "middle" ? ((hgt/2 - _label.getHeight()/2 ) ) : (hgt - _label.getHeight())) );
				}else{
					_label.y = int( cssTop );
				}
				if(!contains(_label)) addChild(_label);
			}else{
				if(contains(_label)) removeChild(_label);
			}
			
			if(_hasRightClips) {
				contRight.x = int( cssRight - contRight.width );
				contRight.y = 0;
				L = contRight.numChildren;
				if( verticalAlign == "middle" || verticalAlign == "bottom" ) {
					
					for(i=0; i < L; i++) {
						d = contRight.getChildAt(i);
						d.y = int( (verticalAlign == "middle" ? (hgt/2 - d.height/2) : (hgt - d.height)) );
					}
				}else{
					for(i=0; i < L; i++) {
						contRight.getChildAt(i).y = int( cssTop );
					}
				}
			}
			
			if( iconTop != null ) {
				iconTop.y = cssTop;
				if(!contains(iconTop)) addChild(iconTop);
				if(contLeft) contLeft.y += int(iconTop.height);
				if(contRight) contRight.y += int(iconTop.height);
				if(_label) _label.y += int(iconTop.height);
			}
			if( iconBottom != null) {
				iconBottom.y = int(cntH-iconBottom.height-cssBoxBottom);
				if(!contains(iconBottom)) addChild(iconBottom);
			}
			if( iconTop || iconBottom ) {
				cssHeight=0;
				super.setHeight(cntH);
				posIconTB();
			}
		
		}
		
	}
}