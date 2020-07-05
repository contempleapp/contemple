package ct.ctrl {
	
	public class ItemForm {

		public function ItemForm (_area:String="", _updateItem:Object=null, _areaItems:Array=null) {
			area = _area;
			updateItem = _updateItem;
			areaItems = _areaItems;
		}
		
		public var area:String;
		public var updateItem:Object;
		public var areaItems:Array;
		public var initValues:Object={};
		public var saveValues:Object={};
		

	}
	
}
