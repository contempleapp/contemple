﻿package agf.ui.ctrl
				/*if( UiCtrl.roundRect ) {
					trace("ROUND POUP LIST... ");
					UiCtrl.drawRoundRect( bg_mc, 0,0,100,100, UiCtrl.roundTopLeft, UiCtrl.roundTopRight, UiCtrl.roundBottomLeft, UiCtrl.roundBottomRight);
				}else{*/
				//}
				if( UiCtrl.roundRect ) 
				{
					var rx:Number = Math.max( UiCtrl.roundTopLeft, UiCtrl.roundBottomLeft);
					var ry:Number = Math.max( UiCtrl.roundTopLeft, UiCtrl.roundTopRight);
					
					trace("RXY: " + rx + ", " + ry);
					
					gr = new Rectangle(rx, ry, 100-rx*2, 100-ry*2);
					
				}else{
				}