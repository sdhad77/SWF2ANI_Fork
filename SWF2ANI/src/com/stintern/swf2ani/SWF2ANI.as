package com.stintern.swf2ani
{
    import com.stintern.swf2ani.utils.Exporter;
    import com.stintern.swf2ani.utils.SWFLoader;
    
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.text.TextField;
    
    public class SWF2ANI extends Sprite
    {
        private var file:File;
        
        public function SWF2ANI()
        {
            file = new File();
            file.addEventListener(Event.SELECT, onFileSelected);
            file.browseForOpen("변환할 SWF 파일을 선택하세요.");
            
        }
        
        private function onFileSelected(event:Event):void
        {
            // SWF 파일을 로드합니다.
            var swfLoader:SWFLoader = new SWFLoader();
            swfLoader.loadSWF(file, onComplete);
        }
        
        private function onComplete(bmp:Bitmap, xml:XML):void
        {
            var exporter:Exporter = new Exporter();
            
            if( !exporter.ExportPNG(bmp) )
            {
                return;
            }
                
            if( !exporter.ExportXML(xml) )
            {
                return;
            }
            
            var textField:TextField = new TextField();
            textField.text = "생성 완료";
            addChild(textField);
            
            exporter = null;
        }
    }
}