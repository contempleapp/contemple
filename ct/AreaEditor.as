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
	import agf.io.*;
	import agf.ui.*;
	import agf.io.ResourceMgr;
	import agf.Main;
	import agf.Options;
	import agf.animation.Animation;
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
	import flash.utils.ByteArray;
	import fl.transitions.easing.Regular;
	import fl.transitions.easing.Strong;
	
	public class AreaEditor extends AreaProcessor
	{
		public function AreaEditor( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
			_clickScrolling = false;
			Application.instance.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
			createAed();
		}
		
		private function removePanel (e:Event) :void {
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
				stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
			}
			if( areapp && contains(areapp)) removeChild( areapp );
			if( areaView && contains(areaView)) removeChild( areaView );
			if( sizeButton && contains(sizeButton)) removeChild( sizeButton );
			if( nameCtrl && contains(nameCtrl)) removeChild( nameCtrl );
			Main(Application.instance).view.removeEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		public static var currPF:ProjectFile=null;
		public static var currItemName:String="";		
		public static var minW:Number=32;
		private static var menuStore:Object={};
		private static var areapp:Popup;
		internal static var areaView:AreaView;
		
		public static function get _areaView () :AreaView {
			return areaView;
		}
		public var lastAreaName:String="";
		public var sizeButton:Button;
		protected var nameCtrl:NameCtrl;
		
		private static var dpth:int=0;
		private static var viewSize:Number = 190;
		private static var newInsertSortID:int=-1;
		private static var props:Object;
		private static var _args:Object;
		private static var _tmpl:Object;
		private static var articlePageWritten:Boolean=false;
		private static var articleAreasInvalid:Boolean=false;
		private var clickY:Number=0;
		private var _h:int=0;
		private var tmplSplitPaths:String;
		private var insertFileStore:Array;
		private var tmpValues:Object;
		
		private var viewSizeStartX:Number=0;
		private var areasVisible:Boolean = true;
		private static var tmpViewSize:Number=0;
		private var _isUpdateForm:Boolean=false;
		private var saveInline:Boolean=false;
		private var dragNewId:int=0;
		private var dragNewName:String="";
		private var dragNewButton:Button;
		
		private var folderBackBtn:Button;
		private var folderLabel:Label;
		
		private var tabs:ItemBar;
		private var tabsPP:Popup;
		
		private static var areaTreeDirty:Boolean = true;
		public static function invalidateAreaTree () :void {
			areaTreeDirty = true;
		}
		
		protected function btnUp (event:MouseEvent) :void {
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
		}
		protected function btnMove (event:MouseEvent) :void {
			var dy:Number = mouseY - clickY;
			
			if( ! clickScrolling ) {
				if( Math.abs(dy) > CTOptions.mobileWheelMove ) {
					clickScrolling = true;
				}
			}else{
				// scroll
				scrollpane.slider.value -= dy;
				scrollpane.scrollbarChange(null);
				clickY = mouseY;
			}
		}
		protected function btnDown (event:MouseEvent) :void {
			stage.addEventListener( MouseEvent.MOUSE_MOVE, btnMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, btnUp );
			clickScrolling = false;
			clickY = mouseY;
		}
		
		public static function get clickScrolling () : Boolean {
			return _clickScrolling || AreaView.clickScrolling;
		}
		public static function set clickScrolling (v:Boolean) :void {
			_clickScrolling = v;
			AreaView.clickScrolling = v; 
		}
		private static var _clickScrolling:Boolean = false;
			
		public function abortClickScrolling () :void {
			btnUp(null);
			clickScrolling=false;
		}
		
		public override function createAed () :void
		{
			if( areapp && contains(areapp)) removeChild( areapp );
			if( areaView && contains(areaView)) removeChild( areaView );
			if( sizeButton && contains(sizeButton)) removeChild( sizeButton );
			if( nameCtrl && contains(nameCtrl)) removeChild( nameCtrl );
			
			if( areaTreeDirty )
			{
				if (CTTools.activeTemplate)
				{
					currentTypes = "undefined";
					
					var i:int;
				
					if (CTTools.procFiles && CTTools.activeTemplate.indexFile && CTTools.projectDir )
					{
						menuStore = {};
						
						areaView = new AreaView( 0,0,this,styleSheet,'areaview','','area-view',false);
						areaView.editor = this;
						
						var pth:String;
						var pfid:int ; 
						var pf:ProjectFile;
						
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
						
						areapp = new Popup([new IconArrowDown( Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize ), "none" ], 0, 0, this, styleSheet, '', 'areaeditor-areapopup', false);
						areapp.visible = false;
						removeChild( areapp );
						
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
						areaView.rootNode.format(false);
						
						areaView.rootNode.addEventListener( "animationFrame", areaAnimFrame);
						areaView.rootNode.addEventListener( "animationComplete", areaAnimComplete);
					}
				}
				
				areaTreeDirty = false;
			}
			else
			{
				// use cached Area Tree..
				areaView.editor = this;
				addChild( areaView );
			}
			
			sizeButton = new Button ([],0,0,this,styleSheet,'','area-sizebutton',false);
			sizeButton.addEventListener( MouseEvent.MOUSE_DOWN, viewSizeDown );
			
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
			
			showAreaItems();
			if( CTOptions.previewInEditor && CTTools.procFiles ) {
				setCurrPF();
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
							bt.options.itemTree = tr;
							bt.addEventListener(MouseEvent.CLICK, areaClick);
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
					bt.options.itemTree = tr;
					bt.addEventListener(MouseEvent.CLICK, areaClick);
					bt.autoSwapState = "";
					treeNode.addItem( bt, false );
				}
			}
		}
		private static var treeStack:Array=null;
		
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
				else if( arr[i] is Button )
				{
					bt = Button(arr[i]);
					
					if( bt.label == lastAreaName )
					{
						bt.swapState("active");
						bt.labelSprite.swapState("active");
						
						if( ! dontOpen ) {
							// open parents
							it = ItemTree( bt.options.itemTree );
							if( it ) {
								while( it != null ) {
									it.open(null);
									it = it.parentTree;
								}
							}
						}
					}else if( bt.labelSprite.state != "normal" ) {
						bt.swapState("normal");
						bt.labelSprite.swapState("normal");
					}
				}
			}
		}
		
		private function areaAnimFrame (e:Event) :void {
			if( areaView ) {
				areaView.scrollpane1.contentHeightChange();
			}
		}
		private function areaAnimComplete (e:Event) :void {
			if( areaView ) {
				areaView.scrollpane1.contentHeightChange();
			}
		}
		private function areaSectionClick (e:MouseEvent) :void {
			e.stopImmediatePropagation();
			if( areaView ) {
				setCurrArea( areaView.itemList1, true );
				areaView.scrollpane1.contentHeightChange();
			}
		}
		
		private function areaClick (e:MouseEvent) :void {
			e.stopImmediatePropagation();
			e.preventDefault();
			
			if( clickScrolling )
			{
				clickScrolling = false;
			}
			else
			{
				var bt:Button = Button(e.currentTarget);
				var lb:String = bt.label;
				var s:Array = areapp.rootNode.search( lb );
				
				if( s && s.length > 0 )
				{
					var curr:PopupItem = s[0];
					currentArea = curr.options.area;
					CTTools.currArea = curr.label;
					areapp.label =  curr.label;
						
					if( CTOptions.rememberArea ) {
						var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
						if( sh && sh.data) {
							sh.data.lastArea = lb;
							sh.flush();
							sh.close();
						}
					}
					
					showAreaItems();
					
					if( CTOptions.previewInEditor && CTTools.procFiles ) {
						setCurrPF();
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
									nd = nd.addItem([secs[j], new IconArrowRight(Application.instance.mainMenu.iconColor, 1, Options.iconSize, Options.iconSize)], styleSheet);
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
		
		private function viewSizeDown (e:MouseEvent) :void {
			if( e ) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}
			if( stage ) {
				stage.addEventListener( MouseEvent.MOUSE_UP, viewSizeUp );
				addEventListener( Event.ENTER_FRAME, viewSizeFrame );
				viewSizeStartX = mouseX;
			}
		}
		
		private function viewSizeUp (e:MouseEvent) :void {
			if( e ) {
				e.stopImmediatePropagation();
				e.preventDefault();
			}
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_UP, viewSizeUp );
				removeEventListener( Event.ENTER_FRAME, viewSizeFrame );
			}
			if( areaView ) {
				setCurrArea( areaView.itemList1 );
			}
		}
		
		private function viewSizeFrame (e:Event) :void {
			if( mouseX < minW ) {
				viewSize = minW;
			}else if( mouseX > getWidth() - minW ) {
				viewSize = getWidth() - minW;
			}else{
				viewSize = mouseX;
			}
			
			//setWidth( getWidth() );
			try {
				Application.instance.view.panel.src.newSize(null);
			}catch(e:Error) {
				Console.log("Error: " + e);
			}
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
		
		public override function setWidth ( w:int ) :void
		{			
			super.setWidth(w);
			
			var avw:Number = Math.floor(  viewSize );
			
			if( areaView ) {
				areaView.x = 0;
				areaView.setWidth( avw );
			}
			
			w = Math.floor( w - viewSize );
			
			var sbw:int = 0;
			if( scrollpane && scrollpane.slider.visible ) sbw = scrollpane.slider.cssSizeX + 4;
			
			if( nameCtrl ) {
				nameCtrl.setWidth(  w - (nameCtrl.cssBoxX + cssBoxX) ); 
				nameCtrl.x = cssLeft + avw;
			}
			 var i:int;
			if( itemList) {
				InputTextBox.heightDirty = false;
					
				if(itemList.items) {
					for(i=0; i < itemList.items.length; i++) {
						if( itemList.items[i].visible ) {
							itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + cssBoxX + sbw ) );
						}
					}
					
					if( InputTextBox.heightDirty )
					{
						var yp:int = 0;
						for( i=0; i < itemList.items.length; i++) {
							//itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + cssBoxX + sbw) );
							if( itemList.items[i].visible ) {
								if( ! (itemList.items[i] is PropertyCtrl) ) {
									
									itemList.items[i].y = int(yp);
									yp += itemList.items[i].cssSizeY + itemList.margin;
								}else{
									
									
									itemList.items[i].y = int(yp);
									yp += PropertyCtrl(itemList.items[i]).textBox.cssSizeY +  PropertyCtrl(itemList.items[i]).textBox.y + PropertyCtrl(itemList.items[i]).cssBoxY + itemList.margin;
								}
							}
						}
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
					if( HtmlEditor.isPreviewOpen && !CTOptions.previewAtBottom ) pw = HtmlEditor.previewX - (px);
					else pw = getWidth() - (px);
					multiSelectMenu.y = -cssTop;
				}else{
					pw = getWidth() ;
					multiSelectMenu.y = areapp.y;
				}
				multiSelectMenu.x = px;
				multiSelectMenu.setWidth( pw - multiSelectMenu.cssBoxX );
			}
			
			if ( folderBackBtn && folderLabel ) {
				folderBackBtn.x = avw;
				folderLabel.x = avw + int(( pw - (folderLabel.textField.textWidth+cssLeft*2+sbw) ) * .5);
				if( folderLabel.x < folderBackBtn.x + folderBackBtn.cssSizeX + 4 ) {
					folderLabel.x = int(folderBackBtn.x + folderBackBtn.cssSizeX + 4);
				}
			}
			
			if ( tabs && tabs.items && tabs.items.length > 0) {
				tabs.x = cssLeft + avw;
				for(i=0; i < tabs.items.length; i++ ) {
					tabs.items[i].setWidth( 0 );
					tabs.items[i].init();
				}
				tabs.setWidth(0);
				tabs.format(false);
				tabs.init();
					
				if( tabs.getWidth() > w ) {
					var ow:int = Math.floor( (w-(tabs.cssBoxX + cssBoxX)) / tabs.items.length );
					for(i=0; i < tabs.items.length; i++ ) {
						tabs.items[i].setWidth( ow-tabs.items[i].cssBoxX );
					}
					tabs.format(false);
					tabs.init();
				}
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
				if ( folderBackBtn && folderLabel ) {
					folderBackBtn.y = scrollpane.y - folderBackBtn.cssSizeY;
					folderLabel.y = scrollpane.y - folderLabel.cssSizeY;
				}
				if( multiSelectMenu ) 
				{
					// not in displayForm possible..
					scrollpane.setHeight( th - (scrollpane.y + scrollpane.cssBoxBottom) );
					scrollpane.contentHeightChange();
				}
				else
				{
					var s:Number = 0;
					if( nameCtrl && nameCtrl.visible ) {
						nameCtrl.y = cssTop;
						s = cssTop + nameCtrl.cssSizeY + nameCtrl.cssMarginBottom;
						
						if( tabs ) {
							tabs.y = cssTop + nameCtrl.getHeight() + tabs.cssMarginTop;
							s += tabs.cssSizeY + tabs.cssMarginY;
						}
					}else{
						s = cssTop;
					}
					scrollpane.setHeight( th - (ch + cssBoxY + s) );
					scrollpane.contentHeightChange();
					scrollpane.y = s;
				}
			}
		}
		
		private function inputHeightChange (e:Event):void {
			if( itemList ) itemList.format();
			if ( scrollpane ) scrollpane.contentHeightChange();
			setWidth( getWidth() );
		}
		
		private function vectorClear (e:InputEvent):void {
			if( itemList ) {
				var ch:Array= itemList.items;
				var L:int = ch.length;
				var pc:PropertyCtrl = PropertyCtrl( e.currentTarget.parent );
				if( pc && pc.textBox && pc.textBox._supertype == "vector" ) {
					var nam:String = pc.name;
					var it:PropertyCtrl;
					for( var i:int=0; i<L; i++) {
						it = PropertyCtrl( ch[i] );
						if( it.textBox._supertype == "vectorlink" && it.textBox.args && it.textBox.args[0] == nam) {
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
				if( pc && pc.textBox && pc.textBox._supertype == "vector" ) {
					var nam:String = pc.name;
					var it:PropertyCtrl;
					for( var i:int=0; i<L; i++) {
						it = PropertyCtrl( ch[i] );
						if( it.textBox._supertype == "vectorlink" && it.textBox.args && it.textBox.args[0] == nam) {
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
				
				if( pc && pc.textBox && pc.textBox._supertype == "vector" ) {
					var nam:String = pc.name;
					var it:PropertyCtrl;
					var sL:int = pc.textBox.vectorTextFields.length;
					var k:int;
					var kL:int;
					
					for( var i:int=0; i<L; i++)  {
						it = PropertyCtrl( ch[i] );
						if( it.textBox._supertype == "vectorlink" && it.textBox.args && it.textBox.args[0] == nam){
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
		
		public override function showAreaItems () :void
		{
			updateItem = null;
			
			Console.log( "Aed.ShowAreaItems");
			
			// Area changed...
			if( multiSelectMenu != null ) {
				removeMultiSelMenu();
			}
			
			if( folderLabel && scrollpane && contains( folderLabel ) ) removeChild( folderLabel );
			if( folderBackBtn && contains(folderBackBtn) ) removeChild( folderBackBtn );
			if( tabs && contains(tabs) ) removeChild( tabs );
			if( tabsPP && contains(tabsPP) ) removeChild( tabsPP );
			
			folderLabel = null;
			folderBackBtn = null;
			
			if( nameCtrl && contains(nameCtrl)) removeChild( nameCtrl );
			nameCtrl = null;
			
			if( areaView && areaView.scrollpane2 ) areaView.scrollpane2.visible = true;
			
			if(scrollpane) {
				if( itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
				if( contains( scrollpane) ) removeChild( scrollpane );
			}
			
			if(!currentArea) return; // nothing to show
			
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
					areaView.clearItems();
					
					if( currentArea.type == "all" || !currentArea.types || currentArea.types.length == 0 )
					{
						// Show all subtemplates
						for(i=0; i<L; i++) 
						{
							T = CTTools.subTemplates[i];
							if( T.hidden ) continue;
							
							nam = T.name;
							ico = CTTools.parseFilePath( T.listicon );
							areaView.addItem( nam, ico );
							
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
									areaView.addItem( nam, ico);
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
												areaView.addItem( nam, ico );
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
							
							/*if ( T.articlepage != "" )
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
							}else{*/
								if( T.articlepage == "" && T.numAreas > 0 ) {
									area_ico = new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "anmeldung-abgerundet.png", Options.iconSize, Options.iconSize);
									area_ico.addEventListener( MouseEvent.MOUSE_DOWN, gotoAreaHandler );
									icos.push( area_ico );
								}
							//}
							
							pg = new Button(icos, 0, 0, itemList, styleSheet, '', 'page-item-btn', false);
							
							if( pg.contRight ) {
								pg.contRight.mouseEnabled = true;
								pg.contRight.mouseChildren = true;
							}
							created = true;
						}
					}
					
					if(!created) {
						pg = new Button([ "" + Language.getKeyword(r.subtemplate) + ": " + r.name, new IconMenu(ico_col, Options.iconSize, Options.iconSize) ], 0, 0, itemList, styleSheet, '', 'page-item-btn', false);
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
					setTimeout( function () {
					setCurrArea( areaView.itemList1 );
					}, 0);
				}
			}
		}
		protected override function areaItemDown (e:MouseEvent) :void
		{
			_subform = false;
			_inlineArea = "";
			super.areaItemDown(e);
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
				
				if( CTOptions.rememberArea ) {
					var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
					if( sh && sh.data) {
						sh.data.lastArea = lb;
						sh.flush();
						sh.close();
					}
				}
				showAreaItems();
				
				if( CTOptions.previewInEditor && CTTools.procFiles ) {
					setCurrPF();
				}
			}
		}
		
		public function gotoArea (area:Area) :void
		{
			currentArea = area;
			CTTools.currArea = area.name;
			
			if( CTOptions.rememberArea ) {
				var sh:SharedObject = SharedObject.getLocal( CTOptions.localSharedObjectId );
				if( sh && sh.data) {
					sh.data.lastArea = area.name;
					sh.flush();
					sh.close();
				}
			}
			
			showAreaItems();
				
			if( CTOptions.previewInEditor && CTTools.procFiles ) {
				setCurrPF();
			}
		}
		
		private var currTab:String=""; // Subtemplate Tab
		private var currCat:String=""; // category for property folding
		private var prevCat:Array=null;
		private var rtScroll:Number = 0;
		
		private static var anim:Animation = new Animation();
		private static var anim2:Animation = new Animation();
		private static var currentCat:Array;
		private static var currCatId:int = 0;
		
		private function backButtonHandler (e:Event):void
		{
			if( currentTemplate )
			{
				if( prevCat )
				{
					var cc:Object = prevCat.pop();
					currCat = cc.name;
					if(prevCat.length == 0) prevCat = null;
					var scr:Number = scrollpane.slider.value;
					
					displayInsertForm( currentTemplate, updateItem != null, _subform, _inlineArea, areaItems, currCat, scr, 0 );
					
					if( cc.scroll > 0 && scrollpane ) {
						scrollpane.applyScrollValue(cc.scroll);
					}
				}
				else
				{
					displayInsertForm( currentTemplate, updateItem != null, _subform, _inlineArea, areaItems, "", 0, 0 );
					
					if( rtScroll > 0 && scrollpane ) {
						scrollpane.applyScrollValue(rtScroll);
					}
				}
				setWidth( cssSizeX-cssBoxX );
			}
		}
		
		public override function displayInsertForm ( tmpl:Template, isUpdateForm:Boolean = false, subform:Boolean = false, inlineArea:String = "", _areaItems:Array = null, 
													 cat:String="", ltscroll:Number=0, gotoDirection:int=2, forceLevel:Boolean = false ) :void 
		{
			if(!tmpl || !tmpl.indexFile) return;
			
			if( multiSelectMenu != null ) removeMultiSelMenu();
			
			if( ! subform ) {
				// root form
				_formNodes = [];
			}
			
			currentTemplate = tmpl;
			_isUpdateForm = isUpdateForm;
			_subform = subform;
			_inlineArea = inlineArea;
			
			// hide new-item functionality
			if( areaView && areaView.scrollpane2 ) areaView.scrollpane2.visible = false;
			
			var files:Array = CTTools.procFiles;
			var L:int = files.length;
			
			
			if ( L > 0 )
			{
				var pfid:int;
				var pth:String;
				var pf:ProjectFile;
				var i:int;
				var j:int;
				var jL:int;
				var ict:CssSprite;
				var btn:Button;
				
				if( (!forceLevel || (subform && !isUpdateForm)) && nameCtrl && contains( nameCtrl ) ) {
					removeChild(nameCtrl);
				}
				
				if( tabs && contains(tabs)) removeChild( tabs );
				if( tabsPP && contains(tabsPP)) removeChild( tabsPP );
				
				if( folderLabel && scrollpane && contains( folderLabel )) removeChild( folderLabel );
				if( folderBackBtn  && contains(folderBackBtn)) removeChild( folderBackBtn );
				folderLabel = null;
				folderBackBtn = null;
				
				if( scrollpane && itemList && scrollpane.content.contains( itemList )) scrollpane.content.removeChild( itemList );
				if( scrollpane && contains( scrollpane) ) removeChild( scrollpane );
				
				var w:Number = getWidth();
				scrollpane = new ScrollContainer(w, 0, this, styleSheet, '', '',false);
				scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
				
				itemList = new ItemList(w,0,scrollpane.content,styleSheet,'','area-insert-container',true);
				var currSprite:CssSprite;
				itemList.margin = 10;
				
				var propName:String;
				var propType:String;
				var propVal:String;
				var namlc:String;
				
				if ( nameCtrl ) {
					ict = nameCtrl;
					if ( !contains(nameCtrl) ) addChild( nameCtrl );
				}else{
					ict = new NameCtrl( "Name", "name", "name", "", null, null, w, 0, this, styleSheet, '', 'area-insert-prop', false);
				}
				
				var nm:NameCtrl = NameCtrl( ict );
				var ppi:PopupItem;
				
				addChild( anim );
				addChild( anim2 );
				
				scrollpane.content.alpha = 0;
				
				setTimeout( function () {
					
					if( gotoDirection == 1 )
					{
						scrollpane.content.x = CssSprite(parent).cssSizeX;
						anim.run( scrollpane.content, { x:0 }, 345, Strong.easeOut );
						anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
					}
					else if( gotoDirection == 2 )
					{
						anim.run( scrollpane.content, { alpha: 1 }, 600, Strong.easeOut );
					}
					else if( gotoDirection == 3 )
					{
						// up
						scrollpane.content.y = -CssSprite(parent).cssSizeX;
						anim.run( scrollpane.content, { y:0 }, 345, Strong.easeOut );
						anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
					}
					else if( gotoDirection == 4 )
					{
						// down
						scrollpane.content.y = CssSprite(parent).cssSizeX;
						anim.run( scrollpane.content, { y:0 }, 345, Strong.easeOut );
						anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
					}
					else if( gotoDirection == 5 )
					{
						// pop
						j = w - 20;
						scrollpane.content.x = (j-int(j*0.75))/2;
						scrollpane.content.y = 25;
						scrollpane.content.scaleX = 0.75;
						scrollpane.content.scaleY = 0.75;
						
						anim.run( scrollpane.content, { x:0, y:0, scaleX:1, scaleY:1 }, 300, Strong.easeOut );
						anim2.run( scrollpane.content, { alpha: 1 }, 700, Strong.easeOut );
					}
					else
					{
						// go back
						scrollpane.content.x = -CssSprite(parent).cssSizeX;
						anim.run( scrollpane.content, { x: 0 }, 345, Strong.easeOut );
						anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
					}
					
				}, 0);
				
				var lbl:Label;
				var backbtn:Button;
				
				if( cat != "" )
				{
					if(currCat != "" && currCat != cat) {
						if(!prevCat) prevCat = [ { name:currCat, scroll:ltscroll }];
						else prevCat.push( {name:currCat, scroll:ltscroll} );
					}
					currCat = cat;
					
					lbl = new Label( w, 0, this, styleSheet, '', 'property-folder-title' , true);
					
					folderLabel = lbl;
					
					lbl.label = Language.getKeyword( cat );
					
					lbl.textField.autoSize = TextFieldAutoSize.LEFT;
					lbl.textField.wordWrap = false;
					lbl.init();
					lbl.y = int(cssTop + lbl.cssMarginTop);
					
					backbtn = new Button( [new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "navi-left-btn.png", Options.iconSize, Options.iconSize), 
					Language.getKeyword(prevCat && prevCat.length > 0 ? prevCat[prevCat.length-1].name : "")], 0, 0, this, styleSheet, '', 'back-button', false );
					
					backbtn.addEventListener( MouseEvent.CLICK, backButtonHandler);
					backbtn.margin = 0;
					backbtn.clipSpacing = 0;
					backbtn.init();
					
					backbtn.y = int(cssTop + backbtn.cssMarginTop);
					backbtn.x = int(cssLeft + backbtn.cssMarginLeft);
					
					folderBackBtn = backbtn;
					
					currCatId = currentCat.push ( [] ) - 1;
				}
				else
				{
					prevCat = null;
					currCat = "";
					currentCat = [[]];
					currCatId = 0;
				}
				
				if( !isUpdateForm ) {
					nm.showSaveAndCloseButton(false);
					nm.showSaveButton(true);
					nm.showDeleteButton(false);
					nm.showNextButton(false);
					nm.showPrevButton(false);
					
					if( subform ) {
						ict.removeEventListener( "save", updatePageItem);
						ict.removeEventListener( "close", cancelPageItem);
					}
					
					ict.addEventListener( "saveInline", insertPageItem);
					ict.addEventListener( "close", cancelPageItem);
					ict.setWidth( w );
					
					if( !nameCtrl ) nameCtrl = NameCtrl(ict);
					nameCtrl.label.label = Language.getKeyword("Create New Area Item") + " " + Language.getKeyword( tmpl.name ) + ":";
											
					setHeight( _h );
					setWidth( w );
					
					return;
				}else{
					if ( areaItems ) {
						if ( areaItems.length <= 1 ) {
							nm.showNextButton(false);
							nm.showPrevButton(false);
						}else if( updateItem  ) {
							if( areaItems[0] && areaItems[0].name == updateItem.name ) {
								nm.showPrevButton( false );
							}else{
								nm.showPrevButton( true );
							}
							
							if( areaItems[areaItems.length-1].name == updateItem.name ) {
								nm.showNextButton(false);
							}else{
								nm.showNextButton(true);
							}
						}
					}
				}
				
				if( !forceLevel || _formNodes.length == 0 )
				{
					_formNodes.push( new ItemForm( _subform ? inlineArea : currentArea.name, updateItem, _areaItems, currCat) );
				}
				nameCtrl = NameCtrl(ict);
				
				if( !forceLevel ) {
					ict.addEventListener( PropertyCtrl.ENTER, ictChange );
					
					ict.addEventListener( "save", updatePageItem);
					ict.addEventListener( "saveInline", inlineSaveClick );
					ict.addEventListener( "delete", deletePageItem );
					ict.addEventListener( "close", cancelPageItem );
					ict.addEventListener( "next", nextPageItem );
					ict.addEventListener( "prev", prevPageItem );
					
					ict.setWidth( w );
					
					if( !isUpdateForm ) {
						nm.visibleStatus = true;
					}else{
						if( updateItem && updateItem.visible != undefined ) {
							nm.visibleStatus = updateItem.visible == true || updateItem.visible == "true" ? true : false;
						}else{
							nm.visibleStatus = true;
						}
						
							
						if( currentTemplate.articlepage != "" )					 
						{
							// create article page with db fields
							var props:Object = { inputname: updateItem.name };
							props["itemtemplate"] = currentTemplate.name;
							props["name"] = updateItem.name;
							
							var filename:String = CTTools.webFileName( currentTemplate.articlename, props );
							var pf1:ProjectFile = CTTools.findArticleProjectFile( filename, "filename" );
							
							if( pf1 ) {
								currPF = pf1;
							}
						}
					}
				}
				
				var propStore:Object = {};
				tmplSplitPaths = "";
				
				tabs = new ItemBar( w, 0, this, styleSheet, '', 'tabs', false );
				var hasTabs:Boolean  =  false;
				var itVisible:Boolean = false;
				
				for(i = 0; i<L; i++)
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
								
								if(propName == "field" || propStore[propName]) continue; // ignore multiple properties with the same name
								propStore[propName] = true;
								
								propVal = "";
								propType = pf.templateProperties[j].defType.toLowerCase();
								
								if( propType == "tab" )
								{
									hasTabs = true;
									btn = new Button( [ Language.getKeyword(propName)],0,0, tabs, styleSheet, '', 'areaeditor-tab', false);
									btn.options.folder = propName;
									btn.options.isTab = true;
									btn.autoSwapState = "";
									
									btn.addEventListener( MouseEvent.CLICK, folderClick );
									
									tabs.addItem(btn, true);
									
									if ( cat == "" ) {
										// Display first Tab
										cat = propName;
										btn.swapState( "active" );
									}else{
										
										if ( cat == propName ) {
											btn.swapState( "active" );
										}
									}
								}
								else
								{
									if ( cat != "" )
									{
										if( pf.templateProperties[j].sections && pf.templateProperties[j].sections.join(".") == cat ) {
											// display section.. 
											itVisible = true;
										}else{
											itVisible = false;
										}
									}
									else
									{
										itVisible = true;
										if( pf.templateProperties[j].sections && pf.templateProperties[j].sections.length > 0) {
											if( pf.templateProperties[j].sections[0] != "" && pf.templateProperties[j].sections[0].toLowerCase() != "root") {
												itVisible = false;
											}
										}
									}
									
									if( propType == "folder" )
									{
										btn = new Button( [ Language.getKeyword(propName), new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "navi-right.png", Options.iconSize, Options.iconSize)], w,0, itemList, styleSheet, '', 'areaeditor-folder', false);
										btn.options.folder = propName;
										btn.addEventListener( MouseEvent.CLICK, folderClick );
										itemList.addItem(btn, true);
										
										btn.visible = itVisible;
									}
									else
									{
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
										
										if (isUpdateForm && updateItem && updateItem[ propName ]) {
											propVal = updateItem[propName];
										}
										
										ict = new PropertyCtrl( Language.getKeyword(propName.toLowerCase()), propName, propType, propVal, pf.templateProperties[j], pf.templateProperties[j].args, w, 0, itemList, styleSheet,'', 'area-insert-prop', false);
										ict.options.propObject = pf.templateProperties[j];
										if( isUpdateForm && updateItem ) {
											PropertyCtrl(ict).textBox.pageItemName = updateItem.name;
										}
										
										ict.addEventListener( PropertyCtrl.ENTER, ictChange );
										PropertyCtrl(ict).textBox.addEventListener("heightChange", inputHeightChange);
										
										if( propType == "vector" || propType == "vectorlink" ) {
											PropertyCtrl(ict).textBox.addEventListener("lengthChange", vectorLengthChange);								
											PropertyCtrl(ict).textBox.addEventListener("add", vectorAdd);
											PropertyCtrl(ict).textBox.addEventListener("clear", vectorClear);
										}
										ict.visible = itVisible;
										
										if( propType == "intern" || propType == "hidden") { 
											ict.setHeight(0);
											ict.alpha = 0;
										}
										
										itemList.addItem(ict, true);
									}
								}
							}
						}
					}
				}
				
				if ( hasTabs )
				{
					// Use Tabs OR Folders
					if( folderLabel && scrollpane && contains( folderLabel ) ) removeChild( folderLabel );
					if( folderBackBtn  && contains(folderBackBtn) ) removeChild( folderBackBtn );
					folderLabel = null;
					folderBackBtn = null;
					tabs.format( false );
					tabs.init();
				}
				
				itemList.format();
				setHeight( _h );
				setWidth( w );
				
				setTimeout( function () { setWidth( getWidth() ); }, 230 );
				
				try {
					Application.instance.view.panel.src["newSize"](null);
				}catch(e:Error) {
					
				}
				if( !forceLevel ) {
					storeCurrentItemValues();
				
					setTimeout(function(){
						try {
							Application.instance.view.panel.src["displayFiles"]();
						}catch(e:Error) {
							
						}
					},550);
				}
			}
		}
		
		private function folderClick (e:Event):void
		{
			if( clickScrolling )
			{
				clickScrolling = false;
			}
			else
			{
				if( currentTemplate )
				{
					var scr:Number = scrollpane.slider.value;
					if ( !prevCat ) rtScroll = scr;			
					displayInsertForm ( currentTemplate, updateItem != null, _subform, _inlineArea, areaItems, e.currentTarget.options.folder, scr, e.currentTarget.options.isTab ? 3 : 1, true );
					setWidth( cssSizeX-cssBoxX );
				}
			}
		}
		
		private function storeCurrentItemValues () :void
		{
			if( nameCtrl && itemList && itemList.items && itemList.items.length > 0 )
			{
				var L:int = itemList.numChildren;
				var pc:PropertyCtrl;
				var initValues:Object = null;
				
				if( _formNodes && _formNodes.length > 0 ) initValues = _formNodes[_formNodes.length-1].initValues;
				
				if( initValues )
				{
					for(var i:int=0; i<L; i++)
					{
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
		}
		
		private function inlineSaveClick (e:Event) :void {
			if( updateItem ) {
				saveInline = true;
				updatePageItem(null);
			}
		}
		
		protected override function showMultiSelectMenu () :void
		{
			super.showMultiSelectMenu();
			
			var px:Number = 0;
			var pw:Number = 0;
			
			if( areaView && areaView.visible ) {
				px = areaView.x + areaView.cssSizeX;
				if( HtmlEditor.isPreviewOpen && !CTOptions.previewAtBottom ) pw = HtmlEditor.previewX - (px);
				else pw = getWidth() - (px);
				multiSelectMenu.y = -cssTop;
			}else{
				if( areapp && areapp.visible ) px = areapp.x + areapp.cssSizeX;
				else pw = getWidth() - (px);
				multiSelectMenu.y = areapp.y;
			}
			
			multiSelectMenu.x = px;
			multiSelectMenu.setWidth( pw  );
		}
		
		// Drag and create new Items from the Area New Field into an area list:
		public function newItem ( id:int, tname:String ) :void {
			var T:Template = CTTools.findTemplate( tname, "name" );
			if(T) {
				displayInsertForm(T);
			}else{
				Console.log("No Template Found For: " + tname);
			}
		}
		
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
			
			showAreaItems();
			if( CTOptions.previewInEditor && CTTools.procFiles )
			{
				setCurrPF();
			}
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
								
								setTimeout(function(){
									try {
										Application.instance.view.panel.src["displayFiles"]();
									}catch(e:Error) {
										
									}
								},0);
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
									if( CTTools.procFiles[i].hasInlineAreas && typeof(CTTools.procFiles[i].inlineAreas[name]) != "undefined" ) {
										currPF = CTTools.procFiles[i];
										currItemName = _currItem;
												
										setTimeout(function(){
											try {
												Application.instance.view.panel.src["displayFiles"]();
											}catch(e:Error) {
												
											}
										},0);
									}else{
										L2 = CTTools.procFiles[i].templateAreas.length;
										for(j = 0; j < L2; j++) 
										{
											if( CTTools.procFiles[i].templateAreas[j].name == _currArea ) 
											{
												currPF = CTTools.procFiles[i];
												currItemName = _currItem;
												
												setTimeout(function(){
													try {
														Application.instance.view.panel.src["displayFiles"]();
													}catch(e:Error) {
														
													}
												},0);
												break;
											}
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
												
												setTimeout(function(){
													try {
														Application.instance.view.panel.src["displayFiles"]();
													}catch(e:Error) {
														
													}
												},0);
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
		}
		
		private function plusClick (e:PopupEvent) :void{
			var curr:PopupItem = e.selectedItem;
			var rawName:String = curr.options.templateID;
			var T:Template = CTTools.findTemplate( rawName, "name" );
			if(T) {
				displayInsertForm(T);
			}else{
				Console.log("No Template Found For: " + rawName);
			}
		}
		
		private function onAskInsert () :void {
			displayInsertForm( currentTemplate, false );
		}
		
		private function cancelPageItem (e:Event) :void {
			// reset ram-db values
			if( this.updateItem ) {
				var initValues:Object = null;
				
				if( _formNodes ) initValues = _formNodes[_formNodes.length-1].initValues;
				
				var updateItem:Object;
				
				if( _subform && _formNodes) {
					updateItem = _formNodes[_formNodes.length-1].updateItem;
				}else{
					updateItem = this.updateItem;
				}
				
				if( _isUpdateForm && initValues )
				{
					if( CTTools.pageItemTable[ updateItem.name ] != undefined ) {
						for ( var nam:String in initValues )
						{
							if( CTTools.pageItemTable[ updateItem.name ] && updateItem.name && initValues[nam].name && initValues[nam].value  )
							{
								CTTools.pageItemTable[ updateItem.name ][ initValues[nam].name ] = initValues[nam].value;
							}
						}
					}
				}
				if( _formNodes )
				{
					_formNodes.pop();
								
					if( _formNodes.length > 0 )
					{
						var itf:ItemForm = ItemForm( _formNodes[_formNodes.length-1] );
						var T2:Template = CTTools.findTemplate( itf.updateItem.subtemplate, "name" );
						
						if( T2 ) {
							_formNodes.pop();
							this.updateItem = itf.updateItem;
							if( _formNodes.length == 0 ) {
								displayInsertForm( T2, true, false, "", null, itf.cat );
							}else{
								displayInsertForm( T2, true, true, itf.area, itf.areaItems, itf.cat);
							}
							return;
						}
					}
				}
			}
			showAreaItems();
		}
		
		private function deleteItemOK (bool:Boolean) :void {
			if( bool ) {
				// Delete updateItem
				var updateItem:Object;
				if( _subform ) {
					updateItem = _formNodes[_formNodes.length-1].updateItem;
				}else{
					updateItem = this.updateItem;
				}
				if( updateItem ) {
					if( updateItem.uid ) {
						// Delete Page Item
						var pms:Object = {};
						pms[":uid"] = updateItem.uid;
						var rv:Boolean = CTTools.db.deleteQuery( onDeletePageItem, "pageitem", "uid=:uid", pms);
						if( ! rv ) Console.log("ERROR Deleting Page Item From DB");
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
				var updateItem:Object;
				if( _subform ) {
					updateItem = _formNodes[_formNodes.length-1].updateItem;
				}else{
					updateItem = this.updateItem;
				}
				if( updateItem && updateItem.ext_uid ) {
					var pms:Object = {};
					pms[":uid"] = updateItem.ext_uid;
					var rv:Boolean = CTTools.db.deleteQuery( onDeletePageItemExtensionTable, currentTemplate.tables, "uid=:uid", pms);
					if( ! rv ) {
						Console.log("ERROR Deleting Page Item Extension Table From DB");
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
				var updateItem:Object;
				if( _subform ) {
					updateItem = _formNodes[_formNodes.length-1].updateItem;
				}else{
					updateItem = this.updateItem;
				}
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
			if( currentTemplate && currentTemplate.numAreas > 0 )
			{
				invalidateAreaTree();
				createAed();
				return;
			}
			
			try {
				Application.instance.view.panel.src["reloadClick"]();
			}catch(e:Error) {
				
			}
			
			Application.instance.hideLoading();
			
			if( _formNodes )
			{
				_formNodes.pop();
							
				if( _formNodes.length > 0 )
				{
					var itf:ItemForm = ItemForm( _formNodes[_formNodes.length-1] );
					var T2:Template = CTTools.findTemplate( itf.updateItem.subtemplate, "name" );
					
					if( T2 ) {
						_formNodes.pop();
						this.updateItem = itf.updateItem;
						if( _formNodes.length == 0 ) {
							displayInsertForm( T2, true, false, "", null, itf ? itf.cat:"");
						}else{
							displayInsertForm( T2, true, true, itf.area, itf.areaItems, itf.cat);
						}
						return;
					}
				}
			}
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
		
		private function updatePageItem ( e:Event ) :void
		{
			var updateItem:Object;
			
			if( _subform ) {
				updateItem = _formNodes[_formNodes.length-1].updateItem;
			}else{
				updateItem = this.updateItem;
			}
			
			if( updateItem )
			{
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
			if( res )
			{
				var updateItem:Object;
				
				if( _subform ) {
					updateItem = _formNodes[_formNodes.length-1].updateItem;
				}else{
					updateItem = this.updateItem;
				}
				
				var pms:Object={};
				
				// update ex_tables
				if( updateItem && updateItem.ext_uid != undefined && currentTemplate.tables && currentTemplate.fields )
				{
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
								if( pc.textBox._supertype == "file" || pc.textBox._supertype == "image" || pc.textBox._supertype == "video" || pc.textBox._supertype == "audio" || pc.textBox._supertype == "pdf")
								{
									storeFile( pc.textBox );
									if( updateItem ) {
										updateItem[ fields[i] ] = pc.textBox.value;
									}
								}
								else if( pc.textBox._supertype == "vector" && (pc.textBox.vectorType == "file" || pc.textBox.vectorType == "image" || pc.textBox.vectorType == "video" || pc.textBox.vectorType == "audio"  || pc.textBox.vectorType == "pdf" ))
								{
									storeFileVector( pc.textBox );
								}
								
								if( pc.textBox._supertype == "text" || pc.textBox._supertype == "richtext"  || pc.textBox._supertype == "line"  )
								{
									
									pms[ ":_"+ fields[i] ] = HtmlParser.toDBText( pc.textBox.value, true, true );
									// Write to intern data
									CTTools.pageItemTable[ updateItem.name ][ fields[i] ] = pms[":_"+fields[i]];
									
								}else if( pc.textBox._supertype == "area" ) {
									
									//CTTools.invalidateArea( pc.textBox.areaName );
									pc.textBox.value = CTTools.getAreaText (pc.textBox.areaName, pc.textBox.areaOffset, pc.textBox.areaLimit/*, pc.textBox.areaSubTemplateFilter*/ )
									//
									pms[ ":_"+ fields[i] ] = pc ? pc.textBox.value : ""
									CTTools.pageItemTable[ updateItem.name ][ fields[i] ] = pms[":_"+fields[i]];
									
								}
								else
								{
									pms[ ":_"+ fields[i] ] = pc ? pc.textBox.value : "";
								}
							}else{
								pms[ ":_"+ fields[i] ] = pc ? pc.textBox.value : "";
							}
							
							fieldVal += ','+fields[i]+'=:_' + fields[i];
						}
					}
					
					if( currentTemplate.articlepage != "" )					 
					{
						// create article page with db fields
						props = { name: pms[":_name"], inputname: pms[":_name"] };
						_args = {};
						_tmpl = {};
						
						for( i = 0; i < L; i++)
						{
							pc = PropertyCtrl( itemList.getChildByName( fields[i] ) );
							
							if( pc )
							{
								//props[ fields[i] ] =  pms[ ":_" + fields[i] ];// pc ? pc.textBox.value : "";// pms[ ":_" + fields[i] ];// || "";
								/*if( pc.textBox._supertype == "text" || pc.textBox._supertype == "richtext"  || pc.textBox._supertype == "line"  )
								{
									props[ fields[i] ] = pc ? Template.transformRichText( pms[":_" + fields[i]], pc._args, currentTemplate) : "";
								}
								else
								{*/
									props[ fields[i] ] = pms[":_" + fields[i]];
								//}
								if( pc.textBox._supertype == "text" || pc.textBox._supertype == "richtext"  || pc.textBox._supertype == "line"  ) {
									_args[fields[i]] = pc._args;
									_tmpl[fields[i]] = currentTemplate;
								}
							}
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
						
						if ( !PageEditor.createPage( fi.name, true, "", "article", currentTemplate.name + ":" + currentTemplate.articlepage, props["inputname"], fi.path, "now", onArticlePage, props, _args, _tmpl) )
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
		
		private static var subRequestForm:ItemForm;
		
		private function onUpdateExtensionItem (res:DBResult) :void {
			Application.instance.hideLoading();
			
			var updateItem:Object;
			if( _subform ) {
				updateItem = _formNodes[_formNodes.length-1].updateItem;
			}else{
				updateItem = this.updateItem;
			}
			
			if(updateItem) {
				currItemName = updateItem.name;
			}else{
				currItemName = "";
			}
			
			invalidateCurrArea( true );
			
			var T2:Template;
			var itf:ItemForm;
			
			
			if( CTOptions.autoSave ) CTTools.save();
			
			if ( !saveInline )
			{
				if ( currentTemplate.articlepage != "" ) {
					if ( currentTemplate.articlepage != "" ) {
						if(articlePageWritten) {
							
							showAreaItems();
							return;
						}else{
							articleAreasInvalid = true;
						}
					}
				}else{
					if( currentTemplate && currentTemplate.numAreas > 0 ) {
						invalidateAreaTree();
						createAed();
					}
				}
				
				_formNodes.pop();
				
				if( _formNodes.length > 0 ) {
					itf = ItemForm( _formNodes[_formNodes.length-1] );
					T2 = CTTools.findTemplate( itf.updateItem.subtemplate, "name" );
					
					if( T2 ) {
						_formNodes.pop();
						this.updateItem = itf.updateItem;
						if( _formNodes.length == 0 ) {
							displayInsertForm( T2, true, false, "", null, itf ? itf.cat:"" );
						}else{
							displayInsertForm( T2, true, true, itf.area, itf.areaItems, itf.cat);
						}
					}
				}else{
					showAreaItems();
				}
			}
			else
			{
				storeCurrentItemValues();
				saveInline = false
				
				if( _formNodes && _formNodes.length > 1 )
				{
					// Re-open the sub form:
					// TODO store _formNodes up-chain and re-open all parent forms...
					// Currently, only the first depth of inline areas are working correctly
					
					var ltf:ItemForm = ItemForm( _formNodes.pop() );
					
					if( subRequestForm == null ) subRequestForm = ltf;
					
					itf = ItemForm( _formNodes[_formNodes.length-1] );
					T2 = CTTools.findTemplate( itf.updateItem.subtemplate, "name" );
					
					if( T2 )
					{
						_formNodes.pop();
						this.updateItem = itf.updateItem;
						
						if( _formNodes.length == 0 )
						{
							displayInsertForm( T2, true, false, "", null, itf ? itf.cat:"" );
						}
						else
						{
							displayInsertForm( T2, true, true, itf.area, itf.areaItems, itf.cat);
						}
						
						inlineSaveClick(null);
						return;
					}
				
				}else{
					if( subRequestForm != null )
					{
						itf = subRequestForm;
						
						T2 = CTTools.findTemplate( itf.updateItem.subtemplate, "name" );
						
						if( T2 )
						{
							this.updateItem = itf.updateItem;
							displayInsertForm( T2, true, true, itf.area, itf.areaItems, itf.cat);
						}
						
						subRequestForm = null;
					}
				}
			}
			if( newInsertSortID >= 0 ) {
				newInsertSortID = -1;
				
				dragSaveClickHandler(null);
				pageItemDragging = false;
				
				//showUpdateForm();
			}else{
				Application.instance.hideLoading();
				
				// try reload preview:
				setTimeout( function () {
					try {
						Application.instance.view.panel.src["reloadClick"]();
					}catch(e:Error) {
						
					}
				}, 0);
				
			}
		}
		
		private function insertPageItem ( e:Event ) :void
		{
			// Try select page item with name first
			
			var pms:Object = {};
			pms[":nam"] = nameCtrl.textBox.value;
			var rv:Boolean = CTTools.db.selectQuery( onPageItemInsertSelect, "uid,name", "pageitem", "name=:nam", "", "", "", pms);
			if(!rv) {
				Console.log("SQL-ERROR Select Insert Page Item");
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
						_areaItems = areaItems.length;// itemList.numItems;
					}
					
					var pms:Object={};
					pms[":nam"] = nameCtrl.textBox.value;
					pms[":vis"] = nameCtrl.visibleStatus;
					pms[":tmpl"] = currentTemplate.name;
					
					if( _subform ) {
						pms[":ara"] = _inlineArea;
					}else{
						pms[":ara"] = currentArea.name;
					}
					pms[":sortid"] = _areaItems; // Last
					pms[":date"] = "now";
					
					newPageItemTmp = { name: pms[":nam"], area: pms[":ara"], sortid: pms[":sortid"], subtemplate: pms[":tmpl"], crdate: "" };
					var rv:Boolean = CTTools.db.insertQuery( onPageItemInsert, "pageitem", "name,visible,area,sortid,subtemplate,crdate", ":nam,:vis,:ara,:sortid,:tmpl,:date", pms);
					
					if(!rv) { 
						Console.log("SQL-ERROR Insert Page Item " + pms[":nam"]);
						Application.instance.hideLoading();
					}
				}
			}
		}
		
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
						else if( fields[i] != "name")
						{
							
							pc = PropertyCtrl( itemList.getChildByName( fields[i] ) );
							if(pc) {
								
								if( pc.textBox._supertype == "file" || pc.textBox._supertype == "image" || pc.textBox._supertype == "video" || pc.textBox._supertype == "audio" || pc.textBox._supertype == "pdf")
								{
									storeFile( pc.textBox );
								}
								else if( pc.textBox._supertype == "vector" && (pc.textBox.vectorType == "file" || pc.textBox.vectorType == "image" || pc.textBox.vectorType == "video" || pc.textBox.vectorType == "audio" || pc.textBox.vectorType == "pdf")  )
								{
									storeFileVector( pc.textBox );
								}
								
								if( pc.textBox._supertype == "text" || pc.textBox._supertype == "richtext"  || pc.textBox._supertype == "line"  )
								{
									pms[ ":_"+ fields[i] ] = HtmlParser.toDBText( pc.textBox.value, false, true );
									newPageItemTmp[ fields[i] ] = pms[":_"+fields[i]];
								}
								else
								{
									pms[ ":_"+ fields[i] ] = pc ? pc.textBox.value : "";
								}
							}else{
								pms[ ":_"+ fields[i] ] = pc ? pc.textBox.value : "";
							}
							fieldVal += ",:_" +  fields[i];
						}
						
						currItemName = newPageItemTmp.name;
						
						// Copy to internal db data...
						newPageItemTmp[ fields[i] ] = pms[ ":_"+ fields[i] ];
					}
					
					if( currentTemplate.articlepage != "" )					 
					{
						// create article page with db fields
						props = { name: pms[":_name"], inputname: pms[":_name"] };
						_args = {};
						_tmpl = {};
						//props['__tmpl'] = currentTemplate;
						
						for( i = 0; i < L; i++) {
							pc = PropertyCtrl( itemList.getChildByName( fields[i] ) );
							//props['__args'] = pc._args;
							
							props[ fields[i] ] =  pms[":_"+fields[i]];
							
							if( pc.textBox._supertype == "text" || pc.textBox._supertype == "richtext"  || pc.textBox._supertype == "line"  ) {
								_args[fields[i]] = pc._args;
								_tmpl[fields[i]] = currentTemplate;
							}
						}
						
						props["itemtemplate"] = currentTemplate.name;
						props["name"] = nameCtrl.textBox.value;
						
						var filename:String = "";
						var fi:FileInfo;
						
						if( currentTemplate.articlename != "" ) {
							filename = CTTools.webFileName( currentTemplate.articlename, props );
						}else{
							fi = FileUtils.fileInfo( currentTemplate.articlepage );
							filename = pms[":_name"] + "." + fi.extension;
						}
						
						fi = FileUtils.fileInfo( filename );
						articlePageWritten = false;
						articleAreasInvalid = false;
						
						if ( !PageEditor.createPage( fi.name, true, "", "article", currentTemplate.name + ":" + currentTemplate.articlepage, props["inputname"], fi.path, "now", onArticlePage, props, _args, _tmpl) ) {
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
					pf.settingDirty();
					CTTools.saveArticleFile( pf, PageEditor._ltPage.webdir );
				}
				
				currPF = pf;
				articlePageWritten = true;
				
				/*if ( articleAreasInvalid )
				{
					showAreaItems();
				}*/
			}
		}
		
		private function onInsertExTable  (res:DBResult) :void {
			if(res && res.rowsAffected ) {
				newPageItemTmp.ext_uid = res.lastInsertRowID;
				Application.instance.hideLoading();
				var T2:Template;
				var itf:ItemForm;
		
				invalidateCurrArea( true );
				
				if ( CTOptions.autoSave ) CTTools.save();
				
				if ( currentTemplate.articlepage != "" ) {
					if(articlePageWritten) {
						showUpdateForm();
						return;
					}else{
						articleAreasInvalid = true;
					}
				}
				showUpdateForm();
				Application.instance.hideLoading();
			}else{
				Console.log( "ERROR In Insert Page Item Extension");
				Application.instance.hideLoading();
				showUpdateForm();
			}
		}
		
		private function showUpdateForm () :void {
			if( nameCtrl && currentTemplate && newPageItemTmp ) {
				nameCtrl.removeEventListener("saveInline", insertPageItem );
				nameCtrl.showSaveAndCloseButton(true);
				nameCtrl.showSaveButton(true);
				nameCtrl.showDeleteButton(true);
				updateItem = newPageItemTmp;
				displayInsertForm( currentTemplate, true, _subform, _inlineArea, areaItems, currCat, 0, 5, false );
			}
		}
		
		protected function storeFileVector (pc_textBox:InputTextBox) :void {
			if( pc_textBox.vectorTextFields ) {
				var L:int = pc_textBox.vectorTextFields.length;
				for(var i:int =0 ; i<L; i++) {
					storeFile( pc_textBox.vectorTextFields[i], i );
				}
				pc_textBox.textEnter();
			}
		}
		
		// on store file from http://
		private function onHttpFile ( e:Event, res:Resource ) :void {
			if( res && res.loaded == 1 ) {
				var f1:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + res.udfData.newname;
				var f2:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + res.udfData.newname;
				
				ResourceMgr.getInstance().clearResourceCache( f1 );
				ResourceMgr.getInstance().clearResourceCache( f2 );
				
				var file1:File = File.applicationStorageDirectory.resolvePath ( f1 );
				var file2:File = File.applicationStorageDirectory.resolvePath ( f1 );
				
				var bytes:ByteArray = ByteArray( res.obj );
				
				var fs1:FileStream = new FileStream();
				fs1.open( file1, FileMode.WRITE );
				fs1.writeBytes( bytes );
				fs1.close();
				
				var fs2:FileStream = new FileStream();
				fs2.open( file2, FileMode.WRITE );
				fs2.writeBytes( bytes );
				fs2.close();
				
				if( res.udfData.textBox && res.udfData.textBox.stage ) {
					res.udfData.textBox.activateValue = "";
					res.udfData.textBox.value = res.udfData.newname;
				}
			}
		}
		
		protected function storeFile (pc_textBox:InputTextBox, vectorIndex:int=-1) :void
		{			
			if( pc_textBox.value == "" || pc_textBox.value.toLowerCase() == "none" ) {
				return;
			}
			
			// test if text-box value is already processed file.. (new file paths begin with file:/// http:// or https://) 
			var tf:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + pc_textBox.value );
			if( tf && tf.exists ) {
				return;
			}
			
			var pcpath:String = pc_textBox.value;
			var endslash:int = pcpath.lastIndexOf( CTOptions.urlSeparator );
			
			var filename:String;
			if( endslash >= 0 ) filename = pcpath.substring(endslash+1);
			else filename = pcpath;
			
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
			
			// test if file is from internet
			if( pcpath.substring(0,7) == "http://" || pcpath.substring(0,8) == "https://") {
				var res:Resource = new Resource();
				res.udfData.newname = newname;
				res.udfData.textBox = pc_textBox;
				// Rewrite textbox to new name
				pc_textBox.value = newname;
				
				res.load( pcpath, true, onHttpFile, null, true);
				return;
			}
			
			var f1:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + newname ;
			var f2:String = CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + newname;
			ResourceMgr.getInstance().clearResourceCache( f1 );
			ResourceMgr.getInstance().clearResourceCache( f2 );
			
			/*
			var file:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + newname);
			if( file.exists ) {
				if( CTOptions.debugOutput ) {
					Console.log( "WARNING: '" + file.url + "' Already Exists..");
				}
			}*/
			
			CTTools.copyFile( pc_textBox.value, f1 );
			CTTools.copyFile( pc_textBox.value, f2 );
			
			// Rewrite textbox to new name
			pc_textBox.value = newname;
			
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
					
					displayInsertForm( currentTemplate, updateItem != null, _subform, _inlineArea, areaItems, currCat );
					
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
