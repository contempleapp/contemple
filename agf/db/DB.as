package agf.db
{
	import flash.events.EventDispatcher;
	
	public class DB extends EventDispatcher
	{
		public function DB() {}
		public static var logQuerys:Boolean = false;
		public function getFilename () :String {return '';}
		public function loadDB ( file:String ) :void {}
		public function selectQuery ( resultHandler:Function, select_fields:String, from_table:String, where_clause:String='', groupBy:String='', orderBy:String='', limit:String='',params:Object=null ) :Boolean { return false;}
		public function insertQuery ( resultHandler:Function, table:String, fields:String, field_values:String, params:Object=null ) :Boolean {return false;}
		public function updateQuery ( resultHandler:Function, table:String, were:String, field_values:String, params:Object=null ) :Boolean {return false;}
		public function deleteQuery ( resultHandler:Function, table:String, where:String='', params:Object=null) :Boolean {return false;}
		public function query ( resultHandler:Function, sql:String, params:Object=null):Boolean{ return false; }
	}
	
}
