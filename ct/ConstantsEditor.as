package ct
{
	import agf.ui.*;
	import agf.html.*;
	import agf.events.*;
	import agf.animation.Animation;
	import agf.icons.IconBack;
	import agf.icons.IconArrowDown;
	import agf.icons.IconArrowRight;
	import agf.icons.IconFromFile;
	import agf.Main;
	import agf.Options;
	import agf.tools.Application;
	import fl.transitions.easing.Regular;
	import fl.transitions.easing.Strong;
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextFieldAutoSize;
	import flash.filesystem.File;
	import flash.net.FileReference;
	import flash.utils.setTimeout;
	import ct.ctrl.PropertyCtrl;
	import agf.db.DBResult;
	import agf.tools.Console;
	import ct.ctrl.InputTextBox;
	
	public class ConstantsEditor extends AreaEditor
	{
		public function ConstantsEditor( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
			Application.instance.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		private var searchBox:SearchBox;
		private var folderBackBtn:Button;
		private var folderLabel:Label;
		private var currItem:PropertyCtrl;
		private var prevButton:Button;
		private var prevButtonVisible:Boolean=true;
		private var nextButton:Button;
		private var nextButtonVisible:Boolean=true;
		
		internal static var clickScrolling:Boolean=false;
		private var clickY:Number=0;
		
		public static var currPF:ProjectFile;
		
		internal function get currentItem () :PropertyCtrl {
			return currItem;
		}
		
		// Change interface if splitpaths changes
		private var tmplSplitPaths:String;
		private var currCat:String=""; // category for property folding
		private var prevCat:Array=null;
		private var rtScroll:Number=0;
		
		private var tmpCurrTemplate:Template;
		
		private function removePanel (e:Event) :void {
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
				stage.removeEventListener( MouseEvent.MOUSE_UP, btnUp );
			}
			Main(Application.instance).view.removeEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		public override function setWidth( w:int) :void {
			super.setWidth(w);
			var sbw:int = 0;
			if( scrollpane ) {
				scrollpane.x = int(cssLeft);
				if( scrollpane.slider.visible ) sbw = scrollpane.slider.cssSizeX + 4;
			}
			
			if( itemList) {
				if(itemList.items) {
					var yp:int=0;
					var lbl:Label;
					
					for( var i:int=0; i < itemList.items.length; i++) {
						itemList.items[i].setWidth( w - (itemList.items[i].cssBoxX + cssBoxX + sbw) );
						if( itemList.items[i] is Label ) {
							lbl = Label( itemList.items[i] );
							lbl.textField.autoSize = TextFieldAutoSize.LEFT;
							lbl.textField.wordWrap = true;
							lbl.textField.width = int( w - (sbw + cssLeft*2) );
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
				nameCtrl.setWidth( w - (nameCtrl.cssBoxX + cssBoxX) ); 
				nameCtrl.x = int(cssLeft);
			}
			
			if( nextButton && nextButton ) {
				nextButton.x = (w) - (nextButton.getWidth() + nextButton.cssMarginRight);
				prevButton.x = nextButton.x - (prevButton.getWidth() + prevButton.cssMarginRight);
			}
			
			if( searchBox ) {
				searchBox.setWidth( w );
			}
			
			if( folderBackBtn && folderLabel ) {
				folderLabel.x = int(( w - (folderLabel.textField.textWidth+cssLeft*2+sbw) ) * .5);
				
				if( folderLabel.x < folderBackBtn.x + folderBackBtn.cssSizeX + 4 ) {
					folderLabel.x = int(folderBackBtn.x + folderBackBtn.cssSizeX + 4);
				}
			}
			if(scrollpane) scrollpane.setWidth( w - cssBoxX );
		}
		
		public override function setHeight (h:int) :void {
			super.setHeight(h);
			if( itemList) {
				itemList.setHeight(0);
				itemList.init();
			}
			if(scrollpane) {
				if( folderBackBtn && folderLabel ) {
					scrollpane.y = int(cssTop + 16 + Math.max( folderBackBtn.cssSizeY, folderLabel.cssSizeY ));
					scrollpane.setHeight( int( h-(Math.max(folderBackBtn.cssSizeY, folderLabel.cssSizeY) + cssBoxY + 32) ) ); 
				}else{
					if( searchBox ) {
						scrollpane.setHeight(h - (cssBoxY + searchBox.cssSizeY + searchBox.cssBoxY) );
						scrollpane.y = int(cssTop + searchBox.cssSizeY + searchBox.cssBoxY);
					}else{
						scrollpane.setHeight(h - ( cssBoxY ));
						scrollpane.y = int(cssTop);
					}
				}
				scrollpane.contentHeightChange();
			}
		}
		
		private static var anim = new Animation();
		private static var anim2 = new Animation();
		private static var currentCat:Array;
		private static var currCatId:int=0;
		
		private function selectSibling (e:PopupEvent) :void
		{
			var lb:String = e.selectedItem.label;
			var goto:String = e.selectedItem.options.name;
			var dir:int = 4; // go down
			var pp:Popup = e.currentPopup;
			
			var L:int = pp.rootNode.children.length;
			
			for( var i:int = 0; i<L; i++ ) {
				if( pp.rootNode.children[i].options.name == goto ) {
					if( i < currSib ) {
						dir = 3;
					}else if( i == currSib ) {
						dir = 2;
					}
					currSib = i;
					currCat = goto;
					break;
				}
			}
			
			if( siblingsPP && contains(siblingsPP) ) removeChild( siblingsPP );
			
			setTimeout( function() {
				displayTemplateProps( currentTemplate, goto, 0, dir, true );
				folderLabel.label = lb;
				setWidth( getWidth() );
			},0);	
		}
		
		private static var siblingsPP:Popup;
		private static var currSib:int;
		
		private function sectionLabelDown (e:MouseEvent) :void {
			
			if( currentCat && currentCat.length > 0 && currentCat.length > currCatId && currCatId > 0 )
			{
				var sibs:Array = currentCat[ currCatId - 1 ];
				
				var L:int = sibs.length;
				var i:int;
				
				if( siblingsPP && contains(siblingsPP) ) removeChild( siblingsPP );
				siblingsPP = null;
				
				var pp:Popup = new Popup ([""], 0, 0, this, styleSheet, '', 'const-sibling-popup', true);
				pp.alignH = "left";
				
				pp.x = folderLabel.x - 4;
				pp.y = folderLabel.y + folderLabel.cssSizeY;
				
				siblingsPP = pp;
				
				pp.addEventListener( Event.SELECT, selectSibling );
				var ppi:PopupItem;
				
				for( i=0; i<L; i++ ) {
					if(sibs[i] == currCat) {
						currSib = i;
						//break;
					}
					ppi = pp.rootNode.addItem( [Language.getKeyword(sibs[i])], styleSheet );
					ppi.options.name = sibs[i];
				}
				
				setTimeout( function ()
				{
					siblingsPP.open(null);
					
				}, 0);
			}
			
		}
		
		// gotoDirection: 0 = backward, forward = 1, 2 = same level
		public function displayTemplateProps ( tmpl:Template, cat:String="", ltscroll:Number=0, gotoDirection:int=1, forceLevel:Boolean = false) :void
		{
			if( !tmpl || !tmpl.indexFile || !CTTools.procFiles) return;
			
			currentTemplate = tmpl;
			
			var files:Array = CTTools.procFiles;
			var L:int = files.length;
			
			if( L > 0 )
			{
				if( !forceLevel ) {
					if( folderBackBtn  && contains(folderBackBtn) ) removeChild( folderBackBtn );
					if( prevButton && contains(prevButton) ) removeChild( prevButton );
					if( nextButton && contains(nextButton) ) removeChild( nextButton );
					//if(  anim && contains(anim) ) removeChild( anim );
					//if(  anim2 && contains(anim2) ) removeChild( anim2 );
					if( searchBox && contains( searchBox ) ) removeChild( searchBox );
					if( folderLabel && scrollpane && contains( folderLabel ) ) removeChild( folderLabel );
					folderBackBtn = null;
					folderLabel = null;
				}
				
				if( scrollpane && itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
				if( scrollpane && contains( scrollpane) ) removeChild( scrollpane );
				
				var pfid:int;
				var pth:String;
				var pf:ProjectFile;
				var i:int;
				var j:int;
				var jL:int;
				var ict:CssSprite;
				
				var w:int = cssSizeX - cssBoxX;
				
				scrollpane = new ScrollContainer( w, 0, this, styleSheet,'', '', false);
				scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
				
				itemList = new ItemList(0,0,scrollpane.content,styleSheet,'','constants-container',true);
				var currSprite:CssSprite;
				itemList.margin = 0;
				
				var propName:String;
				var propType:String;
				var propVal:String;
				var propStore:Object = {}
				var lbl:Label;
				var btn:Button;
				var tmp:String;
				var labelText:String;
				var secj:String;
				
				tmplSplitPaths = "";
				
				var sortArr:Array = [];
				var sort:Boolean = tmpl.sortproperties == "name" || tmpl.sortproperties == "priority";
				
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
					else
					{
						// go back
						scrollpane.content.x = -CssSprite(parent).cssSizeX;
						anim.run( scrollpane.content, { x: 0 }, 345, Strong.easeOut );
						anim2.run( scrollpane.content, { alpha: 1 }, 900, Strong.easeOut );
					}
					
				}, 0);
				 
				
				if( !forceLevel ) {
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
						
						lbl.addEventListener( MouseEvent.MOUSE_DOWN, sectionLabelDown );
						
						var backbtn:Button = new Button( [new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "navi-left-btn.png", Options.iconSize, Options.iconSize), 
						Language.getKeyword(prevCat && prevCat.length > 0 ? prevCat[prevCat.length-1].name : "Settings")], 0, 0, this, styleSheet, '', 'back-button', false );
						
						backbtn.addEventListener( MouseEvent.CLICK, backButtonHandler);
						backbtn.margin = 0;
						backbtn.clipSpacing = 0;
						backbtn.init();
						
						backbtn.y = int(cssTop + backbtn.cssMarginTop);
						backbtn.x = int(cssLeft + backbtn.cssMarginLeft);
						
						folderBackBtn = backbtn;
						
						prevButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "navi-left-btn.png",Options.iconSize,Options.iconSize) ], 0, 0, this, styleSheet, '', 'ce-prev-button', false);
						prevButton.addEventListener( MouseEvent.CLICK, prevClick );
						prevButton.y = cssTop;
						
						nextButton = new Button( [new IconFromFile(Options.iconDir + CTOptions.urlSeparator + "navi-right-btn.png",Options.iconSize,Options.iconSize) ], 0, 0, this, styleSheet, '', 'ce-next-button', false);
						nextButton.addEventListener( MouseEvent.CLICK, nextClick );
						nextButton.y = cssTop;
						
						currCatId = currentCat.push ( [] ) - 1;
					}
					else
					{
						// root category
						prevCat = null;
						currCat = "";
						
						lbl = new Label( w,0, itemList, styleSheet, '', 'property-label', true);
						lbl.init();
						
						if (sort) sortArr.push( { t:lbl, sorting: (tmpl.sortproperties == "priority" ? 0 : "") } );
						else itemList.addItem(lbl, true);
						
						/* // TODO Add Search to search in properties and page items -> SearchScreen
						searchBox = new SearchBox( w, 32, this, styleSheet, "", "searchbox", false );
						scrollpane.setHeight( cssSizeY - (searchBox.cssSizeY + searchBox.cssBoxY) );
						scrollpane.y = cssTop + searchBox.cssSizeY + searchBox.cssBoxY;
						*/
						
						currentCat = [[]];
						currCatId = 0;
					}
				}
				
				for(i = 0; i<L; i++)
				{
					pf = CTTools.procFiles[ i ] as ProjectFile;
					
					if( pf.templateId == tmpl.name )
					{
						if( pf.templateProperties )
						{
							if (pf.splits) {
								tmplSplitPaths += pf.splitPath;
							}

							jL = pf.templateProperties.length;
							
							for(j=0; j<jL; j++)
							{
								propName = pf.templateProperties[j].name;
								if( propName == "name" ) continue;
								
								if( cat != "" ) {
									if( pf.templateProperties[j].sections && pf.templateProperties[j].sections.join(".") == cat ) {
										// display section.. 
									}else{
										continue;
									}
								}else{
									if( pf.templateProperties[j].sections && pf.templateProperties[j].sections.length > 0) {
										if( pf.templateProperties[j].sections[0] != "" && pf.templateProperties[j].sections[0].toLowerCase() != "root") {
											continue;
										}
									}
								}
								
								if(propStore[propName]) continue; // ignore multiple properties with the same name
								
								propStore[propName] = true;
								propType = pf.templateProperties[j].defType.toLowerCase();
								
								if( propType == "folder" )
								{
									if( pf.templateProperties[j].args && pf.templateProperties[j].args.length > 0 ) tmp = Language.getKeyword( pf.templateProperties[j].args[0]);
									else tmp = Language.getKeyword( pf.templateProperties[j].name );
									
									btn = new Button( [ tmp, new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "navi-right.png", Options.iconSize, Options.iconSize)], w,0, itemList, styleSheet, '', 'constanteditor-folder', false);
									
									if( pf.templateProperties[j].args && pf.templateProperties[j].args.length > 1 ) tmp = pf.templateProperties[j].args[1];
									else tmp = pf.templateProperties[j].name;
									
									btn.options.folder = tmp;
									btn.options.propObject = pf.templateProperties[j];
									btn.addEventListener( MouseEvent.CLICK, folderClick );
									
									if(!forceLevel) currentCat[currCatId].push( tmp );
									
									if (sort) sortArr.push( { t:btn, sorting: (tmpl.sortproperties == "priority" ? (btn.options.propObject.priority || 0) : (btn.options.propObject.name || "")) } );
									else itemList.addItem(btn, true);
								
								}
								else if( propType == "label" || propType == "section" )
								{
									// Label or Section Type
									if( pf.templateProperties[j].args && pf.templateProperties[j].args.length > 0 ) {
										lbl = new Label( w,0, itemList, styleSheet, '', 'property-' + (propType) + (pf.templateProperties[j].args.length > 1 ? " " + pf.templateProperties[j].args[1] : ""),true);
										lbl.options.propObject = pf.templateProperties[j];
										lbl.label = Language.getKeyword( pf.templateProperties[j].args[0] );
										
										lbl.textField.autoSize = TextFieldAutoSize.LEFT;
										lbl.textField.wordWrap = true;
										lbl.textField.width = w;
										
										lbl.init();
										
										if (sort) sortArr.push( { t:lbl, sorting: (tmpl.sortproperties == "priority" ? (lbl.options.propObject.priority || 0) : (lbl.options.propObject.name || "")) } );
										else itemList.addItem(lbl, true);
									}else{
										if( CTOptions.debugOutput ) Console.log( "WARNING: SectionLabel '"+ propName + "' Has No Arguments Setup In '" + pf.filename + "'" );
									}
								}
								else
								{
									if( pf.templateProperties[j].sections != null ) {
										secj = pf.templateProperties[j].sections.join(".");
									}else{
										secj = "";
									}
									
									// Input
									if( secj && tmpl.dbProps[ secj + "." + propName ] )
									{
										propVal = tmpl.dbProps[secj + "." + propName].value;
									}
									else if( !secj && tmpl.dbProps[ propName ] )
									{
										propVal = typeof tmpl.dbProps[ propName ] == "object" ? tmpl.dbProps[ propName ].value : tmpl.dbProps[ propName ];
									}
									else
									{
										propVal = pf.templateProperties[j].defValue;
									}
									
									if( pf.templateProperties[j].sections && Language.hasKeyword( pf.templateProperties[j].sections.join(".") + "." + propName.toLowerCase()) ) {
										labelText = Language.getKeyword( pf.templateProperties[j].sections.join(".") + "." + propName.toLowerCase() );
									}else{
										labelText =  Language.getKeyword(propName.toLowerCase());
									}
									
									
									ict = new PropertyCtrl(labelText, propName, propType, propVal, pf.templateProperties[j], pf.templateProperties[j].args,
									w, 0, itemList, styleSheet,'', 'constant-prop', false);
									ict.options.propObject = pf.templateProperties[j];
									ict.options.pf = pf;
									ict.addEventListener( PropertyCtrl.ENTER, ictChange );
									//if( propType == "vector" || propType == "image" || propType == "plugin" ) {
										PropertyCtrl(ict).textBox.addEventListener("heightChange", inputHeightChange);
									//}
									if(sort) sortArr.push( { t:ict, sorting: (tmpl.sortproperties == "priority" ? (pf.templateProperties[j].priority||0x7FFFFFFF) : (pf.templateProperties[j].name||"Zyx"))} );
									else itemList.addItem(ict, true);
									
								}
							}
						}
					}
				}
				
				if( currCatId > 0 )
				{
					if( currentCat[ currCatId-1 ].length <= 1 )
						{
						nextButton.alpha = 0.25;
						prevButton.alpha = 0.25;
					}
					else
					{
						if( currCat == currentCat[ currCatId-1 ][ currentCat[ currCatId-1 ].length-1 ] ){
							// last
							nextButton.alpha = 0.25;
						}else{
							nextButton.alpha = 1;
						}
						
						if( currCat == currentCat[ currCatId-1 ][ 0 ] ){
							// first
							prevButton.alpha = 0.25;
						}else{
							prevButton.alpha = 1;
						}
					}
				}
				if (sort) {
					jL = sortArr.length;
					itemList.clearAllItems();
					if ( tmpl.sortproperties == "priority" ) {
						sortArr.sortOn("sorting", Array.NUMERIC);
					}else {
						sortArr.sortOn("sorting");
					}
					for (j = 0; j < jL; j++ ){
						itemList.addItem( sortArr[j].t, true );
					}
				}
				
				scrollpane.x = int(cssLeft);
				
				itemList.format();
				itemList.init();
				
				setWidth( cssSizeX - cssBoxX );
				
				//if( !scrollpane.slider.visible ) {
				setTimeout( function() {
					setWidth( cssSizeX-cssBoxX );
				}, 250);
				
				setHeight(getHeight());
				
				scrollpane.contentHeightChange();
				
			}
		}
		
		protected function nextClick (e:MouseEvent) :void
		{
			if( currCat != "" && currentCat && currentCat.length >= currCatId ) {
				var list:Array = currentCat[currCatId-1];
				var L:int = list.length;
				for( var i:int=0; i<L; i++ ) {
					if( list[i] == currCat ) {
						if( list.length > i+1 ) {
							folderLabel.label = Language.getKeyword( list[i+1] );
							currCat = list[i+1];
							displayTemplateProps( currentTemplate, list[i+1], 0, 4, true );
							setWidth( getWidth() );
							break;
						}
					}
				}
			}
		}
		
		protected function prevClick (e:MouseEvent) :void
		{			
			if( currCat != "" && currentCat && currentCat.length >= currCatId ) {
				var list:Array = currentCat[currCatId-1];
				var L:int = list.length;
				for( var i:int=0; i<L; i++ ) {
					if( list[i] == currCat ) {
						if( i >= 1 ) {
							folderLabel.label = Language.getKeyword( list[i-1] );
							currCat = list[i-1];
							displayTemplateProps( currentTemplate, list[i-1], 0, 3, true);
							setWidth( getWidth());
							break;
						}
					}
				}
			}
		}
		
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
					
					displayTemplateProps( currentTemplate, currCat, scr, 0 );
					
					if( cc.scroll > 0 && scrollpane )
					{
						scrollpane.applyScrollValue(cc.scroll);
					}
				}
				else
				{
					displayTemplateProps( currentTemplate, "", 0, 0);
					if( rtScroll > 0 && scrollpane )
					{
						scrollpane.applyScrollValue(rtScroll);
					}
				}
				setWidth( cssSizeX-cssBoxX );
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
					if( !prevCat ) rtScroll = scr;
					
					displayTemplateProps( currentTemplate, e.currentTarget.options.folder, scr );
					setWidth( cssSizeX-cssBoxX );
				}
			}
		}
		
		private function inputHeightChange (e:Event):void {
			if( itemList ) {
				itemList.format();
				if( scrollpane ) scrollpane.contentHeightChange();
			}
		}

		// ConstantEditor Property-Ctrl Changed
		private function ictChange( e:Event ) :void
		{
			var it:PropertyCtrl = PropertyCtrl( e.currentTarget );
			
			currItem = it;
			
			if(currentTemplate)
			{
				var pc:PropertyCtrl = it;
				if(pc) {
					if( pc.textBox._supertype == "file" || pc.textBox._supertype == "image" || pc.textBox._supertype == "video" || pc.textBox._supertype == "audio" || pc.textBox._supertype == "pdf")   // was type!?
					{
						storeFile( pc.textBox );
					}
					else if(pc.textBox.type == "vector" && (pc.textBox.vectorType == "file" || pc.textBox.vectorType == "image" || pc.textBox.vectorType == "video" || pc.textBox.vectorType == "audio" || pc.textBox.vectorType == "pdf"))
					{
						storeFileVector( pc.textBox );
					}
				}
				
				var secj:String = "";
				
				if( it._propObj.sections )
				{
					secj = it._propObj.sections.join(".");
				}
				
				if( secj )
				{
					if( currentTemplate.dbProps[ secj +"." + it._name ] == undefined )
					{
						currentTemplate.dbProps[ secj +"." + it._name ] = { name: it._name, type:it.type, section:secj, value:it.textBox.value, templateid:currentTemplate.sqlUid };
					}
					else
					{
						currentTemplate.dbProps[ secj +"." + it._name ].value = it.textBox.value;
					}
				}
				
				if( currentTemplate.dbProps[ it._name ] != null ) 
				{
					currentTemplate.dbProps[ it._name ].value = it.textBox.value;
				}
				else
				{
					// Create new item
					currentTemplate.dbProps[ it._name ] = { name:it._name, type:it.type, value:it.textBox.value, section: it._propObj.sections };
					
					if(it._propObj && it._propObj.sections ) {
						currentTemplate.dbProps[ it._propObj.sections.join(".") + "." + it._name ] =  { name:it._name, type:it.type, value:it.textBox.value, section: it._propObj.sections, templateid:currentTemplate.sqlUid };
					}
				}
				
				currPF = it.options.pf;
			}
			
			var rv:Boolean = CTTools.db.query( selectInsertOrUpdateResHandler, 'SELECT uid FROM tmplprop WHERE name = "' + it._name + '" AND templateid='+currentTemplate.sqlUid+' AND section="'+secj+'";' );
			if( !rv ) {
				Console.log( "DB-Error: SELECT Statement Failed On Template Properties Table");
			}else {
				CTMain(Application.instance).showLoading();
			}
		}
		
		public function insertPropResult (res:DBResult ) :void
		{
			if( res ) {
				if ( tmplSplitPaths != "" )
				{
					// search actual split path
					var L:int = CTTools.procFiles.length;
					var tmppath:String = "";
					for (var i:int = 0; i < L; i++) {
						if (CTTools.procFiles[i].templateId == currentTemplate.name) {
							if ( CTTools.procFiles[i].splits ) {
								tmppath += CTTools.procFiles[i].splitPath;
							}
						}
					}
					if ( tmplSplitPaths != tmppath ) {
						displayTemplateProps(currentTemplate);
					}
				}
				
				// Files have to update constant values
				CTTools.invalidateProperty( currItem._name );
			
				if ( CTOptions.autoSave )
				{
					setTimeout( function()
					{
						CTTools.save();
						
						
						setTimeout( function() {
							try {
							Application.instance.view.panel.src["displayFiles"]();
						}catch(e:Error) {
							
						}
							CTMain(Application.instance).hideLoading(); }, 350 );
						}, 0);
						
						return;
				}
			}
			
			CTMain(Application.instance).hideLoading();
		}
		
		public function selectInsertOrUpdateResHandler ( res:DBResult ) :void
		{
			if( !currItem ) return;
			if( res )
			{
				var it:PropertyCtrl = currItem;
				var pms:Object = {};
				pms[":name"] = it._name;
				pms[":type"] = it.type;
				
				if( it.textBox._supertype == "text" || it.textBox._supertype == "richtext" || it.textBox._supertype == "line" ) {
					pms[ ":value"] = HtmlParser.toDBText( it.textBox.value, false, true );
					currentTemplate.dbProps[ it._name ].value = pms[ ":value"];
				}else{
					pms[":value"] = it.textBox.value;
				}
				if( it._propObj && it._propObj.sections ) {
					pms[":section"] = it._propObj.sections.join(".");
					
				}else{
					pms[":section"] = "";
				}
				
				if( res && res.data && res.data.length > 0 )
				{
					// UPDATE
					pms[":tmplid"] = currentTemplate.sqlUid;
					var rv:Boolean = CTTools.db.updateQuery( insertPropResult, "tmplprop", 'name=:name AND templateid=:tmplid AND section=:section', 'value=:value,type=:type', pms);
					if( !rv ) {
						Console.log( "DB-Error: UPDATE Statement Failed On Template Properties Table " + it._name + ", " + it.type);
						CTMain(Application.instance).hideLoading();
					}
				}
				else
				{
					// INSERT;
					pms[":templateid"] = currentTemplate.sqlUid;
					if(!CTTools.db.insertQuery( insertPropResult, "tmplprop", 'name,section,type,value,templateid',':name,:section,:type,:value,:templateid', pms)) {
						Console.log( "DB-Error: INSERT Statement Failed On Template Properties Table " + it._name + ", " + it.type);
						CTMain(Application.instance).hideLoading();
					}
				}
				
			}else{
				Console.log( "DB-Error: SELECT Statement Failed On Template Properties Table " + it._name + ", " + it.type);
				CTMain(Application.instance).hideLoading();
			}
		}
		
		public override function createAed () :void
		{
			tmpCurrTemplate = currentTemplate;
		}
		
		public override function displayInsertForm ( tmpl:Template, isUpdateForm:Boolean=false, subform:Boolean=false, inlineArea:String="", _areaItems:Array=null ) :void {
			if( folderBackBtn && contains(folderBackBtn) ) {
				removeChild(folderBackBtn);
				folderBackBtn = null;
			}
			if( folderLabel && contains(folderLabel) ) {
				removeChild(folderLabel);
				folderLabel = null;
			}
			if( currentArea == null ) {
				currentArea = new Area( 0,0,[],0, inlineArea );
			}
			super.displayInsertForm( tmpl, isUpdateForm, subform, inlineArea, _areaItems );
		}
		
		public override function showAreaItems () :void
		{
			if( nameCtrl && contains(nameCtrl)) removeChild( nameCtrl );
			nameCtrl = null;
			displayTemplateProps( CTTools.activeTemplate, currCat, rtScroll );
			setWidth( getWidth() );
		}
		
	}
}
