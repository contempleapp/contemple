package agf.view
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import agf.html.CssSprite;
	import agf.html.CssStyleSheet;
	import agf.html.CssUtils;
	import agf.events.AppEvent;
	import agf.io.Resource;
	import agf.ui.Ctrl;
	import agf.ui.Panel;
	import agf.utils.StrVal;
	import agf.tools.Command;
	import agf.tools.Console;
	import agf.io.ResourceMgr;
	import agf.html.XmlUiRenderer;
	import agf.view.PanelType;
	
	/**
	* The view can be accessed with:
	*
	*  var view:ViewContainer = ViewContainer( Application.instance.view );
	*
	* The class object loaded into the view can be accessd with: 
	*
	*. var obj:DisplayObject = DisplayObject( Application.instance.view.panel.src );
	*
	* Set view name and class object in menu.xml. Then use this cmd to change the view:
	*
	* Application.instance.cmd( "Application view Name-Of-New-View" );
	*
	**/
	public class ViewContainer extends CssSprite
	{
		public function ViewContainer (w:Number=0, h:Number=0, body:CssSprite=null, style:CssStyleSheet=null) {
			super(w, h, body, style, 'viewcontainer', '', '', false);
		}
		
		private var _e_resize:Event;
		private var lres:Resource;
		private var currentViewNode:int = 0;
		
		/**
		* Set view node from xml configuration
		* @parameter name String (name of the view node) or integer id in the view-node-list
		*/
		public function setView ( name:Object ) :void
		{
			if( lres )
			{
				var ltvn:int = currentViewNode;
				
				// Get View Nodes from the XML
				var viewNodes:XMLList = new XML(String(lres.obj)).view;
				var L:int = viewNodes.length();
				
				if( isNaN( Number(name) ) ) 
				{
					// Search name attribute in xml list with all view nodes
					var nm:String = String(name);
					
					for(var i:int=0; i < L; i++) {
						if(viewNodes[i].@name == nm) {
							currentViewNode = i;
							break;
						}
					}
				}
				else
				{
					var id:int = int(name);
					
					if( id >= 0 && id < L ) {
						currentViewNode = id;
					}
				}
				
				// different setting
				if(ltvn !== currentViewNode)
				{
					dispatchEvent( new AppEvent( AppEvent.VIEW_CHANGE ) );
					parseXml();
					dispatchEvent( new AppEvent( AppEvent.VIEW_CHANGED ) );
					
				}
			}
		}
		
		/**
		 * 	
			<view name="Four Views" vm="viewmode" src="Class or XmlFile"/>
			<view name="Two Views" vm="viewmode2" src="Class or XmlFile"/>
		*
		*/
		public function parseXml (res:Resource=null) :void 
		{
			if(!res) 
			{
				// Use Last config file
				if(lres) res = lres;
				else return;
			}
			
			// Set current config file resource
			lres = res;
			
			// attribute string parser
			var strParse:Function = StrVal.getval;
			
			// Parse Xml File
			var x:XML = new XML(strParse(String(res.obj)));
			
			// Get current XML View node
			var n:XML = x.view[currentViewNode];
			
			// Clear panel
			if(panel) 
			{
				if(contains(panel)) removeChild(panel);
				panel = null;
			}
			
			panel = new Panel("panel", cssWidth, cssHeight, this, styleSheet, '', '');
			
			var src:* = "";
			
			if( n.@src != undefined ) src = strParse(n.@src);
			
			if(src) {
				if( typeof src == "string" ) {
					loadXml(src); // Load file with XmlUiRenderer
				}else{
					panel.setSrc( new src() ); // Instanciate 
				}
			}
			
			if( n.@viewmode != undefined ) {
				panel.viewType = n.@viewmode;
			}
		}
		
		private function sizePanel (p:CssSprite, it:CssSprite) :void
		{
			p.x = it.cssBorderLeft;
			p.y = it.cssBorderTop;
			
			p.cssWidth = it.cssWidth - (p.cssBorderLeft + p.cssBorderRight);
			p.cssHeight = it.cssHeight - (p.cssBorderTop + p.cssBorderBottom);
			
			p.redrawStyle();
		}
		
		public function resize (w:Number, h:Number) :void
		{
			if(panel)
			{
				sizePanel( panel, this );
				
				if ( !_e_resize ) _e_resize = new Event(Event.RESIZE);
				
				panel.dispatchEvent( _e_resize );
				
				init();
			}
		}
		
		public override function setWidth (w:int) :void {}
		public override function setHeight (h:int) :void {}
		
		// Load x(ht)ml resource into a panel
		public function loadXml (file:String) :void {
			var rm:ResourceMgr = ResourceMgr.getInstance();
			rm.loadResource( file, xmlLoaded );
		}
		public function xmlLoaded (res:Resource) :void {
			var xo:XML = XML( String(res.obj) );
			if( xo ) {
				var xr:XmlUiRenderer;
				if( panel.udfData.xmlRenderer ) {
					xr = XmlUiRenderer( panel.udfData.xmlRenderer );
					if(panel.contains(xr)) panel.removeChild( xr );
					panel.udfData.xmlRenderer = null;
				}
				
				xr = new XmlUiRenderer(panel.getWidth(), panel.getHeight(), panel, panel.styleSheet);
				panel.udfData.xmlRenderer = xr;
				xr.render( xo );
			}
		}
		
		public var panel:Panel;
		
	}
}

