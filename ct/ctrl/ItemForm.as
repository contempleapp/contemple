package ct.ctrl
{	
	public class ItemForm
	{
		public function ItemForm (_area:String="", _updateItem:Object=null, _areaItems:Array=null, _cat:String="") {
			area = _area;
			updateItem = _updateItem;
			areaItems = _areaItems;
			cat = _cat;
		}
		
		public var area:String;
		public var cat:String;
		public var updateItem:Object;
		public var areaItems:Array;
		public var initValues:Object={};
		public var saveValues:Object={};
	}
}
