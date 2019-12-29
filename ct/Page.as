package ct
{
	public class Page
	{
		public function Page (_name:String, _uid:int, _type:String, _title:String, _template:String, _crdate:String="", _visible:Boolean=true, _parent:String="", _webdir:String="", _filename:String="")
		{
			name = _name;
			uid = _uid;
			type = _type;
			title = _title;
			visible = _visible;
			template = _template;
			crdate = _crdate;
			visible = _visible;
			parent = _parent;
			webdir = _webdir;
			filename = _filename;
		}
		
		public var name:String;
		public var uid:int;
		public var type:String;
		public var title:String;
		public var template:String;
		public var webdir:String;
		public var parent:String;
		public var crdate:String;
		public var filename:String;
		public var visible:Boolean;
	}
}
