package com.stintern.swf2ani.utils
{
    import com.adobe.images.PNGEncoder;
    
    import flash.display.Bitmap;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.system.Capabilities;
    import flash.utils.ByteArray;

    public class Exporter
    {
        public function Exporter()
        {
        }
        
        public function ExportPNG(bmp:Bitmap):Boolean
        {
            var file:File;
            var fileStream:FileStream;
            
            try
            {
                var ba:ByteArray = PNGEncoder.encode(bmp.bitmapData);
                file = new File(File.applicationDirectory.resolvePath("out/atlas.png").nativePath);
                fileStream = new FileStream();
                var osName:String = Capabilities.os;
                
                fileStream.open(file, FileMode.WRITE);
                fileStream.writeBytes(ba);
                fileStream.close();
                
                fileStream = null;
                file = null;
                
                return true;
            }
            catch(e:Error)
            {
                throw new Error(e);
                
                fileStream = null;
                file = null;
                
                return false;
            }
        }
        
        public function ExportXML(xml:XML):Boolean
        {
            var ba:ByteArray = new ByteArray();
            
            try
            {
                ba.writeUTFBytes(xml);
                
                var file:File = new File(File.applicationDirectory.resolvePath("out/atlas.xml").nativePath);
                var fileStream:FileStream = new FileStream();
                
                fileStream.open(file, FileMode.WRITE);
                fileStream.writeUTFBytes(ba.toString());
                fileStream.close();
                
                ba.clear();
                ba = null;
                fileStream = null;
                
                return true;
            }
            catch(e:Error)
            {
                throw new Error(e);
                
                ba = null;
                fileStream = null;
                
                return false;
            }
        }
    }
}