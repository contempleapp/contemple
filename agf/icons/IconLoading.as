package agf.icons
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	public class IconLoading extends Sprite
	{
		public function IconLoading (col:Number=0, alpha:Number=1, w:Number=12, h:Number=12)
		{
			__color = col;
			__alpha = alpha;
			__w = w;
			__h = h;
			draw2(col, alpha, w, h);
			addEventListener( Event.ENTER_FRAME, frameHandler);
		}
		private var redrawFrames:int = 3;
		private var redrawTime:int = 1250;
		private var lastDrawTime:int = 0;
		private var __color:int = 8;
		private var __alpha:Number = 8;
		private var __w:int = 8;
		private var __h:int = 8;
		private var currFrame:int=0;
		private var currSate:int=0;
		
		private function frameHandler (e:Event):void {
			currFrame++;
			if( currFrame > redrawFrames ) {
				var t:int = flash.utils.getTimer();
				if( t-lastDrawTime > redrawTime ) {
					lastDrawTime = t;
					if( currSate == 0 ) {
						draw2( __color, __alpha, __w, __h);
					}else if(currSate == 1) {
						draw1( __color, __alpha, __w, __h);
					}else if(currSate == 2 ){
						draw( __color, __alpha, __w, __h);
					}
					currSate++;
					if( currSate > 2 ) currSate = 0;
				}
				currFrame = 0;
			}
		}
		private function draw( col:Number=0, alpha:Number=1, w:Number=15, h:Number=15) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			//graphics.drawRect(0,0,w, h/4);
			/*graphics.moveTo( 0,0 );
			graphics.lineTo( w*0.75,0 );
			graphics.lineTo( w, h/4 );
			graphics.lineTo( 0, h/4 );
			graphics.endFill();*/
			/*
			graphics.beginFill(col, alpha);
			graphics.drawRect(0,h/3,w, h/4);
			graphics.drawRect(0,h/1.5,w, h/4);*/
			graphics.drawRect(0,0,w, h/4)
			graphics.endFill();
		}
		private function draw1( col:Number=0, alpha:Number=1, w:Number=15, h:Number=15) :void {
			graphics.clear();
			//graphics.beginFill(col, alpha);
			//graphics.drawRect(0,0,w, h/4);
			/*graphics.moveTo( 0,0 );
			graphics.lineTo( w*0.75,0 );
			graphics.lineTo( w, h/4 );
			graphics.lineTo( 0, h/4 );
			graphics.endFill();*/
			graphics.beginFill(col, alpha);
			graphics.drawRect(0,0,w, h/4);
			graphics.drawRect(0,h/3,w, h/4);
			//graphics.drawRect(0,h/1.5,w, h/4);
			graphics.endFill();
		}
		private function draw2( col:Number=0, alpha:Number=1, w:Number=15, h:Number=15) :void {
			graphics.clear();
			graphics.beginFill(col, alpha);
			graphics.drawRect(0,0,w, h/4);
			graphics.drawRect(0,h/3,w, h/4);
			graphics.drawRect(0,h/1.5,w, h/4);
			graphics.endFill();
		}
		
	}
}