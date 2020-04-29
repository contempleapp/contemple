package agf.utils {
	
	public class FileUtils {
		
		private static var fi:FileInfo;
		
		public static function fileInfo ( url:String ) :FileInfo {
			if( !fi ) fi = new FileInfo();
			
			var sp1:int = url.lastIndexOf( "/" );
			if( sp1 >= 0 ) {
				fi.separator = "/";
			}else{
				sp1 = url.lastIndexOf("\\");
				if( sp1 >= 0 ) {
					fi.separator = "\\";
				}else{
					sp1 = -1; // no path
					fi.path = "";
				}
			}
			if ( sp1 >= 0 ) {
				fi.path = url.substring( 0, sp1 );
			}
			
			var dot:int = url.lastIndexOf( "." );
			var extension:String="";
			
			if( dot >= 0 ) {
				extension = url.substring( dot+1 ).toLowerCase();
				if( extension == "htm" || extension == "html" || extension == "xml" ) {
					fi.type = "html";
				}else if ( extension == "css" ) {
					fi.type = "style";
				}else if(extension == "js" || extension == "as" || extension == "sql" || extension == "asp" || extension == "php"){
					fi.type = "script";
				}else if(extension == "txt" || extension == "md" || extension == "tf"){
					fi.type = "text";
				}else if(extension == "jpg" || extension == "png" || extension == "gif"){
					fi.type = "image";
				}else if(extension == "svg" ){
					fi.type = "svg";
				}else if(extension == "db" ){
					fi.type = "database";
				}else if(extension == "pdf" ){
					fi.type = "pdf";
				}else{
					fi.type = "unknown/"+extension;
				}
			}else{
				extension = "";
			}
			
			fi.extension = extension;
			
			if ( sp1 == -1 ) {
				fi.name = url.substring( 0, dot );
				fi.filename = url;
			}
			else
			{
				var st:int = url.lastIndexOf( fi.separator ) + 1;
				fi.name = url.substring( st, dot );
				fi.filename = url.substring( st );
			}
			
			return fi;
		}
	}
	
	
}
