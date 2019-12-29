package ct 
{
	public class EmbedFile
	{
		public function EmbedFile (_name:String, _src:String, _area:String) {
			name = _name;
			src = _src;
			area = _area;
		}
		
		public var name:String = "";
		public var src:String = "";
		public var area:String = "";
		public var priority:int = 0;
	}
	
}