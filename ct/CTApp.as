package ct
{
	import flash.display.*;
	import flash.events.*;
	import flash.utils.setTimeout;
	import fl.transitions.easing.Regular;
	import fl.transitions.easing.Strong;
	import flash.events.InvokeEvent; 
    import flash.desktop.NativeApplication; 
	import agf.Main;
	import agf.html.CssUtils;
	import agf.animation.Animation;
	import agf.io.*;
	import agf.events.AppEvent;
	import agf.icons.IconFromFile;
	import agf.tools.Application;
	import agf.tools.Console;
	
	public class CTApp extends MovieClip 
	{
		public function CTApp () 
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			Main.prepare( this, true );
			CTMain.setupConfigFiles();
			
			try
			{
				NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
			}
			catch( e:Error )
			{
				// load the logo first:
				Console.log("Invoke Error");
				setTimeout(showLogo, 125);
			}
		}
		
		private static var invoked:Boolean = false;
		public function onInvoke (invokeEvent:InvokeEvent):void 
        { 
			if( invoked ) return;
			invoked = true;
			
            if(invokeEvent.arguments.length > 0) 
            {
				Console.log("Command Line Arguments called: " + invokeEvent.arguments.toString() );
				Console.show( this );
				
				if( Console._consoleLabel && Console._consoleLabel.textField ) {
					Console._consoleLabel.textField.addEventListener( MouseEvent.CLICK, clickToStart );
				}
				
				var cmds:String = invokeEvent.arguments.toString();
				
				if( cmds == "clear-project-reference" ) {
					Console.log( "Clearing Project References..." );
					try {
						CTTools.clearPrjRef();
						Console.log( "References Cleared");
					}catch(e:Error) {
						Console.log( "Error Clearing Project References: " + e);
					}
				}
				Console.log( "Click To Start...");
            }  
            else
            { 
				setTimeout(showLogo, 222);
            }
        } 
		
		public function clickToStart (e:MouseEvent):void {
			if( Console._consoleLabel && Console._consoleLabel.textField ) {
				Console._consoleLabel.textField.removeEventListener( MouseEvent.CLICK, clickToStart );
			}
			setTimeout(showLogo, 345);
			
			Console.hide();
		}
		
		public function showLogo ():void {
			ResourceMgr.getInstance().loadResource( CTOptions.appLogo, logoLoaded, false );
		}
		
		private function logoLoaded (r:Resource) :void
		{
			anim = new Animation();
			addChild( anim );
			
			if( r.loaded == 1 )
			{
				appLogo = DisplayObject(r.obj);
				var xpos:Number = int(stage.stageWidth/2 - appLogo.width/4);
				var ypos:Number = int(stage.stageHeight/2 - appLogo.height/4);
				
				appLogo.x = int( Math.random() * stage.stageWidth+appLogo.width*2 ) - appLogo.width;
				appLogo.y = int( Math.random() * stage.stageHeight+appLogo.height*2 ) - appLogo.height;
				
				appLogo.scaleX = 1.5;
				appLogo.scaleY = 1.5;
				appLogo.scaleX *=  CssUtils.numericScale;
				appLogo.scaleY *=  CssUtils.numericScale;
				
				appLogo.alpha = 0;
				addChild( appLogo );
				
				anim.addEventListener( Event.COMPLETE, animDone );
				anim.run( appLogo, { y:ypos, x:xpos, scaleX:0.5, scaleY:0.5, alpha:0.125 }, 1570, Strong.easeOut );
			}
			else
			{
				Console.log("Error loading the app logo: " + CTOptions.appLogo );
				createApp();
			}
		}
		
		private function animDone (e:Event = null) :void {
			setTimeout( createApp, 777 );
			anim.removeEventListener( Event.COMPLETE, animDone );
		}
		
		private function createApp () :void {
			// create the application:
			addChild( 
				app = CTMain( Application.init(new CTMain(stage.stageWidth, stage.stageHeight)) )
			);
			
			app.alpha = 0;
			app.setupApp();
			app.addEventListener( AppEvent.START, appStart );
			stage.addEventListener(Event.RESIZE, stageResize);
		}
		
		private function appStart (e:Event = null) :void {
			setTimeout( fadeAppIn, 345 );
			if( appLogo ) {
				appLogo.alpha = 0.04;
				appLogo.scaleX = appLogo.scaleY = 0.4;
			}
		}
		
		private function fadeAppIn (e:Event = null) :void {
			if( appLogo ) {
				appLogo.alpha = 0.02;
				appLogo.scaleX = appLogo.scaleY = 0.25;
			}
			if( anim ) {
				anim.addEventListener( Event.COMPLETE, fadedIn );
				anim.run( app, { alpha:1 }, 1357, Strong.easeOut );
			}else{
				fadedIn();
			}
		}
		
		private function fadedIn (e:Event=null) :void {
			app.alpha = app.scaleX = app.scaleY = 1;
			removeLogo();
			if( anim ) {
				anim.removeEventListener( Event.COMPLETE, fadedIn );
				if( contains( anim ) ) removeChild( anim );
				anim = null;
			}
		}
		
		private function stageResize (e:Event) :void {
			if(app) {
				var st:Stage = Stage(e.target);
				app.setSize( st.stageWidth, st.stageHeight );
			}
			if( appLogo ) {
				appLogo.x = int(stage.stageWidth/2 - appLogo.width/2);
				appLogo.y = int(stage.stageHeight/2 - appLogo.height/2);
				addChild( appLogo );
			}
		}
		
		private function removeLogo (e:Event = null) :void
		{
			if( appLogo && contains( appLogo )) removeChild( appLogo );
			appLogo = null;
		}
		
		public var app:CTMain;
		private var appLogo:DisplayObject;
		private var anim:Animation;
	}
}
