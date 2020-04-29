package agf.ui 
{
	public class Language
	{
		public function Language() {}
		
		public static var onChangeLanguage:Function;
		
		private static var items:Object = {};
		private static var stores:Object = {};
		private static var _lang:String = "en";
		
		public static function get language () :String { return _lang; }
		public static function set language (l:String) :void {
			if( _lang != l){
				_lang = l;
				if( onChangeLanguage != null ) onChangeLanguage();
			}
		}
		
		public static function clear ( storeId:String = "all" ) :void
		{
			if(storeId == "all" ){
				stores = {};
				items = {};
			}else{
				if ( storeId == "" ) {// Clear default store only
					items = {};
				}else{
					if ( stores[storeId] ) { // clear a store
						stores[storeId] = null;
						delete stores[storeId];
					}
				}
			}
		}
		
		public static function addXmlKeywords ( xo:XMLList, storeId:String="" ) :void {
			if( xo ) {
				var L:int = xo.length();
				var L2:int;
				var j:int;
				var langs:XMLList;
				var ids:String;
				
				for(var i:int=0; i<L; i++) {
					if( xo[i].@name ) {
						langs = xo[i].lang;
						L2 = langs.length();
						for(j=0; j<L2; j++) 
						{
							ids = xo[i].@name.toString();
							addKeyword( ids, langs[j].@value.toString(), langs[j].@name.toString(), storeId );
						}
					}
				}
			}
		}
		public static function addKeyword ( key:String, value:String="", lang:String="en", storeId:String="" ) :void {
			if( storeId ) {
				if( !stores[storeId] ) stores[storeId] = {};
				if( !stores[storeId]["_"+lang] ) stores[storeId]["_"+lang] = {};
				stores[storeId]["_"+lang]["_"+key] = value;
			}else{
				if( !items["_"+lang] ) items["_"+lang] = {};
				items["_"+lang]["_"+key] = value;
			}
		}
		
		public static function findKeyByValue (value:String="", lang:String="", storeId:String="" ) :String {
			if( !lang ) lang = _lang;
			var st:String;
			var n:String;
			
			if( stores ) {
				if( storeId ) {
					if( stores[storeId] && stores[storeId]["_"+lang] ) {
						for(n in stores[st]["_"+lang]) {
							if( stores[st]["_"+lang][n] == value) {
								return n.substring(1);
							}
						}
					}
				}else{
					// Search all stores
					for(st in stores) {
						if( stores[st]["_"+lang] ) {
							for(n in stores[st]["_"+lang]) {
								if( stores[st]["_"+lang][n] == value) {
									return n.substring(1);
								}
							}
						}
					}
				}
			}
			
			if( items ) {
				if( items["_"+lang] ) {
					for(n in items["_"+lang]) {
						if( items["_"+lang][n] == value) {
							return n.substring(1);
						}
					}
				}
			}
			
			return value;
		}
		
		public static function getKeyword ( key:String, lang:String="", storeId:String="all" ) :String {
			if( lang == "" ) lang = _lang;
			if( storeId ) if( stores[storeId] && stores[storeId]["_"+lang] && stores[storeId]["_"+lang]["_"+key] != null) return stores[storeId]["_"+lang]["_"+key];
			if( items["_"+lang] && items["_"+lang]["_"+key] != null ) return items["_"+lang]["_"+key];
			if( storeId == "all") {
				for( var store:String in stores ) {
					if( stores[store]["_"+lang] && stores[store]["_"+lang]["_"+key] != null) return stores[store]["_"+lang]["_"+key];
				}
			}
			return key;
		}
		
		public static function hasKeyword ( key:String, lang:String="", storeId:String="all" ) :Boolean {
			if( lang == "" ) lang = _lang;
			if( storeId ) if( stores[storeId] && stores[storeId]["_"+lang] && stores[storeId]["_"+lang]["_"+key] ) return true;
			if( items["_"+lang] && items["_"+lang]["_"+key] != null ) return true;
			if( storeId == "all") {
				for( var store:String in stores ) {
					if( stores[store]["_"+lang] && stores[store]["_"+lang]["_"+key] != null ) return true;
				}
			}
			return false;
		}
	}
} 