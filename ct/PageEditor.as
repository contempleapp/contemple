package ct
{
	import agf.utils.StringMath;
	import flash.display.*;
	import flash.text.*;
	import agf.Main;
	import agf.html.*;
	import agf.events.*;
	import agf.ui.*;
	import flash.events.*;
	import agf.icons.IconArrowDown;
	import agf.tools.Application;
	import flash.filesystem.File;
	import ct.ctrl.InputTextBox;
	import agf.db.DBResult;
	import agf.tools.Console;
	import ct.ctrl.*;
	import agf.html.CssSprite;
	
	public class PageEditor extends CssSprite {

		public function PageEditor(w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false)
		{
			super(w,h,parentCS,style,name,id,classes,noInit);
			
			container = Application.instance.view.panel;
			container.addEventListener(Event.RESIZE, newSize);
			
			Application.instance.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
			
			showPages();
		
			if( CTOptions.animateBackground ) {
				HtmlEditor.dayColorClip( body.bgSprite );
			}
		}
		public var container: Panel;
		
		public var title:Label;
		public var scrollpane:ScrollContainer;
		public var itemList:ItemList;
		public var cont:CssSprite;
		public var body:CssSprite;
		public var plusButton:Button;
		private var pageName:NameCtrl;
		private var pageTitle:PropertyCtrl;
		private var pageType:PropertyCtrl;
		private var pageTemplate:PropertyCtrl;
		private var pageParent:PropertyCtrl;
		private var pageWebDir:PropertyCtrl;
		private var pageCtrls:Vector.<PageCtrl>;
		private var pagesCreated:Boolean = false;
		
		internal static var clickScrolling:Boolean=false;
		private var clickY:Number=0;
		
		private function removePanel (e:Event) :void {
			Main(Application.instance).view.removeEventListener( AppEvent.VIEW_CHANGE, removePanel );
			if( pagesCreated ) {
				Application.instance.cmd( "Application restart");
			}
		}
		
		public function abortClickScrolling () :void {
			clickScrolling=false;
		}
		
		public function newSize(e:Event=null): void {
			if (container && cont && body)
			{
				var w:int = container.getWidth();
				var h:int = container.getHeight();
				
				cont.setWidth(w - cont.cssBoxX);
				cont.setHeight(h - cont.cssBoxY);
				
				body.setWidth(w - body.cssBoxX);
				body.setHeight(h - body.cssBoxY);
				
				var sbw:int = 0;
				if( scrollpane ) {
					if( scrollpane.slider.visible ) sbw = 16;
					if( title ) {
						title.setWidth( w );
						
						scrollpane.setWidth( w - body.cssBoxX );
						scrollpane.setHeight( h - scrollpane.y );
						scrollpane.contentHeightChange();
					}
					scrollpane.setWidth(w);
				}
				
				if( itemList) {
					if(itemList.items) {
						for( var i:int=0; i < itemList.items.length; i++) {
							itemList.items[i].setWidth( w - ( itemList.items[i].cssBoxX + body.cssBoxX + sbw ) );
						}
					}
					itemList.setWidth(0);
					itemList.init();
				}
			}
		}
		
		public function create () :void 
		{
			if( cont ) {
				if( body ) { 
					if( title && body.contains(title) ) body.removeChild(title);
					if( plusButton && body.contains(plusButton) ) body.removeChild(plusButton);
					if( scrollpane && body.contains(scrollpane) ) body.removeChild(scrollpane);
					if( cont.contains(body) ) cont.removeChild(body);
					body = null;
				}
				if( contains(cont) ) removeChild(cont);
				cont = null;
			}
			
			if( container ) {
				cont = new CssSprite( container.getWidth(), container.getHeight(), null, styleSheet, 'body', '', '', true);
				addChild(cont);
				cont.init();
				
				body = new CssSprite( container.getWidth(), container.getHeight(), cont, container.styleSheet, 'div', '', 'editor page-editor', false);
			}
		}
		
		private function plusClick (e:MouseEvent) :void {
			showInsertPageForm();
		}
		
		public function showPages ():void {
		
			var w:Number = container.getWidth();
			create();
			
			title = new Label( w, 20, body, container.styleSheet, '', 'pages-title', false);
			title.label = Language.getKeyword( "Pages" );
			title.x = body.cssLeft + title.cssMarginLeft;
			title.y = body.cssTop + title.cssMarginTop;
			title.setHeight( title.textField.textHeight );
			
			plusButton = new Button( [ "New Page" ], 0, 0, body, container.styleSheet, '', 'pageeditor-plusbutton', false);
			plusButton.addEventListener( MouseEvent.CLICK, plusClick );
			plusButton.x = body.cssLeft + plusButton.cssMarginLeft;
			plusButton.y = body.cssTop + plusButton.cssMarginTop + title.cssSizeY + title.cssMarginBottom;
			
			scrollpane = new ScrollContainer(w,0,body,container.styleSheet,'','pageeditor-container',false);
			scrollpane.y = plusButton.y + plusButton.cssSizeY + plusButton.cssMarginBottom;
			scrollpane.x = body.cssLeft;
			
			itemList = new ItemList(0,0,scrollpane.content,container.styleSheet,'','pageeditor-list',true);
			
			var pages:Array = CTTools.pages;
			var L:int = pages.length;
			
			pageCtrls = new Vector.<PageCtrl>;
			
			var pgc:PageCtrl;
			var yp:Number = plusButton.cssSizeY;
			var margin:Number = 2;
			
			for(var i:int = 0; i < pages.length; i++)
			{
				pgc = new PageCtrl( pages[i].name, pages[i].title, pages[i].type, pages[i].template, pages[i].crdate, pages[i].uid, 0,0, itemList, container.styleSheet, '', 'show-page-ctrl', false);
				pageCtrls.push( pgc );
				itemList.addItem( pgc );
				pgc.setWidth( w );
				pgc.addEventListener( MouseEvent.CLICK, editPageHandler );
			}
			
			itemList.format();
			itemList.init();
			
			body.setChildIndex( plusButton, body.numChildren-2 );
			body.setChildIndex( title, body.numChildren-1 );
			
			newSize();
		}
			
		private function editPageHandler (e:MouseEvent) :void {
			var it:PageCtrl = PageCtrl( e.currentTarget );
			if(it && CTTools.pages ) {
				var id:int=-1;
				for(var i:int=0; i < CTTools.pages.length; i++) {
					if( CTTools.pages[i].name == it._name ) {
						id = i;
						break;
					}
				}
				if( id >= 0 ) {
					showInsertPageForm(id);
				}
			}
		}
		
		public function showInsertPageForm (page:int=-1):void
		{
			create();
			
			var templates:Array = [];
			var pgtmpl:String = CTTools.activeTemplate.pagetemplates;
			var pgt:Array;
			var i:int;
			
			pgt = pgtmpl.split(",");
			for(i=0; i< pgt.length; i++) {
				templates.push( pgt[i] );
			}
			
			scrollpane = new ScrollContainer(0,0,body,styleSheet,'','pageeditor-container',false);
			scrollpane.y = body.cssTop;
			scrollpane.x = body.cssLeft;
			
			itemList = new ItemList(0,0,scrollpane.content,container.styleSheet,'','pageeditor-list',true);
			
			pageName = new NameCtrl( "Name", "name", "name", "", null, null, 0, 32, itemList, container.styleSheet, '', 'area-insert-prop', false);
			
			if( page == -1 ){
				pageName.showDeleteButton(false);// .visible = false;
				pageName.label.label = Language.getKeyword( "New Page") + ":";
				pageName.textBox.value = "Page_" + CTTools.pages.length;
			}else{
				pageName.label.label = Language.getKeyword( "Edit Page") + ":";
				pageName.addEventListener( "delete", deleteClick );
				// disable name changes:
				pageName.textBox.textField.type = TextFieldType.DYNAMIC;
			}
			
			pageName.showSaveAndCloseButton(false);// .visible = false;
			pageName.showNextButton(false);
			pageName.showPrevButton(false);
			
			pageName.addEventListener( "saveInline", saveClick );
			pageName.addEventListener( "close", closeClick);
			
			
			pageType = new PropertyCtrl( "Type", "pageType", "list", "Dynamic", null, ["Dynamic","Static","External","Internal","Article"], 0, 0, itemList, container.styleSheet,'','',false);
			pageTitle = new PropertyCtrl( "Title", "pageTitle", "string", "New Title", null, [], 0, 0, itemList, container.styleSheet,'','',false);
			pageTemplate = new PropertyCtrl( "Template", "pageTemplate", "list", templates.length > 0 ? templates[0] : "", null, templates, 0, 0, itemList, container.styleSheet,'','',false);
			pageWebDir = new PropertyCtrl( "Directory", "pageWebDir", "string", "/", null, [], 0, 0, itemList, container.styleSheet,'','',false);
			pageParent = new PropertyCtrl( "Parent", "pageParent", "pagelist", "", null, [], 0, 0, itemList, container.styleSheet,'','',false);
			
			itemList.addItem( pageName );
		
			if( CTOptions.pageTypeEnabled )  itemList.addItem( pageType );
			else pageType.visible = false;
			
			if( CTOptions.pageTitleEnabled ) itemList.addItem( pageTitle );
			else pageTitle.visible = false;
			
			if( CTOptions.pageTemplateEnabled ) itemList.addItem( pageTemplate );
			else pageTemplate.visible = false;
			
			if( CTOptions.pageParentEnabled ) itemList.addItem( pageParent );
			else pageParent.visible = false;
			
			if( CTOptions.pageWebdirEnabled ) itemList.addItem( pageWebDir );
			else pageWebDir.visible = false;
			
			itemList.format();
			itemList.init();
			
			scrollpane.contentHeightChange();
			
			if( page >= 0 ) {
				if( CTTools.pages && page < CTTools.pages.length ) {
					var pg:Page = CTTools.pages[page];
					pageName.textBox.value = pg.name;
					if( !pg.visible ) {
						pageName.visibleStatus = false;
					}
					pageType.textBox.value = pg.type;
					pageTitle.textBox.value = pg.title;
					pageTemplate.textBox.value = pg.template;
				}
			}
			newSize();
		}
		
		private function deleteClick (e:Event) :void
		{
			deletePage( pageName.textBox.value, deleteCompleteFunc );
			
		}
		private function deleteCompleteFunc ( success:Boolean ) :void {
			showPages();
		}
		
		public static function deletePage (name:String, completeHandler:Function=null):void 
		{
			_name = name;
			_complete = completeHandler;
			
			var pms:Object = {};
			pms[":name"] = name;
			
			if( ! CTTools.db.deleteQuery( deletePageHandler, "page", "name=:name", pms) ) {
				Console.log( "Error: Delete Page");
				if( typeof(_complete) == "function" ) _complete( false );
				return;
			}
			Application.instance.showLoading();
		}
		
		private static function deletePageHandler (res:DBResult) :void
		{
			if( res && res.rowsAffected ) {
				CTTools.clearPage( _name );
				if( typeof(_complete) == "function" ) _complete( true );
			}else if( typeof(_complete) == "function" ) _complete( false );
			
			Application.instance.hideLoading();
		}
		
		private function closeClick (e:Event) :void {
			showPages();
		}
		
		 
		internal static var _ltPage:Page=null;
		internal static var _name:String;
		internal static var _visible:Boolean
		internal static var _title:String;
		internal static var _type:String;
		internal static var _template:String;
		internal static var _parent:String;
		internal static var _webdir:String;
		internal static var _date:String="now";
		internal static var _complete:Function=null;
		internal static var _props:Object=null;
		
		private function saveCompleteFunc ( success:Boolean ) :void {
			if( success && !pagesCreated ) pagesCreated = true;
			showPages();
		}
		
		private function saveClick (e:Event) :void {
			if( pageName )
			{
				if(!pageName.textBox.value ) {
					pageName.textBox.value = "New-Page";
				}
				createPage( pageName.textBox.value, 
						pageName.visibleStatus, 
						pageTitle.textBox.value,
						pageType.textBox.value,
						pageTemplate.textBox.value,
						pageParent.textBox.value,
						pageWebDir.textBox.value,
						"now", saveCompleteFunc, null );
			}
		}
		
		public static function createPage ( name:String, visible:Boolean, title:String, type:String,
											template:String, parent:String, webdir:String,
											date:String = "now", completeHandler:Function = null, props:Object = null) :Boolean
		{
			_name = name;
			_visible = visible;
			_title = title;
			_type = type;
			_template = template;
			_parent = parent;
			_webdir = webdir;
			_date = date;
			_complete = completeHandler;
			_props = props;
			_ltPage = null;
			
			var pms:Object = {};
			pms[":name"] = _name;
			
			if( ! CTTools.db.selectQuery( insertPageSelectHandler, "uid,name", "page", "name=:name", '', '', '', pms) )
			{
				Console.log("Error: Insert Page Select " + _name );
				
				if( typeof(_complete) == "function" ) _complete( false );
				return false;
			}
			
			Application.instance.showLoading();
			return true;
		}
		
		private static var ltFilename:String="";
		
		private static function insertPageSelectHandler (res:DBResult) :void {
			var pms:Object = {};
			pms[":name"] = _name;
			pms[":visible"] = _visible;
			pms[":title"] = _title;
			pms[":type"] = _type;
			pms[":template"] = _template;
			pms[":parent"] = _parent;
			pms[":webdir"] = _webdir;
			pms[":date"] = _date;
			
			var est:int = _template.lastIndexOf(".");
			
			if( est >= 0 ) {
				pms[":filename"] = _name.toLowerCase() + _template.substring(est).toLowerCase();
			}else{
				pms[":filename"] = _name.toLowerCase();
			}
			ltFilename = pms[":filename"];
			
			if( res && res.data && res.data.length > 0 )
			{
				// Update
				
				var L:int;
				var i:int;
				
				if( pms[":type"].toLowerCase() == "article" ) {
					L = CTTools.articlePages.length;
					for( i = 0; i < L; i++)
					{
						if(CTTools.articlePages[i].uid == res.data[0].uid )
						{
							CTTools.articlePages[i].name = pms[":name"];
							CTTools.articlePages[i].title = pms[":title"];
							CTTools.articlePages[i].type = pms[":type"];
							CTTools.articlePages[i].template = pms[":template"];
							CTTools.articlePages[i].parent = pms[":parent"];
							CTTools.articlePages[i].webdir = pms[":webdir"];
							CTTools.articlePages[i].filename = ltFilename;
							_ltPage = CTTools.articlePages[i];
							CTTools.createPage( CTTools.articlePages[i], _props );
							break;
						}
					}

				}else{
					L = CTTools.pages.length;
					for( i = 0; i < L; i++)
					{
						if(CTTools.pages[i].uid == res.data[0].uid )
						{
							CTTools.pages[i].name = pms[":name"];
							CTTools.pages[i].title = pms[":title"];
							CTTools.pages[i].type = pms[":type"];
							CTTools.pages[i].template = pms[":template"];
							CTTools.pages[i].parent = pms[":parent"];
							CTTools.pages[i].webdir = pms[":webdir"];
							CTTools.pages[i].filename = ltFilename;
							_ltPage = CTTools.pages[i];
							CTTools.createPage( CTTools.pages[i], _props );
							break;
						}
					}
				}
				
				if(!CTTools.db.updateQuery( insertPageUpdateHandler, "page", "name=:name", "name=:name,visible=:visible,title=:title,type=:type,template==:template,crdate=:date,parent=:parent,webdir=:webdir,filename=:filename", pms)) {
					agf.tools.Console.log( "ERROR in UPDATE -> Curr Page");
					Application.instance.hideLoading();
					if( typeof(_complete) == "function" ) _complete( false );
				}
				return;
			}
			
			if(! CTTools.db.insertQuery( insertPageInsertHandler, "page", "name,visible,title,type,template,crdate,parent,webdir,filename",":name,:visible,:title,:type,:template,:date,:parent,:webdir,:filename", pms)) {
				agf.tools.Console.log( "ERROR in Insert -> Curr Page");
				Application.instance.hideLoading();
				if( typeof(_complete) == "function" ) _complete( false );
			}
		}
		
		private static function insertPageInsertHandler (res:DBResult) :void {
			if(res && res.rowsAffected )
			{
				var pg:Page = new Page( 
								_name, 
								res.lastInsertRowID,
								_type, 
								_title, 
								_template, 
								"Now",
								_visible,
								_parent,
								_webdir,
								ltFilename );
				_ltPage = pg;
				CTTools.createPage( pg, _props );				
				if( typeof(_complete) == "function" ) _complete( true );
			}
			else
			{
				Console.log( "ERROR Insert page into database");
				if( typeof(_complete) == "function" ) _complete( false );
			}
			
			Application.instance.hideLoading();
		}
		
		private static function insertPageUpdateHandler (res:DBResult) :void {
			if( typeof(_complete) == "function" ) {
				if(res && res.rowsAffected ) {
					 _complete( true );
				}else{
					 _complete( false );
				}
			}
			Application.instance.hideLoading();
		}
		
	}
}
