package agf.io
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.setTimeout;
	
	public class ResourceMgr extends EventDispatcher
	{
		public static function getInstance () :ResourceMgr
		{
			return rm || (rm = new ResourceMgr);
		}
		
		private static var rm:ResourceMgr;
		private var _res:Vector.<Resource>;
		private var _resByName:Object;
		private var finFuncs:Array = [];
		
		public function clearAll () :void 
		{
			if(_res) _res = new Vector.<Resource>();
			if(_resByName) _resByName = {};
			finFuncs = [];
		}
		
		public function loadResource (file:String, fin:Function=null, isTextFile:Boolean=true, binaryTextFile:Boolean = false) :int 
		{
			if(!_res) _res = new Vector.<Resource>();
			if(!_resByName ) _resByName = {};
			
			var L:int = _res.length;
			var ldd:Boolean=false;
			var r:Resource;
			var uid:int=L;
			
			if( _resByName[file] != undefined ) {
				// Resource already loaded / loading
				ldd = true;
				r = _resByName[file];
				uid = r.uid;
			}
			
			if( !ldd )
			{
				// Load resource file for the first time
				r = new Resource();
				r.uid = L;
				
				if(fin != null) finFuncs.push( {res: r, func: fin} );
				
				_res.push( r );
				_resByName[ file ] = r;
				
				r.load(file, isTextFile, resLoaded, null, binaryTextFile);
			}
			else
			{
				if( fin != null ) {
					if( r.loaded )
					{
						// Resource was already cached
						setTimeout( fin, 0, r );
					}
					else
					{
						// Resource is still loading, but already earlier loaded
						finFuncs.push({res:r, func:fin});
					}
				}
			}
			
			return uid;
		}
		
		private function resLoaded (e:Event, res:Resource=null) :void 
		{
			var i:int;
			if( res.loaded == 0 ) {
				// Load Error..
				// clear intern resource for re-load..
				for( i=0; i<_res.length; i++ ) {
					if( _res[i] == res ) {
						_res.splice(i,1);
						if( _resByName[res.url] != undefined ) delete _resByName[ res.url ];
						break;
					}
				}
			}
			// Call all registered complete functions for the Resource
			if( finFuncs.length > 0 ) {
				for(i = finFuncs.length-1; i>=0; i--) {
					if(finFuncs[i].res == res) {
						finFuncs[i].func(res);
						finFuncs.splice(i, 1);
					}	
				}
			}
			if( e ) dispatchEvent( e );
		}
		
			
		public function clearResourceCache (url:String, clearHandlers:Boolean=true) :void 
		{
			
			var res:Resource;
			var i:int;
			
			for(i=_res.length-1; i>=0; i--) {
				if(_res[i].url == url) {
					res = _res[i];
					_res.splice(i, 1);
					if( _resByName[ url ] != undefined ) {
						delete _resByName[ url ];
					}
					break;
				}
			}
			
			
			if( clearHandlers && res) {
				for(i = finFuncs.length-1; i>=0; i--) {
					if(finFuncs[i].res == res) {
						finFuncs.splice(i, 1);
					}	
				}
			}
			
		}
		public function getResourceById (id:int) :Resource 
		{
			if( _res && _res.length > id && id >= 0 ) {
				return _res[id];
			}
			return null;
		}
		
		public function getResource (url:String) :Resource 
		{
			if( _resByName[ url ] != undefined ) {
				return _resByName[ url ];
			}
			
			return null;
		}
	}
}