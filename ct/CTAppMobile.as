package ct
{
	import agf.Options;
	import agf.tools.Console;
	import agf.html.CssStyleSheet;
	import agf.html.CssUtils;
	
	public class CTAppMobile extends CTApp 
	{
		public function CTAppMobile () 
		{	
			super();
			
			Options.iconDir = "ico24";
			CTOptions.appLogo = "ico24/logo.png";
			
			// Set default config options
			if( CssUtils.numericScale > 1 )
			{
				if( CssUtils.numericScale > 2.8 )
				{
					// 400 DPI
					Options.iconSize = 48;
					Options.btnSize = 96;
				}
				else if( CssUtils.numericScale > 2 )
				{
					// 300 DPI
					Options.iconSize = 36;
					Options.btnSize = 64;
				}
				else if( CssUtils.numericScale > 1.2 )
				{
					// 200 DPI
					Options.iconSize = 24;
					Options.btnSize = 48;
				}
			}
			
			CTOptions.isMobile = true;
			CTOptions.mobileProjectFolderName = "ask";
			
			//// to embed theme for testing use: app:/theme-demo
			//CTOptions.installTemplate = "app:/theme-demo";
			CTOptions.installTemplate = "";
			
			/*
			Console.log( "NumScale: " + CssUtils.numericScale );
			Console.log( "IconSize: " + Options.iconSize);
			Console.log( "BtnSize: " + Options.btnSize);
			
			Console.log( "ScaleFonts: " + CssStyleSheet.scaleFonts);
			Console.log( "FontScale: " + CssStyleSheet.fontSizeScale);
			*/
		
			CTOptions.mobileWheelMove = 12 * CssUtils.numericScale;
			CTOptions.previewAtBottom = true;
			
			TemplateTools.editor_w = HtmlEditor.tmpEditorW = 1;
			TemplateTools.editor_h = HtmlEditor.tmpEditorH = 0.6;
			
		}
	}
}
