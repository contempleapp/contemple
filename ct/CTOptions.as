package ct
{
	import agf.tools.BaseTool;
	import flash.text.AntiAliasType;
	import flash.filesystem.File;
	import agf.icons.*;
	
	/**
	 * Contemple default values do not modify values here.
	 * Instead, override default options in CTApp.as or CTAppMobile.as,
	 * or set default options in the install.xml file in the cthub directory,
	 * or use APP-LOAD commands in cmd.xml of the template and SetValue command
	 */
	public class CTOptions 
	{
		public static var appLogo:String = "ico/logo.png";	// Contemple start logo
		
		public static var appName: String = "ContempleCMS"; // Can be set to theme version name runtime
		public static var version: String = "1.0.21"; // Can be set to theme version during runtime
		public static const contempleVersion:String = "1.0.21";
		
		public static var defaultServerStartUrl:String = "https://www.contemple.app/demo/cthub/";
		
		public static var userMode: Boolean = true; // User or Developer
		public static var isMobile: Boolean = false; // Compile for Desktop: false (.app, .exe) or Mobile: true (.apk, .ipa)
		public static var debugOutput: Boolean = true; // Log information and warnings for developers
		public static var verboseMode: Boolean = false; // In verbose mode, console is visible while installing and uploading
		
		public static var monitorFiles:Boolean = false;
		public static var softKeyboard:Boolean = false;  // Resize app when softkeyboard appears on screen. may cause bugs on some android verions
		public static var textEditorUndos:int = 32; 
		
		public static var appConfigDir:String = "res"; // embeded config files inside applicationDirectory
		public static var configFolder:String = "cfg";   // config files in applicationStorageDirectory
		public static var startConfig: String = "conf.css"; // config and stylesheet file in CTOptions.appConfigDir
		
		internal static var hubFolder:String = "cthub";   // hub folder on clientHost
		internal static const hubFolderDefault:String = "cthub";   // default hub folder on clientHost
		internal static var hubScriptFilename:String = "cthub.php";   // hub folder on clientHost
		internal static const hubScriptFilenameDefault:String = "cthub.php";   // hub folder on clientHost
		
		public static var mobileProjectFolderName: String = "ask"; // fixed project-directory name or the string "ask"
		public static var currentMobileFolder:String = ""; // read-only
		public static var mobileParentFolder: File = File.documentsDirectory; // parent folder of project-directory on mobile 
		public static var mobileWheelMove:Number = 12; // in px
		public static var longClickTime:int = 750; // mobile style list-scroll and long-click
		
		public static var JSONArgs:Boolean = true;
		public static var resolveWebFiles:Boolean = true;
		
		public static var insertAreaLocation:Boolean = true;
		public static var insertAreaPre:String = '<a class="loc-area" id="';
		public static var insertAreaPost:String = '"></a>';
		
		public static var insertItemLocation:Boolean = true;
		public static var insertItemPre:String = '<a class="loc-item" id="';
		public static var insertItemPost:String = '"></a>';
		
		public static var defaultNewlineWrap:Array = ['','<br/>']; // Default Wrap Argumnet for Text and Richtecht
		
		public static var previewInEditor:Boolean = true;
		public static var previewAtBottom:Boolean = false;  // (TODO: not implemented) web preview bottom or right
		
		public static var autoSave:Boolean = true;
		public static var dontAskForSave:Boolean = true; // If autoSave is false, performs one autoSave before switching to Fullscreen Preview
		
		public static var animateBackground:Boolean = true;		
		public static var animateBackgroundMin:Number = 0.48;		
		public static var animateBackgroundMax:Number = 1.0;		
		
		public static var autoUpdate:Boolean = false;		  // check for updates every app-start
		public static var autoTemplateUpdate:Boolean = false; //
		
		public static var updateUrl:String = ""; // "/download/update-win.xml"; // url to application update.xml
		
		public static var homeAreaName:String = "Home";
		public static var rememberArea:Boolean = true;
		public static var downloadOverviewWidth:int = 222;
		
		// New-Page settings
		public static var pageTemplateEnabled:Boolean = true;
		public static var pageParentEnabled:Boolean = false;
		public static var pageTypeEnabled:Boolean = false;
		public static var pageTitleEnabled:Boolean = false;
		public static var pageWebdirEnabled:Boolean = false;
		
		public static var charset:String = "utf-8"; // charset for text files
		public static var overrideInstallDB:String = ""; // sqlite db file path or empty
		public static var installTemplate:String = ""; // embed a template within the app, if installTemplate is a empty string, the app needs to download a template first from client host
		public static var projectName:String = "the Website";
		
		public static var urlSeparator:String = "/"; // Separator for file reading with File object
		public static var subtemplateFolder:String = "st";
		
		public static var projectFolderTemplate:String = "tmpl";
		public static var projectFolderRaw:String = "raw";
		public static var projectFolderMinified:String = "min";
		public static var previewFolder:String = "min";
		
		public static var tmpDir:String = "tmpd";		// name of temp directory in app-storage folder
		public static var templateStorage:String = "template-store"; // template downloads in app-storage folder
		
		// Template Information
		public static var templateIndexFile:String = "config.xml";
		public static var generateXhtmlStrictHtml:Boolean = false;
		
		// DB Information
		public static var dbIndexFileName:String = "dbi.xml"; // index file in the project directopry with database information for database
		public static var dbInitFileName:String = "db-index.xml"; // index file for database information and setup for installation.
		public static var dbType:String = "sqlite"; // dbtype for new db-index files, currently only sqlite db is suported, new versions may support text, xml, and online-db
		
		public static var clientHost:String = ""; // e.g: "https://your-site.com/" Or empty string to ask User for host
		public static var webDomain:String = "";
		
		// Upload Information
		public static var UPLOAD_USER_AGENT:String = "ContempleCMS";
		public static var uploadSendFileList:Boolean = true; // if false, the server sends a list of all files and folders in the website directory (not recommended)
		public static var hashCompareAlgorithm:String = "md5"; // md5, sha224, sha256
		public static var localUploadFolder:String = "min"; // 'min' or 'raw'
		public static var uploadMethod:String = "php"; // TODO: ftp, php, asp etc
		public static var uploadScript:String = ""; // https://your-site.com/cthub/cthub.php // Online script that takes file uploads, manage passwords, sync etc.
        public static var uploadViewShowFileInfo:Boolean = true;
		
		public static var syncOnStart:Boolean = true;		// test if newer content is available online every app-start
		
		public static var autoSync:Boolean = true;		// also upload xml content file and optional sync database and template with every publish
		public static var syncDatabase:Boolean = true;
		public static var syncTemplate:Boolean = false;  // TODO sync template files or zip file..
		
		public static const UPLOAD_METHOD_PHP:String = "php";
		//public static const UPLOAD_METHOD_ASP:String = "asp";
		//public static const UPLOAD_METHOD_FTP:String = "ftp";
		
		public static var localSharedObjectId:String = "app.contemple.1.0.6";
		public static var installSharedObjectId:String = "app.contemple.1.0.6";
		public static const localSharedObjectIdDefault:String = "app.contemple.1.0.6";  // set automatically by app
		
		// Experimental Feature: airhttp server (com.airhttp from github)
		// On Windows, Firefox and Chrome can not display the website because of http header and charset problems
		public static var useHttpServer:Boolean = false;
		public static var httpServerPort:int = 4748;
		
		public static var nativePreview:Boolean = false; // Use system html engine (true) or air legacy html engine (false)
		public static var reverseAreasPopup:Boolean = true;
		
		// quit app after install with overrideDB
		public static var restartAfterInstall:Boolean = false;
		
		public static var showLinkHash:Boolean = true;
		public static var fixRandomsOnlyOnMobile:Boolean = true; // if false, random values always force a file to parse, if true this applys only on mobile devices, were the browser requires new random values every time
		
		public static var cacheDownloads:Boolean = false;
		public static var textEditorAllowDrag:Boolean = false;
		public static var textEditorAllowClose:Boolean = false;
		public static var textEditorCodeColoring:Boolean = true;
		
		public static var codeColorStyle:String = ' .tag { color: #000099; font-weight:bold; } /* tag */ .atn { color: #006600; font-weight:normal; } /* attribute-name */ .atv { color: #660000; font-weight:bold; } /* attribute-value */ .pun { color: #111111; } /* attribute-operand (=,;:) */ .spl { color: #000066; font-weight:bold; } /* var */ .lit { color: #000000; } /* Number */ .str { color: #660000; } /* String */ .kwd { color: #000066; } /* Keyword if else etc */ .com { color: #776655; } /* Comment */ ';
		
		public static var richTextCssClasses:Array = [".Styles",
			"font-dark", "font-light", "jumbo", "subtext", "#separator",
			"bold", "italic", "text-underline", "#separator",
			"text-left", "text-center", "text-right", "text-justify",
			"text-uppercase", "text-lowercase", "text-capitalize"
		];
	}
}