package ct
{
	public class Area
	{
		//
		// Template Areas can be used anywere in the template files to define space for database items (list)
		// The items allowed inside the area can be restricted with the area-types
		// 
		//    AREA-NAME([icon:String=""],[options:String=""],[offset:int=0],[limit:int=-1],[link:String=""],[orig-st-name-1],[[linked-overwrite-st-name-1],[orig-st-name-2],[linked-overwrite-st-name-2]..]):area-types
		//
		// Area arguments can be set optional: icon:String, description:String, offset:int, limit:int, link:String, orig-sub-template1, new-sub-stemplate1, orig-substemple2, new-subtemplate2..
		//
		// Examples:
		// {##MENU:menu}
		// {##HOME("ct-icons/user.png",0, -1, "Home Page Content")}
		// {##FEATURED-HOME("ct-icons/falcon.png","Featured Home Page Content",3,2,"HOME","Text","Featured-Text-Template")}
		//
		// The same Area code can be used multiple times in the template to create duplicated content.
		//
		// Sections and priorities can be set to order Areas and Folders in the User Interface. The number before the Name controls the priority of the Folder/Area:
		// {##100.FOOTER:content}
		// {##10.HEADER:content}
		//
		// With the path separater character (.), the area can be in a folder in the user interface.
		// A priority number can be set before a section, or the area for sorting in user interface.
		// {##Products.IAMGE-CONTAINER:content}
		// {##10.Foldernam2.100.FOOTER:content}
		// {##10.Foldernam2.10.HEADER:content}
		// {##Products.Computers.500.Mices:products,sellout,sidebar}
		//
		// Example a onepage website uses these areas for page-items in the root template: 
		// The sidebar requires special items so it has a special type allowing subtemplates of type sidebar only
		// The type of the subtemplates (set in the ti.xml of the subtemplate) have to match the area type.
		// Multiple types can be set in subtemplates and areas.
		//
		// {##CONTENT:page}
		// {##CONTENT-CONTACT:content}
		// {##SIDEBAR1:content,sidebar}
		// {##SIDEBAR2:page,sidebar}
		// {##AUDIO-PLAYER:audio}
		//
		public function Area (_st:int=0, _en:int=0, _sections:Array=null, _priority:int=0, _name:String="", _type:String="", _types:Vector.<String>=null, _args:Array=null, _argv:String="")
		{
			st = _st;
			en = _en;
			sections = _sections;
			priority = _priority;
			name = _name;
			type = _type;
			types = _types;
			argv = _argv;
			
			if( _args != null) {
				args = _args;
				if( _args.length > 0) {
					icon = CTTools.parseFilePath( _args[0] );
				}
				if( _args.length > 1 ) {
					options = _args[1];
				}
				
				if( _args.length > 2 ) {
					offset = int(_args[2]);
				}
				if( _args.length > 3 ) {
					limit = int(_args[3]);
				}
				if( _args.length > 4 ) {
					link = _args[4];
				}
				if( _args.length > 6 )
				{
					linkOverrides = {};
					var L:int = _args.length;
					
					for( var i:int=5; i<L; i+=2)
					{
						if( i+1 < L ) {
							linkOverrides[ _args[i] ] = _args[i+1];
						}
					}
				}
			}
		}
		
		public var name:String;
		public var st:int;
		public var en:int;
		public var sections:Array;
		public var priority:int;
		public var type:String;
		public var types:Vector.<String>;
		public var args:Array;
		public var argv:String;
		public var icon:String="";
		public var options:String = "";
		public var link:String=""; // Use Page Items of another Area
		public var limit:int=0; // limit page items in area..
		public var offset:int=0; // start offset in page item list
		public var linkOverrides = null; // override sub template name in link areas ( linkOverrides[ orig-name ] = new-name )
	}
}