package ct
{
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import flash.filesystem.*;
	import flash.utils.setTimeout;
	import agf.events.PopupEvent;
	import agf.utils.FileUtils;
	import agf.utils.FileInfo;
	import agf.Main;
	import agf.Options;
	import agf.ui.*;
	import agf.html.*;
	import agf.tools.*;
	import agf.events.*;
	import agf.icons.IconFromFile;
	import agf.icons.IconArrowDown;
	import ct.ctrl.*;
	
	/**
	* Template Kickstarter
	*
	* - List active Templates and Subtemplates
	* - Edit Template config files (config.xml, cmd-file, initquery, defaultquery, defaultcontent
	* - Edit Template Property Definitions (#def: .. #def;)
	* - Create new Root- and Sub- Templates
	*/
	public class TemplateScreen extends BaseScreen 
	{
		public function TemplateScreen () 
		{
			Application.instance.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			create();
			InputTextBox.disableFileSearch = true;
		}
			
		protected override function removePanel (e:Event) :void {
			super.removePanel(e);
			InputTextBox.disableFileSearch = false;
		}
		
		protected override function create () :void
		{
			var i:int;
			var pi:PopupItem;
			
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			
			cont = new CssSprite( w, h, null, container.styleSheet, 'body', '', '', true);
			addChild(cont);
			cont.init();
			
			body = new CssSprite(w, h, cont, container.styleSheet, 'div', '', 'editor template-screen', false);
			body.setWidth( w - body.cssBoxX );
			body.setHeight( h - body.cssBoxY );
			
			if( CTOptions.animateBackground ) {
				HtmlEditor.dayColorClip( body.bgSprite );
			}
			
			title = new Label(0, 0, body, container.styleSheet, '', 'template-screen-title', false);
			title.label = Language.getKeyword( "Template Kickstarter" );
			title.textField.autoSize = TextFieldAutoSize.LEFT;
			
			showTemplates();
		}
		
		public var title:Label;
		private var itemList:ItemList;
		private var newTmpl:Button;
		
		private var index_pc:PropertyCtrl;
		private var files_pc:PropertyCtrl;
		private var folders_pc:PropertyCtrl;
		private var sortproperties_pc:PropertyCtrl;
		private var sortareas_pc:PropertyCtrl;
		private var type_pc:PropertyCtrl;
		
		private var listlabel_pc:PropertyCtrl;
		private var listicon_pc:PropertyCtrl;
		private var tables_pc:PropertyCtrl;
		private var fields_pc:PropertyCtrl;
		
		private var version_pc:PropertyCtrl;
		private var templatefolders_pc:PropertyCtrl;
		private var dbcmds_pc:PropertyCtrl;
		private var help_pc:PropertyCtrl;
		private var homeAreaName_pc:PropertyCtrl;
		
		// root templates:
		private var hiddenareas_pc:PropertyCtrl;
		private var defaultcontent_pc:PropertyCtrl;
		private var nocompress_pc:PropertyCtrl;
		private var nolocareas_pc:PropertyCtrl;
		private var pagetemplates_pc:PropertyCtrl;
		private var staticfiles_pc:PropertyCtrl;
		
		// sub templates
		private var hidden_pc:PropertyCtrl;
		private var nolocation_pc:PropertyCtrl;
		private var articlepage_pc:PropertyCtrl;
		private var articlename_pc:PropertyCtrl;
		private var parselistlabel_pc:PropertyCtrl;
		
		protected override function newSize (e:Event=null) :void
		{
			var w:int = container.getWidth();
			var h:int = container.getHeight();
			var sbw:int = 0;
			
			if( cont ) {
				cont.setWidth( w );
				cont.setHeight( h );
			}
			if( body ) {
				body.setWidth(w);
				body.setHeight(h);
			}
			
			if( title ) {
				title.setWidth( w );
				title.setHeight( 64 );
				title.x = body.cssLeft;
				title.y = body.cssTop;
			}
			if( newTmpl ) {
				newTmpl.y = body.cssTop;
				newTmpl.x = w - (newTmpl.cssSizeX + newTmpl.cssBoxX);
			}
			if( scrollpane ) {
				scrollpane.setWidth( w - body.cssBoxX );
				scrollpane.setHeight( h - (title.cssSizeY + title.cssBoxX + body.cssBoxY) );
				scrollpane.contentHeightChange();
				scrollpane.x = body.cssLeft;
				scrollpane.y = body.cssTop + title.cssSizeY + title.cssBoxX;
				if( scrollpane.slider.visible ) sbw = scrollpane.slider.cssSizeX + 4;
			}
			
			if( itemList)
			{
				if(itemList.items)
				{
					var yp:int=0;
					var lbl:Label;
					
					for( var i:int=0; i < itemList.items.length; i++) {
						itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + body.cssBoxX + sbw) );
						if( itemList.items[i] is Label ) {
							lbl = Label( itemList.items[i] );
							lbl.textField.autoSize = TextFieldAutoSize.LEFT;
							lbl.textField.wordWrap = false;
							lbl.textField.width = int( w - (sbw + body.cssLeft*2) );
							itemList.items[i].y = int(yp);
							yp += itemList.items[i].cssSizeY + itemList.margin;
						}else{
							itemList.items[i].y = int(yp);
							yp += itemList.items[i].cssSizeY + itemList.margin;
						}
					}
				}
				
				itemList.setWidth(0);
				itemList.init();
			}
			
			if( nameCtrl ) {
				nameCtrl.x = body.cssLeft;
				nameCtrl.y = body.cssTop;
				nameCtrl.setWidth( w - body.cssBoxX );
			}
		}
		
		private function showTemplates (args:*=null) :void
		{
			if( nameCtrl && body && body.contains(nameCtrl)) body.removeChild(nameCtrl);
			if( newTmpl && body && body.contains(newTmpl)) body.removeChild(newTmpl);
			
			nameCtrl = null;
			
			title.visible = true;
			
			newTmpl = new Button(["New Template", new IconFromFile(Options.iconDir+"/new.png",Options.iconSize, Options.iconSize)],0,0,body,container.styleSheet,"","new-tmpl-button",false);
			newTmpl.addEventListener( MouseEvent.CLICK, newTemplateHandler);
			
			if( scrollpane && itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
			if( scrollpane && body && body.contains( scrollpane) ) body.removeChild( scrollpane );
			
			scrollpane = new ScrollContainer( 0, 0, body, container.styleSheet,'', '', false);
			scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
			
			itemList = new ItemList(0,0,scrollpane.content, container.styleSheet,'','constants-container',true);
			var currSprite:CssSprite;
			itemList.margin = 0;
			
			var lbl:Label;
			var btn:Button;
			
			if( CTTools.activeTemplate )
			{
				lbl = new Label( 0, 0, itemList, container.styleSheet, '', 'property-section', true);
				lbl.label = Language.getKeyword( "Root Template" );
				lbl.textField.autoSize = TextFieldAutoSize.LEFT;
				lbl.textField.wordWrap = false;
				lbl.init();
				itemList.addItem(lbl, true);
				
				btn = new Button( [new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "page.png", Options.iconSize, Options.iconSize), CTTools.activeTemplate.name], 0,0, itemList, container.styleSheet, '', 'constanteditor-folder', false);
				btn.options.tmpl = CTTools.activeTemplate;
				btn.addEventListener( MouseEvent.CLICK, tmplClick );
				itemList.addItem(btn, true);
			}
			
			if( CTTools.subTemplates && CTTools.subTemplates.length > 0 )
			{
				lbl = new Label( 0, 0, itemList, container.styleSheet, '', 'property-section', true);
				lbl.label = Language.getKeyword( "Sub Templates" );
				lbl.textField.autoSize = TextFieldAutoSize.LEFT;
				lbl.textField.wordWrap = false;
				lbl.init();
				itemList.addItem(lbl, true);
				
				var L:int = CTTools.subTemplates.length;
				
				for( var i:int = 0; i<L; i++)
				{
					btn = new Button( [new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "plug.png", Options.iconSize, Options.iconSize), CTTools.subTemplates[i].name], 0,0, itemList, container.styleSheet, '', 'constanteditor-folder', false);
					btn.options.tmpl = CTTools.subTemplates[i];
					btn.addEventListener( MouseEvent.CLICK, tmplClick );
					itemList.addItem(btn, true);
				}
			}
			
			itemList.format();
			newSize();
		}
		
		private function newTemplateHandler (e:MouseEvent) :void
		{
			e.stopImmediatePropagation();
			showNewTemplate();
		}
		
		private function tmplClick (e:Event) :void {
			if( clickScrolling )
			{
				clickScrolling = false;
			}
			else
			{
				var tmpl:Template = e.currentTarget.options.tmpl;
				showTemplate( tmpl );
			}
		}
		
		private static var pfTmp:ProjectFile = new ProjectFile();
		
		private function showTemplate ( tmpl:Template ) :void
		{
			title.visible = false;
			
			if( newTmpl && body && body.contains(newTmpl)) body.removeChild(newTmpl);
			
			if( tmpl )
			{
				if( scrollpane && itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
				if( scrollpane && body && body.contains( scrollpane) ) body.removeChild( scrollpane );
					
				scrollpane = new ScrollContainer( 0, 0, body, container.styleSheet, '', '', false);
				scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
				
				itemList = new ItemList(0, 0, scrollpane.content, container.styleSheet, '', 'constants-container', true);
				var currSprite:CssSprite;
				itemList.margin = 0;
				
				var rootTmpl:Boolean = tmpl == CTTools.activeTemplate;
				
				var nm:NameCtrl = new NameCtrl( tmpl.name, tmpl.name, "", tmpl.name, null, null,
									0, 0, body, container.styleSheet,'', '', false, true);
				nm.addEventListener( "save", saveTemplateHandler );
				nm.addEventListener( "close", closeTemplateHandler );
				nm.showNextButton(false);
				nm.showPrevButton(false);
				nm.showDeleteButton(false);
				nm.showSaveButton(false);
				nameCtrl = nm;
				
				var styl:CssStyleSheet = container.styleSheet;
				
				if( rootTmpl )
				{
					//  name, type, version, index, files, folders, help, hiddenareas, nocompress, nolocareas, pagetemplates, staticfiles, defaultcontent
					nm.showDeleteButton(false);
					nm.label.label = Language.getKeyword("Root Template");
					
					version_pc = new PropertyCtrl( Language.getKeyword("new-template-version"), "new-template-version", "string", tmpl.version, null, null, 0, 0, itemList, styl,'','constant-prop',false);

					index_pc = new PropertyCtrl( Language.getKeyword("new-template-index-file"), "new-template-index-file", "file", tmpl.indexFile, null, ["","","Select Index File","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					files_pc = new PropertyCtrl( Language.getKeyword("new-template-files"), "new-template-files", "vector", tmpl.files, null,  [0,"Files","",",",true,"","","Select folder with static files","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					folders_pc = new PropertyCtrl( Language.getKeyword("new-template-folders"), "new-template-folders", "vector", tmpl.folders, null,  [0,"Directory","",",",true,"","","Select folder","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					sortproperties_pc = new PropertyCtrl( Language.getKeyword("new-template-sortproperties"), "new-template-sortproperties", "list", tmpl.sortproperties, null, ["name","priority"], 0, 0, itemList, styl,'','constant-prop',false);
					sortareas_pc = new PropertyCtrl( Language.getKeyword("new-template-sortareas"), "new-template-sortareas", "list", tmpl.sortareas, null, ["name","priority"], 0, 0, itemList, styl,'','constant-prop',false);
					hiddenareas_pc = new PropertyCtrl( Language.getKeyword("new-template-hiddenareas"), "new-template-hiddenareas", "vector", tmpl.hiddenareas, null, [0,"AreaList","",",",true], 0, 0, itemList, styl,'','constant-prop',false);
					help_pc = new PropertyCtrl( Language.getKeyword("new-template-help"), "new-template-help", "file", tmpl.help, null, ["","","Select Help File","*.xml"], 0, 0, itemList, styl,'','constant-prop',false);
					dbcmds_pc = new PropertyCtrl( Language.getKeyword("new-template-dbcmds"), "new-template-dbcmds", "file", tmpl.dbcmds, null, ["","","Select Command File","*.xml"], 0, 0, itemList, styl,'','constant-prop',false);
					defaultcontent_pc = new PropertyCtrl( Language.getKeyword("new-template-defaultcontent"), "new-template-defaultcontent", "file", tmpl.defaultcontent, null, ["","","Select Content File","*.xml"], 0, 0, itemList, styl,'','constant-prop',false);
					nocompress_pc = new PropertyCtrl( Language.getKeyword("new-template-nocompress"), "new-template-nocompress", "vector", tmpl.nocompress, null, [0,"List","",",",true,tmpl.files], 0, 0, itemList, styl,'','constant-prop',false);
					nolocareas_pc = new PropertyCtrl( Language.getKeyword("new-template-nolocareas"), "new-template-nolocareas", "vector", tmpl.nolocareas, null, [0,"AreaList","",",",true], 0, 0, itemList, styl,'','constant-prop',false);
					pagetemplates_pc = new PropertyCtrl( Language.getKeyword("new-template-pagetemplates"), "new-template-pagetemplates", "vector", tmpl.pagetemplates, null, [0,"Files","",",",true,"","","Select page template","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					staticfiles_pc = new PropertyCtrl( Language.getKeyword("new-template-staticfiles"), "new-template-staticfiles", "vector", tmpl.staticfiles, null, [0,"File","",",",true,"","","Select static file","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					templatefolders_pc = new PropertyCtrl( Language.getKeyword("new-template-templatefolders"), "new-template-templatefolders", "vector", tmpl.templatefolders, null, [0,"File","",",",true,"","","Select static file","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					homeAreaName_pc = new PropertyCtrl( Language.getKeyword("new-template-homeareaname"), "new-template-homeareaname", "arealist", tmpl.homeAreaName, null, null, 0, 0, itemList, styl,'','constant-prop',false);

					itemList.addItem( version_pc, true );
					itemList.addItem( index_pc, true );
					itemList.addItem( files_pc, true );
					itemList.addItem( folders_pc, true );
					itemList.addItem( hiddenareas_pc, true );
					itemList.addItem( help_pc, true );
					itemList.addItem( dbcmds_pc, true );
					itemList.addItem( defaultcontent_pc, true );
					itemList.addItem( nocompress_pc, true );
					itemList.addItem( nolocareas_pc, true );
					itemList.addItem( pagetemplates_pc, true );
					itemList.addItem( staticfiles_pc, true );
					itemList.addItem( templatefolders_pc, true );
					itemList.addItem( sortproperties_pc, true );
					itemList.addItem( sortareas_pc, true );
					itemList.addItem( homeAreaName_pc, true );
				}
				else
				{
					// articlepage, articlename, fields, files, folders, help, index, listlabel, listicon, parselistlabel, nolocation, staticfiles, tables, type(s), version
					nm.label.label = Language.getKeyword("Sub Template");
					
					var tmplTypes:Array = [",","content"];
					var prjat:Object={};
					var arr:Vector.<String>;
					var k:int;
					
					if( CTTools.activeTemplate ) {
						var areas:Object = CTTools.activeTemplate.areasByName;
						var a:String;
						var nam:String;
						for(nam in areas) {
							if( areas[nam].types != undefined) {
								arr = areas[nam].types;
								for(k=0;k<arr.length;k++) {
									prjat[arr[k]]=true;
								}
							}
							prjat[areas[nam].type]=true;
						}
						
						for(nam in prjat) tmplTypes.push(nam);
					}
										
					var typedFields:String = "";
					var fieldArray:Array = tmpl.fields.split(",");
					
					if( fieldArray.length > 0 ) {
						for(var i:int=0; i<fieldArray.length; i++ ) {
							if ( typeof(tmpl.propertiesByName[ fieldArray[i] ]) != "undefined" ) {
								typedFields += tmpl.propertiesByName[ fieldArray[i] ].defType + ":" +  fieldArray[i] + ",";
							}else{
								typedFields += "String:" +  fieldArray[i] + ",";
							}
						}
					}
					
					version_pc = new PropertyCtrl( Language.getKeyword("new-template-version"), "new-template-version", "string", tmpl.version, null, null, 0, 0, itemList, styl,'','constant-prop',false);
					type_pc = new PropertyCtrl( Language.getKeyword("new-template-type"), "new-template-type", "listmultiple", tmpl.type, null, tmplTypes, 0, 0, itemList, styl,'','constant-prop',false);
					index_pc = new PropertyCtrl( Language.getKeyword("new-template-index-file"), "new-template-index-file", "file", tmpl.indexFile, null, ["","","Select Index File","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					tables_pc = new PropertyCtrl( Language.getKeyword("new-template-tables"), "new-template-tables", "string", tmpl.tables, null, null, 0, 0, itemList, styl,'','constant-prop',false);
					fields_pc = new PropertyCtrl( Language.getKeyword("new-template-fields"), "new-template-fields", "vector", typedFields.substring(0, typedFields.length-1), null, [0,"typed","",",",true,"Area,AreaList,Audio,Boolean,Code,Color,Directory,File,Files,Font,Hidden,Image,Integer,Intern,ItemList,ItemListAppend,ItemListMultiple,List,ListAppend,ListMultiple,LabelList,LabelListAppend,LabelListMultiple,Line,Name,Number,PageList,Pdf,Plugin,ScreenInteger,ScreenNumber,String,Richtext,Text,Typed,Vector,VectorLink,Video,Zip"], 0, 0, itemList, styl,'','constant-prop',false);
					tables_pc.textBox.addEventListener( "heightChange", heightUpdate );
					fields_pc.textBox.addEventListener( "heightChange", heightUpdate );
					files_pc = new PropertyCtrl( Language.getKeyword("new-template-files"), "new-template-files", "vector", tmpl.files, null,  [0,"File","",",",true,"","","Select folder with static files","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					folders_pc = new PropertyCtrl( Language.getKeyword("new-template-folders"), "new-template-folders", "vector", tmpl.folders, null,  [0,"Directory","",",",true,"","","Select folder with static files","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					templatefolders_pc = new PropertyCtrl( Language.getKeyword("new-template-templatefolders"), "new-template-templatefolders", "vector", tmpl.templatefolders, null, [0,"File","",",",true,"","","Select static file","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					
					listicon_pc = new PropertyCtrl( Language.getKeyword("new-template-listicon"), "new-template-listicon", "list", tmpl.listicon, null, 
					[[new IconFromFile(Options.iconDir+"/activity-feed.png",Options.iconSize,Options.iconSize),"ico:/activity-feed.png"],
					[new IconFromFile(Options.iconDir+"/audio-book.png",Options.iconSize,Options.iconSize),"ico:/audio-book.png"],
					[new IconFromFile(Options.iconDir+"/aweb.png",Options.iconSize,Options.iconSize),"ico:/aweb.png"],
					[new IconFromFile(Options.iconDir+"/blog.png",Options.iconSize,Options.iconSize),"ico:/blog.png"],
					[new IconFromFile(Options.iconDir+"/cam.png",Options.iconSize,Options.iconSize),"ico:/cam.png"],
					[new IconFromFile(Options.iconDir+"/cap.png",Options.iconSize,Options.iconSize),"ico:/cap.png"],
					[new IconFromFile(Options.iconDir+"/categorize.png",Options.iconSize,Options.iconSize),"ico:/categorize.png"],
					[new IconFromFile(Options.iconDir+"/chat-message.png",Options.iconSize,Options.iconSize),"ico:/chat-message.png"],
					[new IconFromFile(Options.iconDir+"/create.png",Options.iconSize,Options.iconSize),"ico:/create.png"],
					[new IconFromFile(Options.iconDir+"/diamond.png",Options.iconSize,Options.iconSize),"ico:/diamond.png"],
					[new IconFromFile(Options.iconDir+"/diplom.png",Options.iconSize,Options.iconSize),"ico:/diplom.png"],
					[new IconFromFile(Options.iconDir+"/event.png",Options.iconSize,Options.iconSize),"ico:/event.png"],
					[new IconFromFile(Options.iconDir+"/hierarchy.png",Options.iconSize,Options.iconSize),"ico:/hierarchy.png"],
					[new IconFromFile(Options.iconDir+"/image2.png",Options.iconSize,Options.iconSize),"ico:/image2.png"],
					[new IconFromFile(Options.iconDir+"/modul.png",Options.iconSize,Options.iconSize),"ico:/modul.png"],
					[new IconFromFile(Options.iconDir+"/music.png",Options.iconSize,Options.iconSize),"ico:/music.png"],
					[new IconFromFile(Options.iconDir+"/news.png",Options.iconSize,Options.iconSize),"ico:/news.png"],
					[new IconFromFile(Options.iconDir+"/nummerierte-liste.png",Options.iconSize,Options.iconSize),"ico:/nummerierte-liste.png"],
					[new IconFromFile(Options.iconDir+"/octahedron.png",Options.iconSize,Options.iconSize),"ico:/octahedron.png"],
					[new IconFromFile(Options.iconDir+"/page.png",Options.iconSize,Options.iconSize),"ico:/page.png"],
					[new IconFromFile(Options.iconDir+"/panorama.png",Options.iconSize,Options.iconSize),"ico:/panorama.png"]
					], 0, 0, itemList, styl,'','constant-prop',false);
					
					listlabel_pc = new PropertyCtrl( Language.getKeyword("new-template-listlabel"), "new-template-listlabel", "string", tmpl.listlabel, null, null, 0, 0, itemList, styl,'','constant-prop',false);
					sortproperties_pc = new PropertyCtrl( Language.getKeyword("new-template-sortproperties"), "new-template-sortproperties", "list", tmpl.sortproperties, null, ["name","priority"], 0, 0, itemList, styl,'','constant-prop',false);
					help_pc = new PropertyCtrl( Language.getKeyword("new-template-help"), "new-template-help", "file", tmpl.help, null, ["","","Select Content File","*.xml"], 0, 0, itemList, styl,'','constant-prop',false);

					articlepage_pc = new PropertyCtrl( Language.getKeyword("new-template-articlepage"), "new-template-articlepage", "file", tmpl.articlepage, null, ["","","Select Page Template","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
					articlename_pc = new PropertyCtrl( Language.getKeyword("new-template-articlename"), "new-template-articlename", "string", tmpl.articlename, null, [], 0, 0, itemList, styl,'','constant-prop',false);
					parselistlabel_pc = new PropertyCtrl( Language.getKeyword("new-template-parselistlabel"), "new-template-parselistlabel", "boolean", tmpl.parselistlabel ? String(tmpl.parselistlabel) :"false", null, [], 0, 0, itemList, styl,'','constant-prop',false);
					nolocation_pc = new PropertyCtrl( Language.getKeyword("new-template-nolocation"), "new-template-nolocation", "boolean", tmpl.nolocation ?  String(tmpl.nolocation) : "false", null, [], 0, 0, itemList, styl,'','constant-prop',false);
					hidden_pc = new PropertyCtrl( Language.getKeyword("new-template-hidden"), "new-template-hidden", "boolean", tmpl.hidden ?  String(tmpl.hidden) : "false", null, [], 0, 0, itemList, styl,'','constant-prop',false);
					
					itemList.addItem( version_pc, true );
					itemList.addItem( type_pc, true );
					itemList.addItem( index_pc, true );
					itemList.addItem( tables_pc, true );
					itemList.addItem( fields_pc, true );
					itemList.addItem( files_pc, true );
					itemList.addItem( folders_pc, true );
					itemList.addItem( templatefolders_pc, true );
					itemList.addItem( listicon_pc, true );
					itemList.addItem( listlabel_pc, true );
					itemList.addItem( parselistlabel_pc, true );
					itemList.addItem( sortproperties_pc, true );
					itemList.addItem( help_pc, true );
					itemList.addItem( articlepage_pc, true );
					itemList.addItem( articlename_pc, true );
					itemList.addItem( nolocation_pc, true );
					itemList.addItem( hidden_pc, true );
				}
				
				itemList.format();
				
				files_pc.textBox.addEventListener( "heightChange", heightUpdate);
				folders_pc.textBox.addEventListener( "heightChange", heightUpdate);
				
				currTemplate = tmpl;
				newSize();
			}
		}
		
		private var currTemplate:Template;
		
		private function showNewTemplate ( ) :void
		{
			title.visible = false;
			
			if( newTmpl && body && body.contains(newTmpl)) body.removeChild(newTmpl);
			
			if( scrollpane && itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
			if( scrollpane && body && body.contains( scrollpane) ) body.removeChild( scrollpane );
				
			scrollpane = new ScrollContainer( 0, 0, body, container.styleSheet, '', '', false);
			scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
			
			itemList = new ItemList(0, 0, scrollpane.content, container.styleSheet, '', 'constants-container', true);
			var currSprite:CssSprite;
			itemList.margin = 0;
			
			var nm:NameCtrl = new NameCtrl( "", "", "", "", null, null,
								0, 0, body, container.styleSheet, '', '', false, true);
			
			nm.addEventListener( "save", saveNewTemplateHandler );
			nm.addEventListener( "close", closeTemplateHandler );
			nm.showNextButton(false);
			nm.showPrevButton(false);
			nm.showSaveButton(false);
			nm.showDeleteButton(false);
			nameCtrl = nm;
			
			var styl:CssStyleSheet = container.styleSheet;
			
			nm.label.label = Language.getKeyword("New Template");
			nm.textBox.value = "com.yourdomain.themename.v1";
			var tmplTypes:Array = [",","root","content"];
			var prjat:Object={};
			var arr:Vector.<String>;
			var k:int;
			
			if( CTTools.activeTemplate ) {
				var areas:Object = CTTools.activeTemplate.areasByName;
				var a:String;
				var nam:String;
				for(nam in areas) {
					if( areas[nam].types != undefined) {
						arr = areas[nam].types;
						for(k=0;k<arr.length;k++) {
							prjat[arr[k]]=true;
						}
					}
					prjat[areas[nam].type]=true;
				}
				
				for(nam in prjat) tmplTypes.push(nam);
			}
			
			version_pc = new PropertyCtrl( Language.getKeyword("new-template-version"), "new-template-version", "string", "1.0.0", null, null, 0, 0, itemList, styl,'','constant-prop',false);
			type_pc = new PropertyCtrl( Language.getKeyword("new-template-type"), "new-template-type", "listmultiple", "root", null, tmplTypes, 0, 0, itemList, styl,'','constant-prop',false);
			index_pc = new PropertyCtrl( Language.getKeyword("new-template-index-file"), "new-template-index-file", "file", "", null, ["","","Select Index File","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
			files_pc = new PropertyCtrl( Language.getKeyword("new-template-files"), "new-template-files", "vector", "", null,  [0,"File","",",",true,"","","Select folder with static files","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
			folders_pc = new PropertyCtrl( Language.getKeyword("new-template-folders"), "new-template-folders", "vector", "", null,  [0,"Directory","",",",true,"","","Select folder with static files","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
			sortproperties_pc = new PropertyCtrl( Language.getKeyword("new-template-properties"), "new-template-properties", "list", "priority", null, ["name","priority"], 0, 0, itemList, styl,'','constant-prop',false);
			help_pc = new PropertyCtrl( Language.getKeyword("new-template-help"), "new-template-help", "file", "help.xml", null, ["","","Select Content File","*.xml"], 0, 0, itemList, styl,'','constant-prop',false);
			templatefolders_pc = new PropertyCtrl( Language.getKeyword("new-template-templatefolders"), "new-template-templatefolders", "vector", "", null, [0,"File","",",",true,"","","Select static file","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
			listlabel_pc = new PropertyCtrl( Language.getKeyword("new-template-listLabel"), "new-template-listLabel", "string", "", null, null, 0, 0, itemList, styl,'','constant-prop',false);
			
			listicon_pc = new PropertyCtrl( Language.getKeyword("new-template-listicon"), "new-template-listicon", "list", "", null, 
			[[new IconFromFile(Options.iconDir+"/activity-feed.png",Options.iconSize,Options.iconSize),"ico:/activity-feed.png"],
			[new IconFromFile(Options.iconDir+"/audio-book.png",Options.iconSize,Options.iconSize),"ico:/audio-book.png"],
			[new IconFromFile(Options.iconDir+"/aweb.png",Options.iconSize,Options.iconSize),"ico:/aweb.png"],
			[new IconFromFile(Options.iconDir+"/blog.png",Options.iconSize,Options.iconSize),"ico:/blog.png"],
			[new IconFromFile(Options.iconDir+"/cam.png",Options.iconSize,Options.iconSize),"ico:/cam.png"],
			[new IconFromFile(Options.iconDir+"/cap.png",Options.iconSize,Options.iconSize),"ico:/cap.png"],
			[new IconFromFile(Options.iconDir+"/categorize.png",Options.iconSize,Options.iconSize),"ico:/categorize.png"],
			[new IconFromFile(Options.iconDir+"/chat-message.png",Options.iconSize,Options.iconSize),"ico:/chat-message.png"],
			[new IconFromFile(Options.iconDir+"/create.png",Options.iconSize,Options.iconSize),"ico:/create.png"],
			[new IconFromFile(Options.iconDir+"/diamond.png",Options.iconSize,Options.iconSize),"ico:/diamond.png"],
			[new IconFromFile(Options.iconDir+"/diplom.png",Options.iconSize,Options.iconSize),"ico:/diplom.png"],
			[new IconFromFile(Options.iconDir+"/event.png",Options.iconSize,Options.iconSize),"ico:/event.png"],
			[new IconFromFile(Options.iconDir+"/hierarchy.png",Options.iconSize,Options.iconSize),"ico:/hierarchy.png"],
			[new IconFromFile(Options.iconDir+"/image2.png",Options.iconSize,Options.iconSize),"ico:/image2.png"],
			[new IconFromFile(Options.iconDir+"/modul.png",Options.iconSize,Options.iconSize),"ico:/modul.png"],
			[new IconFromFile(Options.iconDir+"/music.png",Options.iconSize,Options.iconSize),"ico:/music.png"],
			[new IconFromFile(Options.iconDir+"/news.png",Options.iconSize,Options.iconSize),"ico:/news.png"],
			[new IconFromFile(Options.iconDir+"/nummerierte-liste.png",Options.iconSize,Options.iconSize),"ico:/nummerierte-liste.png"],
			[new IconFromFile(Options.iconDir+"/octahedron.png",Options.iconSize,Options.iconSize),"ico:/octahedron.png"],
			[new IconFromFile(Options.iconDir+"/page.png",Options.iconSize,Options.iconSize),"ico:/page.png"],
			[new IconFromFile(Options.iconDir+"/panorama.png",Options.iconSize,Options.iconSize),"ico:/panorama.png"]
			], 0, 0, itemList, styl,'','constant-prop',false);
			
			tables_pc = new PropertyCtrl( Language.getKeyword("new-template-tables"), "new-template-tables", "string", "", null, null, 0, 0, itemList, styl,'','constant-prop',false);
			fields_pc = new PropertyCtrl( Language.getKeyword("new-template-fields"), "new-template-fields", "vector", "", null, [0,"typed","",",",true,"AreaList,Audio,Boolean,Code,Color,Directory,File,Files,Hidden,Image,Integer,Intern,List,ListAppend,ListMultiple,LabelList,Label,Name,Number,Pdf,ScreenInteger,ScreenNumber,Section,String,Richtext,Text,Vector,VectorLink,Video"], 0, 0, itemList, styl,'','constant-prop',false);
			
			tables_pc.textBox.addEventListener( "heightChange", heightUpdate);
			fields_pc.textBox.addEventListener( "heightChange", heightUpdate);
			
			articlepage_pc = new PropertyCtrl( Language.getKeyword("new-template-articlepage"), "new-template-articlepage", "string", "", null, [], 0, 0, itemList, styl,'','constant-prop',false);
			articlename_pc = new PropertyCtrl( Language.getKeyword("new-template-articlename"), "new-template-articlename", "string", "", null, [], 0, 0, itemList, styl,'','constant-prop',false);
			parselistlabel_pc = new PropertyCtrl( Language.getKeyword("new-template-parselistlabel"), "new-template-parselistlabel", "boolean", "false", null, [], 0, 0, itemList, styl,'','constant-prop',false);
			nolocation_pc = new PropertyCtrl( Language.getKeyword("new-template-nolocation"), "new-template-nolocation", "boolean", "false", null, [], 0, 0, itemList, styl,'','constant-prop',false);
			hidden_pc = new PropertyCtrl( Language.getKeyword("new-template-hidden"), "new-template-hidden", "boolean", "false", null, [], 0, 0, itemList, styl,'','constant-prop',false);
					
			
			itemList.addItem( version_pc, true );
			itemList.addItem( type_pc, true );
			itemList.addItem( index_pc, true );
			itemList.addItem( files_pc, true );
			itemList.addItem( folders_pc, true );
			itemList.addItem( templatefolders_pc, true );
			itemList.addItem( sortproperties_pc, true );
			itemList.addItem( help_pc, true );
			itemList.addItem( listlabel_pc, true );
			itemList.addItem( listicon_pc, true );
			itemList.addItem( parselistlabel_pc, true );
			itemList.addItem( tables_pc, true );
			itemList.addItem( fields_pc, true );
			itemList.addItem( articlepage_pc, true );
			itemList.addItem( articlename_pc, true );
			itemList.addItem( nolocation_pc, true );
			itemList.addItem( hidden_pc, true );
		
			itemList.format();
			
			files_pc.textBox.addEventListener( "heightChange", heightUpdate);
			folders_pc.textBox.addEventListener( "heightChange", heightUpdate);
			
			newSize();
		}
		
		private static var nameCtrl:NameCtrl=null;
		
		private function heightUpdate (event:Event) :void {
			newSize();
		}
		
		protected function saveNewTemplateHandler (event:Event) :void
		{
			if( nameCtrl )
			{
				var name:String = nameCtrl.textBox.value;
				var type:String = type_pc ? type_pc.textBox.value : "root";
				var index:String = index_pc ? index_pc.textBox.value : "index.html";
				var files:String = files_pc ? files_pc.textBox.value : "";
				var folders:String = folders_pc ? folders_pc.textBox.value : "";
				var tables:String = tables_pc ? tables_pc.textBox.value : "";
				var fields:String = fields_pc ? fields_pc.textBox.value : "";
				var sortproperties:String = sortproperties_pc ? sortproperties_pc.textBox.value  :"";
				var label:String = listlabel_pc ? listlabel_pc.textBox.value : "";
				var icon:String = listlabel_pc ? listicon_pc.textBox.value : "";
				var articlepage:String = articlepage_pc ? articlepage_pc.textBox.value : "";
				var articlename:String = articlename_pc ? articlename_pc.textBox.value : "";
				var parselistlabel:String = parselistlabel_pc ? parselistlabel_pc.textBox.value : "";
				
				if( tables == "" ) {
					tables = CTTools.convertName( name );
				}
				if( fields == "" ) {
					fields = "name";
				}
				var rv:Boolean = TemplateTools.createTemplate ( name, type, index, files, folders, tables, fields, sortproperties, label, icon, articlepage, articlename, CssUtils.stringToBool(parselistlabel) );
				
				showTemplates();
			}
			else
			{
				Console.log("Error create template name ctrl missing");
			}
		}
			
		protected function saveTemplateHandler (event:Event) :void
		{
			// Save to config.xml and reload
			if( nameCtrl && currTemplate )
			{
				var tmpl:Template = currTemplate;
				var rootTmpl:Boolean = tmpl == CTTools.activeTemplate;
				var fileInfo:FileInfo;
				var cfg:File;
				var xo:XML;
				var tmp:String;
				var tmp2:String;
				var tmpArr:Array;
				var file:File;
				var file2:File;
				var L:int;
				var i:int;
				var k:int;
				var version:String;
				var templatefolders:String;
				var homeAreaName:String;
				var help:String;
				var dbcmds:String;
				var type:String;
				var files:String;
				var folders:String;
				var hiddenareas:String;
				var nocompress:String;
				var nolocareas:String;
				var nolocation:String;
				var hidden:String;
				var pagetemplates:String;
				var staticfiles:String;
				var defaultcontent:String;
				var sortareas:String;
				var sortproperties:String;
				var indexFileName:String;
				var listlabel:String;
				var listicon:String;
				var parselistlabel:String;
				var tables:String;
				var fields:String;
				var articlepage:String;
				var articlename:String;
				var new_cfg:String;
				var tmplDir:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator;
				
				if( rootTmpl )
				{
					cfg = new File( tmplDir + CTOptions.urlSeparator + CTOptions.templateIndexFile );
					
					if( cfg.exists ) {
						try {
							xo = new XML( CTTools.readTextFile( cfg.url ) );
						}catch(e:Error) {
							Console.log( "config.xml parse error");
						}
						if( xo )
						{
							
							/*
							index_pc = new PropertyCtrl( Language.getKeyword("new-template-index-file"), "new-template-index-file", "file", tmpl.indexFile, null, ["","","Select Index File","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
							files_pc = new PropertyCtrl( Language.getKeyword("new-template-files"), "new-template-files", "vector", tmpl.files, null,  [0,"Files","",",",true,"","","Select folder with static files","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
							folders_pc = new PropertyCtrl( Language.getKeyword("new-template-folders"), "new-template-folders", "vector", tmpl.folders, null,  [0,"Directory","",",",true,"","","Select folder","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
							sortproperties_pc = new PropertyCtrl( Language.getKeyword("new-template-sortproperties"), "new-template-sortproperties", "list", tmpl.sortproperties, null, ["name","priority"], 0, 0, itemList, styl,'','constant-prop',false);
							hiddenareas_pc = new PropertyCtrl( Language.getKeyword("new-template-hiddenareas"), "new-template-hiddenareas", "vector", tmpl.hiddenareas, null, [0,"String","",",",true], 0, 0, itemList, styl,'','constant-prop',false);
							defaultcontent_pc = new PropertyCtrl( Language.getKeyword("new-template-defaultcontent"), "new-template-defaultcontent", "file", tmpl.defaultcontent, null, ["","","Select Content File","*.xml"], 0, 0, itemList, styl,'','constant-prop',false);
							nocompress_pc = new PropertyCtrl( Language.getKeyword("new-template-nocompress"), "new-template-nocompress", "vector", tmpl.nocompress, null, [0,"String","",",",true], 0, 0, itemList, styl,'','constant-prop',false);
							nolocareas_pc = new PropertyCtrl( Language.getKeyword("new-template-nolocareas"), "new-template-nolocareas", "vector", tmpl.nolocareas, null, [0,"String","",",",true], 0, 0, itemList, styl,'','constant-prop',false);
							pagetemplates_pc = new PropertyCtrl( Language.getKeyword("new-template-pagetemplates"), "new-template-pagetemplates", "vector", tmpl.pagetemplates, null, [0,"Files","",",",true,"","","Select page template","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
							staticfiles_pc = new PropertyCtrl( Language.getKeyword("new-template-staticfiles"), "new-template-staticfiles", "vector", tmpl.staticfiles, null, [0,"Files","",",",true,"","","Select static file","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
							*/
							
							indexFileName = copyTemplateFile( tmplDir, index_pc.textBox.value, "<!-- Index.html -->");
							
							files = "";
							tmp = files_pc.textBox.value;
							tmpArr = tmp.split(",");
							L = tmpArr.length;
							for( i=0; i<L; i++ ) {
								tmp2 = copyTemplateFile( tmplDir, tmpArr[i], "");
								if( tmp2 != "" ) files += tmp2 + ",";
							}
							if( files.length > 1 ) files = files.substring( 0, files.length-1 );
							
							folders = "";
							tmp = folders_pc.textBox.value;
							tmpArr = tmp.split(",");
							L = tmpArr.length;
							for( i=0; i<L; i++ ) {
								tmp2 = copyStaticFolder( CTTools.projectDir + CTOptions.urlSeparator, tmpArr[i]);
								if( tmp2 != "" ) folders += tmp2  + ",";
							}
							if( folders.length > 1 ) folders = folders.substring( 0, folders.length-1 );
							
							hiddenareas = "";
							tmp = hiddenareas_pc.textBox.value;
							tmpArr = tmp.split(",");
							L = tmpArr.length;
							for( i=0; i<L; i++ ) {
								tmp2 = tmpArr[i];
								if( tmp2 != "" ) hiddenareas += tmp2 +",";
							}
							if( hiddenareas.length > 1 ) hiddenareas = hiddenareas.substring( 0, hiddenareas.length-1 );
							
							nocompress = "";
							tmp = nocompress_pc.textBox.value;
							tmpArr = tmp.split(",");
							L = tmpArr.length;
							for( i=0; i<L; i++ ) {
								tmp2 = tmpArr[i];
								if( tmp2 != "" ) nocompress += tmp2 +",";
							}
							if( nocompress.length > 1 ) nocompress = nocompress.substring( 0, nocompress.length-1 );
							
							nolocareas = "";
							tmp = nolocareas_pc.textBox.value;
							tmpArr = tmp.split(",");
							L = tmpArr.length;
							for( i=0; i<L; i++ ) {
								tmp2 = tmpArr[i];
								if( tmp2 != "" ) nolocareas += tmp2 + ",";
							}
							if( nolocareas.length > 1 ) nolocareas = nolocareas.substring( 0, nolocareas.length-1 );
							
							templatefolders = "";
							tmp = templatefolders_pc.textBox.value;
							tmpArr = tmp.split(",");
							L = tmpArr.length;
							for( i=0; i<L; i++ ) {
								tmp2 = copyTemplateFolder( tmplDir, tmpArr[i]);
								if( tmp2 != "" ) templatefolders += tmp2 + ",";
							}
							if( templatefolders.length > 1 ) templatefolders = templatefolders.substring( 0, templatefolders.length-1 );
							
							pagetemplates = "";
							tmp = pagetemplates_pc.textBox.value;
							tmpArr = tmp.split(",");
							L = tmpArr.length;
							for( i=0; i<L; i++ ) {
								tmp2 = copyTemplateFile( tmplDir, tmpArr[i], "");
								if( tmp2 != "" ) pagetemplates += tmp2 + ",";
							}
							if( pagetemplates.length > 1 ) pagetemplates = pagetemplates.substring( 0, pagetemplates.length-1 );
							
							staticfiles = "";
							tmp = staticfiles_pc.textBox.value;
							tmpArr = tmp.split(",");
							L = tmpArr.length;
							for( i=0; i<L; i++ ) {
								tmp2 = copyStaticFile( tmpArr[i], "");
								if( tmp2 != "" ) staticfiles += tmp2 + ",";
							}
							if( staticfiles.length > 1 ) staticfiles = staticfiles.substring( 0, staticfiles.length-1 );
							
							
							dbcmds = copyTemplateFile( tmplDir, dbcmds_pc.textBox.value, "");
							help = copyTemplateFile( tmplDir, help_pc.textBox.value, "");
							defaultcontent = copyTemplateFile( tmplDir, defaultcontent_pc.textBox.value, "");
							sortproperties = sortproperties_pc.textBox.value;
							sortareas = sortareas_pc.textBox.value;
							version = version_pc.textBox.value;
							homeAreaName = homeAreaName_pc.textBox.value;
							
							new_cfg = '<?xml version="1.0" encoding="utf-8" ?>\n<ct>\n  <template name="' +nameCtrl.textBox.value+ '" type="root" \n   version="' + version + '" \n   index="'+indexFileName+'" \n   files="'+files+'" \n   folders="'+folders+'"';
							
							new_cfg += '\n   hiddenareas="'+hiddenareas+'" \n   nocompress="'+nocompress+'" \n   nolocareas="'+nolocareas+'" \n   pagetemplates="'+pagetemplates+'" '; 
							new_cfg += '\n   staticfiles="'+staticfiles+'" \n   defaultcontent="'+defaultcontent+'" \n   sortproperties="'+sortproperties +
										'" \n   sortareas="'+ sortareas +
										'" \n   dbcmds="'+ dbcmds +
										'" \n   templatefolders="' + templatefolders +
										'" \n   help="'+ help +
										'" \n   homeAreaName="'+ homeAreaName +
										'" \n   update="'+(xo.template.@update == undefined ? "" : xo.template.@update.toString()) + 
										'"\n   ></template>'; 
							new_cfg += '\n</ct>\n';
							
							Console.log("New Config: "  + cfg.url + ": \n" + new_cfg);
							
							CTTools.writeTextFile( cfg.url, new_cfg);
							
							Application.command( "restart" );
						}
					}
				}
				else
				{
					
			/*
			type_pc = new PropertyCtrl( Language.getKeyword("new-template-type"), "new-template-type", "listmultiple", "root", null, tmplTypes, 0, 0, itemList, styl,'','constant-prop',false);
			index_pc = new PropertyCtrl( Language.getKeyword("new-template-index-file"), "new-template-index-file", "file", "", null, ["","","Select Index File","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
			files_pc = new PropertyCtrl( Language.getKeyword("new-template-files"), "new-template-files", "vector", "", null,  [0,"File","",",",true,"","","Select folder with static files","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
			folders_pc = new PropertyCtrl( Language.getKeyword("new-template-folders"), "new-template-folders", "vector", "", null,  [0,"Directory","",",",true,"","","Select folder with static files","*.*"], 0, 0, itemList, styl,'','constant-prop',false);
			sortproperties_pc = new PropertyCtrl( Language.getKeyword("new-template-properties"), "new-template-properties", "list", "priority", null, ["name","priority"], 0, 0, itemList, styl,'','constant-prop',false);
			listlabel_pc = new PropertyCtrl( Language.getKeyword("new-template-listLabel"), "new-template-listLabel", "string", "", null, null, 0, 0, itemList, styl,'','constant-prop',false);
			listicon_pc = new PropertyCtrl( Language.getKeyword("new-template-listicon"), "new-template-listicon", "list", "", null, 
			tables_pc = new PropertyCtrl( Language.getKeyword("new-template-tables"), "new-template-tables", "string", "", null, null, 0, 0, itemList, styl,'','constant-prop',false);
			fields_pc = new PropertyCtrl( Language.getKeyword("new-template-fields"), "new-template-fields", "vector", "", null, [0,"typed","",",",true,"AreaList,Audio,Boolean,Code,Color,Directory,File,Files,Hidden,Image,Integer,Intern,List,ListAppend,ListMultiple,LabelList,Label,Name,Number,Pdf,ScreenInteger,ScreenNumber,Section,String,Richtext,Text,Vector,VectorLink,Video"], 0, 0, itemList, styl,'','constant-prop',false);
			articlepage_pc = new PropertyCtrl( Language.getKeyword("new-template-articlepage"), "new-template-articlepage", "string", "", null, [], 0, 0, itemList, styl,'','constant-prop',false);
			articlename_pc = new PropertyCtrl( Language.getKeyword("new-template-articlename"), "new-template-articlename", "string", "", null, [], 0, 0, itemList, styl,'','constant-prop',false);
			parselistlabel_pc = new PropertyCtrl( Language.getKeyword("new-template-parselistlabel"), "new-template-parselistlabel", "boolean", "false", null, [], 0, 0, itemList, styl,'','constant-prop',false);
			*/
					var subtdir:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + 
									CTOptions.subtemplateFolder + CTOptions.urlSeparator + tmpl.name + CTOptions.urlSeparator;
					
					cfg = new File( subtdir + CTOptions.templateIndexFile );

					try {
						xo = new XML( CTTools.readTextFile( cfg.url ) );
					}catch(e:Error) {
						Console.log( "config.xml parse error");
					}
					
					indexFileName = copyTemplateFile( subtdir, index_pc.textBox.value, "<!-- Index file -->");
					
					files = "";
					tmp = files_pc.textBox.value;
					tmpArr = tmp.split(",");
					L = tmpArr.length;
					for( i=0; i<L; i++ ) {
						tmp2 = copyTemplateFile( subtdir, tmpArr[i], "");
						if( tmp2 != "" ) files += tmp2 + ",";
					}
					if( files.length > 1 ) files = files.substring( 0, files.length-1 );
					
					folders = "";
					tmp = folders_pc.textBox.value;
					tmpArr = tmp.split(",");
					L = tmpArr.length;
					for( i=0; i<L; i++ ) {
						tmp2 = copyStaticFolder(  CTTools.projectDir + CTOptions.urlSeparator, tmpArr[i] );
						if( tmp2 != "" ) folders += tmp2  + ",";
					}
					if( folders.length > 1 ) folders = folders.substring( 0, folders.length-1 );
					
					templatefolders = "";
					tmp = templatefolders_pc.textBox.value;
					tmpArr = tmp.split(",");
					L = tmpArr.length;
					for( i=0; i<L; i++ ) {
						tmp2 = copyTemplateFolder( subtdir, tmpArr[i]);
						if( tmp2 != "" ) templatefolders += tmp2 + ",";
					}
					if( templatefolders.length > 1 ) templatefolders = templatefolders.substring( 0, templatefolders.length-1 );
					
					fields = "";
					tmp = fields_pc.textBox.value;
					tmpArr = tmp.split(",");
					L = tmpArr.length;
					for( i=0; i<L; i++ ) {
						k = tmpArr[i].indexOf(":");
						if( k >= 0 ) {
							fields += tmpArr[i].substring( k +1 ) + ",";
						}else{
							fields += tmpArr[i] + ",";
						}
					}
					if( fields.length > 1 ) fields = fields.substring( 0, fields.length-1 );
					
					help = copyTemplateFile( subtdir, help_pc.textBox.value, "");
					type = type_pc.textBox.value;
					listlabel = listlabel_pc.textBox.value;
					listicon = listicon_pc.textBox.value;
					parselistlabel = parselistlabel_pc.textBox.value;
					
					articlepage = copyTemplateFile( subtdir, articlepage_pc.textBox.value, "");
					
					articlename = articlename_pc.textBox.value;
					parselistlabel = parselistlabel_pc.textBox.value;
					sortproperties = sortproperties_pc.textBox.value;
					tables = tables_pc.textBox.value;
					
					if( tables == "" ) {
						tables = CTTools.convertName( nameCtrl.textBox.value );
					}
					
					if( fields == "" ) {
						fields = "name";
					}
					
					version = version_pc.textBox.value;
					nolocation = nolocation_pc.textBox.value;
					hidden = hidden_pc.textBox.value;
					
					new_cfg = '<?xml version="1.0" encoding="utf-8" ?>\n<ct>\n  <template name="' +nameCtrl.textBox.value+ '" type="'+type+'" \n   version="' + version + '" \n   index="'+indexFileName+'" \n   files="'+files+'" \n   folders="'+folders+'"';
					
					new_cfg +='\n   sortproperties="'+sortproperties +
							'" \n   templatefolders="' + templatefolders +
							'" \n   help="'+ help +
							'" \n   tables="'+ tables +
							'" \n   fields="'+ fields +
							'" \n   listlabel="'+ listlabel +
							'" \n   listicon="'+ listicon +
							'" \n   articlepage="'+ articlepage +
							'" \n   articlename="'+ articlename +
							'" \n   parselistlabel="'+ parselistlabel +
							'" \n   nolocation="'+ nolocation +
							'" \n   hidden="'+ hidden;
							
					if( xo ) {
							new_cfg += '" \n   staticfiles="'+(xo.template.@staticfiles == undefined ? "" : xo.template.@staticfiles.toString()) + 
							'" \n   section="'+(xo.template.@section == undefined ? "" : xo.template.@section.toString()) + 
							'" \n   initquery="'+(xo.template.@initquery == undefined ? "" : xo.template.@initquery.toString()) + 
							'" \n   defaultquery="'+(xo.template.@defaultquery == undefined ? "" : xo.template.@defaultquery.toString()) + 
							'"\n   >';
					}else{
						new_cfg += '"\n   >';
					}
					if( xo ) {
						var embedstyle:XMLList = xo.template.embedstyle;
						if( embedstyle == embedstyle.length() > 0 ) {
							for( i=0; i<embedstyle.length(); i++ ) {
								new_cfg += '\n      <embedstyle name="'+ (embedstyle[i].@name == undefined ? "style"+i : embedstyle[i].@name )+'" src="'+
								(embedstyle[i].@src == undefined ? "" : embedstyle[i].@src ) +'" area="'+
								(embedstyle[i].@area == undefined ? "STYLE-BEGIN" : embedstyle[i].@area ) +'" priority="'+
								(embedstyle[i].@priority == undefined ? "0" : embedstyle[i].@priority ) +'"/>';
							}
						}
						var embedscript:XMLList = xo.template.embedscript;
						if( embedscript == embedscript.length() > 0 ) {
							for( i=0; i<embedscript.length(); i++ ) {
								new_cfg += '\n      <embedscript name="'+ (embedscript[i].@name == undefined ? "style"+i : embedscript[i].@name )+'" src="'+
								(embedscript[i].@src == undefined ? "" : embedscript[i].@src ) +'" area="'+
								(embedscript[i].@area == undefined ? "STYLE-BEGIN" : embedscript[i].@area ) +'" priority="'+
								(embedscript[i].@priority == undefined ? "0" : embedscript[i].@priority ) +'"/>';
							}
						}
					}
					new_cfg += '\n</template>'; 
					new_cfg += '\n</ct>\n';
					
					Console.log("New Config: "  + cfg.url + ": \n" + new_cfg);
					
					CTTools.writeTextFile( cfg.url, new_cfg);
					
					setTimeout( function () {
						Application.instance.cmd( "CTTools subtemplate template:/st/" + nameCtrl.textBox.value, showTemplates );
					}, 150);
					return;
				}
			}
			
			showTemplates();
		}
		
		private function copyStaticFolder ( dir:String, path:String ) :String
		{
			if(!dir || !path ) return "";
			
			var fileInfo:FileInfo;
			var tmp2:String;
			var tmpArr:Array;
			var file:File;
			var file2:File;	
			
			fileInfo = FileUtils.fileInfo( path );
			
			tmp2 = path.substring( 0, 7 );
			
			if( tmp2 == "file://" ) {
				file = new File( path );
				
				if( file.exists )
				{
					// copy file to web dirs:
					CTTools.copyFolder( path, dir + CTOptions.projectFolderRaw + CTOptions.urlSeparator + fileInfo.filename );
					CTTools.copyFolder( path, dir + CTOptions.projectFolderMinified + CTOptions.urlSeparator + fileInfo.filename );
				}
				else
				{
					// create new default folder..					
					file2 = new File( dir + CTOptions.projectFolderRaw + CTOptions.urlSeparator + fileInfo.filename );
					file2.createDirectory();
					
					file2 = new File( dir + CTOptions.projectFolderMinified + CTOptions.urlSeparator + fileInfo.filename );
					file2.createDirectory();
				}
			}else if( tmp2 == "http://" || tmp2 == "https:/" ) {
				// TODO copy http file to tmpl dir:
				
			}else{
				
				file2 = new File( dir + CTOptions.projectFolderRaw + CTOptions.urlSeparator + fileInfo.filename );
				if( ! file2.exists ) {
					file2.createDirectory();
				}
				file2 = new File( dir + CTOptions.projectFolderMinified + CTOptions.urlSeparator + fileInfo.filename );
				if( ! file2.exists ) {
					file2.createDirectory();
				}
			}
			return fileInfo.filename;
		}
		
		private function copyTemplateFolder ( tmplDir:String, path:String ) :String
		{
			if( !path ) return "";
			
			var fileInfo:FileInfo;
			var tmp2:String;
			var tmpArr:Array;
			var file:File;
			var file2:File;	
			
			fileInfo = FileUtils.fileInfo( path );
			
			tmp2 = path.substring( 0, 7 );
			
			if( tmp2 == "file://" ) {
				file = new File( tmp2 );
				
				if( file.exists )
				{
					// copy file to tmpl dir:
					CTTools.copyFolder( path, tmplDir + fileInfo.filename );
				}
				else
				{
					// create new default folder..
					file.createDirectory();
				}
			}else if( tmp2 == "http://" || tmp2 == "https:/" ) {
				// TODO copy http file to tmpl dir:
				
			}else{
				
				file2 = new File( tmplDir + fileInfo.filename );
				if( ! file2.exists ) {
					file2.createDirectory();
				}
			}
			return fileInfo.filename;
		}
		
		private function copyTemplateFile ( tmplDir:String, path:String, content:String="" ) :String
		{
			if( !path ) return "";
			
			var fileInfo:FileInfo;
			var tmp2:String;
			var tmpArr:Array;
			var file:File;
			var file2:File;
						
			fileInfo = FileUtils.fileInfo( path );
			
			tmp2 = path.substring( 0, 7 );
			
			if( tmp2 == "file://" ) {
				
				file = new File( path );
				
				if( file.exists )
				{
					// copy file to tmpl dir:
					CTTools.copyFile( path, tmplDir + fileInfo.filename );
				}
				else
				{
					// create new default file..					
					CTTools.writeTextFile(tmplDir + fileInfo.filename, content);
				}
			}else if( tmp2 == "http://" || tmp2 == "https:/" ) {
				// TODO copy http file to tmpl dir:
				
			}else{
				// value is relative to tmpl dir.. test if file exists or create default file..
				file2 = new File( tmplDir + fileInfo.filename );
				if( ! file2.exists ) {
					CTTools.writeTextFile(tmplDir + fileInfo.filename, content);
				}
			}
			return fileInfo.filename;
		}
		
		private function copyStaticFile ( path:String, content:String="" ) :String
		{
			if( !path ) return "";
			
			var fileInfo:FileInfo;
			var tmp2:String;
			var tmpArr:Array;
			var file:File;
			var file2:File;
			
			var dir:String = CTTools.projectDir + CTOptions.urlSeparator;
							
			fileInfo = FileUtils.fileInfo( path );
			
			tmp2 = path.substring( 0, 7 );
			
			if( tmp2 == "file://" ) {
				
				file = new File( path );
				
				if( file.exists )
				{
					// copy file to web dirs:
					CTTools.copyFile( path, dir + CTOptions.projectFolderRaw + CTOptions.urlSeparator + fileInfo.filename );
					CTTools.copyFile( path, dir + CTOptions.projectFolderMinified + CTOptions.urlSeparator + fileInfo.filename );
				}
				else
				{
					// create new default file..
					CTTools.writeTextFile(dir + CTOptions.projectFolderRaw + CTOptions.urlSeparator + fileInfo.filename, content);
					CTTools.writeTextFile(dir + CTOptions.projectFolderMinified + CTOptions.urlSeparator + fileInfo.filename, content);
				}
			}else if( tmp2 == "http://" || tmp2 == "https:/" ) {
				// TODO copy http file to tmpl dir:
				
			}else{
				// value is relative to web dir.. test if file exists or create default file..
				file2 = new File( dir + CTOptions.projectFolderRaw + CTOptions.urlSeparator + fileInfo.filename );
				if( ! file2.exists ) {
					CTTools.writeTextFile(dir + CTOptions.projectFolderRaw + CTOptions.urlSeparator + fileInfo.filename, content);
					CTTools.writeTextFile(dir + CTOptions.projectFolderMinified + CTOptions.urlSeparator + fileInfo.filename, content);
				}
			}
			return fileInfo.filename;
		}
		
		protected function closeTemplateHandler (event:Event) :void
		{
			showTemplates();
		}
			
		//protected function deleteTemplateHandler (event:Event) :void {
			// trace("Delete Template..");
		//}
		
	}
}
