package agf.html
{
	public dynamic class CssObject
	{
		public var overflow:String;
		
		public var opacity:Number;
		
		public var minWidth:Number;
		public var maxWidth:Number;
		public var minHeight:Number;
		public var maxHeight:Number;
		
		public var textAlign:String="left";
		public var verticalAlign:String="middle";
		public var color:uint=0x0;
		
		public var backgroundAlpha:Number;
		public var backgroundColor:uint;
		public var backgroundRepeat:String;
		public var backgroundSize:String;
		public var backgroundImage:Boolean;
		public var bgImagePath:String;
		public var bgImagePositionX:String;
		public var bgImagePositionY:String;
		
		public var paddingTop:Number;	
		public var paddingBottom:Number; 
		public var paddingLeft:Number; 
		public var paddingRight:Number;
		
		public var marginTop:Number;	
		public var marginBottom:Number; 
		public var marginLeft:Number; 
		public var marginRight:Number;
		
		public var width:Number; 
		public var height:Number;
		
		public var bgSolid:Boolean;
		public var bgGradient:Boolean;
		
		public var borderTopWidth:Number;
		public var borderBottomWidth:Number;
		public var borderLeftWidth:Number;
		public var borderRightWidth:Number;
		
		public var borderTopColor:uint;	
		public var borderBottomColor:uint;	
		public var borderLeftColor:uint;	
		public var borderRightColor:uint;
		
		public var borderTopLeftRadius:Number;	
		public var borderTopRightRadius:Number;
		public var borderBottomLeftRadius:Number;	
		public var borderBottomRightRadius:Number;
		
		public var borderTopAlpha:Number;	
		public var borderBottomAlpha:Number;	
		public var borderLeftAlpha:Number;	
		public var borderRightAlpha:Number;
		
		public function makeDefaults () :void 
		{
			overflow = "visible";
			opacity = 1;
			
			minWidth = 0;
			maxWidth = 0;
			minHeight = 0;
			maxHeight = 0;
			
			textAlign = "left";
			verticalAlign = "middle";
			
			color = 0x0;
			
			bgSolid = false;
			bgGradient = false;
			backgroundAlpha = 1;
			backgroundColor = 0xFFFFFF;
			
			backgroundImage = false;
			bgImagePath = "";
			backgroundRepeat = "no-repeat";
			backgroundSize = "contain";
			bgImagePositionX = "left";
			bgImagePositionY = "top";
			
			borderTopWidth = borderBottomWidth = borderLeftWidth = borderRightWidth = 0;
			borderTopColor = borderBottomColor = borderLeftColor = borderRightColor = 0;
			borderTopAlpha = borderBottomAlpha = borderLeftAlpha = borderRightAlpha = 1;
			borderTopLeftRadius = borderTopRightRadius = borderBottomLeftRadius = borderBottomRightRadius = 0;
			
			paddingTop = paddingBottom = paddingLeft = paddingRight = 0;
			marginTop = marginBottom = marginLeft = marginRight = 0;
			
			width = height = 0;
		}
		
		public function clone () :CssObject 
		{
			var r:CssObject = new CssObject();
			
			r.overflow = overflow;
			
			r.opacity = opacity;
			
			r.minWidth = minWidth;
			r.maxWidth = maxWidth;
			r.minHeight = minHeight;
			r.maxHeight = maxHeight;
			
			r.textAlign = textAlign;
			r.verticalAlign = verticalAlign;
			
			r.color = color;
			
			r.bgSolid = bgSolid;
			r.bgGradient = bgGradient;
			r.backgroundAlpha = backgroundAlpha;
			r.backgroundColor = backgroundColor;
			
			r.backgroundImage = backgroundImage;
			r.bgImagePath = bgImagePath;
			r.backgroundRepeat = backgroundRepeat;
			r.backgroundSize = backgroundSize;
			r.bgImagePositionX = bgImagePositionX;
			r.bgImagePositionY = bgImagePositionY;
			
			r.paddingTop = paddingTop;
			r.paddingBottom = paddingBottom;
			r.paddingLeft = paddingLeft;
			r.paddingRight = paddingRight;
			
			r.marginTop = marginTop;
			r.marginBottom = marginBottom;
			r.marginLeft = marginLeft;
			r.marginRight = marginRight;
			
			r.borderTopWidth = borderTopWidth;
			r.borderBottomWidth = borderBottomWidth;
			r.borderLeftWidth = borderLeftWidth;
			r.borderRightWidth = borderRightWidth;
			r.borderTopColor = borderTopColor;
			r.borderBottomColor = borderBottomColor;
			r.borderLeftColor = borderLeftColor;
			r.borderRightColor = borderRightColor;
			r.borderTopAlpha = borderTopAlpha;
			r.borderBottomAlpha = borderBottomAlpha;
			r.borderLeftAlpha = borderLeftAlpha;
			r.borderRightAlpha = borderRightAlpha;
			r.borderTopLeftRadius = borderTopLeftRadius;
			r.borderTopRightRadius = borderTopRightRadius;
			r.borderBottomLeftRadius = borderBottomLeftRadius;
			r.borderBottomRightRadius = borderBottomRightRadius;
			r.width = width;
			r.height = height;
			return r;
		}
		
	}
}