package ct
{
	public class CTCompareContent
	{
		public function CTCompareContent() {}
		
		// Compare two Content XML Files
		// Compare tmpl, prop, item and page nodes with attributes in root node only
		// return patch statements with insert, update and delete nodes as xml
		
		public static function compare ( newVersion:String, oldVersion:String ) :String {
			var oldXML:XML;
			var newXML:XML;
			try {
				newXML = new XML( newVersion );
				oldXML = new XML( oldVersion );
			}catch(e:Error){
				// Console.log( "Error comparing XML Content Files: " + e);
				return "";
			}
			return compareXML( newXML, oldXML );
		}
		
		public static function compareXML ( newVersion:XML, oldVersion:XML ) :String {
			var statements:String = '<?xml version="1.0" encoding="utf-8"?>\n<ct>\n';
			if( newVersion && oldVersion ) {
				statements += compareNodes( "tmpl", newVersion, oldVersion );
				statements += compareNodes( "prop", newVersion, oldVersion );
				statements += compareNodes( "item", newVersion, oldVersion );
				statements += compareNodes( "page", newVersion, oldVersion );
			}
			statements += "</ct>\n";
			return statements;
		}
		
		public static function compareNodes ( nodeName:String, newVersion:XML, oldVersion:XML ) :String
		{
			var statements:String = '';
			var i:int;
			var L:int;
			var j:int;
			var L2:int;
			var oldList:XMLList;
			var newList:XMLList;
			var n:String;
			var x:XMLList;
			var atbNew:XMLList;
			var atbOld:XMLList;
			var atbname:String;
			var newvalue:String;
			var stmp:String;
			
			oldList = oldVersion[nodeName];
			newList = newVersion[nodeName];
			L = newList.length();
			
			for( i=0; i<L; i++ )
			{
				if( newList[i].@name != undefined )
				{
					n = newList[i].@name.toString();
					atbNew = newList[i].attributes();
					L2 = atbNew.length();
					
					//find name in oldList..
					if( (x = oldList.(@name == n)) != undefined )
					{
						// COMPARE ATBS and CREATE UPDATE STATEMENT FOR different ATBS
						atbOld = x.attributes();
						
						if( atbNew.toString() != atbOld.toString() ) // test all attributes 
						{
							stmp = ' <upd ctt="'+nodeName+'" name="'+n+'"';
							
							for(j=0; j<L2; j++)
							{
								atbname = atbNew[j].name().toString();
								if( atbname != "name" && atbname!="ctt" ) {
									newvalue = newList[i].@[atbname].toString();
									
									if( newvalue != x.@[atbname].toString() ) {
										stmp += ' ' + atbname + '="'+ newvalue+'"';
									}
								}
							}
							stmp += "/>\n";
							
							statements += stmp;
						}
					}
					else
					{
						// ADD INSERT STATEMENT
						stmp = ' <ins ctt="'+nodeName+'" name="'+n+'"';
						
						for( j=0; j<L2; j++ )
						{
							atbname = atbNew[j].name().toString();
							if( atbname != "name" && atbname!="ctt" ) {
								newvalue = newList[i].@[atbname].toString();
								stmp += ' ' + atbname + '="'+ newvalue+'"';
							}
						}
						stmp += "/>\n";
						
						statements += stmp;	
					}
				}
			}
			
			// find deleted nodes
			L = oldList.length();
			for( i=0; i<L; i++ )
			{
				if( oldList[i].@name != undefined )
				{
					n = oldList[i].@name.toString();
					
					//find name in newList..
					if( (x = newList.(@name == n)) == undefined )
					{
						// ADD DELETE STATEMENT
						stmp = ' <del ctt="'+nodeName+'" name="'+n+'"/>\n';
						statements += stmp;
					}
				}
			}
			
			return statements;
		}
	}
}