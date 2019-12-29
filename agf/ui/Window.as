package agf.ui
{
	import agf.animation.Animation;
	import agf.events.AppEvent;
	import flash.display.*;
	import flash.events.*;
	import fl.transitions.easing.Regular;
	
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.icons.IconAppLogo;
	import agf.tools.Application;
	import agf.html.CssUtils;
	
	public class Window extends CssSprite
	{
		public function Window( nameUid:String, titleText:String, w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, cssId:String='', cssClasses:String='', titleClass:String="", closeButtonClass:String="", backgroundClass:String="") {
			super(w, h, parentCS, style, "window", cssId, "window " + cssClasses, true);
			createWindow( nameUid, titleText, titleClass, closeButtonClass, backgroundClass );
		}
		
		public var autoIconColor:Boolean=true;
		public var iconColor:uint=0;
		public var body:CssSprite;
		public var bg:CssSprite;
		public var title:CssSprite;
		public var titleText:String;
		public var titleLabel:Label;
		public var closeButton:Button;
		
		private var dragStartX:Number;
		private var dragStartY:Number;
		
		public function close () :void
		{
			if( options && options.anim != undefined && options.anim is Animation ) 
			{
				var anim:Animation = options.anim;
				
				var s:Number = 0.84;
				var d:Number = 387;
				var e:Function = Regular.easeOut;
				var t:String = "pop"; // wipe-top, wipe-left.., fade
				
				if( options ) {
					if( options.animScale != undefined ) s = Number( options.animScale ); 
					if( options.animDuration != undefined ) d = Number( options.animDuration ); 
					if( options.animEaseFunc != undefined ) e = options.animEaseFunc;
					if( options.animType != undefined ) t = options.animType;
				}
				
				if( t == "pop" ) {
					var mainMenuHeight:Number = Application.instance.mainMenu.cssSizeY;
					var w:int = width;
					var h:int = height;
					
					var toX:Number = x + (w - w * s) / 2;
					var toY:Number = y + (h - h * s) / 2;
					anim.addEventListener( Event.COMPLETE, fadedOut );
					anim.run( this, { x:toX, y:toY, scaleX:s, scaleY:s, alpha:0 }, d * 0.62, e );
					
				}
			}
			else
			{
				onClose();
			}
		}
		
		private function fadedOut (e:Event) :void {
			if( options && options.anim != undefined && options.anim is Animation ) 
			{
				var anim:Animation = options.anim;
				options.anim.removeEventListener( Event.COMPLETE, fadedOut );
				if( contains( anim ) ) removeChild( anim );
				anim = null;
			}
			onClose();
		}
		
		private function onClose () :void 
		{
			dispatchEvent(new Event("close"));
			if( parent && parent.contains( this ) ) parent.removeChild(this);
			clearWindowCtrls ();
		}
		
		// KEYBOARD LISTENER
		private var _enterListener:Function = null;
		public function enterListener ( handler:Function ) :void {
			if( _enterListener != null ) {
				if( stage ) {
					stage.removeEventListener( KeyboardEvent.KEY_UP, _enterListener )
				}
				_enterListener = null;
			}
			
			_enterListener = handler;
			
			if( handler != null && stage ) {
				stage.addEventListener( KeyboardEvent.KEY_UP, _enterListener);
			}
		}
		
		public function clearWindowCtrls () :void {
			if( bg ) {
				if( body.contains( bg ) ) body.removeChild( bg );
				bg = null;
			}
			if( title ) {
				if( body.contains( title ) ) body.removeChild( title );
				title = null;
			}
			if( titleLabel ) {
				if( body.contains( titleLabel ) ) body.removeChild( titleLabel );
				titleLabel = null;
			}
			if( closeButton ) {
				if( body.contains( closeButton ) ) body.removeChild( closeButton );
				closeButton = null;
			}
			if( body ) {
				if( contains( body ) ) removeChild( body );
				body = null;
			}
			if( stage ) {
				if( _enterListener != null ) {
					stage.removeEventListener( KeyboardEvent.KEY_UP, _enterListener );
				}
			}
		}
		
		public override function setWidth (w:int) :void {
			super.setWidth( w );
			bg.setWidth( w );
			title.setWidth( Math.floor( w - title.cssBoxX )  );
			closeButton.x = Math.ceil( (title.x + title.width) - closeButton.width );
		}
		public override function setHeight (h:int) :void {
			super.setHeight( h );
			bg.setHeight( h );
			
		}
		public function createWindow ( nameUid:String, titleText:String, titleClass:String='', closeButtonClass:String='', backgroundClass:String='' ) :void
		{
			clearWindowCtrls();
			
			name = nameUid;
			
			var w = this.getWidth();
			var h = this.getHeight();
			var title_height:Number = 18;
			
			body = new CssSprite( w, h, this, this.styleSheet, "body", '', '');
			bg = new CssSprite( w, h, body, this.styleSheet, nameUid + "-background", '', 'window-background ' + backgroundClass, false);
		
			titleLabel = new Label(100, 20, body, this.styleSheet, '', "window-title-text", false);
			titleLabel.textField.htmlText = titleLabel.buildHtmlText( titleText );
			
			title_height = titleLabel.height;
			
			if( autoIconColor ){
				var cs:Object = styleSheet.getMultiStyle( titleLabel.stylesArray );
				iconColor = CssUtils.stringToColor( cs.color );
			}
			
			closeButton = new Button( [new agf.icons.IconWindowClose(iconColor)], 0, title_height, body, this.styleSheet, '', "window-closebutton " + closeButtonClass, false);
			title = new CssSprite( 0, title_height, body, this.styleSheet, nameUid + "-title", '', "window-title " + titleClass, false);
			title.setWidth( bg.cssRight - bg.cssLeft );
			closeButton.x = (title.x + title.width) - closeButton.width;
			closeButton.y = cssTop + bg.cssTop;
			
			title.x = bg.cssLeft;
			title.y = bg.cssTop;
			titleLabel.x = title.cssLeft + title.x + 2;
			titleLabel.y = title.cssTop + title.y;
			
			titleLabel.mouseEnabled = false;
			titleLabel.mouseChildren = false;
			title.addEventListener( MouseEvent.MOUSE_DOWN, onStartDrag );
			closeButton.addEventListener( MouseEvent.CLICK, closeHandler);
			
			body.setChildIndex( closeButton, body.numChildren-1);
			body.setChildIndex( titleLabel, body.numChildren-2);
		}
		
		private function closeHandler (e:Event) :void {
			close();
		}
		
		protected function onStartDrag (e:MouseEvent) :void {
			dragStartX = mouseX;
			dragStartY = mouseY;
			parent.setChildIndex( this, parent.numChildren-1 );
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onDrag );
			stage.addEventListener( MouseEvent.MOUSE_UP, onStopDrag );
		}
		
		protected function onDrag (e:MouseEvent) :void {
			x = stage.mouseX - this.dragStartX;
			y = stage.mouseY - this.dragStartY;
		}
		
		protected function onStopDrag (e:MouseEvent) :void {
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onDrag );
			stage.removeEventListener( MouseEvent.MOUSE_UP, onStopDrag );
		}
	}
}