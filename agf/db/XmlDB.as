package agf.db
{
	import agf.io.Resource;
	import flash.events.Event;
	import agf.html.CompactCode;
	import agf.html.CssUtils;
	
	/**
	* Work in Progress..
	* TODO:
	* Implement UPDATE DELETE actions
	*/
	public class XmlDB extends DB
	{
		public function XmlDB () {}
		
		private var res:Resource;
	 	private var _db:XML = null;
		private var _name:String  = "";
		private var result:DBResult = new DBResult();
		private var exec_handler:Function;
		
		// open or create db
		public override function loadDB ( file:String ) :void
		{
			_name = file;
			if( res ) {
				res = null;
			}
			res = new Resource();
			res.load( file, true, xmlLoaded);
		}
		
		public override function getFilename () :String {
			return _name;
		}
		
		private function xmlLoaded ( e:Event, res:Resource ) :void
		{
			if( res  ) {
				_db = new XML( String(res.obj) );
				trace("DB LOADED: " + String(res.obj) );
				dispatchEvent( new Event( DBAL.DB_LOADED ) );
			}
		}
		
		/*
		* @param	string		List of fields to select from the table. This is what comes right after "SELECT ...". Required value.
		* @param	string		Table(s) from which to select. This is what comes right after "FROM ...". Required value.
		* @param	string		additional WHERE clauses put in the end of the query. NOTICE: You must escape values in this argument with $this->fullQuoteStr() yourself! DO NOT PUT IN GROUP BY, ORDER BY or LIMIT!
		* @param	string		Optional GROUP BY field(s), if none, supply blank string.
		* @param	string		Optional ORDER BY field(s), if none, supply blank string.
		* @param	string		Optional LIMIT value ([begin,]max), if none, supply blank string.
		* @return	pointer		MySQL result pointer / DBAL object
		*/
		
		public override function selectQuery (resultHandler:Function, select_fields:String, from_table:String, where_clause:String='', groupBy:String='', orderBy:String='' , limit:String='', params:Object=null) :Boolean { 
			
		//public override function selectQuery ( resultHandler:Function, select_fields:String, from_table:String, where_clause:String='', groupBy:String='', orderBy:String='', limit:String='') :Boolean { 
			if( _db ) 
			{
				// Build query: SELECT fields.join( , ) FROM table.join( , ) WHERE clause GROUP BY groupBy ORDER BY orderBy LIMIT limit
				// var res:DBResult = new DBResult();
				
				// SELECT spalte1, tbl.spalteX, tmp as tbl2.spalte3, tbl3.* ... FROM ... oder NULL: SELCT FROM tbl... (*)
				/*
				var distinct:Boolean = false;
				var distinctRow:Boolean = false;
				
				var p1:int;
				var p2:int;
				
				if( p1 = select_fields.indexOf("DISTINCT") ) {
					distinct = true;
					if( p2 = select_field.indexOf("DISTINCT-ROW") >= 0 ) {
						distinctRow = true;
						select_fields = select_field.substring( 12 );
					}
				}
				
				var fields:Array = select_field.split(",");
				var tbls:Array = from_table.split(",");  // Join tables
				var currTabl:XMLList;
				
				var i:int;
				var j:int;
				var L:int = tbls.length;
				
				var fi:int;
				var fL:int = fields.length;
				
				
				
				for( i=0; i<L; i++)
				{
					// Select table:
					currTabl = _db[ tbls[i] ];
				
					for( j=0; j < fL; j++) {
						
						
					}
				}
				*/
				
				return true;
			}
			return false;
		}
		
		/* 
		* @param	string		Table name
		* @param	array		Field values as key=>value pairs. Values will be escaped internally. Typically you would fill an array like "$insertFields" with 'fieldname'=>'value' and pass it to this function as argument.
		* @param	string/array		See fullQuoteArray()
		* @return	pointer		MySQL result pointer / DBAL object
		*/

		public override function insertQuery ( resultHandler:Function, table:String, fields:String, field_values:String, params:Object=null ) :Boolean { 
			if( _db ) {
				//var res:DBResult = new DBResult();
				return true;
			}
			return false;
		}
		
		/* @param	string		Database tablename
		* @param	string		WHERE clause, eg. "uid=1". NOTICE: You must escape values in this argument with $this->fullQuoteStr() yourself!
		* @param	array		Field values as key=>value pairs. Values will be escaped internally. Typically you would fill an array like "$updateFields" with 'fieldname'=>'value' and pass it to this function as argument.
		* @param	string/array		See fullQuoteArray()
		* @return	pointer		MySQL result pointer / DBAL object
		*/
		public override function updateQuery ( resultHandler:Function, table:String, where:String, field_values:String, params:Object=null ) :Boolean {
			if( _db ) {
				//var res:DBResult = new DBResult();
				return true;
			}
			return false;
		}
		
		/*
		* @param	string		Database tablename
		* @param	string		WHERE clause, eg. "uid=1". NOTICE: You must escape values in this argument with $this->fullQuoteStr() yourself!
		* @return	pointer		MySQL result pointer / DBAL object
		*/
		public override function deleteQuery (resultHandler:Function, table:String, where:String='', params:Object=null) :Boolean {
			if( _db ) {
				//var res:DBResult = new DBResult();
				return true;
			}
			return false;
		}
		private function trim (s:String) :String {
			return CssUtils.trimQuotes( CssUtils.trim(s) );
		}
		public override function query ( resultHandler:Function, sql:String, params:Object=null):Boolean
		{
			// "SELECT " + select_fields + " FROM "+from_table + " WHERE " + where_clause + " " + groupBy + " " + orderBy + " " + limit;
			// "INSERT INTO " + table + " ("+ fields + ") VALUES("+ field_values + ");";
			// "UPDATE " + table + " SET " + field_values + " WHERE "+ where;
			// "DELETE FROM " + table + " WHERE " + where;
			// CREATE TABLE IF NOT EXISTS file (uid INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT);
			
			sql = agf.html.CompactCode.compactSql(sql);
			
			trace("XMLDB Query: " + sql);
			
			var L:int = sql.length;
			var L2:int;
			var cc:int;
			var tmparr:Array;
			var j:int;
			var nam:String;
			var sql_ac:String=""; // SELECT, INSERT, UPDATE, DELETE, CREATE
			var i:int;
			var st:int;
			var en:int;
			var tmp:String;
			var key:Array;
			var tblName:String;
			var atbs:XMLList;
			var values:Array;
			var xmlnode:String;
			
			var sql_lc:String  =  sql.toLowerCase();
			
			for( i=0; i<L; i++) {
				cc = sql.charCodeAt(i);
				if( cc <= 32 ) {
					sql_ac = sql_lc.substring(0, i);
					break;
				}
			}
			if( sql_ac == "" ) {
				throw new Error("XmlDB SQL Error at " + sql);
				return false;
			}
			exec_handler = resultHandler;
			
			if( sql_ac == "select") {
				var from:int = sql_lc.indexOf("from", i);
				if( from == -1 ) {
					throw new Error("XmlDB SQL Error missing FROM clause at " + sql);
					return false;
				}
				
				var w:int = sql_lc.indexOf("where", i);
				var g:int = sql_lc.indexOf("group by", i);
				var o:int = sql_lc.indexOf("order by", i);
				var l:int = sql_lc.indexOf("limit", i);
				
				var list:Array = [{ac:"from",c:from}];
				
				if( w >= 0 )  list.push({ac:"where", c:w});
				if( g >= 0 )  list.push({ac:"group_by", c:g});
				if( o >= 0 )  list.push({ac:"order_by", c:o});
				if( l >= 0 )  list.push({ac:"limit", c:l});
				
				list.sortOn("c", Array.NUMERIC);
				
				var args:String;
				en = list[0].c - 1;
				st = sql_ac.length+1;
				
				// Select args
				var selObj:Object = { 
					select: sql.substring( st, en ),
					from:"", where:"", group_by:"", order_by:"", limit:""
				};
				
				for(i=0; i<list.length; i++) {
					st = list[i].ac.length + list[i].c + 1;
					en = i == list.length-1 ? sql.length : list[i+1].c-1;
					args = sql.substring( st, en );
					selObj[ list[i].ac ] = args;
				}
				
				trace("Select: '" + selObj.select + "', From: '" + selObj.from + "', Where: '" + selObj.where 
					+ "', limit: '" + selObj.limit+"', Group By: '"+selObj.group_by +"', Order By: '"+selObj.order_by+"'");
				
				var tables:Object = {};
				var fields:Object = {};
				var where:Object = {};
				var testWhere:Boolean=false;
				
				var keyval:Array;
				var limit:Number=0;
				var offset:Number=0;
				
				if( selObj.limit.indexOf(",") ) {
					tmparr = selObj.limit.split(",");
					if( tmparr.length == 0 ) {
					}else if( tmparr.length == 1 ) {
					}else if( tmparr.length == 2 ) {
						offset = Number(trim(tmparr[0]));
						limit = Number(trim(tmparr[1]));
					}
				}else{
					limit = Number( selObj.limit );
					offset = 0;
				}
				
				trace("Offset: " + offset + ", Limit: " + limit);
				
				
				if( selObj.from.indexOf(",") >= 0 ) {
					tmparr = selObj.from.split(",");
					trace("From1: " + tmparr);
					
					for(j=0; j<tmparr.length; j++) {
						tables[ trim(tmparr[j]) ] = true;
						
					}
				}else{
					
					trace("From2: " + selObj.from);
					tables[ trim(selObj.from)] = true;
				}
				
				
				if( selObj.select == "*" ) {
					for( nam in tables ) {
						atbs = _db[ nam ].attributes();
						L2 = atbs.length();
						for(j=0; j<L2; j++) {
							fields[ atbs[j].name().toString() ] = true;
							trace("Field1: " + atbs[j].name().toString()  );
						}
					}
				}
				else if( selObj.select.indexOf(",") >= 0) {
					tmparr = selObj.select.split(",");
					for(j=0; j<tmparr.length; j++) {
						fields[ trim( tmparr[j] ) ] = true;
						trace("Field2: " + tmparr[j] );
					}
				}else{
					
					trace("Fields: " + selObj.from );
					fields[ trim(selObj.from) ] = true;					
				}
				
				if( selObj.where.indexOf("AND") == -1 ) {
					tmparr = [selObj.where];
				}else{
					tmparr = selObj.where.split(" AND ");
				}
				
				for(j=0; j<tmparr.length; j++) {
					keyval = CssUtils.trim( tmparr[j] ).split("=");
					if( keyval.length == 0 ) {
					}else if( keyval.length == 1) {
					}else if( keyval.length == 2) {
						where[ trim(keyval[0]) ] = trim(keyval[1]);
						trace("Where : " + keyval[0] + ": " + keyval[1] );
						
						testWhere=true;
					}
				}
				
				var data:Array = [];
				var xl:XMLList;
				var kv:String;
				var L3:int;
				var k:int;
				var r:Object;
				
				if(testWhere) {
					for( var tbl:String in tables ) {
						xl = _db[tbl].c;
						trace("Table1:" + xl);
						
						for( kv in where ) {
							xl = xl.(@[kv] == params[where[kv]] );
							if( xl.length() == 0 ) break;
						}
					}
					L3 = xl.length();
					if(  offset < L3 ) {
						for(k=offset; k<L3; k++) {
							r = {};
							for( nam in fields ) {
								r[nam] = xl[k].@[nam];
							}
							data.push(r);
							if(data.length >= offset + limit) break;
						}
					}
				}else{
					for( var tbl:String in tables ) {
						xl = _db[tbl].c;
						trace("Table2: " + xl );
						L3 = xl.length();
						if( offset < L3 ) {
							for(k=offset; k<L3; k++) {
								r = {};
								for( nam in fields ) {
									r[nam] = xl[k].@[nam];
								}
								data.push(r);
								if(data.length >= offset+limit) break;
							}
						}
					}
				}
				
				// sort data 
				if( selObj.order_by != "") {
					if( selObj.order_by.indexOf(",") ) {
						tmparr = selObj.order_by.split(",");
						for(k=tmparr.length-1; k>=0; k--) data.sortOn( trim(tmparr[k]), Array.NUMERIC );
					}else{
						data.sortOn( selObj.order_by, Array.NUMERIC );
					}
				}
				
				result.data = data;
				result.lastInsertRowID = 0;
				result.rowsAffected = data.length;
				result.complete = true;
				
				if( exec_handler != null ) exec_handler( result );
				
				return true;
				
			} else if( sql_ac == "create") {
				st = sql.indexOf("(");
				en = sql.indexOf(")");
				
				if( st == -1 || en == -1 ) {
					throw new Error("XmlDB SQL Error at " + sql);
					return true;
				}
				
				tmp = sql.substring(0, st);
				key = tmp.split(" ");
				
				for( i=key.length-1; i>=0; i--) {
					key[i] = trim(key[i]);
					if(key[i] == "") key.splice(i,1);
				}
				
				tblName = key[ key.length-1 ];
				trace("CREATE: " + tblName);
				
				if( tmp.toLowerCase().indexOf("if not exists") >= 0 ) {
					if( _db[tblName] != undefined ) {
						
						trace("Table already exists: " + tblName);
						return false;
					}
				}
				
				xmlnode = "<" + tblName + " ";
				//var firstNode:String = "<c ";
				values = sql.substring( st+1, en ).split(",");
				L2 = values.length;
				var str1:String;
				var str2:String;
				
				trace("Values: " + values);
				
				for(i=0; i<L2; i++) {
					nam = values[i];
					cc = nam.indexOf(" ");
					if ( cc >= 0 ) {
						
						str1 = nam.substring( 0, cc );
						str2 = nam.substring(cc+1);
						
						xmlnode += str1 + '="'+ str2 +'" ';;
						
					}else{
						// use test type
						str1 = nam.substring( 0, cc ) + '="TEXT" ';
						xmlnode += str1;
						//firstNode += str1;
					}
				}
				xmlnode += '/>';
				
				if( _db[tblName] != undefined ) delete _db[tblName];
				
				_db.appendChild( new XML( xmlnode ) );
				
				return true;
				//trace("New DB: " + _db);
			
			}else if( sql_ac == "insert") {
				
				st = sql.indexOf("(");
				en = sql.indexOf(")");
				
				if( st == -1 || en == -1 ) {
					throw new Error("XmlDB SQL Error at " + sql);
					return false;
				}
				
				tmp = sql.substring(0, st);
				key = tmp.split(" ");
				
				for( i=key.length-1; i>=0; i--) {
					key[i] = CssUtils.trim(key[i]);
					if(key[i] == "") key.splice(i,1);
				}
				
				tblName = key[ key.length-1 ];
				trace("INSERT INTO: " + tblName);
				
				// auto values
				xmlnode = '<c ';
				
				var defAtb:Object= {};
				
				atbs = _db[ tblName ].attributes();
				L2 = atbs.length();
				for(j=0; j<L2; j++) {
					nam = _db[ tblName ].@[atbs[j].name().toString()].toString().toLowerCase();
					if( nam.indexOf("autoincrement") >= 0 ) {
						xmlnode += atbs[j].name().toString() +'="'+ (_db[tblName].children().length()+1) +'" ' ;
					}
				}
			
			
				values = sql.substring( st+1, en ).split(",");
				L2 = values.length;
				
				st = sql.indexOf("(", en);
				en = sql.indexOf(")", st);
				
				var val:Array = sql.substring(st+1,en).split(",");
				var p:Object;
				
				for(i=0; i<L2; i++) {
					p = params[ trim(val[i]) ];
					if(!p) p="";
					nam = trim(values[i]);
					if( defAtb[nam] == undefined ) {
						xmlnode += nam + '="'+ p+'" ';
					}
				}
				
				xmlnode += '/>';
				
				_db[tblName].appendChild( new XML( xmlnode) );
				
				trace( "Inserted: " + _db);
				return true;
			}else if( sql_ac == "update") {
				
			}else if( sql_ac == "delete") {
				var from:int = sql_lc.indexOf("from", i);
				if( from == -1 ) {
					throw new Error("XmlDB SQL Error missing FROM clause at " + sql);
					return false;
				}
				var w:int = sql_lc.indexOf("where", i);
				/*
				for( var tbl:String in tables ) {
					xl = _db[tbl].c;
					for( kv in where ) {
						xl = xl.(@[kv] == params[where[kv]] );
						if( xl.length() == 0 ) break;
					}
				}
				L3 = xl.length();
				if(  offset < L3 ) {
					for(k=offset; k<L3; k++) {
						r = {};
						for( nam in fields ) {
							r[nam] = xl[k].@[nam];
						}
						data.push(r);
						if(data.length >= offset + limit) break;
					}
				}*/
			}
			
			return false;
		}
	 }
	
}

