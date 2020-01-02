﻿package ct
	
			// Font only on macOS 
			Console.DEFAULT_FONT = "Lucida Console";
			
			CTOptions.verboseMode = false;
			
			CTOptions.version = "1.0.0";
			CTOptions.appConfigDir = "ctres";
			CTOptions.clientHost = "http://localhost:8888/";
			CTOptions.projectName = "the Contemple Demo Website";
			CTOptions.startConfig = "ct-config-user-mobile.css"; //"ctres-hm/ct-config-user.css";
			CTOptions.installTemplate = "app:/template-base";
			
			CTOptions.dbInitFileName = "db-index.xml"; //"app:/ctres-hm/db-index.xml";
			
			CTOptions.hashCompareAlgorithm = "md5";
			
			CTOptions.localSharedObjectId = "at.contemple.base.1";
			CTOptions.homeAreaName = "Content";
			
			CTOptions.uploadViewShowFileInfo = false;
			CTOptions.reverseAreasPopup = false;
			CTOptions.rememberArea = true;
			
			CTOptions.localUploadFolder = "min";
			CTOptions.uploadMethod = "php";
			
			CTOptions.uploadScript = "http://localhost:8888/cthub/cthub-hm.php";
		
			CTOptions.overrideInstallDB = "";//"app:/ctres-hm/local.db";
			
			
			CTOptions.animateBackground = true;
			CTOptions.animateBackgroundMin = 0.3;
			CTOptions.animateBackgroundMax = 1;
			
			CTMain.setupConfigFiles();