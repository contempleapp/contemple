package ct
{
	import flash.display.*;
	import flash.events.*;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import agf.Main;
	import agf.Options;
	import agf.icons.IconFromFile;
	import agf.tools.*;
	import agf.html.*;
	import agf.ui.*;
	import agf.db.*;
	import ct.ctrl.InputTextBox;
	import ct.ctrl.MultiSelectMenu;
	
	public class AreaProcessor extends CssSprite
	{
		public function AreaProcessor(w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
		}
		
		public var currentArea:Area;
		public var currentTypes:String = "";
		public var currentTemplate:Template;
		
		protected var scrollpane:ScrollContainer;
		protected var itemList:ItemList;
	
		public var updateItem:Object;
		
		protected var _subform:Boolean=false;
		protected var _inlineArea:String="";
		protected var _formNodes:Array;
		
		protected var dragOrdering:Boolean = false;
		protected var storeOrderByName:Object = null;
		
		protected var pageItemOldIndex:int;
		protected var pageItemNewIndex:int;
		protected var pageItemDragging:Boolean = false;
		protected var pageItemDragSX:int;
		protected var pageItemDragSY:int;
		protected var pageItemDragItem:Ctrl;
		protected var pageItemCurr:int = 0;
		protected var newPageItemTmp:Object={};
		
		protected var selection:Array;
		
		protected var areaClickItem:Ctrl;
		protected var areaClickTime:int;
		protected var areaClickY:int;
		protected var longClick:Boolean = false;
		
		protected var areaItems:Array;
		
		protected var multiSelectMenu:MultiSelectMenu = null;
		
		protected static var sbClickValue:Number;
		protected var inlineLongClick:Boolean = false;
		
		protected var dragDisplay:CssSprite;
		
		protected var delTables:Array;
		
		protected function invalidateCurrArea ( testST:Boolean=false ) :void
		{
			if( !currentArea ) return;
			
			CTTools.invalidateArea( currentArea.name );
			
			if( testST && CTTools.subTemplates )
			{
				var st:Template = null;
				var i:int;
				var L:int = CTTools.subTemplates.length;
				
				for(i = 0; i < L; i++ )
				{
					if( CTTools.subTemplates[i].areasByName[ currentArea.name ] != undefined ) 
					{
						st = CTTools.subTemplates[i];
						break;
					}
				}
				
				if( st != null )
				{
					// Search Area of Page Item CTTools.currArea:
					if( CTTools.pageItems )
					{
						L = CTTools.pageItems.length;
						for(i = 0; i < L; i++)
						{
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
		
		protected function updateNextPageItemSorting ():void {
			if( pageItemCurr >= itemList.items.length ) {
				pageItemOldIndex = -1;
				pageItemNewIndex = -1;
				pageItemDragItem = null;
				
				invalidateCurrArea( true );
				
				if( CTOptions.autoSave ) CTTools.save();
				
				showAreaItems();
				
				Application.instance.hideLoading();
				
				setTimeout( function () {
					try {
						Application.instance.view.panel.src["reloadClick"]();
					}catch(e:Error) {
						
					}
				},0);
				
				return;
			}
			var pms:Object={};
			pms[":nam"] = itemList.items[pageItemCurr].options.result.name;
			pms[":sid"] = pageItemCurr;
			if( !CTTools.db.updateQuery( pageItemSortingUpdate, "pageitem", "name=:nam", "sortid=:sid", pms) ) {
				Console.log("ERROR Updating PageItem Sort Index");
				pageItemCurr++;
				updateNextPageItemSorting();
			}
		}
		protected function pageItemSortingUpdate (res:DBResult):void {
			pageItemCurr++;
			updateNextPageItemSorting();
		}
		
		protected function showDragSaveButtons () :void
		{
			storeOrderByName = {};
			var L:int = itemList.items.length;
			var options:Object;
			
			for(var i:int=0; i<L; i++)
			{
				options = itemList.items[i].options;
				
				if( options != null && options.result != null ) {
					storeOrderByName[ options.result.name] = options.result.sortid;
				}
			}
			dragOrdering = true;
			multiSelectMenu.enableUndo(true);
		}
		protected function dragCancelClickHandler (e:MouseEvent) :void {
			// restore list order
			if( itemList != null && storeOrderByName != null )
			{
				var L:int = itemList.items.length;
				var options:Object;
				
				for(var i:int=0; i<L; i++)
				{
					options = itemList.items[i].options;
					options.result.sortid = storeOrderByName[options.result.name];
				}
			}
			storeOrderByName = null;
			dragOrdering = false;
		}
		protected function dragSaveClickHandler (e:MouseEvent) :void{
			dragOrdering = false;
			storeOrderByName = null;
			Application.instance.showLoading( );
			// Update items in db...
			pageItemCurr = 0;
			updateNextPageItemSorting ();
		}
		
		protected function removeMultiSelMenu () :void {
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
		
		protected function areaItemDown (e:MouseEvent) :void
		{
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			
			areaClickItem = Ctrl( Sprite(e.currentTarget) );
			areaClickTime = getTimer();
			areaClickY = mouseY;  
			TemplateEditor.endClickScrolling();
			
			if( !longClick ) 
			{
				stage.addEventListener( Event.ENTER_FRAME, areaItemMove );
				stage.addEventListener( MouseEvent.MOUSE_UP, areaItemUp );
			}
			else // longClickMode is activated..
			{
				var bt:Button = Button ( areaClickItem );
				
				stage.addEventListener( Event.ENTER_FRAME, selectItemMove );
				stage.addEventListener( MouseEvent.MOUSE_UP, selectItemUp );
				
				// multi sel mode..
				if( bt.contRight && bt.mouseX > bt.contRight.x ) {
					// drag button start
					if( selection && selection.length > 1 ) {
						startDragItems( );
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
						selection.push( bt.options.result.name );
						
						if( bt.state != "active" ) {
							bt.swapState("active");
						}
					}
				}
			}
		}
		protected function areaItemMove (e:Event) :void
		{
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			
			var dy:Number = mouseY - areaClickY;
			var sd:Slider;
			if( scrollpane ) sd = scrollpane.slider;
			
			if( TemplateEditor.clickScrolling )
			{
				if(sd) sd.value -= dy;
				if( scrollpane ) scrollpane.scrollbarChange(null);
				areaClickY = mouseY;
			}
			else
			{
				if( !longClick )
				{
					 if( getTimer() - areaClickTime > CTOptions.longClickTime ) {
						showMultiSelectMenu();
						var bt:Button = Button( areaClickItem );
						bt.swapState("active");
					}
					
					if( (sd && sd.visible) && Math.abs(dy) > CTOptions.mobileWheelMove ) {
						// start click scrolling..
						TemplateEditor.startClickScrolling();
						sbClickValue = scrollpane ? scrollpane.slider.value : 0;
					}
				}
			}
		}
		protected function areaItemUp (e:MouseEvent) :void 
		{
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			
			stage.removeEventListener( Event.ENTER_FRAME, areaItemMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, areaItemUp );
			
			if( !TemplateEditor.clickScrolling) {
				if( longClick ||  getTimer() - areaClickTime > CTOptions.longClickTime ) {
					if ( !pageItemDragging ) {
						showMultiSelectMenu();
						Button(areaClickItem).swapState( "active" );
						selection.push( Button(areaClickItem).options.result.name );
					}
				}else{
					// normal click..
					// todo hit test clickItem?
					
					Console.log( "Item Up: " + areaClickItem.options.result.subtemplate );
					
					var T:Template = CTTools.findTemplate( areaClickItem.options.result.subtemplate, "name" );
					if( T ) {
						updateItem = areaClickItem.options.result;
						displayInsertForm( T, true, _subform, _inlineArea, null, '', 0, ( _subform ? 5 : 2) );
					}else Console.log("ERROR: Can Not Find Template '" + areaClickItem.options.result.subtemplate + "' For Page Item: " +  areaClickItem.options.result.name);
				}
			}
		}
		
		protected function selectItemMove (e:Event) :void {
			if( ! pageItemDragging ) {
				var dy:Number = mouseY - areaClickY;
				
				if( TemplateEditor.clickScrolling ) {
					
					var sd:Slider;
					if( scrollpane ) sd = scrollpane.slider;
					if( sd && sd.visible ) {
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
						TemplateEditor.startClickScrolling();
						sbClickValue = scrollpane ? scrollpane.slider.value : 0;
					}
				}
			}
		}
		protected function selectItemUp (e:MouseEvent) :void {
			inlineLongClick = false;
			TemplateEditor.endClickScrolling();
			
			stage.removeEventListener( Event.ENTER_FRAME, selectItemMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, selectItemUp );
			if( selection && itemList ) {
				var L:int = selection.length;
				var ds:DisplayObject;
				for( var i:int=0; i<L; i++) {
					ds = itemList.getChildByName( selection[i] ) as DisplayObject;
					if( ds ) {
						Button( ds ).swapState( "active" );
					}
				}
			}			
		}
		private var multiDrag:Boolean = false;
		private var multiDragItems:Array;
		
		protected function startDragItems ( ) :void
		{
			multiDrag = true;
			
			var ds:Ctrl = Ctrl( itemList.getChildByName( selection[0] ) );
			
			if( ds )
			{
				pageItemDragItem = ds;
				pageItemDragSX = pageItemDragItem.mouseX;
				pageItemDragSY = pageItemDragItem.mouseY;
				pageItemDragging = true;
				var ib:ItemList = itemList;
				
				if( !dragDisplay ) {
					dragDisplay = new CssSprite( getWidth(), 0, scrollpane ? scrollpane.content : this, styleSheet, '', '','drag-display', false);
				}
				if( !dragOrdering ) showDragSaveButtons();
				
				pageItemNewIndex = -1;
				
				multiDragItems = [];
				var poi:int=0;
				var tmp:int;
				var i:int;
				
				// sort selection
				if( areaItems ) {
					var tmpsel:Array = [];
					for( i=0; i<areaItems.length; i++) {
						if( selection.indexOf( areaItems[i].name ) >= 0 ) {
							tmpsel.push( areaItems[i].name );
						}
					}
					selection = tmpsel;
				}
				
				for( i=0; i<selection.length; i++ ) {
					ds = Ctrl( itemList.getChildByName( selection[i] ) );
					if( ds ) {
						if( multiDragItems.length == 0 ) poi = itemList.removeItem( ds, true);
						else{
							tmp = itemList.removeItem( ds, true);
							if( tmp < poi ) poi = tmp;
						}
						multiDragItems.push( ds );
					}
				}
				pageItemOldIndex = poi;
				
				Main(Application.instance).topContent.addChild( pageItemDragItem );
				
				stage.addEventListener( Event.ENTER_FRAME, dragItemMove );
				stage.addEventListener( MouseEvent.MOUSE_UP, dragItemUp );
			}
		}
		
		protected function startDragItem ( item:Ctrl ) :void
		{
			multiDrag = false;
			pageItemDragItem = Ctrl(Sprite(item));
			pageItemDragSX = pageItemDragItem.mouseX;
			pageItemDragSY = pageItemDragItem.mouseY;
			pageItemDragging = true;
			var ib:ItemList = itemList;
			
			if( !dragDisplay ) {
				dragDisplay = new CssSprite( getWidth(), 0, scrollpane ? scrollpane.content : this, styleSheet, '', '','drag-display', false);
			}
			if( !dragOrdering ) showDragSaveButtons();
			
			pageItemNewIndex = -1;
			pageItemOldIndex = ib.removeItem(pageItemDragItem, true);
			
			Main(Application.instance).topContent.addChild( pageItemDragItem );
			
			stage.addEventListener( Event.ENTER_FRAME, dragItemMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, dragItemUp );
		}
		
		protected function dragItemMove (e:Event) :void {
			var ib:ItemList = itemList;
			if( pageItemDragging ) {
				if(scrollpane && scrollpane.slider.visible) {
					if(scrollpane.mouseY < 8) {
						scrollpane.slider.value -= 5;
						scrollpane.scrollbarChange(null);
					}else if(scrollpane.mouseY > scrollpane.height - 25) {
						scrollpane.slider.value += 5;
						scrollpane.scrollbarChange(null);
					}
				}
				if( !(this is InputTextBox) ) {
					pageItemDragItem.x = (AreaEditor.areaView && AreaEditor.areaView.visible  ? AreaEditor.areaView.cssSizeX : 0) + cssLeft;
				}else{
					pageItemDragItem.x = this.parent.parent.parent.parent.x;
				}
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
		protected function dragItemUp (e:MouseEvent) :void {
			var tc: Sprite;
			stage.removeEventListener( Event.ENTER_FRAME, dragItemMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, dragItemUp );
			if(scrollpane ) {
				if( dragDisplay && scrollpane.content.contains( dragDisplay ) ) scrollpane.content.removeChild( dragDisplay );
			}else{
				if( dragDisplay && contains( dragDisplay ) ) removeChild( dragDisplay );
			}
			dragDisplay = null;
			
			pageItemDragging = false;
			tc = Sprite( Main(Application.instance).topContent );
			if( tc.contains(pageItemDragItem) ) tc.removeChild(pageItemDragItem);
			var i:int;
			
			if( multiDrag ) {
				if( multiDragItems ) {
					for( i=0; i<multiDragItems.length; i++) {
						itemList.addItemAt( Ctrl(multiDragItems[i]), pageItemNewIndex + i );
					}
				}
			}else{
				itemList.addItemAt( pageItemDragItem, pageItemNewIndex );
			}
			
			if( pageItemOldIndex != pageItemNewIndex)
			{
				// set order id on all items from 0 - item-length
				for( i=0; i<itemList.items.length; i++ ) {
					Ctrl(itemList.getItemAt(i)).options.result.sortid = i;
				}
			}
			
			pageItemDragItem.x = 0;
			
			if( this is InputTextBox ) {
				setWidth( getWidth() + cssBoxX );
			}else{
				setWidth( getWidth() );
			}
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
				
				if( ! rv ) Console.log("ERROR Deleting Page Item From DB");
				else Application.instance.showLoading();
			}
		}
		
		protected function onMultiDeletePageItem (res:DBResult) :void {
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
					for (var id:String in tbStore)
					{	
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
		protected function onMultiDeleteNext (res:DBResult=null) :void
		{
			if( delTables && delTables.length > 0 ) {
				var next:Object = delTables.pop();
				var rv:Boolean = CTTools.db.deleteQuery( onMultiDeleteNext, next.tbl, next.where, next.pms);
						
				if( ! rv ) {
					Console.log("ERROR Deleting Page Item Extension Table From DB");
					Application.instance.hideLoading();
				}
			}else{
				// all deleted..
				onMultiDeletePageItemExtensionTable();
			}
		}
		protected function onMultiDeletePageItemExtensionTable (res:DBResult=null) :void {
			// Delete object from CTTools.pageItems and CTTools.pageItemTable
			var pg:Array = CTTools.pageItems;
			
			for( var i:int = pg.length-1; i>=0; i--)
			{
				if( selection.indexOf( pg[i].name ) >= 0 ) {
					CTTools.pageItemTable[ pg[i].name ] = null;
					CTTools.pageItems.splice( i, 1 );
				}
			}
			
			selection = [];
			
			invalidateCurrArea( true );
			
			if( CTOptions.autoSave ) CTTools.save();
			
			if( currentTemplate && currentTemplate.numAreas > 0 ) {
				createAed();
			}
			
			
			Application.instance.hideLoading();
			
			showAreaItems();
			
			setTimeout( function() {
				try {
					Application.instance.view.panel.src["reloadClick"]();
				}catch(e:Error) {
					
				}
			}, 0);
		}
		
		public function createAed () :void {}
		
		protected function showMultiSelectMenu () :void {
			
			if( multiSelectMenu == null )
			{
				longClick = true;
				selection = [];
				
				multiSelectMenu = new MultiSelectMenu(this,0,0,this,styleSheet,"","area-multi-select-menu",false);
				multiSelectMenu.setWidth( super.getWidth() - super.cssBoxX );
				
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
				if( scrollpane ) {
					scrollpane.y = multiSelectMenu.cssSizeY;
					scrollpane.setHeight( getHeight() - scrollpane.y );
					scrollpane.contentHeightChange();
				}
			}
		}
		
		protected function nextPageItem (e:Event) :void {
			var updateItem:Object;
			var areaItems:Array;
			if( _subform ) {
				updateItem = _formNodes[_formNodes.length-1].updateItem;
				areaItems = _formNodes[_formNodes.length-1].areaItems;
			}else{
				updateItem = this.updateItem;
				areaItems = this.areaItems;
			}
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
								this.updateItem = areaItems[i+1];
								if( _subform ) {
									_formNodes.pop();
								}
								displayInsertForm( T, true, _subform, _inlineArea, areaItems, "", 0, 2 );
							}else Console.log("ERROR: Can Not Find Template '" + areaItems[i + 1].subtemplate + "' For Page Item: " +  areaItems[i + 1].name);
							
							break;
						}
					}
				}
			}
		}
		
		protected function prevPageItem (e:Event) :void {
			var updateItem:Object;
			var areaItems:Array;
			if( _subform ) {
				updateItem = _formNodes[_formNodes.length-1].updateItem;
				areaItems = _formNodes[_formNodes.length-1].areaItems;
			}else{
				updateItem = this.updateItem;
				areaItems = this.areaItems;
			}
			if ( updateItem ) {
				var L:int = areaItems.length;
				
				for( var i:int = L-1; i >= 0; i--)
				{
					if( areaItems[i] && areaItems[i].name == updateItem.name )
					{
						if( i > 0 && areaItems[i-1] )
						{
							var T:Template = CTTools.findTemplate( areaItems[i-1].subtemplate, "name" );
							if( T ) {
								this.updateItem = areaItems[i-1];
								if( _subform ) {
									_formNodes.pop();
								}
								displayInsertForm( T, true, _subform, _inlineArea, areaItems, "", 0, 2 );
							}else Console.log("ERROR: Can Not Find Template '" + areaItems[i-1].subtemplate + "' For Page Item: " +  areaItems[i-1].name);
							
							break;
						}
					}
				}
				
			}
		}
		
		public function showAreaItems () :void {}
		public function displayInsertForm ( tmpl:Template, isUpdateForm:Boolean = false, subform:Boolean = false, inlineArea:String = "", _areaItems:Array = null,
										cat:String="", ltscroll:Number=0, gotoDirection:int=1, forceLevel:Boolean = false) :void {}
	}
}
