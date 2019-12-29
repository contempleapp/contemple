package agf.db
{
	public class DBResult
	{
		public function DBResult() {}
		
		public var complete:Boolean=false;	
		public var data:Array;
		public var rowsAffected:Number=0;
		public var lastInsertRowID:Number=0;
	}
	
}
