package agf.db
{
	import flash.data.*;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.events.Event;
	
	import agf.tools.Console;
	import flash.events.SQLErrorEvent;
	
	public class SqliteDB extends DB
	{
		public function SqliteDB () {}
		
		private var _name:String  = "";
		private var conn:SQLConnection;
		private var stat:SQLStatement;
		private var dbloaded:Boolean=false;
		private var sql_exec:Boolean = false;
		private var exec_handler:Function;
		
		private var res:DBResult = new DBResult();
		
		public override function getFilename () :String {
			return _name;
		}
		
		// open or create db
		public override function loadDB ( file:String ) :void {
			_name = file;
			conn = new SQLConnection();
			conn.addEventListener(SQLEvent.OPEN, connOpenHandler);
			var dbFile:File = new File( file );
			conn.openAsync(dbFile, SQLMode.CREATE);
		}
		
		private function connOpenHandler(event:SQLEvent) :void{
			dbloaded = true;
			dispatchEvent( new SQLEvent( DBAL.DB_LOADED, false, true ) );
		}

		protected function sqlErrorHandler(event:SQLErrorEvent) :void{
			Console.log("SQL ERROR (handler): " + event.error );
			if( exec_handler != null ) {
				exec_handler( null );
			}
		}
		
		protected function sqlResultHandler(event:SQLEvent) :void{
			sql_exec = false;
			if( exec_handler != null ) {
				var result:SQLResult = stat.getResult();
				res.complete = result.complete;
				res.data = result.data;
				res.rowsAffected = result.rowsAffected;
				res.lastInsertRowID = result.lastInsertRowID;
				
				exec_handler( res );
				if ( pendingQuerys && pendingQuerys.length > 0 ) {
					var obj:Object = pendingQuerys.pop();
					if ( pendingQuerys.length < 1) pendingQuerys = null;
					query( obj.resultHandler, obj.sql, obj.params );
				}
			}
		}
		private var pendingQuerys:Array;
		
		public override function query ( resultHandler:Function, sql:String, params:Object=null ) :Boolean { 
			
			if( sql_exec && stat && !stat.executing ) sql_exec = false;
			
			if( !sql_exec && conn && dbloaded ) 
			{
				if( DB.logQuerys ) Console.log ( "DB: " + sql );
			
				exec_handler = resultHandler;
				
				if( !stat ) {
					stat = new SQLStatement();
					stat.sqlConnection = conn;
					stat.addEventListener(SQLEvent.RESULT, sqlResultHandler);
					stat.addEventListener(SQLErrorEvent.ERROR, sqlErrorHandler);
				}
				stat.text = sql;
				stat.clearParameters();
				try {
					
					if( params ) {
						for( var nam:String in params ) {
							stat.parameters[nam] = params[nam];
						}
					}
					
					stat.execute();
					sql_exec = true;
					return true;
				}catch(e:Error) {
					Console.log("DB-ERROR in Query: " + e.message);
					return false;
				}
			}
			else
			{
				if ( !pendingQuerys ) pendingQuerys = [];
				pendingQuerys.push( { sql:sql, params: params, resultHandler:resultHandler } );
			}
			return true;
		}
		
		public override function selectQuery (resultHandler:Function, select_fields:String, from_table:String, where_clause:String='', groupBy:String='', orderBy:String='' , limit:String='', params:Object=null) :Boolean { 
			if( !sql_exec && conn && dbloaded ) 
			{
				var sql:String =  "SELECT " + select_fields + " FROM "+from_table + " WHERE " + where_clause + " " + groupBy + " " + orderBy + " " + limit;
				return query( resultHandler, sql, params );
			}
			return false;
		}
		
		public override function insertQuery ( resultHandler:Function, table:String, fields:String, field_values:String, params:Object=null ) :Boolean { 
			if( conn  && dbloaded) {
				var sql:String =  "INSERT INTO " + table + " ("+ fields + ") VALUES("+ field_values + ");";
				return query( resultHandler, sql, params );
			}
			return false;
		}
		public override function updateQuery ( resultHandler:Function, table:String, where:String, field_values:String, params:Object=null ) :Boolean {
			if( conn  && dbloaded) {
				var sql:String =  "UPDATE " + table + " SET " + field_values + " WHERE "+ where;
				return query( resultHandler, sql, params );
			}
			return false;
		}
		public override function deleteQuery (resultHandler:Function, table:String, where:String='', params:Object=null) :Boolean {
			if( conn && dbloaded) {
				var sql:String =  "DELETE FROM " + table + " WHERE "+ where;
				return query( resultHandler, sql, params );
			}
			return false;
		}
	 }
	
}

