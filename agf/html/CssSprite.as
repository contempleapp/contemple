package agf.html
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	import agf.ui.Ctrl;
	import agf.events.CssEvent;
	
	public class CssSprite extends Ctrl
	{
		public function CssSprite (w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) 
		{
			nodeName  = name || "div";
			nodeId    = id;
			nodeClass = classes;
			
			bgSprite  = new Sprite();
			addChild(bgSprite);
			
			cssWidth  = w;
			cssHeight = h;
			
			if(parentCS) {
				parentCS.addChild( this );
				_parentNode = parentCS;
			}
			
			cssStyleSheet = style;
			
			if(!noInit) init();
		}
		
		public static var mouseIsDown:Boolean=false;
		public static var focusCtrl:CssSprite;
		
		public var initialized:Boolean=false;
		
		public var nodeName:String;
		public var nodeId:String;
		public var nodeClass:String;		// Node classes, multiple classnames can be separated by whitespace
		
		public var textAlign:String="left";
		public var verticalAlign:String="middle";
		
		public var bgSprite:Sprite;         // Contains the graphics renderein of bgs and border
		
		public var cssWidth:Number;			// The prefered size of the Sprite
		public var cssHeight:Number;
		
		protected var cssStyleSheet:CssStyleSheet;
		public var _parentNode:CssSprite;
		
		public var autoSwapState:String = "all"; //all, hover, press or empty ""
		public var cssStates:Object = { _normal:null, _hover:null, _active:null, _disabled:null };
		public var stylesArray:Array;
		
		public var contextStyles:Array=[]; // contextual styles div img, div > img
		public var inheritStyles:Array=[]; // apply inherited styles only before any other styles
		
		public var fluid:Boolean=false;
		public var ignoreSize:Boolean = false;
		
		// used by xml renderer
		internal var maxLineHeight:Number = 0;
		internal var cursorX:Number = 0;
		internal var cursorY:Number = 0;
		
		internal var _cssLeft  :Number=0;
		internal var _cssRight :Number=0;
		internal var _cssTop   :Number=0;
		internal var _cssBottom:Number=0;
		
		internal var _cssSizeX:Number=0;
		internal var _cssSizeY:Number=0;
		
		internal var _cssBorderLeft   :Number=0;
		internal var _cssBorderRight  :Number=0;
		internal var _cssBorderTop    :Number=0;
		internal var _cssBorderBottom :Number=0;
		
		internal var _cssBorderTopLeftRadius     :Number=0;
		internal var _cssBorderTopRightRadius    :Number=0;
		internal var _cssBorderBottomLeftRadius  :Number=0;
		internal var _cssBorderBottomRightRadius :Number=0;
		
		internal var _cssPaddingLeft   :Number=0;
		internal var _cssPaddingRight  :Number=0;
		internal var _cssPaddingTop    :Number=0;
		internal var _cssPaddingBottom :Number=0;
		
		internal var _cssMarginLeft   :Number=0;
		internal var _cssMarginRight  :Number=0;
		internal var _cssMarginTop    :Number=0;
		internal var _cssMarginBottom :Number=0;
		
		internal var _cssColor:uint=0x0;
		internal var _cssBackgroundColor:uint=0xFFFFFF;
		
		private var styl:Array;
		
		public function get cssLeft ()   :Number { return _cssLeft; }
		public function get cssRight ()  :Number { return _cssRight; }
		public function get cssTop ()    :Number { return _cssTop; }
		public function get cssBottom () :Number { return _cssBottom; }
		
		public function get cssSizeX () :Number { return _cssSizeX; }
		public function get cssSizeY () :Number { return _cssSizeY; }
		
		public function get cssBorderLeft ()   :Number { return _cssBorderLeft; }
		public function get cssBorderRight ()  :Number { return _cssBorderRight; }
		public function get cssBorderTop ()    :Number { return _cssBorderTop; }
		public function get cssBorderBottom () :Number { return _cssBorderBottom; }
		
		public function get cssPaddingLeft ()   :Number { return _cssPaddingLeft; }
		public function get cssPaddingRight ()  :Number { return _cssPaddingRight; }
		public function get cssPaddingTop ()    :Number { return _cssPaddingTop; }
		public function get cssPaddingBottom () :Number { return _cssPaddingBottom; }
		
		public function get cssMarginLeft ()   :Number { return _cssMarginLeft; }
		public function get cssMarginRight ()  :Number { return _cssMarginRight; }
		public function get cssMarginTop ()    :Number { return _cssMarginTop; }
		public function get cssMarginBottom () :Number { return _cssMarginBottom; }
		
		
		public function get cssColor () :Number{ return _cssColor; }
		public function get cssBackgroundColor () :Number{ return _cssBackgroundColor; }
		
		public function get cssBorderTopLeftRadius ()   :Number{ return _cssBorderTopLeftRadius; }
		public function get cssBorderTopRightRadius ()  :Number{ return _cssBorderTopRightRadius; }
		public function get cssBorderBottomLeftRadius ()    :Number{ return _cssBorderBottomLeftRadius; }
		public function get cssBorderBottomRightRadius () :Number{ return _cssBorderBottomRightRadius; }
		
		public function get styleSheet () :CssStyleSheet { return cssStyleSheet;	}
		
		public override function setWidth (w:int) :void { cssWidth = w; redrawStyle(); }		
		public override function getWidth () :int { return cssWidth || width; }
		
		public override function setHeight (h:int) :void { cssHeight = h; redrawStyle(); }
		public override function getHeight () :int { return cssHeight || height; }
		
		public function get cssMarginX () :Number {
			return _cssMarginLeft + _cssMarginRight;
		}
		public function get cssMarginY () :Number {
			return _cssMarginTop + _cssMarginBottom;
		}
		public function get cssPaddingX () :Number {
			return _cssPaddingLeft + _cssPaddingRight;
		}
		public function get cssPaddingY () :Number {
			return _cssPaddingTop + _cssPaddingBottom;
		}
		
		public function get cssBoxRight () :Number {
			return _cssBorderRight + _cssPaddingRight;
		}
		public function get cssBoxBottom () :Number {
			return _cssBorderBottom + _cssPaddingBottom;
		}
		public function get cssBoxX () :Number {
			return _cssBorderLeft + _cssBorderRight + _cssPaddingLeft + _cssPaddingRight;
		}
		public function get cssBoxY () :Number {
			return _cssBorderTop + _cssBorderBottom + _cssPaddingTop + _cssPaddingBottom;
		}
		
		public function get nodeOpen () :String {
			return (nodeClass ? (' class="'+nodeClass+'"') :  "" ) + (nodeId?(' id="'+nodeId+'"') : "");
		}
		
		public function getUpNodes () :Vector.<CssSprite>
		{
			var rv:Vector.<CssSprite>  =  new Vector.<CssSprite>();
			
			if( _parentNode ) 
			{
				var p:CssSprite = this;
				
				while (p && p is CssSprite) {
					rv.push( p );
					p = p._parentNode;
				}
			}
			
			return rv;
		}
		
		public function buildHtmlText ( text:String, forceBody:Boolean=true) :String {
			var nodes:Vector.<CssSprite> = getUpNodes();
			
			var bOpen:String="";
			var bClose:String="";
			
			for(var i:int = nodes.length-1; i >= 0; i--) {
				bOpen  += '<'  + nodes[i].nodeName + " " + nodes[i].nodeOpen + '>';
				bClose += '</' + nodes[nodes.length-1-i].nodeName + '>';
			}
			if( forceBody ) {
				if( bOpen.indexOf("body") == -1 ) {
					bOpen = "<body>" + bOpen;
					bClose += "</body>";
				}
			}
			
			return bOpen + "<p " + nodeOpen + ">" + text + "</p>" + bClose;
		}
		
		private function pushNodeClasses ( arr:Array, strid:String, pushSingle:Boolean=true ) :void 
		{
			if(nodeClass.indexOf(" ") >= 0) {
				var cls:Array = nodeClass.split(" ");
				for(var i:int=0; i < cls.length; i++) {
					if(pushSingle) arr.push( "." + cls[i] );
					arr.push( strid + "." + cls[i] );
				}
			}else{
				if(pushSingle) arr.push( "." + nodeClass );
				arr.push( strid + "." + nodeClass );
			}
		}
		
		public function init (dontDraw:Boolean=false) :void 
		{
			initialized = false;
			
			// requires a node-name
			if( !nodeName ) 
			{
				nodeName = "div";
			}
			
			// Create style inheritance chain
			var arr:Array = ["body", "*", nodeName];
			var i:int;
			
			if(nodeClass)
			{
				pushNodeClasses( arr, nodeName );
			}
			
			if(nodeId)
			{
				arr.push( "#" + nodeId);
				arr.push( nodeName + "#" + nodeId);
				
				if(nodeClass)
				{
					pushNodeClasses( arr, nodeName + "#" + nodeId, false);
				}
			}
			
			for(i=0; i<contextStyles.length; i++) arr.push(contextStyles[i]);
			
			stylesArray = arr;
			
			if(cssStyleSheet) 
			{
				var sta:Array = cssStyleSheet.getStyleArray(arr);
				cssNormal = sta.length == 0 ? null : sta;
				
				var arrHover:Array = [];
				for(i=0; i< arr.length; i++) arrHover.push( arr[i]+":hover");
				sta = cssStyleSheet.getStyleArray(arrHover);
				cssHover = sta.length == 0 ? null : sta;
				
				var arrPress:Array = [];
				for(i=0; i< arr.length; i++) arrPress.push( arr[i]+":active");
				sta = cssStyleSheet.getStyleArray(arrPress);
				cssActive = sta.length == 0 ? null : sta;

				if(!dontDraw)
				{
					if(cssStates["_"+_state] && _parentNode) {
						applyStyle(cssStates["_"+_state], _parentNode, cssWidth, cssHeight );
					}
				}
			}
		}
		
		public function swapState (state:String="normal") :void {
			_state = state;
			if( cssStates["_"+state] ) {
				applyStyle( cssStates["_"+state], _parentNode, cssWidth, cssHeight );
			}
			dispatchEvent(new CssEvent( CssEvent.STATE_CHANGE ));
		}
		
		protected var _state:String = "normal"; // normal, hover, active
		public function get state () :String { return _state; }
		
		public function get cssNormal () :Array { return this.cssStates._normal || null; }
		public function set cssNormal (c:Array) :void {	cssStates._normal = c;	}
		
		public function get cssHover () :Array { return this.cssStates._hover || null; }
		public function set cssHover (c:Array) :void {
			cssStates._hover = c;
			if(c==null) {
				bgSprite.removeEventListener(MouseEvent.ROLL_OVER, overHandler);
				bgSprite.removeEventListener(MouseEvent.ROLL_OUT, outHandler);
			}else{
				bgSprite.addEventListener(MouseEvent.ROLL_OVER, overHandler);
				bgSprite.addEventListener(MouseEvent.ROLL_OUT, outHandler);
				if(cssStates._normal != null) cssStates._hover = mergeStyles(cssStates._normal, cssStates._hover);
			}
		}
		
		public function onLoaded () :void {
			dispatchEvent( new CssEvent( CssEvent.FILES_LOADED ) );
		}
		public function get cssActive () :Array { return this.cssStates._active || null; }
		public function set cssActive (c:Array) :void {
			cssStates._active = c;
			if(c==null) {
				bgSprite.removeEventListener(MouseEvent.MOUSE_DOWN, downHandler);
			}else{
				bgSprite.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
				if(cssStates._normal != null) cssStates._active = mergeStyles(cssStates._normal, cssStates._active);
			}
		}
		
		private function overHandler (e:MouseEvent) :void {
			if( e.currentTarget != bgSprite ) return;
			if(_state == "hover") return;
			if(!mouseIsDown && autoSwapState == "all" || autoSwapState == "hover") {
				swapState( "hover" );
			}
			focusCtrl = this;
			if(e) e.stopPropagation();
		}
		private function outHandler (e:MouseEvent) :void
		{
			if( e.currentTarget != bgSprite ) return;
			if(_state == "normal") return;
			if(!mouseIsDown && autoSwapState == "all" || autoSwapState == "hover") {
				swapState( "normal" );
			}
			focusCtrl = null;
		}
		
		private function downHandler (e:MouseEvent) :void {
			mouseIsDown = true;
			focusCtrl = this;
			if(stage) stage.addEventListener(MouseEvent.MOUSE_UP, upHandler);
			if(_state == "active") return;
			if(autoSwapState == "all" || autoSwapState == "active") {
				swapState( "active" );
			}
		}
		private function upHandler (e:MouseEvent) :void {
			mouseIsDown = false;
			if(stage) stage.removeEventListener(MouseEvent.MOUSE_UP, upHandler);
			if(parent && autoSwapState == "all" || autoSwapState == "active") {
				swapState( hitTestPoint( parent.mouseX, parent.mouseY, true ) ? "hover" : "normal" );
			}
			focusCtrl = null;
		}
		
		public function set styleSheet (style:CssStyleSheet) :void {
			cssStyleSheet = style;
			init();
		}
		
		public static function mergeStyles (a:Array, b:Array) :Array {
			var rv:Array = [];
			var i:int;
			for(i=0; i<a.length; i++) rv.push( [a[i][0], a[i][1]] );
			for(i=0; i<b.length; i++) rv.push( [b[i][0], b[i][1]] );
			return rv;
		}
		
		public function applyStyle (style:Array, parentCS:CssSprite, w:Number=0, h:Number=0) :void 
		{
			cssWidth = w;
			cssHeight = h;
			styl = style;
			_parentNode = parentCS;
			redrawStyle();
		}
		
		public function redrawStyle() :void
		{
			if(styl && _parentNode) 
			{
				CssRenderer.cssFilePath = cssStyleSheet.cssFilePath;
				_cssSizeX = _cssSizeY = 0;
				CssRenderer.drawBox( styl, this, _parentNode, cssWidth, cssHeight, ignoreSize );
			}
		}
		
	}
}