package ct.ctrl {
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import agf.tools.*;
	import agf.ui.*;
	
	public class CommandEditor extends Window {

		public function CommandEditor() {
			super("command-ed", "Command Editor", 300, 200, null, Application.instance.config, "", "command-editor", "command-editor-title", "command-editor-close-button", "command-editor-background");
		}
		
		public var commandPP:Popup;
		public var commandTF:TextField;
		public var processButton:Button;
		
		// use after added to stage only
		public function createEditor () :void
		{
			if( commandPP && body.contains( commandPP ) ) body.removeChild( commandPP );
			if( commandTF && body.contains( commandTF ) ) body.removeChild( commandTF );
			if( processButton && body.contains( processButton ) ) body.removeChild( processButton );
			
			commandPP = new Popup( ["Commands.."],0,0, body, styleSheet, "", "command-editor-popup",false);
			
			var L:int = allcmds.length;
			for( var i:int=0; i < L; i++) {
				if( allcmds[i].name != "" ) {
					commandPP.rootNode.addItem( [ allcmds[i].name ], styleSheet );
				}
			}
			
			commandPP.y = title.cssSizeY + body.cssTop + cssTop;
			commandPP.x = body.getWidth() - commandPP.cssSizeX;
			
			commandTF = new TextField();
			commandTF.x = cssLeft + body.cssLeft;
			commandTF.y = title.cssSizeY + body.cssTop + cssTop;
			commandTF.width = body.getWidth() - commandPP.cssSizeX;
			commandTF.text = "yYvVÜÖpP1!$";
			commandTF.height = commandTF.textHeight;
			commandTF.text = "";
			
			body.addChild( commandTF );
			
			processButton = new Button( ["Execute"], 0, 0, body, styleSheet, '', 'command-editor-process-btn', false);
			processButton.x = cssLeft + body.cssLeft + (body.getWidth() - processButton.cssSizeX) * 0.5;
			processButton.y = body.getHeight() - processButton.cssSizeY;
		}
		
		
		public static var allcmds:Array = [
			{ name: "", cmd: "", info:"" },
			
			{ name: "", cmd: "", info:"" },
			{ name: "Create Template", cmd: "TemplateTools create-template", info:"Displays a form to create new Templates" },
			{ name: "", cmd: "", info:"" },
			{ name: "Export SQL", cmd: "TemplateTools export-sql [sub-template-name]", info:"Exports content stored in the database" },
			{ name: "", cmd: "", info:"" },
			{ name: "Open", cmd: "CTTools open [filepath-to-project-dir]", info:"Open a existing contemple project" },
			{ name: "", cmd: "", info:"" },
			{ name: "Install Template", cmd: "TemplateTools install-template [filepath-to-zip-file]", info:"Installs a zip-compressed template" },
			{ name: "", cmd: "", info:"" },
			{ name: "Save", cmd: "CTTools save", info:"" },
			{ name: "Save As", cmd: "CTTools saveas", info:"" },
			{ name: "", cmd: "", info:"" },
			{ name: "Subtemplate", cmd: "CTTools subtemplate [filepath-to-subtemplate-folder]", info:"" },
			{ name: "", cmd: "", info:"" },
			{ name: "", cmd: "", info:"" },
			{ name: "Template", cmd: "CTTools template [filepath-to-template-folder]", info:"Installs a new template" },
			{ name: "", cmd: "", info:"" },
			{ name: "", cmd: "", info:"" },
			{ name: "Update Template", cmd: "TemplateTools update-template [filepath-to-zip-file]", info:"Update a template" },
			{ name: "Unset Project", cmd: "CTTools clear-project-reference", info:"Clears the current project and resets chached folders, on mobile mode the files are also deleted from disk." },
			{ name: "", cmd: "", info:"" },
			{ name: "Quit", cmd: "Application quit", info:"Closes the application immediatly." },
			
			{ name: "", cmd: "", info:"" },
			{ name: "", cmd: "", info:"" },
			{ name: "", cmd: "", info:"" },
		];
	}
	
}
