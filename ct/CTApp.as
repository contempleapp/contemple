package ct
{
	import flash.events.Event;
	import flash.display.*;
	import flash.events.Event;
	import flash.utils.setTimeout;
	import fl.transitions.easing.Regular;
	import fl.transitions.easing.Strong;
	import agf.Main;
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
			
			// load the logo first:
			setTimeout(showLogo, 0);
		}
		
		function showLogo ():void {
			ResourceMgr.getInstance().loadResource( CTOptions.appLogo, logoLoaded, false );
		}
		
		private function logoLoaded (r:Resource) :void
		{
			anim = new Animation();
			anim.loop = false;
			addChild( anim );
			
			if( r.loaded == 1 ) {
				appLogo = DisplayObject(r.obj);
				var xpos:Number = int(stage.stageWidth/2 - appLogo.width/2);
				var ypos:Number = int(stage.stageHeight/2 - appLogo.height/2);
				appLogo.y = ypos - 16;
				appLogo.x = xpos - 16;
				appLogo.scaleX = 1.5;
				appLogo.scaleY = 1.5;
				appLogo.alpha = 0;
				
				anim.loop = false;
				anim.addEventListener( Event.COMPLETE, animDone );
				anim.run( appLogo, { y:ypos, x:xpos, scaleX:1, scaleY:1, alpha:0.5 }, 777, Strong.easeOut );
				
				addChild( appLogo );
				
			}else{
				Console.log("Error loading the app logo: " + CTOptions.appLogo );
				createApp();
			}
		}
		
		private function animDone (e:Event = null) :void {
			setTimeout( createApp, 777 );
			anim.removeEventListener( Event.COMPLETE, animDone );
		}
		
		private function createApp () :void
		{
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
				appLogo.scaleX = appLogo.scaleY = 0.75;
			}
		}
		
		private function fadeAppIn (e:Event = null) :void {
			if( appLogo ) {
				appLogo.alpha = 0.02;
				appLogo.scaleX = appLogo.scaleY = 0.5;
			}
			if( anim ) {
				anim.addEventListener( Event.COMPLETE, fadedIn );
				anim.run( app, { alpha:1 }, 1789, Strong.easeOut );
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
