package ct
{
	import flash.filesystem.File;
	import agf.html.CompactCode;
	import agf.html.HtmlParser;
	import com.adobe.air.filesystem.FileMonitor;
	import agf.tools.Console;
	import agf.tools.Application;
	import flash.events.Event;
	import com.adobe.air.filesystem.events.FileMonitorEvent;
	
	public class ProjectFile
	{
		public function ProjectFile ( tmplId:String="new") {
			templateId = tmplId;
		}
		
		public var templateId:String;             // Name of the template the file belongs to
		
		public var type:String = "script";        // Script or Html/Xml
		public var path:String="";	              // full path
		public var name:String="";	              // File name without extension
		public var filename:String="";	          // File name with extension
		public var extension:String="";      	  // File extension
		
		internal var template:String = "";          // raw template text
		
		private var text:String = "";             // translated text with template and database
		private var compact:String = "";          // Minified text version without whitespace
		private var compactTemplate:String = "";  // Minified text version without whitespace
		
		internal var splits:Boolean=false;      	  // If the file contains split branches
		internal var splitPath:String = "";
		
		internal var templateStruct:Array;          // Code Between Areas
		internal var templateAreas:Vector.<Area>;   // {##AREA}
		internal var templateProperties:Array;      // {#PROPERTY}
		
		internal var compactDirty:Boolean = false;   // set after changes in content items
		internal var templateDirty:Boolean = false;  // set after changes in the template
		internal var textDirty:Boolean = false;      // set after changes in content items
		internal var compactTemplateDirty = false;   // set when template changes
		
		private var monitor:FileMonitor;
		internal var templateSaveDirty:Boolean = false; // saveDirty have to be set to false after a file-save (from CTTools)
		internal var textSaveDirty:Boolean = false;	// and will be always set to true when content changed
		private var pageItemName:String=""; // for temporary subtemplate parsing
		
		
		public function setUrl ( url:String ) :void {
			path = url;
			var dot:int = url.lastIndexOf( "." );
			if( dot >= 0 ) {
				extension = url.substring( dot+1 );
				if( extension == "htm" || extension == "html" || extension == "xml" ) {
					type = "html";
				}else if ( extension == "css" ) {
					type = "style";
				}else{
					type = "script";
				}
			}else{
				extension = "";
			}
			
			var st:int = url.lastIndexOf( CTOptions.urlSeparator ) + 1;
			name = url.substring( st, dot );
			filename = url.substring( st );
			
			if( !CTOptions.isMobile && CTOptions.monitorFiles )
				monitorFile(true);
		}
		
		public function monitorFile( enable:Boolean=false ) :void {
			if( monitor ) {
				monitor.unwatch();
				monitor = null;
			}
			if(enable) {
				var file:File = new File( path );
				if( file.exists ) {
					monitor = new FileMonitor( file );
					monitor.addEventListener(FileMonitorEvent.CHANGE, onFileChange );
					monitor.addEventListener(FileMonitorEvent.CREATE, onFileCreate );
					monitor.addEventListener(FileMonitorEvent.MOVE, onFileMove );
					
					monitor.watch();
				}
			}
		}

		private function onFileCreate ( e:FileMonitorEvent ) :void {
			// trace("FILE-MONITOR: Create '"+e.file.url+"'");
		}
		
		private function onFileMove ( e:FileMonitorEvent ) :void {
			// trace("FILE-MONITOR: Move '"+e.file.url+"'");
		}
		
		private function onFileChange( e:FileMonitorEvent ):void
		{
			var s:String = CTTools.readTextFile( e.file.url );

			// trace("FileMonitor CHANGE: " + e.file.url);
			
			setTemplate( s );
			
			
			if( templateId && CTTools.activeTemplate && templateId != CTTools.activeTemplate.name  )
			{
				// Invalidate sub template files
				CTTools.invalidateTemplateFiles(CTTools.activeTemplate,false);
			}
			
			// don't need to save modified file again..
			templateSaveDirty = false;
			
			if( CTOptions.autoSave ) CTTools.save();
			
			try {
				// update text editors
				Application.instance.view.panel.src["displayFiles"]();
			}catch(e:Error) {
				
			}
			
			if(CTOptions.debugOutput ) {
				Console.log( "Reloaded modified file '"+path+"'");
			}
		}
		
		public function allDirty () :void {
			templateDirty = true;
			compactTemplateDirty = true;
			textDirty = true;
			compactDirty = true;
			templateSaveDirty = true;
			textSaveDirty = true;
		}
		public function contentDirty () :void {
			textDirty = true;
			compactDirty = true;
			textSaveDirty = true;
		}
		
		public function getTemplate () :String { return template; }
		public function setTemplate ( str:String, stPageItemName:String="" ) :void {
			template = str;
			pageItemName = stPageItemName;
			templateDirty = true;
			compactTemplateDirty = true;
			textDirty = true;
			compactDirty = true;
			templateSaveDirty = true;
			textSaveDirty = true;
		}
		
		public function getCompactTemplate () :String {
			if( compactTemplateDirty ){
				if( type == "html" ) {
					compactTemplate = CompactCode.compactHtml( getTemplate() );
				}else if ( type == "style" ) {
					compactTemplate = CompactCode.compactStyle ( getTemplate() );
				}else{
					compactTemplate = CompactCode.compactScript( getTemplate() );
				}
				compactTemplateDirty = false;
			}
			return compactTemplate;
		}
		
		// text may be set by Template-Engine only
		public function setText (str:String) :void {
			text = str;
			textDirty = true;
			compactDirty = true;
			textSaveDirty = true;
		}
		
		public function getText () :String
		{
			if( templateDirty )
			{
				Template.parseFile ( this, CTTools.findTemplate(templateId, "name"), pageItemName, name );
				templateDirty = false;
			}
			
			if( textDirty )
			{
				CTTools.fillTemplate(this);
				
				if( type == "html" && CTOptions.generateXhtmlStrictHtml ) {
					setText( HtmlParser.toXml( text, false, false ) );
				}
				textDirty = false;
			}
			
			return text;
		}
		
		public function getCompact () :String {
			if( compactDirty ){
				if( type == "html" ) {
					compact = CompactCode.compactHtml( getText() );
				}else if ( type == "style" ) {
					compact = CompactCode.compactStyle ( getText() );
				}else{
					compact = CompactCode.compactScript ( getText() );
				}
				compactDirty = false;
			}
			return compact;
		}
		
	}
	
}
