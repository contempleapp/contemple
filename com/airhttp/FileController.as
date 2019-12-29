package com.airhttp
{
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
	
	import agf.tools.Console;
	import ct.CTOptions;
	
    /**
    * Is an ActionController for AirHttp that provides the ability to
    * retrieve files for a limited number of mime types relative to a 
    * "webroot" that is defined at constuction.
    * <p>
    * Available mime types:
    * </p>
    * <ul>
    *   <li>.htm => text/html</li>
    *   <li>.html => text/html</li>
    *   <li>.js => application/x-javascript</li>
    *   <li>.css => text/css</li>
    *   <li>.gif => image/gif</li>
    *   <li>.ico => image/x-icon</li>
    *   <li>.jpg => image/jpeg</li>
    *   <li>.png => image/png</li>
    * </ul>
     */
    public class FileController extends ActionController
    {
        private var _mimeTypes:Object = new Object();
        //private var _webroot:String;
		private var _htdocs:File;
		
        /**
        * @param webroot is the directory relative to the application
        * storage directory that will serve up files.
         */
        public function FileController( htdocs:File )
        {
            super();
           
			//_webroot = webroot;
           if ( htdocs ) {
				if ( !htdocs.isDirectory ) {
					Console.log( "Error: htdocs is not a directory");
				}else{
					_htdocs = htdocs;
				}
				
			}else{
				Console.log("Error : no htdocs directory set");
			}
			
            // The mime types supported by this mini web server
            _mimeTypes[".css"]   = "text/css;charset=utf-8";
            _mimeTypes[".gif"]   = "image/gif";
            _mimeTypes[".htm"]   = "text/html;charset=utf-8";
            _mimeTypes[".html"]  = "text/html;charset=utf-8";
            _mimeTypes[".ico"]   = "image/x-icon";
            _mimeTypes[".jpg"]   = "image/jpeg";
            _mimeTypes[".js"]    = "application/x-javascript;charset=utf-8";
            _mimeTypes[".png"]   = "image/png";
        }
        
        /**
        * The full filesystem path where webroot is found.
         */
        public function get docRoot(): String
        {
           // return File.applicationStorageDirectory.resolvePath(_webroot).nativePath;
            return _htdocs.url; // File.documentsDirectory.resolvePath(_webroot).url;
        }
        
        /**
        * Retrive a file relative to webroot.
        * <p>
        * <b>Note:</b> Files with a '..' will be rejected and will generate
        * <code>403 Forbidden</code responses. 
        * </p>
        * @param filepath the path, relative to webroot that should be reteived.
        * 
        * @return a ByteArray with the web response which may be a <code>200 OK</code>,
        * a <code>404 Not Found</code> or <code>403 Forbidden</code> response.
         */
        public function getFile(filepath:String):ByteArray
        {
            var content:ByteArray = new ByteArray();
			content.endian = Endian.LITTLE_ENDIAN;
			if( _htdocs ) {
				if (filepath.indexOf("..") != -1) {
					content.writeMultiByte(responseForbidden(filepath), CTOptions.charset);
					return content;
				}

				var file:File = new File(_htdocs.url + "/" + filepath); // File.documentsDirectory.resolvePath(_webroot + filepath);
				
				if (!file.exists || file.isDirectory) {
					content.writeMultiByte(responseNotFound("Path Not Found " + file.url ), CTOptions.charset);
					return content;
				}

				var stream:FileStream = new FileStream();
				stream.endian = Endian.LITTLE_ENDIAN;
				stream.open( file, FileMode.READ );
				content.writeMultiByte ( header(200, "OK", getMimeType(filepath) ), CTOptions.charset);
				stream.readBytes(content);
				stream.close();
			}
            return content;   
        }
        
        /**
        * Reteive the mime-type header information for the requested file.
        * 
        * @param path is the filepath (relative to webroot) to use in the
        * lookup.
        * 
        * @return A String with the mime-type, defaulting to "test/html" if
        * one wasn't found.
         */
        private function getMimeType(path:String):String
        {
            var mimeType:String;
            var index:int = path.lastIndexOf(".");
            if (index > -1)
            {
                mimeType = _mimeTypes[path.substring(index)];
            }
            return mimeType == null ? "text/html" : mimeType ; // default to text/html for unknown mime types
        }
        
    }
}