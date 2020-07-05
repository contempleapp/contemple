package agf.utils
{
	public class FileInfo
	{
		public function FileInfo () {}
		
		public var path:String="";
		public var name:String="";
		public var type:String="";
		public var directory:String="";
		public var extension:String="";
		public var filename:String="";
		public var separator:String="";
		
		public function clone () :FileInfo
		{
			var fi:FileInfo = new FileInfo();
			
			fi.path = path;
			fi.name = name;
			fi.type = type;
			fi.directory = directory;
			fi.extension = extension;
			fi.filename = filename;
			fi.separator = separator;
			
			return fi;
		}
	}
}
