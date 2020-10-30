﻿package ct
	import agf.io.*;
	import agf.events.AppEvent;
	
			// Font only on macOS 
			Console.DEFAULT_FONT = "Lucida Console";
			
			CTOptions.verboseMode = false;
			
			CTOptions.version = "1.9.0";
			CTOptions.appConfigDir = "ctres-hm";
			CTOptions.clientHost = "http://www.herbert-mayer.com/";
			CTOptions.projectName = "the Herbert Mayer Website";
			CTOptions.startConfig = "ct-config-user-mobile.css"; //"ctres-hm/ct-config-user.css";
			CTOptions.installTemplate = "app:/template-hm-02";
			
			CTOptions.dbInitFileName = "db-index.xml"; //"app:/ctres-hm/db-index.xml";
			
			CTOptions.hashCompareAlgorithm = "md5";
			
			CTOptions.localSharedObjectId = "at.contemple.hm.K";
			CTOptions.installSharedObjectId = "at.contemple.hm.K";
			CTOptions.homeAreaName = "PAINTING";
			
			CTOptions.uploadViewShowFileInfo = false;
			CTOptions.reverseAreasPopup = false;
			CTOptions.rememberArea = true;
			
			CTOptions.localUploadFolder = "min";
			CTOptions.uploadMethod = "php";
			
			CTOptions.uploadScript = "http://www.herbert-mayer.com/cthub/cthub-hm.php";
			//CTOptions.uploadScript = "http://localhost:8888/cthub/cthub-hm.php";
			CTOptions.updateUrl = "http://www.herbert-mayer.com/cthub/cthub-app-update-hm.xml";
			CTOptions.overrideInstallDB = "app:/ctres-hm/local.db";
			
			
			CTOptions.animateBackground = true;
			CTOptions.animateBackgroundMin = 0.3;
			CTOptions.animateBackgroundMax = 1;
			/*
			CTMain.setupConfigFiles();
			
			// don't modify the following code..
			
			Main.prepare( this, false );
			CTMain.setupConfigFiles();
			
			// load the logo first...
			ResourceMgr.getInstance().loadResource( CTOptions.appLogo, logoLoaded, false );
		}
		
		private function logoLoaded( r:Resource ):void 
		{
			// Create the Application:
			addChild( 
				app = CTMain( Application.init(new CTMain(stage.stageWidth, stage.stageHeight)) )
			);
			
			app.setupApp();
			app.addEventListener( AppEvent.START, removeLogo );
			stage.addEventListener(Event.RESIZE, stageResize);
			
			if( r.loaded == 1 ) {
				appLogo = DisplayObject(r.obj);
				
				appLogo.x = int(stage.stageWidth/2 - appLogo.width/2);
				appLogo.y = int(stage.stageHeight/2 - appLogo.height/2);
				appLogo.alpha = 1;
				addChild( appLogo );
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
			if( appLogo && contains( appLogo )) removeChild( appLogo );
			appLogo = null;
			app.removeEventListener( AppEvent.START, removeLogo );
		}
		private var appLogo:DisplayObject;