package ct.ctrl
{
	import agf.tools.Application;
	
	public class UICmd 
	{
		public function UICmd ( _label:Array, _cmd:String='', _cbFunc:Function=null, _cbArgs:Array=null) {
			label = _label;
			cmd = _cmd;
			cbFunc = _cbFunc;
			cbArgs = _cbArgs;
		}
		
		public var label:Array; // strings and displayobjects
		public var cmd:String;
		public var cbFunc:Function;
		public var cbArgs:Array;
		
		// Run the cmd with callback function after the cmd finished OR run callback function immediatly if cmd is a empty string
		public function run () :void {
			if( cmd != '' ) {
				Application.instance.cmd( cmd, cbFunc, cbArgs );
			} else {
				if ( cbFunc != null ) {
					if( cbArgs != null) cbFunc.apply(null, cbArgs);
					else cbFunc();
				}
			}
		}
	}
}