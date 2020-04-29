package ct
{
	import agf.html.*;
	import agf.events.*;
	import agf.utils.FileInfo;
	import agf.utils.FileUtils;
	import agf.utils.StringMath;
	import flash.events.*;
	import agf.icons.*;
	import agf.tools.*;
	import flash.filesystem.File;
	import ct.ctrl.*;
	import agf.db.DBResult;
	import agf.ui.*;
	import agf.io.ResourceMgr;
	import agf.Main;
	import agf.Options;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.utils.setTimeout;
	import flash.utils.getTimer;
	import flash.display.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.filesystem.*;
	import flash.net.FileReference;
	import flash.net.SharedObject; 
	
	public class AreaEditor extends CssSprite
	{
		public function AreaEditor( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
			_clickScrolling = false;
			Application.instance.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
			create();
		}
		
		private function removePanel (e:Event) :void {
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnUp );
			}
			Main(Application.instance).view.removeEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		private function btnUp (event:MouseEvent) :void {
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
		}
		private function btnMove (event:MouseEvent) :void {
			var dy:Number = mouseY - clickY;
			
			if( ! clickScrolling )
			{
				if( Math.abs(dy) > CTOptions.mobileWheelMove )
				{
					clickScrolling = true;
				}
			}else{
				// scroll
				scrollpane.slider.value -= dy;
				scrollpane.scrollbarChange(null);
				clickY = mouseY;
			}
		}
		private function btnDown (event:MouseEvent) :void {
			stage.addEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, btnUp );
			clickScrolling = false;
			clickY = mouseY;
		}
		
		private var clickY:Number=0; 
		private var _h:int=0;
		public var areapp:Popup;
		public var plusButton:Popup;
		
		public var currentArea:Area;
		public var currentTypes:String = "";
		public var currentTemplate:Template;
		public var lastAreaName:String="";
		
		private var areaView:AreaView;
		private static var viewSize:Number = 190;
		public var sizeButton:Button;
		
		private var scrollpane:ScrollContainer;
		private var itemList:ItemList;
		private var nameCtrl:NameCtrl;
		
		internal var updateItem:Object;		
		private var dragOrdering:Boolean = false;
		private var storeOrderByName:Object = null;
		
		private var pageItemOldIndex:int;
		private var pageItemNewIndex:int;
		private var pageItemDragging:Boolean = false;
		private var pageItemDragSX:int;
		private var pageItemDragSY:int;
		private var pageItemDragItem:Ctrl;
		private var pageItemDragTime:int = 750;
		private var pageItemDownTime:int = 0;
		private var pageItemCurr:int = 0;
		private var newPageItemTmp:Object={};
		
		// Change interface if template split changes
		private var tmplSplitPaths:String;
		private var insertFileStore:Array;
		private var tmpValues:Object;
		private var initValues:Object;
		
		private var selection:Array;
		private var menuStore:Object={};
		
		private var multiSelectMenu:MultiSelectMenu = null;
		
		public static var currPF:ProjectFile=null;
		public static var currItemName:String="";
		
		private static var dpth:int=0;
		
		private var areaClickItem:Ctrl;
		private var areaClickTime:int;
		private var areaClickY:int;
		private var longClick:Boolean = false;
		
		internal static function get clickScrolling () : Boolean {
			return _clickScrolling || AreaView.clickScrolling;
		}
		internal static function set clickScrolling (v:Boolean) :void {
			_clickScrolling = v;
			AreaView.clickScrolling = v;
		}
		private static var _clickScrolling:Boolean = false;
		
		
		public function abortClickScrolling () :void {
			clickScrolling=false;
		}
		
		public function create () :void
		{
			if( plusButton && contains(plusButton)) removeChild( plusButton );
			if( areapp && contains(areapp)) removeChild( areapp );
			if( areaView && contains(areaView)) removeChild( areaView );
			if( sizeButton && contains(sizeButton)) removeChild( sizeButton );
			if( nameCtrl && contains(nameCtrl)) removeChild( nameCtrl );
			
			if (CTTools.activeTemplate)
			{
				currentTypes = "undefined";
				
				var i:int;
			
				if (CTTools.procFiles && CTTools.activeTemplate.indexFile && CTTools.projectDir )
				{
					areaView = new AreaView( 0,0,this,styleSheet,'areaview','','area-view',false);
					if( viewSize == 0 ) areaView.visible = false;
					
					areaView.editor = this;
					
					sizeButton = new Button ([],0,0,this,styleSheet,'','area-sizebutton',false);
					sizeButton.addEventListener( MouseEvent.MOUSE_DOWN, viewSizeDown );
					
					plusButton = new Popup( [ new IconFromFile(Options.iconDir + "/plus.png", Options.iconSize, Options.iconSize), Language.getKeyword("New Item In")],0,0,this,this.styleSheet,'','areaeditor-plusbutton', false);
					plusButton.visible = viewSize == 0;
					
					plusButton.alignH = plusButton.textAlign = "right";
					plusButton.x = cssRight - plusButton.cssSizeX;
					plusButton.addEventListener( Event.SELECT, plusClick );
					
					var pth:String;
					var pfid:int ; 
					var pf:ProjectFile;
					menuStore={};
					var f:int;
					var areas:Vector.<Area>;
					var all:String = CTTools.activeTemplate.files;
					
					if( CTTools.pages && CTTools.pages.length > 0 ) {
						for(f=0;f<CTTools.pages.length; f++) {
							all += ","+CTTools.pages[f].filename;
						}
					}					
					
					var tFiles:Array = all.split(",");
					tFiles.splice(0, 0, CTTools.activeTemplate.indexFile);
					
					var L:int;
					var nam:String;
					
					areapp = new Popup([new IconArrowDown( Application.instance.mainMenu.iconColor ), "none" ], 0, 0, this, styleSheet, '', 'areaeditor-areapopup', false);
					areapp.visible = viewSize == 0;
					
					for(f = 0; f<tFiles.length; f++)
					{						
						pth = CTTools.projectDir + CTOptions.urlSeparator + CTTools.activeTemplate.relativePath + CTOptions.urlSeparator + tFiles[f];					
						pfid = CTTools.projFileBy( pth, "path" );
						pf = CTTools.procFiles[ pfid ] as ProjectFile;
						
						if(pf && pf.templateAreas )
						{
							areas = pf.templateAreas;
							
							if( areas && areas.length > 0 ) {
								L = areas.length;
								if( !currentArea ) {
									for(i=0; i<L; i++) {
										if(areas[i].name == CTTools.currArea ) {
											currentArea = areas[i];
											break;
										}
									}
									if( !currentArea ) {
										currentArea = areas[0];
									}
								}
								if( currentArea ) {
									areapp.label = currentArea.name;
								}
								for (i = 0; i < L; i++) {
									storeArea( areas[i] );
								}
							}
						}
					} // for f
					
					L = CTTools.subTemplates.length;
					var st:Template;
					
					for(i=0; i<L; i++) {
						st = CTTools.subTemplates[i];
						if(st.areasByName) {
							for(nam in st.areasByName) {
								if ( st.areasByName[nam].name != "" && st.stPageAreas[nam] == undefined ) {
									storeArea( st.areasByName[nam] );
								}
							}
						}
					}
					
					sortAreas( areapp.rootNode );
					
					if( CTOptions.reverseAreasPopup )
						areapp.rootNode.children.reverse();
					
					dpth = 0;
					cloneAreas( areapp.rootNode, areaView.rootNode );
					areaView.rootNode.format(true);
					
					// Select first Area...
					var currArea:String = CTTools.activeTemplate.homeAreaName;
					
					if( CTOptions.rememberArea ) {
						var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
						if( sh && sh.data && sh.data.lastArea != undefined ) {
							currArea = String(sh.data.lastArea);
							sh.close();
						}
					}
					
					var s:Array = areapp.rootNode.search( currArea );
					if( s && s.length > 0 ) {
						var curr:PopupItem = s[0];
						currentArea = curr.options.area;
						CTTools.currArea = curr.label;
						AreaEditor.currItemName = curr.label;
						areapp.label =  curr.label;
					}
					
					areapp.addEventListener( PopupEvent.SELECT, areappChange );
					areapp.x = cssLeft;
					
					showAreaItems();
					
					setCurrPF();
				}
			}
		}
		
		// clone area popup to tree view
		private function cloneAreas ( node:PopupItem, treeNode:ItemTree ) :void
		{
			var tr:ItemTree;
			var L:int;
			var i:int;
			var bt:Button;
			var ic:Array;
			
			if( node && treeNode )
			{
				if( node.children && node.children.length > 0 )
				{
					if( node.label == "" ) {
						tr = treeNode;
					}else{
						tr = treeNode.addFolder(  [ new IconFromFile(Options.iconDir + "/folder.png", Options.iconSize, Options.iconSize), node.label ], true );
						tr.btn.nodeClass = "tree-folder-"+dpth;
						tr.btn.addEventListener( MouseEvent.CLICK, areaSectionClick);
						tr.btn.init();
						dpth++;
					}
					
					L = node.children.length;
					var tmp:PopupItem;
					
					for( i=0; i<L; i++ )
					{
						tmp = node.children[i];
						if( tmp.children && tmp.children.length > 0 ) {
							cloneAreas ( tmp, tr );
							dpth--;
						}else{
							if( tmp.options.area && tmp.options.area.icon != "" ) {
								bt = new Button( [ new IconFromFile(tmp.options.area.icon, Options.iconSize, Options.iconSize), tmp.label  ], 0, 0, tr.itemList, styleSheet, '', 'tree-item-'+dpth, false );
							}else{
								bt = new Button( [ tmp.label ], 0, 0, tr.itemList, styleSheet, '', 'tree-item-'+dpth, false );
							}
							bt.addEventListener(MouseEvent.CLICK, areaClick);
							bt.labelSprite.nodeClass = 'area-bt-label';
							bt.labelSprite.init();
							
							bt.autoSwapState = "";
							tr.addItem( bt, false );
						}
					}
				}
				else
				{
					if( node.options.area && node.options.area.icon != "" ) {
						bt = new Button( [ new IconFromFile(node.options.area.icon, Options.iconSize, Options.iconSize), node.label ], 0, 0, treeNode.itemList, styleSheet, '', 'tree-item-'+dpth, false );
					}else{
						bt = new Button( [ node.label ], 0, 0, treeNode.itemList, styleSheet, '', 'tree-item-'+dpth, false );
					}
					
					bt.addEventListener(MouseEvent.CLICK, areaClick);
					bt.autoSwapState = "";
					bt.labelSprite.nodeClass ='area-bt-label';
					bt.labelSprite.init();
					treeNode.addItem( bt, false );
				}
			}
		}
		
		internal function setCurrArea ( tr:ItemTree, dontOpen:Boolean=false ) :void
		{
			var arr:Array = tr.itemList.items;
			var L:int = arr.length;
			var bt:Button;
			var it:ItemTree;
			
			for( var i:int=0; i<L; i++ ) {
				if( arr[i] is ItemTree ) {
					setCurrArea( ItemTree(arr[i]), dontOpen );
				}
				else if( arr[i]  is  Button )
				{
					bt = Button(arr[i]);
					
					if( bt.label == lastAreaName ) {
						bt.labelSprite.swapState("hover");
						
						if( ! dontOpen ) {
							// open parents
							it = ItemTree( bt.parent.parent );
							if( it ) {
								while( it != null ) {
									it.open(null);
									it = it.parentTree;
								}
							}
						}
					}else if( bt.labelSprite.state != "normal" ) {
						bt.labelSprite.swapState("normal");
					}
				}
			}
		}
		
		private function areaSectionClick (e:MouseEvent) :void {
			if( areaView ) {
				setCurrArea( areaView.itemList1, true );
				areaView.scrollpane1.contentHeightChange();
			}
		}
		
		private function areaClick (e:MouseEvent) :void {
			if( !clickScrolling ) {
				var bt:Button = Button(e.currentTarget);
				var lb:String = bt.label;
				var s:Array = areapp.rootNode.search( lb );
				
				if( s && s.length > 0 )
				{
					var curr:PopupItem = s[0];
					currentArea = curr.options.area;
					CTTools.currArea = curr.label;
					areapp.label =  curr.label;
					
					setCurrPF();
					
					if( CTOptions.rememberArea ) {
						var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
						if( sh && sh.data) {
							sh.data.lastArea = lb;
							sh.flush();
							sh.close();
						}
					}
					
					showAreaItems();
					
					if( areaView ) {
						setCurrArea( areaView.itemList1 );
					}
					
				}
			}
		}
		
		private function storeArea (area:Area) :void {
			
			if( area != null && area.link == "" ) {
				
				if( CTTools.activeTemplate && CTTools.activeTemplate.hiddenAreasLookup != null ) {
					if( CTTools.activeTemplate.hiddenAreasLookup[area.name] != null ) {
						return;
					}
				}
				
				var path:String = "";
				var nam:String = area.name.toLowerCase();
				
				var nd:PopupItem;
				var itid:int;
				var newit:PopupItem;
				var L:int;
				var secs:Array;
				var jL:int;
				var secPrio:Number;
				var j:int;
				
				if( nam == "script-begin" || nam == "script-end" || nam=="style-begin" || nam=="style-end" || nam.indexOf("script-object-") >= 0 || nam.indexOf("style-object-") >= 0 ) {
					return;
				}
				
				if( area.sections && area.sections.length > 0 )
				{
					secs = area.sections;
					jL = secs.length;
					
					if( jL > 0 ) 
					{
						nd = areapp.rootNode;
						
						// trough path prio.section.prio.section.prio.area...
						for(j=0; j<jL; j++)
						{												
							secPrio = Number( secs[j] );
							
							// Build rootNode deep items
							if( !isNaN(secPrio) )
							{
								if( nd && nd != areapp.rootNode ) nd.sortid = int(secPrio);
							}
							else
							{
								path += "-" + secs[j];
								
								itid = nd.getItemIdByLabel( secs[j] );
								
								if( itid >= 0 ) {
									// found item
									nd = nd.children[itid];
								}else{
									// Create item
									nd = nd.addItem([secs[j], new IconArrowRight(Application.instance.mainMenu.iconColor)], styleSheet);
								}
							}
						}
						if( !menuStore[ path + area.name ] ) {
							newit = nd.addItem( [area.name], styleSheet );
							menuStore[ path + area.name ] = true;
							newit.options.area = area;
							newit.sortid = area.priority;
						}
					}
				}else{
					if( !menuStore[ area.name ] ) {
						newit = areapp.rootNode.addItem( [area.name], styleSheet );
						menuStore[ area.name ] = true;
						newit.options.area = area;
						newit.sortid = area.priority;
					}
				}
			}
		}
		
		public static var minW:Number=32;
		private var viewSizeStartX:Number=0;
		private var areasVisible:Boolean = true;
		
		private function viewSizeDown (e:MouseEvent) :void {
			if( stage ) {
				stage.addEventListener( MouseEvent.MOUSE_UP, viewSizeUp );
				addEventListener( Event.ENTER_FRAME, viewSizeFrame );
				viewSizeStartX = mouseX;
			}
			if( e ) {
				e.preventDefault();
				e.stopImmediatePropagation();
			}
		}
		
		private function viewSizeUp (e:MouseEvent) :void {
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_UP, viewSizeUp );
				removeEventListener( Event.ENTER_FRAME, viewSizeFrame );
			}
			if( areaView ) {
				setCurrArea( areaView.itemList1 );
			}
			if( e ) {
				e.preventDefault();
				e.stopImmediatePropagation();
			}
		}
		private static var tmpViewSize:Number=0;
		
		public function toggleAreaView () :void {
			if( viewSize > 0 ) {
				tmpViewSize = viewSize;
				viewSize = 0;
				areaView.visible = false;
				plusButton.visible = areapp.visible = true;
				setHeight( getHeight() );
				setWidth( getWidth() );
			}else{
				viewSize = tmpViewSize;
				areaView.visible = true;
				plusButton.visible = areapp.visible = false;
				setHeight( getHeight() );
				setWidth( getWidth() );
			}
		}
		private function viewSizeFrame (e:Event) :void
		{
			if( mouseX < minW ) {
				viewSize = minW;
			}else if( mouseX > getWidth() - minW ) {
				viewSize = getWidth() - minW;
			}else{
				viewSize = mouseX;
			}
			
			setWidth( getWidth() );
		}
		
		private function sortAreas ( nd:PopupItem ) :void {
			if( nd && nd.children ) {
				if( nd.children.length > 0 ) {
					if( CTTools.activeTemplate.sortareas == "priority" ) {
						nd.children.sort( sortAreaPriority );
					}else if( CTTools.activeTemplate.sortareas == "name" ) {
						nd.children.sort( sortAreaName );
					}
					for(var i:int=0; i < nd.children.length; i++) {
						if( nd.children[i].children && nd.children[i].children.length > 0 ) {
							sortAreas( nd.children[i] );
						}
					}
				}
			}
		}
		private function sortAreaName ( a:PopupItem, b:PopupItem ) :int {
			if( a.label > b.label ) return -1;
			return 1;
		}
		private function sortAreaPriority ( a:PopupItem, b:PopupItem ) :int {
			if( a.sortid > b.sortid ) return 1;
			return -1;
		}
		
		public override function setWidth ( w:int ) :void {
			if(plusButton && areapp) if( w < plusButton.cssSizeX + areapp.cssSizeX + 7) w = plusButton.cssSizeX + areapp.cssSizeX + 8;
			
			super.setWidth(w);
			if( plusButton ) {
				plusButton.x = w - (plusButton.cssSizeX + cssBoxRight);
				if( plusButton.x < 0 ) plusButton.x = 0;
			}
			
			var avw:Number = Math.floor(  viewSize );
			
			if( areaView ) {
				areaView.x = 0;
				areaView.setWidth( avw );
			}
			if( areapp ) {
				areapp.x = cssLeft + viewSize;
			}
			w = Math.floor( w - viewSize );
			
			var sbw:int = 0;
			if( scrollpane && scrollpane.slider.visible ) sbw = 16;
			
			if( nameCtrl ) {
				nameCtrl.setWidth(  w - (nameCtrl.cssBoxX + cssBoxX) ); 
				nameCtrl.x = cssLeft + avw;
			}
			
			if( itemList) {
				if(itemList.items) {
					for( var i:int=0; i < itemList.items.length; i++) {
						itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + cssBoxX + sbw ) );
					}
				}
				itemList.setWidth(0);
				itemList.init();
			}
			
			if( multiSelectMenu ) {
				var px:Number = 0;
				var pw:Number = 0;
				if( areaView && areaView.visible ) {
					px = areaView.x + areaView.cssSizeX;
					if( HtmlEditor.isPreviewOpen ) pw = HtmlEditor.previewX - (px);
					else pw = getWidth() - (px);
					multiSelectMenu.y = -cssTop;
				}else{
					if( areapp && areapp.visible ) px = areapp.x + areapp.cssSizeX;
					if( plusButton && plusButton.visible ) pw = plusButton.x - (px);
					else pw = getWidth() - (px);
					multiSelectMenu.y = areapp.y;
				}
				multiSelectMenu.x = px;
				multiSelectMenu.setWidth( pw - multiSelectMenu.cssBoxX );
			}
			if( sizeButton ) {
				sizeButton.x = avw >= 0 ? Math.floor( avw  ) : 0;
			}
			if( scrollpane ) {
				scrollpane.x = cssLeft + avw;
				scrollpane.setWidth( w - cssBoxX );
			}
		}
		public override function setHeight (h:int) :void
		{
			super.setHeight(h); 	
			_h = h;
			var th:int = getHeight();
			var ch:int = 2;
			
			if( areaView ) {
				areaView.setHeight( th - ch );
				areaView.y = -cssTop;
			}
			
			if( sizeButton ) {
				sizeButton.setHeight( th -  (ch + cssBoxY) );
			}
			
			if(scrollpane)
			{
				if( multiSelectMenu ) 
				{
					// not in displayForm possible..
					scrollpane.setHeight( th - (scrollpane.y + scrollpane.cssBoxBottom) );
					scrollpane.contentHeightChange();
				}
				else
				{
					var s:Number = (areapp && areapp.visible) || (plusButton && plusButton.visible) ? Math.max(areapp.cssSizeY, plusButton.cssSizeY) : 0;
					
					if( nameCtrl ) {
						nameCtrl.y = s + cssTop;
						s += nameCtrl.cssSizeY + nameCtrl.cssMarginBottom;
					}
					
					scrollpane.setHeight( th - (ch + cssBoxY + s) );
					scrollpane.contentHeightChange();
					var pbH:Number = s + cssTop;
					scrollpane.y = pbH;
				}
			}
		}
		
		private function inputHeightChange (e:Event):void {
			if( itemList ) {
				itemList.format();
			}
			if( scrollpane ) scrollpane.contentHeightChange();
		}
		
		private function vectorClear (e:InputEvent):void {
			if( itemList ) {
				var ch:Array= itemList.items;
				var L:int = ch.length;
				var pc:PropertyCtrl = PropertyCtrl( e.currentTarget.parent );
				if( pc && pc.textBox && pc.textBox.type == "vector" ) {
					var nam:String = pc.name;
					var it:PropertyCtrl;
					for( var i:int=0; i<L; i++) {
						it = PropertyCtrl( ch[i] );
						if( it.textBox.type == "vectorlink" && it.textBox.args && it.textBox.args[0] == nam) {
							it.textBox.vectorCurrent = e.val;
							it.textBox.vectorMinusClick(null);
						}
					}
				}
			}
		}
		
		private function vectorAdd (e:InputEvent):void {
			if( itemList ) {
				var ch:Array= itemList.items;
				var L:int = ch.length;
				var pc:PropertyCtrl = PropertyCtrl( e.currentTarget.parent );
				if( pc && pc.textBox && pc.textBox.type == "vector" ) {
					var nam:String = pc.name;
					var it:PropertyCtrl;
					for( var i:int=0; i<L; i++) {
						it = PropertyCtrl( ch[i] );
						if( it.textBox.type == "vectorlink" && it.textBox.args && it.textBox.args[0] == nam) {
							it.textBox.vectorCurrent = e.val;
							it.textBox.vectorPlusClick(null);
						}
						
					}
				}
			}
		}
		
		private function vectorLengthChange (e:Event):void {
			if( itemList ) {
				var ch:Array= itemList.items;
				var L:int = ch.length;
				var pc:PropertyCtrl = PropertyCtrl( e.currentTarget.parent );
				
				if( pc && pc.textBox && pc.textBox.type == "vector" ) {
					var nam:String = pc.name;
					var it:PropertyCtrl;
					var sL:int = pc.textBox.vectorTextFields.length;
					var k:int;
					var kL:int;
					
					for( var i:int=0; i<L; i++)  {
						it = PropertyCtrl( ch[i] );
						if( it.textBox.type == "vectorlink" && it.textBox.args && it.textBox.args[0] == nam){
							kL =  it.textBox.vectorTextFields.length;
							
							if( kL < sL ) {
								for(k = kL; k < sL; k++) {
									it.textBox.vectorPlusClick(null);
								}
							}else if ( kL > sL ) {
								for(k = sL; k>=sL; k--) {
									it.textBox.vectorMinusClick(null);
								}
							}
						}
					}
				}
			}
		}
		private var areaItems:Array;
		
		public function showAreaItems () :void
		{
			updateItem = null;
			
			// Area changed...
			if( multiSelectMenu != null ) {
				removeMultiSelMenu();
			}
			
			if( nameCtrl && contains(nameCtrl)) removeChild( nameCtrl );
			nameCtrl = null;
			
			if( areaView && areaView.scrollpane2 ) areaView.scrollpane2.visible = true;
			
			if(scrollpane) {
				if( itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
				if( contains( scrollpane) ) removeChild( scrollpane );
			}
			
			if(!plusButton || !currentArea) return; // nothing to show
			
			var i:int;
			var L:int;
			var T:Template;
			var ppi:PopupItem;
			
			if ( CTTools.subTemplates ) { // Select allowed sub templates for currentArea from DB...
				
				L = CTTools.subTemplates.length;
				var tmpl_types:Vector.<String>;
				var area_types:Vector.<String>;
				var k:int;
				var L2:int;
				var hash:Object = {};
				var id:String;
				var nam:String;
				
				var ico:String;
				
				
				if( currentArea.types.join(",") != currentTypes )
				{
					if( areaView ) {
						areaView.clearItems();
					}
					
					if( plusButton.visible ) 
						plusButton.rootNode.removeItems();
				
					if( currentArea.type == "all" || !currentArea.types || currentArea.types.length == 0 )
					{
						// Show all subtemplates
						for(i=0; i<L; i++) 
						{
							T = CTTools.subTemplates[i];
							if( T.hidden ) continue;
							
							nam = T.name;
							
							ico = CTTools.parseFilePath( T.listicon );
							
							if( plusButton.visible ) {
								ppi = plusButton.rootNode.addItem( [ Language.getKeyword(nam), new IconFromFile(ico,Options.iconSize,Options.iconSize) ], styleSheet );
								ppi.options.templateID = nam;
							}
							if( areaView ) {
								areaView.addItem( nam, ico );
							}
						}
						currentTypes = "all";
					}
					else
					{
						currentTypes = currentArea.types.join(",");
						
						// Show subtemplates of type in types array of area
						for(i=0; i<L; i++)
						{
							T = CTTools.subTemplates[i];
							if( T.hidden ) continue;
							nam = T.name;
							id = T.relativePath + nam;
							
							if( currentArea.types.indexOf( T.type ) >= 0 ) 
							{
								// Test multiple area types
								if( !hash[id] ) { 
									hash[id] = true;
									
									ico = CTTools.parseFilePath( T.listicon );
									
									if( plusButton.visible ) {
										ppi = plusButton.rootNode.addItem( [ Language.getKeyword(nam), new IconFromFile(ico,Options.iconSize,Options.iconSize) ], styleSheet );
										ppi.options.templateID = nam;
									}
									if( areaView ) {
										areaView.addItem( nam, ico);
									}
								}
							}
							else
							{
								// Test multiple types of subtemplate (set in config.xml of subtemplate)
								L2 = T.types.length; 
								if( L2 > 1 )
								{
									for (k=1; k<L2; k++ )
									{
										if( currentArea.types.indexOf(T.types[k] ) >= 0 ){
											if( !hash[ id ] ) { 
												hash[ id ] = true;
												ico = CTTools.parseFilePath( T.listicon );
												
												if( plusButton.visible ) {
													ppi = plusButton.rootNode.addItem( [ Language.getKeyword(nam), new IconFromFile(ico,Options.iconSize,Options.iconSize) ], styleSheet );
													ppi.options.templateID = nam;
												}
												if( areaView ) {
													areaView.addItem( nam, ico );
												}
												
											}
											break;
										}
									}
								}
							}
						} // for subtemplates
					}
				}
			}
			
			var w:Number = getWidth();
			
			scrollpane = new ScrollContainer( 0,0, this, styleSheet,'', 'area-scroll-container', false);
			itemList = new ItemList(0, 0, scrollpane.content, styleSheet, '', 'area-container', false);
			itemList.margin = 1;
			var icos:Array;
			var area_ico:Sprite;
			var article_areas:Popup;
			var pf:ProjectFile;
			var filename:String;
			
			if( CTTools.pageItems )
			{
				L = CTTools.pageItems.length;
				var pg:Button;
				var r:Object;
				
				// Get PageItem List of Items in the CurrentArea
				//var areaItems:Array = [];
				
				areaItems = [];
				for(i=0; i<L; i++) {
					r = CTTools.pageItems[i];
					if( r && r.area && r.area == currentArea.name ) areaItems.push(r);
				}
				areaItems.sortOn( "sortid", Array.NUMERIC );
				L = areaItems.length;
				var ico_col:int = Application.instance.mainMenu.iconColor;
				var created:Boolean;
				var labelText:String;
				var j:int;
				var jL:int;
				var listIcon:String;
				//var ppi:PopupItem;
				
				for (i = 0; i < L; i++)
				{
					r = areaItems[i];
					T = CTTools.findTemplate( r.subtemplate, "name" );
					created = false;
					listIcon = "";
					
					if( T )
					{
						labelText = TemplateTools.obj2Text(T.listlabel, "#", r, false, true);
								
						if( T.parselistlabel ) {
							labelText = TemplateTools.obj2Text(labelText, "#", r, true, false);
							labelText = HtmlParser.fromDBText( labelText );
						}
						
						if( T.listlabel )
						{
							if( T.listicon ) {
								listIcon = CTTools.parseFilePath( T.listicon );
								icos = [ new IconFromFile( listIcon, Options.iconSize, Options.iconSize), labelText ];
							}else{
								icos = [new IconMenu(ico_col, Options.iconSize, Options.iconSize), labelText];
							}
							
							if ( T.articlepage != "" )
							{
								if( r.inputname == undefined ) {
									r.inputname = r.name;
								}
								filename = CTTools.webFileName( T.articlename, r );
								
								pf = CTTools.findArticleProjectFile( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + filename, "path");
								
								if ( pf && pf.templateAreas && pf.templateAreas.length > 0 )
								{
									article_areas = new Popup( [new IconArrowDown(Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize)], 
															Options.btnSize, Options.btnSize, null, styleSheet, '', 'article-areas-popup', true );
									article_areas.alignH = "right";
									article_areas.textAlign = "right";
									
									jL = pf.templateAreas.length;
									
									for (j = 0; j < jL; j++ )
									{
										if ( CTTools.activeTemplate.areasByName[pf.templateAreas[j].name] == undefined) {
											ppi = article_areas.rootNode.addItem( [pf.templateAreas[j].name], styleSheet );
											ppi.options.area = pf.templateAreas[j];
										}
									}
									if( article_areas.rootNode.children && article_areas.rootNode.children.length > 0 ) {
										article_areas.addEventListener( PopupEvent.SELECT, gotoAreaPP );
										icos.push( article_areas );
									}
								}
							}else{
								if( T.numAreas > 0 ) {
									area_ico = new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "anmeldung-abgerundet.png", Options.iconSize, Options.iconSize);
									area_ico.addEventListener( MouseEvent.MOUSE_DOWN, gotoAreaHandler );
									icos.push( area_ico );
								}
							}
							
							pg = new Button(icos, 0, 0, itemList, styleSheet, '', 'page-item-btn', false);
							
							if( pg.contRight ) {
								pg.contRight.mouseEnabled = true;
								pg.contRight.mouseChildren = true;
							}
							created = true;
						}
					}
					
					if(!created) {
						pg = new Button([ "" + Language.getKeyword(r.subtemplate) + ": " + r.name, new IconMenu(ico_col) ], 0, 0, itemList, styleSheet, '', 'page-item-btn', false);
					}
					
					if( areaItems[i].visible == false ) {
						pg.alpha = 0.35;
					}
					
					pg.options.result = r;
					pg.name = r.name;
					pg.addEventListener( MouseEvent.MOUSE_DOWN, areaItemDown);
					itemList.addItem( pg, true);
				}
				
				lastAreaName = currentArea.name;
				itemList.format();

				setHeight( _h );
				setWidth( w );
				
				if( areaView ) {
					setCurrArea( areaView.itemList1 );
				}
			}
		}
		private function gotoAreaPP (e:PopupEvent) :void {
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			
			var curr:PopupItem = e.selectedItem;
			gotoArea( curr.options.area );
		}
		private function gotoAreaHandler (e:MouseEvent) :void
		{
			e.stopPropagation();
			e.stopImmediatePropagation();
			e.preventDefault();
			
			var currbt:Button =  Button(e.currentTarget.parent.parent)
			var lb:String = currbt.options.result.name;
			
			var s:Array = areapp.rootNode.search( lb );
				
			if( s && s.length > 0 )
			{
				var curr:PopupItem = s[0];
				currentArea = curr.options.area;
				CTTools.currArea = curr.label;
				areapp.label =  curr.label;
				
				setCurrPF();
				
				if( CTOptions.rememberArea ) {
					var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
					if( sh && sh.data) {
						sh.data.lastArea = lb;
						sh.flush();
						sh.close();
					}
				}
				
				showAreaItems();
				
				if( areaView ) {
					setCurrArea( areaView.itemList1 );
				}	
			}
		}
		
		private var _isUpdateForm:Boolean=false;
		
		
		public function gotoArea (area:Area) :void
		{
			currentArea = area;
			CTTools.currArea = area.name;
			if( areapp ) {
				areapp.label = area.name;
			}
			if( CTOptions.rememberArea ) {
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( sh && sh.data) {
					sh.data.lastArea = area.name;
					sh.flush();
					sh.close();
				}
			}
			if( CTOptions.previewInEditor && CTTools.procFiles )
			{
				setCurrPF();
			}
			
			showAreaItems();
		}
		
		public function displayInsertForm ( tmpl:Template, isUpdateForm:Boolean=false ) :void 
		{
			if(!tmpl || !tmpl.indexFile) return;
			
			if( multiSelectMenu != null ) removeMultiSelMenu();
			
			currentTemplate = tmpl;
			_isUpdateForm = isUpdateForm;
			
			if( areaView && areaView.scrollpane2 ) areaView.scrollpane2.visible = false;
			
			var files:Array = CTTools.procFiles;
			var L:int = files.length;
			
			if ( L > 0 )
			{
				var pfid:int;
				var pth:String;
				var pf:ProjectFile;
				var j:int;
				var jL:int;
				var ict:CssSprite;
				
				if( nameCtrl && contains( nameCtrl ) ) removeChild(nameCtrl);
				
				if( scrollpane && itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
				if( scrollpane && contains( scrollpane) ) removeChild( scrollpane );
				
				var w:Number =  getWidth();
				scrollpane = new ScrollContainer(w, 0, this, styleSheet, '', '',false);
				scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
				
				itemList = new ItemList(w,0,scrollpane.content,styleSheet,'','area-insert-container',true);
				var currSprite:CssSprite;
				itemList.margin = 3;
				
				var propName:String;
				var propType:String;
				var propVal:String;
				var namlc:String;
				
				ict = new NameCtrl( "Name", "name", "name", "", null, null, w, 0, this, styleSheet,'', 'area-insert-prop', false);
				var nm:NameCtrl = NameCtrl( ict );
				var ppi:PopupItem; 
				
				if ( isUpdateForm && tmpl.articlepage != "" && updateItem )
				{
					var r:Object = CTTools.pageItemTable[ updateItem.name ];
					
					if ( r )
					{
						if( r.inputname == undefined ) {
							r.inputname = r.name;
						}
						var filename:String = CTTools.webFileName( tmpl.articlename, r );
						
						pf = CTTools.findArticleProjectFile( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + filename, "path");
						
						if ( pf && pf.templateAreas && pf.templateAreas.length > 0 )
						{
							jL = pf.templateAreas.length;
							
							nm.areaPopup.rootNode.removeItems();
							
							for (j = 0; j < jL; j++ )
							{
								if ( CTTools.activeTemplate.areasByName[pf.templateAreas[j].name] == undefined) {
									ppi = nm.areaPopup.rootNode.addItem( [pf.templateAreas[j].name], styleSheet );
									ppi.options.area = pf.templateAreas[j];
								}
							}
							
							nm.areaPopup.addEventListener( PopupEvent.SELECT, gotoAreaPP );
						}
					}
				}
				
				if( !isUpdateForm ) {
					nm.showSaveButton(false); // .visible = false;
					nm.showDeleteButton(false); // .visible = false;
					nm.showNextButton(false);
					nm.showPrevButton(false);
				}else{
					if ( areaItems ) {
						if ( areaItems.length <= 1 ) {
							nm.showNextButton(false);
							nm.showPrevButton(false);
						}
					}
				}
				
				
				ict.addEventListener( PropertyCtrl.ENTER, ictChange );
				ict.addEventListener( "save", (isUpdateForm ? updatePageItem : insertPageItem));
				ict.addEventListener( "saveInline", inlineSaveClick );
				ict.addEventListener( "delete", deletePageItem );
				ict.addEventListener( "close", cancelPageItem);
				ict.addEventListener( "next", nextPageItem);
				ict.addEventListener( "prev", prevPageItem);
				
				nameCtrl = NameCtrl(ict);
				
				ict.setWidth( w );
				
				if( !isUpdateForm ) {
					nm.visibleStatus = true;
				}else{
					if( updateItem && updateItem.visible != undefined ) {
						nm.visibleStatus = updateItem.visible == true || updateItem.visible == "true" ? true : false;
					}else{
						nm.visibleStatus = true;
					}
				}
				
				initValues = {};
				
				var propStore:Object = {};
				tmplSplitPaths = "";
				
				for(var i:int = 0; i<L; i++)
				{
					pf = CTTools.procFiles[ i ] as ProjectFile;
					
					if( pf.templateId == tmpl.name )
					{
						if( pf.templateProperties )
						{
							jL = pf.templateProperties.length;
							
							if (pf.splits) {
								tmplSplitPaths += pf.splitPath;
							}
							
							for(j=0; j<jL; j++)
							{
								propName = pf.templateProperties[j].name;
								propVal = "";
								if( propName == "field" ) continue;
								
								propType = pf.templateProperties[j].defType.toLowerCase();
								
								if(propStore[propName]) continue; // ignore multiple properties with the same name
								propStore[propName] = true;
								
								if ( isUpdateForm ) {
									if ( updateItem && CTTools.pageItemTable[ updateItem['name'] ] && typeof(CTTools.pageItemTable[ updateItem['name'] ][propName]) != "undefined" )
									{
										propVal = CTTools.pageItemTable[ updateItem['name'] ][propName];
									}
								}
								else
								{
									propVal = pf.templateProperties[j].defValue;
									
								}
								
								// filter "name" and "visible" property
								namlc = propName.toLowerCase();
								
								if( namlc == "visible" ) {
									continue;
								}
								if( namlc == "name")
								{
									nameCtrl.label.label = (isUpdateForm ? "" : (Language.getKeyword("Create New Area Item") + " ") ) + Language.getKeyword( tmpl.name ) + ":";
									
									if( isUpdateForm && updateItem && updateItem[ "name" ] ) {
										nameCtrl.textBox.value = updateItem[ "name" ];
									}else{
										if( propVal != "" ) {
											nameCtrl.textBox.value = propVal;
										}
									}
									continue;	
								}
								
								if (isUpdateForm && updateItem && updateItem[ propName ])
								{
									propVal = updateItem[propName];
								}
								
								ict = new PropertyCtrl( Language.getKeyword(propName.toLowerCase()), propName, propType, propVal, pf.templateProperties[j], pf.templateProperties[j].args, w, 0, itemList, styleSheet,'', 'area-insert-prop', false);
								ict.options.propObject = pf.templateProperties[j];
								
								// Remove Reset to Default Value..
								PropertyCtrl(ict).ctrlOptions.rootNode.children.shift();
								if( PropertyCtrl(ict).ctrlOptions.rootNode.children.length <= 0 ) {
									// Remove Help Popup if no help available..
									PropertyCtrl(ict).label.x = 0;
									PropertyCtrl(ict).ctrlOptions.visible = false;
								}
								ict.addEventListener( PropertyCtrl.ENTER, ictChange );
								
								if( propType == "text" || propType == "richtext" || propType == "vector" || propType=="vectorlink" || propType == "code" )
								{
									PropertyCtrl(ict).textBox.addEventListener("heightChange", inputHeightChange);
									
									if( propType == "vector" || propType == "vectorlink" ) {
										PropertyCtrl(ict).textBox.addEventListener("lengthChange", vectorLengthChange);
									}
									
									if( propType == "vector") {									
										PropertyCtrl(ict).textBox.addEventListener("add", vectorAdd);
										PropertyCtrl(ict).textBox.addEventListener("clear", vectorClear);
									}
								}
								
								if( propType == "intern" || propType == "hidden") { 
									ict.setHeight(1);
									ict.alpha = 0;
								}
								
								itemList.addItem(ict, true);
							}
						}
					}
				}
				
				itemList.format();
				
				setHeight( _h );
				setWidth( w );
				
				storeCurrentItemValues();
				
				try {
					Application.instance.view.panel.src["displayFiles"]();
				}catch(e:Error) {
					
				}
				
				setWidth( w );
			}
		}
		private function storeCurrentItemValues () :void {
			
			if( nameCtrl && itemList && itemList.items && itemList.items.length > 0 ) {
				var L:int = itemList.numChildren;
				var pc:PropertyCtrl;
				
				for(var i:int=0; i<L; i++) {
					if( itemList.items[i] is PropertyCtrl ) {
						pc = PropertyCtrl( itemList.items[i] );
						initValues[ pc._name ] = { value: pc.textBox.value, name: pc._name };
					}
				}
				
				var nm:NameCtrl = nameCtrl;
				initValues[ 'visible' ] = { value: nm.visibleStatus, name:'visible' };
				
				currItemName = nm.textBox.value;
			}
		}
		
		private var saveInline:Boolean=false;
		
		private function inlineSaveClick (e:Event) :void {
			if( updateItem ) {
				saveInline = true;
				updatePageItem(null);
			}
		}
		
		private function showDragSaveButtons () :void {
			storeOrderByName = {};
			for(var i:int=0; i<itemList.items.length; i++) {
				if( itemList.items[i].options && itemList.items[i].options .result ) {
					storeOrderByName[Ctrl(itemList.getItemAt(i)).options.result.name] = Ctrl(itemList.getItemAt(i)).options.result.sortid;
				}
			}
			dragOrdering = true;
			multiSelectMenu.enableUndo(true);
		}
		private function dragCancelClickHandler (e:MouseEvent) :void {
			// restore list order
			if( itemList && storeOrderByName ) {
				for(var i:int=0; i<itemList.items.length; i++) {
					Ctrl(itemList.getItemAt(i)).options.result.sortid = storeOrderByName[Ctrl(itemList.getItemAt(i)).options.result.name];
				}
			}
			storeOrderByName = null;
			dragOrdering = false;
		}
		private function dragSaveClickHandler (e:MouseEvent) :void{
			dragOrdering = false;
			storeOrderByName = null;
			Application.instance.showLoading( );
			// Update items in db...
			pageItemCurr = 0;
			updateNextPageItemSorting ();
		}
		
		private function removeMultiSelMenu () :void {
			if( multiSelectMenu != null )
			{
				if( contains( multiSelectMenu ) ) {
					removeChild( multiSelectMenu );
				}
				multiSelectMenu = null;
				longClick = false;
			}
		}
		
		public function multiSelUndo () :void {
			if( multiSelectMenu.getUndoEnabled() ) {
				dragCancelClickHandler(null);
				removeMultiSelMenu();
				showAreaItems();
			}
		}
		public function multiSelAbort () :void {
			// reverse ordering..
			if( multiSelectMenu.getUndoEnabled() ) {
				removeMultiSelMenu();
				dragSaveClickHandler(null);
				
			}else{
				removeMultiSelMenu();
				showAreaItems();
			}
		}
		private function showMultiSelectMenu () :void {
			if( multiSelectMenu == null )
			{
				longClick = true;
				selection = [];
				
				multiSelectMenu = new MultiSelectMenu(this,0,0,this,styleSheet,"","area-multi-select-menu",false);
				
				var px:Number = 0;
				var pw:Number = 0;
				
				if( areaView && areaView.visible ) {
					px = areaView.x + areaView.cssSizeX;
					if( HtmlEditor.isPreviewOpen ) pw = HtmlEditor.previewX - (px);
					else pw = getWidth() - (px);
					multiSelectMenu.y = -cssTop;
				}else{
					if( areapp && areapp.visible ) px = areapp.x + areapp.cssSizeX;
					if( plusButton && plusButton.visible ) pw = plusButton.x - (px);
					else pw = getWidth() - (px);
					multiSelectMenu.y = areapp.y;
				}
				multiSelectMenu.x = px;
				multiSelectMenu.setWidth( pw - multiSelectMenu.cssSizeX );
				
				if( itemList && itemList.items ) {
					var L:int = itemList.items.length;
					var bt:Button;
					var ar:Array;
					for(var i:int=0; i<L; i++) {
						bt = Button( itemList.items[i] );
						if( bt ) {
							ar = bt.clips;
							ar.push( new IconFromFile( Options.iconDir + "/neu-anordnen.png", Options.iconSize, Options.iconSize ) );
							bt.clips = ar;
							bt.autoSwapState = "";
							bt.swapState("normal");
							bt.setWidth( bt.getWidth() );
						}
					}
				}
				
				scrollpane.y = multiSelectMenu.cssSizeY;
				scrollpane.setHeight( getHeight() - scrollpane.y );
				scrollpane.contentHeightChange();
			}
			
		}
		
		// new pageItemDown:
		private function areaItemDown (e:MouseEvent) :void
		{
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			
			areaClickItem = Ctrl( Sprite(e.currentTarget) );
			areaClickTime = getTimer();
			areaClickY = mouseY;
			clickScrolling = false;
			
			if( !longClick )
			{
				stage.addEventListener( Event.ENTER_FRAME, areaItemMove );
				stage.addEventListener( MouseEvent.MOUSE_UP, areaItemUp );
			}
			else
			{
				var bt:Button = Button ( areaClickItem );
				
				stage.addEventListener( Event.ENTER_FRAME, selectItemMove );
				stage.addEventListener( MouseEvent.MOUSE_UP, selectItemUp );
				
				// multi sel mode..
				if( bt.contRight && bt.mouseX > bt.contRight.x ) {
					// drag button start
					if( selection && selection.length > 1 ) {
						startDragItems( areaClickItem );
					}else{
						startDragItem( areaClickItem );
					}
				}
				else{
					// select/deselect
					
					var id:int = selection.indexOf( bt.options.result.name );
					
					if( id >= 0 )
					{
						selection.splice( id, 1 );
						
						if( bt.state != "normal" ) {
							bt.swapState("normal");
						}
					}
					else
					{
						//var id:int = 
						selection.push( bt.options.result.name );
						
						if( bt.state != "active" ) {
							bt.swapState("active");
						}
					}
				}
			}
		}
		private function areaItemMove (e:Event) :void
		{
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			
			var dy:Number = mouseY - areaClickY;
			var sd:Slider = scrollpane.slider;
			
			if( clickScrolling ) {
				sd.value -= dy;
				scrollpane.scrollbarChange(null);
				areaClickY = mouseY;
			}else{
				if( !longClick && getTimer() - areaClickTime > CTOptions.longClickTime ) {
					showMultiSelectMenu();
					var bt:Button = Button( areaClickItem );
					
					if( bt.contRight && bt.mouseX > bt.contRight.x ) {
						showMultiSelectMenu();
						startDragItem( areaClickItem );
					}else{
						bt.swapState("active");
					}
				}
				
				if(sd.visible && !longClick && Math.abs(dy) > CTOptions.mobileWheelMove ) {
					// start click scrolling..
					clickScrolling = true;
					sbClickValue = scrollpane.slider.value;
				}
			}
		}
		private function areaItemUp (e:MouseEvent) :void 
		{
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			
			stage.removeEventListener( Event.ENTER_FRAME, areaItemMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, areaItemUp );
			
			if( !clickScrolling) {
				if( longClick ||  getTimer() - areaClickTime > CTOptions.longClickTime ) {
					if ( !pageItemDragging ) {
						showMultiSelectMenu();
						Button(areaClickItem).swapState( "active" );
						selection.push( Button(areaClickItem).options.result.name );
					}
				}else{
					// normal click..
					// todo hit test clickItem?
					var T:Template = CTTools.findTemplate( areaClickItem.options.result.subtemplate, "name" );
					if( T ) {
						updateItem = areaClickItem.options.result;
						displayInsertForm( T, true );
					}else Console.log("ERROR: Can not find Template '" + areaClickItem.options.result.subtemplate + "' for Page Item: " +  areaClickItem.options.result.name);
				}
			}
		}
		
		private static var sbClickValue:Number;
		private var inlineLongClick:Boolean = false;
		
		private function selectItemMove (e:Event) :void {
			if( ! pageItemDragging ) {
				var dy:Number = mouseY - areaClickY;
				
				if( clickScrolling ) {
					var sd:Slider = scrollpane.slider;
					if( sd.visible ) {
						sd.value -= dy;
						scrollpane.scrollbarChange(null);
						areaClickY = mouseY;
					}
				}else{
					if( !inlineLongClick && getTimer() - areaClickTime > CTOptions.longClickTime ) {
						// select on drag over...
						inlineLongClick = true;
					}
					if( !inlineLongClick && Math.abs(dy) > CTOptions.mobileWheelMove ) {
						// start click scrolling..
						clickScrolling = true;
						sbClickValue = scrollpane.slider.value;
					}
				}
			}
		}
		
		private function selectItemUp (e:MouseEvent) :void {
			inlineLongClick = false;
			clickScrolling = false;
			stage.removeEventListener( Event.ENTER_FRAME, selectItemMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, selectItemUp );
			if( selection ) {
				var L:int = selection.length;
				var ds:DisplayObject;
				
				for( var i:int=0; i<L; i++) {
					ds = DisplayObject( itemList.getChildByName( selection[i] ) );
					if( ds ) {
						Button( ds ).swapState( "active" );
					}
				}
			}			
		}
		
		private var dragDisplay:CssSprite;
		private function startDragItems ( item:Ctrl ) :void {
			// TODO:
			Console.log("Not implemented..");
		}
		private function startDragItem ( item:Ctrl ) :void {
			pageItemDragItem = Ctrl(Sprite(item));
			pageItemDragSX = pageItemDragItem.mouseX;
			pageItemDragSY = pageItemDragItem.mouseY;
			pageItemDragging = true;
			var ib:ItemList = itemList;
			
			if( !dragDisplay ) {
				dragDisplay = new CssSprite( getWidth(), 0, scrollpane.content, styleSheet, '', '','drag-display', false);
			}
			if( !dragOrdering ) showDragSaveButtons();
			
			pageItemNewIndex = -1;
			pageItemOldIndex = ib.removeItem(pageItemDragItem, true);
			
			Main(Application.instance).topContent.addChild( pageItemDragItem );
			
			stage.addEventListener( Event.ENTER_FRAME, dragItemMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, dragItemUp );
		}
		
		private function dragItemMove (e:Event) :void {
			var ib:ItemList = itemList;
			if( pageItemDragging ) {
				if(scrollpane.slider.visible) {
					if(scrollpane.mouseY < 8) {
						scrollpane.slider.value -= 5;
						scrollpane.scrollbarChange(null);
					}else if(scrollpane.mouseY > scrollpane.height - 25) {
						scrollpane.slider.value += 5;
						scrollpane.scrollbarChange(null);
					}
				}
				pageItemDragItem.x = (areaView && areaView.visible  ? areaView.cssSizeX : 0) + cssLeft;
				pageItemDragItem.y = Main(Application.instance).topContent.mouseY - pageItemDragSY; 
				var L:int = ib.numItems;
				var i:int;
				
				pageItemNewIndex = -1;
				for(i=0; i<L; i++) {
					if(pageItemDragItem.hitTestObject(ib.getItemAt(i))){
						pageItemNewIndex = i;
						break;
					}
				}
				if( dragDisplay && itemList && itemList.items ) {
					if( pageItemNewIndex >= 0 && pageItemNewIndex < itemList.numItems ) {
						dragDisplay.y = itemList.getItemAt( pageItemNewIndex ).y;
					}else if( pageItemNewIndex < 0 ) {
						if( itemList.items.length > 0 ) {
							dragDisplay.y = itemList.getItemAt( itemList.numItems-1 ).y + CssSprite(itemList.getItemAt( itemList.numItems-1 )).cssSizeY;
						}
					}
				}
			}
		}
		private function dragItemUp (e:MouseEvent) :void {
			var tc: Sprite;
			stage.removeEventListener( Event.ENTER_FRAME, dragItemMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, dragItemUp );
			
			if( dragDisplay && scrollpane.content.contains( dragDisplay ) ) scrollpane.content.removeChild( dragDisplay );
			
			dragDisplay = null;
			
			pageItemDragging = false;
			tc = Sprite( Main(Application.instance).topContent );
			if( tc.contains(pageItemDragItem) ) tc.removeChild(pageItemDragItem);
			itemList.addItemAt( pageItemDragItem, pageItemNewIndex );
			
			if( pageItemOldIndex != pageItemNewIndex)
			{
				// set order id on all items from 0 - item-length
				for( var i:int=0; i<itemList.items.length; i++ ) {
					Ctrl(itemList.getItemAt(i)).options.result.sortid = i;
				}
			}
			
			pageItemDragItem.x = 0;
			itemList.format(false);
			setWidth( getWidth() );
		}
		
		// Drag and create new Items from the Area New Field into an area list:
		public function newItem ( id:int, tname:String ) :void {
			var T:Template = CTTools.findTemplate( tname, "name" );
			if(T) {
				displayInsertForm(T);
			}else{
				Console.log("No Template found with the name : " + tname);
			}
		}
		
		private var dragNewId:int=0;
		private var dragNewName:String="";
		private var dragNewButton:Button;
		
		public function startDragNewItem (id:int, tname:String) :void {
			dragNewId = id;
			dragNewName = tname;
			
			if( stage ) {
				if( dragNewButton && contains(dragNewButton) ) removeChild( dragNewButton );
				dragNewButton = new Button([Language.getKeyword(tname) ],0,0,this,styleSheet,'','drag-new-button',false);
				
				if( dragDisplay && scrollpane.content.contains( dragDisplay ) ) scrollpane.content.removeChild( dragDisplay );
				dragDisplay = new CssSprite( getWidth(), 0, scrollpane.content, styleSheet, '', '','drag-display', false);
				
				addEventListener ( Event.ENTER_FRAME, dragNewMove );
				stage.addEventListener( MouseEvent.MOUSE_UP, dragNewUp );	
			}
		}
		private static var newInsertSortID:int=-1;
		
		private function dragNewUp (e:Event) :void
		{
			removeEventListener( Event.ENTER_FRAME, dragNewMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, dragNewUp );
			
			if( dragNewButton && contains(dragNewButton) ) {
				removeChild( dragNewButton );
				dragNewButton = null;
			}
			
			if( dragDisplay && scrollpane.content.contains( dragDisplay ) ) {
				scrollpane.content.removeChild( dragDisplay );
				dragDisplay = null;
			}
			
			if( mouseX > areaView.getWidth()  - Options.iconSize )
			{
				var L:int = CTTools.pageItems.length;
				var r:Object;
				
				// Get PageItem List of Items in the CurrentArea stored in the db
				var _areaItems:Array = [];
				var i:int;
				
				for( i=0; i<L; i++ ) {
					r = CTTools.pageItems[i];
					if( r && r.area && r.area == currentArea.name ) _areaItems.push(r);
				}
				_areaItems.sortOn( "sortid", Array.NUMERIC );
				
				L = _areaItems.length;
				for( i=0; i<L; i++ ) {
				
					if( i == pageItemNewIndex )
					{
						newInsertSortID = _areaItems[i].sortid;
						_areaItems[i].sortid ++;
					}
					else if( i > pageItemNewIndex ) 
					{
						_areaItems[i].sortid ++;
					}
				}
				
				newItem( dragNewId, dragNewName );
			}
		}
		
		private function dragNewMove (e:Event):void
		{
			if( dragNewButton )
			{
				if( mouseX < areaView.getWidth() - Options.iconSize )
				{
					dragNewButton.visible = false;
				}
				else
				{
					dragNewButton.visible = true;
					dragNewButton.x = mouseX - (dragNewButton.cssSizeX * .5);
					dragNewButton.y = mouseY - (dragNewButton.cssSizeY * .5);
					
					var newIndex:int = -1;
					var L:int = itemList.numItems;
					
					for(var i:int=0; i<L; i++) {
						if(dragNewButton.hitTestObject(itemList.getItemAt(i))){
							newIndex = i;
							break;
						}
					}
					var it:Sprite;
					if( newIndex >= 0 && newIndex < itemList.numItems ) {
						it = Sprite( itemList.getItemAt( newIndex ) );
						if( it ) {
							dragDisplay.y = it.y;
						}
					}else if( pageItemNewIndex < 0 ) {
						it = itemList.getItemAt( itemList.numItems-1 );
						if( it ) {
							dragDisplay.y = it.y + CssSprite(it).cssSizeY;
						}
					}
					pageItemNewIndex = newIndex;
				}
			}
		}
		
		private function invalidateCurrArea ( testST:Boolean=false ) :void
		{
			CTTools.invalidateArea( currentArea.name );
			
			if( testST && CTTools.subTemplates )
			{
				var st:Template = null;
				var i:int;
				var L:int = CTTools.subTemplates.length;
				
				for(i = 0; i < L; i++ ) {
					if( CTTools.subTemplates[i].areasByName[ currentArea.name ] != undefined ) 
					{
						st = CTTools.subTemplates[i];
						break;
					}
				}
				
				if( st != null )
				{
					// Search Area of Page Item CTTools.currArea:
					if( CTTools.pageItems ) {
						L = CTTools.pageItems.length;
						for(i = 0; i < L; i++) {
							if( CTTools.pageItems[i].name == CTTools.currArea )
							{
								CTTools.invalidateArea( CTTools.pageItems[i].area );
								break;
							}
						}
					}
				}
			}
			
		}
		
		private function updateNextPageItemSorting ():void {
			if( pageItemCurr >= itemList.items.length ) {
				pageItemOldIndex = -1;
				pageItemNewIndex = -1;
				pageItemDragItem = null;
				
				invalidateCurrArea( true );
				
				try {
					Application.instance.view.panel.src["reloadClick"]();
				}catch(e:Error) {
					
				}
				Application.instance.hideLoading();
				if( CTOptions.autoSave ) CTTools.save();
				showAreaItems();
				return;
			}
			var pms:Object={};
			pms[":nam"] = itemList.items[pageItemCurr].options.result.name;
			pms[":sid"] = pageItemCurr;
			if( !CTTools.db.updateQuery( pageItemSortingUpdate, "pageitem", "name=:nam", "sortid=:sid", pms) ) {
				Console.log("ERROR in updating PageItem sort index");
				pageItemCurr++;
				updateNextPageItemSorting();
			}
		}
		private function pageItemSortingUpdate (res:DBResult):void {
			pageItemCurr++;
			updateNextPageItemSorting();
		}
		private function areappChange (e:PopupEvent) :void {
			var curr:PopupItem = e.selectedItem;
			var lb:String = curr.label;
			currentArea = curr.options.area;
			CTTools.currArea = lb;
			areapp.label = lb;
			if( CTOptions.rememberArea ) {
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( sh && sh.data) {
					sh.data.lastArea = lb;
					sh.flush();
					sh.close();
				}
			}
			if( CTOptions.previewInEditor && CTTools.procFiles )
			{
				setCurrPF();
			}
			showAreaItems();
		}
		
		private function setCurrPF () :void 
		{
			if( CTTools.activeTemplate )
			{
				var L:int, i:int, j:int, L2:int;
				
				if( CTTools.activeTemplate.areasByName[ CTTools.currArea ] != undefined ) 
				{ 
					L = CTTools.procFiles.length;
					currPF = null;
					
					for(i = 0; i < L; i++) 
					{
						L2 = CTTools.procFiles[i].templateAreas.length;
						for(j = 0; j < L2; j++) 
						{
							if( CTTools.procFiles[i].templateAreas[j].name == CTTools.currArea ) 
							{
								currPF = CTTools.procFiles[i];
								currItemName = CTTools.currArea;
								try {
									Application.instance.view.panel.src["displayFiles"]();
								}catch(e:Error) {
									
								}
								break;
							}
						}
						if ( currPF != null ) break;
					}
				
				}
				else
				{
					if( CTTools.subTemplates )
					{
						var st:Template=null;
						L = CTTools.subTemplates.length;
						for(i = 0; i < L; i++ ) {
							if( CTTools.subTemplates[i].areasByName[ CTTools.currArea ] != undefined ) 
							{
								st = CTTools.subTemplates[i];
								break;
							}
						}
						
						if( st != null )
						{
							var _currArea:String="";
							var _currItem:String="";
							
							// Search Area of Page Item CTTools.currArea:
							if( CTTools.pageItems ) {
								L = CTTools.pageItems.length;
								for(i = 0; i < L; i++) {
									if( CTTools.pageItems[i].name == CTTools.currArea )
									{
										_currArea = CTTools.pageItems[i].area;
										_currItem = CTTools.pageItems[i].name;
										break;
									}
								}
							}
							
							if( _currArea != "" && _currItem != "" )
							{
								L = CTTools.procFiles.length;
								
								currPF = null;
								
								for(i = 0; i < L; i++) 
								{
									L2 = CTTools.procFiles[i].templateAreas.length;
									for(j = 0; j < L2; j++) 
									{
										if( CTTools.procFiles[i].templateAreas[j].name == _currArea ) 
										{
											currPF = CTTools.procFiles[i];
											currItemName = _currItem;
											
											try {
												Application.instance.view.panel.src["displayFiles"]();
											}catch(e:Error) {
												
											}
											break;
										}
									}
									if ( currPF != null ) break;
								}
							}
						}else{
							
							if ( CTTools.articleProcFiles )
							{
								L = CTTools.articleProcFiles.length;
								
								for(i = 0; i < L; i++) 
								{
									if ( CTTools.articleProcFiles[i].templateAreas )
									{
										L2 = CTTools.articleProcFiles[i].templateAreas.length;
										for(j = 0; j < L2; j++) 
										{
											if( CTTools.articleProcFiles[i].templateAreas[j].name == CTTools.currArea ) 
											{
												currPF = CTTools.articleProcFiles[i];
												currItemName = CTTools.currArea;
												
												try {
													Application.instance.view.panel.src["displayFiles"]();
												}catch(e:Error) {
													
												}
												break;
											}
										}
										if ( currPF != null ) break;
									}
								}
								
								
							}
						}
						
					}
					
				}
			}
			//if( currPF ) trace("CURRPF: " + currPF.name);
			
		}
		private function plusClick (e:PopupEvent) :void{
			var curr:PopupItem = e.selectedItem;
			var rawName:String = curr.options.templateID;
			var T:Template = CTTools.findTemplate( rawName, "name" );
			if(T) {
				displayInsertForm(T);
			}else{
				Console.log("No Template found with the name : " + rawName);
			}
		}
		private function onAskInsert () :void {
			displayInsertForm( currentTemplate, false );
		}
		
		private function nextPageItem (e:Event) :void {
			if ( updateItem && areaItems && areaItems.length > 0)
			{
				var L:int = areaItems.length;
				
				for( var i:int=0; i<L; i++)
				{
					if( areaItems[i] && areaItems[i].name == updateItem.name )
					{
						if( L > i+1 && areaItems[i+1] )
						{
							var T:Template = CTTools.findTemplate( areaItems[i+1].subtemplate, "name" );
							if( T ) {
								updateItem = areaItems[i+1];
								displayInsertForm( T, true );
							}else Console.log("ERROR: Can not find Template '" + areaItems[i+1].subtemplate + "' for Page Item: " +  areaItems[i+1].name);
							
							
							break;
						}
					}
				}
			}
		}
		private function prevPageItem (e:Event) :void {
			if ( updateItem ) {
				var L:int = areaItems.length;
				
				for( var i:int=L-1; i>=0; i--)
				{
					if( areaItems[i] && areaItems[i].name == updateItem.name )
					{
						if( i>0 && areaItems[i-1] )
						{
							var T:Template = CTTools.findTemplate( areaItems[i-1].subtemplate, "name" );
							if( T ) {
								updateItem = areaItems[i-1];
								displayInsertForm( T, true );
							}else Console.log("ERROR: Can not find Template '" + areaItems[i-1].subtemplate + "' for Page Item: " +  areaItems[i-1].name);
							
							break;
						}
					}
				}
				
				
			}
		}
		private function cancelPageItem (e:Event) :void {
			// reset ram-db values
			if( _isUpdateForm && initValues ) {
				if( CTTools.pageItemTable[ updateItem.name ] != undefined ) {
					for ( var nam:String in initValues ) {
						if( CTTools.pageItemTable[ updateItem.name ] && updateItem.name && initValues[nam].name &&  initValues[nam].value  ) {
							CTTools.pageItemTable[ updateItem.name ][ initValues[nam].name ] = initValues[nam].value;
						}
					}
				}
			}
			
			showAreaItems();
		}
		public function multiSelDelete () :void {
			if( selection && selection.length > 0 )
			{
				var win:Window = Window( Application.instance.window.GetBooleanWindow( "DeleteItemMsg", Language.getKeyword("Delete Items Alert"), Language.getKeyword("CT-Delete-Items-MSG"), {
				complete: multiDeleteOK,
				continueLabel:Language.getKeyword( "Delete-MSG-Yes" ),
				allowCancel: true,
				autoWidth:false,
				autoHeight:true,
				cancelLabel: Language.getKeyword("Delete-MSG-Cancel")
				}, 'multidelete-yn-window') );
				
				Application.instance.windows.addChild( win );
				
			}
		}
		private function multiDeleteOK (v:Boolean) :void {
			if(v) {
				var pms:Object = {};
				var where:String = "uid IN (";
				
				for( var i:int=0; i < selection.length; i++ )
				{
					where += " :uid"+i+",";
					pms[':uid'+i] = CTTools.pageItemTable[ selection[i] ].uid;
				}
				
				var rv:Boolean = CTTools.db.deleteQuery( onMultiDeletePageItem, "pageitem", where.substring( 0, where.length-1 ) + ")", pms);
				
				if( ! rv ) Console.log("ERROR Deleting Page Item from DB");
				else Application.instance.showLoading();
			}
		}
		private var delTables:Array;
		
		private function onMultiDeletePageItem (res:DBResult) :void {
			if( res && res.rowsAffected ) {
				if( selection && selection.length > 0 )
				{
					var tbStore:Object = {};
					
					for( var i:int=0; i < selection.length; i++ )
					{
						var T:Template = CTTools.findTemplate( CTTools.pageItemTable[ selection[i] ].subtemplate, "name" );
						
						if( T ) {
							if( !tbStore[T.name] ) {
								tbStore[T.name] = { where:":uid" + i +",", tbl:T.tables, pms:{} };
							}else{
								tbStore[T.name].where += ":uid" + i +",";
							}
							tbStore[T.name].pms[':uid'+i] = CTTools.pageItemTable[ selection[i] ].ext_uid;
						}
					}
					
					var tbls:Array = [];
					for(var id:String in tbStore) {
						
						tbStore[id].where = tbStore[id].where.substring( 0, tbStore[id].where.length-1 );
						tbls.push( tbStore[id] );
					}
					onMultiDeleteNext();
				}
				else
				{
					Application.instance.hideLoading();	
				}
			}
		}
		private function onMultiDeleteNext (res:DBResult=null) :void
		{
			if( delTables && delTables.length > 0 ) {
				var next:Object = delTables.pop();
				var rv:Boolean = CTTools.db.deleteQuery( onMultiDeleteNext, next.tbl, next.where, next.pms);
						
				if( ! rv ) {
					Console.log("ERROR Deleting Page Item Extension Table from DB");
					Application.instance.hideLoading();
				}
			}else{
				// all deleted..
				onMultiDeletePageItemExtensionTable();
			}
		}
		private function onMultiDeletePageItemExtensionTable (res:DBResult=null) :void {
			// Delete object from CTTools.pageItems and CTTools.pageItemTable
			var pg:Array = CTTools.pageItems;
			
			for( var i:int = pg.length-1; i>=0; i--)
			{
				if( selection.indexOf( pg[i].name ) >= 0 ) {
					CTTools.pageItemTable[ pg[i].name ] = null;
					CTTools.pageItems.splice( i, 1 );
				}
			}
			
			invalidateCurrArea( true );
			
			if( CTOptions.autoSave ) CTTools.save();
			
			if( currentTemplate && currentTemplate.numAreas > 0 ) {
				create();
			}
			
			try {
				Application.instance.view.panel.src["reloadClick"]();
			}catch(e:Error) {
				
			}
			
			Application.instance.hideLoading();
			showAreaItems();
		}
		
		private function deleteItemOK (bool:Boolean) :void {
			if( bool ) {
				// Delete updateItem
				if( updateItem ) {
					if( updateItem.uid ) {
						// Delete Page Item
						var pms:Object = {};
						pms[":uid"] = updateItem.uid;
						var rv:Boolean = CTTools.db.deleteQuery( onDeletePageItem, "pageitem", "uid=:uid", pms);
						if( ! rv ) Console.log("ERROR Deleting Page Item from DB");
						else Application.instance.showLoading();
					}else{
						Console.log("ERROR: Update Item Without Uid: " + updateItem );
					}
				}else{
					Console.log("ERROR: Nothing To Delete..");
				}
			}
		}
		private function onDeletePageItem (res:DBResult) :void {
			if( res && res.rowsAffected ) {
				// Delete extension table
				if( updateItem && updateItem.ext_uid ) {
					var pms:Object = {};
					pms[":uid"] = updateItem.ext_uid;
					var rv:Boolean = CTTools.db.deleteQuery( onDeletePageItemExtensionTable, currentTemplate.tables, "uid=:uid", pms);
					if( ! rv ) {
						Console.log("ERROR Deleting Page Item Extension Table from DB");
						Application.instance.hideLoading();
					}
				}else {
					Application.instance.hideLoading();	
				}
			}
		}
		private function onDeletePageItemExtensionTable (res:DBResult) :void {
			if( res && res.rowsAffected > 0 ) {
				// Delete object from CTTools.pageItems and CTTools.pageItemTable
				for( var i:int = CTTools.pageItems.length-1; i>=0; i--) {
					if( CTTools.pageItems[i].name == updateItem.name ) {
						CTTools.pageItems.splice( i, 1 );
						CTTools.pageItemTable[ updateItem.name ] = null;
						updateItem = null;
						break;
					}
				}
			}
			
			invalidateCurrArea( true );
			
			if( CTOptions.autoSave ) CTTools.save();
			if( currentTemplate && currentTemplate.numAreas > 0 ) {
				create();
			}
			
			try {
				Application.instance.view.panel.src["reloadClick"]();
			}catch(e:Error) {
				
			}
			
			Application.instance.hideLoading();
			showAreaItems();
		}
		
		// click handler
		private function deletePageItem ( e:Event ) :void {
			var win:Window = Window( Application.instance.window.GetBooleanWindow( "DeleteItemMsg", Language.getKeyword("Delete Item Alert"), Language.getKeyword("CT-Delete-Item-MSG"), {
				complete: deleteItemOK,
				continueLabel:Language.getKeyword( "Delete-MSG-Yes" ),
				allowCancel: true,
				autoWidth:false,
				autoHeight:true,
				cancelLabel: Language.getKeyword("Delete-MSG-Cancel")
				}, 'delete-yn-window') );
			Application.instance.windows.addChild( win );
			
			// 
			// TODO
			//
			// Test for file input objects and ask to delete files if available..
			//
			// .. 
			//
		}
		
		private function updatePageItem ( e:Event ) :void {
			if( updateItem ) {
				var pms:Object={};
				pms[":_name"] = updateItem.name;
				pms[":_visible"] = updateItem.visible;
				pms[":_uid"] = updateItem.uid;
				var rv:Boolean = CTTools.db.updateQuery( onUpdateItem, "pageitem", "uid=:_uid", "name=:_name,visible=:_visible", pms);
				if( rv ) Application.instance.showLoading();
			}
		}
		
		private function onUpdateItem (res:DBResult) :void
		{
			if( res ) {
				var pms:Object={};
				// update ex_tables
				if( updateItem && updateItem.ext_uid != undefined && currentTemplate.tables && currentTemplate.fields ) {
					var fieldVal:String = "name=:_name";
					pms[":_name"] = updateItem.name;
					pms[":_uid"] = updateItem.ext_uid;
					var fields:Array = currentTemplate.fields.split(",");
					var pc:PropertyCtrl;
					var L:int = fields.length;
					var i:int;
					
					for(i=0; i < L; i++)
					{
						// fill pms and build query...
						if( fields[i] == "crdate")
						{
							pms[ ":_crdate"] = "now";
							fieldVal += ',crdate=:_crdate';
						}
						else if( fields[i] != "name")
						{
							pc = PropertyCtrl( itemList.getChildByName( fields[i] ) );
							if( pc )
							{
								if( pc.type == "file" || pc.type == "image" || pc.type == "video" || pc.type == "audio" || pc.type == "pdf") {
									storeFile( pc.textBox );
									if( updateItem ) {
										updateItem[ fields[i] ] = pc.textBox.value;
									}
								}else if( pc.type == "vector" && (pc.textBox.vectorType == "file" || pc.textBox.vectorType == "image" || pc.textBox.vectorType == "video" || pc.textBox.vectorType == "audio"  || pc.textBox.vectorType == "pdf" )) {
									storeFileVector( pc.textBox );
								}
							}
							pms[ ":_"+ fields[i] ] = pc ? pc.textBox.value : "";
							fieldVal += ','+fields[i]+'=:_' +  fields[i];
						}
					}
					
					if( currentTemplate.articlepage != "" )					 
					{
						// create article page with db fields
						// var props:Object = { inputname: pms[":_name"] };
						props = { inputname: pms[":_name"] };
						
						
						for( i = 0; i < L; i++)
						{
							pc = PropertyCtrl( itemList.getChildByName( fields[i] ) );
							props[ fields[i] ] = pc ? pc.textBox.value : "";
						}
						
						props["itemtemplate"] = currentTemplate.name;
						props["name"] = nameCtrl.textBox.value;
						
						var filename:String = "";
						var fi:FileInfo;
						
						if( currentTemplate.articlename != "" )
						{
							filename = CTTools.webFileName( currentTemplate.articlename, props );
						}
						else
						{
							fi = FileUtils.fileInfo( currentTemplate.articlepage );
							
							filename = pms[":_name"] + "." + fi.extension;
						}
						
						fi = FileUtils.fileInfo( filename );
						
						articlePageWritten = false;
						articleAreasInvalid = false;
						
						if ( !PageEditor.createPage( fi.name, true, "", "article", currentTemplate.name + ":" + currentTemplate.articlepage, props["inputname"], fi.path, "now", onArticlePage, props) )
						{
							Console.log( "Error: Create " + fi.name + " Page");
						}
					}
					
					var rv:Boolean = CTTools.db.updateQuery( onUpdateExtensionItem, currentTemplate.tables, "uid=:_uid", fieldVal, pms);
					if( !rv) {
						Console.log( "ERROR Updating Item Extension Table " + updateItem + ", uid: " + updateItem.ext_uid + ", tmpl: " + currentTemplate + ", fields: " + currentTemplate.fields);
						Application.instance.hideLoading();
					}
				}else{
					Console.log( "ERROR Updating Page Item Table " + updateItem + ", uid: " + updateItem.ext_uid + ", tmpl: " + currentTemplate + ", fields: " + currentTemplate.fields);
					Application.instance.hideLoading();
				}
			}
		}
		private function onUpdateExtensionItem (res:DBResult) :void {
			Application.instance.hideLoading();
				
			if(updateItem) {
				currItemName = updateItem.name;
			}else{
				currItemName = "";
			}
			
			invalidateCurrArea(true );
			
			if( CTOptions.autoSave ) CTTools.save();
			
			if ( !saveInline )
			{
				if ( currentTemplate.articlepage != "" ) {
					if ( currentTemplate.articlepage != "" ) {
						if(articlePageWritten) {
							
							//Application.instance.cmd( "Application restart");
							showAreaItems();
							return;
						}else{
							articleAreasInvalid = true;
						}
					}
				}else{
					if( currentTemplate && currentTemplate.numAreas > 0 ) {
						create();
					}
				}
			
				showAreaItems();
			}else{
				storeCurrentItemValues();
				saveInline = false;
			}
			
			Application.instance.hideLoading();
			
			// try reload preview:
			try {
				Application.instance.view.panel.src["reloadClick"]();
			}catch(e:Error) {
				
			}
		}
		
		private function insertPageItem ( e:Event ) :void {
			// Try select page item with name first
			var pms:Object = {};
			pms[":nam"] = nameCtrl.textBox.value;
			var rv:Boolean = CTTools.db.selectQuery( onPageItemInsertSelect, "uid,name", "pageitem", "name=:nam", "", "", "", pms);
			if(!rv) {
				Console.log("SQL-ERROR in Select Page Item");
				onPageItemInsertSelect(null);
			}
			
			Application.instance.showLoading();
		}
		
		private function onPageItemInsertSelect (res:DBResult) :void {
			if (res && res.data && res.data.length > 0 ) {
				Application.instance.hideLoading();
				
				// Page Item already available...
				var win:Window = Window( Application.instance.window.InfoWindow( Language.getKeyword("Information"), Language.getKeyword("Page Item Already Available"), Language.getKeyword("The Item") +" '"+
				nameCtrl.textBox.value+ "' "+ Language.getKeyword("is already in the database"), {
				continueLabel:Language.getKeyword("OK"),
				allowCancel: false,
				autoWidth:false,
				autoHeight:true,
				cancelLabel: ""}, 'pageitem-insert-window') );
				
				Application.instance.windows.addChild( win );
				
			}else{				
				if( itemList ) {
					var _areaItems:int;
					
					if( newInsertSortID >= 0 ) {
						_areaItems = newInsertSortID;
					}else{
						_areaItems = itemList.numItems;
					}
					
					var pms:Object={};
					pms[":nam"] = nameCtrl.textBox.value;
					pms[":vis"] = nameCtrl.visibleStatus;
					pms[":tmpl"] = currentTemplate.name;
					pms[":ara"] = currentArea.name;
					pms[":sortid"] = _areaItems; // Last
					pms[":date"] = "now";
					
					newPageItemTmp = { name: pms[":nam"], area: pms[":ara"], sortid: pms[":sortid"], subtemplate: pms[":tmpl"], crdate: "" };
					var rv:Boolean = CTTools.db.insertQuery( onPageItemInsert, "pageitem", "name,visible,area,sortid,subtemplate,crdate", ":nam,:vis,:ara,:sortid,:tmpl,:date", pms);
					
					if(!rv) { 
						Console.log("SQL-ERROR in inserting PageItem " + pms[":nam"]);
						Application.instance.hideLoading();
					}
				}
			}
		}
		private static var props:Object;
		private static var articlePageWritten:Boolean=false;
		private static var articleAreasInvalid:Boolean=false;
		
		private function onPageItemInsert  (res:DBResult) :void {
			if (res && res.rowsAffected > 0) 
			{
				newPageItemTmp.uid = res.lastInsertRowID;
				
				// insert into ex_tables
				if ( currentTemplate.tables && currentTemplate.fields && itemList )
				{
					insertFileStore = [];
					var i:int;
					var L:int;
					var pc:PropertyCtrl;
					var fieldVal:String = ":_name";
					var fields:Array = currentTemplate.fields.split(",");
					var pms:Object = {};
					pms[":_name"] = nameCtrl.textBox.value;
					
					L = fields.length;
					for (i = 0; i < L; i++) 
					{
						// build query...
						
						if( fields[i] == "crdate") {
							pms[ ":_"+ fields[i] ] = "now";
							fieldVal += ",:_crdate";
						}
						else if( fields[i] != "name") {
							pc = PropertyCtrl( itemList.getChildByName( fields[i] ) );
							if(pc) {
								
								if( pc.type == "file" || pc.type == "image" || pc.type == "video" || pc.type == "audio" || pc.type == "pdf")
								{
									storeFile( pc.textBox );
								}
								else if( pc.type == "vector" && (pc.textBox.vectorType == "file" || pc.textBox.vectorType == "image" || pc.textBox.vectorType == "video" || pc.textBox.vectorType == "audio" || pc.textBox.vectorType == "pdf")  )
								{
									storeFileVector( pc.textBox );
								}
							}
							pms[ ":_"+ fields[i] ] = pc ? pc.textBox.value : "";
							fieldVal += ",:_" +  fields[i];
						}
						
						currItemName = newPageItemTmp.name;
						
						// Copy to internal db data...
						newPageItemTmp[ fields[i] ] = pms[ ":_"+ fields[i] ];
					}
					
					if( currentTemplate.articlepage != "" )					 
					{
						// create article page with db fields
						//var props:Object = { inputname: pms[":_name"] };
						props = { inputname: pms[":_name"] };
						
						for( i = 0; i < L; i++)
						{
							pc = PropertyCtrl( itemList.getChildByName( fields[i] ) );
							props[ fields[i] ] = pc ? pc.textBox.value : "";
						}
						
						props["itemtemplate"] = currentTemplate.name;
						props["name"] = nameCtrl.textBox.value;
						
						var filename:String = "";
						var fi:FileInfo;
						
						if( currentTemplate.articlename != "" )
						{
							filename = CTTools.webFileName( currentTemplate.articlename, props );
						}
						else
						{
							fi = FileUtils.fileInfo( currentTemplate.articlepage );
							
							filename = pms[":_name"] + "." + fi.extension;
						}
						
						fi = FileUtils.fileInfo( filename );
						
						articlePageWritten = false;
						articleAreasInvalid = false;
						
						if ( !PageEditor.createPage( fi.name, true, "", "article", currentTemplate.name + ":" + currentTemplate.articlepage, props["inputname"], fi.path, "now", onArticlePage, props) )
						{
							Console.log( "Error: Create " + fi.name + " Page");
						}
					}
					
					var rv:Boolean = CTTools.db.insertQuery(onInsertExTable, currentTemplate.tables, currentTemplate.fields, fieldVal, pms);
					if(!rv) {
						Application.instance.hideLoading();
						Console.log("ERROR Inserting Item Extension Table " + pms[":_name"]);
					}
				}
				
				// Construct inline db-item
				CTTools.pageItems.push( newPageItemTmp );
				CTTools.pageItemTable[newPageItemTmp.name] = newPageItemTmp;
			}
		}
		
		private function onArticlePage ( success:Boolean ) :void
		{
			if ( success )
			{
				var s:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderTemplate + CTOptions.urlSeparator + (PageEditor._ltPage.webdir ? PageEditor._ltPage.webdir + CTOptions.urlSeparator : "") + PageEditor._ltPage.filename;
				var pf:ProjectFile = CTTools.findArticleProjectFile( s, "path" );
				
				if ( pf ) {
					pf.allDirty();
					CTTools.saveArticleFile( pf, PageEditor._ltPage.webdir );
				}
				
				articlePageWritten = true;
								
				if ( articleAreasInvalid )
				{
					//Application.instance.cmd( "Application restart");
					showAreaItems();
					//create();
				}
			}
		}
		
		private function onInsertExTable  (res:DBResult) :void {
			if(res && res.rowsAffected ) {
				newPageItemTmp.ext_uid = res.lastInsertRowID;
				Application.instance.hideLoading();
				
				if( newInsertSortID >= 0 ) {
					newInsertSortID = -1;
					showAreaItems();
					dragSaveClickHandler(null);
					pageItemDragging = false;
				}else{
					
					invalidateCurrArea( true );
					
					if ( CTOptions.autoSave ) CTTools.save();
					
					// rebuild area tree for new areas..
						
					if ( currentTemplate.articlepage != "" ) {
						if(articlePageWritten) {
							//create();
							//Application.instance.cmd( "Application restart");
							showAreaItems();
							return;
						}else{
							articleAreasInvalid = true;
						}
					}else{
						if( currentTemplate && currentTemplate.numAreas > 0 ) {
							create();
						}
					}
					Application.instance.hideLoading();
					
					if(!saveInline) {
						showAreaItems();
					}else{
						storeCurrentItemValues();
						saveInline = false;
					}
					
					try {
						Application.instance.view.panel.src["reloadClick"]();
					}catch(e:Error) {
						
					}
				}
			}else{
				Console.log( "ERROR In Insert Page Item Extension");
				Application.instance.hideLoading();
				showAreaItems();
			}
		}
		
		private function onFilesInserted(res:DBResult) :void {
			Application.instance.hideLoading();
			showAreaItems();
		}
		
		private function storeFileVector (pc_textBox:InputTextBox) :void {
			if( pc_textBox.vectorTextFields )
			{
				var L:int = pc_textBox.vectorTextFields.length;
				
				for(var i:int =0 ; i<L; i++) {
					storeFile( pc_textBox.vectorTextFields[i], i );
				}
				pc_textBox.textEnter();
			}
		}
		
		private function storeFile (pc_textBox:InputTextBox, vectorIndex:int=-1) :void {
			
			var fileHere:Boolean = false;
			var filePath:String = "";
						
			// should clear old files before selection.
			
			if( pc_textBox.value == "" || pc_textBox.value.toLowerCase() == "none" ) {
				return;
			}
			
			// test if new file is in www-directory, new file paths always begin with file:///
			var tf:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + pc_textBox.value );
			if( tf && tf.exists ) {
				return;
			}

			// test if path is relative website path in file www_folder setup
			/*var testfile:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + pc_textBox.www_folder + CTOptions.urlSeparator + pc_textBox.value );
			if( testfile && testfile.exists ) {
				return;
			}*/
			
			var pcpath:String = pc_textBox.value;
			var endslash:int = pcpath.lastIndexOf(CTOptions.urlSeparator);
			
			var filename:String;
			if( endslash >= 0 ) {
				filename = pcpath.substring(endslash+1);
			}else{
				filename = pcpath;
			}

			var newname:String = filename;
			
			if( pc_textBox.rename_template )
			{
				var d:Date = new Date();
				var obj:Object = {};

				obj.extension = "";
				var pid:int = filename.lastIndexOf(".");
				if( pid >= 0 ) obj.extension = filename.substring(pid+1);
				
				obj.year = d.fullYear;
				obj.month = d.month+1;
				obj.day = d.day;
				obj.date = d.date;
				obj.hours = d.hours;
				obj.minutes = d.minutes;
				obj.seconds = d.seconds;
				//obj.milliseconds = d.milliseconds;
				obj.time = d.time;
				obj.timezoneOffset = d.timezoneOffset;
				obj.vectorindex = vectorIndex;
				
				if(nameCtrl) {
					obj["inputname"] = nameCtrl.textBox.value;
				}
				
				if( pc_textBox.propObj ) {
					for( var nm:String in pc_textBox.propObj ) {
						obj[nm] = pc_textBox.propObj[nm];
					}
				}else{
					obj.name = InputTextBox.getUniqueName("file-");
					obj.sortid = 0;
					obj.uid = 0;
				}
				
				newname = TemplateTools.obj2Text( pc_textBox.www_folder + CTOptions.urlSeparator + pc_textBox.rename_template, "#", obj );
			}else{
				newname = pc_textBox.www_folder + CTOptions.urlSeparator + newname;
			}
			
			// test if the text-box value is a www-file renamed.. otherwise copy file to raw and min folders...
			var file:File = new File( CTTools.projectDir + CTOptions.urlSeparator + 
							CTOptions.projectFolderRaw + CTOptions.urlSeparator + newname);
			
			if( file.exists ) {
				if( CTOptions.debugOutput ) {
					Console.log( "WARNING: '" + file.url + "' Already Exists..");
				}
			}
			var f1:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + newname ;
			var f2:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + newname;
			
			CTTools.copyFile( pc_textBox.value, f1 );
			CTTools.copyFile( pc_textBox.value, f2 );
			
			// Rewrite textbox to new name
			pc_textBox.value = newname;
			
			ResourceMgr.getInstance().clearResourceCache( f1 );
			ResourceMgr.getInstance().clearResourceCache( f2 );
			// Display new image...
			
		}
		private function ictChange ( e:Event ) :void {
			var it:PropertyCtrl = PropertyCtrl( e.currentTarget );
			
			if( updateItem ) {
				// Update Mode
				if( it._name == "name" ) {
					updateItem[ "name" ] = it.textBox.value;
					updateItem[ "visible" ] = NameCtrl(it).visibleStatus;
				}else{
					updateItem[ it._name ] = it.textBox.value;
				}
			 }
			
			var i:int;
			var L:int;
			
			// Test if template splits changed
			if ( currentTemplate && tmplSplitPaths != "" )
			{
				//Insert in tmpl->dbprops
				if( currentTemplate.dbProps[ it._name ] != undefined) {
					currentTemplate.dbProps[ it._name ].value = it.textBox.value;
				}else{
					// Create new item cause is not stored in the db
					currentTemplate.dbProps[ it._name ] = { name:it._name, visible:true, value:it.textBox.value, type:it.type, argv:(it.options.propObject ? it.options.propObject.argv : ""), args:(it.options.propObject ? it.options.propObject.args : null) };
				}
				
				// Files have to update  constant values
				CTTools.invalidateTemplateFiles ( currentTemplate, true );
				
				// search actual split path
				L = CTTools.procFiles.length;
				var tmppath:String = "";
				
				for (i=0; i<L; i++) {
					if(CTTools.procFiles[i].templateId == currentTemplate.name) {
						if ( CTTools.procFiles[i].splits ) {
							tmppath += CTTools.procFiles[i].splitPath;
						}
					}
				}
				
				if ( tmplSplitPaths != tmppath )
				{
					// store all menu values, reload interface and enterback the values
					tmpValues = {};
					L = itemList.numChildren;
					var pc:PropertyCtrl;
					
					for(i=0; i<L; i++) {
						if( itemList.items[i] is PropertyCtrl ) {
							pc = PropertyCtrl( itemList.items[i] );
							tmpValues[ pc._name ] = { value: pc.textBox.value }
						}
					}
					var tmp:Object = updateItem;
					displayInsertForm( currentTemplate, updateItem != null );
					updateItem = tmp;
					// Enter back the values
					for( i=0; i<itemList.numChildren; i++) {
						if( itemList.items[i] is PropertyCtrl ) {
							pc = PropertyCtrl( itemList.items[i] );
							if( tmpValues[ pc._name ] ) {
								pc.textBox.value  = tmpValues[pc._name].value;
							}
						}
					}
				}
				
			}
		
		}
	}
}
