package ct
{
	import agf.ui.*;
	import agf.html.*;
	import agf.events.*;
	import agf.icons.IconArrowDown;
	import agf.Main;
	import agf.tools.Application;
	import flash.display.*;
	import flash.events.*;
	
	// Accessible in static HtmlEditor.editor
	public class TemplateEditor extends CssSprite
	{
		public function TemplateEditor(w:Number=0, h:Number=0, parentCS:CssSprite=null, style:CssStyleSheet=null, name:String='', id:String="", classes:String="", noInit:Boolean=false) {
			super(w,h,parentCS,style,name,id,classes,noInit);
			_w = w;
			create();
		}
		public var currentEditor:CssSprite;
		public var mode_label:Label;
		private var _w:int;
		private var _h:int;
		
		public function create () :void {
			if( CTTools.projectDir && CTTools.procFiles ) {
				showSection( Language.getKeyword("Content") );
			}
		}
		
		public static function get clickScrolling () :Boolean {
			var currentEditor:CssSprite;
			if( Application.instance.view.panel.src is HtmlEditor &&  HtmlEditor(Application.instance.view.panel.src).editor ) {
				currentEditor = HtmlEditor(Application.instance.view.panel.src).editor.currentEditor;
			}
			if ( currentEditor ) {
				if ( currentEditor is AreaEditor ) {
					return AreaEditor.clickScrolling;
				}else if ( currentEditor is ConstantsEditor ) {
					return ConstantsEditor.clickScrolling;
				}else if ( currentEditor is MediaEditor ) {
					return MediaEditor.clickScrolling;
				}else if ( currentEditor is PageEditor ) {
					return PageEditor.clickScrolling;
				}
			}else{
				if( Application.instance.view.panel.src is BaseScreen ) {
					return BaseScreen.clickScrolling;
				}
			}
			return false;
		}
		public static function abortClickScrolling () :void { 
			var currentEditor:CssSprite;
			if( Application.instance.view.panel.src is HtmlEditor && HtmlEditor(Application.instance.view.panel.src).editor ) {
				currentEditor = HtmlEditor(Application.instance.view.panel.src).editor.currentEditor;
			}
			if ( currentEditor ) {
				if ( currentEditor is AreaEditor ) {
					AreaEditor( currentEditor ).abortClickScrolling();
				}else if ( currentEditor is ConstantsEditor ) {
					ConstantsEditor( currentEditor ).abortClickScrolling();
				}else if ( currentEditor is MediaEditor ) {
					MediaEditor( currentEditor ).abortClickScrolling();
				}else if ( currentEditor is PageEditor ) {
					PageEditor( currentEditor ).abortClickScrolling();
				
				}
			}else{
				if( Application.instance.view.panel.src is BaseScreen ) {
					BaseScreen( Application.instance.view.panel.src ).abortClickScrolling();
				}
			}
		}
		
		public static function endClickScrolling () :void {
			var currentEditor:CssSprite;
			if( Application.instance.view.panel.src is HtmlEditor &&  HtmlEditor(Application.instance.view.panel.src).editor ) {
				currentEditor = HtmlEditor(Application.instance.view.panel.src).editor.currentEditor;
			}
			if ( currentEditor ) {
				if ( currentEditor is AreaEditor ) {
					AreaEditor.clickScrolling = false;
				}else if ( currentEditor is ConstantsEditor ) {
					ConstantsEditor.clickScrolling = false;
				}else if ( currentEditor is MediaEditor ) {
					MediaEditor.clickScrolling = false;
				}else if ( currentEditor is PageEditor ) {
					PageEditor.clickScrolling = false;
				}
			}
		}
		
		public static function startClickScrolling () :void {
			var currentEditor:CssSprite;
			if( Application.instance.view.panel.src is HtmlEditor &&  HtmlEditor(Application.instance.view.panel.src).editor ) {
				currentEditor = HtmlEditor(Application.instance.view.panel.src).editor.currentEditor;
			}
			if ( currentEditor ) {
				if ( currentEditor is AreaEditor ) {
					AreaEditor.clickScrolling = true;
				}else if ( currentEditor is ConstantsEditor ) {
					ConstantsEditor.clickScrolling = true;
				}else if ( currentEditor is MediaEditor ) {
					MediaEditor.clickScrolling = true;
				}else if ( currentEditor is PageEditor ) {
					PageEditor.clickScrolling = true;
				
				}
			}else{
				if( Application.instance.view.panel.src is BaseScreen ) {
					BaseScreen.clickScrolling = true;
				}
			}
		}
		
		public override function setWidth( w:int) :void {
			super.setWidth(w);
			_w = w;
			if( currentEditor ) currentEditor.setWidth( w );
		}
		public override function setHeight ( h:int ) :void {
			super.setHeight(h);
			_h = h;
			if( currentEditor ) currentEditor.setHeight( h - cssBoxY );
		}
		
		private static var fixAreaED:AreaEditor = null;
		
		public function showSection (lb:String="") :void
		{
			if( currentEditor ) {
				if(contains(currentEditor)) removeChild(currentEditor);
			}
			
			if( CTTools.procFiles && CTTools.activeTemplate ) {
				if( lb == Language.getKeyword("Template") || lb == Language.getKeyword("Options") ) {
					currentEditor = new ConstantsEditor( _w-8, getHeight(), this, styleSheet, '', '', 'constant-editor',false);
					var cte1:ConstantsEditor = ConstantsEditor( currentEditor );
					cte1.displayTemplateProps( CTTools.activeTemplate, ConstantsEditor.currCat, 0, 2 );
					cte1.y = cssTop;
				}else if( lb == Language.getKeyword("Pages") ) {
					currentEditor = new PageEditor( _w-8, getHeight(), this, styleSheet, '', '', 'page-editor',false);
					var ped:PageEditor = PageEditor ( currentEditor );
					currentEditor.y = currentEditor.cssTop;
				}else if( lb == Language.getKeyword("Area") || lb == Language.getKeyword("Content") ) {
					
					if( fixAreaED == null ) {
						fixAreaED = new AreaEditor( _w-8, getHeight(), this, styleSheet, '', '', 'area-editor',false);
					}else{
						addChild( fixAreaED );
						fixAreaED.createAed();
					}
					currentEditor = fixAreaED;
					var aed:AreaEditor = AreaEditor ( currentEditor );
					currentEditor.y = currentEditor.cssTop;
				}else if( lb == Language.getKeyword("Media") ){
					currentEditor = new MediaEditor( _w-8, getHeight(), this, styleSheet, '', '', 'media-editor',false);
					var meded:MediaEditor = MediaEditor ( currentEditor );
					meded.showMediaItems("", 2);
					currentEditor.y = currentEditor.cssTop;
				}
				else{
					// show subtemplate fields.. currently unused..
					currentEditor = new ConstantsEditor( _w-8, getHeight(), this, styleSheet, '', '', 'constant-editor',false);
					var cte:ConstantsEditor = ConstantsEditor( currentEditor );
					cte.y = cssTop;
					var tmpl:Template = CTTools.findTemplate( lb, "name" );
					cte.displayTemplateProps( tmpl );
				}
				setHeight( _h );
				setWidth( _w );
			}
		}
	}
}
