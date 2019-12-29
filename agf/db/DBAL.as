package agf.db
{
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.events.SQLEvent;
	
	public class DBAL extends EventDispatcher
	{
		public function DBAL() {}
		
		public static const DB_LOADED:String = "db_loaded";
		
	 	private var _db:DB = null;
		
		public function useDB (name:String, type:Class) :void {
			_db = new type();
			_db.addEventListener( DB_LOADED, onLoaded );
			_db.loadDB( name );
		}
		
		private function onLoaded (e:SQLEvent) :void{
			dispatchEvent(e);
		}
		public function getFilename () :String {
			return _db.getFilename();
		}
		public function selectQuery ( resultHandler:Function, select_fields:String, from_table:String, where_clause:String='', groupBy:String='', orderBy:String='', limit:String='', params:Object=null ) :Boolean { 
			return _db.selectQuery( resultHandler, select_fields, from_table, where_clause, groupBy, orderBy, limit, params );
		}
		public function insertQuery ( resultHandler:Function, table:String, fields:String, field_values:String, params:Object=null ) :Boolean { 
			return _db.insertQuery( resultHandler,table, fields, field_values, params );
		}
		public function updateQuery ( resultHandler:Function, table:String, where:String, field_values:String, params:Object=null ) :Boolean {
			return _db.updateQuery( resultHandler, table, where, field_values, params );
		}
		public function deleteQuery ( resultHandler:Function, table:String, where:String='', params:Object=null) :Boolean {
			return _db.deleteQuery( resultHandler, table, where, params );
		}
		public function query ( resultHandler:Function, sql:String, params:Object=null):Boolean { 
			return _db.query( resultHandler, sql, params);
		}
	 }
	
}

