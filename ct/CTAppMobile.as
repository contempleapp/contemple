﻿package ct
{
	import agf.Options;
	
	public class CTAppMobile extends CTApp 
	{
		public function CTAppMobile () 
		{	
			super();
			
			// Set default config options
			
			Options.iconDir = "ico24";
			Options.iconSize = 24;
			Options.btnSize = 48;
			
			CTOptions.appLogo = "ico24/logo.png";
			
			CTOptions.userMode = true;
			CTOptions.startConfig = "ct-config-user.css"; // "ct-config-user-mobile.css";
			CTOptions.isMobile = true;
			CTOptions.verboseMode = false;
			CTOptions.debugOutput = true;
			
			CTOptions.appConfigDir = "ctres";
			CTOptions.appName = "ContempleCMS";
			CTOptions.version = "1.0.11";
			
			CTOptions.mobileProjectFolderName = "ask";
			CTOptions.localSharedObjectId = "app.contemple.1.0.6";
			CTOptions.installSharedObjectId = "app.contemple.1.0.6";
			
			//// to embed theme for testing use: app:/theme-demo
			//CTOptions.installTemplate = "app:/theme-demo";
			CTOptions.installTemplate = "";
			
			CTOptions.clientHost = "";
			CTOptions.projectName = "";
			CTOptions.dbInitFileName = "db-index.xml";
			CTOptions.animateBackground = true;
			CTOptions.animateBackgroundMin = 0.48;
			CTOptions.animateBackgroundMax = 1;
		}
	}
}
