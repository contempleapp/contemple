package agf.ui
{
	import flash.events.*;
	import agf.html.*;
	import agf.utils.ColorUtils;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	public class ColorPicker extends CssSprite 
	{
		public function ColorPicker( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', noInit:Boolean=false) {
			super(w, h, parentCS, style, "colorpicker", cssId, cssClasses, false);
			create(w, h);
		}
		
		public static var knownColors:Array = [ 0x020202, 0xFFFFFF ];
		
		// add color to known colors box..
		public static function testColor (c:int):void {
			if( knownColors.indexOf( c ) == -1 ) {
				knownColors.push( c );
			}
		}
		
		private var _color:uint=0; // current color
		private var _multiplier:Number=1;
		//private var mulR:Number = 1;
		//private var mulG:Number = 1;
		//private var mulB:Number = 1;
		
		//private var lightness:Number = 1; // 0-20
		
		public var target:Object;
		public var targetName:String="colorValue";
		
		private var img1:ColorSelectImage;
		private var img2:ColorSelectImage;
		private var sb:Slider;
		
		// known colors box
		private var kcbox:ScrollContainer;
		private var kcbmp:Bitmap;
		public static var kcsize:int = 32;
		
		private var label:Label;
		private var colorText:TextField;
		private var setButton:Button;
		private var cancelButton:Button;
		private var colorPreview:Sprite;
		private var colorPreviewWidth:int=40;
		
		public function get color () :uint {
			/*
			var col:Object = {};
			ColorUtils.getRGBAComponents( _color, col );
			if( multiplier != 1 ) {
				if( col.r <= 1 ) col.r = 1;
				if( col.g <= 1 ) col.g = 1;
				if( col.b <= 1 ) col.b = 1;
				
				if( col.r <= 127 ) mulR = (127/col.r)*(_multiplier-1);
				else mulR = 1;
				if( col.g <= 127 ) mulG = 127/col.g*(_multiplier-1);
				else mulG = 1;
				if( col.b <= 127 ) mulB = 127/col.b*(_multiplier-1);
				else mulB = 1;	
				
				if( mulR < 1 ) mulR = 1;
				if( mulG < 1 ) mulG = 1;
				if( mulB < 1 ) mulB = 1;
			}
			return ColorUtils.combineRGB( col.r * (_multiplier*mulR), col.g * (_multiplier*mulG), col.b * (_multiplier*mulB) ); 
			*/
			if ( _multiplier != 1 ) {
				var lght:Number = multiplier < 1 ? multiplier : Math.pow( multiplier, 8 );
				var col:Object = {};
				ColorUtils.getRGBAComponents( _color, col );
				return ColorUtils.lightness( col, lght );
			}else{
				return _color; 
			}
		}
		public function set color (v:uint) :void {
			_color = v;
			if( colorPreview ) drawColor();
			updateColorText();
		}
		public function get multiplier () :Number { return _multiplier; }
		public function set multiplier (v:Number) :void {
			_multiplier = v;
			if( colorPreview ) drawColor();
			updateColorText();
		}
		
		private function updateColorText () :void {
			var col:Object = {};
			ColorUtils.getRGBAComponents( color, col );
			
			var hexCol:String = "#";
			if( col.r < 16 ) hexCol += "0";
			hexCol += col.r.toString(16);
			if( col.g < 16 ) hexCol += "0";
			hexCol += col.g.toString(16);
			if( col.b < 16 ) hexCol += "0";
			hexCol += col.b.toString(16);
			
			colorText.text = hexCol;
		}
		private function updateColor (px:uint) :void {
			_multiplier = 1;
			//mulR = 1;
			//mulG = 1;
			//mulB = 1;
			// lightness = 1;
			sb.value = 100;
			
			color = px;
			//_color = px;
			
		}
		public function setLabel (s:String) :void {
			if( label ) {
				label.label = s;
			}
		}
		public function create (w:int, h:int) :void
		{
			if(img1 && contains(img1)) removeChild(img1);
			if(img2 && contains(img2)) removeChild(img2);
			if(kcbox && kcbmp && kcbox.contains(kcbmp) ) kcbox.removeChild(kcbmp);
			if(kcbox && contains(kcbox)) removeChild(kcbox);
			if(label && contains(label)) removeChild( label );
			
			if(colorText && contains(colorText)) removeChild( colorText );
			if(setButton && contains(setButton)) removeChild( setButton );
			if(cancelButton && contains(cancelButton)) removeChild( cancelButton );
			if(colorPreview && contains(colorPreview)) removeChild( colorPreview );
			if(sb && contains(sb)) removeChild(sb);
			
			sb = new Slider(0, w, this, styleSheet, '', 'color-picker-slider', false);
			var ltlw:int = w/2;
			
			label = new Label(0,0,this,styleSheet,'','color-picker-label',false);
			label.label = Language.getKeyword( "Select Color" );
			
			setButton = new Button( [Language.getKeyword( "Set Color" )], 0, 0, this, styleSheet, '', 'color-picker-set-button',false);
			cancelButton = new Button( [Language.getKeyword( "Cancel Color" )], 0, 0, this, styleSheet, '', 'color-picker-cancel-button',false);
			
			colorText = new TextField();
			var fmt:TextFormat = styleSheet.getTextFormat( stylesArray );
			colorText.defaultTextFormat = fmt;
			
			var previewWidth:int = cancelButton.cssSizeY + setButton.cssSizeY + setButton.cssMarginBottom + cancelButton.cssMarginBottom;
			colorPreviewWidth = previewWidth;
			
			colorPreview = new Sprite();
			addChild( colorPreview );
			addChild( colorText );
			
			ltlw -= int(previewWidth/2);
			
			setButton.setWidth( ltlw - (setButton.cssBoxX + setButton.cssMarginX) );
			cancelButton.setWidth( ltlw - (cancelButton.cssBoxX + cancelButton.cssMarginX) );
			colorText.width = ltlw - 8;
			colorText.x = 4;
			
			setButton.addEventListener( MouseEvent.CLICK, setColorHandler );
			cancelButton.addEventListener( MouseEvent.CLICK, cancelColorHandler );
			
			colorPreview.x = ltlw;
			setButton.x = ltlw + colorPreviewWidth + setButton.cssMarginLeft;
			cancelButton.x = ltlw + colorPreviewWidth + cancelButton.cssMarginLeft;
			
			var muih:Number = Math.max( colorText.height, setButton.cssSizeY, colorPreviewWidth );
			var uih:int = muih;
			
			colorPreview.y =
			colorText.y = 
			setButton.y = (h-label.getHeight()) - colorPreviewWidth;
			cancelButton.y = setButton.y + setButton.cssSizeY + setButton.cssMarginBottom;
			
			h = h - uih;
			
			var imgw:Number = w - (cssBoxX);
			var imgh:int = Math.round((h-30)/1.618);
			
			label.y = cssTop;
			
			img1 = new ColorSelectImage( "rgb", imgw, imgh, true, 0x00000000 );
			img1.x = cssLeft;
			img1.y = cssTop + label.getHeight();
			addChild( img1 );
			
			var h4:int = int( (h-imgh) / 3.2 );
			img2 = new ColorSelectImage( "kelvin", imgw, h4, true, 0x00000000 );
			img2.x = cssLeft;
			img2.y = imgh + img1.y;
			addChild( img2 );
			
			sb.setScrollerHeight( int( h/4) );
			sb.setHeight( imgw );
			sb.rotation = -90;
			
			sb.x = cssLeft;
			sb.y = img2.y+img2.height + 16;
			sb.minValue = 0;
			sb.maxValue = 200;
			sb.value = 100;
			
			sb.addEventListener( Event.CHANGE, scrollbarChange);
			
			kcbox = new ScrollContainer(0,0,this,styleSheet,'','colorpicker-known-colors',false);
			
			var cols:Number = Math.floor( imgw / kcsize );
			var kch:Number = kcsize;
			var L:int = knownColors.length;
			if( L > cols ) {
				kch = Math.ceil( (L / cols ) * kcsize );
			}
			
			var bmd:BitmapData = new BitmapData( imgw, kch, true, 0x00000000);
			kcbmp = new Bitmap( bmd );
			kcbmp.name = "bmp";
			kcbox.content.addChild( kcbmp );
			
			var col:int=0;
			var rc:Rectangle = new Rectangle(0,0,kcsize,kcsize);
			
			for(  var i:int=0; i<L; i++) {
				if( col > cols ) {
					col = 0;
					rc.x = 0;
					rc.y += kcsize;
				}
				
				bmd.fillRect( rc, 0xFF << 24 | knownColors[i] );
				rc.x += kcsize;
				col  ++;
			}
			
			kcbox.x = cssLeft;
			kcbox.y = sb.y + sb.cssSizeX; // rotation flipped x/y
			kcbox.setHeight( setButton.y - kcbox.y );
			kcbox.setWidth( imgw );
			kcbox.contentHeightChange();
			
			setChildIndex( sb, numChildren-1);
			
			var overlay:ColorSelectImage = new ColorSelectImage( "overlay", imgw, imgh, true, 0x00000000, { center: 0.45, maxValue:.999} );

			img1.bitmap.bitmapData.draw( overlay );
			
			img1.addEventListener( MouseEvent.MOUSE_DOWN, click );
			img2.addEventListener( MouseEvent.MOUSE_DOWN, click );
			kcbox.content.addEventListener( MouseEvent.MOUSE_DOWN, click );
			
			color = _color;
		}
		
		private function drawColor() :void {
			colorPreview.graphics.beginFill( color, 1 );
			colorPreview.graphics.drawRect(0, 0, colorPreviewWidth, colorPreviewWidth);
			colorPreview.graphics.endFill();
		}
		private var currEditImg:Bitmap=null;
		
		private function mouse_move (e:MouseEvent) :void  {
			if( currEditImg ) {
				var px:uint =  currEditImg.bitmapData.getPixel32( currEditImg.parent.mouseX, currEditImg.parent.mouseY );
				updateColor(px);
			}else{
				mouse_up(null);
			}
		}
		private function mouse_up (e:MouseEvent) :void {
			if( currEditImg ) {
				var px:int =  currEditImg.bitmapData.getPixel32( currEditImg.parent.mouseX, currEditImg.parent.mouseY );
				updateColor(px);
			}
			currEditImg = null;
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, mouse_move );
			stage.removeEventListener( MouseEvent.MOUSE_UP, mouse_up );
		}
		private function click (e:MouseEvent) :void
		{
			if( e.target is ColorSelectImage ) {
				currEditImg = Bitmap(  e.target.bitmap );
			}else{
				currEditImg = Bitmap(  e.target.getChildByName("bmp") );
			}
			var px:int =  currEditImg.bitmapData.getPixel32( currEditImg.parent.mouseX, currEditImg.parent.mouseY );
			updateColor(px);
			
			if( stage ) {
				stage.addEventListener( MouseEvent.MOUSE_MOVE, mouse_move );
				stage.addEventListener( MouseEvent.MOUSE_UP, mouse_up );
			}
		}
		
		public function scrollbarChange (e:Event) :void {
			multiplier = sb.value/100;
		}
		private function setColorHandler (e:MouseEvent) :void {
			updateRequester();
			testColor( color );
			if(parent && parent.contains(this)) parent.removeChild(this);
		}
		private function cancelColorHandler (e:MouseEvent) :void {
			if(parent && parent.contains(this)) parent.removeChild(this);
		}
		private function updateRequester ():void {
			if( target && target[targetName] != null ) {
				if( typeof target[targetName] == "function") {
					target[targetName]( color );
				}else{
					target[targetName] = color;
				}
			}
		}

	}
	
}
