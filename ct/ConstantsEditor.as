package ct
{
	import agf.ui.*;
	import agf.html.*;
	import agf.events.*;
	import agf.icons.IconBack;
	import agf.icons.IconArrowDown;
	import agf.icons.IconArrowRight;
	import agf.icons.IconFromFile;
	import agf.Main;
	import agf.Options;
	import agf.tools.Application;
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextFieldAutoSize;
	import flash.filesystem.File;
	import flash.net.FileReference;
	import ct.ctrl.PropertyCtrl;
	import agf.db.DBResult;
	import agf.tools.Console;
	import ct.ctrl.InputTextBox;
	
	public class ConstantsEditor extends CssSprite
	{
		public function ConstantsEditor( w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
			Application.instance.view.addEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		public var searchBox:SearchBox;
		
		public var scrollpane:ScrollContainer;
		public var currentTemplate:Template;
		private var itemList:ItemList;
		private var folderBackBtn:Button;
		private var folderLabel:Label;
		internal var currItem:PropertyCtrl;
		internal static var clickScrolling:Boolean=false;
		private var clickY:Number=0;
		
		public static var currPF:ProjectFile;
		
		// Change interface if splitpaths changes
		private var tmplSplitPaths:String;
		private var currCat:String=""; // category for property folding
		
		private function removePanel (e:Event) :void {
			if( stage ) {
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnMove );
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, btnUp );
			}
			Main(Application.instance).view.removeEventListener( AppEvent.VIEW_CHANGE, removePanel );
		}
		
		public override function setWidth( w:int) :void {
			super.setWidth(w);
			var sbw:int = 0;
			if( scrollpane && scrollpane.slider.visible ) sbw = 16;
				
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
							lbl.textField.width = w - (sbw + cssLeft*2);
							itemList.items[i].y = yp;
							yp += itemList.items[i].cssSizeY + itemList.margin;
						}else{
							itemList.items[i].y = yp;
							yp += itemList.items[i].cssSizeY + itemList.margin;
						}
					}
				}
				
				itemList.setWidth(0);
				itemList.init();
			}
			if( folderBackBtn && folderLabel ) {
				folderLabel.x = ( w - (folderLabel.textField.textWidth+cssLeft*2+sbw) ) * .5;
				
				if( folderLabel.x < folderBackBtn.x + folderBackBtn.cssSizeX + 4 ) {
					folderLabel.x = folderBackBtn.x + folderBackBtn.cssSizeX + 4;
				}
			}
			if(scrollpane) scrollpane.setWidth( w - cssBoxX);
		}
		
		public override function setHeight (h:int) :void {
			super.setHeight(h);
			if( itemList) {
				itemList.setHeight(0);
				itemList.init();
			}
			if(scrollpane) {
				if( folderBackBtn && folderLabel ) {
					scrollpane.setHeight( (h-Math.max(folderBackBtn.cssSizeY, folderLabel.cssSizeY)) - cssBoxY); 
				}else{
					scrollpane.setHeight(h - cssBoxY); 
				}
				scrollpane.contentHeightChange();
				
			}
		}
		
		public function abortClickScrolling () :void {
			btnUp(null);
			clickScrolling=false;
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
		
		public function displayTemplateProps ( tmpl:Template, cat:String="", ltscroll:Number=0 ) :void
		{
			if( !tmpl || !tmpl.indexFile || !CTTools.procFiles) return;
			
			currentTemplate = tmpl;
			
			var files:Array = CTTools.procFiles;
			var L:int = files.length;
			
			if( L > 0 )
			{
				if( searchBox && contains( searchBox ) ) removeChild( searchBox );
				if( folderBackBtn && scrollpane && contains(folderBackBtn) ) removeChild( folderBackBtn );
				if( folderLabel && scrollpane && contains( folderLabel ) ) removeChild( folderLabel );
				if( scrollpane && itemList && scrollpane.content.contains( itemList ) ) scrollpane.content.removeChild( itemList );
				if( scrollpane && contains( scrollpane) ) removeChild( scrollpane );
				
				var pfid:int;
				var pth:String;
				var pf:ProjectFile;
				var i:int;
				var j:int;
				var jL:int;
				var ict:CssSprite;
				
				folderBackBtn = null;
				folderLabel = null;
				
				var w:int = cssSizeX - (cssBoxX);
				
				scrollpane = new ScrollContainer( w, getHeight(), this, styleSheet,'', '', false);
				scrollpane.setHeight( cssSizeY );
				scrollpane.setWidth( cssSizeX );
				scrollpane.content.addEventListener( MouseEvent.MOUSE_DOWN, btnDown );
				
				itemList = new ItemList(0,0,scrollpane.content,styleSheet,'','constants-container',true);
				var currSprite:CssSprite;
				itemList.margin = 7;
				
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
					lbl.y = cssTop + lbl.cssMarginTop;
					
					var backbtn:Button = new Button( [new IconFromFile( Options.iconDir + CTOptions.urlSeparator + "navi-left.png", Options.iconSize, Options.iconSize), Language.getKeyword(prevCat && prevCat.length > 0 ? prevCat[prevCat.length-1].name : "Settings")], 0, 0, this, styleSheet, '', 'back-button', false );
					
					backbtn.addEventListener( MouseEvent.CLICK, backButtonHandler);
					backbtn.margin = 0;
					backbtn.clipSpacing = 0;
					backbtn.init();
					
					backbtn.y = cssTop + backbtn.cssMarginTop;
					backbtn.x = cssLeft + backbtn.cssMarginLeft;
					
					folderBackBtn = backbtn;
					scrollpane.setHeight( getHeight() - scrollpane.y );
				}else{
					// root category
					prevCat = null;
					currCat = "";
					
					lbl = new Label( w,0, itemList, styleSheet, '', 'property-section', true);
					lbl.options.propObject = null;// pf.templateProperties[j];
					lbl.label = Language.getKeyword( "Settings" );
					
					lbl.textField.autoSize = TextFieldAutoSize.LEFT;
					lbl.textField.wordWrap = true;
					lbl.textField.width = w;
					
					lbl.init();
					
					if (sort) sortArr.push( { t:lbl, sorting: (tmpl.sortproperties == "priority" ? 0 : "") } );
					else itemList.addItem(lbl, true);
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
									btn.setWidth( btn.getWidth()-btn.cssBoxX );
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
									if( propType == "vector") {
										PropertyCtrl(ict).textBox.addEventListener("heightChange", inputHeightChange);
									}
									if(sort) sortArr.push( { t:ict, sorting: (tmpl.sortproperties == "priority" ? (pf.templateProperties[j].priority||0x7FFFFFFF) : (pf.templateProperties[j].name||"Zyx"))} );
									else itemList.addItem(ict, true);
									
								}
							}
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
				
				// Insert empty label for scroller height
				lbl = new Label( w,16, itemList, styleSheet, '', 'property-label', false);
				itemList.addItem( lbl, true );
				
				scrollpane.x = cssLeft;
				
				if( folderBackBtn && folderLabel ) {
					scrollpane.y = cssTop + Math.max( folderBackBtn.cssSizeY, folderLabel.cssSizeY );
				}else{
					scrollpane.y = cssTop;
				}
				itemList.format();
				itemList.init();
				scrollpane.contentHeightChange();
				
				if( !scrollpane.slider.visible ) {
					setWidth( cssSizeX-cssBoxX );
				}
				setHeight(getHeight());
			}
		}
		private var prevCat:Array;
		private var rtScroll:Number=0;
		
		private function backButtonHandler (e:Event):void {
			if( currentTemplate ) {
				if( prevCat ) {
					var cc:Object = prevCat.pop();
					currCat = cc.name;
					if(prevCat.length == 0) prevCat = null;
					var scr:Number = scrollpane.slider.value;
					
					displayTemplateProps( currentTemplate, currCat, scr );
					
					if( cc.scroll > 0 && scrollpane ) {
						scrollpane.applyScrollValue(cc.scroll);
					}
				}else{
					displayTemplateProps( currentTemplate, "");
					if( rtScroll > 0 && scrollpane ) {
						scrollpane.applyScrollValue(rtScroll);
					}
				}
				setWidth( cssSizeX-cssBoxX );
			}
		}
		private function folderClick (e:Event):void {
			if( clickScrolling ) {
				clickScrolling = false;
			}else{
				if( currentTemplate ) {
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
					if( pc.type == "file" || pc.type == "image" || pc.type == "video" || pc.type == "audio" || pc.type == "pdf") {
						storeFile( pc.textBox );
					}else if(pc.type == "vector" && (pc.textBox.vectorType == "file" || pc.textBox.vectorType == "image" || pc.textBox.vectorType == "video" || pc.textBox.vectorType == "audio" || pc.textBox.vectorType == "pdf")){
						storeFileVector( pc.textBox );
					}
				}
				
				var secj:String = "";
				if( it._propObj.sections ) {
					secj = it._propObj.sections.join(".");
				}
				
				if( secj ) {
					if( currentTemplate.dbProps[ secj +"." + it._name ] == undefined ) {
						currentTemplate.dbProps[ secj +"." + it._name ] = { name: it._name, type:it.type, section:secj, value:it.textBox.value };
					}else{
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
					currentTemplate.dbProps[ it._name ] = { name:it._name, type:it.type, value:it.textBox.value, section: it._propObj.sections /*argv:it.options.propObject.argv, args:it.options.propObject.args*/ };
					
					if(it._propObj && it._propObj.sections ) {
						currentTemplate.dbProps[ it._propObj.sections.join(".") + "." + it._name ] =  { name:it._name, type:it.type, value:it.textBox.value, section: it._propObj.sections };
					}
				}
				
				currPF = it.options.pf;
			}
			
			var rv:Boolean = CTTools.db.query( selectInsertOrUpdateResHandler, 'SELECT uid FROM tmplprop WHERE name = "' + it._name + '" AND templateid='+currentTemplate.sqlUid+' AND section="'+secj+'";' );
			if( !rv ) {
				Console.log( "DB-Error: SELECT statement failed on template properties table");
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
				
				// Files have to update all constant values
				CTTools.invalidateTemplateFiles ( currentTemplate, false );
				
				if( CTOptions.autoSave ) {
					CTTools.save();
					try {
						Application.instance.view.panel.src["displayFiles"]();
					}catch(e:Error) {
						
					}
				}
			}
			CTMain(Application.instance).hideLoading();
		}
		
		public function selectInsertOrUpdateResHandler ( res:DBResult ) :void {
			if( !currItem ) return;
			if( res ) {
				var it:PropertyCtrl = currItem;
				var pms:Object = {};
				
				if( res && res.data && res.data.length > 0 ) {
					// UPDATE
					pms[":name"] = it._name;
					pms[":value"] = it.textBox.value;
					
					if( it._propObj && it._propObj.sections ) {
						pms[":section"] = it._propObj.sections.join(".");
					}else{
						pms[":section"] = "";
					}
					
					pms[":tmplid"] = currentTemplate.sqlUid;
					var rv:Boolean = CTTools.db.updateQuery( insertPropResult, "tmplprop", 'name=:name AND templateid=:tmplid AND section=:section', 'value=:value', pms);
					if( !rv ) {
						Console.log( "DB-Error: UPDATE statement failed on template properties table " + it._name + ", " + it.type);
						CTMain(Application.instance).hideLoading();
					}
				}else{
					// INSERT
					pms[":name"] = it._name;
					pms[":type"] = it.type;
					if( it._propObj && it._propObj.sections ) {
						pms[":section"] = it._propObj.sections.join(".");
					}else{
						pms[":section"] = "";
					}
					pms[":value"] = it.textBox.value;
					pms[":templateid"] = currentTemplate.sqlUid;
					if(!CTTools.db.insertQuery( insertPropResult, "tmplprop", 'name,section,type,value,templateid',':name,:section,:type,:value,:templateid', pms)) {
						Console.log( "DB-Error: INSERT statement failed on template properties table " + it._name + ", " + it.type);
						CTMain(Application.instance).hideLoading();
					}
				}
			}else{
				Console.log( "DB-Error: SELECT statement failed on template properties table " + it._name + ", " + it.type);
				CTMain(Application.instance).hideLoading();
			}
		}
		
		private function storeFileVector (pc_textBox:InputTextBox) :void {
			if( pc_textBox.vectorTextFields ) {
				var L:int = pc_textBox.vectorTextFields.length;				
				for(var i:int =0 ; i<L; i++) {
					storeFile( pc_textBox.vectorTextFields[i], i );
				}
				pc_textBox.textEnter();
			}
		}
		
		private function storeFile (pc_textBox:InputTextBox, vectorIndex:int=-1) :void {
			
			// store a file input
			
			var fileHere:Boolean = false;
			var filePath:String = "";
			
			if( pc_textBox.value == "" || pc_textBox.value.toLowerCase() == "none" ) {
				return;
			}
			var webfile:Boolean = false;
			
			if( pc_textBox.value.substring(0,4)=="http" ) {
				if( pc_textBox.value.substring(0,7) == "http://" || pc_textBox.value.substring(0,8)=="https://" ) {
					webfile = true;
				}
			}
			
			if(!webfile) {
				// test if file is in www-directory
				var tf:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + pc_textBox.value );
				if( tf && tf.exists ) {
					fileHere = true;
					filePath = tf.url;
				}

				// test if path is relative website path in file www_folder setup
				/*var testfile:File = new File( CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + pc_textBox.www_folder + CTOptions.urlSeparator + pc_textBox.value );
				if( testfile && testfile.exists ) {
					fileHere = true;
					filePath = testfile.url;
				}*/
				
				if( fileHere ) {
					if( CTOptions.debugOutput )  Console.log("File " + filePath + " is already in www_folder, using existing file...");
					return;
				}
			}
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
				obj.month = d.month + 1;
				obj.day = d.day;
				obj.date = d.date;
				obj.hours = d.hours;
				obj.minutes = d.minutes;
				obj.seconds = d.seconds;
				obj.milliseconds = d.milliseconds;
				obj.time = d.time;
				obj.timezoneOffset = d.timezoneOffset;
				obj.vectorindex = vectorIndex;
				
				if( pc_textBox.propObj ) {
					for( var nm:String in pc_textBox.propObj ) {
						obj[nm] = pc_textBox.propObj[nm];
					}
				}else{
					obj.name = InputTextBox.getUniqueName("file-");
					obj.sortid = 0;
					obj.uid = 0;
				}
				
				newname = TemplateTools.obj2Text ( pc_textBox.www_folder + CTOptions.urlSeparator + pc_textBox.rename_template, "#", obj );
				
			}else{
				newname = pc_textBox.www_folder + CTOptions.urlSeparator + newname;
			}
			
			CTTools.copyFile( pc_textBox.value, CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderMinified + CTOptions.urlSeparator + newname );
			CTTools.copyFile( pc_textBox.value,  CTTools.projectDir + CTOptions.urlSeparator + CTOptions.projectFolderRaw + CTOptions.urlSeparator + newname );
			
			// Rewrite textbox to new name
			pc_textBox.value = newname;
			pc_textBox.setType( pc_textBox.type );
		}
		
		
	}
}
