package ct
{
	import agf.Options;
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
				if( CssUtils.numericScale > 3.5 )
				{
					// 400 DPI
					Options.iconSize = 48;
					Options.btnSize = 96;
				}
				else if( CssUtils.numericScale > 2.5 )
				{
					// 300 DPI
					Options.iconSize = 48;
					Options.btnSize = 96;
				}
				else if( CssUtils.numericScale > 1.25 )
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
			
			CTOptions.previewAtBottom = true;
			
			TemplateTools.editor_w = HtmlEditor.tmpEditorW = 1;
			TemplateTools.editor_h = HtmlEditor.tmpEditorH = 0.6;
			
			
			
		}
	}
}
