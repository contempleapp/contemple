﻿package agf.io
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	
	public class Resource extends EventDispatcher
	{
		public var udfData:Object={};
		public var url:String;
		public var urlRequest:URLRequest;
		
		public var isText:Boolean;
		public var obj:Object;
		public var uid:int = -1;
		public var fin:Function = null;
		private var _error:Error = null;
		private var _loaded:int = -1;
		private  var _loader:Object;
		
		public function load (a_url:String="", isTextFile:Boolean=true, a_fin:Function=null, postVars:URLVariables=null, binaryTextFile:Boolean=false) :void {
			url = a_url;
			obj = null;
			fin = a_fin;
			isText = isTextFile;
			_loaded = -1;
			
			if( url == "" ) {
				// clean up and return
				return;
			}
			
			var loader;
			var req:URLRequest;
			
			try 
			{
				if(isTextFile)
				{
					loader = new URLLoader();
					if( binaryTextFile ) {
						loader.dataFormat = URLLoaderDataFormat.BINARY;
					}
					loader.addEventListener(Event.COMPLETE, textCompleteHandler);
					loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
					loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				}
				else
				{
					loader = new Loader();
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageCompleteHandler);
					loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressHandler);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				}
				
				req = new URLRequest(url);
				
				if(postVars) {
					req.data = postVars;
					req.method = URLRequestMethod.POST;
				}
				urlRequest = req;
				
				_loader = loader;
				loader.load( req );
			}
			catch (error:Error)
			{
				_error = error;
				complete(null, 0);
			}
		}
		public function abort () :void {
			if( loaded != 1 ) {
				if( _loader ) {
					/*if( _loader is URLLoader ) {
						URLLoader( _loader ).close();
					}
					*/
					_loader.close();
				}
			}
		}
		private function progressHandler(event:ProgressEvent):void
		{
			dispatchEvent(event);
        }

		public function get loaded () :Boolean { return _loaded == 1; }
		public function get error () :Error { return _error; }
		private function ioErrorHandler (e:IOErrorEvent) :void {
			complete(null, 0);
		}
		private function imageCompleteHandler (e:Event) :void {
			obj = Loader(e.target.loader).content;
			complete(e, 1);
		}
		private function textCompleteHandler (e:Event) :void {
			obj = URLLoader(e.target).data;
			complete(e, 1);
		}
		private function complete (e:Event, ld:int) :void {
			_loaded = ld;
			if(fin != null) fin.apply(fin, [e, this]);
		}
	}
}