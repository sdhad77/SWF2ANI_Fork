package com.stintern.swf2ani
{
    import com.stintern.swf2ani.utils.Exporter;
    import com.stintern.swf2ani.utils.Packer;
    import com.stintern.swf2ani.utils.PngLoader;
    import com.stintern.swf2ani.utils.SwfLoader;
    
    import flash.display.Bitmap;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.text.TextField;
    
    public class SWF2ANI extends Sprite
    {
        public function SWF2ANI()
        {
            var swfLoader:SwfLoader = new SwfLoader();
            swfLoader.loadSWF("res/title.swf", titleLoaded);
        }
        
        private function titleLoaded(mc:MovieClip):void
        {
            var titleMc:MovieClip = mc;
            titleMc.scaleX = titleMc.width/stage.stageWidth;
            titleMc.scaleY = titleMc.width/stage.stageWidth;
            
            addChild(titleMc);
            
            titleMc.getChildAt(0).addEventListener(MouseEvent.CLICK, firstButtonClick);
            titleMc.getChildAt(1).addEventListener(MouseEvent.CLICK, secondButtonClick);
        }
        
        /**
         * 첫번째 버튼 클릭, pngFile 버튼
         * @param evt event
         */
        private function firstButtonClick(evt:Event):void
        {
            var file:File = new File();
            file.addEventListener(Event.SELECT, pngFolderSelected);
            file.browseForDirectory("변환할 PNG파일이 있는 폴더를 선택하세요.");
            
            function pngFolderSelected(event:Event):void
            {
                file.removeEventListener(Event.SELECT, pngFolderSelected);
                
                var pngFolderLoader:PngLoader = new PngLoader;
                pngFolderLoader.loadPngFolder(file, packing);
            }
        }
        
        /**
         * 두번째 버튼 클릭, swfFile 버튼
         * @param evt event
         */
        private function secondButtonClick(evt:Event):void
        {
            var file:File = new File();
            file.addEventListener(Event.SELECT, swfFileSelected);
            file.browseForOpen("변환할 SWF 파일을 선택하세요.");
            
            function swfFileSelected(event:Event):void
            {
                file.removeEventListener(Event.SELECT, swfFileSelected);
                
                var swfLoader:SwfLoader = new SwfLoader();
                swfLoader.loadSWF(file.nativePath, packing, true);
            }
        }
        
        /**
         * 읽어온 이미지 데이터들을 이용하여 하나의 스프라이트 시트와 xml 파일을 만드는 함수
         * @param param 읽어온 이미지 데이터
         */
        private function packing(param:Array):void
        {
            var packer:Packer = new Packer();
            var result:Array = packer.imagePacking(param);
            onComplete(result[0], result[1]);
            
            packer = null;
        }
        
        /**
         * 스프라이트 시트와 xml파일을 파일로 출력하는 함수
         * @param bmp 스프라이트 시트
         * @param xml xml파일
         */
        private function onComplete(bmp:Bitmap, xml:XML):void
        {
            var exporter:Exporter = new Exporter();
            
            if( !exporter.ExportPNG(bmp) ) return;
            if( !exporter.ExportXML(xml) ) return;
            
            var textField:TextField = new TextField();
            textField.text = "생성 완료";
            addChild(textField);
            
            exporter = null;
        }
    }
}