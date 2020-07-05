package ct
{	
	/**
	*
	* This is the root class of the contemple app for desktop (windows/mac)
	*
	* To check out the demo website, 
	* enter the following url when the app ask for the webserver url to begin: 
	*
	*   https://www.contemple.app/demo/cthub/
	*
	*
	**
	*
	* To develop themes and templates without a web server, or to use contemple without the upload features:
	*
	* - Select File / New from the contemple main menu. Choose Select another Template and Select a template folder or zip file.
	* - Install the template into a new directory.
	*
	* After the installation, the website build can be found in the /raw/ folder in the new directory. An optional compressed/minified version of the website is also saved into the /min/ folder.
	*
	* Upload the contents of the min/ or raw/ folder into your website root directory in order to publish the website manually.
	*
	* The theme/template is also copied into to directory/tmpl directory.
	*
	* Contemple can build the website automatically after file changes from external text editors.
	* Monitor Files have to be enabled under Developer / Preferences.
	* Contemple will watch all template files for file changes if enabled.
	*
	* Notes for theme developement:
	*
	* - After changes inside the template files wich affects the User Interface in Contemple (e.g. add/remove template areas/properties, or changes of property types/arguments)
	* Contemple may have to be restarted to behave correctly.
	* To restart Contemple, select a Language from the main menu or choose Restart from the Developer Preferences (Developer / Preferences / Restart )
	*
	**
	*
	* If you want to load your own template from your webserver and publish new content with contemple, 
	* the following steps are required before you can use the app with your website:
	*
	* - Create a template
	* - Download the hub-script from www.contemple.app
	* - Copy template.zip into hubfolder
	* - Modify the files: install.xml and cthub.php in the hub folder (see instructions inside install.xml and cthub.php)
	* - Upload the modified hub folder to your webserver (Optional rename the hub folder for security reasons)
	*
	* Then Editors can use the template from your webserver:
	*
	* - Start the contemple app, the app will ask for a web url to begin
	* - Enter the url to your hub folder on your webserver
	* - Proceed installing the available websites/templates
	*
	*
	**
	*
	* Another option is to compile the app with a template already embeded or with embeded webhost settings:
	* Then the users of the app don't have to do anything in order to install the website/template
	*
	* - Copy and rename this class (CTAppDesktop.as, for Android and IOS CTAppMobile.as)
	*
	* - set installTemplate to a template folder (for release builds, the folder have to be embeded in the air application settings): 
	*   CTOptions.installTemplate = "app:/my-template";
	*
	* - set clientHost:
	*   CTOptions.clientHost = "https://www.my-domain.com/";
	*
	* - set appName and projectName:
	*   CTOptions.appName = "My WebCMS":
	*   CTOptions.projectName = "the My-Website";
	*
	* - set uploadScript
	*   CTOptions.uploadScript = "https://www.my-domain.com/cthub-renamed/cthub-renamed.php";
	*
	* - set hub name and cthub script name:
	*   CTOptions.hubFolder = "cthub-renamed";
	*	CTOptions.hubScriptFilename = "cthub-renamed.php";
	* 
	* - set properties in CTOptions
	*
	* - Use the new root class inside Adobe Animate contemple.fla or contemple-mobile.fla as the Document class
	*
	* - Add the template folder to the included files in the Air Settings
	*
	* - Compile the app with Adobe Air 
	*
	* - Launch your app, the app automatically installs the embeded template
	*
	*
	**
	*
	* Alternatively it also possible to just open a Project-Directory created previously with contemple.
	* Then no installation is required. The Project Directory contains the template, database and the generated website.
	* Only the uploadScript, hubFolder and hubScriptFilename has to be set to point to your webserver, 
	* this can also be done from inside the template (the template/cmd.xml is able to override options on every app start)
	*
	*/
	public class CTAppDesktop extends CTApp 
	{
		public function CTAppDesktop () 
		{
			super();
			
			// Set default config options
			
			//CTOptions.appName = "Contemple-CMS";
			//CTOptions.version = "1.0.12";
			
			//CTOptions.userMode = true;
			//CTOptions.startConfig = "conf.css";
			//CTOptions.isMobile = false;
			//CTOptions.debugOutput = true;
			//CTOptions.verboseMode = false;
			//CTOptions.appConfigDir = "res";
			
			//CTOptions.clientHost = "";
			//CTOptions.installTemplate = "";
			
			//CTOptions.projectName = "the Contemple Website";
			//CTOptions.localSharedObjectId = "app.contemple.1.0.6";
			//CTOptions.installSharedObjectId = "app.contemple.1.0.6";
			//CTOptions.uploadViewShowFileInfo = false;
			//CTOptions.reverseAreasPopup = true;
			
			//CTOptions.animateBackground = true;
			//CTOptions.animateBackgroundMin = 0;
			//CTOptions.animateBackgroundMax = 0.3;
			
			//CTOptions.localUploadFolder = "min";
			//CTOptions.uploadMethod = "php";
		}
	}
}
